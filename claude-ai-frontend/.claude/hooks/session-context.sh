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

# Node.js project info
if [ -f "$PROJECT_DIR/package.json" ]; then
  VERSION=$(jq -r '.version // "unknown"' "$PROJECT_DIR/package.json" 2>/dev/null)
  echo "**Project version:** $VERSION"

  if [ -d "$PROJECT_DIR/node_modules" ]; then
    echo "**Dependencies:** installed"
  else
    echo "**Dependencies:** NOT installed — run \`npm install\`"
  fi
  echo ""
fi

# Node.js version
if command -v node &> /dev/null; then
  echo "**Node.js:** $(node --version 2>/dev/null)"
fi

# Persist NODE_ENV for the session
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV="${NODE_ENV:-development}"' >> "$CLAUDE_ENV_FILE"
fi

echo ""

# Check for common issues
if [ -f "$PROJECT_DIR/.env" ] && ! [ -f "$PROJECT_DIR/.env.example" ]; then
  echo "**Warning:** .env exists but no .env.example template"
fi

if [ -f "$PROJECT_DIR/next.config.ts" ]; then
  if grep -q "middleware" "$PROJECT_DIR/src/middleware.ts" 2>/dev/null; then
    echo "**Warning:** middleware.ts detected — Next.js 16 uses proxy.ts instead"
  fi
fi

exit 0
