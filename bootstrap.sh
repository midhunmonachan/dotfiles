#!/usr/bin/env bash
set -euo pipefail

DOT_DIR="$HOME/.dotfiles"
URL="https://github.com/midhunmonachan/dotfiles/archive/main.tar.gz"

trap 'echo "Installation failed. Cleaning up..." && rm -rf "$DOT_DIR"' ERR
curl -sL "$URL" | tar xz --strip-components=1 -C "${DOT_DIR:?}" && chmod +x "$DOT_DIR/setup_dot.sh" && "$DOT_DIR/setup_dot.sh"
