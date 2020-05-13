#!/bin/sh
echo "--------------------------------------------------------------------------"
echo 
echo "Syncing FAHT Reports to THE BEAST - /home/PublicShare/FAHT-Reports"
echo
echo "Please enter the password for THE BEAST. Hint=six"
echo
echo "--------------------------------------------------------------------------"


scp -rp /mnt/usbdata/faht-tests/* techtutors@192.168.1.51:/home/PublicShare/FAHT-Reports/
