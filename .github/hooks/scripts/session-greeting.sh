#!/usr/bin/env bash
# SessionStart hook: greet the user with the current time and the weather
# in Geretsried, injected into the agent's context on every new session.
#
# Why a hook? The model has no clock and no thermometer. Running on every
# SessionStart means the agent always opens knowing the real local time and
# how hot it is outside — deterministically, with zero prompting.
#
# Schema-agnostic on purpose, so ONE hook works in both:
#   * VS Code Copilot  -> reads hookSpecificOutput.additionalContext
#   * GitHub Copilot CLI -> reads top-level additionalContext / context
# We emit BOTH shapes; each host reads the field it understands.

CITY="Geretsried"
TIME=$(date '+%H:%M on %A, %B %-d, %Y')

# wttr.in needs no API key. --max-time keeps the session start snappy and the
# fallback keeps the demo alive if the venue WiFi is offline.
WEATHER=$(curl -s --max-time 6 "https://wttr.in/${CITY}?format=%C+%t" 2>/dev/null)
if [ -z "$WEATHER" ]; then
  WEATHER="weather unavailable (offline)"
fi

CONTEXT="Good day! It is ${TIME}. In ${CITY} right now: ${WEATHER}."

cat <<JSON
{
  "additionalContext": "$CONTEXT",
  "context": "$CONTEXT",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$CONTEXT"
  }
}
JSON
exit 0
