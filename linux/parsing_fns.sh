#!/bin/bash

### parsing_fns.sh
###
### Functions related to parsing results for FAHT test + outputting to file
index=
diskarray_to_flatvars () {
	i=1
	while [[ "$i" -le "${FAHT_TOTAL_TEST_DISKS}" ]]; do
		declare -n CURR_FAHT_DISK_ARRAY=FAHT_TEST_DISK_${i}_ARRAY

		for index in "${!CURR_FAHT_DISK_ARRAY[@]}"; do
			: echo "current index name: ${index}"
			declare index_name=${index}
			declare -n curr_index=FAHT_TEST_DISK_${i}_${index_name}
			curr_index=${CURR_FAHT_DISK_ARRAY[${index}]}
			: echo "current index value: ${curr_index}"
		done
		(( i++ ))
	done
}

memtest_parsing () {
	echo Parsing memtest file: $FAHT_MEMTEST_REPORT_FILE
	iconv -f utf16 -t utf8 -o $FAHT_MEMTEST_REPORT_FILE $FAHT_MEMTEST_REPORT_FILE
	FAHT_mt_vendor_name=`cat $FAHT_MEMTEST_REPORT_FILE|sed -n '/Manufacturer/{n;p}'|head -1|sed -r 's/.*>(.*)<\/td>.*/\1/'`
	FAHT_mt_prod_name=`cat $FAHT_MEMTEST_REPORT_FILE|sed -n '/Product Name/{n;p}'|head -1|sed -r 's/.*>(.*)<\/td>.*/\1/'`
	FAHT_mt_version=`cat $FAHT_MEMTEST_REPORT_FILE|sed -n '/Version/{n;p}'|head -1|sed -r 's/.*>(.*)<\/td>.*/\1/'`
	FAHT_MEM_TEST_RESULTS=`cat $FAHT_MEMTEST_REPORT_FILE|sed -n '/Result/{n;p}'|head -1|sed -r 's/.*>([A-Z]*)<.*/\1/'`
	if [ "$FAHT_MEM_TEST_RESULTS" == "PASS" ]; then
		FAHT_MEM_TEST=Completed
	else
		FAHT_MEM_TEST="Error(s)"
	fi
}

save_vars ()
{
	( set -o posix; set ) | grep FAHT_ > "$FAHT_WORKINGDIR"/raw_vars.txt
	cat "$FAHT_WORKINGDIR"/raw_vars.txt|grep -v ARRAY |grep -v DISK > "$FAHT_WORKINGDIR"/vars_noarray.txt
}

save_disk_vars () {
	( set -o posix; set ) | grep FAHT_ |grep DISK > "$FAHT_WORKINGDIR"/raw_disk_vars.txt
	cat "$FAHT_WORKINGDIR"/raw_disk_vars.txt|grep -v ARRAY > "$FAHT_WORKINGDIR"/disk_vars_noarray.txt
}

results_prep () {
	cp /usr/share/faht/faht-report-template.fodt "$FAHT_WORKINGDIR"/faht-report.fodt

	diskarray_to_flatvars

	sed -r 's/(FAHT_.*)=.*/\1/g' "$FAHT_WORKINGDIR"/vars_noarray.txt > "$FAHT_WORKINGDIR"/varsnames.txt
	sed -r 's/.*=(.*)/\1/g' "$FAHT_WORKINGDIR"/vars_noarray.txt > "$FAHT_WORKINGDIR"/varsvalues.txt

	touch "$FAHT_WORKINGDIR/disksvarsnames.txt"
	touch "$FAHT_WORKINGDIR/disksvarsvalues.txt"

	sed -r 's/(FAHT_.*)=.*/\1/g' "$FAHT_WORKINGDIR"/disk_vars_noarray.txt > "$FAHT_WORKINGDIR/diskvarsnames.txt"
	sed -r 's/.*=(.*)/\1/g' "$FAHT_WORKINGDIR"/disk_vars_noarray.txt > "$FAHT_WORKINGDIR/diskvarsvalues.txt"

	for filename in diskvars vars; do
		$DIAG
		i=0
		varsNames=()
		varsvalues=()

		namesfile="$FAHT_WORKINGDIR"/${filename}names.txt
		valuesfile="$FAHT_WORKINGDIR"/${filename}values.txt


		while IFS= read line; do
			varsNames[$i]=$line
			: echo ${varsNames[$i]}
			(( i++ ));
		done < "${namesfile}"
		$DIAG

		i=0

		while IFS= read line; do
			varsValues[$i]=$line
			: echo ${varsValues[$i]}
			(( i++ ));
		done < "${valuesfile}"
		$DIAG

		i=0

		

		### Remove single quotes from values...

		index=

		for index in ${!varsValues[@]}; do
			varsValues[$index]=$(echo ${varsValues[$index]//\'/})
		done

		j=0

		for x in ${varsNames[@]}; do
			: echo "Working on $x..."
			: echo "Var number: $j"
			sed -i "s|\[\[ ${x} \]\] |${varsValues[$j]}|g" "$FAHT_WORKINGDIR"/faht-report.fodt
			$DIAG
			(( j++ ));
		done
	done


	$DIAG

	### clean up any unused vars for now...

	sed -i "s|\[\[ .* \]\] ||g" "$FAHT_WORKINGDIR"/faht-report.fodt


	sed -i 's|style-name="RESULTSSTYLE">PASSED|style-name="PASSED">PASSED|g' "$FAHT_WORKINGDIR"/faht-report.fodt
	sed -i 's|style-name="RESULTSSTYLE">FAILED|style-name="FAILED">FAILED|g' "$FAHT_WORKINGDIR"/faht-report.fodt
	sed -i 's|style-name="RESULTSSTYLE">WARNING|style-name="WARNING">WARNING|g' "$FAHT_WORKINGDIR"/faht-report.fodt

}

results_check () {
	### Iterate through tests run, check for failures, give option to check connection and re-test.

	for x in wifi eth audio bluetooth ; do

		declare -n faht_result=FAHT_$(echo ${x^^})_RESULTS

		if [ "${faht_result}" == "FAILED" ] ; then
			confirm_prompt "${x^} test failed. Would you like to re-run the ${x} test again?"
			
			case $prompt_answer in
				y|Y) ${x}_test ;;
				n|N) ;;
			esac
		fi
	done
	
	save_vars
}
