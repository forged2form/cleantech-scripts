#!/bin/bash

### parsing_fns.sh
###
### Functions related to parsing results for FAHT test + outputting to file

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

save_vars ()
{
	diskarray_to_flatvars

	( set -o posix; set ) | grep FAHT > "$FAHT_WORKINGDIR"/raw_vars.txt
	cat "$FAHT_WORKINGDIR"/raw_vars.txt|grep -v ARRAY > "$FAHT_WORKINGDIR"/vars_noarray.txt

	sed -r 's/(FAHT_.*)=.*/\1/g' "$FAHT_WORKINGDIR"/vars_noarray.txt > "$FAHT_WORKINGDIR"/varsnames.txt
	sed -r 's/.*=(.*)/\1/g' "$FAHT_WORKINGDIR"/vars_noarray.txt > "$FAHT_WORKINGDIR"/varsvalues.txt


	i=0
	varsNames=()
	varsvalues=()

	while IFS= read line; do
		varsNames[$i]=$line
		echo ${varsNames[$i]}
		(( i++ ));
	done < "$FAHT_WORKINGDIR"/varsnames.txt

	i=0

	while IFS= read line; do
		varsValues[$i]=$line
		echo ${varsValues[$i]}
		(( i++ ));
	done < "$FAHT_WORKINGDIR"/varsvalues.txt

	i=0

	cp /usr/share/faht/faht-report-template.fodt "$FAHT_WORKINGDIR"/faht-report.fodt

	### Remove single quotes from values...

	for index in ${!varsValues[@]}; do
		varsValues[$index]=$(echo ${varsValues[$index]//\'/})
	done

	for x in ${varsNames[@]}; do
		echo "Working on $x..."
		sed -i "s| \[\[ ${x} \]\] |${varsValues[$i]}|g" "$FAHT_WORKINGDIR"/faht-report.fodt
		(( i++ ));
	done

	### clean up any unused vars for now...

	sed -i "s| \[\[ .* \]\] ||g" "$FAHT_WORKINGDIR"/faht-report.fodt

}
