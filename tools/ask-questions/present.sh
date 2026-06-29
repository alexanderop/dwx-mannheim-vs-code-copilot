#!/usr/bin/env bash
# Scripted re-creation of the #askQuestions picker, for the VHS recording.
# Driven by ask-questions.tape; not meant to be run interactively (paced sleeps).
# Purely cosmetic: renders the option box, moves the selection, lands on
# "Web App", and confirms — mirrors the static box on the slide.
set -u

teal=$'\e[38;5;80m'
gray=$'\e[38;5;245m'
green=$'\e[38;5;78m'
white=$'\e[1;97m'
bold=$'\e[1m'
dim=$'\e[2m'
inv=$'\e[7m'
rst=$'\e[0m'

W=60   # inner width of the box

emit() { printf '%b\n' "$1"; sleep "${2:-0.18}"; }
type_prompt() {
  local text="$1" i
  printf '%b❯%b  ' "$white" "$rst"; printf '%b' "$bold"
  for ((i = 0; i < ${#text}; i++)); do printf '%s' "${text:i:1}"; sleep 0.02; done
  printf '%b\n' "$rst"
}

hr() { printf '─%.0s' $(seq 1 "$W"); }

# Option rows: "Name|Description"
opts=(
  "Web App|Browser-based PWA, accessible anywhere"
  "iOS Native|Swift/SwiftUI for iPhone"
  "Android Native|Kotlin for Android devices"
  "Cross-Platform|React Native or Flutter for iOS & Android"
  "Desktop|Electron app for Mac/Windows"
)

# Print one padded option row. $1 index, $2 selected-index.
# Selection is shown by a ★ marker + teal/bold highlight (no checkmark glyph,
# which renders double-width and would break the right border alignment).
opt_row() {
  local idx="$1" sel="$2" name="${opts[$1]%%|*}" desc="${opts[$1]#*|}"
  local plain
  if [[ "$idx" == "$sel" ]]; then
    plain=$(printf ' ★ %s  %s' "$name" "$desc")
    printf '%b│%b%b%-*s%b%b│%b\e[K\n' "$gray" "$rst" "$teal$bold" "$W" "$plain" "$rst" "$gray" "$rst"
  else
    plain=$(printf '   %s  %s' "$name" "$desc")
    printf '%b│%b%-*s%b│%b\e[K\n' "$gray" "$rst" "$W" "$plain" "$gray" "$rst"
  fi
}

# Draw the whole box with option $1 selected.
draw_box() {
  local sel="$1" i
  printf '%b┌%s┐%b\e[K\n' "$gray" "$(hr)" "$rst"
  printf '%b│%b%b%*s%*s%b%b│%b\e[K\n' "$gray" "$rst" "$bold" "$(((W + 14) / 2))" "Platform (1/4)" "$(((W - 14) / 2))" "" "$rst" "$gray" "$rst"
  printf '%b├%s┤%b\e[K\n' "$gray" "$(hr)" "$rst"
  printf '%b│%b %-*s%b│%b\e[K\n' "$gray" "$rst" "$((W - 1))" "What platform should the workout tracking app target?" "$gray" "$rst"
  printf '%b├%s┤%b\e[K\n' "$gray" "$(hr)" "$rst"
  for i in "${!opts[@]}"; do opt_row "$i" "$sel"; done
  printf '%b└%s┘%b\e[K\n' "$gray" "$(hr)" "$rst"
}

# Number of lines draw_box prints (for cursor-up redraws): 6 chrome + N options.
BOX_LINES=$((6 + ${#opts[@]}))

clear
type_prompt "help me create a workout tracking app — use #askQuestions for the tech specs"
echo
sleep 0.4

draw_box 4          # selection starts at the bottom option
sleep 0.7
printf '\e[%dA' "$BOX_LINES"; draw_box 2   # arrow up
sleep 0.4
printf '\e[%dA' "$BOX_LINES"; draw_box 1   # arrow up
sleep 0.4
printf '\e[%dA' "$BOX_LINES"; draw_box 0   # land on Web App
sleep 1.0
echo
emit "${green}●${rst} ${bold}Platform:${rst} Web App ${dim}— scaffolding a browser-based PWA…${rst}" 0.5
sleep 1.6
