#!/bin/bash
# Quick start Firebase Emulators for development
# Used by Claude for rapid testing

# Dynamically resolve project root (portable across environments)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

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
