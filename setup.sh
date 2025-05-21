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

# PHP version to install
PHP_VERSION="8.4" # Latest as of 2025-05-21

# Node.js version to install
NODEJS_VERSION="24" # Latest as of 2025-05-21

# PHP extensions to install
PHP_EXTENSIONS=(
	"cli"       # Command-line interface for PHP scripts
	"fpm"       # FastCGI Process Manager for serving PHP via web servers
	"mysql"     # MySQL database driver for PHP
	"mbstring"  # Multibyte string support (required for many frameworks)
	"xml"       # XML parsing support
	"curl"      # Client URL library for PHP (HTTP requests, APIs)
	"gd"        # Image processing library
	"intl"      # Internationalization functions (localization, formatting)
	"bcmath"    # Arbitrary precision mathematics
	"zip"       # Zip archive support
	"tokenizer" # Tokenizing PHP source code (used by some frameworks)
	"opcache"   # Opcode caching for improved performance
	"redis"     # Redis key-value store support
)

# List of composer global packages to install
COMPOSER_GLOBAL_PACKAGES=(
	"laravel/installer" # Laravel installer
)

# List of node.js global packages to install
NODEJS_GLOBAL_PACKAGES=(
	"yarn" # Package manager for Node.js
)

# List of basic packages to install
BASIC_PACKAGES=(
	"software-properties-common" # Common software properties
	"apt-transport-https"        # Allows the use of HTTPS for APT
	"ca-certificates"            # Common CA certificates
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
setup_system() {
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

setup_web_server() {
	log "Setting up web server"
	apt-get install -y nginx
}

setup_php_environment() {
	log "Setting up PHP environment"
	apt-get install -y "php$PHP_VERSION" "${PHP_EXTENSIONS[@]/#/php$PHP_VERSION-}"
}

setup_composer() {
	log "Setting up Composer"
	local expected_checksum actual_checksum
	expected_checksum="$(curl -fsSL https://composer.github.io/installer.sig)"
	curl -fsSL -o composer-setup.php https://getcomposer.org/installer
	actual_checksum="$(sha384sum composer-setup.php | awk '{ print $1 }')"
	if [[ "$expected_checksum" != "$actual_checksum" ]]; then
		echo 'ERROR: Invalid Composer installer checksum'
		rm -f composer-setup.php
		exit 1
	fi
	php composer-setup.php --install-dir=/usr/local/bin --filename=composer
	rm composer-setup.php

	log "Installing Composer global packages"
	local user="${SUDO_USER:-$(logname)}"
	sudo -u "$user" composer global require "${COMPOSER_GLOBAL_PACKAGES[@]}"
}

setup_nodejs() {
	log "Setting up Node.js"
	curl -fsSL https://deb.nodesource.com/setup_"$NODEJS_VERSION".x | bash -
	apt-get install -y nodejs
	# Fix permissions issues for npm global packages
	npm config set prefix ~/.local
	PATH=~/.local/bin/:$PATH
	log "Installing Node.js global packages"
	local user="${SUDO_USER:-$(logname)}"
	npm install -g "${NODEJS_GLOBAL_PACKAGES[@]}"
}

#---------------------------------------------------------------------------------
# Main Script
#---------------------------------------------------------------------------------

setup_system
setup_web_server
setup_php_environment
setup_composer
setup_nodejs

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
