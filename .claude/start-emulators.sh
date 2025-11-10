#!/bin/bash
# Quick start Firebase Emulators for development
# Used by Claude for rapid testing

cd /Users/duskolicanin/git/rab_booking

echo "🔥 Starting Firebase Emulators..."
echo ""
echo "Services:"
echo "  📊 Firestore:       http://localhost:8080"
echo "  ⚡ Functions:       http://localhost:5001"
echo "  🌐 Hosting (owner): http://localhost:5000"
echo "  🎨 Hosting (widget):http://localhost:5002"
echo "  🎛️  Emulator UI:    http://localhost:4000"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start emulators
firebase emulators:start
