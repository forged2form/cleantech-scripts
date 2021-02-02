#!/bin/bash

### Functions to scan for malware, viruses, or other undesirables on Windows system drive ###
### Requires disks-fns.sh ###

virus_scan () {

	if [ "${FAHT_CLAMAV}" == "ON" ] && [ "${FAHT_QUICKMODE}" != "ON" ] && [ "${FAHT_SYSDRIVE_HEALTH}" == "PASSED" ]; then

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
			echo
			echo NOTE: If this hangs, or if you want to continue FAHT
			echo and cancel this process, open another terminal and
			echo run the command: sudo killall clamscan
			echo
			sudo clamscan --bell -irl "${FAHT_WORKINGDIR}/clamscan-${curr_dir}.txt" /mnt/faht/${FAHT_WIN_PART}/${curr_dir}/
			FAHT_CLAMSCAN_RESULTS="$(echo $?)"

			if [ "$FAHT_CLAMSCAN_RESULTS" eq 1 ] ; then
				FAHT_PUPS="PUPs DETECTED!!!"
				echo "$FAHT_PUPS"
				FAHT_PUPS_RESULTS="FAILED"
			fi
			
			if [ "$FAHT_CLAMSCAN_RESULTS" eq 0 ]  && [ "${FAHT_PUPS_RESULTS}" !="FAILED" ]; then
				FAHT_PUPS="No PUPs detected."
				echo "$FAHT_PUPS"
				FAHT_PUPS_RESULTS="PASSED"
			fi
		done
		echo

	else
		echo "ClamAV option not set! Skipping..."
	fi
}
