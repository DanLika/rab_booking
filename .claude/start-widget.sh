#!/bin/bash
# Quick script to start widget on port 8081
# Usage: ./.claude/start-widget.sh

echo "Starting Flutter widget on port 8081..."
cd /Users/duskolicanin/git/rab_booking

# Clean build if flag provided
if [[ "$1" == "--clean" ]]; then
    echo "Cleaning build..."
    flutter clean
    flutter pub get
fi

# Start server
flutter run -d chrome --web-port=8081 --dart-define=FLUTTER_WEB_USE_SKIA=true

echo ""
echo "Widget available at:"
echo "  http://localhost:8081/widget?propertyId=YOUR_PROPERTY&unitId=YOUR_UNIT"
