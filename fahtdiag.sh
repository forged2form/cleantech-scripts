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

source io.sh
source hw_tests.sh

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

### Init vars
FAHT_CURR_USER=$(head -n 1 /tmp/fahtdiaguser)
FAHT_FIRSTNAME=
FAHT_LASTNAME=
FAHT_FULLNAME=
CONFIRM=n
FAHT_AUDIO=
FAHT_AUDIO_RESULTS="n/a"
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
FAHT_GFX_STRESS_TETS_RESULTS="n/a"
FAHT_BLUETOOTH_RESULTS="n/a"
FAHT_PORTS_RESULTS="n/a"
FAHT_GFX_STRESS_TEST="n/a"
FAHT_GFX_STRESS_TEST_RESULTS="n/a"
FAHT_PROC_STRESS_TEST="n/a"
FAHT_PROC_STRESS_TEST_RESULTS="n/a"
FAHT_DISPLAY_TEST_RESULTS="n/a"
FAHT_DISPLAY_TEST=""
FAHT_POWER_RESULTS="n/a"
FAHT_ASSESSMENT_RESULTS=""

declare -A FAHT_FORM_ARRAY=( [FAHT_FULLNAME]="" [FAHT_PROBLEMS]="" [FAHT_NOTES]="" [FAHT_PHYSICAL_NOTES]="" [FAHT_COMPUTER_TYPE]="" [FAHT_ASSESSMENT_RESULTS]="" [FAHT_NOTES]="" )

if [ "$FAHT_DIAGMODE" == "true" ]; then
	clear
	set -x
	echo DIAG MODE ACTIVATED!!!!!!!!
	###TEMP DIAG=break_program;
fi
### Get basic system id for faht folder ###

lshw -c system>/tmp/fs.txt

FAHT_COMP_TYPE=$(cat /tmp/fs.txt|grep description|sed 's/.*description: \([A-z]+\)/\1/')
FAHT_COMP_VENDOR=$(cat /tmp/fs.txt|grep vendor|head -1|sed 's/.*vendor: //')
FAHT_COMPUTER_SERIAL=$(cat /tmp/fs.txt|grep serial|sed 's/.*serial: //')
FAHT_COMP_DESC="$FAHT_COMP_VENDOR-$FAHT_COMP_TYPE-$FAHT_COMPUTER_SERIAL"

client_details

