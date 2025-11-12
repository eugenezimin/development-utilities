#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_repo_url> <destination_directory>"
    exit 1
fi

# Assign arguments to variables
SOURCE_REPO=$1
DEST_DIR=$2

# Clone the repository with --mirror option
git clone --mirror "$SOURCE_REPO" "$DEST_DIR"

# Change to the destination directory
cd "$DEST_DIR" || exit

# Convert the mirrored repository to a normal repository
git config --bool core.bare false

# create a .git folder and copy bare repo to .git folder
mkdir .git && find . -maxdepth 1 -not -name "." -not -name ".git" -exec mv {} .git/ \;

# Checkout the default branch (usually main or master)
git checkout $(git symbolic-ref --short HEAD)

# Reset the working directory to match the HEAD commit
git reset --hard

echo "Repository has been cloned, converted to a normal repository, and reset."
