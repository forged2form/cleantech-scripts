#!/bin/bash

### parsing_fns.sh
###
### Functions related to parsing results for FAHT test + outputting to file

save_vars ()
{
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

	for x in ${varsNames[*]}; do
		echo "Working on $x..."
		sed -i "s| \[\[ $x \]\] |${varsValues[$i]}|g" "$FAHT_WORKINGDIR"/faht-report.fodt
		(( i++ ));
	done

	for x in name serial totalsize windowspartfreespace timeon readspeed writespeed smart_results totalsize_results; do
		sed -i "s| \[\[ FAHT_TEST_DISK_1_ARRAY\[$x\] \]\] |${FAHT_TEST_DISK_1_ARRAY[$x]}|g" "$FAHT_WORKINGDIR"/faht-report.fodt
	done

	### clean up any unused vars for now...

	sed -i "s| \[\[ .* \]\] ||g" "$FAHT_WORKINGDIR"/faht-report.fodt

	#cp /tmp/vars*.txt "$FAHT_WORKINGDIR"/
}
