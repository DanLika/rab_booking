#!/bin/bash
# update_og_tags.sh
# Post-build script to update Open Graph tags for each target
#
# Run this after flutter build for each target:
#   ./scripts/update_og_tags.sh
#
# Or integrate into CI/CD pipeline

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Updating Open Graph meta tags for all build targets...${NC}"

# === OWNER BUILD (app.bookbed.io) ===
OWNER_INDEX="$PROJECT_ROOT/build/web_owner/index.html"
if [ -f "$OWNER_INDEX" ]; then
    echo -e "${GREEN}✓ Owner build found${NC}"
    # Owner uses app.bookbed.io - no changes needed if already correct
    sed -i '' 's|https://app\.bookbed\.io/og-image\.png|https://app.bookbed.io/og-image.png|g' "$OWNER_INDEX" 2>/dev/null || true
    sed -i '' 's|content="#0066FF"|content="#6B4CE6"|g' "$OWNER_INDEX" 2>/dev/null || true
    
    # Copy og-image to build folder
    cp "$PROJECT_ROOT/web/og-image.png" "$PROJECT_ROOT/build/web_owner/og-image.png" 2>/dev/null || true
    echo "  - Updated theme-color to #6B4CE6"
    echo "  - Copied og-image.png"
else
    echo -e "${RED}✗ Owner build not found at $OWNER_INDEX${NC}"
fi

# === WIDGET BUILD (view.bookbed.io and *.view.bookbed.io) ===
WIDGET_INDEX="$PROJECT_ROOT/build/web_widget/index.html"
if [ -f "$WIDGET_INDEX" ]; then
    echo -e "${GREEN}✓ Widget build found${NC}"
    
    # Update OG tags for widget domain
    sed -i '' 's|https://app\.bookbed\.io/og-image\.png|https://view.bookbed.io/og-image.png|g' "$WIDGET_INDEX"
    sed -i '' 's|https://app\.bookbed\.io"|https://view.bookbed.io"|g' "$WIDGET_INDEX"
    sed -i '' 's|BookBed - Property Management Platform|BookBed - Book Your Stay|g' "$WIDGET_INDEX"
    sed -i '' 's|BookBed - Vacation Rental Management|BookBed - Book Your Stay|g' "$WIDGET_INDEX"
    sed -i '' 's|Manage your vacation rentals with ease|Book your perfect vacation rental|g' "$WIDGET_INDEX"
    sed -i '' 's|content="#0066FF"|content="#6B4CE6"|g' "$WIDGET_INDEX" 2>/dev/null || true
    
    # Copy og-image to build folder
    cp "$PROJECT_ROOT/web/og-image.png" "$PROJECT_ROOT/build/web_widget/og-image.png" 2>/dev/null || true
    echo "  - Updated OG URL to view.bookbed.io"
    echo "  - Updated OG titles for booking widget"
    echo "  - Updated theme-color to #6B4CE6"
    echo "  - Copied og-image.png"
else
    echo -e "${RED}✗ Widget build not found at $WIDGET_INDEX${NC}"
fi

# === ADMIN BUILD (bookbed-admin.web.app) ===
ADMIN_INDEX="$PROJECT_ROOT/build/web_admin/index.html"
if [ -f "$ADMIN_INDEX" ]; then
    echo -e "${GREEN}✓ Admin build found${NC}"
    
    # Update OG tags for admin domain
    sed -i '' 's|https://app\.bookbed\.io/og-image\.png|https://bookbed-admin.web.app/og-image.png|g' "$ADMIN_INDEX"
    sed -i '' 's|https://app\.bookbed\.io"|https://bookbed-admin.web.app"|g' "$ADMIN_INDEX"
    sed -i '' 's|BookBed - Property Management Platform|BookBed Admin|g' "$ADMIN_INDEX"
    sed -i '' 's|BookBed - Vacation Rental Management|BookBed Admin Dashboard|g' "$ADMIN_INDEX"
    sed -i '' 's|content="#0066FF"|content="#6B4CE6"|g' "$ADMIN_INDEX" 2>/dev/null || true
    
    # Copy og-image to build folder
    cp "$PROJECT_ROOT/web/og-image.png" "$PROJECT_ROOT/build/web_admin/og-image.png" 2>/dev/null || true
    echo "  - Updated OG URL to bookbed-admin.web.app"
    echo "  - Updated OG title for admin dashboard"
    echo "  - Updated theme-color to #6B4CE6"
    echo "  - Copied og-image.png"
else
    echo -e "${RED}✗ Admin build not found at $ADMIN_INDEX${NC}"
fi

echo ""
echo -e "${GREEN}✓ Open Graph tags update complete!${NC}"
echo ""
echo "Deploy with: firebase deploy --only hosting"
