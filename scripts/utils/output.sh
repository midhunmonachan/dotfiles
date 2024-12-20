#!/bin/sh

# Function to print informational messages in green
print_info() {
  TEXT=$1
  echo "\033[32m${TEXT}\033[0m"
}

# Function to print warning messages in yellow
print_warning() {
  TEXT=$1
  echo "\033[33m${TEXT}\033[0m"
}

# Function to print error messages in red
print_error() {
  TEXT=$1
  echo "\033[31m${TEXT}\033[0m"
}

# Function to print an empty line
print_empty_line() {
  echo ""
}