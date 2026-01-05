#!/bin/bash
# Performance profiling helper for Claude Code
# Helps Claude identify performance bottlenecks quickly

echo "========================================="
echo "⚡ FLUTTER PERFORMANCE PROFILING"
echo "========================================="
echo ""

# Dynamically resolve project root (portable across environments)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 1. Check for common performance anti-patterns
echo "🔍 Checking for performance anti-patterns..."
echo ""

echo "1. Non-const constructors in build methods:"
grep -rn "Widget build" lib/ | head -5
echo ""

echo "2. Unnecessary setState calls:"
grep -rn "setState(" lib/ | wc -l | xargs -I {} echo "   Found {} setState calls (review for optimization)"
echo ""

echo "3. Large build methods (>50 lines):"
for file in $(find lib/ -name "*.dart"); do
    # Count lines in build methods
    awk '/Widget build\(BuildContext/ {start=NR} start && /^  \}/ {print FILENAME ":" start "-" NR " (" NR-start " lines)"; start=0}' "$file" 2>/dev/null | awk -F'[:-]' '{if ($3-$2 > 50) print}'
done | head -10
echo ""

echo "4. Missing const constructors:"
grep -rn "class.*Widget" lib/ | grep -v "const" | head -10
echo ""

echo "5. Rebuilding issues - providers without .family or .autoDispose:"
grep -rn "Provider\(" lib/ | grep -v "family" | grep -v "autoDispose" | wc -l | xargs -I {} echo "   Found {} providers without optimization"
echo ""

# 2. Check widget rebuild counts
echo "========================================="
echo "📊 Widget Inspector Recommendations"
echo "========================================="
echo ""
echo "To profile in real-time:"
echo "1. Run app in Profile mode (not Debug!)"
echo "2. Open DevTools → Performance tab"
echo "3. Click 'Record' and interact with UI"
echo "4. Look for:"
echo "   - Red bars (frame drops)"
echo "   - Excessive rebuilds (same widget multiple times)"
echo "   - Shader compilation (first run slowness)"
echo ""

echo "Quick commands:"
echo "  flutter run --profile  # Profile mode"
echo "  p                      # Toggle performance overlay (in app)"
echo "  w                      # Dump widget tree"
echo ""

echo "========================================="
echo "💡 Common Fixes"
echo "========================================="
echo ""
echo "1. Add 'const' to StatelessWidget constructors"
echo "2. Extract widgets to avoid rebuilding entire tree"
echo "3. Use Consumer instead of watching entire provider"
echo "4. Add .family to providers that depend on parameters"
echo "5. Add .autoDispose to providers not used globally"
echo "6. Use RepaintBoundary for expensive widgets"
echo ""
