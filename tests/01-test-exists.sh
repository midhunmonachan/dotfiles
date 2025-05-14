#!/usr/bin/env bash
set -euo pipefail

BUILD_SCRIPT="$(dirname "$0")/../build/dot.sh"

# Test: Check if the script exists and is executable
if [[ -x "$BUILD_SCRIPT" ]]; then
	echo "PASS: dot.sh exists and is executable."
else
	echo "FAIL: dot.sh does not exist or is not executable."
	exit 1
fi