FAHT_FULLNAME="$FAHT_FIRSTNAME $FAHT_LASTNAME"

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
		dmidecode -t $i >"$FAHT_WORKINGDIR"/dmidecode-$i.txt;
	done

	lscpu>"$FAHT_WORKINGDIR"/lscpu.txt

	### Not sure if we'll ever use this since it just grabs a whole bunch of info from (mostly) commands that we will run, but dumping it for potentially future use...

    ### temp	hardinfo -r -f text>"$FAHT_WORKINGDIR"/hardinfo.txt

	### Grab summary info for summary sheet ###

	FAHT_COMPUTER_DESC="$(cat "$FAHT_WORKINGDIR"/lshw-system.txt|grep product|sed -r 's/.*product: (.*) \(.*/\1/')"
	FAHT_COMPUTER_DESC="$(echo $FAHT_COMPUTER_DESC)"
	FAHT_PROC_MODEL="$(cat "$FAHT_WORKINGDIR"/lshw-processor.txt|grep product|sed 's/.*product: //')"
	FAHT_SOCKET_COUNT="$(cat "$FAHT_WORKINGDIR"/lscpu.txt|grep -i "Socket(s):"|sed 's/[^0-9]*//g')"
	FAHT_CORE_COUNT="$(( $(cat "$FAHT_WORKINGDIR"/lscpu.txt|egrep -i -m 1 ".*core.*socket*"|sed 's/[^0-9]*//g') * $FAHT_SOCKET_COUNT ))"
	FAHT_PROC_CORES="$(( $FAHT_CORE_COUNT * FAHT_SOCKET_COUNT ))"
	if [[ "${FAHT_PROC_CORES}" -le "2" ]]; then
		FAHT_PROC_CORES_RESULTS="FAILED"
	fi
	if [[ "${FAHT_PROC_CORES}" -ge "2" ]]; then
		FAHT_PROC_CORES_RESULTS="PASSED"
	fi
	FAHT_MEM_CONFIG="n/a"
	FAHT_MEM_TEST="n/a"
	FAHT_MEM_TEST_RESULTS="n/a"
	FAHT_CORE_THREAD="$(cat "$FAHT_WORKINGDIR"/lscpu.txt|egrep -i -m 1 ".*Thread.*core*"|sed 's/[^0-9]*//g')"
	FAHT_MAX_MEMORY="$(cat "$FAHT_WORKINGDIR"/dmidecode-memory.txt|grep -i -m 1 "Maximum Capacity:"|sed 's/[^0-9]*//g')"
	FAHT_MEM_SIZE="$(cat "$FAHT_WORKINGDIR"/lshw-memory.txt |awk '/*-memory/,/*-bank:0/'|grep size|sed -r 's/.*size: ([0-9]+).*/\1/g')"

	if [[ "${FAHT_MEM_SIZE}" -le "4" ]]; then
		FAHT_MEM_SIZE_RESULTS="FAILED"
	fi
	if [[ "${FAHT_MEM_SIZE}" -ge "8" ]]; then
		FAHT_MEM_SIZE_RESULTS="PASSED"
	fi
	if [ "${FAHT_MEM_SIZE}" -ge "6" ] && [ "${FAHT_MEM_SIZE}" -lt "8" ]; then
		FAHT_MEM_SIZE_RESULTS="WARNING"
	fi

	FAHT_MEM_SIZE="${FAHT_MEM_SIZE} GB"

	FAHT_MEM_TYPE="$(cat "$FAHT_WORKINGDIR"/dmidecode-memory.txt|grep DDR|tail -1|sed -r 's/.*(DDR[1-6].*).*/\1/')"
	###FIXME: Cheating on fixing the whitespace for now...
	FAHT_MEM_TYPE="$(echo $FAHT_MEM_TYPE)"
	FAHT_MEM_SPEED="$(cat "$FAHT_WORKINGDIR"/dmidecode-memory.txt|grep "Configured Clock Speed:"|tail -1|sed -r 's/.* ([0-9]*) .*/\1/')"

	### FIXME: Would like to get config (e.g. 2 x 2GB DDR3 Samsung Modules 1600Mhz)
	#FAHT_MEM_CONFIG=
	#while [ j -le "$(cat $FAHT_WORKINGDIR/lshw-memory|grep bank|sed 's/[^0-9]*//'|tail -1)" ]; do
	#
	#done

	FAHT_PROC_THREADS="$(( $FAHT_CORE_COUNT * $FAHT_CORE_THREAD ))"
	if [[ "${FAHT_PROC_THREADS}" -le "2" ]]; then
		FAHT_PROC_THREADS_RESULTS="FAILED"
	fi
	if [[ "${FAHT_PROC_THREADS}" -ge "2" ]]; then
		FAHT_PROC_THREADS_RESULTS="PASSED"
	fi
	FAHT_CPU_MODEL="$(cat /proc/cpuinfo|grep -i -m 1 "model name"|sed -r 's/model name.*: (.*)/\1/g'|sed -n 's/  */ /gp')"
	FAHT_PROC_SPEED_MHZ="$(cat $FAHT_WORKINGDIR/dmidecode-processor.txt|grep "Current Speed"|sed 's/[^0-9*]//g')"
	if [[ "${FAHT_PROC_SPEED_MHZ}" -lt "1600" ]]; then
		FAHT_PROC_SPEED_RESULTS="FAILED"
	fi
	if [[ "${FAHT_PROC_SPEED_MHZ}" -ge "1600" ]]; then
		FAHT_PROC_SPEED_RESULTS="PASSED"
	fi

	FAHT_PROC_SPEED="$(echo "scale=2;$FAHT_PROC_SPEED_MHZ/1000"|bc)"

	acpi -i>"$FAHT_WORKINGDIR"/acpi.txt

	FAHT_BATT_DESIGN_CAPACITY="$(cat "$FAHT_WORKINGDIR"/acpi.txt|tail -1|sed -r 's/.*design capacity ([0-9]*).*/\1/') mAh"
	FAHT_BATT_CURR_CAPACITY="$(cat "$FAHT_WORKINGDIR"/acpi.txt|tail -1|sed -r 's/.*full capacity ([0-9]*).*/\1/') mAh"
	FAHT_BATT_HEALTH="$(cat "$FAHT_WORKINGDIR"/acpi.txt|tail -1|sed -r 's/.*= ([0-9]*).*/\1/')"
	
	if [[ "$FAHT_BATT_HEALTH" -ge "70" ]]; then
		FAHT_BATT_HEALTH_RESULTS="PASSED"
	else
		FAHT_BATT_HEALTH_RESULTS="FAILED"
	fi
	FAHT_BATT_HEALTH="${FAHT_BATT_HEALTH} %"

	if [ "$(cat "$FAHT_WORKINGDIR"/acpi.txt)" == "" ]; then
		FAHT_BATT_HEALTH_RESULTS="n/a"
		FAHT_BATT_DESIGN_CAPACITY="n/a"
		FAHT_BATT_CURR_CAPACITY="n/a"
		FAHT_BATT_HEALTH="n/a"
	fi

	### Note block device where linux is currently mounted for using as an exception when listing hdds
	FAHT_LIVE_DEV="$(mount|grep " on / "|sed -n 's/^\/dev\/\(.*\)[0-9] on \/ .*/\1/gp')"
	j=1

	$DIAG
}

sysinfo_dump

: echo "Testing ethernet connection..."
eth_test

: echo "Testing Wi-Fi connection..."
wifi_test

: echo "Testing Audio..."
audio_test

: echo "Testing GFX..."
gfx_test
echo

source disks_fns.sh

: echo "Setting up local disk arrays..."
disk_array_setup
echo

: echo "Mounting avialable volumes..."
mount_avail_volumes
echo

: echo "Searching for Windows system volumts..."
find_win_part
echo

### NOTE: Must run SMART Assessments first, otherwise write benchmark willbe skipped.
: echo "Running SMART Assessments..."
smart_test
echo

: echo "Benchmarking disks"
benchmark_disks
echo

: echo "Listing disk information..."
echo

list_disks_info
echo

echo !!! Almost done !!!
confirm_prompt "Did you notice any power issues during the test?"

case $prompt_answer in
	y|Y) FAHT_POWER_RESULTS=FAILED ;;
	n|N) FAHT_POWER_RESULTS=PASSED ;;
esac

source parsing_fns.sh

save_vars

chown -Rf $FAHT_CURR_USER:$FAHT_CURR_USER "$FAHT_WORKINGDIR"

echo -e "All Done!\n"
echo
echo Opening faht-report.fodt
soffice "${FAHT_WORKINGDIR}/faht-report.fodt"
