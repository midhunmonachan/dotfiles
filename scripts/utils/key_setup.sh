#!/bin/sh

# Function to prompt for GitHub user details
prompt_github_details() {
  GITHUB_NAME=$(git config --global user.name)
  GITHUB_EMAIL=$(git config --global user.email)

  if [ -z "$GITHUB_NAME" ]; then
    read -p "Enter your GitHub name: " GITHUB_NAME
    git config --global user.name "$GITHUB_NAME" || return 1
  fi

  if [ -z "$GITHUB_EMAIL" ]; then
    read -p "Enter your GitHub email: " GITHUB_EMAIL
    git config --global user.email "$GITHUB_EMAIL" || return 1
  fi
}

# Function to delete existing SSH and GPG keys
delete_existing_keys() {
  read -p "Do you want to delete all existing SSH and GPG keys? (y/n): " DELETE_KEYS

  if [ "$DELETE_KEYS" = "y" ]; then
    # Delete existing SSH keys
    rm -f ~/.ssh/id_* || return 1

    # Delete existing GPG keys
    rm -rf ~/.gnupg || return 1
    mkdir -p ~/.gnupg || return 1
    chmod 700 ~/.gnupg || return 1

    print_info "Existing SSH and GPG keys deleted."
  else
    print_warning "No keys were deleted. Continuing with existing keys."
  fi

  print_empty_line
}

# Function to generate SSH and GPG keys
generate_keys() {
  # Generate SSH key
  SSH_KEY_FILE="$HOME/.ssh/id_ed25519"
  if [ ! -f "$SSH_KEY_FILE" ]; then
    ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$SSH_KEY_FILE" -N "" > /dev/null || return 1
    eval "$(ssh-agent -s)" > /dev/null || return 1
    ssh-add "$SSH_KEY_FILE" 2>/dev/null || return 1
    print_info "SSH key generated and added to ssh-agent. Copy the following key to your GitHub account settings:"
    cat "$SSH_KEY_FILE.pub"
  else
    print_warning "SSH key already exists. Copy the following key to your GitHub account settings:"
    cat "$SSH_KEY_FILE.pub"
  fi

  print_empty_line

  # Generate GPG key
  if ! gpg --list-keys 2>/dev/null | grep -q "$GITHUB_EMAIL"; then
    cat > gpg_batch <<EOF
%no-protection
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: $GITHUB_NAME
Name-Comment: ""
Name-Email: $GITHUB_EMAIL
Expire-Date: 0
EOF

    gpg --batch --generate-key gpg_batch 2>/dev/null || return 1
    rm gpg_batch

    print_info "GPG key generated. Copy the following key to your GitHub account settings:"
    gpg --armor --export "$GITHUB_EMAIL" 2>/dev/null
  else
    print_warning "GPG key already exists. Copy the following key to your GitHub account settings:"
    gpg --armor --export "$GITHUB_EMAIL" 2>/dev/null
  fi

  print_empty_line
}