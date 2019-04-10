#!/bin/bash

####### TechTutors Diag Script ########
####### For internal use only! ########

FIRSTNAME=
LASTNAME=
CONFIRM=n
CLIENTNAME=
DATE=`date +%Y-%m-%d-%H`

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

CLIENTNAME=$LASTNAME-$FIRSTNAME

echo -e "Client: $CLIENTNAME\n"

ttdiaglog=/home/techtutors/log/diag-$CLIENTNAME-$DATE.txt

for p in `ip -o link | grep -E en\d* | sed -e 's/[0-9]: \(en.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>$ttdiaglog.txt

for p in `ip -o link | grep -E wl\d* | sed -e 's/[0-9]: \(wl.*\): .*/\1/'`; do ping -c 5 -I $p www.google.ca; done>>$ttdiaglog.txt

echo -e "All Done!\n"
