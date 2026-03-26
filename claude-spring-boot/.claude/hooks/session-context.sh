#!/bin/bash
# Inject project context at session start
# Output becomes additionalContext for Claude

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

# Gradle project info
if [ -f "$PROJECT_DIR/build.gradle.kts" ] || [ -f "$PROJECT_DIR/build.gradle" ]; then
  echo "**Build tool:** Gradle"
  if [ -f "$PROJECT_DIR/gradlew" ]; then
    GRADLE_VERSION=$("$PROJECT_DIR/gradlew" --version 2>/dev/null | grep "^Gradle" | head -1 || echo "unknown")
    echo "**$GRADLE_VERSION**"
  fi
  echo ""
# Maven project info
elif [ -f "$PROJECT_DIR/pom.xml" ]; then
  echo "**Build tool:** Maven"
  if [ -f "$PROJECT_DIR/mvnw" ]; then
    echo "**Maven wrapper:** available"
  fi
  echo ""
fi

# Java version
if command -v java &> /dev/null; then
  JAVA_VERSION=$(java -version 2>&1 | head -1)
  echo "**Java:** $JAVA_VERSION"
  echo ""
fi

# Spring Boot version detection
if [ -f "$PROJECT_DIR/build.gradle.kts" ]; then
  BOOT_VERSION=$(grep -oP "id\(\"org.springframework.boot\"\) version \"\K[^\"]*" "$PROJECT_DIR/build.gradle.kts" 2>/dev/null)
  if [ -n "$BOOT_VERSION" ]; then
    echo "**Spring Boot:** $BOOT_VERSION"
  fi
elif [ -f "$PROJECT_DIR/pom.xml" ]; then
  BOOT_VERSION=$(grep -oP '<spring-boot.version>\K[^<]*' "$PROJECT_DIR/pom.xml" 2>/dev/null || grep -A1 'spring-boot-starter-parent' "$PROJECT_DIR/pom.xml" 2>/dev/null | grep -oP '<version>\K[^<]*')
  if [ -n "$BOOT_VERSION" ]; then
    echo "**Spring Boot:** $BOOT_VERSION"
  fi
fi

# Docker status
if command -v docker &> /dev/null; then
  if docker info &> /dev/null; then
    RUNNING=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    echo "**Docker:** running ($RUNNING containers active)"
  else
    echo "**Docker:** installed but not running"
  fi
fi

echo ""

# Persist SPRING_PROFILES_ACTIVE for the session
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-dev}"' >> "$CLAUDE_ENV_FILE"
fi

# Check for common issues
if [ -f "$PROJECT_DIR/.env" ] && ! [ -f "$PROJECT_DIR/.env.example" ]; then
  echo "**Warning:** .env exists but no .env.example template"
fi

if [ -f "$PROJECT_DIR/src/main/resources/application.yml" ]; then
  if grep -q "ddl-auto: create\|ddl-auto: update" "$PROJECT_DIR/src/main/resources/application.yml" 2>/dev/null; then
    echo "**Warning:** ddl-auto is set to create/update — use 'validate' with Flyway for production"
  fi
  if grep -q "open-in-view: true" "$PROJECT_DIR/src/main/resources/application.yml" 2>/dev/null; then
    echo "**Warning:** open-in-view is true — set to false for performance"
  fi
fi

exit 0
