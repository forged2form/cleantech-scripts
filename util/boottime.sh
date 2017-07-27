#1/bin/bash

sudo echo Starting Boot Timer
rm $HOME/boottime.txt
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Users/timconrad/Desktop/startup.command.app", hidden:false}'
echo `date +%s` > $HOME/boottime.txt
sudo reboot now
