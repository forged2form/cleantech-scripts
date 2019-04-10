!/bin/bash

echo "--------------------------------------"
echo "TechTutors Windows Image Update Script"
echo "--------------------------------------"
echo
echo This script simply walks the user through the process
echo of going methodically through the TechTutor\'s Win10 vm
echo images and updating drivers, fresh installing major OS
echo versions, adding/updating apps, and customizing Windows
echo to \"not suck\".
echo
echo It 

Step 1) Set BIOS VM to settings
Name: win10-image-bios
Eth: e1000
CD: Win10-Latest.iso
HDD: Win10Home-TT-BIOS.img

Step 2) Install Windows 10 Home
Step 3) Install latest updatesz
Step 4) Reboot VM
Step 5) Run Customization script
Step 6) Reboot again
Setp 7) Remove all TT files / recents
Step 8) Double check system (LibreOffice defaults, Chrome, Adobe)
Step 9) Shutdown VM
Step 10) Set boot to PXE
Step 11) Boot into clonedeploy
Step 12) Upload to Existing image (Win10-TT-BIOS-CUSTO)
Step 13) Shutdown VM
Step 14) Change ISO to Win10 iso if needed
Step 15) Make copy of disk image
code: rsync -avhP /media/techtutors/ScratchDisk/vm/Win10Home-TT-BIOS.img /media/techtutors/ScratchDisk/vm/Win10Home-TT-UEFI.img
Step 16) Set UEFI VM to settings
Name: win10-image-uefi
Eth: e1000
CD: Win10-Latest.iso
HDD: Win10Home-TT-UEFI.img
Step 17) Boot into WinPE
Step 18) Convert disk to GPT
code: mbr2gpt /disk:0 /validate
code: mbr2gpt /disk:0 /convert
!!!NOTE!!! Should be able to automate this with a customized
Step 20) Boot to EFI disk to verify
Step 21) Shutdown VM
Step 22) Change ISO to clonedeploy client ISO
Step 23) 