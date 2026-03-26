#!/bin/bash
# Block dangerous Bash commands before execution
# Exit 2 to block, exit 0 to allow

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block destructive system operations
if echo "$COMMAND" | grep -qE 'rm -rf /|rm -rf \.|rm -rf \*|:(){.*}|fork\(\)|>/dev/sd|mkfs\.|dd if='; then
  echo "Blocked: Destructive system command detected." >&2
  exit 2
fi

# Block force-pushing to protected branches
if echo "$COMMAND" | grep -qE 'git push.*(--force|-f).*(main|master|production)'; then
  echo "Blocked: Force-push to protected branch." >&2
  exit 2
fi

# Block dangerous database operations
if echo "$COMMAND" | grep -qE 'DROP (TABLE|DATABASE|SCHEMA)|TRUNCATE|DELETE FROM.*WHERE 1|DELETE FROM [a-z]+ *;'; then
  echo "Blocked: Dangerous database operation." >&2
  exit 2
fi

# Block production environment access
if echo "$COMMAND" | grep -qE 'SPRING_PROFILES_ACTIVE=prod.*rm|flyway.*clean.*prod'; then
  echo "Blocked: Dangerous production operation." >&2
  exit 2
fi

# Block Flyway clean (destructive migration reset)
if echo "$COMMAND" | grep -qE 'flyway.*clean|flywayClean'; then
  echo "Blocked: Flyway clean drops all objects. Use flyway repair instead." >&2
  exit 2
fi

exit 0
