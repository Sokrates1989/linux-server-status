#!/bin/bash

# Default values.
info_type="short"
tab_space_default=28
tab_space=$tab_space_default

# Parse command-line options.
while getopts ":l:s:t:" opt; do
  case $opt in
    l)
      info_type="long"
      ;;
    s)
      info_type="short"
      ;;
    t)
      # Only takes effect when using -s (short) option.
      tab_space=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Validate tab_space only when using short option.
if [ "$info_type" = "short" ]; then
  if [ "$tab_space" -lt 1 ]; then
    echo "Error: Tab space must be a positive integer." >&2
    exit 1
  fi
fi

# Get the number of CPU cores.
cpu_cores=$(nproc)

# Get the load averages and assign them to variables.
# Use the uptime command for load averages.
load_allmin=$(uptime | awk -F'average:' '{print $2}')
# Remove commas from the load_allmin variable.
load_allmin=$(echo "$load_allmin" | tr -d ',')
# Extract individual load averages and assign them to variables.
load_1min=$(echo "$load_allmin" | awk '{print $1}')
load_5min=$(echo "$load_allmin" | awk '{print $2}')
load_15min=$(echo "$load_allmin" | awk '{print $3}')

# Calculate the percentage of system load for each duration.
load_percent_1min=$(echo "scale=2; $load_1min / $cpu_cores * 100" | bc)
load_percent_5min=$(echo "scale=2; $load_5min / $cpu_cores * 100" | bc)
load_percent_15min=$(echo "scale=2; $load_15min / $cpu_cores * 100" | bc)

# Print the results based on info_type.
if [ "$info_type" = "short" ]; then
  # Print with tab space.
  printf "%-${tab_space}s: %s\n" "CPU Usage" "$load_percent_15min% (last 15 minutes)"
elif [ "$info_type" = "long" ]; then
  echo "Number of CPU cores: $cpu_cores"
  echo "1-minute load percentage: $load_percent_1min%"
  echo "5-minute load percentage: $load_percent_5min%"
  echo "15-minute load percentage: $load_percent_15min%"
else
  echo "Invalid info_type: $info_type"
  exit 1
fi
