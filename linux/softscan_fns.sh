#!/bin/bash

### Functions to scan for malware, rootkits, or other undesirables on Windows system drive ###
### Requires disks-fns.sh ###

virus_scan () {

	if [ "${FAHT_CLAMAV}" == "true" ] ; then

		if [ "${FAHT_QUICKMODE}" =="true" ]; then

			echo "------------------------------------------------------"
			echo "Scanning for viruses, malware, and PUPs (QUICKMODE)..."
			echo "------------------------------------------------------"
			echo

			echo Mounting volumes to scan....
			echo
			mount_avail_volumes

			echo
			echo Beginning scan...
			clamscan --bell -irl "${FAHT_WORKINGDIR}/clamscan.txt" /mnt/faht/*
		fi
		
		if [ "${FAHT_QUICKMODE}" != "true" ] ; then

			echo "------------------------------------------"
			echo "Scanning for viruses, malware, and PUPs..."
			echo "------------------------------------------"
			echo

			echo Mounting volumes to scan....
			echo
			mount_avail_volumes

			for curr_dir in "Windows Users" ; do
				echo
				echo Beginning scani of ${curr_dir}...
				clamscan --bell -irl "${FAHT_WORKINGDIR}/clamscan-${curr_dir}.txt" /mnt/faht/${FAHT_WIN_PART}/${curr_dir}/
			done
			echo
		fi
	fi
}
