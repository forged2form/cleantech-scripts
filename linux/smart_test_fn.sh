#!/bin/bash -x

### Testing y'all

DIAG=pause_input

FAHT_LIVE_DEV="$(sudo mount|grep " on / "|sed -n 's/^\/dev\/\(.*\)[0-9] on \/ .*/\1/gp')"

FAHT_WORKINGDIR=/tmp

pause_input () {
	read -n1 -s -r -p "Press any key to continue"
	echo -e "\n"
}

### init vars so they are global and retain values when used in functions...
FAHT_TOTAL_TEST_DISKS=0
### Put disks in array minus current OS disk
declare -A FAHT_TEST_DISKS_ARRAY
i=1
j=
for j in $(sudo lsblk -n -r -o NAME|grep -v "$FAHT_LIVE_DEV"|grep -E -v "[0-9]"|grep -E "^[a-z]d[a-z]"); do
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

	CURR_FAHT_DISK_ARRAY[testing]="A-OK"
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

		###TEMP echo Working on Disk ${i}: ${CURR_FAHT_DISK_ARRAY[deviceid]}
		###TEMP echo

		CURR_FAHT_DISK_ARRAY[totalsize]=$(lsblk -drno SIZE /dev/$j)
		
		pn=1
		for p in $(sudo lsblk -n -r -o NAME|grep "${CURR_FAHT_DISK_ARRAY[deviceid]}[0-9]"); do
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
	done
}

