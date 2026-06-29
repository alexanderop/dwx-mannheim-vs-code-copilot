#!/usr/bin/env bash
# Scripted re-creation of the #runSubagent fan-out, for the VHS recording.
# Driven by subagent-fanout.tape; not meant to be run interactively (paced sleeps).
# Purely cosmetic: mirrors the Copilot CLI spinning up 3 parallel web-search
# agents that resolve into one merged answer.
set -u

blue=$'\e[38;5;75m'
teal=$'\e[38;5;80m'
gray=$'\e[38;5;245m'
green=$'\e[38;5;78m'
white=$'\e[1;97m'
bold=$'\e[1m'
dim=$'\e[2m'
rst=$'\e[0m'

emit() { printf '%b\n' "$1"; sleep "${2:-0.18}"; }
type_prompt() {
  local text="$1" i
  printf '%b❯%b  ' "$white" "$rst"; printf '%b' "$bold"
  for ((i = 0; i < ${#text}; i++)); do printf '%s' "${text:i:1}"; sleep 0.018; done
  printf '%b\n' "$rst"
}

# Animate three spinner rows in place, then resolve them to checkmarks.
spin3() {
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧') i f
  printf '  %b├%b %s  agent 1  searching the web…\n' "$blue" "$rst" "${frames[0]}"
  printf '  %b├%b %s  agent 2  searching the web…\n' "$blue" "$rst" "${frames[0]}"
  printf '  %b└%b %s  agent 3  searching the web…\n' "$blue" "$rst" "${frames[0]}"
  for ((i = 1; i < 16; i++)); do
    f="${frames[i % ${#frames[@]}]}"
    printf '\e[3A'
    printf '\r  %b├%b %b%s%b  agent 1  searching the web…\e[K\n' "$blue" "$rst" "$teal" "$f" "$rst"
    printf '\r  %b├%b %b%s%b  agent 2  searching the web…\e[K\n' "$blue" "$rst" "$teal" "$f" "$rst"
    printf '\r  %b└%b %b%s%b  agent 3  searching the web…\e[K\n' "$blue" "$rst" "$teal" "$f" "$rst"
    sleep 0.11
  done
}

clear
type_prompt "#runSubagent run 3 subagents that search the web and tell me something interesting about Geretsried"
echo
emit "${blue}●${rst} ${bold}Spinning up 3 subagents…${rst}" 0.4

spin3

# Resolve the three rows to their findings.
printf '\e[3A'
printf '\r  %b├ %b✓%b %bagent 1%b  lies on the river Isar, south of Munich in Upper Bavaria\e[K\n' "$blue" "$green" "$rst" "$bold" "$rst"
sleep 0.35
printf '\r  %b├ %b✓%b %bagent 2%b  the youngest town in Bavaria — founded in 1950\e[K\n' "$blue" "$green" "$rst" "$bold" "$rst"
sleep 0.35
printf '\r  %b└ %b✓%b %bagent 3%b  built on a former WWII munitions site in the forest\e[K\n' "$blue" "$green" "$rst" "$bold" "$rst"
sleep 0.7
echo

emit "${blue}●${rst} ${bold}Merged 3 findings${rst}" 0.5
emit "  - Bad Tölz–Wolfratshausen district, Upper Bavaria · ~25,000 residents" 0.3
emit "  - Bavaria's youngest town — incorporated 1950" 0.3
emit "  - Grew from a post-war displaced-persons settlement on an old munitions plant" 0.3
sleep 1.8
