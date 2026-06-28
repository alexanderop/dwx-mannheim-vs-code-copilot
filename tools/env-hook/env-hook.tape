# VHS tape for the .env PreToolUse guard demo.
# Regenerate from the repo root:  vhs tools/env-hook/env-hook.tape
# Requires: vhs, ttyd, ffmpeg, jq.
Output "starter/public/videos/env-hook-guard.mp4"
Output "starter/public/videos/env-hook-guard.webm"

Set Shell "bash"
Set FontSize 22
Set Width 1280
Set Height 760
Set Padding 28
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms

# Launch the scripted walkthrough off-screen so only its output is recorded.
Hide
Type "bash tools/env-hook/present.sh"
Enter
Sleep 900ms
Show
Sleep 18s
