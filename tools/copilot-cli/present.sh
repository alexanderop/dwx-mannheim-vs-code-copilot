#!/usr/bin/env bash
# Scripted re-creation of the GitHub Copilot CLI session, for the VHS recording.
# Driven by copilot-cli.tape; not meant to be run interactively (it has paced sleeps).
# Purely cosmetic: it prints a styled transcript that mirrors `copilot` v1.0.65 —
# the welcome banner, a typed prompt, and the streamed answer.
set -u

# ── palette (approximates the Copilot CLI theme) ────────────────────────────
blue=$'\e[38;5;75m'    # info bullets / links
green=$'\e[38;5;78m'   # "thinking" bullet
yellow=$'\e[38;5;221m' # warnings
teal=$'\e[38;5;80m'    # command tokens & hyperlinks
gray=$'\e[38;5;245m'   # secondary / tree connectors
white=$'\e[1;97m'      # prompt chevron / emphasis
bold=$'\e[1m'
dim=$'\e[2m'
selbg=$'\e[44m'        # selected tab background (blue)
logoblue=$'\e[38;5;39m'  # rounded antenna boxes
purple=$'\e[38;5;99m'    # visor body
eyes=$'\e[38;5;84m'      # green eyes
rst=$'\e[0m'

line() { printf '%b\n' "$1"; }

# Stream a line out word-friendly: print whole, then small pause (feels like render).
emit() { printf '%b\n' "$1"; sleep "${2:-0.18}"; }

# Type text after a chevron, character by character, like real input.
type_prompt() {
  local text="$1" i
  printf '%b❯%b ' "$white" "$rst"
  printf '%b' "$bold"
  for ((i = 0; i < ${#text}; i++)); do
    printf '%s' "${text:i:1}"
    sleep 0.028
  done
  printf '%b\n' "$rst"
}

clear

# ── header / tab bar ────────────────────────────────────────────────────────
printf '%b Session %b  %bIssues%b  %bPull requests%b  %bGists%b\n' \
  "$selbg$white" "$rst" "$gray" "$rst" "$gray" "$rst" "$gray" "$rst"
echo

# ── Copilot mascot + version banner ─────────────────────────────────────────
# Two rounded blue boxes (antennae) above a purple open-top visor with green eyes.
line "  ${logoblue}╭───╮  ╭───╮${rst}"
line "  ${logoblue}│   │  │   │${rst}"
line "  ${logoblue}╰───╯  ╰───╯${rst}    ${bold}Copilot v1.0.65 uses AI.${rst}"
line "  ${purple}██${eyes} ▐▌  ▐▌ ${purple}██${rst}    ${gray}Check for mistakes.${rst}"
line "  ${purple}██        ██${rst}"
line "  ${purple}████████████${rst}"
echo
sleep 0.9

# ── startup notice ──────────────────────────────────────────────────────────
emit "${blue}●${rst} Your terminal already has multiline support with ${bold}shift+enter${rst}."
echo
sleep 1.1

# ── the user types a prompt ─────────────────────────────────────────────────
type_prompt "which tools are available from your system context — answer with a short bullet list"
echo
sleep 0.9

# ── the agent "thinks", then streams the answer ─────────────────────────────
emit "${green}●${rst} ${bold}Checking my documentation${rst}" 0.5
emit "  ${gray}└${rst} ${gray}# GitHub Copilot CLI Documentation${rst}" 0.8
echo

label() { printf '%b●%b   - %b%s:%b %s\n' "$blue" "$rst" "$bold" "$1" "$rst" "$2"; }
item()  { printf '    - %b%s:%b %s\n' "$bold" "$1" "$rst" "$2"; }

label "Shell/CLI"        "${teal}git${rst}, ${teal}curl${rst}, ${teal}gh${rst}"; sleep 0.22
item  "File/code inspection" "${teal}view${rst}, ${teal}glob${rst}, ${teal}rg${rst}"; sleep 0.22
item  "Editing"          "${teal}apply_patch${rst}"; sleep 0.22
item  "Execution"        "${teal}bash${rst}"; sleep 0.22
item  "Project context"  "IDE diagnostics/selection, SQL session store, memory tools"; sleep 0.22
item  "Web/GitHub"       "web fetch, GitHub MCP search/file/space tools"; sleep 0.22
item  "Agents/skills"    "task agents, background agents, skills, user prompts"; sleep 0.9
echo

# ── status line + input box + footer ────────────────────────────────────────
line "${gray}~/Projects/slidev/dwx-mannheim-vs-code-copilot [⎇ main*%]          Session: 6.85 AIC used${rst}"
echo
# Input box, generated so borders line up regardless of terminal width.
boxw=72
bar=$(printf '─%.0s' $(seq 1 "$boxw"))
pad=$(printf ' %.0s' $(seq 1 "$((boxw - 2))"))
line "${gray}╭${bar}╮${rst}"
line "${gray}│${rst} ${white}❚${rst}${pad}${gray}│${rst}"
line "${gray}╰${bar}╯${rst}"
line "${gray}/${rst} commands · ${gray}?${rst} help · ${bold}tab${rst} next tab                                ${gray}GPT-5.4${rst}"
sleep 2.2
