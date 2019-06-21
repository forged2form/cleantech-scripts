#!/bin/bash

### init vars so they are global and retain values when used in functions...
FAHT_TOTAL_TEST_DISKS=0
### Put disks in array minus current OS disk
declare -A FAHT_TEST_DISKS_ARRAY
i=1
j=
for j in $(lsblk -n -r -o NAME|grep -v "$FAHT_LIVE_DEV"|grep -E -v "[0-9]"|grep -E "^[a-z]d[a-z]"); do
	DISKNO=Disk${i}
	FAHT_TOTAL_TEST_DISKS=$i
	FAHT_TEST_DISKS_ARRAY[$i]=$j	
	((i++));
done

i=1
for j in ${FAHT_TEST_DISKS_ARRAY[@]}; do
	#Create arrays outside nested loops for more global (?) scope...
	declare -A FAHT_TEST_DISK_${i}_ARRAY
	declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY
	(( i++ ));
done
FAHT_DISK_BENCH_VOL=

disk_array_setup ()
{
	###TEMP echo Number of Disks to test: $FAHT_TOTAL_TEST_DISKS
	i=1
	for j in ${FAHT_TEST_DISKS_ARRAY[@]}; do
	###TEMP 	echo Disk ${i}: ${j}
		(( i++ ));
	done

	# Set up individual disk arrays with partitions...
	i=1
	j=
	for j in ${FAHT_TEST_DISKS_ARRAY[@]}; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY
			
		CURR_FAHT_DISK_ARRAY[deviceid]=$j
		for stat in serial model vendor; do
			CURR_FAHT_DISK_ARRAY[$stat]=$(lsblk -dno $stat /dev/$j);
		done
		CURR_FAHT_DISK_ARRAY[name]="${CURR_FAHT_DISK_ARRAY[vendor]} ${CURR_FAHT_DISK_ARRAY[model]}"

		### Trim whitespace...
		CURR_FAHT_DISK_ARRAY[name]=$(echo ${CURR_FAHT_DISK_ARRAY[name]})

		###TEMP echo Working on Disk ${i}: ${CURR_FAHT_DISK_ARRAY[deviceid]}
		###TEMP echo


		CURR_FAHT_DISK_ARRAY[totalsize_results]="n/a"

		CURR_FAHT_DISK_ARRAY[totalsize]=$(lsblk -drno SIZE /dev/$j)

		CURR_FAHT_DISK_ARRAY[totalsize_bytes]="$(lsblk -drnbo SIZE /dev/$j)"

		if [[ "${CURR_FAHT_DISK_ARRAY[totalsize_bytes]}" -ge "12800000000" ]]; then
			CURR_FAHT_DISK_ARRAY[totalsize_results]=PASSED
		else
			CURR_FAHT_DISK_ARRAY[totalsize_results]=FAILED
		fi

		pn=1
		for p in $(lsblk -n -r -o NAME|grep "${CURR_FAHT_DISK_ARRAY[deviceid]}[0-9]"); do
			CURR_FAHT_DISK_ARRAY[part${pn}]=${p}
			CURR_FAHT_DISK_ARRAY[totalparts]=${pn}
			###TEMP echo Partition detected: ${CURR_FAHT_DISK_ARRAY[part${pn}]}
			(( pn++ ));
		done
		(( i++ ));
	done

	###TEMP echo Potential partitions to use for benchmarking:
	###TEMP echo
	i=1
	q=1

	echo Searching disks for paritions...
	echo --------------------------------
	while [[ "$i" -le "$FAHT_TOTAL_TEST_DISKS" ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY
		echo From Disk $i \(${CURR_FAHT_DISK_ARRAY[deviceid]}\)
		q=1
		while [[ "$q" -le "${CURR_FAHT_DISK_ARRAY[totalparts]}" ]]; do
			echo ${CURR_FAHT_DISK_ARRAY[part${q}]}
			(( q++ ));
		done
		echo
		### Put array items into itemized strings

		x=1
		for x in deviceid totalparts totalsize serial; do
			declare -n CURR_FAHT_DISK_VAR=FAHT_DISK_${i}_${x}
			CURR_FAHT_DISK_VAR=${CURR_FAHT_DISK_ARRAY[${x}]}
		###TEMP	echo "FAHT_DISK_${i}_${x} = ${CURR_FAHT_DISK_VAR}"
		###TEMP	echo ${x}
			(( x++ ))
		done
		(( i++ ));

		echo "Find SMART-capable drives..."
		echo

		for s in $(echo "$(smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
			if [[ "${CURR_FAHT_DISK_ARRAY[deviceid]}" == "$s" ]]; then
				CURR_FAHT_DISK_ARRAY[smartcapable]="YES"
				if [ "$(sudo smartctl -a /dev/${CURR_FAHT_DISK_ARRAY[deviceid]}|grep "Self-tests/Logging not supported")" ]; then
					CURR_FAHT_DISK_ARRAY[selftest_capable]="NO"
				else
					CURR_FAHT_DISK_ARRAY[selftest_capable]="YES"
				fi	
			fi
		done
	done
}

smart_drive_find () {

	### Testing for SMART-capable drives ###
	smartctl --scan|sed -r 's/\/dev\/([a-z]d[a-z]).*/\1/g'|grep -v $FAHT_LIVE_DEV

	if [ $? -eq 0 ]; then
		## Setting SMART capable drives in array for testing
		
	declare -A FAHT_SMART_DRIVES_ARRAY

	j=0

	for i in $(echo "$(smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
		FAHT_SMART_DRIVES_ARRAY[$j]="$i"
		echo $j
		echo FAHT_SMART_DRIVES_ARRAY[$j] = ${FAHT_SMART_DRIVES_ARRAY[$j]}
		echo
		((j++));
	done

		echo Drives with SMART capabilities:
		echo ${FAHT_SMART_DRIVES_ARRAY[@]}
		echo;
	else
		echo No drives are SMART capable. Skipping test...
		echo;
	fi
	$DIAG
}

smart_test ()
{
	### SMART Testing ###

	echo --------------------------------
	echo Testing Hard Drives. Please wait
	echo --------------------------------
	$DIAG
	echo

	FAHT_DISK_NO=1

	i=1
	while [[ "$i" -le "$FAHT_TOTAL_TEST_DISKS" ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY

		echo Working on Disk ${i}...
		echo -----------------------

		if [ "${CURR_FAHT_DISK_ARRAY[smarttest_capable]}" == "YES" ]; then
			curr_smart_dev="${CURR_FAHT_DISK_ARRAY[deviceid]}"

			smartctl -x /dev/"$curr_smart_dev">"$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
			: echo
			: cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
			: echo

			### Store hours on in human readable way...

			CURR_FAHT_DISK_ARRAY[hourson]="$(sudo smartctl -a /dev/$curr_smart_dev|grep -I "Power_On_Hours"|awk '{print $10}')"
			: echo ${CURR_FAHT_DISK_ARRAY[hourson]}
			$DIAG

			declare -A FAHT_DISK_${i}_TIME_ON_ARRAY
			declare -n CURR_FAHT_DISK_TIME_ON_ARRAY=FAHT_DISK_${i}_TIME_ON_ARRAY

			if [[ "${CURR_FAHT_DISK_ARRAY[hourson]}" -gt 0 ]]; then

				declare -A FAHT_hours

				FAHT_hours[days]=24
				FAHT_hours[months]=720
				FAHT_hours[years]=8760

				let FAHT_hours_REMAINING="${CURR_FAHT_DISK_ARRAY[hourson]}"

				### Divide hours by units of time, dropping the remainder to be parsed next...

				for d in years months days; do

					CURR_FAHT_DISK_TIME_ON_ARRAY[${d}]=$((($FAHT_hours_REMAINING/${FAHT_hours[$d]})))
					: echo ${CURR_FAHT_DISK_TIME_ON_ARRAY[${d}]}
					FAHT_hours_REMAINING=$((($FAHT_hours_REMAINING%${FAHT_hours[$d]})))

				done

				CURR_FAHT_DISK_TIME_ON_ARRAY[hours]=$FAHT_hours_REMAINING

				### Parsing time on in human-readable format

				for d in years months days hours; do
					if [[ "${CURR_FAHT_DISK_TIME_ON_ARRAY[$d]}" -gt "0" ]]; then
						CURR_FAHT_DISK_ARRAY[timeon]="${CURR_FAHT_DISK_ARRAY[timeon]} $(printf "${CURR_FAHT_DISK_TIME_ON_ARRAY[$d]} $d ")"
					fi;
				done
				
				### Trim trailing whitespace...
				CURR_FAHT_DISK_ARRAY[timeon]=$(echo ${CURR_FAHT_DISK_ARRAY[timeon]})
				: echo ${CURR_FAHT_DISK_ARRAY[timeon]}
				: echo

				if [[ "${CURR_FAHT_DISK_ARRAY[hourson]}" -ge "26280" ]]; then
					CURR_FAHT_DISK_ARRAY[timeon_results]=FAILED
				else
					CURR_FAHT_DISK_ARRAY[timeon_results]=PASSED
				fi
			fi	

			if [[ "${CURR_FAHT_DISK_ARRAY[selftest_capable]}" == "YES" ]]; then

				echo Beginning SMART short test on "$curr_smart_dev"
				smartctl -t force -t short /dev/$curr_smart_dev>"$FAHT_WORKINGDIR"/smartshorttest-$curr_smart_dev.txt
				cat "$FAHT_WORKINGDIR"/smartshorttest-$curr_smart_dev.txt
				smart_short_test_max_minutes=$(cat "$FAHT_WORKINGDIR"/smartshorttest-$curr_smart_dev.txt|grep "Please wait"|sed 's/[^0-9]*//g')

				echo
				echo -en "\r$smart_short_test_max_minutes mins remaining"
				j=0

				while [ "$j" -lt "$smart_short_test_max_minutes" ]; do
					sleep 60
					time_remaining=$(( $smart_short_test_max_minutes - $j ))
					echo -en "\r$time_remaining mins remaining"

					smartctl -l selftest /dev/"$curr_smart_dev"|grep "# 1"|grep "failure"

					if [ $? -eq 0 ]; then
						j=9999
					else
						let j=j+1;
					fi
				done
				echo
				
				echo
				echo Short SMART test done.
				echo

				if [ "$FAHT_SHORTONLY" != "true" ]; then
					echo Beginning SMART long test on $curr_smart_dev

					smartctl -t force -t long /dev/"$curr_smart_dev">"$FAHT_WORKINGDIR"/smartlongtest-"$curr_smart_dev".txt

					cat "$FAHT_WORKINGDIR"/smartlongtest-"$curr_smart_dev".txt
					smart_long_test_max_minutes=$(cat "$FAHT_WORKINGDIR"/smartlongtest-$curr_smart_dev.txt|grep "Please wait"|sed 's/[^0-9]*//g')

					echo
					echo -en "\r$smart_long_test_max_minutes mins remaining"
					
					j=0
					
					while [ "$j" -lt "$smart_long_test_max_minutes"  ]; do
						sleep 60
						time_remaining=$(( $smart_long_test_max_minutes - $j ))
						echo -en "\r$time_remaining mins remaining"

						smartctl -l selftest /dev/"$curr_smart_dev"|grep "# 1"|grep "failure"|sed 's/.*\(failure\).*/\1/'

						if [ $? -eq 0 ]; then
							j=9999
						else
							let j=j+1;
						fi
					done

					echo
					echo Long SMART test done.
					echo

					smartctl -x /dev/"$curr_smart_dev">"$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
					echo
					: cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt
					echo
					echo Long test result: "$(cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt|grep "# 1")"
					echo

				fi

				SMART_PASSED=$(cat "$FAHT_WORKINGDIR"/smartlog-"$curr_smart_dev".txt|grep "# 1"|sed -r 's/.*(Completed without error).*/\1/')

				if [ "$SMART_PASSED" == "Completed without error" ]; then
					CURR_FAHT_DISK_ARRAY[selftest_results]="PASSED";
				else
					CURR_FAHT_DISK_ARRAY[selftest_results]="FAILED";
				fi
			fi	
		(( i++ ))
	done

			$DIAG
}

mount_avail_volumes () {
	### Set up mount points
	### Ensure test drives are unmounted first and mount dir structure is good
	echo Attempting to mount volumes....
	echo -------------------------------

	if [ ! -d /mnt/faht ]; then mkdir /mnt/faht; fi
	for i in /mnt/faht/*; do
		umount $i
		rmdir $i;
	done

	i=1
	while [[ "$i" -le "$FAHT_TOTAL_TEST_DISKS" ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY

		pn=1
		while [[ "$pn" -le ${CURR_FAHT_DISK_ARRAY[totalparts]} ]]; do
			umount /dev/${FAHT_TEST_PARTS_ARRAY[$pn]} 2>/dev/null
			(( pn++ ));
		done

		pn=1
		while [[ "$pn" -le ${CURR_FAHT_DISK_ARRAY[totalparts]} ]]; do
			x=${CURR_FAHT_DISK_ARRAY[part${pn}]}
			if [ ! -d /mnt/faht/${x} ]; then
				mkdir /mnt/faht/${x}
				echo Created mountpount: /mnt/faht/${x};
			fi
			mount /dev/$x /mnt/faht/$x 2>/dev/null
			if [[ "$?" -ne "0" ]]; then
				echo Mount of /dev/${x} failed. Removing mountpoint...
				rmdir /mnt/faht/${x}
			else echo mounted /dev/$x /mnt/faht/$x
			fi

			if [[ -z ${CURR_FAHT_DISK_ARRAY[benchvol]} ]]; then
				touch /mnt/faht/$x/test
				if [[ "$?" -eq "0" ]]; then
					CURR_FAHT_DISK_ARRAY[benchvol]=/mnt/faht/$x
					rm /mnt/faht/$x/test
					echo
					echo ---
					benchvol_free_mb=$(df -h --output=avail /mnt/faht/$x|tail -1|sed -r 's/ ([0-9]+).*/\1/g')
					echo $benchvol_free_mb MB free disk space on benchmarking volume
					memtotal_kb=$(cat /proc/meminfo|grep MemTotal|sed -r 's/^.* ([0-9]+) .*/\1/')
					echo $memtotal_kb KB total RAM
					benchvol_free_kb=$(df --output=avail -B K /mnt/faht/$x|tail -1|sed 's/[^0-9]//')
					echo $benchvol_free_kb KB free disk space on benchmarking volume
					echo Write benchmark location for Disk ${i}: ${CURR_FAHT_DISK_ARRAY[benchvol]};
					echo ---
				fi
			fi
			(( pn++ ))
			echo;
		done
		(( i++ ))

	# Test partitions for r/w mount

	# If unable to get r/w mount set benchmark for read-only

	# If volume is writeable set benchamrk for read-write

	done
}

find_win_part () {
	echo Searching for Windows system volume...
	echo --------------------------------------
	i=1
	while [[ "$i" -le "$FAHT_TOTAL_TEST_DISKS" ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY
		echo Seaching Disk ${i}...

		j=1
		while [[ "$j" -le "${CURR_FAHT_DISK_ARRAY[totalparts]}" ]]; do
			WIN_VOL=NO
			#echo "Testing parition ${j}: ${CURR_FAHT_DISK_ARRAY[part${j}]}"
			if [[ -d "/mnt/faht/${CURR_FAHT_DISK_ARRAY[part${j}]}/Windows" ]]; then
				echo
				echo "Found Windows partition in /dev/${CURR_FAHT_DISK_ARRAY[part${j}]}"
				CURR_FAHT_DISK_ARRAY[windowspart]=${CURR_FAHT_DISK_ARRAY[part${j}]}
				FAHT_WIN_PART=${CURR_FAHT_DISK_ARRAY[part${j}]}
				echo FAHT_WIN_PART=$FAHT_WIN_PART
				echo
				CURR_FAHT_DISK_ARRAY[windowspartfreespace]=$(df -h --output=avail /dev/${CURR_FAHT_DISK_ARRAY[part${j}]}|tail -1|sed 's/^[ \t]*//')
				#WIN_PART_FREE_SPACE=$(df -h --output=avail /dev/${CURR_FAHT_DISK_ARRAY[part${j}]}|tail -1|sed 's/^[ \t]*//');
				CURR_FAHT_DISK_ARRAY[windowspartfreespace_bytes]=$((($(df --output=avail /dev/${CURR_FAHT_DISK_ARRAY[part${j}]}|tail -1)*1000)))

				CURR_FAHT_DISK_ARRAY[windowspartfreespace_results]="n/a"

				CURR_FAHT_DISK_ARRAY[freespace_percent]="$(echo "scale=2;${CURR_FAHT_DISK_ARRAY[windowspartfreespace_bytes]}/${CURR_FAHT_DISK_ARRAY[totalsize_bytes]}"|bc|sed 's/\.//')"

				if [[ "${CURR_FAHT_DISK_ARRAY[freespace_percent]}" -le "10" ]]; then
					CURR_FAHT_DISK_ARRAY[windowspartfreespace_results]="FAILED"
				fi

				if [ "${CURR_FAHT_DISK_ARRAY[freespace_percent]}" -gt "10" ] && [ "$CURR_FAHT_DISK_ARRAY[freespace_percent]" -le "25" ]; then
					CURR_FAHT_DISK_ARRAY[windowspartfreespace_results]="WARNING"
				fi

				if [[ "${CURR_FAHT_DISK_ARRAY[freespace_percent]}" -gt "25" ]]; then
					CURR_FAHT_DISK_ARRAY[windowspartfreespace_results]="PASSED"
				fi
			fi
			(( j++ ));
		done
		(( i++ ));
	done
	echo
}

benchmark_disks () {
	echo Benchmarking attached disks...
	echo ------------------------------

	### Need to add logic to NOT write to the disk if SMART fails.
	### That means this should be run ONLY AFTER Smart test completes.

	i=1
	while [[ "$i" -le "${FAHT_TOTAL_TEST_DISKS}" ]]; do
		echo Testing read speed of Disk ${i}...
		echo

		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY

		### Default to skip write test in case of bug or other unforseen circumstance. (Bash is funny... OK!?)
		WRITE_TEST="NO"

		if [[ "${CURR_FAHT_DISK_ARRAY[selftest_results]}" == "FAILED" ]]; then
			WRITE_TEST="NO";
		fi

		TESTDEV_SIZE_IN_BYTES=$(lsblk -dnrbo SIZE /dev/${CURR_FAHT_DISK_ARRAY[deviceid]})
		: echo TESTDEV_SIZE_IN_BYTES = ${TESTDEV_SIZE_IN_BYTES}

		#1GB Block size (1073741824 bytes)
		BLOCK_SIZE_IN_BYTES=1073741824

		TOTAL_DATA_SIZE_IN_BLOCKS="$((( "$TESTDEV_SIZE_IN_BYTES" / "$BLOCK_SIZE_IN_BYTES" )))"
		: echo "TOTAL_DATA_SIZE_IN_BLOCKS=$((( $TESTDEV_SIZE_IN_BYTES / $BLOCK_SIZE_IN_BYTES )))"

		PASSES=5

		c="$PASSES"
		# Default BLOCK size = 512
		# 1 GiB / 512 BLOCK size = 2,097,152
		BLOCK_COUNT=1

		echo Running ${c} passes, 1 GB each.

		touch "${FAHT_WORKINGDIR}"/dd-read-"${CURR_FAHT_DISK_ARRAY[deviceid]}".txt
		touch "${FAHT_WORKINGDIR}"/dd-write-"${CURR_FAHT_DISK_ARRAY[deviceid]}".txt
		
		b=1
		while [[ "$c" -ge "1" ]]; do
			START_PLACE="$((( $TOTAL_DATA_SIZE_IN_BLOCKS - "$c" )))"
			echo Running pass ${b}...
			: echo "dd if=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} of=/dev/null bs=${BLOCK_SIZE_IN_BYTES} count=${BLOCK_COUNT} skip=${START_PLACE} 2>"${FAHT_WORKINGDIR}"/dd-read-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt"
			dd if=/dev/"${CURR_FAHT_DISK_ARRAY[deviceid]}" of=/dev/null bs="${BLOCK_SIZE_IN_BYTES}" count="${BLOCK_COUNT}" skip="${START_PLACE}" 2>"${FAHT_WORKINGDIR}"/dd-read-"${CURR_FAHT_DISK_ARRAY[deviceid]}".txt
			sleep 2
			
			RSPEED="$(cat "${FAHT_WORKINGDIR}"/dd-read-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt|grep bytes|sed -r 's/.* copied\, ([0-9]+\.[0-9]+) s.*/\1/g')"
			CURR_FAHT_DISK_ARRAY[readbench_"${c}"]=$(printf "%.0f" $(echo "scale=2;1024/$RSPEED"|bc))
			(( b++ ))
			(( c-- ));
		done

		c=1
		READ_TOTAL=0
		while [[ "$c" -le "$PASSES" ]]; do
			: echo Pass number $c: ${CURR_FAHT_DISK_ARRAY[readbench_$c]}
			READ_TOTAL="$((( $READ_TOTAL + "${CURR_FAHT_DISK_ARRAY[readbench_"${c}"]}")))"
			(( c++ ));
		done

		READ_AVERAGE=$((( $READ_TOTAL / "$PASSES" )))
		echo
		echo Read average for ${CURR_FAHT_DISK_ARRAY[deviceid]}: $READ_AVERAGE MB/s

		if [[ "$READ_AVERAGE" -le "75" ]]; then
			CURR_FAHT_DISK_ARRAY[readspeed_results]="FAILED"
		fi
		if [[ "$READ_AVERAGE" -ge "90" ]]; then
			CURR_FAHT_DISK_ARRAY[readspeed_results]="PASSED"
		fi
		if [ "$READ_AVERAGE" -gt "75" ] && [ "$READ_AVERAGE" -lt "90" ]; then
			CURR_FAHT_DISK_ARRAY[readspeed_results]="WARNING"
		fi

		CURR_FAHT_DISK_ARRAY[readspeed]="$READ_AVERAGE MB/s"

		CURR_FAHT_DISK_ARRAY[writespeed]="Write test skipped."

		MOUNT_RESULT=""
		CURR_DEV_UNMOUNTED="UNKNOWN"

		umount /dev/${CURR_FAHT_DISK_ARRAY[deviceid]}* 2>/dev/null

		MOUNT_RESULT="$(mount | grep "${CURR_FAHT_DISK_ARRAY[deviceid]}")"

		if [[ "$MOUNT_RESULT" != "" ]]; then
			CURR_DEV_UNMOUNTED="NO"
			echo Disk ${i}: ${CURR_FAHT_DISK_ARRAY[devicedid]} NOT unmounted!!!!
			: "echo CURR_DEV_UNMOUNTED=${CURR_DEV_UNMOUNTED}"
			: echo MOUNT_RESULT="${MOUNT_RESULT}"
			echo
		fi

		if [[ "$MOUNT_RESULT" == "" ]]; then
			CURR_DEV_UNMOUNTED="YES"
			echo
			echo Disk ${i}: ${CURR_FAHT_DISK_ARRAY[devicedid]} sucessfully unmounted.
			: "echo CURR_DEV_UNMOUNTED=${CURR_DEV_UNMOUNTED}"
			: echo MOUNT_RESULT="${MOUNT_RESULT}"
			echo
		fi

		if [[ "$CURR_DEV_UNMOUNTED" == "NO" ]]; then
			echo Could not unmount Disk ${i}: ${CURR_FAHT_DISK_ARRAY[deviced]}... Write test aborted.
			echo
		fi

		if [[ "${CURR_DEV_UNMOUNTED}" == "YES" ]] && [[ "${CURR_FAHT_DISK_ARRAY[selftest_results]}" == "PASSED" ]]; then
			echo Testing write speed of Disk ${i}...
			echo
			
			### 1048576 = 1MiB in Bytes
			### WRITE_BLOCK_SIZE=1048576

			WRITE_BLOCK_SIZE=1048576
			WRITE_TOTAL_BLOCKS=$((( $TESTDEV_SIZE_IN_BYTES / $WRITE_BLOCK_SIZE )))

			#### The "SUBDIV" is to get the number of blocks needed to fill 1 GiB (1 GiB / BLOCK size in Bytes)
			#### WRITE_BLOCK_SUBDIV=10
			#### 1GiB in Bytes = 1073741824

			TOTAL_BENCH_DATA_SIZE=1073741824

			WRITE_BLOCK_SUBDIV=$((( $TOTAL_BENCH_DATA_SIZE / $WRITE_BLOCK_SIZE )))
			WRITE_BLOCK_COUNT=$WRITE_BLOCK_SUBDIV

			: echo "WRITE_TOTAL_BLOCKS=${WRITE_TOTAL_BLOCKS}"
			: echo "WRITE_BLOCK_SIZE=${WRITE_BLOCK_SIZE}"

			c=$PASSES
			echo Running ${c} passes, 1 GB each.
			b=1
			while [[ "$c" -ge "1" ]]; do
				WRITE_COUNT=$((( "$c" * "$WRITE_BLOCK_SUBDIV" )))
				START_PLACE=$((( $WRITE_TOTAL_BLOCKS - "$WRITE_COUNT" )))
				echo Running pass: ${b}...
				: echo "command to run: dd if=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} of=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} ibs=${WRITE_BLOCK_SIZE} obs=${WRITE_BLOCK_SIZE} count=${WRITE_BLOCK_COUNT} skip=${START_PLACE} seek=${START_PLACE} 2>"${FAHT_WORKINGDIR}"/dd-write-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt"
				dd if=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} of=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} ibs=${WRITE_BLOCK_SIZE} obs=${WRITE_BLOCK_SIZE} count=${WRITE_BLOCK_COUNT} skip=${START_PLACE} seek=${START_PLACE} 2>"${FAHT_WORKINGDIR}"/dd-write-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt
				sleep 2

				WSPEED="$(cat "${FAHT_WORKINGDIR}"/dd-write-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt|grep bytes|sed -r 's/.* copied\, ([0-9]+\.[0-9]+) s.*/\1/g')"
				CURR_FAHT_DISK_ARRAY[writebench_$c]=$(printf "%.0f" $(echo "scale=2;1024/$WSPEED"|bc))
				(( b++ ))
				(( c-- ));
			done

			c=1
			WRITE_TOTAL=0
			while [[ "$c" -le "$PASSES" ]]; do
				: echo "Pass number $c: ${CURR_FAHT_DISK_ARRAY[writebench_$c]}"
				WRITE_TOTAL=$((( $WRITE_TOTAL + ${CURR_FAHT_DISK_ARRAY[writebench_$c]})))
				(( c++ ));
			done

			WRITE_AVERAGE=$((( $WRITE_TOTAL / "$PASSES" )))

			if [[ "$WRITE_AVERAGE" -le "50" ]]; then
				CURR_FAHT_DISK_ARRAY[writespeed_results]="FAILED"
			fi
			if [[ "$WRITE_AVERAGE" -ge "65" ]]; then
				CURR_FAHT_DISK_ARRAY[writespeed_results]="PASSED"
			fi
			if [ "$WRITE_AVERAGE" -gt "50" ] && [ "$WRITE_AVERAGE" -lt "65" ]; then
				CURR_FAHT_DISK_ARRAY[writespeed_results]="WARNING"
			fi

			echo
			echo Write average for ${CURR_FAHT_DISK_ARRAY[deviceid]}: $WRITE_AVERAGE MB/s

			CURR_FAHT_DISK_ARRAY[writespeed]="$WRITE_AVERAGE MB/s"
		else
			echo "Skipping write test..."
		fi

		(( i++ ))
		echo;
	done
}

list_disks_info () {
	i=1
	while [[ "$i" -le $FAHT_TOTAL_TEST_DISKS ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY
		echo Disk ${i}
		echo -----------------------------------
		echo Name: ${CURR_FAHT_DISK_ARRAY[name]}
		echo Device ID: ${CURR_FAHT_DISK_ARRAY[deviceid]}
		echo Serial \#: ${CURR_FAHT_DISK_ARRAY[serial]}
		if [[ "${CURR_FAHT_DISK_ARRAY[smartcapable]}" == "YES" ]]; then
			echo Smart Capable: Yes
			if [ "${CURR_FAHT_DISK_ARRAY[selftest_capable]}" ]; then
				echo "Self Test Result: ${CURR_FAHT_DISK_ARRAY[selftest_results]}"
			fi
			echo "Time On: ${CURR_FAHT_DISK_ARRAY[timeon]} (${CURR_FAHT_DISK_ARRAY[timeon_results]})"
		else
			echo Smart capable: No
		fi
		echo Total partitions: ${CURR_FAHT_DISK_ARRAY[totalparts]}
		echo "Total size: ${CURR_FAHT_DISK_ARRAY[totalsize]} (${CURR_FAHT_DISK_ARRAY[totalsize_results]})"
		if [[ ${CURR_FAHT_DISK_ARRAY[windowspart]} ]]; then
			echo Windows partition: ${CURR_FAHT_DISK_ARRAY[windowspart]}
			echo Free space on system volume: ${CURR_FAHT_DISK_ARRAY[windowspartfreespace]};
		fi
		echo Benchmark mount point: ${CURR_FAHT_DISK_ARRAY[benchvol]}
		echo Disk read speed: ${CURR_FAHT_DISK_ARRAY[readspeed]}
		echo Disk write speed: ${CURR_FAHT_DISK_ARRAY[writespeed]}
		echo
		(( i++ ));
	done
}
