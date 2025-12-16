#!/bin/bash
# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃=======================> Midhun's Server Setup Script <=======================┃
# ┃                                                                              ┃
# ┃  Automated server configuration and software installation for Ubuntu 24.04   ┃
# ┃------------------------------------------------------------------------------┃
# ┃  Author: Midhun Monachan                                Updated: 2025-05-21  ┃
# ┃  GitHub: github.com/midhunmonachan                             License: MIT  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

#---------------------------------------------------------------------------------
# Configuration Variables
#---------------------------------------------------------------------------------

# Code Folder Location
CODE_DIR="$HOME/code"

# PHP version to install
PHP_VERSION="8.4" # Latest as of 2025-05-21

# NVM version to install
NVM_VERSION="0.40.3" # Latest as of 2025-05-21

# PHP extensions to install
PHP_EXTENSIONS=(
	"cli"       # Command-line interface for PHP scripts
	"fpm"       # FastCGI Process Manager for serving PHP via web servers
#	"mysql"     # MySQL database driver for PHP
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
#	"gh"                         # GitHub CLI
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
# Initial Checks
#---------------------------------------------------------------------------------

# Check if it is running Ubuntu 24.04
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
	echo "ERROR: This script is intended for Ubuntu 24.04 only."
	exit 1
fi

# Ensure the script is not executed as root
if [[ $EUID -eq 0 ]]; then
	echo "ERROR: Do not run this script as root."
	exit 1
fi

#---------------------------------------------------------------------------------
# Initialization
#---------------------------------------------------------------------------------

# Exit on error, unset vars, or failed pipes
set -euo pipefail

CURRENT_COMMAND=""
LAST_COMMAND=""

# Track the last and current line number for accurate error reporting
trap 'LAST_COMMAND=$CURRENT_COMMAND; CURRENT_COMMAND=$BASH_COMMAND; LAST_LINENO=$LINENO' DEBUG

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
# Sudo Keep-Alive Setup
#---------------------------------------------------------------------------------

# Keep sudo authentication active for the script's duration
sudo -v
(while sudo -n true 2>/dev/null; do sleep 2; done) &
SUDO_PID=$!
echo "Sudo keep-alive PID: $SUDO_PID" >>"$LOG_FILE"

#---------------------------------------------------------------------------------
# Script Cleanup
#---------------------------------------------------------------------------------

script_cleanup() {
	local exit_signal=${1:-EXIT}
	local exit_status=${2:-0}
	local line_number=${3:-unknown}

	trap - EXIT INT TERM # Clear traps to prevent re-entry
	echo >/dev/tty

	# Use LAST_LINENO if available
	if [[ "$line_number" == "auto" && -n "${LAST_LINENO-}" ]]; then
		line_number=$LAST_LINENO
	fi

	# Before trying to use LOG_FILE, check if it's defined
	if [[ -n "${LOG_FILE-}" && -f "$LOG_FILE" ]]; then
		echo "=== Stopping: Received $exit_signal (Exit: $exit_status, Line: $line_number), PID: $$ ===" >>"$LOG_FILE"

		# Similarly check SUDO_PID before using it
		if [[ -n "${SUDO_PID-}" ]]; then
			echo "Stopping sudo keep-alive process: $SUDO_PID" >>"$LOG_FILE"
			kill "$SUDO_PID" &>/dev/null || true
		fi

		echo "=== Script execution ended $(date) ===" >>"$LOG_FILE"
	else
		echo "Script stopped before log file initialization" >/dev/tty
	fi

	echo "Script stopped by signal: $exit_signal at line $line_number (exit code: $exit_status)" >/dev/tty

	if [[ -n "${LOG_FILE-}" && -f "$LOG_FILE" ]]; then
		echo "Log file created at: $LOG_FILE" >/dev/tty
	fi
}

trap 'script_cleanup ERR $? auto' ERR
trap 'script_cleanup INT $? "unknown"' INT
trap 'script_cleanup TERM $? "unknown"' TERM
trap 'script_cleanup EXIT $? auto' EXIT

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
	# Remove apache2 if installed (since we use nginx) and clean up system in one line
	dpkg -l | grep -q apache2 && log info "Uninstalling apache2 (conflicts with nginx)" && sudo systemctl stop apache2 || true && sudo apt-get purge -y apache2 apache2-utils apache2-bin apache2.2-common || true && sudo rm -rf /etc/apache2 /var/log/apache2 || true
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
	       local max_retries=3
	       local attempt=1
	       local success=0

		       # Only login if not already authenticated
		       if ! gh auth status --hostname github.com &>/dev/null; then
			       while [[ $attempt -le $max_retries ]]; do
				       gh auth login -s "$SCOPE" -h github.com -w && success=1 && break
				       log error "GitHub CLI login failed (attempt $attempt/$max_retries)"
				       ((attempt++))
				       sleep 30 # Wait before retrying
			       done

			       if [[ $success -ne 1 ]]; then
				       error_and_exit "GitHub CLI login failed after $max_retries attempts"
			       fi
		       fi

		       gh auth status || error_and_exit "GitHub CLI authentication status check failed"
		       GITHUB_USER=$(gh api user -q .name) || error_and_exit "Unable to fetch GitHub username"
		       GITHUB_EMAIL=$(gh api user/emails --jq '.[0].email') || error_and_exit "Unable to fetch GitHub email"
}

