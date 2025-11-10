#!/bin/bash
# Firebase development tools for Claude Code
# Helps Claude manage Firebase services quickly

cd /Users/duskolicanin/git/rab_booking

echo "========================================="
echo "🔥 FIREBASE DEVELOPMENT TOOLS"
echo "========================================="
echo ""

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not installed!"
    echo "Install: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI: $(firebase --version)"
echo ""

# Menu
echo "Choose action:"
echo ""
echo "1️⃣  Start Emulators (Firestore + Functions + Hosting)"
echo "2️⃣  Validate Firestore Rules"
echo "3️⃣  Validate Firestore Indexes"
echo "4️⃣  Deploy to Firebase (Production)"
echo "5️⃣  Deploy Firestore Rules Only"
echo "6️⃣  Deploy Firestore Indexes Only"
echo "7️⃣  Check Firebase Project Status"
echo "8️⃣  View Firestore Rules"
echo "9️⃣  Test Firestore Rules (with emulator)"
echo "🔟  Quick Deploy (Hosting only - owner + widget)"
echo ""

read -p "Enter choice [1-10]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting Firebase Emulators..."
        echo "   - Firestore: http://localhost:8080"
        echo "   - Functions: http://localhost:5001"
        echo "   - Hosting (owner): http://localhost:5000"
        echo "   - Hosting (widget): http://localhost:5002"
        echo "   - Emulator UI: http://localhost:4000"
        echo ""
        firebase emulators:start
        ;;
    2)
        echo ""
        echo "🔍 Validating Firestore Rules..."
        if firebase firestore:rules:validate firestore.rules; then
            echo "✅ Firestore rules are valid!"
        else
            echo "❌ Firestore rules have errors!"
        fi
        ;;
    3)
        echo ""
        echo "🔍 Validating Firestore Indexes..."
        if cat firestore.indexes.json | python3 -m json.tool > /dev/null 2>&1; then
            echo "✅ Firestore indexes JSON is valid!"
            echo ""
            echo "Indexes defined:"
            cat firestore.indexes.json | python3 -m json.tool | grep -A5 "collectionGroup"
        else
            echo "❌ Firestore indexes JSON is invalid!"
        fi
        ;;
    4)
        echo ""
        echo "🚀 Deploying to Firebase Production..."
        echo "⚠️  This will deploy:"
        echo "   - Firestore rules"
        echo "   - Firestore indexes"
        echo "   - Cloud Functions"
        echo "   - Hosting (owner + widget)"
        echo ""
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            firebase deploy
        else
            echo "Cancelled."
        fi
        ;;
    5)
        echo ""
        echo "🚀 Deploying Firestore Rules..."
        firebase deploy --only firestore:rules
        ;;
    6)
        echo ""
        echo "🚀 Deploying Firestore Indexes..."
        firebase deploy --only firestore:indexes
        ;;
    7)
        echo ""
        echo "📊 Firebase Project Status..."
        firebase projects:list
        echo ""
        echo "Current project:"
        firebase use
        ;;
    8)
        echo ""
        echo "📄 Current Firestore Rules:"
        echo "========================================="
        cat firestore.rules
        ;;
    9)
        echo ""
        echo "🧪 Testing Firestore Rules with Emulator..."
        echo "1. Starting emulator..."
        firebase emulators:exec "echo 'Emulator ready for testing'" --only firestore &
        sleep 5
        echo ""
        echo "2. Run your tests now or use Emulator UI:"
        echo "   http://localhost:4000"
        echo ""
        read -p "Press Enter when done..."
        ;;
    10)
        echo ""
        echo "🚀 Quick Deploy (Hosting Only)..."
        echo "Deploying owner and widget..."
        firebase deploy --only hosting:owner,hosting:widget
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Done!"
