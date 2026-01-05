#!/bin/bash
# Run app in staging mode
echo "🚀 Starting BookBed in STAGING mode..."
flutter run -t lib/main_staging.dart --dart-define=ENVIRONMENT=staging
