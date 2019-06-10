#!/bin/bash

# !!!!!! Need to deal with whitespace on user input for names

####### TechTutors Diag Script ########
####### For internal use only! ########

### Update... ###

cd /home/techtutors/Documents/cleantech-scripts
git pull
rsync -avhP faht-report-template.fodt /usr/share/faht/

### Dump current user to tmp var and re run as root  ###
if (( UID !=0 )); then
	whoami>/tmp/fahtdiaguser
	echo Re-starting as root...
	exec sudo -E "$0" "$@"
fi

FAHT_QUICKMODE=false
FAHT_DIAGMODE=
FAHT_SHORTONLY=
FAHT_QUICKMODE=
FAHT_CLAMAV=

pause_input () {
	read -n1 -s -r -p "Press any key to continue"
	echo -e "\n"
}

### Usage confirm_prompt "Question string" $VARIABLE_TO_PUT_ANSWER_IN
confirm_prompt ()
{
	prompt_answer=
	while [ -z "$prompt_answer" ]; do
		if [ $2 ]
		then
			text_verify="You entered \e[1m$2\e[0m. "
		else
			text_verify=
		fi	
		echo -e "$text_verify$1 [Y/n] \c"

		read -n1 CONFIRM
		: ${CONFIRM:=y}
		echo
		
		case ${CONFIRM,,} in
			y|Y) prompt_answer=y;;
			n|N) prompt_answer=n;;
			*) echo -e "Please retry... \n";;
		esac
	done
}
### input_prompt usage: input_prompt "Question string" VARIABLE_NAME
### OR 
input_prompt ()
{
	INPUT=
	prompt_answer=
	if [ -z "$1" ]
	then
		echo "-Param #1 is zero-length"
	fi
	if [ -z "$2" ]
	then
		while [ -z "$prompt_answer" ]; do
			echo -e "$1 \c "
		confirm_prompt
	done
	else
		while [ "$prompt_answer" != "y" ]; do
		echo -e "$1 \c "
		read INPUT
		eval $2=$INPUT
		confirm_prompt "Is this correct?" $INPUT
	done
	fi

}

### Called without args
dialog_prompt ()
{
	INPUT=
	prompt_answer=
	if [ -z "$1" ]
	then
		echo "-Param #1 is zero-length"
	fi
	if [ -z "$2" ]
	then
		while [ -z "$prompt_answer" ]; do
			echo -e "$1 \c "
		confirm_prompt
	done
	else
		exec 3>&1
		INPUT="$(dialog --inputbox "$1" 0 0 2>&1 1>&3)"
		exec 3>&-
		eval "$2"=\"$(echo $INPUT)\"
	fi

}

### Called without args
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

while getopts ":hdsqc" option; do
	case $option in
		h) echo "usage: $0 [-h] [-d] [-s] [-q] [-c]..."; exit ;;
		d) FAHT_DIAGMODE=true ;;
		s) FAHT_SHORTONLY=true ;;
		q) FAHT_QUICKMODE=true ;;
		c) FAHT_CLAMAV=true ;;
		?) echo "error: option -$OPTARG is not implemented"; exit;;
	esac
done

shift $(( OPTIND - 1))

echo $FAHT_DIAGMODE

clear
echo -e "---------------------------"
echo -e "TechTutor's Diag Script"
echo -e "--------------------------- \n"

### Init ###
FAHT_CURR_USER=$(head -n 1 /tmp/fahtdiaguser)
FAHT_FIRSTNAME=
FAHT_LASTNAME=
FAHT_FULLNAME=
CONFIRM=n
FAHT_AUDIO=
FAHT_TEST_DATE=$(date +%Y-%m-%d)
FAHT_TEST_TIME=$(date +%Hh)
PAUSE=pause_input
FAHT_NOTES=
FAHT_PHYSICAL_GRADE=
FAHT_PHYSICAL_NOTES=
FAHT_COMPUTER_TYPE=
FAHT_ASSESMENT_RESULTS=
FAHT_NOTES=
FAHT_PROBLEMS=
declare -A FAHT_FORM_ARRAY=( [FAHT_FULLNAME]="" [FAHT_PROBLEMS]="" [FAHT_NOTES]="" [FAHT_PHYSICAL_NOTES]="" [FAHT_COMPUTER_TYPE]="" [FAHT_ASSESSMENT_RESULTS]="" [FAHT_NOTES]="" )

