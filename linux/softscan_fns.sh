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

			FAHT_CLAMSCAN_RESULTS="$(echo $?)"

			if [ "$FAHT_CLAMSCAN_RESULTS" eq "1" ] ; then
				FAHT_PUPS="ALERT!!! MALICIOUS SOFTWARE DETECTED!!!i"
				echo "$FAHT_PUPS"
				FAHT_PUPS_RESULTS="FAILED"
			fi
			
			if [ "$FAHT_CLAMSCAN_RESULTS" eq "0" ]  && [ "${FAHT_PUPS_RESULTS}" !="FAILED" ]; then
				FAHT_PUPS="No malicious software detected."
				echo "$FAHT_PUPS"
				FAHT_PUPS_RESULTS="PASSED"
			fi
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
				FAHT_CLAMSCAN_RESULTS="$(echo $?)"

				if [ "$FAHT_CLAMSCAN_RESULTS" eq "1" ] ; then
					FAHT_PUPS="ALERT!!! MALICIOUS SOFTWARE DETECTED!!!i"
					echo "$FAHT_PUPS"
					FAHT_PUPS_RESULTS="FAILED"
				fi
				
				if [ "$FAHT_CLAMSCAN_RESULTS" eq "0" ]  && [ "${FAHT_PUPS_RESULTS}" !="FAILED" ]; then
					FAHT_PUPS="No malicious software detected."
					echo "$FAHT_PUPS"
					FAHT_PUPS_RESULTS="PASSED"
				fi
			done
			echo
		fi
	fi
}
