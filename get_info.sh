#!/bin/bash

echo "\nSystem Information:"
uname -a

echo "\n\nDisk Usage:"
df -h /

echo "\n\nMemory Usage:"
free -h
# Calculate percentage of memory usage.
total_memory=$(free -m | awk '/Mem:/ {print $2}')
used_memory=$(free -m | awk '/Mem:/ {print $3}')
memory_usage_percentage=$(echo "scale=2; $used_memory / $total_memory * 100" | bc)
echo "Use%: $memory_usage_percentage%" 

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
if [[ "$updates" =~ "[upgradable]" ]];
then
    # Display the updates.
    echo "\n\nAvailable Updates:"
    echo "$updates"
    
    # Tell user how to apply them.
    echo "\nTo update you can use this:"
    echo "sudo apt-get -y update && sudo apt-get -y upgrade"
    
    echo "\nIf there are still updates remaining, try these:"
    echo "sudo apt-get --with-new-pkgs upgrade <list of packages kept back>"
    echo "sudo apt-get install <list of packages kept back>"
    
    echo "\nAggressive solutions are available. Read link. Try above 2 first!"
    echo "https://askubuntu.com/questions/601/the-following-packages-have-been-kept-back-why-and-how-do-i-solve-it"
else
    echo "\n\nNo available updates."
fi


echo "\n\nLast Login Information:"
last
