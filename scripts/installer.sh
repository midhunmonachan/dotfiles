#!/bin/bash

source "$(dirname "$0")/common.sh"

cd "$(dirname "$0")/.."

# Clean the whole directory except the dotfiles directory and scripts directory
showMessage "Cleaning the directory..."
executeAndCheck find . -mindepth 1 -not -path './dotfiles*' -not -path './scripts*' -not -path './config.yaml' -delete

# Move the contents of the dotfiles directory to the root directory
showMessage "Moving dotfiles to the root directory..."
executeAndCheck mv dotfiles/* .

# Remove the dotfiles directory
showMessage "Removing the dotfiles directory..."
executeAndCheck rm -rf dotfiles

# Read the list of file to be symlinked from the config.yaml file
showMessage "Reading the list of files to be symlinked..."
files=$(grep -A 1 'symlinks:' config.yaml | awk 'NR==2 {print $2}')
# Create symlinks for each file
for file in "${files[@]}"; do
    src=$(echo "$file" | cut -d ':' -f 1)
    dest=$(echo "$file" | cut -d ':' -f 2)
    showMessage "Creating symlink for $src to $dest..."
    executeAndCheck sudo ln -s "$PWD/$src" "$dest"
done

# Read the list of bash scripts to be run from the config.yaml file
showMessage "Reading the list of bash scripts to be run..."
scripts=$(grep -A 1 'scripts:' config.yaml | awk 'NR==2 {print $2}')
# Run each bash script
for script in "${scripts[@]}"; do
    showMessage "Running $script..."
    executeAndCheck bash "$PWD/$script"
done
