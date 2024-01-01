#!/bin/bash

echo "\nSystem Information:"
uname -a

echo "\n\nDisk Usage:"
df -h /

echo "\n\nMemory Usage:"
free -m

echo "\n\nSwap Usage:"
swapon --show

echo "\n\nProcesses:"
ps aux | wc -l

echo "\n\nLogged-in Users:"
who

echo "\n\nNetwork Information:"
ip a

echo "\n\nAvailable Updates:"
apt list --upgradable

echo "\n\nLast Login Information:"
last
