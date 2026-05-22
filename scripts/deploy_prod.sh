#!/bin/bash
# Deploy to production environment
echo "🚨 Deploying to PRODUCTION..."
echo "⚠️  Are you sure? This will affect live users!"
read -p "Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Switch to production project
firebase use production

# Build web apps
echo "📦 Building widget..."
flutter build web --release --target lib/widget_main.dart --dart-define=SENTRY_DSN="$SENTRY_DSN" -o build/web_widget

echo "📦 Building owner dashboard..."
flutter build web --release --target lib/main_prod.dart --dart-define=SENTRY_DSN="$SENTRY_DSN" -o build/web_owner

# Update OG meta tags for all targets
echo "🏷️  Updating OG tags for all domains..."
./scripts/update_og_tags.sh

# Deploy
echo "🚀 Deploying to Firebase..."
firebase deploy --only hosting,functions

echo "✅ Production deployment complete!"
