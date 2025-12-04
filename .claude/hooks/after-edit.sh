#!/bin/bash
# Hook that runs after file edits
# Automatically checks for Flutter/Dart errors

# Dynamically resolve project root (portable across environments)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Only run for Dart files
if [[ "$EDITED_FILE" == *.dart ]]; then
    echo "Running flutter analyze on edited file..."
    cd "$PROJECT_ROOT"
    flutter analyze "$EDITED_FILE" --no-fatal-infos 2>&1 | head -20
fi

exit 0
