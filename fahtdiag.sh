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
FAHT_TIMEON_THRESHOLD=26280
declare -A FAHT_FORM_ARRAY=( [FAHT_FULLNAME]="" [FAHT_PROBLEMS]="" [FAHT_NOTES]="" [FAHT_PHYSICAL_NOTES]="" [FAHT_COMPUTER_TYPE]="" [FAHT_ASSESSMENT_RESULTS]="" [FAHT_NOTES]="" )

if [ "$FAHT_DIAGMODE" == "true" ]; then
	clear
	set -x
	echo DIAG MODE ACTIVATED!!!!!!!!
	###TEMP DIAG=break_program;
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

    ### temp	hardinfo -r -f text>"$FAHT_WORKINGDIR"/hardinfo.txt

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
	FAHT_BATT_DESIGN_CAPACITY="$(cat $FAHT_WORKINGDIR/acpi.txt|tail -1|sed -r 's/.*design capacity ([0-9]*).*/\1/')"
	FAHT_BATT_CURR_CAPACITY="$(cat $FAHT_WORKINGDIR/acpi.txt|tail -1|sed -r 's/.*full capacity ([0-9]*).*/\1/')"
	FAHT_BATT_HEALTH="$(cat $FAHT_WORKINGDIR/acpi.txt|tail -1|sed -r 's/.*= ([0-9]*).*/\1/')"

	### Note block device where linux is currently mounted for using as an exception when listing hdds
	FAHT_LIVE_DEV="$(mount|grep " on / "|sed -n 's/^\/dev\/\(.*\)[0-9] on \/ .*/\1/gp')"
	j=1

	$DIAG
}

sysinfo_dump

source disks_fns.sh

echo Setting up local disk arrays...
disk_array_setup
echo
echo Mounting avialable volumes...
mount_avail_volumes
echo
echo Searching for Windows system volumts...
find_win_part
echo
#echo Benchmarking disks
#benchmark_disks
echo Running SMART Assessments...
smart_test
echo
echo Listing disk information...
echo
list_disks_info
echo

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



### Appears to get reset with function declaration...

#	declare -A FAHT_SMART_DRIVES_ARRAY

#	for i in $(echo "$(smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
#		FAHT_SMART_DRIVES_ARRAY[$j]="$i"
#		echo $j
#		echo FAHT_SMART_DRIVES_ARRAY[$j] = ${FAHT_SMART_DRIVES_ARRAY[$j]}
#		echo
#		((j++));
#	done

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

save_vars ()
{
	( set -o posix; set ) | grep FAHT > "$FAHT_WORKINGDIR"/vars.txt

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

#save_vars

chown -Rf $FAHT_CURR_USER:$FAHT_CURR_USER "$FAHT_WORKINGDIR"

#cat "$FAHT_WORKINGDIR"/vars.txt

echo -e "All Done!\n"
