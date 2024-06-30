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
    echo -ne "${CYAN}$1 ${RESET}"
}

executeAndCheck() {
    # Execute the command while suppressing output
    if "$@" >/dev/null 2>&1; then
        # If the command succeeds, print a green check mark
        echo -e "\033[0;32m✔\033[0m\n"
    else
        # If the command fails, print a red cross mark
        local status=$?
        echo -e "\033[0;31m✘ (Error code: $status)\033[0m\n"
        return $status
    fi
}

# Improved error handling
trap 'echo -e "${RED}An error occurred. Exiting...${RESET}"' ERR
