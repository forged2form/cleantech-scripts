#!/bin/bash

####### TechTutors Diag Script ########
####### For internal use only! ########


### Init variables ###
FAHT_FIRSTNAME=Darling
FAHT_LASTNAME=Ryan
FAHT_CONFIRM=n
FAHT_CLIENTNAME=$FAHT_LASTNAME-$FAHT_FIRSTNAME
FAHT_DATE=`date +%Y-%m-%d-%H`
FAHT_WORKINGDIR=/home/techtutors/fahttest/$FAHT_CLIENTNAME-$FAHT_DATE
FAHT_AUDIO=

### Prep client folder ###
mkdir $FAHT_WORKINGDIR

### Grab summary info for summary sheet ###
FAHT_MACHINE=$(dmidecode|grep -i "Product Name:"|sed 's/.*Product Name: //')
FAHT_CORE_COUNT=$(dmidecode|grep -i "Socket Designation: CPU "|sed 's/[^0-9]*//g'|tail -1)
FAHT_CORE_COUNT=$(($FAHT_CORE_COUNT +1))
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

### Dump systeminfo ###
modprobe eeprom
lshw>$FAHT_WORKINGDIR/lshw.txt
dmidecode > $FAHT_WORKINGDIR/dmidecode.txt
lscpu>$FAHT_WORKDIT/lscpu.txt
smartctl -x /dev/sda>$FAHT_WORKINGDIR/smartctl-sda.txt
acpi -i>$FAHT_WORKINGDIR/battery.txt
hardinfo -r -f text>$FAHT_WORKINGDIR/hardinfo.txt
smartctl --info /dev/sda>$FAHT_WORKINGDIR/sda-info.txt

clear
echo -e "---------------------------"
echo -e "TechTutor's Diag Script"
echo -e "--------------------------- \n"

while true; do
	echo -e "First Name: \c "
	read FIRSTNAME

	echo -e "Last Name: \c "
	read LASTNAME

	echo -e "You entered \e[1m$FIRSTNAME $LASTNAME\e[0m. Is this correct? [Y/n] \c "
	read -n1 CONFIRM
	: ${CONFIRM:=y}
	echo

	case ${CONFIRM,,} in
		y|Y) break;;
		*) echo -e "Please retry... \n";;
	esac
done

CONFIRM=

### Old stuff.. Keep for now...

# CLIENTNAME=$LASTNAME-$FIRSTNAME

# echo -e "Client: $CLIENTNAME\n"

# ttdiaglog=/home/techtutors/log/diag-$CLIENTNAME-$DATE.txt

### Network test - Ethernet ###
clear
echo -------------------------------
echo Testing Ethernet... Please wait
echo -------------------------------
echo
for p in `ip -o link | grep -i -E en\d* | sed -e 's/[0-9]: \(en.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$FAHT_WORKINGDIR/ethtest.txt

### Network test - Wireless ###
echo -----------------------------
echo Testing Wi-Fi.... Please wait
echo -----------------------------
echo
for p in `ip -o link | grep -i -E wl\d* | sed -e 's/[0-9]: \(wl.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$FAHT_WORKINGDIR/wifitest.txt


### Audio test ###
clear
echo ----------------------------
echo Testing Audio... Please wait
echo ----------------------------
echo
speaker-test -t sine -f 1000 -l 1

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

### GFX Benchmark ###
clear
echo -------------------------------
echo Testing GFX card... Please wait
echo -------------------------------
echo
$FAHT_GFX_BENCH=$(glmark2 |grep -I score:)

( set -o posix; set ) | grep FAHT > $FAHT_WORKINGDIR/vars.txt

echo -e "All Done!\n"
