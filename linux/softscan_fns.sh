#!/bin/bash

### Functions to scan for malware, rootkits, or other undesirables on Windows system drive ###
### Requires disks-fns.sh ###

virus_scan () {

	if [ "${FAHT_CLAMAV}" == "ON" ] ; then

		if [ "${FAHT_QUICKMODE}" == "OFF" ]; then


			echo Mounting volumes to scan....
			echo
			mount_avail_volumes

			echo "------------------------------------------------------"
			echo "Scanning for viruses, malware, and PUPs (QUICKMODE)..."
			echo "------------------------------------------------------"
			echo

			echo
			echo Beginning scan...
			sudo clamscan --bell -irl "${FAHT_WORKINGDIR}/clamscan.txt" /mnt/faht/*

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
		
		if [ "${FAHT_QUICKMODE}" == "ON" ] ; then

			echo Mounting volumes to scan....
			echo
			mount_avail_volumes

			echo "------------------------------------------"
			echo "Scanning for viruses, malware, and PUPs..."
			echo "------------------------------------------"
			echo

			for curr_dir in Users ; do
				echo
				echo Beginning scan of ${curr_dir}...
				sudo clamscan --bell -irl "${FAHT_WORKINGDIR}/clamscan-${curr_dir}.txt" /mnt/faht/${FAHT_WIN_PART}/${curr_dir}/
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
	else
		"ClamAV option not set! Skipping..."
	fi
}
