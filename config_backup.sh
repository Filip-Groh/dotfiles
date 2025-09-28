#!/bin/bash
#
# Config Copy Script
# Description: Copies a specified directory from ~/.config/ to a location relative to the script. It then commits changes via Git.
# Usage: ./config_backup.sh<directory_name>
# Example: ./config_backup.sh hypr 
#   (This copies ~/.config/hypr to ./hypr and commits the changes)

CONFIG_BASE="$HOME/.config"
# Get the absolute directory where this script resides (the destination base)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# 1. Input Validation
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <config_directory_name>"
    echo "Example: $0 hypr (This copies $CONFIG_BASE/hypr to $SCRIPT_DIR/hypr)"
    exit 1
fi

DIR_NAME="$1"
SOURCE_PATH="$CONFIG_BASE/$DIR_NAME"
DEST_PATH="$SCRIPT_DIR/$DIR_NAME"

# 2. Source Existence Check
if [ ! -d "$SOURCE_PATH" ]; then
    echo "Error: Source directory not found."
    echo "Expected path: $SOURCE_PATH"
    exit 1
fi

# 3. Confirmation and Execution
echo ""
echo "--- Configuration Backup Script ---"
echo "Source: $SOURCE_PATH"
echo "Destination: $DEST_PATH"
echo "-----------------------------------"
echo ""

# Ask for confirmation before proceeding (optional but safe)
read -r -p "Do you want to proceed with copying (will overwrite files and DELETE files from backup if they don't exist in source)? (y/N) " response
echo ""

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then

    # Create the destination parent directory if it doesn't exist (e.g., if SCRIPT_DIR is new)
    mkdir -p "$SCRIPT_DIR"

    # Use rsync to perform a true mirror synchronization.
    # -a (archive mode) preserves permissions, timestamps, etc.
    # --delete removes files from the destination ($DEST_PATH) that are not in the source ($SOURCE_PATH).
    # The trailing slash on the source path ($SOURCE_PATH/) copies the *contents* of the config directory.
    rsync -av --delete "$SOURCE_PATH/" "$DEST_PATH"

    if [ $? -eq 0 ]; then
        echo ""
        echo "Successfully copied '$DIR_NAME' configuration!"
        echo "Configuration is now available at: $DEST_PATH"

        # 4. Git Commit Stage
        echo ""
        echo "--- Git Commit Stage ---"

        # Check if git is installed
        if ! command -v git &> /dev/null; then
            echo "Warning: Git command not found. Skipping commit."
            exit 0
        fi

        # Change directory to the repository root
        cd "$SCRIPT_DIR" || { echo "Error: Could not change directory to $SCRIPT_DIR for git."; exit 1; }

        # 1. Stage the copied directory
        git add "$DIR_NAME"

        # 2. Attempt to commit changes
        COMMIT_MESSAGE="chore: Sync $DIR_NAME config on $(date +%Y-%m-%d %H:%M:%S)"

        # We redirect stderr to suppress "nothing to commit" message if no changes occurred
        git commit -m "$COMMIT_MESSAGE" 2> /tmp/git_commit_output.txt

        if [ $? -eq 0 ]; then
            echo "Successfully committed changes for '$DIR_NAME'."

            # 3. Git Push Stage (only if a successful commit was made)
            echo ""
            echo "--- Git Push Stage ---"

            git push

            if [ $? -eq 0 ]; then
                echo "Successfully pushed changes to remote repository."
            else
                echo "Error: Git push failed."
                echo "Ensure your remote is set up and your authentication credentials (PAT or SSH Key) are correct."
            fi
        elif grep -q "nothing to commit" /tmp/git_commit_output.txt; then
            echo "No changes detected for '$DIR_NAME'. Skipping commit."
        else
            echo "Error: Git commit failed. Check status manually."
            cat /tmp/git_commit_output.txt
        fi

        # Cleanup temporary file
        rm -f /tmp/git_commit_output.txt
    else
        echo ""
        echo "Error: Copy command failed."
        exit 1
    fi
else
    echo "Copy operation cancelled by user."
    exit 0
fi

exit 0
