#!/bin/sh

# Create a temporary directory
TEMP_DIR=$(mktemp -d)

# Function to clean up temporary directory on exit
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Clear the screen
clear

# Download the repository to the temporary directory
git clone https://github.com/midhunmonachan/dotfiles.git "$TEMP_DIR" > /dev/null 2>&1 || { echo "ERROR: Failed to clone repository."; exit 1; }

# Change to the repository directory
cd "$TEMP_DIR" || echo "ERROR: Failed to change directory."

# Source the output utility script from the repository
. "$TEMP_DIR/scripts/utils/output.sh" || { echo "ERROR: File not found. ($TEMP_DIR/scripts/utils/output.sh)"; exit 1; }

# Make the setup script executable
chmod +x ./scripts/setup.sh || { echo "ERROR: Failed to make setup script executable."; exit 1; }

# Run the setup script
./scripts/setup.sh || handle_error "Setup script failed."