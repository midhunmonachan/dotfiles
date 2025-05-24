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
# Checks
#---------------------------------------------------------------------------------

# Check if it is compatible OS
if [[ ! -f /etc/debian_version ]]; then
	log error "This script only works on Debian/Ubuntu systems"
	exit 1
fi

# Ensure the script is not executed as root
if [[ $EUID -eq 0 ]]; then
	log error "Do not run this script as root. Please execute as a regular user."
	exit 1
fi

#---------------------------------------------------------------------------------
# Initialization
#---------------------------------------------------------------------------------

# Get sudo privileges
if ! sudo -v; then
	log error "Failed to obtain sudo privileges. Please check your user permissions."
	exit 1
fi

# Keep sudo alive
while sleep 60; do
	sudo -n true || exit
	kill -0 "$$" >/dev/null || exit
done &

# Exit on error, unset vars, or failed pipes
set -euo pipefail

# Suppress interactive prompts during package installs
export DEBIAN_FRONTEND=noninteractive

# Log file for script output
LOG_FILE="/var/log/dotfiles/$(date +%Y%m%d-%H%M%S).log"

# Create log directory if it doesn't exist and set permissions
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo chmod 777 "$(dirname "$LOG_FILE")"

# Create log file and redirect output to it
touch "$LOG_FILE" && exec > >(tee -a "$LOG_FILE") 2>&1

# Log the start time of the script execution
echo "=== Script execution started on $(date) ===" >>"$LOG_FILE"

#---------------------------------------------------------------------------------
# Configuration Variables
#---------------------------------------------------------------------------------

# PHP version to install
PHP_VERSION="8.4" # Latest as of 2025-05-21

# NVM version to install
NVM_VERSION="0.40.3" # Latest as of 2025-05-21

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
	"vite" # React build tool
)

