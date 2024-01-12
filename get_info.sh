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
system_info_json() {
    sh "$SCRIPT_DIR/res/system-info.sh" --json
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
}

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
                    system_info_json
                    exit 0
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

# If no option is specified or an invalid option is provided, display short info
display_short_info
