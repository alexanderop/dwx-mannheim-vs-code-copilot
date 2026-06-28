#!/usr/bin/env bash
# Scripted walkthrough of the .env PreToolUse guard, for the VHS recording.
# Driven by env-hook.tape; not meant to be run interactively (it has paced sleeps).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1
HOOK=.github/hooks/scripts/block-secrets.sh

cmd=$'\e[38;5;212m'   # brand pink-ish
dim=$'\e[2m'
red=$'\e[1;31m'
grn=$'\e[1;32m'
rst=$'\e[0m'

prompt() { printf "%s\$ %s%s\n" "$cmd" "$1" "$rst"; sleep 0.7; }
note()   { printf "%s# %s%s\n" "$dim" "$1" "$rst"; }

clear
note "A PreToolUse hook inspects every tool call before it runs."
note "Rule: the agent must NEVER read .env into its context."
echo; sleep 1.6

note "The secrets we are protecting:"
prompt "cat .env"
# Fake demo secrets (skip if .env is absent so the recording still renders).
sed -n '4,6p' .env 2>/dev/null || printf 'OPENAI_API_KEY=sk-FAKE-demo\nDATABASE_URL=postgres://demo:hunter2@localhost/dwx\nSTRIPE_SECRET_KEY=sk_live_FAKE_demo\n'
echo; sleep 2.0

note "The agent tries to read .env — the hook sees the call first:"
prompt "echo '{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\".env\"}}' | hook"
echo '{"tool_name":"Read","tool_input":{"file_path":".env"}}' | bash "$HOOK" | jq .
sleep 2.2
printf "%s>> permissionDecision: deny  —  the secret never enters context.%s\n" "$red" "$rst"
echo; sleep 1.8

note "Sneaky indirect read via the terminal? Blocked too:"
prompt "echo '{\"toolName\":\"shell\",\"toolArgs\":{\"command\":\"cat .env\"}}' | hook"
echo '{"toolName":"shell","toolArgs":{"command":"cat .env"}}' | bash "$HOOK" | jq .
sleep 2.2
echo

note "A normal source file flows straight through:"
prompt "echo '{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"src/index.ts\"}}' | hook"
echo '{"tool_name":"Read","tool_input":{"file_path":"src/index.ts"}}' | bash "$HOOK" | jq .
sleep 1.6
printf "%s>> allowed. Secrets blocked, real work flows.%s\n" "$grn" "$rst"
sleep 2.2
