#!/bin/bash
set -e

echo "🚀 RAB Booking - Flutter Web Build Script"
echo "=========================================="
echo ""

# Check if Flutter is already installed
if command -v flutter &> /dev/null; then
    echo "✓ Flutter already installed"
    flutter --version
else
    echo "📦 Installing Flutter SDK..."

    # Download Flutter stable (3.35.6 has Dart 3.9.0+ required by pubspec.yaml)
    FLUTTER_VERSION="3.35.6-stable"
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}.tar.xz"

    echo "  - Downloading Flutter ${FLUTTER_VERSION}..."
    curl -sS -O ${FLUTTER_URL}

    echo "  - Extracting Flutter..."
    tar xf flutter_linux_${FLUTTER_VERSION}.tar.xz

    # Add Flutter to PATH
    export PATH="$PATH:`pwd`/flutter/bin"

    # Cleanup
    rm flutter_linux_${FLUTTER_VERSION}.tar.xz

    echo "✓ Flutter installed successfully!"
    flutter --version
fi

echo ""
echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "🔨 Building for web..."
flutter build web --release

echo ""
echo "✅ Build complete! Output: build/web/"
echo "=========================================="