smart_drive_find () {

	### Testing for SMART-capable drives ###
	sudo smartctl --scan|sed -r 's/\/dev\/([a-z]d[a-z]).*/\1/g'|grep -v $FAHT_LIVE_DEV

	if [ $? -eq 0 ]; then
		## Setting SMART capable drives in array for testing
		
	declare -A FAHT_SMART_DRIVES_ARRAY

	j=0

	for i in $(echo "$(sudo smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
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

mount_avail_volumes () {
	### Set up mount points
	### Ensure test drives are unmounted first and mount dir structure is good
	echo Attempting to mount volumes....
	echo -------------------------------

	if [ ! -d /mnt/faht ]; then sudo mkdir /mnt/faht; fi
	for i in /mnt/faht/*; do
		sudo umount $i
		rmdir $i;
	done

	i=1
	while [[ "$i" -le "$FAHT_TOTAL_TEST_DISKS" ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY

		pn=1
		while [[ "$pn" -le ${CURR_FAHT_DISK_ARRAY[totalparts]} ]]; do
			sudo umount /dev/${FAHT_TEST_PARTS_ARRAY[$pn]} 2>/dev/null
			(( pn++ ));
		done

		pn=1
		while [[ "$pn" -le ${CURR_FAHT_DISK_ARRAY[totalparts]} ]]; do
			x=${CURR_FAHT_DISK_ARRAY[part${pn}]}
			if [ ! -d /mnt/faht/${x} ]; then
				sudo mkdir /mnt/faht/${x}
				echo Created mountpount: /mnt/faht/${x};
			fi
			sudo mount /dev/$x /mnt/faht/$x 2>/dev/null
			if [[ "$?" -ne "0" ]]; then
				echo Mount of /dev/${x} failed. Removing mountpoint...
				sudo rmdir /mnt/faht/${x}
			else echo mounted /dev/$x /mnt/faht/$x
			fi

			if [[ -z ${CURR_FAHT_DISK_ARRAY[benchvol]} ]]; then
				sudo touch /mnt/faht/$x/test
				if [[ "$?" -eq "0" ]]; then
					CURR_FAHT_DISK_ARRAY[benchvol]=/mnt/faht/$x
					sudo rm /mnt/faht/$x/test
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
				WIN_PART_FREE_SPACE=$(df -h --output=avail /dev/${CURR_FAHT_DISK_ARRAY[part${j}]}|tail -1|sed 's/^[ \t]*//');
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
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY

		### Default to skip write test in case of bug or other unforseen circumstance. (Bash is funny... OK!?)
		WRITE_TEST="NO"

		if [[ "${CURR_FAHT_DISK_ARRAY[smart_results]}" == "FAILED" ]]; then
			WRITE_TEST="NO";
		fi

		TESTDEV_SIZE_IN_BYTES=$(sudo lsblk -dnrbo SIZE /dev/${CURR_FAHT_DISK_ARRAY[deviceid]})
		echo TESTDEV_SIZE_IN_BYTES = ${TESTDEV_SIZE_IN_BYTES}

		#1GB Block size (1073741824 bytes)
		BLOCK_SIZE_IN_BYTES=1073741824

		TOTAL_DATA_SIZE_IN_BLOCKS="$((( "$TESTDEV_SIZE_IN_BYTES" / "$BLOCK_SIZE_IN_BYTES" )))"
		echo "TOTAL_DATA_SIZE_IN_BLOCKS=$((( $TESTDEV_SIZE_IN_BYTES / $BLOCK_SIZE_IN_BYTES )))"

		PASSES=5

		c="$PASSES"
		# Default BLOCK size = 512
		# 1 GiB / 512 BLOCK size = 2,097,152
		BLOCK_COUNT=1

		touch "${FAHT_WORKINGDIR}"/dd-read-"${CURR_FAHT_DISK_ARRAY[deviceid]}".txt
		touch "${FAHT_WORKINGDIR}"/dd-write-"${CURR_FAHT_DISK_ARRAY[deviceid]}".txt
		
		while [[ "$c" -ge "1" ]]; do
			START_PLACE="$((( $TOTAL_DATA_SIZE_IN_BLOCKS - "$c" )))"
			echo "sudo dd if=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} of=/dev/null bs=${BLOCK_SIZE_IN_BYTES} count=${BLOCK_COUNT} skip=${START_PLACE} 2>"${FAHT_WORKINGDIR}"/dd-read-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt"
			sudo dd if=/dev/"${CURR_FAHT_DISK_ARRAY[deviceid]}" of=/dev/null bs="${BLOCK_SIZE_IN_BYTES}" count="${BLOCK_COUNT}" skip="${START_PLACE}" 2>"${FAHT_WORKINGDIR}"/dd-read-"${CURR_FAHT_DISK_ARRAY[deviceid]}".txt
			sleep 5
			
			RSPEED="$(cat "${FAHT_WORKINGDIR}"/dd-read-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt|grep bytes|sed -r 's/.* copied\, ([0-9]+\.[0-9]+) s.*/\1/g')"
			CURR_FAHT_DISK_ARRAY[readbench_"${c}"]=$(printf "%.0f" $(echo "scale=2;1024/$RSPEED"|bc))
			(( c-- ));
		done

		c=1
		READ_TOTAL=0
		while [[ "$c" -le "$PASSES" ]]; do
			echo Pass number $c: ${CURR_FAHT_DISK_ARRAY[readbench_$c]}
			READ_TOTAL="$((( $READ_TOTAL + "${CURR_FAHT_DISK_ARRAY[readbench_"${c}"]}")))"
			(( c++ ));
		done

		READ_AVERAGE=$((( $READ_TOTAL / "$PASSES" )))

		echo Read average for ${CURR_FAHT_DISK_ARRAY[deviceid]}: $READ_AVERAGE

		CURR_FAHT_DISK_ARRAY[readspeed]="$READ_AVERAGE MB/s"

		CURR_FAHT_DISK_ARRAY[writespeed]="Write test skipped."

		### Read benchmark
		#echo Testing read speed of Disk ${i}
		#echo running command: hdparm -t /dev/${CURR_FAHT_DISK_ARRAY[deviceid]}
		#hdparm -t /dev/${CURR_FAHT_DISK_ARRAY[deviceid]}>"${FAHT_WORKINGDIR}"/logdir-disk${i}-hdparm.txt
		#CURR_FAHT_DISK_ARRAY[readspeed]="$(cat "${FAHT_WORKINGDIR}"/logdir-disk${i}-hdparm.txt|grep "disk reads"|sed -r 's/.* \= (.*)/\1/g')"
		#echo ${CURR_FAHT_DISK_ARRAY[readspeed]}
		#$DIAG

		# |sed -r 's/^.* \= ([0-9].*)/\1/g'

		### Write benchmark

		#echo running command: bonnie++ -d ${CURR_FAHT_DISK_ARRAY[benchvol]} -r 8096 -u techtutors
		#bonnie++ -d ${CURR_FAHT_DISK_ARRAY[benchvol]} -r 8096 -u techtutors

		### bench command

		#declare -a CURR_BENCH_ARRAY
		#b=0
		#while [[ "$b" -lt "100" ]]; do
		#	echo running command: dd if=/dev/zero of=${CURR_FAHT_DISK_ARRAY[benchvol]}/testfile bs=100M count=1 oflag=direct 2>"${FAHT_WORKINGDIR}"/logdir-disk${i}-dd-write.txt
		#	dd if=/dev/zero of=${CURR_FAHT_DISK_ARRAY[benchvol]}/testfile bs=100M count=1 oflag=direct 2>"${FAHT_WORKINGDIR}"/logdir-disk${i}-dd-write.txt
		#	CURR_BENCH_ARRAY[${b}]="$(cat "${FAHT_WORKINGDIR}"/logdir-disk${i}-dd-write.txt|grep bytes|sed -r 's/.* s\, ([0-9]+)/\1/g')"
		#	(( b++ ));
		#done
		#echo ${CURR_BENCH_ARRAY[@]}
		#echo running command: dd if=/dev/zero of=${CURR_FAHT_DISK_ARRAY[benchvol]}/testfile bs=100M count=1 oflag=direct 2>"${FAHT_WORKINGDIR}"/logdir-disk${i}-dd-write.txt
		#dd if=/dev/zero of=${CURR_FAHT_DISK_ARRAY[benchvol]}/testfile bs=100M count=1 oflag=direct 2>"${FAHT_WORKINGDIR}"/logdir-disk${i}-dd-write.txt
		MOUNT_RESULT=""
		CURR_DEV_UNMOUNTED="UNKNOWN"

		sudo umount /dev/${CURR_FAHT_DISK_ARRAY[deviceid]}*

		MOUNT_RESULT="$(sudo mount | grep "${CURR_FAHT_DISK_ARRAY[deviceid]}")"

		if [[ "$MOUNT_RESULT" != "" ]]; then
			CURR_DEV_UNMOUNTED="NO"
			echo Disk ${i}: ${CURR_FAHT_DISK_ARRAY[devicedid]} NOT unmounted!!!!
			echo CURR_DEV_UNMOUNTED=${CURR_DEV_UNMOUNTED}
			echo MOUNT_RESULT="${MOUNT_RESULT}"
			echo
		fi

		if [[ "$MOUNT_RESULT" == "" ]]; then
			CURR_DEV_UNMOUNTED="YES"
			echo
			echo Disk ${i}: ${CURR_FAHT_DISK_ARRAY[devicedid]} sucessfully unmounted!
			echo CURR_DEV_UNMOUNTED=${CURR_DEV_UNMOUNTED}
			echo MOUNT_RESULT="${MOUNT_RESULT}"
			echo
		fi

		if [[ "$CURR_DEV_UNMOUNTED" == "NO" ]]; then
			echo Could not unmount Disk ${i}: ${CURR_FAHT_DISK_ARRAY[deviced]}... Write test aborted.
			echo
		fi

		CURR_FAHT_DISK_ARRAY[smart_results]=PASSED

		if [[ "${CURR_DEV_UNMOUNTED}" == "YES" ]] && [[ "${CURR_FAHT_DISK_ARRAY[smart_results]}" == "PASSED" ]]; then
			echo Testing write speed of Disk ${i}
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

			echo WRITE_TOTAL_BLOCKS=${WRITE_TOTAL_BLOCKS}
			echo WRITE_BLOCK_SIZE=${WRITE_BLOCK_SIZE}

			c=$PASSES
			while [[ "$c" -ge "1" ]]; do
				WRITE_COUNT=$((( "$c" * "$WRITE_BLOCK_SUBDIV" )))
				START_PLACE=$((( $WRITE_TOTAL_BLOCKS - "$WRITE_COUNT" )))
				echo "command to run: dd if=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} of=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} ibs=${WRITE_BLOCK_SIZE} obs=${WRITE_BLOCK_SIZE} count=${WRITE_BLOCK_COUNT} skip=${START_PLACE} seek=${START_PLACE} 2>"${FAHT_WORKINGDIR}"/dd-write-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt"
				dd if=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} of=/dev/${CURR_FAHT_DISK_ARRAY[deviceid]} ibs=${WRITE_BLOCK_SIZE} obs=${WRITE_BLOCK_SIZE} count=${WRITE_BLOCK_COUNT} skip=${START_PLACE} seek=${START_PLACE} 2>"${FAHT_WORKINGDIR}"/dd-write-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt
				sleep 5

				WSPEED="$(cat "${FAHT_WORKINGDIR}"/dd-write-${CURR_FAHT_DISK_ARRAY[deviceid]}.txt|grep bytes|sed -r 's/.* copied\, ([0-9]+\.[0-9]+) s.*/\1/g')"
				CURR_FAHT_DISK_ARRAY[writebench_$c]=$(printf "%.0f" $(echo "scale=2;1024/$WSPEED"|bc))
				(( c-- ));
			done

			c=1
			WRITE_TOTAL=0
			while [[ "$c" -le "$PASSES" ]]; do
				echo Pass number $c: ${CURR_FAHT_DISK_ARRAY[writebench_$c]}
				WRITE_TOTAL=$((( $WRITE_TOTAL + ${CURR_FAHT_DISK_ARRAY[writebench_$c]})))
				(( c++ ));
			done

			WRITE_AVERAGE=$((( $WRITE_TOTAL / "$PASSES" )))

			echo Write average for ${CURR_FAHT_DISK_ARRAY[deviceid]}: $WRITE_AVERAGE

			CURR_FAHT_DISK_ARRAY[writespeed]="$WRITE_AVERAGE MB/s"
		else
			echo "Skipping write test..."
		fi

		(( i++ ))
		echo;
	done
}

echo testing... 
echo ----------
echo

disk_array_setup
mount_avail_volumes
echo

echo Number of Disks to test: $FAHT_TOTAL_TEST_DISKS
i=1
for j in ${FAHT_TEST_DISKS_ARRAY[@]}; do
	echo Disk ${i}: ${j}
	(( i++ ));
done
echo

sudo umount /mnt/faht/*
sudo rmdir /mnt/faht/*
benchmark_disks

