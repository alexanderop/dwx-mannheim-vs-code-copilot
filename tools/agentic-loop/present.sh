#!/usr/bin/env bash
# Scripted re-creation of a nanocode agent-loop run, for the VHS recording.
# Driven by agentic-loop.tape; not meant to be run interactively (paced sleeps).
# Purely cosmetic: mirrors the static transcript on the "Agentic Loop" slide,
# animated so the request → tool-call → feed-results-back → loop is visible.
set -u

teal=$'\e[38;5;80m'
gray=$'\e[38;5;245m'
green=$'\e[38;5;78m'
white=$'\e[1;97m'
pink=$'\e[38;5;212m'
bold=$'\e[1m'
dim=$'\e[2m'
rst=$'\e[0m'

emit() { printf '%b\n' "$1"; sleep "${2:-0.18}"; }
rule() { printf '%b' "$dim"; printf '─%.0s' $(seq 1 78); printf '%b\n' "$rst"; }
type_prompt() {
  local text="$1" i
  printf '%b❯%b  ' "$white" "$rst"; printf '%b' "$bold"
  for ((i = 0; i < ${#text}; i++)); do printf '%s' "${text:i:1}"; sleep 0.024; done
  printf '%b\n' "$rst"
}

clear
emit "${gray}nanocode${rst} ${dim}|${rst} ${teal}claude-opus-4-5${rst} ${dim}|${rst} ${gray}~/Projects/typescript/nanocode${rst}" 0.4
echo
rule
type_prompt "create a simple typescript file as a sum function"
rule
sleep 0.5

emit "${dim}[agentLoop] Starting with 1 messages${rst}" 0.5
emit "${dim}[agentLoop] Got response, stop_reason: tool_use${rst}" 0.7
echo
emit "${pink}⏺${rst} ${bold}Write${rst}(${teal}src/sum.ts${rst})" 0.4
emit "  ${gray}⎿${rst}  ${green}ok${rst}" 0.7
echo
emit "${dim}[agentLoop] Starting with 3 messages${rst}   ${pink}🔁 tool results fed back → loop${rst}" 0.7
emit "${dim}[agentLoop] Got response, stop_reason: end_turn${rst}" 0.8
echo
emit "${pink}⏺${rst} Created ${teal}src/sum.ts${rst} with a simple sum function that takes two numbers and returns their sum." 0.6
sleep 1.8
