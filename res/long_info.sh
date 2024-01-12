#!/bin/bash

# Get the directory of the script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to display available system updates.
display_update_info() {
    sh "$SCRIPT_DIR/update_info.sh"
}

# Function to display cpu usage.
display_cpu_info() {
    sh "$SCRIPT_DIR/cpu_info.sh" -l  # To display long info.
}

# Function to convert seconds to a human-readable format
convert_seconds_to_human_readable() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(( (seconds % 3600) / 60 ))
    local seconds=$((seconds % 60))

    echo "${hours}h ${minutes}m ${seconds}s"
}


# Output system info.
echo "\nSystem Information:"
uname -a

echo "\n\nCpu Usage:"
display_cpu_info

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



# Restart required?
echo "\n\n"
timestamp=$(date +%s)
restart_required_timestamp=""
if [ -f /var/run/reboot-required ]; then
    restart_required_timestamp=$(stat -c %Y /var/run/reboot-required)
    time_elapsed=$((timestamp - restart_required_timestamp))
    time_elapsed_human_readable=$(convert_seconds_to_human_readable "$time_elapsed")
    echo "System restart required since $time_elapsed_human_readable"
else
    echo "No restart required"
fi