if [ "$FAHT_DIAGMODE" == "true" ]; then
	clear
	set -x
	echo DIAG MODE ACTIVATED!!!!!!!!
	DIAG=break_program;
fi
### Get basic system id for faht folder ###

lshw -c system>/tmp/fs.txt

FAHT_COMP_TYPE=$(cat /tmp/fs.txt|grep description|sed 's/.*description: //')
FAHT_COMP_VENDOR=$(cat /tmp/fs.txt|grep vendor|sed 's/.*vendor: //')
FAHT_COMPUTER_SERIAL=$(cat /tmp/fs.txt|grep serial|sed 's/.*serial: //')
FAHT_COMP_DESC=$FAHT_COMP_VENDOR-$FAHT_COMP_TYPE-$FAHT_COMPUTER_SERIAL

client_details ()
{

	while [ "$prompt_answer" != "y" ]; do 
		dialog_prompt "First Name:" FAHT_FIRSTNAME
		dialog_prompt "Last Name:" FAHT_LASTNAME
		dialog_prompt "Problems Experienced:" FAHT_PROBLEMS

		clear
		echo "First Name: $FAHT_FIRSTNAME"
		echo "Last Name: $FAHT_LASTNAME"
		echo "Computer: $FAHT_COMP_DESC"
		echo "Problems Experienced: $FAHT_PROBLEMS"
		confirm_prompt "Is this correct?"

	done

	CONFIRM=
	FAHT_CLIENTNAME="$FAHT_LASTNAME-$FAHT_FIRSTNAME"
	FAHT_WORKINGDIR=/home/"$FAHT_CURR_USER"/fahttest/"$FAHT_CLIENTNAME"-"$FAHT_TEST_DATE"-"$FAHT_TEST_TIME"-"$FAHT_COMP_DESC"

	#FAHT_TEMP="$(lshw -class system|grep product|sed -r 's/.*product: (.*) \(.*)/\1/'|sed 's/ /_/g'')"
	### Prep client folder ###
	if [ ! -d /home/$FAHT_CURR_USER/fahttest ]; then
		mkdir /home/$FAHT_CURR_USER/fahttest
		chown "$FAHT_CURR_USER":"$FAHT_CURR_USER" /home/"$FAHT_CURR_USER"/fahttest;
	fi

	if [ ! -d "$FAHT_WORKINGDIR" ]; then
		mkdir "$FAHT_WORKINGDIR"
		chown "$FAHT_CURR_USER":"$FAHT_CURR_USER" "$FAHT_WORKINGDIR";
	fi

	cp /usr/share/faht/faht-report-template.fodt $FAHT_WORKINGDIR/faht-report.fodt
}

client_details

