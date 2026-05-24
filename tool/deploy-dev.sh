#!/usr/bin/env bash
#
# Deploy DEV builds to bookbed-dev Firebase project.
#
# Refuses to deploy a PROD-options build to dev hosting (the audit/33
# F-OwnerDashboard-001 contamination class — fix locked in here at build time).
#
# Usage:
#   tool/deploy-dev.sh owner    # owner dashboard → bookbed-owner-dev.web.app
#   tool/deploy-dev.sh widget   # booking widget  → bookbed-widget-dev.web.app
#
# Admin DEV not yet supported — lib/admin_main_dev.dart does not exist.
# See .claude/rules/hosting-build.md "Dart entrypoints" table.

set -euo pipefail

PROJECT_ID="bookbed-dev"
SURFACE="${1:-}"

err() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; }
ok()  { printf '\033[32m✓ %s\033[0m\n' "$*"; }
info(){ printf '\033[36mℹ %s\033[0m\n' "$*"; }

usage() {
  cat <<EOF
Usage: $0 <surface>

Surfaces:
  owner    Build owner dashboard with --target lib/owner_main_dev.dart,
           deploy to hosting:owner on $PROJECT_ID.
  widget   Build booking widget with --target lib/widget_main_dev.dart,
           deploy to hosting:widget on $PROJECT_ID.

After deploy, open the URL → DevTools Network → confirm the first Firestore
request targets projects/$PROJECT_ID/databases/(default). If it targets
rab-booking-248fc you bundled the wrong entry point — re-run this script.

Reference: audit/33-owner-dashboard-web-smoke-2026-05-24.md §2.6
EOF
  exit 2
}

case "$SURFACE" in
  owner)
    ENTRY="lib/owner_main_dev.dart"
    OUTDIR="build/web_owner"
    TARGET="owner"
    URL="https://bookbed-owner-dev.web.app"
    ;;
  widget)
    ENTRY="lib/widget_main_dev.dart"
    OUTDIR="build/web_widget"
    TARGET="widget"
    URL="https://bookbed-widget-dev.web.app"
    ;;
  ""|"-h"|"--help")
    usage
    ;;
  admin)
    err "Admin DEV entry point not yet implemented (lib/admin_main_dev.dart missing)."
    err "See .claude/rules/hosting-build.md 'Dart entrypoints' table TODO."
    exit 3
    ;;
  *)
    err "Unknown surface: $SURFACE"
    usage
    ;;
esac

# Refuse if entry point file does not exist or imports the wrong Firebase options
if [[ ! -f "$ENTRY" ]]; then
  err "Entry point $ENTRY does not exist at expected path."
  exit 4
fi

if ! grep -q "firebase_options_dev" "$ENTRY"; then
  err "$ENTRY does not import firebase_options_dev — refusing to deploy."
  err "PROD options would be bundled. See audit/33 §2 contamination class."
  exit 5
fi

if ! grep -q "expectedProjectId.*bookbed-dev" "$ENTRY"; then
  info "$ENTRY missing kDebugMode assert for bookbed-dev project ID — consider adding (defense-in-depth)."
fi

# Firebase CLI authentication check
if ! command -v firebase >/dev/null 2>&1; then
  err "firebase CLI not found in PATH."
  exit 6
fi

if ! firebase projects:list >/dev/null 2>&1; then
  err "firebase CLI not authenticated. Run: firebase login"
  exit 7
fi

# Verify project alias resolves
if ! grep -q "\"$PROJECT_ID\"" .firebaserc 2>/dev/null; then
  err ".firebaserc does not reference $PROJECT_ID — refusing to deploy."
  exit 8
fi

info "Surface:       $SURFACE"
info "Entry point:   $ENTRY"
info "Output dir:    $OUTDIR"
info "Hosting target: $TARGET"
info "Firebase project: $PROJECT_ID"
info "URL: $URL"
echo

# Build
info "Building Flutter web ($SURFACE) with $ENTRY ..."
flutter build web \
  --release \
  --target "$ENTRY" \
  -o "$OUTDIR"
ok "Build complete: $OUTDIR"

# Widget-only: copy overlay script + embed.js (mirror of deploy-widget.yml CI)
if [[ "$SURFACE" == "widget" ]]; then
  if [[ -f "web/bookbed-overlay.js" ]]; then
    cp web/bookbed-overlay.js "$OUTDIR/"
    ok "Copied web/bookbed-overlay.js → $OUTDIR/"
  fi
  if [[ -f "public/embed.js" ]]; then
    cp public/embed.js "$OUTDIR/"
    ok "Copied public/embed.js → $OUTDIR/"
  fi
fi

# Deploy
info "Deploying to Firebase Hosting ($TARGET on $PROJECT_ID) ..."
firebase deploy \
  --only "hosting:$TARGET" \
  --project "$PROJECT_ID"
ok "Deploy complete."

echo
ok "Open $URL"
info "Verify in DevTools Network panel that the first Firestore request targets:"
info "  projects/$PROJECT_ID/databases/(default)"
info "If it targets rab-booking-248fc you have contamination — see audit/33."
