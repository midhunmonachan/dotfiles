#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

showMessage() {
    echo -e "\n${CYAN}$1 ${RESET}"
}

executeAndCheck() {
    # Execute the command while suppressing output
    if "$@" >/dev/null 2>&1; then
        # If the command succeeds, print a green check mark
        echo -e "${GREEN}✔ Success${RESET}"
    else
        # If the command fails, print a red cross mark
        local status=$?
        echo -e "${RED}✘ Error (Code: $status)${RESET}"
        return $status
    fi
}

# Improved error handling
trap 'echo -e "${RED}An error occurred. Exiting...${RESET}"' ERR

# Section header
echo -e "${YELLOW}=== Setup Initialization ===${RESET}"

# Prompt user for the directory to clone dotfiles with default value
echo -ne "${YELLOW}Enter directory to clone dotfiles (default: ~/dotfiles): ${RESET}"
read -r dotfiles_dir
dotfiles_dir=${dotfiles_dir:-"$HOME/dotfiles"}

# Check if the directory already exists
if [ -d "$dotfiles_dir" ]; then
    echo -ne "${YELLOW}Directory '$dotfiles_dir' exists. Overwrite? (Y/n): ${RESET}"
    read -r overwrite
    if [[ ! "$overwrite" =~ ^([Yy]|)$ ]]; then
        echo -e "${RED}Setup aborted. Existing files remain unchanged.${RESET}"
        exit 1
    else
        showMessage "Overwriting directory '$dotfiles_dir'..."
        executeAndCheck rm -rf "$dotfiles_dir"
    fi
fi

showMessage "Cloning repository into '$dotfiles_dir'..."
executeAndCheck git clone https://github.com/midhunmonachan/dotfiles.git "$dotfiles_dir"

showMessage "Changing directory to '$dotfiles_dir'..."
executeAndCheck cd "$dotfiles_dir" || exit

showMessage "Making installer script executable..."
executeAndCheck chmod +x scripts/installer.sh

# Section header for installer script
echo && echo -e "${YELLOW}=== Running Installer Script ===${RESET}"
./scripts/installer.sh

# Section footer
echo -e "${GREEN}=== Setup Complete ===${RESET}"

showMessage "Removing the setup script..."
executeAndCheck rm -f "$0"
