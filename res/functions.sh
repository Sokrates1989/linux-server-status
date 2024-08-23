#!/bin/bash

## Global functions ##

# Function to print formatted output.
print_info() {
    while [ "$#" -gt 0 ]; do
        local text=$1
        local output_tab_space=$2
        printf "%-${output_tab_space}s" "$text"
        shift 2
        if [ "$#" -gt 0 ]; then
            printf "  | "
        fi
    done
    echo ""  # Print a newline at the end
}

# Loading animation.
loading_animation() {

    # Speed parameter with default value.
    local speed="normal"
    if [ -n "$1" ]; then
        speed=$1
    fi

    # Prepare default values based on speed.
    local duration=3
    local delay=0.1
    if [ "$speed" == "fast" ]; then
        delay=0.05
        duration=0
    elif [ "$speed" == "normal" ]; then
        delay=0.2
        duration=3
    elif [ "$speed" == "slow" ]; then
        delay=0.4
        duration=5
    fi

    # Show animation.
    local spinstr='|/-\'
    local temp
    SECONDS=0
    while (( SECONDS < duration )); do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}


# Function to show a loading dots animation.
show_loading_dots() {

    # Speed parameter with default value.
    local speed="normal"
    if [ -n "$1" ]; then
        speed=$1
    fi

    # Prepare default values based on speed.
    local duration=3
    local delay=0.5
    if [ "$speed" == "fast" ]; then
        delay=0.05
        duration=0
    elif [ "$speed" == "normal" ]; then
        delay=0.2
        duration=3
    elif [ "$speed" == "slow" ]; then
        delay=0.4
        duration=5
    fi

    # Show animation.
    SECONDS=0
    while (( SECONDS < duration )); do
        printf "."
        sleep $delay
        printf "\b\b  \b\b"
        sleep $delay
        printf ".."
        sleep $delay
        printf "\b\b\b   \b\b\b"
        sleep $delay
        printf "..."
        sleep $delay
        printf "\b\b\b    \b\b\b\b"
        sleep $delay
    done
    printf "    \b\b\b\b"
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
    result="${result}${hours}h ${minutes}m ${seconds}s"

    # Return result.
    echo -e "$result"
}


# Function to find the location of swarm-info/get_info.sh
find_swarm_info_script() {
    local search_paths=("/tools" "/usr/local")
    for path in "${search_paths[@]}"; do
        if [ -f "$path/swarm-info/get_info.sh" ]; then
            echo "$path/swarm-info/get_info.sh"
            return 0
        fi
        found_script=$(find "$path" -type f -name "get_info.sh" -path "*/swarm-info/*" 2>/dev/null)
        if [ -n "$found_script" ]; then
            echo "$found_script"
            return 0
        fi
    done

    # If not found in /tools or /usr/local, search the entire filesystem
    found_script=$(find / -type f -name "get_info.sh" -path "*/swarm-info/*" 2>/dev/null)
    if [ -n "$found_script" ]; then
        echo "$found_script"
        return 0
    fi

    return 1
}


# Main function to get restart information and provide instructions if necessary.
get_restart_information() {
    # Function parameter: output option how to format user ouput.
    local output_options=${1:-"long"} # Default value for output_options is "long" if not provided.
    local output_tab_space=${2:-28}  # Default value for output_tab_space is 28 if not provided.

    # Variable declarations and initializations.
    local timestamp=$(date +%s)
    local restart_required_timestamp=""

    # Is a system restart required?
    if [ -f /var/run/reboot-required ]; then
        # Determine duration since when restart has been required by the system already, to give user possible insight of urgency of restart.
        restart_required_timestamp=$(stat -c %Y /var/run/reboot-required)
        local time_elapsed=$((timestamp - restart_required_timestamp))
        local time_elapsed_human_readable=$(convert_seconds_to_human_readable "$time_elapsed")

        # Print user info: System needs to be restarted.
        if [ "$output_options" == "short" ]; then
            printf "%-${output_tab_space}s: %s\n" "Restart required" "Yes, since $time_elapsed_human_readable" 
        else
            echo -e "System restart required since $time_elapsed_human_readable"
        fi

        # Check if the server is part of a Docker Swarm.
        if docker info | grep -q "Swarm: active"; then

            # Reboot instructions to avoid downtime.
            local node_name=$(hostname)
            echo -e "\nRestart instructions/advice to decrease downtime of containers:"
            echo "DO NOT simply reboot. Instead, follow these steps:"
            echo ""
            echo "1. Drain the node (all services/containers will be redeployed onto different nodes):"
            echo "   docker node update --availability drain $node_name"
            echo ""
            echo "2. Watch progress to ensure the host no longer runs any services:"
            echo "   watch docker service ls"

            # Find the location of the swarm-info/get_info.sh script
            local swarm_info_script_location=$(find_swarm_info_script)
            if [ -n "$swarm_info_script_location" ]; then
                echo "   watch bash $swarm_info_script_location --node-services"
            else
                echo "   To easily view service distribution across nodes, please install swarm-info from https://github.com/Sokrates1989/swarm-info"
            fi

            echo ""
            echo "3. Reboot the server:"
            echo "   reboot"
            echo ""
            echo "4. Make the node available again:"
            echo "   docker node update --availability active $node_name"
            echo ""
            echo "5. Ensure equal distribution of services:"

            if [ -n "$swarm_info_script_location" ]; then
                echo "   watch bash $swarm_info_script_location --node-services"
            else
                echo "   To easily view service distribution across nodes, please install swarm-info from https://github.com/Sokrates1989/swarm-info"
            fi

            echo "   docker service update --force <service_name>"
        fi
    else

        # Print user info: System needs to be restarted.
        if [ "$output_options" == "short" ]; then
            printf "%-${output_tab_space}s: %s\n" "Restart required" "No"
        else
            echo -e "No restart required"
        fi
    fi
}
