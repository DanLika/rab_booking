#!/bin/bash
# Deploy to staging environment
echo "🎭 Deploying to STAGING..."

# Switch to staging project
firebase use staging

# Build web apps
echo "📦 Building widget..."
flutter build web --release --target lib/widget_main.dart -o build/web_widget

echo "📦 Building owner dashboard..."
flutter build web --release --target lib/main_staging.dart -o build/web_owner

# Deploy
echo "🚀 Deploying to Firebase..."
firebase deploy --only hosting,functions

echo "✅ Staging deployment complete!"
