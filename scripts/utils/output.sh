#!/bin/sh

# Function to print an empty line
print_empty_line() {
  echo ""
}

# Function to print informational messages in magenta
print_info() {
  TEXT=$1
  printf "\033[35m%s\033[0m\n" "$TEXT"
  print_empty_line
}

# Function to print warning messages in yellow
print_warning() {
  TEXT=$1
  printf "\033[33m%s\033[0m\n" "$TEXT"
  print_empty_line
}

# Function to print error messages in red
print_error() {
  TEXT=$1
  printf "\033[31m%s\033[0m\n" "$TEXT"
  print_empty_line
}

# Function to print prompts in yellow
print_prompt() {
  TEXT=$1
  print_empty_line
  printf "\033[33m%s\033[0m" "$TEXT"
}

# Function to print key outputs in green
print_key_output() {
  TEXT=$1
  printf "\033[32m%s\033[0m\n" "$TEXT"
}

# Function to handle errors
handle_error() {
  print_error "$1"
  exit 1
}