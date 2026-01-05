#!/bin/bash
# Find all TODO, FIXME, BUG, OPTIMIZE comments in project
# Usage: ./.claude/check-todos.sh

echo "========================================="
echo "📋 PROJECT TODOs, FIXMEs, and BUGS"
echo "========================================="
echo ""

# Dynamically resolve project root (portable across environments)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Find TODO comments
echo "🔵 TODO Items:"
grep -rn "// TODO:" lib/ 2>/dev/null | head -20 || echo "  None found"
echo ""

# Find FIXME comments
echo "🔴 FIXME Items:"
grep -rn "// FIXME:" lib/ 2>/dev/null | head -20 || echo "  None found"
echo ""

# Find BUG comments
echo "🐛 BUG Items:"
grep -rn "// BUG:" lib/ 2>/dev/null | head -20 || echo "  None found"
echo ""

# Find OPTIMIZE comments
echo "⚡ OPTIMIZE Items:"
grep -rn "// OPTIMIZE:" lib/ 2>/dev/null | head -20 || echo "  None found"
echo ""

echo "========================================="
echo "Run 'flutter analyze' for code issues"
echo "========================================="
