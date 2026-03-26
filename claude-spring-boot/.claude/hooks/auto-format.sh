#!/bin/bash
# Auto-verify Java files after Write/Edit using Spotless
# Runs silently — exit 0 on success, exit 2 to block on critical errors

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Only check Java, Kotlin, YAML, and properties files
case "$FILE_PATH" in
  *.java|*.kt|*.yml|*.yaml|*.properties)
    # Try Spotless via Gradle wrapper
    if [ -f "$PROJECT_DIR/gradlew" ] && [ -x "$PROJECT_DIR/gradlew" ]; then
      "$PROJECT_DIR/gradlew" spotlessApply -q 2>/dev/null
    # Try Spotless via Maven wrapper
    elif [ -f "$PROJECT_DIR/mvnw" ] && [ -x "$PROJECT_DIR/mvnw" ]; then
      "$PROJECT_DIR/mvnw" spotless:apply -q 2>/dev/null
    fi
    ;;
esac

exit 0
