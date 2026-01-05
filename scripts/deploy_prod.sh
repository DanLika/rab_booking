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
flutter build web --release --target lib/widget_main.dart -o build/web_widget

echo "📦 Building owner dashboard..."
flutter build web --release --target lib/main_prod.dart -o build/web_owner

# Deploy
echo "🚀 Deploying to Firebase..."
firebase deploy --only hosting,functions

echo "✅ Production deployment complete!"
