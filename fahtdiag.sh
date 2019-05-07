#!/bin/bash

# !!!!!! Need to deal with whitespace on user input for names

####### TechTutors Diag Script ########
####### For internal use only! ########

CONTINUE_SCRIPT=Y

pause_input () {
	read -n1 -s -r -p "Press any key to continue"
	echo -e "\n"
}

break_program () {
	while true; do
		echo -e "Continue script? [Y/n]: \c "
		read -n1 CONTINUE_SCRIPT 
		echo -e "\n"
		: ${CONTINUE_SCRIPT:=y}

		case ${CONTINUE_SCRIPT,,} in
			y|Y) break;;
			n|N) exit;;
			*) echo -e "Please retry... \n";;
		esac
	done
}

### Dump current user to tmp var and re run as root  ###
if (( UID !=0 )); then
	whoami>/tmp/fahtdiaguser
	echo Re-starting as root...
	exec sudo -E "$0"
fi

set -x

clear
echo -e "---------------------------"
echo -e "TechTutor's Diag Script"
echo -e "--------------------------- \n"

### Init variables ###
FAHT_CURR_USER=$(head -n 1 /tmp/fahtdiaguser)
FAHT_FIRSTNAME=
FAHT_LASTNAME=
CONFIRM=n
FAHT_AUDIO=
FAHT_DATE=$(date +%Y-%m-%d-%Hh)
PAUSE=pause_input
DIAG=break_program

while true; do
	echo -e "First Name: \c "
	read FAHT_FIRSTNAME

	echo -e "Last Name: \c "
	read FAHT_LASTNAME

	echo -e "You entered \e[1m$FAHT_FIRSTNAME $FAHT_LASTNAME\e[0m. Is this correct? [Y/n] \c "
	read -n1 CONFIRM
	: ${CONFIRM:=y}
	echo

	case ${CONFIRM,,} in
		y|Y) break;;
		*) echo -e "Please retry... \n";;
	esac
done

$DIAG

CONFIRM=
FAHT_CLIENTNAME=$FAHT_LASTNAME-$FAHT_FIRSTNAME
FAHT_WORKINGDIR=/home/$FAHT_CURR_USER/fahttest/$FAHT_CLIENTNAME-$FAHT_DATE

### Prep client folder ###
if [ ! -d /home/$FAHT_CURR_USER/fahttest ]; then
	mkdir /home/$FAHT_CURR_USER/fahttest
	chown $FAHT_CURR_USER:$FAHT_CURR_USER /home/$FAHT_CURR_USER/fahttest;
fi

if [ ! -d $FAHT_WORKINGDIR ]; then
	mkdir $FAHT_WORKINGDIR
	chown $FAHT_CURR_USER:$FAHT_CURR_USER $FAHT_WORKINGDIR;
fi

cp /usr/share/faht/faht-report-template.fodt $FAHT_WORKINGDIR/faht-report.fodt

### Dump systeminfo ###
echo -e "-----------------------------------"
echo -e "Dumping system info. Please wait..."
echo -e "-----------------------------------\n"
$DIAG
echo

modprobe eeprom
#dmidecode>$FAHT_WORKINGDIR/demidecode.txt
lshw>$FAHT_WORKINGDIR/lshw.txt
#dmidecode > $FAHT_WORKINGDIR/dmidecode.txt
lscpu>$FAHT_WORKINGDIR/lscpu.txt
smartctl -x /dev/sda>$FAHT_WORKINGDIR/smartctl-sda.txt
acpi -i>$FAHT_WORKINGDIR/battery.txt
#hardinfo -r -f text>$FAHT_WORKINGDIR/hardinfo.txt
smartctl --info /dev/sda>$FAHT_WORKINGDIR/sda-info.txt

### Grab summary info for summary sheet ###

FAHT_MACHINE=$(cat $FAHT_WORKINGDIR/dmidecode.txt|grep -i "Product Name:"|sed 's/.*Product Name: //')
FAHT_SOCKET_COUNT=$(cat $FAHT_WORKINGDIR/lscpu.txt|grep -i "Socket(s):"|sed 's/[^0-9]*//g')
FAHT_CORE_COUNT=$(( $(cat $FAHT_WORKINGDIR/lscpu.txt|egrep -i -m 1 ".*core.*socket*"|sed 's/[^0-9]*//g') * $FAHT_SOCKET_COUNT ))
FAHT_CORE_THREAD=$(cat $FAHT_WORKINGDIR/lscpu.txt|egrep -i -m 1 ".*Thread.*core*"|sed 's/[^0-9]*//g')
FAHT_MAX_MEMORY_GB=$(dmidecode|grep -i -m 1 "Maximum Capacity:"|sed 's/[^0-9]*//g')
FAHT_TOTAL_MEMORY_GB=$(lshw -c memory|grep -i size|grep -m 1 GiB|sed -n 's/[^0-9]*//gp')
FAHT_TOTAL_THREADS=$(( $FAHT_CORE_COUNT * $FAHT_CORE_THREAD ))
FAHT_CPU_MODEL=$(cat /proc/cpuinfo|grep -i -m 1 "model name"|sed -r 's/model name.*: (.*)/\1/g'|sed -n 's/  */ /gp')
FAHT_CPU_SPEED=$(lshw -c cpu|grep capacity|tail -1|sed 's/[^0-9]*//g')
FAHT_BATT_DESC=$(acpi -i)

