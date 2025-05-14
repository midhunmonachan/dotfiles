#!/usr/bin/env bash
# Combines all .sh scripts in src/scripts/ into a single dot.sh in build/
set -euo pipefail

SRC_DIR="$(dirname "$0")/scripts"
OUT_DIR="$(dirname "$0")/../build"
OUT_FILE="$OUT_DIR/dot.sh"

mkdir -p "$OUT_DIR"

# Backup old build if it exists
if [[ -f "$OUT_FILE" ]]; then
	cp "$OUT_FILE" "$OUT_FILE.bak"
	BACKUP_MADE=1
	echo "Backup of existing $OUT_FILE created at $OUT_FILE.bak"
else
	BACKUP_MADE=0
	echo "No existing $OUT_FILE found. No backup created."
fi

# Start with a shebang and a header
{
	echo "#!/usr/bin/env bash"
	echo "# Auto-generated from $(git config --get remote.origin.url | sed -E 's#(git@|https://)github.com[:/](.*)\.git#https://github.com/\2#') on $(date)"
	echo
} >"$OUT_FILE"

# Concatenate all scripts in alphabetical order
for script in "$SRC_DIR"/*.sh; do
	if [[ -f "$script" ]]; then
		echo "# --- $script ---" >>"$OUT_FILE"
		cat "$script" >>"$OUT_FILE"
		echo -e "\n" >>"$OUT_FILE"
	fi
done

chmod +x "$OUT_FILE"
echo "Generated script created at $OUT_FILE"

# Run all test scripts in the tests directory
TEST_DIR="$(dirname "$0")/../tests"
TEST_FAILED=0

if compgen -G "$TEST_DIR/*.sh" >/dev/null; then
	echo "Running tests..."
	for test_script in "$TEST_DIR"/*.sh; do
		if [[ -x "$test_script" ]]; then
			echo "Running $test_script"
			if ! "$test_script"; then
				echo "Test $test_script failed."
				TEST_FAILED=1
				break
			fi
		else
			echo "Skipping $test_script (not executable)"
		fi
	done

	if [[ $TEST_FAILED -eq 1 ]]; then
		echo "One or more tests failed."
		if [[ "$BACKUP_MADE" -eq 1 ]]; then
			echo "Restoring previous build from backup."
			mv "$OUT_FILE.bak" "$OUT_FILE"
		else
			echo "No previous build to restore. Deleting failed build."
			rm -f "$OUT_FILE"
		fi
		exit 1
	else
		echo "All tests passed."
		echo "Build successful! dot.sh is ready at $OUT_FILE"
	fi
else
	echo "No test scripts found in $TEST_DIR."
	echo "Stopping build and removing $OUT_FILE."
	rm -f "$OUT_FILE"
	exit 1
fi

# Remove backup if tests passed
if [[ -f "$OUT_FILE.bak" ]]; then
	rm -f "$OUT_FILE.bak"
fi