# List of basic packages to install
ESSENTIAL_PACKAGES=(
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

# List of PPA repositories to add
PPA_LIST=(
	"ppa:ondrej/nginx" # For Nginx
	"ppa:ondrej/php"   # For PHP
)

#---------------------------------------------------------------------------------
# Helper Functions
#---------------------------------------------------------------------------------
# Prints a formatted log message
# Usage: log "type" "Your message here"
log() {
	local COLOR=$([[ $1 == error ]] && echo 31 || echo 32)
	local SEP=$(printf '%*s' "$(tput cols)" | tr ' ' '-')
	echo -e "\033[1;${COLOR}m${SEP}\n[${1^^}] ${@:2}\n${SEP}\033[0m"
}

# Print error and exit
error_and_exit() {
	log error "$1"
	exit 1
}

#---------------------------------------------------------------------------------
# System Preparation
#---------------------------------------------------------------------------------

# Update package lists
update_package_lists() {
	log info "Updating package lists"
	sudo apt-get update -y || error_and_exit "Failed to update package lists"
}

# Upgrade the system
upgrade_system() {
	log info "Upgrading system packages"
	sudo apt-get dist-upgrade -y || error_and_exit "Failed to upgrade system"
}

# Cleanup system
cleanup_system() {
	log info "Cleaning up system"
	# Clean up package cache and remove unused packages to free up disk space
	sudo apt-get autoremove -y && sudo apt-get autoclean -y && sudo apt-get clean -y || error_and_exit "Failed to clean up system"
}

# Add PPA repositories
add_repositories() {
	log info "Adding PPA repositories"
	for ppa in "${PPA_LIST[@]}"; do
		sudo add-apt-repository -y "$ppa" 2>/dev/null || error_and_exit "Failed to add repository $ppa"
	done
	update_package_lists
}

#---------------------------------------------------------------------------------
# Package Installation
#---------------------------------------------------------------------------------

# Install a package
install_package() {
	log info "Installing ${2:-$1}"
	sudo apt-get install -y "$1" || error_and_exit "Failed to install $1"
}

# Install essential packages
essential_packages() {
	log info "Installing essential packages"
	update_package_lists
	for package in "${ESSENTIAL_PACKAGES[@]}"; do
		install_package "$package" "$package"
	done
}

#---------------------------------------------------------------------------------
# GitHub CLI Configuration
#---------------------------------------------------------------------------------

configure_github_cli() {
	log info "Configuring GitHub CLI"

	# Scope for GitHub CLI
	local SCOPE="repo,user,admin:repo_hook,admin:ssh_signing_key,admin:public_key,admin:gpg_key"

	# Login to GitHub CLI
	gh auth login -s "$SCOPE" -h github.com -w || error_and_exit "GitHub CLI login failed"

	# Check GitHub CLI authentication status
	gh auth status || error_and_exit "GitHub CLI authentication status check failed"
}

#---------------------------------------------------------------------------------
# Git Configuration
#---------------------------------------------------------------------------------

configure_git() {
	log info "Configuring Git for GitHub User"

	# Get GitHub username and email automatically
	local GITHUB_USER=$(gh api user -q .name) || error_and_exit "Unable to fetch GitHub username"
	local GITHUB_EMAIL=$(gh api user/emails --jq '.[0].email') || error_and_exit "Unable to fetch GitHub email"

	# Set global git configuration
	git config --global user.name "$GITHUB_USER" || error_and_exit "Unable to set git name"
	git config --global user.email "$GITHUB_EMAIL" || error_and_exit "Unable to set git email"
	git config --global init.defaultBranch main || error_and_exit "Unable to set default branch"
	git config --global pull.rebase true || error_and_exit "Unable to set pull.rebase"
	git config --global core.editor "nano" || error_and_exit "Unable to set git editor"

	# Verify git configuration
	git config --list || error_and_exit "Unable to list git configuration"
}

#---------------------------------------------------------------------------------
# SSH Key Configuration
#---------------------------------------------------------------------------------

configure_ssh_key() {
	log info "Generating SSH key and adding to GitHub"

	# Get GitHub user email automatically
	local GITHUB_EMAIL=$(gh api user/emails --jq '.[0].email') || error_and_exit "Unable to fetch GitHub email for SSH key comment"

	# Generate SSH key if it doesn't exist
	if [[ ! -f ~/.ssh/id_ed25519 ]]; then
		ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f ~/.ssh/id_ed25519 -N "" || error_and_exit "Failed to generate SSH key"
	fi

	# Add SSH key to ssh-agent
	eval "$(ssh-agent -s)" || error_and_exit "Failed to start ssh-agent"
	ssh-add ~/.ssh/id_ed25519 || error_and_exit "Failed to add SSH key to ssh-agent"

	# Add SSH key to GitHub account (use file directly)
	gh ssh-key add ~/.ssh/id_ed25519.pub || error_and_exit "Failed to add SSH key to GitHub account"

	# Set Github CLI operations protocol to SSH
	gh config set git_protocol ssh || error_and_exit "Failed to set GitHub CLI git protocol to SSH"

	echo "SSH key configured and added to GitHub successfully."
}

#---------------------------------------------------------------------------------
# GPG Key Configuration
#---------------------------------------------------------------------------------

configure_gpg_key() {
	log info "Generating GPG key and adding to GitHub"

	# Get GitHub user name and email
	local GITHUB_USER=$(gh api user -q .name) || error_and_exit "Unable to fetch GitHub username for GPG key"
	local GITHUB_EMAIL=$(gh api user/emails --jq '.[0].email') || error_and_exit "Unable to fetch GitHub email for GPG key"

	# Generate GPG key if it doesn't exist
	if [[ -z "$(gpg --list-secret-keys --with-colons "$GITHUB_EMAIL" | grep '^sec:')" ]]; then
		log info "Generating GPG key"
		gpg --batch --passphrase "" --quick-generate-key "${GITHUB_USER} <${GITHUB_EMAIL}>" ed25519 cert,sign 0 || error_and_exit "Failed to generate GPG key"
	fi

	# Get GPG key ID
	local GPG_KEY_ID=$(gpg --list-keys --with-colons "${GITHUB_USER} <${GITHUB_EMAIL}>" | awk -F: '/^pub:/ { print $5 }' | head -n 1)

	# Add GPG key to GitHub account
	gh gpg-key add <(gpg --armor --export "$GPG_KEY_ID") || error_and_exit "Failed to add GPG key to GitHub account"

	# Set GPG key configuration for Git
	git config --global user.signingkey "$GPG_KEY_ID" || error_and_exit "Failed to set GPG key for Git"
	git config --global commit.gpgsign true || error_and_exit "Failed to set GPG signing for commits"
	git config --global tag.gpgsign true || error_and_exit "Failed to set GPG signing for tags"

	echo "GPG key configured and added to GitHub successfully."
}

#---------------------------------------------------------------------------------
# Firewall Configuration (UFW)
#---------------------------------------------------------------------------------

configure_ufw() {
	log info "Configuring UFW (Uncomplicated Firewall)"

	# Set default policies
	sudo ufw default deny incoming || error_and_exit "Failed to set UFW incoming policy"
	sudo ufw default allow outgoing || error_and_exit "Failed to set UFW outgoing policy"

	# Allow essential ports
	sudo ufw allow ssh || error_and_exit "Failed to allow SSH through UFW"
	sudo ufw allow http || error_and_exit "Failed to allow HTTP through UFW"
	sudo ufw allow https || error_and_exit "Failed to allow HTTPS through UFW"

	# Enable UFW
	sudo ufw --force enable || error_and_exit "Failed to enable UFW"

	# Check UFW status
	sudo ufw status verbose || error_and_exit "Failed to check UFW status"
}

#---------------------------------------------------------------------------------
# Intrusion Prevention (Fail2Ban)
#---------------------------------------------------------------------------------

configure_fail2ban() {
	log info "Configuring Fail2Ban"
	sudo systemctl enable fail2ban || error_and_exit "Failed to enable Fail2Ban service"
	sudo systemctl restart fail2ban || error_and_exit "Failed to restart Fail2Ban"
	sudo systemctl status fail2ban || error_and_exit "Failed to check Fail2Ban status"
}

#---------------------------------------------------------------------------------
# Nginx
#---------------------------------------------------------------------------------

install_nginx() {
	install_package nginx "Nginx Web Server"
}

#---------------------------------------------------------------------------------
# PHP
#---------------------------------------------------------------------------------

install_php() {
	install_package "php$PHP_VERSION" "PHP $PHP_VERSION"
}

php_extensions() {
	for extension in "${PHP_EXTENSIONS[@]}"; do
		install_package "php$PHP_VERSION-$extension" "PHP extension: $extension"
	done
}

#---------------------------------------------------------------------------------
# Composer
#---------------------------------------------------------------------------------

install_composer() {
	log info "Installing Composer"
	curl -sS https://getcomposer.org/installer -o composer-setup.php &&
		sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer || error_and_exit "Failed to install Composer"
	rm -f composer-setup.php
}

composer_packages() {
	log info "Installing Composer global packages"
	for package in "${COMPOSER_GLOBAL_PACKAGES[@]}"; do
		composer global require "$package" || error_and_exit "Failed to install Composer package $package"
	done
}

#---------------------------------------------------------------------------------
# Node.js
#---------------------------------------------------------------------------------
install_nodejs() {
	log info "Installing Node.js via NVM"
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash || error_and_exit "Failed to install NVM"
	bash -c 'source "$HOME/.nvm/nvm.sh" && nvm install node && corepack enable yarn' || error_and_exit "Failed to install Node.js or enable yarn"
}

install_nodejs_packages() {
	log info "Installing Node.js global packages"
	for package in "${NODEJS_GLOBAL_PACKAGES[@]}"; do
		npm install -g "$package" || error_and_exit "Failed to install Node.js package $package"
	done
}

#---------------------------------------------------------------------------------
# Main Setup
#---------------------------------------------------------------------------------

# Main setup function
setup_system() {
	log info "Starting system setup"
	essential_packages
	add_repositories
	upgrade_system
	cleanup_system

	configure_github_cli
	configure_git
	configure_ssh_key
	configure_gpg_key

	configure_ufw
	configure_fail2ban

	install_nginx
	install_php
	php_extensions

	install_composer
	composer_packages

	install_nodejs
	install_nodejs_packages
	log info "System setup completed"
}

#---------------------------------------------------------------------------------
# Main Script
#---------------------------------------------------------------------------------

setup_system

#---------------------------------------------------------------------------------
# Cleanup
#---------------------------------------------------------------------------------

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
# - Do not run as root. This script will prompt for sudo password.
