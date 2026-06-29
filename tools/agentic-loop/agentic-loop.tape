# VHS tape: animated nanocode agent-loop run.
# Regenerate from the repo root:  vhs tools/agentic-loop/agentic-loop.tape
# Requires: vhs, ttyd, ffmpeg.
Output "starter/public/videos/agentic-loop.mp4"
Output "starter/public/videos/agentic-loop.webm"

Set Shell "bash"
Set FontSize 20
Set Width 1400
Set Height 600
Set Padding 28
Set Theme "Catppuccin Mocha"

Hide
Type "bash tools/agentic-loop/present.sh"
Enter
Sleep 600ms
Show
Sleep 11s
