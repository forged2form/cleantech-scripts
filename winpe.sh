#!/bin/bash

sudo qemu-system-x86_64 -m 1024 -drive if=ide,media=disk,format=raw,file=/dev/sda -drive if=ide,media=cdrom,file=/root/WinPE_amd64.iso -boot order=dc

