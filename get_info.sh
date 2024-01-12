#!/bin/bash

# Get the directory of the script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to display short system information.
display_short_info() {
    sh "$SCRIPT_DIR/res/short_info.sh"
}

# Function to display full system information.
display_full_info() {
    sh "$SCRIPT_DIR/res/long_info.sh"
}

# Function to display available system updates.
display_update_info() {
    echo ""
    sh "$SCRIPT_DIR/res/update_info.sh"
    echo ""
}

# Function to display cpu info.
display_cpu_info() {
    echo ""
    sh "$SCRIPT_DIR/res/cpu_info.sh" -l  # To display long info.
    echo ""
}

# Function to display and save system information as json.
CUSTOM_OUTPUT_FILE="NONE"
server_states_dir="$SCRIPT_DIR/server-states"
server_states_json_file="$server_states_dir/system_info.json"
system_info_json() {
    # Check if CUSTOM_OUTPUT_FILE is still in its default value
    if [ "$CUSTOM_OUTPUT_FILE" = "NONE" ]; then
        sh "$SCRIPT_DIR/res/system-info.sh" --json --output-file "$server_states_json_file"
    else
        sh "$SCRIPT_DIR/res/system-info.sh" --json --output-file "$CUSTOM_OUTPUT_FILE"
    fi
}

# Function to display help information.
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -f, --full     Display full system information"
    echo "  -l             Alias for --full"
    echo "  -u             Display available system updates"
    echo "  -s             Display short system information"
    echo "  --cpu          Display CPU information"
    echo "  --help         Display this help message"
    echo "  --json         Save and display info in json format"
    echo "  --output-file  Where to save the system info output (only in combination with --json)"
}


# Default values.
use_file_output="False"
file_output_type="json"

# Check for command-line options.
while getopts ":flus:-:" opt; do
    case $opt in
        f)
            display_full_info
            exit 0
            ;;
        l)
            display_full_info
            exit 0
            ;;
        u)
            display_update_info
            exit 0
            ;;
        s)
            display_short_info
            exit 0
            ;;
        -)
            case "${OPTARG}" in
                cpu)
                    display_cpu_info
                    exit 0
                    ;;
                help)
                    display_help
                    exit 0
                    ;;
                json)
                    use_file_output="True"
                    file_output_type="json"
                    ;;
                output-file)
                    CUSTOM_OUTPUT_FILE="$OPTARG"
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done


# Use file output?
if [ "$use_file_output" = "True" ]; then
    if [ "$file_output_type" = "json" ]; then
        system_info_json
    else
        # If no option is specified or an invalid option is provided, display short info.
        echo "invalid file_output_type: $file_output_type"
    fi
else
    # If no option is specified or an invalid option is provided, display short info.
    display_short_info
fi
