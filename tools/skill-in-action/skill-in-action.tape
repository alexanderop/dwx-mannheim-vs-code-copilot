# VHS tape: the Plausible SEO skill running end-to-end.
# Regenerate from the repo root:  vhs tools/skill-in-action/skill-in-action.tape
# Requires: vhs, ttyd, ffmpeg.
Output "starter/public/videos/skill-in-action.mp4"
Output "starter/public/videos/skill-in-action.webm"

Set Shell "bash"
Set FontSize 20
Set Width 1400
Set Height 700
Set Padding 28
Set Theme "Catppuccin Mocha"

Hide
Type "bash tools/skill-in-action/present.sh"
Enter
Sleep 600ms
Show
Sleep 13500ms
