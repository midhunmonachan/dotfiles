#!/bin/sh

# Source the output utility script
. "$(dirname "$0")/utils/output.sh"

# Function to set up SSH and GPG keys
setup_keys() {
  read -p "Do you need to set up SSH and GPG keys? (y/n): " SETUP_KEYS

  if [ "$SETUP_KEYS" = "y" ]; then
    # Source the key setup utility script
    . "$(dirname "$0")/utils/key_setup.sh"
    prompt_github_details || { print_error "Failed to prompt GitHub details."; exit 1; }
    delete_existing_keys || { print_error "Failed to delete existing keys."; exit 1; }
    generate_keys || { print_error "Failed to generate keys."; exit 1; }
  else
    print_warning "Skipping SSH and GPG key setup."
  fi
}

# Run the setup process
setup_keys || { print_error "SSH and GPG setup failed."; exit 1; }

print_info "Setup script has finished successfully."