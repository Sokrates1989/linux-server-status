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

# Check for command-line options
while getopts ":flus" opt; do
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
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# If no option is specified or an invalid option is provided, display short info
display_short_info

