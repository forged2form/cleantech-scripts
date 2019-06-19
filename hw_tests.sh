#!/bin/bash

### hw_tests.sh
###
### Library for testing functions for various HW other than disks

eth_test () {
	### Network test - Ethernet ###
	clear
	echo -------------------------------
	echo Testing Ethernet... Please wait
	echo -------------------------------
	$DIAG
	echo

	FAHT_ETH="$(ip -o link|grep -i -E ": en.* "\d*|sed -r 's/[0-9]: (en.*): .*/\1/g')"

	if [ $FAHT_ETH ]
	then
		for p in $FAHT_ETH; do
			ping -c 5 -I $p 1.1.1.1
			FAHT_ETH_RESULTS=$?
		done > $FAHT_WORKINGDIR/ethtest-$p.txt
	else
		$FAHT_ETH_RESULTS="N/A"
	fi

	if [ "$FAHT_ETH_RESULTS" -gt 0 ]
	then
		FAHT_ETH_RESULTS="FAILED"
	else
		FAHT_ETH_RESULTS="PASSED"
	fi
}

#temp eth_test

wifi_test () {
### Network test - Wireless ###
### FIXME: Doesn't fail gracefully. GET IT!
	echo -----------------------------
	echo Testing Wi-Fi.... Please wait
	echo -----------------------------
	$DIAG
	echo

	FAHT_WIFI="$(ip -o link|grep -i -E ": wl.* "\d*|sed -r 's/[0-9]: (wl.*): .*/\1/g')"

	if [ $FAHT_WIFI ]
	then
		for p in $FAHT_WIFI; do
			ping -c 5 -I $p 1.1.1.1
			FAHT_WIFI_RESULTS=$?
		done > $FAHT_WORKINGDIR/wifitest-$p.txt
	else
		$FAHT_WIFI_RESULTS="N/A"
	fi

	if [ "$FAHT_WIFI_RESULTS" -gt 0 ]
	then
		FAHT_WIFI_RESULTS="FAILED"
	else
		FAHT_WIFI_RESULTS="PASSED"
	fi
}

#temp wifi_test

audio_test ()
{
	### Audio test ###
	clear
	echo ----------------------------
	echo Testing Audio... Please wait
	echo ----------------------------
	$DIAG
	echo

	audio_test_complete=0

	while [[ "$audio_test_complete" -eq 0 ]]; do
	amixer -D pulse sset Master 100%

		for i in {1..3}; do
			mplayer /usr/share/faht/starcmd.m4a;
		done

		amixer -D pulse sset Master 40%

		confirm_prompt "Did you hear the test tone?"

		case $prompt_answer in
			y|Y) FAHT_AUDIO_RESULTS=PASSED ;;
			n|N) FAHT_AUDIO_RESULTS=FAILED ;;
		esac

		if [ "$FAHT_AUDIO_RESULTS" == "FAILED" ]
		then
			confirm_prompt "Were you even listening?"

			case $prompt_answer in
				y|Y) audio_test_complete=1 ;;
				n|N) ;;
			esac
		else
			audio_test_complete=1
		fi	
	done
}

#temp audio_test



### Appears to get reset with function declaration...

#	declare -A FAHT_SMART_DRIVES_ARRAY

#	for i in $(echo "$(smartctl --scan| grep -v $FAHT_LIVE_DEV| sed -n 's/\/dev\/\([a-z][a-z][a-z]\).*/\1/gp')"); do
#		FAHT_SMART_DRIVES_ARRAY[$j]="$i"
#		echo $j
#		echo FAHT_SMART_DRIVES_ARRAY[$j] = ${FAHT_SMART_DRIVES_ARRAY[$j]}
#		echo
#		((j++));
#	done

gfx_test ()
{
### GFX Benchmark ###
clear
echo -------------------------------
echo Testing GFX card... Please wait
echo -------------------------------
$DIAG
echo

glmark2|grep Score>"$FAHT_WORKINGDIR"/glmark2.txt

FAHT_GFX_BENCH="$(cat "$FAHT_WORKINGDIR"/glmark2.txt|sed -r 's/.*: ([0-9]*) /\1/g')"
}