#---------------------------------------------------------------------------------
# Git Configuration
#---------------------------------------------------------------------------------

configure_git() {
	log info "Configuring Git"

	# Set global git configuration
	git config --global user.name "$GITHUB_USER" || error_and_exit "Unable to set git name"
	git config --global user.email "$GITHUB_EMAIL" || error_and_exit "Unable to set git email"
	git config --global init.defaultBranch main || error_and_exit "Unable to set default branch"
	git config --global pull.rebase true || error_and_exit "Unable to set pull.rebase"
	git config --global core.editor "nano" || error_and_exit "Unable to set git editor"

	# Verify git configuration
	git config --global --list || error_and_exit "Unable to list git configuration"
}

#---------------------------------------------------------------------------------
# SSH Key Configuration
#---------------------------------------------------------------------------------

configure_ssh_key() {
	log info "Generating and adding SSH key to GitHub"

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

	# Add GitHub's SSH key to known_hosts
	ssh-keyscan -H github.com >>~/.ssh/known_hosts 2>/dev/null || error_and_exit "Failed to add GitHub to known_hosts"

	echo "SSH key configured and added to GitHub successfully."
}

#---------------------------------------------------------------------------------
# GPG Key Configuration
#---------------------------------------------------------------------------------

configure_gpg_key() {
	log info "Generating and adding GPG key to GitHub"

	# Generate GPG key if it doesn't exist
	if [[ -z "$(gpg --list-secret-keys --with-colons "$GITHUB_EMAIL" | grep '^sec:')" ]]; then
		log info "Generating GPG key"
		gpg --batch --passphrase "" --quick-generate-key "${GITHUB_USER} <${GITHUB_EMAIL}>" ed25519 cert,sign 0 || error_and_exit "Failed to generate GPG key"
	fi

	# Get GPG key ID
	local GPG_KEY_ID=$(gpg --list-keys --with-colons "${GITHUB_USER} <${GITHUB_EMAIL}>" | awk -F: '/^pub:/ { print $5 }' | head -n 1)

	       # Add GPG key to GitHub account only if not already present
	       if ! gh gpg-key list | grep -q "$GPG_KEY_ID"; then
		       gh gpg-key add <(gpg --armor --export "$GPG_KEY_ID") || error_and_exit "Failed to add GPG key to GitHub account"
	       else
		       log info "GPG key already exists on GitHub account, skipping add."
	       fi

	# Set GPG key configuration for Git
	git config --global user.signingkey "$GPG_KEY_ID" || error_and_exit "Failed to set GPG key for Git"
	git config --global commit.gpgsign true || error_and_exit "Failed to set GPG signing for commits"
	git config --global tag.gpgsign true || error_and_exit "Failed to set GPG signing for tags"

	echo "GPG key configured and added to GitHub successfully."
}

#---------------------------------------------------------------------------------
# Setup Code Directory
#---------------------------------------------------------------------------------

