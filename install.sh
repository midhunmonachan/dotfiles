#!/bin/bash

declare -A SUPPORTED_OS
SUPPORTED_OS["ubuntu"]="24.04"

log() { local l=${1^^} m=$2 c; case $l in INFO)c="30;42";;WARNING)c="30;43";;ERROR)c="30;41";;*)echo -e "[$l] $m";return;;esac; echo -e "\\033[${c}m $l \\033[0m $m"; }

check_os() { source /etc/os-release 2>/dev/null; log INFO "${PRETTY_NAME:-Unknown OS} detected."; [[ -v SUPPORTED_OS[${ID:-unknown}] && ",${SUPPORTED_OS[${ID:-unknown}]}," == *",${VERSION_ID:-unknown},"* ]] || { read -r -p "$(log WARNING "Unsupported OS. Continue? (y/n)") " confirm; [[ "$confirm" =~ ^[Yy]$ ]] || { log ERROR "Aborted by user."; exit 1; }; }; }

install_dependencies() {
	log INFO "Installing dependencies...";
	[[ "${ID:-unknown}" == "ubuntu" ]] && sudo apt update -y && sudo apt install -y --no-install-recommends git;
}

check_os
install_dependencies