sysinfo_dump ()
{
	### Dump systeminfo ###
	echo -e "-----------------------------------"
	echo -e "Dumping system info. Please wait..."
	echo -e "-----------------------------------\n"
	$DIAG
	echo

	modprobe eeprom
	for i in system memory disk bus multimedia power display processor bridge volume network; do
		lshw -c "$i" >"$FAHT_WORKINGDIR"/lshw-"$i".txt;
	done

	for i in bios system baseboard chassis processor memory cache connector slot; do
		dmidecode -t $i >$FAHT_WORKINGDIR/dmidecode-$i.txt;
	done

	lscpu>"$FAHT_WORKINGDIR"/lscpu.txt

	### Yes, we are presuming for now the first (and presumably only) HDD for the SMART test... This is most common, so it is acceptable FOR NOW...

	smartctl -x /dev/sda>"$FAHT_WORKINGDIR"/smartctl-sda.txt

	acpi -i>"$FAHT_WORKINGDIR"/acpi.txt

	### Not sure if we'll ever use this since it just grabs a whole bunch of info from (mostly) commands that we will run, but dumping it for potentially future use...

temp	hardinfo -r -f text>"$FAHT_WORKINGDIR"/hardinfo.txt

	### Grab summary info for summary sheet ###

	FAHT_COMPUTER_DESC="$(cat $FAHT_WORKINGDIR/lshw-system.txt|grep product|sed -r 's/.*product: (.*) \(.*/\1/')"
	FAHT_PROC_MODEL="$(cat $FAHT_WORKINGDIR/lshw-processor.txt|grep product|sed 's/.*product: //')"
	FAHT_SOCKET_COUNT="$(cat $FAHT_WORKINGDIR/lscpu.txt|grep -i "Socket(s):"|sed 's/[^0-9]*//g')"
	FAHT_CORE_COUNT="$(( $(cat $FAHT_WORKINGDIR/lscpu.txt|egrep -i -m 1 ".*core.*socket*"|sed 's/[^0-9]*//g') * $FAHT_SOCKET_COUNT ))"
	FAHT_PROC_CORES="$(( $FAHT_CORE_COUNT * FAHT_SOCKET_COUNT ))"
	FAHT_CORE_THREAD="$(cat $FAHT_WORKINGDIR/lscpu.txt|egrep -i -m 1 ".*Thread.*core*"|sed 's/[^0-9]*//g')"
	FAHT_MAX_MEMORY="$(dmidecode|grep -i -m 1 "Maximum Capacity:"|sed 's/[^0-9]*//g')"
	FAHT_MEM_SIZE="$(cat $FAHT_WORKINGDIR/lshw-memory.txt |awk '/*-memory/,/*-bank:0/'|grep size|sed -r 's/.*([0-9]+).*/\1/')"
	FAHT_MEM_TYPE="$(cat $FAHT_WORKINGDIR/dmidecode-memory.txt|grep DDR|sed -r 's/.*(DDR[1-6].*).*/\1/')"
	FAHT_MEM_SPEED="$(cat $FAHT_WORKINGDIR/dmidecode-memory.txt|grep "Configured Clock Speed:"|tail -1|sed -r 's/.* ([0-9]*) .*/\1/')"


	### FIXME: Would like to get config (e.g. 2 x 2GB DDR3 Samsung Modules 1600Mhz)
	#FAHT_MEM_CONFIG=
	#while [ j -le "$(cat $FAHT_WORKINGDIR/lshw-memory|grep bank|sed 's/[^0-9]*//'|tail -1)" ]; do
	#
	#done

	FAHT_PROC_THREADS="$(( $FAHT_CORE_COUNT * $FAHT_CORE_THREAD ))"
	FAHT_CPU_MODEL="$(cat /proc/cpuinfo|grep -i -m 1 "model name"|sed -r 's/model name.*: (.*)/\1/g'|sed -n 's/  */ /gp')"
	FAHT_PROC_SPEED="$(bc <<< "scale=1; $(cat $FAHT_WORKINGDIR/lshw-processor.txt|grep capacity|tail -1|sed 's/[^0-9]*//g') / 1000")"
	#FAHT_PROC_SPEED="$(bc <<< "scale=1; $FAHT_PROC_SPEED_MHZ/1000")"
	FAHT_BATT_DESIGN_CAPACITY="$(cat $FAHT_WORKINGDIR/acpi.txt|tail-1|sed -r 's/.*design capacity ([0-9]*).*/\1/')"
	FAHT_BATT_CURR_CAPACITY="$(cat $FAHT_WORKINGDIR/acpi.txt|tail -1|sed -r 's/.*full capacity ([0-9]*).*/\1/')"
	FAHT_BATT_HEALTH="$(cat $FAHT_WORKINGDIR/acpi.txt|tail -1|sed -r 's/.*= ([0-9]*).*/\1/')"

	### Note block device where linux is currently mounted for using as an exception when listing hdds
	FAHT_LIVE_DEV="$(mount|grep " on / "|sed -n 's/^\/dev\/\(.*\)[0-9] on \/ .*/\1/gp')"
	j=1

	declare -A FAHT_SMART_DRIVES_ARRAY

	for i in $(echo "$(smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
		FAHT_SMART_DRIVES_ARRAY[$j]="$i"
		echo $j
		echo FAHT_SMART_DRIVES_ARRAY[$j] = ${FAHT_SMART_DRIVES_ARRAY[$j]}
		echo
		((j++));
	done

	echo Listing SMART capable drives...
	echo ----
	echo ${FAHT_SMART_DRIVES_ARRAY[@]}
	echo
	$DIAG
}

sysinfo_dump

disk_array_setup ()
{

	## Setting disks in array minus current OS disk
	FAHT_TEST_DISKS_ARRAY=()
	i=0
	j=
	for j in $(lsblk -n -r -o NAME|grep -v "$FAHT_LIVE_DEV"|grep -E -v "[0-9]"|grep -E "^[a-z]d[a-z]"); do
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
		
	declare -A FAHT_SMART_DRIVES_ARRAY

	for i in $(echo "$(smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
		FAHT_SMART_DRIVES_ARRAY[$j]="$i"
		echo $j
		echo FAHT_SMART_DRIVES_ARRAY[$j] = ${FAHT_SMART_DRIVES_ARRAY[$j]}
		echo
		((j++));
	done

		echo Drives with SMART capabilities:
		echo ${FAHT_SMART_DRIVES_ARRAY[@]}
		echo;
	else
		echo No drives are SMART capable. Skipping test...
		echo;
	fi

	$DIAG
}

#temp disk_array_setup

smartctl --info /dev/sda>$FAHT_WORKINGDIR/sda-info.txt

eth_test () {
	### Network test - Ethernet ###
	clear
	echo -------------------------------
	echo Testing Ethernet... Please wait
	echo -------------------------------
	$DIAG
	echo

	FAHT_ETH="$(ip -o link|grep -i -E ": en.* "\d*|sed -r 's/[0-9]: (en.*): .*/\1/g')"

	if [ $FAHT_ETH ]
	then
		for p in $FAHT_ETH; do
			ping -c 5 -I $p 1.1.1.1
			FAHT_ETH_RESULTS=$?
		done > $FAHT_WORKINGDIR/ethtest-$p.txt
	else
		$FAHT_ETH_RESULTS="N/A"
	fi

	if [ "$FAHT_ETH_RESULTS" -gt 0 ]
	then
		FAHT_ETH_RESULTS="FAILED"
	else
		FAHT_ETH_RESULTS="PASSED"
	fi
}

#temp eth_test

wifi_test () {
### Network test - Wireless ###
### FIXME: Doesn't fail gracefully. GET IT!
	echo -----------------------------
	echo Testing Wi-Fi.... Please wait
	echo -----------------------------
	$DIAG
	echo

	FAHT_WIFI="$(ip -o link|grep -i -E ": wl.* "\d*|sed -r 's/[0-9]: (wl.*): .*/\1/g')"

	if [ $FAHT_WIFI ]
	then
		for p in $FAHT_WIFI; do
			ping -c 5 -I $p 1.1.1.1
			FAHT_WIFI_RESULTS=$?
		done > $FAHT_WORKINGDIR/wifitest-$p.txt
	else
		$FAHT_WIFI_RESULTS="N/A"
	fi

	if [ "$FAHT_WIFI_RESULTS" -gt 0 ]
	then
		FAHT_WIFI_RESULTS="FAILED"
	else
		FAHT_WIFI_RESULTS="PASSED"
	fi
}

#temp wifi_test

audio_test ()
{
	### Audio test ###
	clear
	echo ----------------------------
	echo Testing Audio... Please wait
	echo ----------------------------
	$DIAG
	echo

	audio_test_complete=0

	while [[ "$audio_test_complete" -eq 0 ]]; do
	amixer -D pulse sset Master 100%

		for i in {1..3}; do
			mplayer /usr/share/faht/starcmd.m4a;
		done

		amixer -D pulse sset Master 40%

		confirm_prompt "Did you hear the test tone?"

		case $prompt_answer in
			y|Y) FAHT_AUDIO_RESULTS=PASSED ;;
			n|N) FAHT_AUDIO_RESULTS=FAILED ;;
		esac

		if [ "$FAHT_AUDIO_RESULTS" == "FAILED" ]
		then
			confirm_prompt "Were you even listening?"

			case $prompt_answer in
				y|Y) audio_test_complete=1 ;;
				n|N) ;;
			esac
		else
			audio_test_complete=1
		fi	
	done
}

