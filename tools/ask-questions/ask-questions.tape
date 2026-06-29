# VHS tape: the #askQuestions option picker landing on "Web App".
# Regenerate from the repo root:  vhs tools/ask-questions/ask-questions.tape
# Requires: vhs, ttyd, ffmpeg.
Output "starter/public/videos/ask-questions.mp4"
Output "starter/public/videos/ask-questions.webm"

Set Shell "bash"
Set FontSize 20
Set Width 1400
Set Height 620
Set Padding 28
Set Theme "Catppuccin Mocha"

Hide
Type "bash tools/ask-questions/present.sh"
Enter
Sleep 600ms
Show
Sleep 9s
