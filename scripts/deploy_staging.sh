#!/bin/bash
# Deploy to staging environment
echo "🎭 Deploying to STAGING..."

# Switch to staging project
firebase use staging

# Build web apps
echo "📦 Building widget..."
flutter build web --release --target lib/widget_main_staging.dart -o build/web_widget

echo "📦 Building owner dashboard..."
flutter build web --release --target lib/main_staging.dart -o build/web_owner

# Update OG meta tags for all targets
echo "🏷️  Updating OG tags for all domains..."
./scripts/update_og_tags.sh

# Deploy
echo "🚀 Deploying to Firebase..."
firebase deploy --only hosting,functions

echo "✅ Staging deployment complete!"
