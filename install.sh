#!/bin/bash

declare -A SUPPORTED_OS=(["ubuntu"]="24.04")

log() { local l=${1^^} lc ms= me=; case $l in INFO)lc="30;47";;WARN)lc="30;43";ms='\033[33m';me='\033[0m';;ERROR)lc="30;41";ms='\033[31m';me='\033[0m';;*)echo -e "\n[$l] $2";return;;esac;echo -e "\n\033[${lc}m $l \033[0m${ms} $2${me}"; }
check_os() { source /etc/os-release 2>/dev/null; log INFO "${PRETTY_NAME:-Unknown OS} detected."; [[ "${SUPPORTED_OS[${ID:-unknown}]}" == "${VERSION_ID:-unknown}" ]] || { read -r -p "$(log WARN "Unsupported OS: ${PRETTY_NAME:-${ID:-unknown}} ${VERSION_ID:-unknown}. Continue? (y/n)") " confirm; [[ "$confirm" =~ ^[Yy]$ ]] || exit "Aborted by user."; }; }
exit() { log ERROR "$1"; command exit "${2:-1}"; }

install_dependencies() {
  log INFO "Installing dependencies..."
  [[ "${ID:-unknown}" == "ubuntu" ]] && {
    sudo apt update -y || exit "apt update failed."
    sudo apt install -y --no-install-recommends git || exit "apt install git failed."
  } || log WARN "Skipping dependency install for ${ID:-unknown}."
}

install_dotfiles() {
  log INFO "Installing dotfiles..."
  cd "$HOME" || exit "Failed to cd to home."
  [[ -d ".dotfiles" ]] && rm -rf ".dotfiles" || :
  git clone https://github.com/midhunmonachan/dotfiles.git ".dotfiles" || exit "Clone failed."
  rm -f ".dotfiles/README.md" ".dotfiles/install.sh" || log WARN "Cleanup failed."
  log INFO "Dotfiles installed."
}

install_dot_command() {
  log INFO "Installing 'dot' command..."
  [[ ! -f "dot_command.sh" ]] && exit "'dot_command.sh' not found."
  sudo chmod +x "dot_command.sh" || exit "Failed to make 'dot_command.sh' executable."
  sudo cp "dot_command.sh" "/usr/local/bin/dot" || exit "Failed to copy 'dot_command.sh' to /usr/local/bin/dot"
  log INFO "'dot' command installed to /usr/local/bin/dot."
}

check_os
install_dependencies
install_dotfiles
install_dot_command
