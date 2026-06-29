#!/usr/bin/env bash
# Scripted re-creation of the Plausible SEO skill running, for the VHS recording.
# Driven by skill-in-action.tape; not meant to be run interactively (paced sleeps).
# Purely cosmetic: mirrors the "Skill in Action" slide — description match →
# skill.md loads → script runs → reference doc → WebFetch → findings.
set -u

blue=$'\e[38;5;75m'
teal=$'\e[38;5;80m'
gray=$'\e[38;5;245m'
green=$'\e[38;5;78m'
white=$'\e[1;97m'
bold=$'\e[1m'
dim=$'\e[2m'
selbg=$'\e[44m'          # selected tab background (blue)
logoblue=$'\e[38;5;39m'  # rounded antenna boxes
purple=$'\e[38;5;99m'    # visor body
eyes=$'\e[38;5;84m'      # green eyes
rst=$'\e[0m'

line() { printf '%b\n' "$1"; }
emit() { printf '%b\n' "$1"; sleep "${2:-0.2}"; }
type_prompt() {
  local text="$1" i
  printf '%b❯%b  ' "$white" "$rst"; printf '%b' "$bold"
  for ((i = 0; i < ${#text}; i++)); do printf '%s' "${text:i:1}"; sleep 0.024; done
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

type_prompt "Why is my bounce rate so high on the Vue posts?"
echo
sleep 0.5

emit "${green}●${rst} ${bold}plausible-insights${rst} ${dim}— description matched${rst}" 0.4
emit "  ${gray}└${rst} loading ${teal}skill.md${rst} ${dim}(~500 tokens)${rst}" 0.7
echo

emit "${blue}●${rst} Running ${teal}bun cli top-pages --range 7d --pattern \"/vue/\"${rst}" 0.5
emit "  ${gray}⎿${rst}  /vue/reactivity-deep-dive   ${bold}bounce 82%${rst}   visits 1,204" 0.25
emit "      /vue/composables-guide     ${bold}bounce 78%${rst}   visits   942" 0.25
emit "      /vue/watchers-explained     ${bold}bounce 75%${rst}   visits   610" 0.6
echo

emit "${blue}●${rst} Reading ${teal}references/seo/thresholds.md${rst} ${dim}— interpretation guide${rst}" 0.6
emit "${blue}●${rst} ${bold}WebFetch${rst} ${teal}/vue/reactivity-deep-dive${rst} ${dim}— inspecting real content${rst}" 0.8
echo

emit "${green}●${rst} ${bold}Findings${rst}" 0.4
emit "  - Thin intro + no internal links → readers bounce before scrolling" 0.3
emit "  - Add a TL;DR block and 3 related-post links above the fold" 0.3
emit "  - Code samples lack output — add results so readers stay to verify" 0.3
echo
emit "${dim}Key: data shows the symptoms; content shows the causes.${rst}" 0.5
sleep 1.8
