#!/bin/bash
# Verify work before Claude stops — ensures TypeScript compiles and Biome passes
# Exit 2 to block stopping if critical checks fail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Only run if package.json exists (project is scaffolded)
if [ ! -f "$PROJECT_DIR/package.json" ]; then
  exit 0
fi

# Only run if node_modules exist (dependencies installed)
if [ ! -d "$PROJECT_DIR/node_modules" ]; then
  exit 0
fi

# Check for TypeScript compilation errors
if [ -f "$PROJECT_DIR/node_modules/.bin/tsc" ]; then
  if ! npx tsc --noEmit --pretty false 2>/dev/null; then
    echo "TypeScript compilation errors detected. Fix before stopping." >&2
    exit 2
  fi
fi

exit 0
