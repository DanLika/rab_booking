#!/bin/bash
# Hook that runs after file edits
# Automatically checks for Flutter/Dart errors

# Only run for Dart files
if [[ "$EDITED_FILE" == *.dart ]]; then
    echo "Running flutter analyze on edited file..."
    cd /Users/duskolicanin/git/rab_booking
    flutter analyze "$EDITED_FILE" --no-fatal-infos 2>&1 | head -20
fi

exit 0
