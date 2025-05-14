#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# 00-blank_test.sh
#
# Example blank test: This test always passes!
#
# Usage:
#   This script is intended as a template for writing new test scripts.
#   The build system will automatically run all .sh files in this directory.
#
# How it works:
#   - The script checks a condition
#   - If the condition passes, it prints a PASS message and exits with code 0 (success).
#   - If the condition fails, it prints a FAIL message and exits with code 1 (failure).
#
# Why use exit codes?
#   - exit 0: Signals success to the build system or any calling process.
#   - exit 1: Signals failure, which can be used to halt the build or indicate a problem.
#
# You can copy this file and modify the logic to create your own tests.
# -----------------------------------------------------------------------------

set -euo pipefail

# Test: Check if the testing logic is working
if [[ 0 -eq 0 ]]; then
	echo "PASS: Testing logic is working!"
	# This is a test success, so we exit with a zero code.
	# This will signal to the build system that everything is okay.
	# The build system can then proceed with the next steps.
	exit 0
else
	echo "FAIL: Not happy with the testing logic as it should always pass!"
	# This is a test failure, so we exit with a non-zero code.
	# This will signal to the build system that something went wrong.
	# The build system can then take appropriate action.
	exit 1
fi
