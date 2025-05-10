#!/bin/bash

declare -A SUPPORTED_OS
SUPPORTED_OS["ubuntu"]="24.04"

log() { local c; case ${1^^} in INFO)c="30;42";;WARNING)c="30;43";;ERROR)c="30;41";;*)echo -e "[${1^^}] $2";return;;esac; echo -e "\\033[${c}m ${1^^} \\033[0m $2"; }

check_os() { source /etc/os-release 2>/dev/null; log INFO "${PRETTY_NAME:-Unknown OS} detected."; [[ -v SUPPORTED_OS[${ID:-unknown}] && ",${SUPPORTED_OS[${ID:-unknown}]}," == *",${VERSION_ID:-unknown},"* ]] || { read -r -p "$(log WARNING "Unsupported OS. Continue? (y/n)") " confirm; [[ "$confirm" =~ ^[Yy]$ ]] || { log ERROR "Aborted by user."; exit 1; }; }; }

install_dependencies() {
	log INFO "Installing dependencies...";
	[[ "${ID:-unknown}" == "ubuntu" ]] && sudo apt update -y && sudo apt install -y --no-install-recommends git;
}

install_dotfiles() {
	log INFO "Installing dotfiles...";
	(
	  cd "$HOME" || { log ERROR "Failed to change to $HOME directory. Aborting installation."; exit 1; }

	  if [[ -d ".dotfiles" ]]; then
		  log INFO "Existing .dotfiles directory found. Removing it before fresh installation."
		  rm -rf ".dotfiles" || { log ERROR "Failed to remove existing .dotfiles directory."; exit 1; }
	  fi

	  git clone https://github.com/midhunmonachan/dotfiles.git ".dotfiles" || { log ERROR "Failed to clone dotfiles repository."; exit 1; }

	  rm -f ".dotfiles/README.md" && rm -f ".dotfiles/install.sh"
	) || exit 1
}

check_os
install_dependencies
install_dotfiles
