#!/bin/bash

# Get the directory of the script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to display available system updates.
display_update_info() {
    sh "$SCRIPT_DIR/update_info.sh"
}

# Function to display cpu usage.
display_cpu_info() {
    sh "$SCRIPT_DIR/cpu_info.sh" -l  # To display long info.
}

# Function to display network usage.
display_network_info() {
    sh "$SCRIPT_DIR/network_info.sh" -l  # To display long info.
}

# Function to convert seconds to a human-readable format.
convert_seconds_to_human_readable() {
    # Parameters of this function.
    local seconds="$1"

    # Conversion.
    local days=$((seconds / 86400))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local seconds=$((seconds % 60))

    # Concatenate result.
    local result=""
    if [ "$days" -gt 0 ]; then
        result="${days}d "
    fi
    result+="${hours}h ${minutes}m ${seconds}s"

    # Return result.
    echo "$result"
}

# Output system info.
echo "\nSystem Information:"
hostname=$(hostname)
echo "Hostname: $hostname" 
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

echo "\n\nNetwork:"
display_network_info

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


# Is the repo of this project itself up to date?
echo "\n\n"

# Save the current directory to be able to revert back again to it later.
current_dir=$(pwd)
# Change to the Git repository directory to make git commands work.
cd $MAIN_DIR

# Check remote connection.
repo_url=https://github.com/Sokrates1989/linux-server-status.git
if git ls-remote --exit-code $repo_url >/dev/null 2>&1; then
    echo "Remote repository $repo_url is accessible."

    # Check local changes.
    if [ -n "$(git status --porcelain)" ]; then
        echo "There are local changes. Please commit or stash your changes before pulling."
    fi

    # Check for upstream changes.
    git fetch -q
    behind_count=$(git rev-list HEAD..origin/main --count)
    if [ "$behind_count" -gt 0 ]; then
        echo "The local repository is $behind_count commits behind the remote repository. Pull is recommended."
        
        # Print user info how to update repo.
        echo "\nTo Update repo do this:"
        echo "cd $MAIN_DIR"
        echo "git pull\n"
        
    else
        echo "No changes in the remote repository."
    fi
else
    echo "Error: Remote repository $repo_url is not accessible."
fi

# Revert back to the original directory.
cd "$current_dir"
