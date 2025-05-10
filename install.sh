#!/bin/bash

declare -A SUPPORTED_OS=(["ubuntu"]="24.04")

log() { local c; case ${1^^} in INFO)c="30;47";;WARNING)c="30;43";;ERROR)c="30;41";;*)echo -e "\n[${1^^}] $2";return;;esac; echo -e "\n\033[${c}m ${1^^} \033[0m $2"; }
exit() { log ERROR "$1"; command exit "${2:-1}"; }

check_os() { source /etc/os-release 2>/dev/null; log INFO "${PRETTY_NAME:-Unknown OS} detected."; [[ "${SUPPORTED_OS[${ID:-unknown}]}" == "${VERSION_ID:-unknown}" ]] || { read -r -p "$(log WARNING "Unsupported OS: ${PRETTY_NAME:-${ID:-unknown}} ${VERSION_ID:-unknown}. Continue? (y/n)") " confirm; [[ "$confirm" =~ ^[Yy]$ ]] || exit "Aborted by user."; }; }

install_dependencies() {
  log INFO "Installing dependencies..."
  [[ "${ID:-unknown}" == "ubuntu" ]] && {
    sudo apt update -y || exit "apt update failed."
    sudo apt install -y --no-install-recommends git || exit "apt install git failed."
  } || log WARNING "Skipping dependency install for ${ID:-unknown}."
}

install_dotfiles() {
  log INFO "Installing dotfiles..."
  cd "$HOME" || exit "Failed to cd to home."
  [[ -d ".dotfiles" ]] && rm -rf ".dotfiles" || :
  git clone https://github.com/midhunmonachan/dotfiles.git ".dotfiles" || exit "Clone failed."
  rm -f ".dotfiles/README.md" ".dotfiles/install.sh" || log WARNING "Cleanup failed."
  log INFO "Dotfiles installed."
}

check_os
install_dependencies
install_dotfiles
