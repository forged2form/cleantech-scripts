#!/bin/bash 

### Testing y'all

DIAG=pause_input

FAHT_LIVE_DEV="$(mount|grep " on / "|sed -n 's/^\/dev\/\(.*\)[0-9] on \/ .*/\1/gp')"

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
					echo Write benchmark location for Disk ${i}: ${CURR_FAHT_DISK_ARRAY[benchvol]};
				fi
			fi
			(( pn++ ))
			echo;
		done
		(( i++ ))

		$DIAG


	# Test partitions for r/w mount

	# If unable to get r/w mount set benchmark for read-only

	# If volume is writeable set benchamrk for read-write

	done

	$DIAG
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

	i=1
	while [[ "$i" -le "${FAHT_TOTAL_TEST_DISKS}" ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY
		### Read benchmark
		echo Testing read speed of Disk ${i}
		echo running command: hdparm -t /dev/${CURR_FAHT_DISK_ARRAY[deviceid]}
		hdparm -t /dev/${CURR_FAHT_DISK_ARRAY[deviceid]}>/tmp/logdir-disk${i}-hdparm.txt
		#CURR_FAHT_DISK_ARRAY[readspeed]="$(cat /tmp/logdir-disk${i}-hdparm.txt|tail -1|sed -r 's/^.* \= ([0-9].*)/\1/g')"
		echo ${CURR_FAHT_DISK_ARRAY[readspeed]}
		#$DIAG

		### Write benchmark
		echo running command: bonnie++ -d ${CURR_FAHT_DISK_ARRAY[benchvol]} -s 10
		bonnie++ -d ${CURR_FAHT_DISK_ARRAY[benchvol]} -r 8096 -u techtutors
		
		#bench command
		#echo Testing write speed of Disk ${2}
		#echo running command: dd if=/dev/zero of=${CURR_FAHT_DISK_ARRAY[benchvol]}/testfile bs=400M count=1 oflag=direct
		#dd if=/dev/zero of=${CURR_FAHT_DISK_ARRAY[benchvol]}/testfile bs=1M count=100 oflag=direct
		#rm ${CURR_FAHT_DISK_ARRAY[benchvol]}/testfile
		(( i++ ))
		$DIAG;
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

find_win_part

i=1
while [[ "$i" -le $FAHT_TOTAL_TEST_DISKS ]]; do
	declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY
	echo Disk ${i}
	echo -----------------------------------
	echo Name: ${CURR_FAHT_DISK_ARRAY[name]}
	echo Device ID: ${CURR_FAHT_DISK_ARRAY[deviceid]}
	echo Serial \#: ${CURR_FAHT_DISK_ARRAY[serial]}
	echo Total partitions: ${CURR_FAHT_DISK_ARRAY[totalparts]}
	echo Total size: ${CURR_FAHT_DISK_ARRAY[totalsize]}
	if [[ ${CURR_FAHT_DISK_ARRAY[windowspart]} ]]; then
		echo Windows partition: ${CURR_FAHT_DISK_ARRAY[windowspart]}
		echo Free space on system volume: ${CURR_FAHT_DISK_ARRAY[windowspartfreespace]};
	fi
	echo Benchmark mount point: ${CURR_FAHT_DISK_ARRAY[benchvol]}
	echo
	(( i++ ));
done

benchmark_disks

umount /mnt/faht/*
rmdir /mnt/faht/*