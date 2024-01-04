#!/bin/bash

# Output format like this:
# sampleText1               : sampleText2
# Can be achieved using this:
# printf '%-30s: %s\n' "sampleText1" "sampleText2"
# https://unix.stackexchange.com/questions/396223/bash-shell-script-output-alignment
output_tab_space=28 # The space until the colon to align all output info to
networking_tab_space=28 # The space until the colon to align all output info to
# printf "%-${output_tab_space}s: %s\n" "sampletext1" "sampleText2"


# Get the directory of the script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to display cpu usage.
display_cpu_info() {
    sh "$SCRIPT_DIR/cpu_info.sh" -s -t $output_tab_space # To display short info with tab space
}


# System name information.
echo "\nSystem information\n"
dist_name=$(lsb_release -ds)
kernel_ver=$(uname -sr)
sys_info_from_vars="${dist_name} (${kernel_ver})"
sys_info="$(lsb_release -ds) ($(uname -sr))"
printf "%-${output_tab_space}s: %s\n" "System name" "$sys_info"

# Spacer.
echo ""

# CPU Usage.
display_cpu_info

# Disk usage.
mount_point="/"
df_output=$(df -h "$mount_point" | awk -v mp="$mount_point" 'NR==2 {printf "%s of %s (%s)", $5, $2, $3}')
printf "%-${output_tab_space}s: %s\n" "Disk Usage of $mount_point" "$df_output"


# Memory Usage.
total_memory=$(free -m | awk '/Mem:/ {print $2}')
total_memory_human=$(free -h | awk '/Mem:/ {print $2}')
used_memory=$(free -m | awk '/Mem:/ {print $3}')
used_memory_human=$(free -h | awk '/Mem:/ {print $3}')
memory_usage_percentage=$(echo "scale=2; $used_memory / $total_memory * 100" | bc)
printf "%-${output_tab_space}s: %s\n" "Memory Usage" "$memory_usage_percentage% of $total_memory_human ($used_memory_human)"

# Swap Usage.
swap_info=$(swapon --show)
if [ -n "$swap_info" ]; then
    printf "%-${output_tab_space}s: %s\n" "Swap Usage" "Swap is in use"
    echo "$swap_info"
else
    printf "%-${output_tab_space}s: %s\n" "Swap Usage" "No active swap"
fi


# Spacer.
echo ""

# Processes.
amount_processes=$(ps aux | wc -l)
printf "%-${output_tab_space}s: %s\n" "Processes" "$amount_processes"

# Logged in users.
logged_in_users=$(who | wc -l)
printf "%-${output_tab_space}s: %s\n" "Users logged in" "$logged_in_users"


# Spacer.
echo ""

# Ipv4 Adresses.
ip -4 a | awk -v tab_space="$networking_tab_space" '/inet/ {printf "%-"tab_space"s: %s\n", "IPv4 of "$NF, $2}'


# Spacer.
echo ""

# Available updates.
updates=$(apt list --upgradable 2>/dev/null)
if [ "${#updates}" -gt 10 ]; # Checks length of updates var, because also a fully updated system returns the string "Listing..."
then
    printf "%-${output_tab_space}s: %s\n" "Updates Available" "Yes (use -u option to view all available updates -> sh path/to/get_info.sh -u )"
else
    printf "%-${output_tab_space}s: %s\n" "Updates Available" "No"
fi

# Spacer.
echo "\n"
echo "To view full system report use -f option -> sh path/to/get_info.sh -f  "
echo ""


