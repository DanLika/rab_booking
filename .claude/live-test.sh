#!/bin/bash
# Live testing workflow for Claude Code
# Manages browsers, emulators, and multi-instance testing

# Dynamically resolve project root (portable across environments)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================="
echo "🧪 LIVE TESTING WORKFLOW"
echo "========================================="
echo ""

echo "Choose testing scenario:"
echo ""
echo "1️⃣  Full Stack Test (Emulators + Flutter + Browser)"
echo "2️⃣  Firebase Emulator + Widget"
echo "3️⃣  Multi-Browser Test (Chrome, Safari, Firefox)"
echo "4️⃣  Mobile Emulator (iOS Simulator)"
echo "5️⃣  Mobile Emulator (Android)"
echo "6️⃣  Production-like Test (No Emulators)"
echo "7️⃣  Kill All Test Processes"
echo ""

read -p "Enter choice [1-7]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting Full Stack Test Environment..."
        echo ""

        # Start Firebase Emulators in background
        echo "1. Starting Firebase Emulators..."
        firebase emulators:start > /tmp/firebase-emulators.log 2>&1 &
        FIREBASE_PID=$!
        echo "   Firebase PID: $FIREBASE_PID"
        sleep 5

        # Start Flutter app
        echo "2. Starting Flutter app on port 8081..."
        flutter run -d chrome --web-port=8081 > /tmp/flutter-app.log 2>&1 &
        FLUTTER_PID=$!
        echo "   Flutter PID: $FLUTTER_PID"
        sleep 10

        # Open browsers
        echo "3. Opening test URLs..."
        open http://localhost:4000  # Emulator UI
        sleep 2
        open http://localhost:8081  # Widget

        echo ""
        echo "✅ Full stack ready!"
        echo ""
        echo "Services running:"
        echo "  - Firebase Emulators: http://localhost:4000"
        echo "  - Flutter Widget:     http://localhost:8081"
        echo ""
        echo "Logs:"
        echo "  - Firebase: tail -f /tmp/firebase-emulators.log"
        echo "  - Flutter:  tail -f /tmp/flutter-app.log"
        echo ""
        echo "To stop: ./.claude/live-test.sh → Option 7"
        ;;

    2)
        echo ""
        echo "🔥 Starting Firebase + Widget Test..."

        # Start emulators
        firebase emulators:start > /tmp/firebase-emulators.log 2>&1 &
        sleep 5

        # Start widget
        flutter run -d chrome --web-port=8081 > /tmp/flutter-widget.log 2>&1 &
        sleep 10

        open "http://localhost:8081?propertyId=test&unitId=test"

        echo "✅ Ready for testing!"
        ;;

    3)
        echo ""
        echo "🌐 Multi-Browser Testing..."

        # Start Flutter once
        flutter run -d chrome --web-port=8081 > /tmp/flutter-app.log 2>&1 &
        sleep 10

        # Open in multiple browsers
        open -a "Google Chrome" http://localhost:8081
        sleep 1
        open -a "Safari" http://localhost:8081
        sleep 1

        # Firefox (if installed)
        if [ -d "/Applications/Firefox.app" ]; then
            open -a "Firefox" http://localhost:8081
        fi

        echo "✅ Opened in multiple browsers!"
        ;;

    4)
        echo ""
        echo "📱 iOS Simulator Test..."

        # List available simulators
        echo "Available iOS Simulators:"
        xcrun simctl list devices available | grep "iPhone"
        echo ""

        # Start simulator and run app
        flutter run -d ios
        ;;

    5)
        echo ""
        echo "🤖 Android Emulator Test..."

        # List available emulators
        echo "Available Android Emulators:"
        flutter emulators
        echo ""

        read -p "Emulator name (or press Enter for default): " emulator_name

        if [ -z "$emulator_name" ]; then
            flutter run -d android
        else
            flutter run -d "$emulator_name"
        fi
        ;;

    6)
        echo ""
        echo "🏭 Production-like Test (No Emulators)..."
        echo "⚠️  Will connect to real Firebase!"
        echo ""
        read -p "Continue? (yes/no): " confirm

        if [ "$confirm" = "yes" ]; then
            flutter run -d chrome --web-port=8081 --release
        else
            echo "Cancelled."
        fi
        ;;

    7)
        echo ""
        echo "🛑 Killing all test processes..."

        # Kill Firebase emulators
        pkill -f "firebase emulators" 2>/dev/null

        # Kill Flutter processes
        pkill -f "flutter run" 2>/dev/null

        # Kill Chrome instances
        pkill -f "flutter_tools_chrome_device" 2>/dev/null

        # Clean up log files
        rm -f /tmp/firebase-emulators.log /tmp/flutter-app.log /tmp/flutter-widget.log

        echo "✅ All processes killed!"
        ;;

    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Done!"
