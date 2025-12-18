#!/bin/bash
# Design compliance verification for 42lib-flutter
# Constitution XVII: Design Compliance Verification

set -e

echo "🎨 Verifying 42 Brand Design Compliance..."

# Color definitions
EXPECTED_PRIMARY="0xFF00BABC"
THEME_FILE="lib/app/theme.dart"

# Check 1: Validate theme.dart exists
if [ ! -f "$THEME_FILE" ]; then
  echo "❌ ERROR: Theme file not found: $THEME_FILE"
  exit 1
fi

# Check 2: Validate primary color in theme.dart
echo "✓ Checking primary color definition..."
if ! grep -q "Color($EXPECTED_PRIMARY)" "$THEME_FILE"; then
  echo "❌ ERROR: Primary color must be $EXPECTED_PRIMARY (42 teal/cyan with full opacity)"
  echo "   Current theme.dart does not contain correct color value."
  echo ""
  echo "   Expected: static const Color primary42 = Color($EXPECTED_PRIMARY);"
  echo ""
  echo "   Check for common mistakes:"
  echo "   - Missing 'FF' alpha channel: Color(0x00BABC) ← WRONG (transparent!)"
  echo "   - Incorrect hex value: Color(0xFFXXXXXX) ← WRONG color"
  exit 1
fi

# Check 3: Find hardcoded colors in widget/screen files
echo "✓ Scanning for hardcoded colors..."
SEARCH_PATHS=("lib/features" "lib/screens" "lib/widgets")
HARDCODED=""

for path in "${SEARCH_PATHS[@]}"; do
  if [ -d "$path" ]; then
    FOUND=$(grep -r "Color(0x" "$path" 2>/dev/null | grep -v "theme.dart" || true)
    if [ -n "$FOUND" ]; then
      HARDCODED="${HARDCODED}${FOUND}\n"
    fi
  fi
done

if [ -n "$HARDCODED" ]; then
  echo "❌ ERROR: Hardcoded colors found (use AppTheme instead):"
  echo -e "$HARDCODED"
  echo ""
  echo "   Refactor to use Theme.of(context).colorScheme or AppTheme constants."
  exit 1
fi

# Check 4: Verify AppTheme class exports
echo "✓ Verifying theme exports..."
if ! grep -q "class AppTheme" "$THEME_FILE"; then
  echo "❌ ERROR: AppTheme class not found in $THEME_FILE"
  exit 1
fi

# Check 5: Verify dark theme exists
echo "✓ Checking dark theme definition..."
if ! grep -q "darkTheme" "$THEME_FILE"; then
  echo "⚠️  WARNING: Dark theme not found in $THEME_FILE"
  echo "   Constitution VI requires dark theme support for 42 brand identity."
fi

echo "✅ Design compliance verification PASSED"
echo ""
echo "   Primary color: $EXPECTED_PRIMARY ✓"
echo "   No hardcoded colors ✓"
echo "   Theme structure valid ✓"
exit 0