#temp audio_test

smart_test ()
{
	### SMART Testing ###

	clear
	echo --------------------------------
	echo Testing Hard Drives. Please wait
	echo --------------------------------
	$DIAG
	echo

	FAHT_DISK_NO=1

	echo Listing SMART capable drives...
	echo ${FAHT_SMART_DRIVES_ARRAY[1]}
	echo
	echo ${FAHT_SMART_DRIVES_ARRAY[@]}
	$DIAG
	for curr_smart_dev in ${FAHT_SMART_DRIVES_ARRAY[*]}; do

		echo Beginning SMART short test on "$curr_smart_dev"
		smartctl -t force -t short /dev/$curr_smart_dev>$FAHT_WORKINGDIR/smartshorttest-$curr_smart_dev.txt
		cat $FAHT_WORKINGDIR/smartshorttest-$curr_smart_dev.txt
		smart_short_test_max_minutes=$(cat $FAHT_WORKINGDIR/smartshorttest-$curr_smart_dev.txt|grep "Please wait"|sed 's/[^0-9]*//g')

		echo
		echo -en "\r$smart_short_test_max_minutes mins remaining"
		j=9999

		while [ "$j" -lt "$smart_short_test_max_minutes" ]; do		
			sleep 60
			time_remaining=$(( $smart_short_test_max_minutes - $j ))
			echo -en "\r$time_remaining mins remaining"
			smartctl -l selftest /dev/"$curr_smart_dev"|grep "# 1"|grep "failure"

			if [ $? -eq 0 ]; then
				j=9999
			else
				let j=j+1;
			fi
		done
		
		echo
		echo Short SMART test done.
		echo

		smartctl -x /dev/"$curr_smart_dev">"$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
		echo
		cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
		echo

		### Present hours on in human readable way... ###

		FAHT_DISK1_TIME_ON_HOURS=$(sudo smartctl -a /dev/$curr_smart_dev |grep "Power_On_Hours"|awk '{print $10}')

		declare -A FAHT_DISK1_TIME_ON_ARRAY

		if [[ FAHT_DISK1_TIME_ON_HOURS -gt 0 ]]; then

			declare -A FAHT_HOURS

			FAHT_HOURS[DAYS]=24
			FAHT_HOURS[MONTHS]=720
			FAHT_HOURS[YEARS]=8760

			echo ${FAHT_HOURS[DAYS]}
			echo ${FAHT_HOURS[MONTHS]}
			echo ${FAHT_HOURS[YEARS]}

			let FAHT_HOURS_REMAINING=FAHT_DISK1_TIME_ON_HOURS

			for i in YEARS MONTHS DAYS; do

				let FAHT_DISK1_TIME_ON_ARRAY[$i]=$FAHT_DISK1_TIME_ON_HOURS/${FAHT_HOURS[$i]}
				echo $(((FAHT_DISK1_TIME_ON_HOURS%FAHT_HOURS[$i])))
				let FAHT_DISK1_TIME_ON_HOURS=$FAHT_DISK1_TIME_ON_HOURS%${FAHT_HOURS[$i]}

			done

			FAHT_DISK1_TIME_ON_ARRAY[HOURS]=$FAHT_DISK1_TIME_ON_HOURS

			echo
			echo Printing TIME ON
			FAHT_DISK1_TIME_ON="$(for i in YEARS MONTHS DAYS HOURS; do if [[ "${FAHT_DISK1_TIME_ON_ARRAY[$i]}" -gt "0" ]]; then printf "${FAHT_DISK1_TIME_ON_ARRAY[$i]} $i "; fi; done)"
			
			### Trim trailing whitespace...
			FAHT_DISK1_TIME_ON=$(echo $FAHT_DISK1_TIME_ON)
			echo $FAHT_DISK1_TIME_ON
			echo

			$DIAG
		fi	

		if [ "$FAHT_SHORTONLY" != "true" ]; then
			echo Beginning SMART long test on $curr_smart_dev

			smartctl -t force -t long /dev/"$curr_smart_dev">"$FAHT_WORKINGDIR"/smartlongtest-"$curr_smart_dev".txt

			cat "$FAHT_WORKINGDIR"/smartlongtest-"$curr_smart_dev".txt
			smart_long_test_max_minutes=$(cat $FAHT_WORKINGDIR/smartlongtest-$curr_smart_dev.txt|grep "Please wait"|sed 's/[^0-9]*//g')

			echo
			echo -en "\r$smart_long_test_max_minutes mins remaining"
			
			j=0
			
			while [ "$j" -lt "$smart_long_test_max_minutes"  ]; do
				sleep 60
				time_remaining=$(( $smart_long_test_max_minutes - $j ))
				echo -en "\r$time_remaining mins remaining"

				smartctl -l selftest /dev/"$curr_smart_dev"|grep "# 1"|grep "failure"

				if [ $? -eq 0 ]; then
					j=9999
				else
					let j=j+1;
				fi
			done

			echo
			echo Long SMART test done.
			echo

		fi

		smartctl -x /dev/"$curr_smart_dev">"$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
		echo
		cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
		echo

		echo Long test result: "$(cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt|grep "# 1")"
		SMART_PASSED=$(cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt|grep "# 1"|sed -r 's/.*(Completed without error).*/\1/')

		if [ "$SMART_PASSED" == "Completed without error" ]; then
			FAHT_DISK1_ASSESSMENT_RESULTS=PASSED;
		else
			FAHT_DISK1_ASSESSMENT_RESULTS=FAILED;
		fi

		$DIAG

	done
}

