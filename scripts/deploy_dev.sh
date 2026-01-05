#!/bin/bash
# Deploy to development environment
echo "🔧 Deploying to DEVELOPMENT..."

# Switch to dev project
firebase use development

# Build web apps
echo "📦 Building widget..."
flutter build web --release --target lib/widget_main.dart -o build/web_widget

echo "📦 Building owner dashboard..."
flutter build web --release --target lib/main_dev.dart -o build/web_owner

# Deploy
echo "🚀 Deploying to Firebase..."
firebase deploy --only hosting,functions

echo "✅ Development deployment complete!"