code_directory() {
	log info "Cloning all GitHub repositories to $CODE_DIR"

	# Create code directory and change to it
	[[ -d "$CODE_DIR" ]] && rm -rf "$CODE_DIR" && echo "Removed existing code directory: $CODE_DIR"
	mkdir -p "$CODE_DIR" || error_and_exit "Failed to create code folder: $CODE_DIR"
	cd "$CODE_DIR" || error_and_exit "Failed to change directory to $CODE_DIR"

	# Fetch url list of all repositories
	local REPO_URLS=$(gh repo list --limit 1000 --json sshUrl --jq '.[].sshUrl') || error_and_exit "Failed to list GitHub repositories"

	# Clone all repositories
	[[ -z "$REPO_URLS" ]] && echo "No repositories found to clone." || while read -r url; do git clone "$url"; done <<<"$REPO_URLS"

	# Change back to the original directory
	cd "$(dirname "${BASH_SOURCE[0]}")"
}

#---------------------------------------------------------------------------------
# Windows Shortcut for Code Directory
#---------------------------------------------------------------------------------

wsl_shortcut() {
	# Continue only if running in WSL
	! grep -qE "(Microsoft|WSL)" /proc/version &>/dev/null && return 0

	log info "Creating Windows shortcut for WSL code directory"

	local win_dir_name="code"

	# Get Windows user profile path
	local win_user_profile=$(powershell.exe -NoProfile -NonInteractive -Command "echo \$env:USERPROFILE" | tr -d '\r')

	# Create Windows shortcut path
	local windows_code_path="${win_user_profile}\\${win_dir_name}.lnk"

	# PowerShell script to create the shortcut
	local ps_script
	ps_script="\$wshell = New-Object -ComObject WScript.Shell; "
	ps_script+="\$sc = \$wshell.CreateShortcut('${windows_code_path}'); "
	ps_script+="\$sc.TargetPath = 'explorer.exe'; "
	ps_script+="\$sc.Arguments = '$(wsl.exe wslpath -w "$CODE_DIR")'; "
	ps_script+="\$sc.Description = 'Shortcut to WSL Code Directory ($CODE_DIR)'; "
	ps_script+="\$sc.IconLocation = 'imageres.dll, 166'; " # WSL-like folder icon
	ps_script+="\$sc.Save()"

	# Encode the PowerShell script to Base64 (UTF-16LE is PowerShell's default)
	# This is the most reliable way to pass complex commands to powershell.exe
	local encoded_ps_command
	encoded_ps_command=$(echo "$ps_script" | iconv -f UTF-8 -t UTF-16LE | base64 -w 0) || error_and_exit "Failed to encode PowerShell command"

	powershell.exe -NoProfile -NonInteractive -EncodedCommand "$encoded_ps_command" || error_and_exit "Failed to create Windows shortcut using PowerShell"

	echo "Windows shortcut created: $windows_code_path"
}

#---------------------------------------------------------------------------------
# Bash Setup
#---------------------------------------------------------------------------------

bash_setup() {
	log info "Setting up bash profile"

	# Set bash starting directory
	grep -qFx -- "cd ~" ~/.bashrc || echo "cd ~" >>~/.bashrc
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
	for port in ssh http https; do
		sudo ufw allow "$port" || error_and_exit "Failed to allow $port through UFW"
	done

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

	# Download and run installation script
	curl -sS https://getcomposer.org/installer -o composer-setup.php &&
		sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer || error_and_exit "Failed to install Composer"

	# Cleanup after installation
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

	# Ensure libatomic1 is installed for Node.js shared library dependency
	sudo apt-get install -y libatomic1 || error_and_exit "Failed to install libatomic1 (required for Node.js)"

	# Download and Run NVM Setup Script
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash || error_and_exit "Failed to install NVM"

	# Source NVM into the current script session
	export NVM_DIR="$HOME/.nvm" && source "$NVM_DIR/nvm.sh" || error_and_exit "Failed to source NVM"

	# Install latest Node.js
	nvm install node || error_and_exit "Failed to install Node.js"
	# Install corepack globally using npm
	npm install -g corepack || error_and_exit "Failed to install corepack"
	# Enable yarn via corepack
	corepack enable yarn || error_and_exit "Failed to enable yarn"
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

	#configure_github_cli
	#configure_git

	configure_ssh_key
	configure_gpg_key

	code_directory
	wsl_shortcut
	bash_setup

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
# Notes
#---------------------------------------------------------------------------------
# - This script is under active development. Use at your own risk.
# - Intended for fresh Ubuntu 24.04 installations only.
# - Review the code before running on production systems.
# - Do not run as root. This script will prompt for sudo password.
