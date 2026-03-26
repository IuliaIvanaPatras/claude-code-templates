#!/bin/bash
# Verify work before Claude stops — ensures build/tests pass
# Exit 2 to block stopping if critical checks fail

# Only run if Gradle wrapper exists (project is scaffolded)
if [ ! -f "gradlew" ] && [ ! -f "mvnw" ]; then
  exit 0
fi

# Check for uncommitted Java compilation errors
if [ -f "gradlew" ]; then
  if ! ./gradlew compileJava -q 2>/dev/null; then
    echo "Compilation errors detected. Fix before stopping." >&2
    exit 2
  fi
elif [ -f "mvnw" ]; then
  if ! ./mvnw compile -q 2>/dev/null; then
    echo "Compilation errors detected. Fix before stopping." >&2
    exit 2
  fi
fi

exit 0
