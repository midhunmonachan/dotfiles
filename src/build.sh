#!/usr/bin/env bash
# Combines all .sh scripts in src/scripts/ into a single dot.sh in build/
set -euo pipefail

SRC_DIR="$(dirname "$0")/scripts"
OUT_DIR="$(dirname "$0")/../build"
OUT_FILE="$OUT_DIR/dot.sh"

mkdir -p "$OUT_DIR"

# Start with a shebang and a header
{
	echo "#!/usr/bin/env bash"
	echo "# Auto-generated from $(git config --get remote.origin.url | sed -E 's#(git@|https://)github.com[:/](.*)\.git#https://github.com/\2#') on $(date)"
	echo
} >"$OUT_FILE"

# Concatenate all scripts in alphabetical order
for script in "$SRC_DIR"/*.sh; do
	if [[ -f "$script" ]]; then
		echo "# --- $script ---" >>"$OUT_FILE"s
		cat "$script" >>"$OUT_FILE"
		echo -e "\n" >>"$OUT_FILE"
	fi
done

chmod +x "$OUT_FILE"
echo "Combined script created at $OUT_FILE"
