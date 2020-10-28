#!/bin/bash

reboot_towin () {
	echo "-----------------------------------------------"
	echo "Updating bootloader and booting into Windows..."
	sudo update-grub
	WINDOWS_BOOT=`grep -i "windows" /boot/grub/grub.cfg|head -n 1|cut -d"'" -f2`
	sudo /usr/sbin/grub-reboot "$WINDOWS_BOOT"
	sudo /sbin/reboot
}

reboot_tomemtest() {
	echo "-------------------------------------------------"
	echo "Updating bootloader and booting into Memtest86..."
	if [ -d /sys/firmware/efi ]; then
		MEMTEST_BOOT=`grep "Memtest" /boot/grub/grub.cfg |cut -d"'" -f2`
		sudo /usr/sbin/grub-reboot "$MEMTEST_BOOT"
	else
		MEMTEST_BOOT=`grep "(memtest86+)" /boot/grub/grub.cfg |tail -n1|cut -d"'" -f2`
		sudo /usr/sbin/grub-reboot "$MEMTEST_BOOT"
	fi

	$DIAG

	FAHT_NEXT_STAGE=finish_memtest
	save_vars
	sudo reboot
}
