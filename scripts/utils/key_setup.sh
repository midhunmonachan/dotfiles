#!/bin/sh

# Function to prompt for GitHub details
prompt_github_details() {
  GITHUB_NAME=$(git config --global user.name)
  GITHUB_EMAIL=$(git config --global user.email)

  if [ -z "$GITHUB_NAME" ] || [ -z "$GITHUB_EMAIL" ]; then
    print_prompt "Enter your git name: "
    read -r GITHUB_NAME
    print_prompt "Enter your git email: "
    read GITHUB_EMAIL
    git config --global user.name "$GITHUB_NAME"
    git config --global user.email "$GITHUB_EMAIL"
  else
    echo "Current git user details:"
    printf "Name: "
    print_key_output "$GITHUB_NAME"
    printf "Email: "
    print_key_output "$GITHUB_EMAIL"
    print_prompt "Do you want to modify these details? (y/n): "
    read MODIFY_DETAILS
    if [ "$MODIFY_DETAILS" = "y" ]; then
      print_prompt "Enter your git name: "
      read -r GITHUB_NAME
      print_prompt "Enter your git email: "
      read GITHUB_EMAIL
      git config --global user.name "$GITHUB_NAME"
      git config --global user.email "$GITHUB_EMAIL"
    fi
  fi
}

# Function to delete existing SSH and GPG keys
delete_existing_keys() {
  print_prompt "Do you want to delete all existing SSH and GPG keys? (y/n): "
  read DELETE_KEYS

  print_empty_line

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
    print_key_output "$(cat "$SSH_KEY_FILE.pub")"
  else
    print_warning "SSH key already exists. Copy the following key to your GitHub account settings:"
    print_key_output "$(cat "$SSH_KEY_FILE.pub")"
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

    gpg --batch --generate-key gpg_batch > /dev/null 2>&1 || return 1
    rm gpg_batch

    print_info "GPG key generated. Copy the following key to your GitHub account settings:"
    print_key_output "$(gpg --armor --export "$GITHUB_EMAIL" 2>/dev/null)"
  else
    print_warning "GPG key already exists. Copy the following key to your GitHub account settings:"
    print_key_output "$(gpg --armor --export "$GITHUB_EMAIL" 2>/dev/null)"
  fi

  print_empty_line

  # Configure Git to use the GPG key
  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep '^sec' | awk '{print $2}' | cut -d'/' -f2)
  git config --global user.signingkey "$GPG_KEY_ID" || return 1
  git config --global commit.gpgSign true || return 1
  print_info "Git configured to sign commits with the GPG key."
}