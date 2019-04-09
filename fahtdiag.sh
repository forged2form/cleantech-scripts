#!/bin/bash

####### TechTutors Diag Script ########
####### For internal use only! ########

FAHT_FIRSTNAME=
FAHT_LASTNAME=
FAHT_CONFIRM=n
FAHT_CLIENTNAME=
FAHT_DATE=`date +%Y-%m-%d-%H`
FAHT_WORKINGDIR=/home/$(whoami)
FAHT_MACHINE=$(dmidecode|grep "Product Name:"|sed 's/.*Product Name: //')
FAHT_CORE_COUNT=$(dmidecode|grep "Socket Designation: CPU "|sed 's/[^0-9]*//g'|tail -1)
FAHT_CORE_COUNT=$(($FAHT_CORE_COUNT +1))
FAHT_CORE_THREAD=$(dmidecode|grep -m 1 "Thread Count:"|sed 's/[^0-9]*//g')
FAHT_MEMORY_GB=$(dmidecode|grep -m 1 "Maximum Capacity:"|sed 's/[^0-9]*//g')
FAHT_TOTAL_THREADS=$(($FAHT_CORE_COUNT * $FAHT_CORE_THREAD))
FAHT_CPU_MODEL=$(cat /proc/cpuinfo|grep -m 1 "model name"|sed -r 's/model name.*: (.*)/\1/g'|sed -n 's/  */ /gp')

### Note block device where linux is currently mounted for using as an exception when listing hdds
FAHT_LIVE_DEV=$(mount|grep "on / "|sed -n 's/^\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')

set -o posix ;set|grep FAHT|less
#>$FAHT_WORKINGDIR/sysinfo.txt

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

while

CLIENTNAME=$LASTNAME-$FIRSTNAME

echo -e "Client: $CLIENTNAME\n"

ttdiaglog=/home/techtutors/log/diag-$CLIENTNAME-$DATE.txt

for p in `ip -o link | grep -E en\d* | sed -e 's/[0-9]: \(en.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$ttdiaglog.txt

for p in `ip -o link | grep -E wl\d* | sed -e 's/[0-9]: \(wl.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>>$ttdiaglog.txt

echo -e "All Done!\n"
