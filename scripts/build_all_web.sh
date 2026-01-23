#!/bin/bash

# Build All Web Targets Script
# This script builds all three web targets (owner, widget, admin)
# and updates their Open Graph meta tags with correct domain URLs

set -e

# Find flutter in PATH or use homebrew location
FLUTTER=$(which flutter 2>/dev/null || echo "/opt/homebrew/bin/flutter")
if [ ! -x "$FLUTTER" ]; then
    echo "Error: Flutter not found. Please install Flutter or update the path."
    exit 1
fi

echo "=== BookBed Web Build Script ==="
echo "Using Flutter: $FLUTTER"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# OG tags are now handled by the unified script: scripts/update_og_tags.sh

# Build Owner Dashboard
echo -e "${YELLOW}1. Building Owner Dashboard...${NC}"
$FLUTTER build web --release --target lib/main.dart -o build/web_owner
echo -e "${GREEN}   Owner build complete${NC}"
# Owner keeps app.bookbed.io (default)
echo "  Meta tags: app.bookbed.io (default)"
echo ""

# Build Widget
echo -e "${YELLOW}2. Building Booking Widget...${NC}"
$FLUTTER build web --release --target lib/widget_main.dart -o build/web_widget
echo -e "${GREEN}   Widget build complete${NC}"
update_meta_tags "build/web_widget" "view.bookbed.io" \
    "BookBed - Online Booking Widget" \
    "Book your stay directly. Check availability, select dates, and pay online securely."
echo ""

# Build Admin Dashboard
echo -e "${YELLOW}3. Building Admin Dashboard...${NC}"
$FLUTTER build web --release --target lib/admin_main.dart -o build/web_admin
echo -e "${GREEN}   Admin build complete${NC}"
echo ""

# Update OG meta tags for all targets
echo -e "${YELLOW}4. Updating Open Graph meta tags for all domains...${NC}"
./scripts/update_og_tags.sh
echo ""

echo -e "${GREEN}=== All builds complete ===${NC}"
echo ""
echo "Deploy with:"
echo "  firebase deploy --only hosting        # Deploy all"
echo "  firebase deploy --only hosting:owner  # Deploy owner only"
echo "  firebase deploy --only hosting:widget # Deploy widget only"
echo "  firebase deploy --only hosting:admin  # Deploy admin only"
