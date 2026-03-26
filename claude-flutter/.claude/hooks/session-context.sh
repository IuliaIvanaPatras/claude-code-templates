#!/bin/bash
# Inject project context at session start

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

echo "## Project Context"
echo ""

# Git info
if command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null; then
  echo "**Branch:** $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  echo "**Uncommitted changes:** $(git status --short 2>/dev/null | wc -l | tr -d ' ') files"
  LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo 'none')
  echo "**Last commit:** $LAST_COMMIT"
  echo ""
fi

# Flutter SDK info
if command -v flutter &> /dev/null; then
  FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1 || echo "unknown")
  echo "**$FLUTTER_VERSION**"
  echo ""
fi

# Dart SDK info
if command -v dart &> /dev/null; then
  DART_VERSION=$(dart --version 2>&1 | head -1 || echo "unknown")
  echo "**$DART_VERSION**"
  echo ""
fi

# Project info from pubspec.yaml
if [ -f "$PROJECT_DIR/pubspec.yaml" ]; then
  NAME=$(grep "^name:" "$PROJECT_DIR/pubspec.yaml" 2>/dev/null | awk '{print $2}')
  VERSION=$(grep "^version:" "$PROJECT_DIR/pubspec.yaml" 2>/dev/null | awk '{print $2}')
  if [ -n "$NAME" ]; then
    echo "**Project:** $NAME v$VERSION"
  fi

  if [ -d "$PROJECT_DIR/.dart_tool" ]; then
    echo "**Dependencies:** resolved"
  else
    echo "**Dependencies:** NOT resolved — run \`flutter pub get\`"
  fi
  echo ""
fi

# Connected devices
if command -v flutter &> /dev/null; then
  DEVICE_COUNT=$(flutter devices --machine 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")
  echo "**Connected devices:** $DEVICE_COUNT"
fi

# Persist FLUTTER_ENV for the session
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export FLUTTER_ENV="${FLUTTER_ENV:-development}"' >> "$CLAUDE_ENV_FILE"
fi

echo ""

# Check for common issues
if [ -f "$PROJECT_DIR/.env" ] && ! [ -f "$PROJECT_DIR/.env.example" ]; then
  echo "**Warning:** .env exists but no .env.example template"
fi

if [ -f "$PROJECT_DIR/pubspec.yaml" ]; then
  if grep -q "sdk: any" "$PROJECT_DIR/pubspec.yaml" 2>/dev/null; then
    echo "**Warning:** SDK constraint is 'any' — pin to a specific range"
  fi
fi

if [ -f "$PROJECT_DIR/analysis_options.yaml" ]; then
  if ! grep -q "very_good_analysis\|flutter_lints" "$PROJECT_DIR/analysis_options.yaml" 2>/dev/null; then
    echo "**Warning:** No lint package detected — consider using very_good_analysis"
  fi
fi

exit 0
