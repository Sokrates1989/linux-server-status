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

# Check for available updates.
updates=$(apt list --upgradable 2>/dev/null)
if [ -n "$updates" ]; 
then
    echo "\n\nAvailable Updates:"
    
    # Tell user how to apply them.
    echo "\nTo update you can use this:"
    echo "\nsudo apt-get -y update && sudo apt-get -y upgrade"
    
    echo "\n\nIf there are still updates remaining, try these:"
    echo "\nsudo apt-get --with-new-pkgs upgrade <list of packages kept back>"
    echo "\nsudo apt-get install <list of packages kept back>"
    
    echo "\n\nAggressive solutions are available. Read link. Try above 2 first!"
    echo "\nhttps://askubuntu.com/questions/601/the-following-packages-have-been-kept-back-why-and-how-do-i-solve-it"

    # Display the updates.
    echo "\n$updates"
else
    echo "\n\nNo available updates."
fi


echo "\n\nLast Login Information:"
last
