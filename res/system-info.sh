#!/bin/bash

# Get the directory of the script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Specify the destination directory of server-state file.
MAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DESTINATION_DIR="$MAIN_DIR/server-states"


# Function to display cpu info.
get_cpu_info() {
    sh "$SCRIPT_DIR/cpu_info.sh" -p 
}

# Function to convert seconds to a human-readable format
convert_seconds_to_human_readable() {
    local seconds="$1"
    local hours=$((seconds / 3600))
    local minutes=$(( (seconds % 3600) / 60 ))
    local seconds=$((seconds % 60))

    echo "${hours}h ${minutes}m ${seconds}s"
}

# Default values.
output_type="json"
output_file="$DESTINATION_DIR/system_info.json"

# Check for command-line options.
while [ $# -gt 0 ]; do
    case "$1" in
        --json)
            output_type="json"
            shift
            ;;
        --output-file)
            shift
            output_file="$1"
            shift
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
done

# Get current timestamp in Unix format
timestamp=$(date +%s)
# Get human-readable timestamp
human_readable_timestamp=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S")


# System name information.
hostname=$(hostname)
dist_name=$(lsb_release -ds)
kernel_ver=$(uname -sr)
sys_info_from_vars="${dist_name} (${kernel_ver})"
sys_info="$(lsb_release -ds) ($(uname -sr))"

# CPU.
cpu_cores=$(nproc)
last_15min_cpu_percentage=$(get_cpu_info)

# Disk usage.
mount_point="/"
total_disk_avail=$(df -h "$mount_point" | awk -v mp="$mount_point" 'NR==2 {print $2}')
disk_usage_amount=$(df -h "$mount_point" | awk -v mp="$mount_point" 'NR==2 {print $3}')
disk_usage_percentage=$(df -h "$mount_point" | awk -v mp="$mount_point" 'NR==2 {print $5}') # Just percentage string -> 2%

# Memory Usage.
total_memory=$(free -m | awk '/Mem:/ {print $2}')
total_memory_human=$(free -h | awk '/Mem:/ {print $2}')
used_memory=$(free -m | awk '/Mem:/ {print $3}')
used_memory_human=$(free -h | awk '/Mem:/ {print $3}')
memory_usage_percentage=$(echo "scale=2; $used_memory / $total_memory * 100" | bc)

# Swap Usage.
swap_info=$(swapon --show)
swap_info_output=""
if [ -n "$swap_info" ]; then
    swap_info_output="On"
else
    swap_info_output="Off"
fi

# Processes.
amount_processes=$(ps aux | wc -l)

# Logged in users.
logged_in_users=$(who | wc -l)

# Available updates.
sudo apt-get update -qq
updates=$(apt list --upgradable 2>/dev/null)
amount_of_available_updates=""
if [ "${#updates}" -gt 10 ]; then
    amount_of_available_updates=$(apt list --upgradable 2>/dev/null | grep -c '/upgradable')
    updates_available_output="~$amount_of_available_updates updates available"
else
    updates_available_output="no updates available"
    amount_of_available_updates=0
fi


# Check if a system restart is required
restart_required=""
restart_required_timestamp=""
time_elapsed=0
if [ -f /var/run/reboot-required ]; then
    restart_required="System restart required"
    restart_required_timestamp=$(stat -c %Y /var/run/reboot-required)
    time_elapsed=$((timestamp - restart_required_timestamp))
else
    restart_required="No restart required"
fi

# Calculate time elapsed since restart required.
time_elapsed_human_readable=$(convert_seconds_to_human_readable "$time_elapsed")



# This tools state.
repo_url=https://github.com/Sokrates1989/linux-server-status.git
repo_accessible="unknown"
local_changes="unknown"
up_to_date="unknown"
behind_count="unknown"

# Check remote connection.
if git ls-remote --exit-code $repo_url >/dev/null 2>&1; then
    repo_accessible="True"

    # Check local changes.
    if [ -n "$(git status --porcelain)" ]; then
        local_changes="Yes"
    else
        local_changes="None"
    fi

    # Check for upstream changes.
    git fetch
    behind_count=$(git rev-list HEAD..origin/main --count)
    if [ "$behind_count" -gt 0 ]; then
        up_to_date="False"
    else
        up_to_date="True"
        behind_count=0
    fi
else
    repo_accessible="False"
fi


# Create JSON string
json_data=$(cat <<EOF
{
  "timestamp": {
    "unix_format": $timestamp,
    "human_readable_format": "$human_readable_timestamp"
  },
  "system_info": {
    "hostname": "$hostname",
    "dist_name": "$dist_name",
    "kernel_ver": "$kernel_ver",
    "sys_info": "$sys_info"
  },
  "cpu": {
    "cpu_cores": "$cpu_cores",
    "last_15min_cpu_percentage": "$last_15min_cpu_percentage"
  },
  "disk": {
    "mount_point": "$mount_point",
    "total_disk_avail": "$total_disk_avail",
    "disk_usage_amount": "$disk_usage_amount",
    "disk_usage_percentage": "$disk_usage_percentage"
  },
  "memory": {
    "total_memory": "$total_memory",
    "total_memory_human": "$total_memory_human",
    "used_memory": "$used_memory",
    "used_memory_human": "$used_memory_human",
    "memory_usage_percentage": "$memory_usage_percentage"
  },
  "swap": {
    "swap_status": "$swap_info_output"
  },
  "processes": {
    "amount_processes": "$amount_processes"
  },
  "users": {
    "logged_in_users": "$logged_in_users"
  },
  "updates": {
    "amount_of_available_updates": "$amount_of_available_updates",
    "updates_available_output": "$updates_available_output"
  },
  "system_restart": {
    "status": "$restart_required",
    "time_elapsed_seconds": "$time_elapsed",
    "time_elapsed_human_readable": "$time_elapsed_human_readable"
  },
  "linux_server_state_tool": {
    "repo_url": "$repo_url",
    "repo_accessible": "$repo_accessible",
    "local_changes": "$local_changes",
    "up_to_date": "$up_to_date",
    "behind_count": "$behind_count"
  }
}
EOF
)

# Write JSON string to file
echo "$json_data" > "$output_file"
echo "$json_data"

echo "System information has been saved to $output_file with timestamp $timestamp"

