#!/bin/bash

# Default values.
info_type="processable"
output_tab_space_default=28
output_tab_space=$output_tab_space_default

# Parse command-line options.
while getopts ":lspt:" opt; do
  case $opt in
    l)
      info_type="long"
      ;;
    s)
      info_type="short"
      ;;
    p)
      # Processable -> just print the output of get_gluster_info .
      # Calling script should then use output like this:
      # eval "$(output)" .
      # It then has access to the vars as descriped in get_gluster_info.
      info_type="processable"
      ;;
    t)
      # Only takes effect when using -s (short) option.
      output_tab_space=$OPTARG
      ;;
    \?)
      echo -e "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Validate tab_space only when using short option.
if [ "$info_type" = "short" ]; then
  if [ "$output_tab_space" -lt 1 ]; then
    echo -e "Error: Tab space must be a positive integer." >&2
    exit 1
  fi
fi

# Get the directory of the script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Seperators.
newArrayElementIndicator=",,,"
wordSeperator="---"
emptyArrayString="empty"
# Function to split string into an array.
split_string_into_array() {
  local input_string="$1"
  local delimiter="$2"

  # Set the IFS to the specified delimiter for splitting.
  IFS="$delimiter"
  # Convert the input string to an array.
  read -a array <<< "$input_string"
  # Reset IFS to its default value.
  IFS=$' \t\n'

  # Return the array.
  echo "${array[@]}"
}


