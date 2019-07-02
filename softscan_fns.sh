#!/bin/bash

### Functions to scan for malware, rootkits, or other undesirables on Windows system drive ###
### Requires disks-fns.sh ###

virus_scan () {

	echo "------------------------------------------"
	echo "Scanning for viruses, malware, and PUPs..."
	echo "------------------------------------------"
	echo

	echo Mounting volumes to scan....
	echo
	mount_avail_volumes

	echo
	echo Begnning scan...
	clamscan --bell --detect-pua=yes -irl "${FAHT_WORKINGDIR}/clamscan.txt" /mnt/faht/*
}
