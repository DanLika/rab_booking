#!/bin/bash
# Quick error analysis for Claude Code
# Helps Claude identify and categorize errors quickly

echo "========================================="
echo "🐛 ERROR ANALYSIS REPORT"
echo "========================================="
echo ""

cd /Users/duskolicanin/git/rab_booking

# Run flutter analyze and capture output
ANALYZE_OUTPUT=$(flutter analyze 2>&1)

# Count errors by type
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep "error •" | wc -l | tr -d ' ')
WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep "warning •" | wc -l | tr -d ' ')
INFO_COUNT=$(echo "$ANALYZE_OUTPUT" | grep "info •" | wc -l | tr -d ' ')

echo "📊 Summary:"
echo "  Errors:   $ERROR_COUNT"
echo "  Warnings: $WARNING_COUNT"
echo "  Info:     $INFO_COUNT"
echo ""

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "========================================="
    echo "🔴 ERRORS (Must Fix)"
    echo "========================================="
    echo "$ANALYZE_OUTPUT" | grep "error •" | head -20
    echo ""
fi

if [ "$WARNING_COUNT" -gt 0 ]; then
    echo "========================================="
    echo "⚠️  WARNINGS (Should Fix)"
    echo "========================================="
    echo "$ANALYZE_OUTPUT" | grep "warning •" | head -20
    echo ""
fi

# Common error patterns
echo "========================================="
echo "🔍 Common Error Patterns"
echo "========================================="
echo ""

echo "1. Missing imports:"
grep -rn "Undefined" <<< "$ANALYZE_OUTPUT" | head -5
echo ""

echo "2. Type errors:"
grep -rn "type.*isn't.*type" <<< "$ANALYZE_OUTPUT" | head -5
echo ""

echo "3. Null safety issues:"
grep -rn "null" <<< "$ANALYZE_OUTPUT" | head -5
echo ""

echo "4. Missing members:"
grep -rn "isn't defined" <<< "$ANALYZE_OUTPUT" | head -5
echo ""

echo "5. Switch statement issues:"
grep -rn "exhaustively matched" <<< "$ANALYZE_OUTPUT" | head -5
echo ""

echo "========================================="
echo "💡 Quick Fix Suggestions"
echo "========================================="
echo ""
echo "Run: dart fix --dry-run    # See what can be auto-fixed"
echo "Run: dart fix --apply      # Auto-fix issues"
echo "Run: dart format lib/      # Format code"
echo ""

# Check for deprecated API usage
echo "========================================="
echo "⚠️  Deprecated API Usage"
echo "========================================="
grep -rn "deprecated" <<< "$ANALYZE_OUTPUT" | head -10
echo ""

exit 0
