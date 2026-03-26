#!/bin/bash
# Verify work before Claude stops — ensures Dart analysis passes
# Exit 2 to block stopping if critical checks fail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Only run if pubspec.yaml exists (project is scaffolded)
if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
  exit 0
fi

# Check for Dart analysis errors (not warnings)
if command -v dart &> /dev/null; then
  ERRORS=$(dart analyze "$PROJECT_DIR/lib" 2>/dev/null | grep -c " error " || true)
  if [ "$ERRORS" -gt 0 ]; then
    echo "Dart analysis found $ERRORS error(s). Fix before stopping." >&2
    exit 2
  fi
fi

exit 0
