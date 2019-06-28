#!/bin/bash

reboot_towin () {
	echo "-----------------------------------------------"
	echo "Updating bootloader and booting into Windows..."
	update-grub
	winreboot
}
