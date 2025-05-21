#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃=======================> Midhun's Server Setup Script <=======================┃
# ┃                                                                              ┃
# ┃  Automated server configuration and software installation for Ubuntu/Debian  ┃
# ┃------------------------------------------------------------------------------┃
# ┃  Author: Midhun Monachan                                Updated: 2025-05-21  ┃
# ┃  GitHub: github.com/midhunmonachan                             License: MIT  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

#---------------------------------------------------------------------------------
# Initialization
#---------------------------------------------------------------------------------

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root. Please use sudo or run as root user."
	exit 1
fi

# Exit on error, unset vars, or failed pipes
set -euo pipefail

# Suppress interactive prompts during package installs
export DEBIAN_FRONTEND=noninteractive

# Log file for script output
LOG_FILE="/var/log/dotfiles-setup-$(date +%Y%m%d-%H%M%S).log"

# Create log file and redirect output
touch "$LOG_FILE" && exec > >(tee -a "$LOG_FILE") 2>&1

# Log the start time of the script execution
echo "=== Script execution started on $(date) ===" >>"$LOG_FILE"

#---------------------------------------------------------------------------------
# Configuration Variables
#---------------------------------------------------------------------------------

# List of basic packages to install
BASIC_PACKAGES=(
	"software-properties-common" # Common software properties
	"apt-transport-https"        # Allows the use of HTTPS for APT
	"ca-certificates"            # Common CA certificates
	"openssh-server"             # OpenSSH server
	"git"                        # Version control system
	"gnupg"                      # GNU Privacy Guard
	"gh"                         # GitHub CLI
	"curl"                       # Command line tool for transferring data
	"wget"                       # Command line utility for downloading files
	"ufw"                        # Uncomplicated Firewall
	"fail2ban"                   # Intrusion prevention software
	"htop"                       # Interactive process viewer
	"unzip"                      # Required for extracting zip files
	"zip"                        # Required for creating zip files
	"nano"                       # Text editor
)

# List of PPAs to add
PPA_LIST=(
	"ppa:ondrej/nginx" # For Nginx
	"ppa:ondrej/php"   # For PHP
)

#---------------------------------------------------------------------------------
# Functions
#---------------------------------------------------------------------------------

# Prints a formatted log message
# Usage: log "Your message here"
log() {
	echo ""
	echo "--------------------------------------------------------------------------------"
	echo "➤  ${1^^}"
	echo "--------------------------------------------------------------------------------"
}

# Function to update package lists, install basic packages, add PPAs and upgrade the system
initialize_system() {
	log "Updating package lists"
	apt-get update -y

	log "Installing basic packages"
	apt-get install -y "${BASIC_PACKAGES[@]}"

	log "Adding External Repositories"
	for ppa in "${PPA_LIST[@]}"; do add-apt-repository -y "$ppa"; done && apt-get update -y

	log "Upgrading system"
	apt-get dist-upgrade -y

	log "Cleaning up"
	apt-get autoremove -y && apt-get autoclean -y
}

#---------------------------------------------------------------------------------
# Main Script
#---------------------------------------------------------------------------------

initialize_system

#---------------------------------------------------------------------------------
# Cleanup
#---------------------------------------------------------------------------------

log "Script execution completed"

# Log the end time of the script execution
echo "=== Script execution completed on $(date) ===" >>"$LOG_FILE"

# Notify the user about the log file location
echo "Log saved to $LOG_FILE" >/dev/tty

#---------------------------------------------------------------------------------
# Notes
#---------------------------------------------------------------------------------
# - This script is under active development. Use at your own risk.
# - Intended for fresh Ubuntu/Debian installations only.
# - Review the code before running on production systems.
# - This script must be executed with root privileges.
