#!/bin/bash
clear
wait ${!}
export PS1="\e[0;31m[\u@\h \W]\$ \e[m "
cat $HOME/boottime.txt
sleep 60
