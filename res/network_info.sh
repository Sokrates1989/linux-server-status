#!/bin/bash

# Function to convert units to bytes.
convert_to_bytes() {
    local value=$1
    local unit=$2

    case $unit in
        KiB) echo "$value * 1024" | bc;;
        MiB) echo "$value * 1024^2" | bc;;
        GiB) echo "$value * 1024^3" | bc;;
        *) echo "$value";;
    esac
}

# Function to format values in Kbit/s, Mbit/s, or bit/s.
format_speed() {
    local speed=$1
    if [ $(echo "$speed >= 1000000" | bc -l) -eq 1 ]; then
        echo "$(echo "scale=2; $speed / 1000000" | bc) Mbit/s"
    elif [ $(echo "$speed >= 1000" | bc -l) -eq 1 ]; then
        echo "$(echo "scale=2; $speed / 1000" | bc) kbit/s"
    else
        echo "$speed bit/s"
    fi
}

# Default values.
info_type="short"
output_type="default"
tab_space_default=28
tab_space=$tab_space_default
duration_seconds=3600  # Assuming 1 hour duration for average calculation.

# Parse command-line options.
while getopts ":abdhlst:u" opt; do
  case $opt in
    a)
      # Aggregate both up and downstream -> total.
      info_type="total"
      ;;
    b)
      # Output in bytes.
      output_type="bytes"
      ;;
    d)
      # DownsStream.
      info_type="downstream"
      ;;
    h)
      # Output in human readable format.
      output_type="human"
      ;;
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
    u)
      # Upstream.
      info_type="upstream"
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

# Is vnstat enabled?
vnstab_is_installed=true
enough_data=true
error_info_msg=""
vnstat_command=$(command -v vnstat)
if [ -n "$vnstat_command" ]; then
    vnstab_is_installed=true

    # Enough data?
    line_count=$(vnstat -h | grep -E '[0-9]{2}:[0-9]{2}' | tail -n 2 | wc -l )
    if [ "$line_count" -lt 2 ]; then
      enough_data=false
      error_info_msg="There is not enough data yet"
    else
      # rx traffic (received data) of the last hour.
      # We use the second to last line as the last line uses the ongoing hour and therefore it is unsafe to calculate with.
      rx_last_hour=$(vnstat -h | grep -E '[0-9]{2}:[0-9]{2}' | tail -n 2 | head -n 1 | awk '{print $2}')
      rx_unit=$(vnstat -h | grep -E '[0-9]{2}:[0-9]{2}' | tail -n 2 | head -n 1 | awk '{print $3}')
      rx_last_hour_bytes=$(convert_to_bytes "$rx_last_hour" "$rx_unit")
      rx_avg_last_hour_bits=$(echo "scale=2; $rx_last_hour_bytes / $duration_seconds * 8" | bc)
      rx_avg_last_hour_human=$(format_speed $rx_avg_last_hour_bits)

      # tx traffic (transmitted data) of the last hour.
      # We use the second to last line as the last line uses the ongoing hour and therefore it is unsafe to calculate with.
      tx_last_hour=$(vnstat -h | grep -E '[0-9]{2}:[0-9]{2}' | tail -n 2 | head -n 1 | awk '{print $5}')
      tx_unit=$(vnstat -h | grep -E '[0-9]{2}:[0-9]{2}' | tail -n 2 | head -n 1 | awk '{print $6}')
      tx_last_hour_bytes=$(convert_to_bytes "$tx_last_hour" "$tx_unit")
      tx_avg_last_hour_bits=$(echo "scale=2; $tx_last_hour_bytes / $duration_seconds * 8" | bc)
      tx_avg_last_hour_human=$(format_speed $tx_avg_last_hour_bits)

      # Total traffic (transmitted and received data) of the last hour.
      traffic_total_last_hour=$(echo "scale=2; $tx_last_hour_bytes + $rx_last_hour_bytes" | bc)
      traffic_total_avg_last_hour_bits=$(echo "scale=2; $traffic_total_last_hour / $duration_seconds * 8" | bc)
      traffic_total_avg_last_hour_human=$(format_speed $traffic_total_avg_last_hour_bits)
    fi

else
    vnstab_is_installed=false
    enough_data=false
    error_info_msg="vnstab is not installed"
fi


# Check if tool is installed and enough data.
if [ "$vnstab_is_installed" = true ] && [ "$enough_data" = true ]; then

  # Print the results based on info_type.
  if [ "$info_type" = "short" ]; then
    
    # Print with tab space.

    # Bytes or human readable output?
    if [ "$output_type" = "bytes" ]; then
      printf "%-${tab_space}s: %s\n" "Downstream" "$rx_avg_last_hour_bits"
      printf "%-${tab_space}s: %s\n" "Upstream" "$tx_avg_last_hour_bits"
      printf "%-${tab_space}s: %s\n" "Total" "$traffic_total_avg_last_hour_bits"
    else
      printf "%-${tab_space}s: %s\n" "Downstream" "$rx_avg_last_hour_human"
      printf "%-${tab_space}s: %s\n" "Upstream" "$tx_avg_last_hour_human"
      printf "%-${tab_space}s: %s\n" "Total" "$traffic_total_avg_last_hour_human"
    fi
  elif [ "$info_type" = "long" ]; then

    # Bytes or human readable output?
    if [ "$output_type" = "bytes" ]; then
      printf "%-${tab_space}s: %s\n" "Downstream" "$rx_avg_last_hour_bits"
      printf "%-${tab_space}s: %s\n" "Upstream" "$tx_avg_last_hour_bits"
      printf "%-${tab_space}s: %s\n" "Total" "$traffic_total_avg_last_hour_bits"
    else
      printf "%-${tab_space}s: %s\n" "Downstream" "$rx_avg_last_hour_human"
      printf "%-${tab_space}s: %s\n" "Upstream" "$tx_avg_last_hour_human"
      printf "%-${tab_space}s: %s\n" "Total" "$traffic_total_avg_last_hour_human"
    fi

  elif [ "$info_type" = "downstream" ]; then
  
    # Bytes or human readable output?
    if [ "$output_type" = "human" ]; then
      echo $rx_avg_last_hour_human
    else
      echo $rx_avg_last_hour_bits
    fi

  elif [ "$info_type" = "upstream" ]; then
  
    # Bytes or human readable output?
    if [ "$output_type" = "human" ]; then
      echo $tx_avg_last_hour_human
    else
      echo $tx_avg_last_hour_bits
    fi

  elif [ "$info_type" = "total" ]; then
  
    # Bytes or human readable output?
    if [ "$output_type" = "human" ]; then
      echo $traffic_total_avg_last_hour_human
    else
      echo $traffic_total_avg_last_hour_bits
    fi
    
  else
    echo "Invalid info_type: $info_type"
    exit 1
  fi

else
  # Print the error msg based on the info type.
  if [ "$info_type" = "short" ]; then
    # Print with tab space.
    printf "%-${tab_space}s: %s\n" "Downstream" "$error_info_msg"
    printf "%-${tab_space}s: %s\n" "Upstream" "$error_info_msg"
    printf "%-${tab_space}s: %s\n" "Total" "$error_info_msg"
  elif [ "$info_type" = "long" ]; then
    echo $error_info_msg
  elif [ "$info_type" = "downstream" ]; then
    echo $error_info_msg
  elif [ "$info_type" = "upstream" ]; then
    echo $error_info_msg
  elif [ "$info_type" = "total" ]; then
    echo $error_info_msg
  else
    echo "Invalid info_type: $info_type"
    exit 1
  fi
fi