### Returns info about glusterfs.
###
### Usage.
### Call using eval like this:
### eval "$(get_gluster_info)"
### You will then have access to the variables described below.
### 
### Return.
### After calling method using eval you can use these variables:
### $is_gluster_installed        "true"|"false"
### $is_peer_state_valid         "true"|"false"             (only available, if $is_gluster_installed is true)
### $gluster_peers               array of peers             (only available, if $is_peer_state_valid is true and $number_of_peers > 0. Contains hostname and peer_state)
### $number_of_peers             int                        (only available, if $is_peer_state_valid is true)
### $number_of_healthy_peers     int                        (only available, if $is_peer_state_valid is true)
### $gluster_volumes             array of volumes           (only available, if $is_gluster_installed is true and $number_of_volumes > 0. Contains hostname and peer_state)
### $number_of_volumes           int                        (only available, if $is_gluster_installed is true)
### $number_of_healthy_volumes   int                        (only available, if $is_gluster_installed is true)
### $all_unhealthy_bricks        Array of strings           Each array element represents a volume.   The strings within contain unhealthy_bricks where each word is seperated with "---" and each element within is seperated by ",,,"
### $all_unhealthy_processes     Array strings              Each array element represents a volume.   The strings within contain unhealthy_processes where each word is seperated with "---" and each element within is seperated by ",,,"
### $all_errors_warnings         Array strings              Each array element represents a volume.   The strings within contain errors_warnings where each word is seperated with "---" and each element within is seperated by ",,,"
### $all_active_tasks            Array of strings           Each array element represents a volume.   The strings within contain active_tasks where each word is seperated with "---" and each element within is seperated by ",,,"
get_gluster_info() {

    # Variable to return.
    local gluster_info=()

    # Get Gluster install state.
    gluster_installed=$(command -v gluster 2>/dev/null)
    if [ -n "$gluster_installed" ]; then

        # Return install state.
        echo -e "is_gluster_installed=true"

        # Get the status of GlusterFS peers.
        peer_status=$(gluster peer status 2>/dev/null)
        if [ $? -eq 0 ]; then

            # Return peer state.
            echo -e "is_peer_state_valid=true"

            # Return number of peers.
            number_of_peers=$(echo "$peer_status" | grep -oP 'Number of Peers: \K\d+')
            echo -e "number_of_peers=$number_of_peers"

            # Information about peers.
            local gluster_peers=()
            number_of_healthy_peers=0

            # Get Hostnames from gluster peer status command and store them in an array.
            read -ra hostnames <<< "$(gluster peer status | awk '/Hostname:/{print $2}' | tr '\n' ' ')"

            # Loop through hostnames to retrieve state.
            for hostname in "${hostnames[@]}"; do
                peer_state=$(gluster peer status | awk -v h="$hostname" '$0 ~ "Hostname: "h {getline; getline; sub(/^[^(]*\(|\)[^)]*$/, "", $0); sub(/\)$/, "", $0); print}')
                gluster_peers+=("$hostname:$peer_state")

                # Is Peer healthy?
                if [ "$peer_state" == "Connected" ]; then
                    ((number_of_healthy_peers++))
                fi
            done

            # Return peer information.
            echo "gluster_peers=(${gluster_peers[@]})"
            echo -e "number_of_healthy_peers=$number_of_healthy_peers"
        else
            # Return peer state.
            echo -e "is_peer_state_valid=false"
        fi


        
        # GlusterFS volumes.

        # Get all gluster volumes as array.
        gluster_volumes=($(gluster volume list))

        # Errors/warnings and unhealthy processes as array.
        local all_unhealthy_bricks=()
        local all_unhealthy_processes=()
        local all_errors_warnings=()
        local all_active_tasks=()

        # Return the number of volumes.
        number_of_volumes=${#gluster_volumes[@]}
        echo -e "number_of_volumes=$number_of_volumes"

        # Prepare count of healthy volumes.
        number_of_healthy_volumes=0

        # Directly use the array in subsequent operations.
        for volume in "${gluster_volumes[@]}"; do
            # Get the status of the GlusterFS volume.

            # Get the status of the GlusterFS volume.
            gluster_volume_state_output=$(gluster volume status "$volume")
            # Set a flag to indicate when to start processing lines.
            start_processing=false

            # Initialize an empty variable to concatenate lines.
            raw_multiline_process_states=""
            # Process each line of the command gluster_volume_state_output.
            while IFS= read -r line; do
                # Check for the delimiter to start processing.
                if [ "$line" = "------------------------------------------------------------------------------" ]; then
                    start_processing=true
                    continue
                fi

                # Line length as delimeter option.
                line_length=${#line}

                # Check for the delimiters to stop processing.
                if [ "$line_length" = 1 ] || [[ -z "$line" ]] || [ "$line" = "Task Status of Volume $volume" ]; then
                    break
                fi

                # Process lines only when the flag is set.
                if $start_processing; then
                    # Concatenate the lines.
                    raw_multiline_process_states="${raw_multiline_process_states}${line}\n"
                fi
                
            # End of loop -> Here we pass variable to make it accessible within loop above.
            done < <(echo "$gluster_volume_state_output")


            # Sanitize misguided/misformatted lines.
            sanitized_multiline_process_states=""
            # Use a loop to iterate through raw lines.
            while IFS= read -r line; do
                # Line String length.
                line_length=${#line}

                # Skip empty lines.
                if [ "$line_length" = 0 ]; then
                    continue
                fi
                
                # Count the number of spaces in the string.
                space_count=$(echo "$line" | tr -cd ' ' | wc -c)
                
                # Concatenate lines based on space count.
                if [ "$space_count" -lt 2 ]; then
                    sanitized_multiline_process_states+="$line"
                else
                    sanitized_multiline_process_states+="$line\n"
                fi

            # End of loop -> Here we pass variable to make it accessible within loop above.
            done < <(echo -e "$raw_multiline_process_states")


            # Check for unhealthy processes.
            unhealthy_bricks=($(echo -e "$sanitized_multiline_process_states" | awk -v newArrayElementIndicator="$newArrayElementIndicator" -v wordSeperator="$wordSeperator" '$0 ~ /^Brick/ && $5 != "Y" {print $1wordSeperator $2 newArrayElementIndicator}'))
            # Remove spaces and last trailing ,,, .
            unhealthy_bricks_string=$(echo "${unhealthy_bricks[*]}" | tr -d '[:space:]' | sed 's/,\{3\}$//')
            # Multi empty array is just empty array -> replace empty string with emptyArrayString.
            if [ "$unhealthy_bricks_string" = "" ]; then
                unhealthy_bricks_string="$emptyArrayString"
            fi
            all_unhealthy_bricks+=("$unhealthy_bricks_string")
            # Self-heal processes.
            unhealthy_processes=($(echo -e "$sanitized_multiline_process_states" | awk -v newArrayElementIndicator="$newArrayElementIndicator" -v wordSeperator="$wordSeperator" '$0 ~ /^Self-heal/ && $7 != "Y" {print $1wordSeperator $2wordSeperator $3wordSeperator $4 newArrayElementIndicator}'))
            unhealthy_processes_string=$(echo "${unhealthy_processes[*]}" | tr -d '[:space:]' | sed 's/,\{3\}$//')
            # Multi empty array is just empty array -> replace empty string with emptyArrayString.
            if [ "$unhealthy_processes_string" = "" ]; then
                unhealthy_processes_string="$emptyArrayString"
            fi
            all_unhealthy_processes+=("$unhealthy_processes_string")

            # Check for errors or warnings.
            errors_warnings=($(echo "$gluster_volume_state_output" | grep -E '^(Error|Warning)'))
            errors_warnings_string=""
            # Iterate through each error or warning
            for item in "${errors_warnings[@]}"
            do
                # Replace spaces with "---" within each error or warning
                formatted_item=$(echo "$item" | sed 's/ /---/g')

                # Print the formatted error or warning
                errors_warnings_string+="$formatted_item$newArrayElementIndicator"
                errors_warnings_string=$(echo "$errors_warnings_string" | sed 's/,\{3\}$//'  | tr -d '[:space:]')

            done
            # Multi empty array is just empty array -> replace empty string with emptyArrayString.
            if [ "$errors_warnings_string" = "" ]; then
                errors_warnings_string="$emptyArrayString"
            fi
            all_errors_warnings+=("$errors_warnings_string")

            # Check for active volume tasks.
            active_tasks=$(echo "$gluster_volume_state_output" | awk '/^Task Status of Volume/ { active=1; next } active && !/^-+/ { print }')
            active_tasks_string=""
            for item in "${active_tasks[@]}"
            do
                # Replace spaces with "---" within each error or warning.
                formatted_item=$(echo "$item" | sed 's/ /---/g')

                # Print the formatted error or warning.
                active_tasks_string+="$formatted_item$newArrayElementIndicator"
                active_tasks_string=$(echo "$active_tasks_string" | sed 's/,\{3\}$//' | tr -d '[:space:]')

            done
            # Multi empty array is just empty array -> replace empty string with emptyArrayString.
            if [ "$active_tasks_string" = "" ]; then
                active_tasks_string="$emptyArrayString"
            fi
            all_active_tasks+=("$active_tasks_string")


            # Save, if volume is healthy.
            volume_is_healthy=true
            # Are there any offline bricks?
            if [ ${#unhealthy_bricks[@]} -gt 0 ]; then
                # Indicate, that volume is unhealthy.
                volume_is_healthy=false
            fi
            # Are there any offline processes?
            if [ ${#unhealthy_processes[@]} -gt 0 ]; then
                # Indicate, that volume is unhealthy.
                volume_is_healthy=false
            fi
            # Are there any errors or warnings tasks?
            if [ ${#errors_warnings[@]} -gt 0 ]; then
                # Indicate, that volume is unhealthy.
                volume_is_healthy=false
            fi

            # Is Volume healthy?
            if [ "$volume_is_healthy" == "true" ]; then
                ((number_of_healthy_volumes++))
            fi

        done
        

        # Return volume information.
        echo "gluster_volumes=(${gluster_volumes[@]})"
        echo -e "number_of_healthy_volumes=$number_of_healthy_volumes"
        echo "all_unhealthy_bricks=(${all_unhealthy_bricks[@]})"
        echo "all_unhealthy_processes=(${all_unhealthy_processes[@]})"
        echo "all_errors_warnings=(${all_errors_warnings[@]})"
        echo "all_active_tasks=(${all_active_tasks[@]})"
        
    else
        # Return install state.
        echo -e "is_gluster_installed=false"
    fi
}

# Print the results based on info_type.
if [ "$info_type" = "short" ]; then
    # Get gluster info and evaluate the result.
    eval "$(get_gluster_info)"
    if [ $is_gluster_installed = "true" ]; then

        # Print Install state: is installed.
        printf "%-${output_tab_space}s: %s\n" "GlusterFS Installed" "Yes"

        # Print Peer state.
        if [ $is_peer_state_valid = "true" ]; then
            
            # Print number of peers (and healthy peers in brackets).
            printf "%-${output_tab_space}s: %s\n" "Peers (healthy/total)" "$number_of_healthy_peers/$number_of_peers"

        else
            # Print peer state info.
            printf "%-${output_tab_space}s: %s\n" "Peers" "Error fetching peer state or no peers"
        fi

        # Print volume state.
        
        # Print number of volumes (and healthy volumes in brackets).
        printf "%-${output_tab_space}s: %s\n" "Volumes (healthy/total)" "$number_of_healthy_volumes/$number_of_volumes"

        echo -e "use -g option to view full gluster information -> bash path/to/get_info.sh -g "

    else
        # Print Install state: is not installed.
        printf "%-${output_tab_space}s: %s\n" "GlusterFS Installed" "No"
    fi
elif [ "$info_type" = "long" ]; then
  # Get gluster info and evaluate the result.
    eval "$(get_gluster_info)"
    echo -e "Full GlusterFS information\n"
    if [ $is_gluster_installed = "true" ]; then

        # Print Install state: is installed.
        printf "%-${output_tab_space}s: %s\n" "GlusterFS Installed" "Yes"

        # Print Peer state.
        echo -e "\nPeer information"
        if [ $is_peer_state_valid = "true" ]; then
            
            # Print number of peers (and healthy peers in brackets).
            printf "%-${output_tab_space}s: %s\n" "Peers (healthy/total)" "$number_of_healthy_peers/$number_of_peers"

            # Print info about peers.
            echo -e "\nPeers"
            for gluster_peer in "${gluster_peers[@]}"; do
                IFS=':' read -r hostname peer_state <<< "$gluster_peer"
                printf "%-${output_tab_space}s: %s\n" "$hostname" "$peer_state"
            done

        else
            # Print peer state info.
            printf "%-${output_tab_space}s: %s\n" "Peers" "Error fetching peer state or no peers"
        fi

        # Print volume state.
        echo -e "\nVolume information"
        
        # Print number of volumes (and healthy volumes in brackets).
        printf "%-${output_tab_space}s: %s\n" "Volumes (healthy/total)" "$number_of_healthy_volumes/$number_of_volumes"

        # Print info about volumes.
        for ((i=0; i<$number_of_volumes; i++)); do

            # Print volume name as heading.
            echo -e "\nVolume ${gluster_volumes[$i]}" 

            # Print Warnings and errors, ....
            if [ -z "${all_unhealthy_bricks[$i]}" ] || [ "${all_unhealthy_bricks[$i]}" = "empty" ]; then
                echo "All bricks are healthy."
            else
                this_volumes_unhealthy_bricks=($(split_string_into_array "${all_unhealthy_bricks[$i]}" "$newArrayElementIndicator"))
                number_of_unhealthy_bricks=${#this_volumes_unhealthy_bricks[@]}
                printf "%-${output_tab_space}s: %s\n" "Unhealthy Bricks" "${this_volumes_unhealthy_bricks[0]//---/ }"
                for ((j=1; j<$number_of_unhealthy_bricks; j++)); do
                    printf "%-${output_tab_space}s: %s\n" " " "${this_volumes_unhealthy_bricks[$j]//---/ }"
                done
            fi

            if [ -z "${all_unhealthy_processes[$i]}" ] || [ "${all_unhealthy_processes[$i]}" = "empty" ]; then
                echo "All processes are healthy."
            else
                this_volumes_unhealthy_processes=($(split_string_into_array "${all_unhealthy_processes[$i]}" "$newArrayElementIndicator"))
                number_of_unhealthy_processes=${#this_volumes_unhealthy_processes[@]}
                printf "%-${output_tab_space}s: %s\n" "Unhealthy Processes" "${this_volumes_unhealthy_processes[0]//---/ }"
                for ((j=1; j<$number_of_unhealthy_processes; j++)); do
                    printf "%-${output_tab_space}s: %s\n" " " "${this_volumes_unhealthy_processes[$j]//---/ }"
                done
            fi

            if [ -z "${all_errors_warnings[$i]}" ] || [ "${all_errors_warnings[$i]}" = "empty" ]; then
                echo "There are no errors/warnings."
            else
                this_volumes_errors_warnings=($(split_string_into_array "${all_errors_warnings[$i]}" "$newArrayElementIndicator"))
                number_of_errors_warnings=${#this_volumes_errors_warnings[@]}
                printf "%-${output_tab_space}s: %s\n" "Errors/ Warnings" "${this_volumes_errors_warnings[0]//---/ }"
                for ((j=1; j<$number_of_errors_warnings; j++)); do
                    printf "%-${output_tab_space}s: %s\n" " " "${this_volumes_errors_warnings[$j]//---/ }"
                done
            fi

            if [ -z "${all_active_tasks[$i]}" ] || [ "${all_active_tasks[$i]}" = "There---are---no---active---volume---tasks---"  ]; then
                echo "There are no active volume tasks."
            else
                this_volumes_active_tasks=($(split_string_into_array "${all_active_tasks[$i]}" "$newArrayElementIndicator"))
                number_of_active_tasks=${#this_volumes_active_tasks[@]}
                printf "%-${output_tab_space}s: %s\n" "Active Tasks" "${this_volumes_active_tasks[0]//---/ }"
                for ((j=1; j<$number_of_active_tasks; j++)); do
                    printf "%-${output_tab_space}s: %s\n" " " "${this_volumes_active_tasks[$j]//---/ }"
                done
            fi

        done

    else
        # Print Install state: is not installed.
        printf "%-${output_tab_space}s: %s\n" "GlusterFS Installed" "No"
    fi
elif [ "$info_type" = "processable" ]; then
    eval "$(get_gluster_info)"
    export is_gluster_installed
    export is_peer_state_valid
    export gluster_peers
    export number_of_peers
    export number_of_healthy_peers
    export gluster_volumes
    export number_of_volumes
    export number_of_healthy_volumes
    export all_unhealthy_bricks
    export all_unhealthy_processes
    export all_errors_warnings
    export all_active_tasks
else
  echo -e "Invalid info_type: $info_type"
  exit 1
fi

