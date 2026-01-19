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

# Function to update meta tags in index.html
update_meta_tags() {
    local build_dir=$1
    local domain=$2
    local title=$3
    local description=$4

    local index_file="${build_dir}/index.html"

    if [ ! -f "$index_file" ]; then
        echo -e "${RED}Error: ${index_file} not found${NC}"
        return 1
    fi

    echo "  Updating meta tags for ${domain}..."

    # Update canonical URL
    sed -i '' "s|href=\"https://app.bookbed.io\"|href=\"https://${domain}\"|g" "$index_file"

    # Update og:image
    sed -i '' "s|content=\"https://app.bookbed.io/og-image.png\"|content=\"https://${domain}/og-image.png\"|g" "$index_file"

    # Update og:url
    sed -i '' "s|<meta property=\"og:url\" content=\"https://app.bookbed.io\">|<meta property=\"og:url\" content=\"https://${domain}\">|g" "$index_file"

    # Update og:title if provided
    if [ -n "$title" ]; then
        sed -i '' "s|<meta property=\"og:title\" content=\"BookBed - Property Management Platform\">|<meta property=\"og:title\" content=\"${title}\">|g" "$index_file"
        sed -i '' "s|<meta name=\"twitter:title\" content=\"BookBed - Property Management Platform\">|<meta name=\"twitter:title\" content=\"${title}\">|g" "$index_file"
    fi

    # Update og:description if provided
    if [ -n "$description" ]; then
        sed -i '' "s|Manage your vacation rentals with ease. Bookings, calendars, pricing, and online payments - all in one place.|${description}|g" "$index_file"
        sed -i '' "s|Manage your vacation rentals with ease. Bookings, calendars, pricing, and online payments.|${description}|g" "$index_file"
    fi

    # Update twitter:image
    sed -i '' "s|content=\"https://app.bookbed.io/og-image.png\"|content=\"https://${domain}/og-image.png\"|g" "$index_file"

    echo -e "  ${GREEN}Done${NC}"
}

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
update_meta_tags "build/web_admin" "bookbed-admin.web.app" \
    "BookBed Admin Dashboard" \
    "Admin dashboard for BookBed platform management."
echo ""

echo -e "${GREEN}=== All builds complete ===${NC}"
echo ""
echo "Deploy with:"
echo "  firebase deploy --only hosting        # Deploy all"
echo "  firebase deploy --only hosting:owner  # Deploy owner only"
echo "  firebase deploy --only hosting:widget # Deploy widget only"
echo "  firebase deploy --only hosting:admin  # Deploy admin only"
