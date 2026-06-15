#!/bin/bash
# Deploy to production environment
echo "🚨 Deploying to PRODUCTION..."
echo "⚠️  Are you sure? This will affect live users!"
read -p "Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Source secrets from gitignored .env.production. `set -a` exports vars for the
# build subprocess. STRIPE_* land in the shell env ONLY — they are NEVER passed
# via --dart-define (that would bake the secret into main.dart.js). Only
# SENTRY_DSN is forwarded to the client build below.
set -a
[ -f .env.production ] && source .env.production
set +a
if [ -z "$SENTRY_DSN" ]; then
    echo "🔴 SENTRY_DSN empty (add it to .env.production) — aborting to avoid a Sentry-blind PROD build."
    exit 1
fi

# Switch to production project
firebase use production

# Build web apps
echo "📦 Building widget..."
flutter build web --release --no-tree-shake-icons --target lib/widget_main.dart --dart-define=SENTRY_DSN="$SENTRY_DSN" -o build/web_widget

# CRITICAL (.claude/rules/widget.md): `flutter build -o` rewrites the output dir,
# so the iframe-scroll overlay must be re-copied AFTER every widget build —
# otherwise the deploy ships a widget with broken scroll on view.bookbed.io
# (a regression, not just a missing polish). cp + verify, fail-closed.
cp web/bookbed-overlay.js build/web_widget/ || { echo "🔴 overlay.js copy failed — aborting"; exit 1; }
[ -f build/web_widget/bookbed-overlay.js ] || { echo "🔴 overlay.js missing post-copy — aborting"; exit 1; }

echo "📦 Building owner dashboard..."
flutter build web --release --no-tree-shake-icons --target lib/main_prod.dart --dart-define=SENTRY_DSN="$SENTRY_DSN" -o build/web_owner

echo "📦 Building admin panel..."
flutter build web --release --no-tree-shake-icons --target lib/admin_main.dart --dart-define=SENTRY_DSN="$SENTRY_DSN" -o build/web_admin

# Update OG meta tags for all targets
echo "🏷️  Updating OG tags for all domains..."
./scripts/update_og_tags.sh

# Deploy — hosting only. Functions are deployed separately/deliberately
# (a CF redeploy can transiently strip Cloud Run allUsers/invoker IAM, and the
# safe order is CF → hosting → rules, not bundled). For CF changes run e.g.
# `firebase deploy --only functions:<name>` on its own.
echo "🚀 Deploying hosting (owner + widget + admin)..."
firebase deploy --only hosting:owner,hosting:widget,hosting:admin

echo "✅ Production deployment complete!"

# Restore default working alias to dev — never leave the shell pointed at PROD
firebase use development
