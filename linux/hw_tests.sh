#!/bin/bash

### hw_tests.sh
###
### Library for testing functions for various HW other than disks

proc_bench () {
	### Processor test - Benchmark ###
	echo
	echo -------------------------------
	echo Benchmarking CPU... Please wait
	echo -------------------------------
	$DIAG
	echo
	7z b
}

proc_stress () {

}

proc_test () {
	echo "Sorry, not implemented yet..."
}

eth_test () {
	### Network test - Ethernet ###
	echo
	echo -------------------------------
	echo Testing Ethernet... Please wait
	echo -------------------------------
	$DIAG
	echo

	FAHT_ETH="$(ip -o link|grep -i -E ": en.* "\d*|sed -r 's/[0-9]: (en.*): .*/\1/g')"

	if [ ! "$FAHT_ETH" ]; then	
		FAHT_ETH_RESULTS="n/a"
	fi

	if [ "$FAHT_ETH" ]; then
		for p in "$FAHT_ETH"; do
			ping -c 5 -I $p 1.1.1.1
			FAHT_ETH_TEST=$?
		done > "$FAHT_WORKINGDIR"/ethtest-$p.txt
		
		if [ "$FAHT_ETH_TEST" -eq 0 ]; then
			FAHT_ETH_RESULTS="PASSED"
		else
			FAHT_ETH_RESULTS="FAILED"
		fi
	fi

	echo "${FAHT_ETH_RESULTS}!"
	echo
}

wifi_test () {
### Network test - Wireless ###
### FIXME: Doesn't fail gracefully. GET IT!
	echo -----------------------------
	echo Testing Wi-Fi.... Please wait
	echo -----------------------------
	$DIAG
	echo

	FAHT_WIFI="$(ip -o link|grep -i -E ": wl.* "\d*|sed -r 's/[0-9]: (wl.*): .*/\1/g')"
	
	if [ ! "$FAHT_WIFI" ]; then	
		FAHT_WIFI_RESULTS="n/a"
	fi

	if [ "$FAHT_WIFI" ]; then
		for p in "$FAHT_WIFI"; do
			ping -c 5 -I $p 1.1.1.1
			FAHT_WIFI_TEST=$?
		done > "$FAHT_WORKINGDIR"/ethtest-$p.txt
		
		if [ "$FAHT_WIFI_TEST" -eq 0 ]; then
			FAHT_WIFI_RESULTS="PASSED"
		else
			FAHT_WIFI_RESULTS="FAILED"
		fi
	fi

	#if [ $FAHT_WIFI ]; then
	#	for p in $FAHT_WIFI; do
	#		ping -c 5 -I $p 1.1.1.1
	#		FAHT_WIFI_RESULTS=$?
	#	done > $FAHT_WORKINGDIR/wifitest-$p.txt
	#fi
	#if [ ! $FAHT_WIFI ]; then
	#	$FAHT_WIFI_RESULTS="n/a"
	#fi

	#if [ ! "$FAHT_WIFI" ] || [ "$FAHT_WIFI_RESULTS" -gt 0 ]
	#then
	#	FAHT_WIFI_RESULTS="FAILED"
	#else
	#	FAHT_WIFI_RESULTS="PASSED"
	#fi

	echo "${FAHT_WIFI_RESULTS}!"
	echo
}

init_memtest () {
	# Hackish way to clear old reports for now...

	#OLD_REPORTS_DIR=$(sudo )

#	if sudo test -d "/boot/efi/EFI/memtest/oldreports"; then
#		sudo mkdir /boot/efi/EFI/memtest/oldreports
#	fi

	if [ "$FAHT_MEMTEST" == "ON" ]; then

		sudo bash -c 'mv /boot/efi/EFI/memtest/*.html /boot/efi/EFI/memtest/oldreports'

		$DIAG

		#FAHT_CURR_
		save_vars
		
		reboot_tomemtest
	else
		echo "Memtest not set! Skipping..."
	fi
}

finish_memtest () {

	if [ "$FAHT_MEMTEST" == "ON" ]; then
		echo "-------"
		echo "Importing Memtest results"

		if [ -d /sys/firmware/efi ]; then
			export FAHT_MEMTEST_REPORT_FILE="${FAHT_WORKINGDIR}"/memtest.html
			echo Copying HTML report file to $FAHT_WORKINGDIR
			export MT_FILE=$(sudo bash -c 'ls /boot/efi/EFI/memtest/*.html')
			sudo bash -c 'cp ${0} ${1}' "$MT_FILE" "$FAHT_MEMTEST_REPORT_FILE"
			memtest_parsing
			sudo rm $MT_FILE
			echo Importing results
		fi
	else
		echo "Memtest not set! Skipping..."
	fi
}

audio_test ()
{
	### Audio test ###
	echo	
	echo ----------------------------
	echo Testing Audio... Please wait
	echo ----------------------------
	$DIAG
	echo

	audio_test_complete=0

	while [[ "$audio_test_complete" -eq 0 ]]; do
	amixer -D pulse sset Master 80% unmute

		for i in {1..3}; do
			mplayer /usr/share/faht/starcmd.m4a > /dev/null 2>&1
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

	echo "${FAHT_AUDIO_RESULTS}!"
}

gfx_test ()
{
### GFX Benchmark ###
echo -------------------------------
echo Testing GFX card... Please wait
echo -------------------------------
$DIAG
echo

glmark2|grep Score>"$FAHT_WORKINGDIR"/glmark2.txt

FAHT_GFX_BENCH="$(cat "$FAHT_WORKINGDIR"/glmark2.txt|sed -r 's/.*: ([0-9]*) /\1/g')"

if [[ "$FAHT_GFX_BENCH" -gt "100" ]]; then
	FAHT_GFX_STRESS_TEST_RESULTS=PASSED
else
	FAHT_GFX_STRESS_TETS_RESULTS=FAILED
fi

confirm_prompt "Does the internal display appear to be working?"

case $prompt_answer in
	y|Y) FAHT_DISPLAY_TEST_RESULTS=PASSED ;;
	n|N) FAHT_DISPLAY_TEST_RESULTS=FAILED ;;
esac

}