### Note block device where linux is currently mounted for using as an exception when listing hdds
FAHT_LIVE_DEV=$(mount|grep " on / "|sed -n 's/^\/dev\/\(.*\)[0-9] on \/ .*/\1/gp')
FAHT_SMART_DRIVES_ARRAY=$(smartctl --scan|grep -v $FAHT_LIVE_DEV|sed -n 's/\(\/dev\/[a-z][a-z][a-z]\).*/\1/gp')

#  Get number of partitions from connected drives (For array size)
# lsblk -n -r -o NAME|egrep sd[a-z]+[0-9]+|sed -r 's/.*([a-z]d[a-z][0-9])/\1/g'|wc -l
# Get number of disks (For array size)
# lsblk -n -r -o NAME|grep -v [0-9]|wc -l

## Setting disks in array minus current OS disk
FAHT_TEST_DISKS_ARRAY=()
i=0
j=
for j in $(lsblk -n -r -o NAME|grep -v $FAHT_LIVE_DEV|grep -v [0-9]|grep "^[a-z]d[a-z]"); do
	FAHT_TEST_DISKS_ARRAY[$i]=$j
	((i++));
done

echo Available disks to test
echo ${FAHT_TEST_DISKS_ARRAY[@]}
echo

# Set up individual disk arrays

i=1
j=
for j in ${FAHT_TEST_DISKS_ARRAY[@]}; do
	declare -n CURR_FAHT_DISK=FAHT_DISK_${i}
	CURR_FAHT_DISK[deviceid]=$j
	echo ${CURR_FAHT_DISK[deviceid]}
	i=0
	CURR_PART=partition${x}
	for x in /dev/$(echo ${CURR_FAHT_DISK[deviceid]})*; do
		CURR_PART=part${i}
		CURR_FAHT_DISK[${CURR_PART}]=${x}
		echo ${CURR_FAHT_DISK[${CURR_PART}]};
	done
	echo ${!CURR_FAHT_DISK}
	echo ${!CURR_FAHT_DISK[deviceid]}
	(( i++ ));
done

$DIAG

# Set up array of partitions
FAHT_DISK_PARTS=()
i=0
j=

for j in $(lsblk -n -r -o NAME|grep -v $FAHT_LIVE_DEV|grep "^[a-z]d[a-z][0-9]"); do
	FAHT_TEST_PARTS_ARRAY[$i]=$j
	((i++));
done

echo Potential partitions to use for benchmarking:
echo ${FAHT_TEST_PARTS_ARRAY[@]}
echo

# Set up mount points

i=0
j=0

## Ensure test drives are unmounted first and mount structure is good

if [ ! -d /mnt/faht ]; then mkdir /mnt/faht; fi
for i in /mnt/faht/*; do
	rmdir $i;
done

$DIAG

for j in ${FAHT_TEST_PARTS_ARRAY[@]}; do
	umount /dev/${FAHT_TEST_PARTS_ARRAY[$j]};
done

j=0
for j in ${FAHT_TEST_PARTS_ARRAY[@]} ; do
	if [ ! -d /mnt/faht/$j/ ]; then
		mkdir /mnt/faht/$j;
	fi
	mount /dev/$j /mnt/faht/$j;
done

# Remove empty dirs (i.e. mounts that didn't work for whatever reason. We will loop through the remaining dirs to test for r/w.

for i in /mnt/faht/*; do
	rmdir $i;
done

$DIAG

# Test partitions for r/w mount

j=0

for j in /mnt/faht/*; do
	touch $i/test
	$DIAG
	rm $i/test;
done

# If unable to get r/w mount set benchmark for read-only

# If volume is writeable set benchamrk for read-write

### Testing for SMART-capable drives ###

smartctl --scan|sed -r 's/\/dev\/([a-z]d[a-z]).*/\1/g'|grep -v $FAHT_LIVE_DEV
if [ $? -eq 0 ]; then
	## Setting SMART capable drives in array for testing
	FAHT_SMART_DRIVES_ARRAY=()
	i=0
	j=0

	for j in $(smartctl --scan|sed -r 's/\/dev\/([a-z]d[a-z]).*/\1/g'|grep -v $FAHT_LIVE_DEV); do
		FAHT_SMART_DRIVES_ARRAY[$i]=$j
		((i++));
	done

	echo Drives with SMART capabilities:
	echo ${FAHT_SMART_DRIVES_ARRAY[@]}
	echo;
else
	echo No drives are SMART capable. Skipping test...
	echo;
fi

$DIAG

( set -o posix; set ) | grep FAHT > /tmp/vars.txt

sed -r 's/(FAHT_.*)=.*/\1/g' /tmp/vars.txt > /tmp/varsnames.txt
sed -r 's/.*=(.*)/\1/g' /tmp/vars.txt > /tmp/varsvalues.txt


i=0
varsNames=()
varsvalues=()

