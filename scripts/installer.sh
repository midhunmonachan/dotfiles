#!/bin/bash

source "$(dirname "$0")/common.sh"

cd "$(dirname "$0")/.."

#echo current directory
showMessage "Current directory: $(pwd)\n"

# Clean the whole directory except the dotfiles directory and scripts directory
showMessage "Cleaning the directory..."
executeAndCheck find . -mindepth 1 -not -path './dotfiles*' -not -path './scripts*' -delete
