#!/bin/bash
# Run app in production mode
echo "🚀 Starting BookBed in PRODUCTION mode..."
flutter run -t lib/main_prod.dart --dart-define=ENVIRONMENT=production