while IFS= read line; do
	varsNames[$i]=$line
	echo ${varsNames[$i]}
	(( i++ ));
done < /tmp/varsnames.txt

i=0

while IFS= read line; do
	varsValues[$i]=$line
	echo ${varsValues[$i]}
	(( i++ ));
done < /tmp/varsvalues.txt

i=0

cp /usr/share/faht/faht-report-template.fodt $FAHT_WORKING_DIR/faht-report.fodt

for x in ${varsNames[*]}; do
	echo "Working on $x..."
	sed -i "s/$x/${varsValues[$i]}/g" $FAHT_WORKING_DIR/faht-report.fodt
	(( i++ ));
done

$DIAG

### Network test - Ethernet ###
clear
echo -------------------------------
echo Testing Ethernet... Please wait
echo -------------------------------
$DIAG
echo
for p in `ip -o link | grep -i -E en\d* | sed -e 's/[0-9]: \(en.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$FAHT_WORKINGDIR/ethtest.txt

### Network test - Wireless ###
echo -----------------------------
echo Testing Wi-Fi.... Please wait
echo -----------------------------
$DIAG
echo
for p in `ip -o link | grep -i -E wl\d* | sed -e 's/[0-9]: \(wl.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$FAHT_WORKINGDIR/wifitest.txt


### Audio test ###
clear
echo ----------------------------
echo Testing Audio... Please wait
echo ----------------------------
$DIAG
echo

amixer -D pulse sset Master 100%

for i in {1..3}; do
	mplayer /usr/share/faht/starcmd.m4a;
done;

amixer -D pulse sset Master 40%

while true; do
	echo Did you hear the test tone? \(y/n\) 
	read -n1 CONFIRM
	: ${CONFIRM:=y}
	echo

	case ${CONFIRM,,} in
		y|Y) FAHT_AUDIO=PASSED && break;;
		n|N) FAHT_AUDIO=FAILED && break;;
		*) echo -e "Invalid entry. Please retry.... \n\n";;
	esac
done

### SMART Testing ###
clear
echo --------------------------------
echo Testing Hard Drives. Please wait
echo --------------------------------
$DIAG
echo

curr_smart_dev=/dev/sda
echo Beginning SMART short test on $curr_smart_dev

smartctl -t force -t long $curr_smart_dev>$FAHT_WORKINGDIR/smartshorttest.txt

cat $FAHT_WORKINGDIR/smartshorttest.txt
smart_short_test_max_minutes=$(cat $FAHT_WORKINGDIR/smartshorttest.txt|grep "Please wait"|sed 's/[^0-9]*//g')

echo
echo -en "\r$smart_short_test_max_minutes mins remaining"
j=1
while [ $j -lt $smart_shot_test_max_minutes  ]; do
	sleep 60
	time_remaining=$(( $smart_short_test_max_minutes - $j ))
	echo -en "\r$time_remaining mins remaining"
	let j=j+1;
done
echo
echo Smart test done.
echo

smartctl -x $curr_smart_dev>$FAHT_WORKINGDIR/smartshorttestresult.txt
echo
cat $FAHT_WORKINGDIR/smartshorttestresult.txt
echo

echo Beginning SMART long test on $curr_smart_dev

#smartctl -a $curr_smart_dev|awk... smart_long_test_max, smart_short_test_max

smartctl -t force -t long $curr_smart_dev>$FAHT_WORKINGDIR/smartlongtest.txt

cat $FAHT_WORKINGDIR/smartlongtest.txt
smart_long_test_max_minutes=$(cat $FAHT_WORKINGDIR/smartlongtest.txt|grep "Please wait"|sed 's/[^0-9]*//g')

#echo Estimated time to complete Extended SMART test: $smart_long_test_max_minutes
#echo
#echo Test started on $(date). Estimated time of completion: $(date -d '+$smart_long_test_max_mins minutes')
#smartctl -t force long $curr_smart_dev

#smart_start_time=$((date +%s))
#smart_minutes_remaining=$((smart_start_time/60))

echo
echo -en "\r$smart_long_test_max_minutes mins remaining"
j=1
while [ $j -lt $smart_long_test_max_minutes  ]; do
	sleep 60
	time_remaining=$(( $smart_long_test_max_minutes - $j ))
	echo -en "\r$time_remaining mins remaining"
	let j=j+1;
done
echo
echo Smart test done.
echo

smartctl -x $curr_smart_dev>$FAHT_WORKINGDIR/smartlongtestresult.txt
echo
cat $FAHT_WORKINGDIR/smartlongtestresult.txt
echo

#| dialog --gauge "Running SMART Extended test on $curr_smart_dev Please wait..." 0 60 0 

### GFX Benchmark ###
#clear
echo -------------------------------
echo Testing GFX card... Please wait
echo -------------------------------
$DIAG
echo
$FAHT_GFX_BENCH=$(glmark2 |grep -I score:)

( set -o posix; set ) | grep FAHT > $FAHT_WORKINGDIR/vars.txt

chown -Rfv $FAHT_CURR_USER:$FAHT_CURR_USER $FAHT_WORKINGDIR

echo -e "All Done!\n"
