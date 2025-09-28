#!/bin/bash
#
# Config Restore Script
# Description: Copies a specified directory from the script's location back to ~/.config/
# Usage: ./config_restore.sh <directory_name>
# Example: ./config_restore.sh hypr 
#   (This copies ./hypr to ~/.config/hypr)

CONFIG_BASE="$HOME/.config"
# Get the absolute directory where this script resides (the source base)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# 1. Input Validation
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <config_directory_name>"
    echo "Example: $0 hypr (This restores $SCRIPT_DIR/hypr to $CONFIG_BASE/hypr)"
    exit 1
fi

DIR_NAME="$1"
SOURCE_PATH="$SCRIPT_DIR/$DIR_NAME"
DEST_PATH="$CONFIG_BASE/$DIR_NAME"

# 2. Source Existence Check (Check if the backup exists)
if [ ! -d "$SOURCE_PATH" ]; then
    echo "Error: Backup configuration directory not found."
    echo "Expected path: $SOURCE_PATH"
    exit 1
fi

# 3. Confirmation and Execution
echo "--- Configuration Restore Script ---"
echo "Source: $SOURCE_PATH"
echo "Destination: $DEST_PATH"
echo "-----------------------------------"

# Ask for confirmation before proceeding (Crucial, as this overwrites live configs)
read -r -p "WARNING: This will overwrite files in your $CONFIG_BASE/$DIR_NAME and delete files in the destination if they don't exist in the backup. Do you want to proceed? (y/N) " response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then

    # Create the destination directory in ~/.config/ if it doesn't exist
    mkdir -p "$DEST_PATH"

    # Use rsync to perform a true mirror synchronization.
    # -a (archive mode) preserves permissions, timestamps, etc.
    # --delete removes files from the destination ($DEST_PATH) that are not in the source ($SOURCE_PATH).
    # The trailing slash on the source path ($SOURCE_PATH/) copies the *contents* of the backup directory.
    rsync -av --delete "$SOURCE_PATH/" "$DEST_PATH"

    if [ $? -eq 0 ]; then
        echo ""
        echo "Successfully restored '$DIR_NAME' configuration!"
        echo "The live configuration is now located at: $DEST_PATH"
    else
        echo ""
        echo "Error: Restore command failed."
        exit 1
    fi
else
    echo "Restore operation cancelled by user."
    exit 0
fi

exit 0

