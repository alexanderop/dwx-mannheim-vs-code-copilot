# VHS tape: #runSubagent fan-out of 3 parallel web-search agents.
# Regenerate from the repo root:  vhs tools/subagent-fanout/subagent-fanout.tape
# Requires: vhs, ttyd, ffmpeg.
Output "starter/public/videos/subagent-fanout.mp4"
Output "starter/public/videos/subagent-fanout.webm"

Set Shell "bash"
Set FontSize 20
Set Width 1560
Set Height 560
Set Padding 28
Set Theme "Catppuccin Mocha"

Hide
Type "bash tools/subagent-fanout/present.sh"
Enter
Sleep 600ms
Show
Sleep 11s
