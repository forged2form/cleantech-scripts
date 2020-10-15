#!/bin/bash

reboot_towin () {
	echo "-----------------------------------------------"
	echo "Updating bootloader and booting into Windows..."
	sudo update-grub
	sudo winreboot
}
