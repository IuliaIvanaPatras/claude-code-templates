#!/bin/bash
# Auto-analyze Dart files after Write/Edit
# Runs silently — only reports errors to Claude via exit code 2

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Only analyze Dart and YAML files
case "$FILE_PATH" in
  *.dart)
    if command -v dart &> /dev/null && [ -f "$PROJECT_DIR/pubspec.yaml" ]; then
      # Format the file first
      dart format "$FILE_PATH" 2>/dev/null
      # Then run analysis on the single file
      dart analyze "$FILE_PATH" 2>/dev/null
    fi
    ;;
  pubspec.yaml)
    if command -v flutter &> /dev/null; then
      flutter pub get --no-example 2>/dev/null
    fi
    ;;
esac

exit 0
