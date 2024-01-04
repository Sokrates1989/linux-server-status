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
if [[ "$info_type" == "short" ]]; then
  if ((tab_space < 1)); then
    echo "Error: Tab space must be a positive integer." >&2
    exit 1
  fi
fi

# Get the number of CPU cores.
cpu_cores=$(nproc)

# Get the load averages and assign them to variables.
# read -r load_1min load_5min load_15min <<< "$(uptime | awk -F'average:' '{print $2}')"
tempfile=$(mktemp)
uptime | awk -F'average:' '{print $2}' > "$tempfile"
read -r load_1min load_5min load_15min < "$tempfile"
rm "$tempfile"  # Clean up the temporary file.

# Calculate the percentage of system load for each duration.
load_percent_1min=$(echo "scale=2; $load_1min / $cpu_cores * 100" | bc)
load_percent_5min=$(echo "scale=2; $load_5min / $cpu_cores * 100" | bc)
load_percent_15min=$(echo "scale=2; $load_15min / $cpu_cores * 100" | bc)

# Calculate the average load percentage.
average_load_percent=$(echo "scale=2; ($load_percent_1min + $load_percent_5min + $load_percent_15min) / 3" | bc)

# Print the results based on info_type.
if [[ "$info_type" == "short" ]]; then
  # Print with tab space.
  printf "%-$tab_space}s: %s\n" "CPU Usage" "$average_load_percent"
elif [[ "$info_type" == "long" ]]; then
  echo "Number of CPU cores: $cpu_cores"
  echo "1-minute load percentage: $load_percent_1min%"
  echo "5-minute load percentage: $load_percent_5min%"
  echo "15-minute load percentage: $load_percent_15min%"
  echo "Average load percentage: $average_load_percent%"
else
  echo "Invalid info_type: $info_type"
  exit 1
fi
