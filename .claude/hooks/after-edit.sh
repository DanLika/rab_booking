#!/bin/bash
# Hook that runs after file edits
# Automatically checks for Flutter/Dart errors
#
# Claude Code passes the edited file path as the first argument ($1)

# Dynamically resolve project root (portable across environments)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Get edited file from first argument (passed by Claude Code)
EDITED_FILE="${1:-}"

# Exit early if no file provided
if [[ -z "$EDITED_FILE" ]]; then
    exit 0
fi

# Only run for Dart files
if [[ "$EDITED_FILE" == *.dart ]]; then
    echo "Running flutter analyze on edited file..."
    cd "$PROJECT_ROOT"
    flutter analyze "$EDITED_FILE" --no-fatal-infos 2>&1 | head -20
fi

exit 0
