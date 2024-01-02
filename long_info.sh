#!/bin/bash

# Function to display available system updates.
display_update_info() {
    sh ./update_info.sh
}

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

echo "\n\nLast Login Information:"
last

echo "\n\nNetwork Information:"
ip a

# Update info.
echo "\n\n"
display_update_info
