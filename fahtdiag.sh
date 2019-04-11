#!/bin/bash

####### TechTutors Diag Script ########
####### For internal use only! ########

pause_input () {
	read -n 1 -s -r -p "Press any key to continue"
	echo -e "\n"
}

### Dump current user to tmp var and re run as root  ###
if (( UID !=0 )); then
	whoami>/tmp/fahtdiaguser
	echo Re-starting as root...
	exec sudo -E "$0"
fi

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

### Dump systeminfo ###
echo -e "-----------------------------------"
echo -e "Dumping system info. Please wait..."
echo -e "-----------------------------------\n"
$PAUSE
echo

modprobe eeprom
dmidecode>$FAHT_WORKINGDIR/demidecode.txt
lshw>$FAHT_WORKINGDIR/lshw.txt
dmidecode > $FAHT_WORKINGDIR/dmidecode.txt
lscpu>$FAHT_WORKINGDIR/lscpu.txt
smartctl -x /dev/sda>$FAHT_WORKINGDIR/smartctl-sda.txt
acpi -i>$FAHT_WORKINGDIR/battery.txt
#hardinfo -r -f text>$FAHT_WORKINGDIR/hardinfo.txt
smartctl --info /dev/sda>$FAHT_WORKINGDIR/sda-info.txt

### Grab summary info for summary sheet ###

FAHT_MACHINE=$(cat $FAHT_WORKINGDIR/dmidecode.txt|grep -i "Product Name:"|sed 's/.*Product Name: //')
FAHT_SOCKET_COUNT=$(cat $FAHT_WORKINGDIR/lscpu.txt|grep -i "Socket(s):"|sed 's/[^0-9]*//g')
FAHT_CORE_COUNT=$(($(cat $FAHT_WORKINGDIR/lspcu.txt|grep -i ""|sed 's/[^0-9]*//g')*$FAHT_SOCKET_COUNT))
FAHT_CORE_THREAD=$(dmidecode|grep -i -m 1 "Thread Count:"|sed 's/[^0-9]*//g')
FAHT_MAX_MEMORY_GB=$(dmidecode|grep -i -m 1 "Maximum Capacity:"|sed 's/[^0-9]*//g')
FAHT_TOTAL_MEMORY_GB=$(lshw -c memory|grep -i size|grep -m 1 GiB|sed -n 's/[^0-9]*//gp')
FAHT_TOTAL_THREADS=$(($FAHT_CORE_COUNT*$FAHT_CORE_THREAD))
FAHT_CPU_MODEL=$(cat /proc/cpuinfo|grep -i -m 1 "model name"|sed -r 's/model name.*: (.*)/\1/g'|sed -n 's/  */ /gp')
FAHT_CPU_SPEED=$(lshw -c cpu|grep capacity|tail -1|sed 's/[^0-9]*//g')
FAHT_BATT_DESC=$(acpi -i)

### Note block device where linux is currently mounted for using as an exception when listing hdds
FAHT_LIVE_DEV=$(mount|grep -i "on / "|sed -n 's/^\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')
FAHT_SMART_DRIVES=$(smartctl --scan|grep -v $FAHT_LIVE_DEV|sed -n 's/\(\/dev\/[a-z][a-z][a-z]\).*/\1/gp')
( set -o posix; set ) | grep FAHT > /tmp/hwinfo.txt 
sleep 10
#	cat ->$FAHT_WORKING_DIR/hw_summary_vars.txt

#>$FAHT_WORKINGDIR/sysinfo.txt


### Old stuff.. Keep for now...

# CLIENTNAME=$LASTNAME-$FIRSTNAME

# echo -e "Client: $CLIENTNAME\n"

# ttdiaglog=/home/techtutors/log/diag-$CLIENTNAME-$DATE.txt

### Network test - Ethernet ###
clear
echo -------------------------------
echo Testing Ethernet... Please wait
echo -------------------------------
$PAUSE
echo
for p in `ip -o link | grep -i -E en\d* | sed -e 's/[0-9]: \(en.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$FAHT_WORKINGDIR/ethtest.txt

### Network test - Wireless ###
echo -----------------------------
echo Testing Wi-Fi.... Please wait
echo -----------------------------
$PAUSE
echo
for p in `ip -o link | grep -i -E wl\d* | sed -e 's/[0-9]: \(wl.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$FAHT_WORKINGDIR/wifitest.txt


### Audio test ###
clear
echo ----------------------------
echo Testing Audio... Please wait
echo ----------------------------
$PAUSE
echo

amixer -D pulse sset Master 100%

#for i in {1..3}; do
#	mplayer /usr/share/ttaudio/starcmd.m4a;
#done;

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
$PAUSE
echo

curr_smart_dev=/dev/sda
echo Beginning SMART long test on $curr_smart_dev

#smartctl -a $curr_smart_dev|awk... smart_long_test_max, smart_short_test_max

smartctl -t force -t long $curr_smart_dev>$FAHT_WORKING_DIR/smartlongtest.txt

cat $FAHT_WORKING_DIR/smartlongtest.txt
smart_long_test_max_minutes=$(cat $FAHT_WORKING_DIR/smartlongtest.txt|grep "Please wait"|sed 's/[^0-9]*//g')

#echo Estimated time to complete Extended SMART test: $smart_long_test_max_minutes
#echo
#echo Test started on $(date). Estimated time of completion: $(date -d '+$smart_long_test_max_mins minutes')
#smartctl -t force long $curr_smart_dev

#smart_start_time=$((date +%s))
#smart_minutes_remaining=$((smart_start_time/60))

echo -en "\r$smart_long_test_max_minutes mins remaining"
for i in {1..$smart_long_test_max_minutes}; do
	sleep 60
	time_remaining=$(($smart_long_test_max_minutes-$1))
	echo -en "\r$time_remaining mins remaining";
done
echo
echo Smart test done.

smartctl -a $curr_smart_dev>$FAHT_WORKING_DIR/smartlongtestresult.txt
#| dialog --gauge "Running SMART Extended test on $curr_smart_dev Please wait..." 0 60 0 

### GFX Benchmark ###
#clear
echo -------------------------------
echo Testing GFX card... Please wait
echo -------------------------------
$PAUSE
echo
$FAHT_GFX_BENCH=$(glmark2 |grep -I score:)

( set -o posix; set ) | grep FAHT > $FAHT_WORKINGDIR/vars.txt

chmod -Rfv $FAHT_CURR_USER:$FAHT_CURR_USER $FAHT_WORKINGDIR

echo -e "All Done!\n"
