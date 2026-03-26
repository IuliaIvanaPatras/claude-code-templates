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

# Block publishing to pub.dev without confirmation
if echo "$COMMAND" | grep -qE 'dart pub publish|flutter pub publish'; then
  echo "Blocked: Publishing to pub.dev requires explicit user confirmation." >&2
  exit 2
fi

# Block keystore/signing operations
if echo "$COMMAND" | grep -qE 'keytool.*-genkey|keytool.*-delete|keytool.*-importkeystore'; then
  echo "Blocked: Keystore operations require explicit user confirmation." >&2
  exit 2
fi

exit 0
