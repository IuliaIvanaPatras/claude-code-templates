#!/bin/bash
# Auto-lint files after Write/Edit using Biome
# Runs silently — only reports errors to Claude via exit code 2

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Only lint TypeScript/JavaScript/JSON/CSS files
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css)
    if command -v npx &> /dev/null && [ -f "$PROJECT_DIR/node_modules/.package-lock.json" ]; then
      npx biome check --fix "$FILE_PATH" 2>/dev/null
    fi
    ;;
esac

exit 0
