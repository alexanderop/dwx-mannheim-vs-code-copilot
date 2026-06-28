#!/usr/bin/env bash
# PreToolUse guard: keep secret files out of the agent's context.
#
# Secrets the agent never reads can't leak into the LLM context, the cloud,
# transcripts, or chat. We inspect EVERY string in the tool call — the file path
# (Read/Edit) and the raw command (terminal: `cat .env`, `printenv`, ...) —
# because the secret can sneak in through either.
#
# Schema-agnostic on purpose, so ONE hook works in both:
#   * VS Code Copilot  -> stdin has tool_input{}, wants hookSpecificOutput.*
#   * GitHub Copilot CLI -> stdin has toolArgs (unknown), wants top-level fields
# We flatten all string leaves with jq and emit BOTH deny shapes; each host
# reads the field it understands and ignores the rest.

INPUT=$(cat)

# Flatten every string value anywhere in the payload (tool_input.*, toolArgs.*,
# toolArgs-as-string, command, file_path, ...). Fall back to the raw JSON if jq
# is unavailable, so the guard fails safe rather than silently allowing.
TARGET=$(printf '%s' "$INPUT" | jq -r '[.. | strings] | join(" ")' 2>/dev/null) \
  || TARGET=$INPUT
[ -z "$TARGET" ] && TARGET=$INPUT

if printf '%s' "$TARGET" | grep -qiE \
  '(^|[/[:space:]"'\''=])\.env($|[./[:space:]"'\''])|\.(pem|key|p12|pfx)($|[[:space:]"'\''])|id_rsa|credentials|\.aws/|secrets/'; then
  REASON="Blocked: secret file (.env / key / credentials). Reference the env var name, not its value."
  # Top-level keys -> Copilot CLI.  hookSpecificOutput -> VS Code Copilot.
  cat <<JSON
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "$REASON",
  "hookSpecificOutput": {
    "permissionDecision": "deny",
    "permissionDecisionReason": "$REASON"
  }
}
JSON
  exit 0
fi

# Not a secret — stay neutral so the host's normal permission flow continues.
echo '{"continue":true}'
exit 0
