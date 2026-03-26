#!/bin/bash
# Block dangerous Bash commands before execution

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block destructive operations
if echo "$COMMAND" | grep -qE 'rm -rf /|rm -rf \.|rm -rf \*|:(){.*}|fork\(\)|>/dev/sd|mkfs\.|dd if='; then
  echo "Blocked: Destructive system command detected." >&2
  exit 2
fi

# Block force-pushing to protected branches
if echo "$COMMAND" | grep -qE 'git push.*(--force|-f).*(main|master|production)'; then
  echo "Blocked: Force-push to protected branch." >&2
  exit 2
fi

# Block direct production env access
if echo "$COMMAND" | grep -qE 'NODE_ENV=production.*rm|DROP TABLE|TRUNCATE'; then
  echo "Blocked: Dangerous production operation." >&2
  exit 2
fi

exit 0