### Appears to get reset with function declaration...

	declare -A FAHT_SMART_DRIVES_ARRAY

	for i in $(echo "$(smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
		FAHT_SMART_DRIVES_ARRAY[$j]="$i"
		echo $j
		echo FAHT_SMART_DRIVES_ARRAY[$j] = ${FAHT_SMART_DRIVES_ARRAY[$j]}
		echo
		((j++));
	done


smart_test

gfx_test ()
{
### GFX Benchmark ###
clear
echo -------------------------------
echo Testing GFX card... Please wait
echo -------------------------------
$DIAG
echo

glmark2|grep Score>"$FAHT_WORKINGDIR"/glmark2.txt

FAHT_GFX_BENCH="$(cat "$FAHT_WORKINGDIR"/glmark2.txt|sed -r 's/.*: ([0-9]*) /\1/g')"
}

#temp gfx_test

( set -o posix; set ) | grep FAHT > "$FAHT_WORKINGDIR"/vars.txt

save_vars ()
{
	( set -o posix; set ) | grep FAHT > /tmp/vars.txt
	cat /tmp/vars.txt|grep -v ARRAY > /tmp/vars_noarray.txt

	sed -r 's/(FAHT_.*)=.*/\1/g' /tmp/vars_noarray.txt > /tmp/varsnames.txt
	sed -r 's/.*=(.*)/\1/g' /tmp/vars_noarray.txt > /tmp/varsvalues.txt


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

	cp /usr/share/faht/faht-report-template.fodt "$FAHT_WORKINGDIR"/faht-report.fodt

	for x in ${varsNames[*]}; do
		echo "Working on $x..."
		sed -i "s|\[\[$x\]\]|${varsValues[$i]}|g" "$FAHT_WORKINGDIR"/faht-report.fodt
		(( i++ ));
	done

	cp /tmp/vars*.txt "$FAHT_WORKINGDIR"/
}

save_vars

chown -Rfv $FAHT_CURR_USER:$FAHT_CURR_USER "$FAHT_WORKINGDIR"

cat "$FAHT_WORKINGDIR"/vars.txt

echo -e "All Done!\n"
