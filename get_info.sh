#!/bin/bash

echo "System Information:"
uname -a

echo -e "\nDisk Usage:"
df -h /

echo -e "\nMemory Usage:"
free -m

echo -e "\nSwap Usage:"
swapon --show

echo -e "\nProcesses:"
ps aux | wc -l

echo -e "\nLogged-in Users:"
who

echo -e "\nNetwork Information:"
ip a

echo -e "\nAvailable Updates:"
apt list --upgradable

echo -e "\nLast Login Information:"
last
