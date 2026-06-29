# VHS tape recreating the GitHub Copilot CLI session for the slides.
# Regenerate from the repo root:  vhs tools/copilot-cli/copilot-cli.tape
# Requires: vhs, ttyd, ffmpeg.
Output "starter/public/videos/copilot-cli-tools.mp4"
Output "starter/public/videos/copilot-cli-tools.webm"

Set Shell "bash"
Set FontSize 20
Set Width 1400
Set Height 860
Set Padding 28
Set Theme "Catppuccin Mocha"

# Run the scripted transcript off-screen so only its output is recorded.
Hide
Type "bash tools/copilot-cli/present.sh"
Enter
Sleep 600ms
Show
Sleep 12s
