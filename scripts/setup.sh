#!/bin/sh

# Source the output utility script
. "$(dirname "$0")/utils/output.sh"

# Check if the script is running in an interactive shell
if [ ! -t 0 ]; then
  echo "ERROR: This script must be run in an interactive shell."
  exit 1
fi

# Function to set up SSH and GPG keys
setup_keys() {
    print_prompt "Would you like to set up SSH and GPG keys? (y/n): "
    read SETUP_KEYS

  if [ "$SETUP_KEYS" = "y" ]; then
    print_empty_line
    # Source the key setup utility script
    . "$(dirname "$0")/utils/key_setup.sh"
    prompt_github_details || handle_error "Failed to prompt GitHub details."
    delete_existing_keys || handle_error "Failed to delete existing keys."
    generate_keys || handle_error "Failed to generate keys."
  else
    print_info "Skipping SSH and GPG key setup."
  fi
}

# Run the setup process
setup_keys || handle_error "SSH and GPG setup failed."

print_info "Setup script has finished successfully."