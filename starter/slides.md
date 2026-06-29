---
theme: '@alexop/slidev-theme-brand'
addons:
  - '@alexop/slidev-addon-utils'
title: "Mastering the Basics: Agents, Subagents, Skills & Hooks in VS Code Copilot"
info: |
  ## Mastering the Basics: Agents, Subagents, Skills & Hooks in VS Code Copilot
  by Alexander Opalic
author: Alexander Opalic
transition: slide-left
mdc: true
fonts:
  hand: 'Caveat'
layout: image
image: /dwx-2026-cover.png
backgroundSize: contain
---

---
layout: cover
---

# Mastering the Basics: Agents, Subagents, Skills & Hooks in VS Code Copilot

by Alexander Opalic

<div class="abs-br mr-10 mb-16 flex flex-col items-center gap-2">
  <img src="/slides-qr.svg" class="w-36 h-36 rounded-lg bg-white p-2" alt="Scan to open these slides" />
  <div class="text-sm opacity-80">📱 Scan to follow along</div>
</div>

---
layout: center
---

# Quick heads-up 👋

<div class="max-w-2xl mx-auto text-left space-y-5 mt-10 text-xl leading-relaxed">

<div>👉&nbsp; This one's a bit more **spontaneous** — I jumped in as a short-notice replacement</div>

<div>👉&nbsp; It's also my **first time giving two talks back-to-back** at a conference</div>

<div>👉&nbsp; So if something isn't 100% perfect, **please bear with me** 🙏</div>

<div>👉&nbsp; Let's have some fun and **dive in!**</div>

</div>

---
layout: image
image: /copilotWorkshop/karpathy.png
backgroundSize: contain
---

---

## Talk Outline

<OutlineRoadmap />

---
layout: center
class: 'text-center'
---

# Before we start — who's in the room?

<div class="text-lg op-70 mt-2 mb-8">Hands up. I'm reading the room.</div>

<TalkCardGrid
  :columns="2"
  compact
  max-width="max-w-3xl"
  :cards="[
    { title: 'GitHub Copilot', logo: '/logos/githubcopilot.svg', glow: true },
    { title: 'Claude Code', logo: '/logos/claude.svg', glow: true },
    { title: 'Cursor', logo: '/logos/cursor.svg', glow: true },
    { title: 'Codex / other', logo: '/logos/openai.svg', glow: true },
  ]"
/>

<div class="text-sm op-60 mt-8">No wrong answer. I just want to know who I'm talking to.</div>

---

# About me

<About image="/alex-speaking.png" />

---
layout: section
---

# What is an Agent?

---

## The Transformation: LLM → Agent

<AgentFormula />

---
layout: image
image: /copilotWorkshop/agent.png
backgroundSize: contain
---

---

## The Agentic Loop (nanocode)

```shell
nanocode | claude-opus-4-5 | /Users/alexanderopalic/Projects/typescript/nanocode

────────────────────────────────────────────────────────────────────────────────
❯  create a simple typescript file as a sum function
────────────────────────────────────────────────────────────────────────────────
[agentLoop] Starting with 1 messages
[agentLoop] Got response, stop_reason: tool_use

⏺ Write(src/sum.ts)
  ⎿  ok
[agentLoop] Starting with 3 messages
[agentLoop] Got response, stop_reason: end_turn

⏺ Created `src/sum.ts` with a simple sum function that takes two numbers and returns their sum.
```

**~350 lines of TypeScript** to understand how Claude Code works.

---

<DemoVideo
  title="The agent loop, live"
  src="/videos/agentic-loop.mp4"
  caption="One prompt → tool call → results fed back → loop → done. The recursion is the agent."
/>

---

## The Agentic Loop (Code)

````md magic-move {lines: true}
```typescript
// 1. An LLM is just: messages in → response out
async function agentLoop(messages: Message[], systemPrompt: string) {
  const response = await callApi(messages, systemPrompt)
  printResponse(response)
}
```

```typescript
// 2. Let it DO things — run the tools it asked for
async function agentLoop(messages: Message[], systemPrompt: string) {
  const response = await callApi(messages, systemPrompt)
  printResponse(response)

  const toolResults = await processToolCalls(response.content)
}
```

```typescript
// 3. No tools requested? The turn is over.
async function agentLoop(messages: Message[], systemPrompt: string): Promise<Message[]> {
  const response = await callApi(messages, systemPrompt)
  printResponse(response)

  const toolResults = await processToolCalls(response.content)
  const newMessages = [...messages, { role: 'assistant', content: response.content }]

  if (toolResults.length === 0) {
    return newMessages // we're done
  }
}
```

```typescript {14-17}
// 4. Feed results back & call yourself — THIS is the agent 🔁
async function agentLoop(messages: Message[], systemPrompt: string): Promise<Message[]> {
  const response = await callApi(messages, systemPrompt)
  printResponse(response)

  const toolResults = await processToolCalls(response.content)
  const newMessages = [...messages, { role: 'assistant', content: response.content }]

  if (toolResults.length === 0) {
    return newMessages // we're done
  }

  return agentLoop(
    [...newMessages, { role: 'user', content: toolResults }],
    systemPrompt
  )
}
```
````

<v-click>

The entire request → response → execute → **loop** cycle in ~15 lines. An LLM becomes an agent the moment it can call its own results back.

</v-click>

---

## Tool Registration

```typescript
const TOOLS = new Map([
  ['read', {
    description: 'Read file with line numbers',
    schema: { path: 'string', offset: 'number?', limit: 'number?' },
    execute: read
  }],
  ['write', {
    description: 'Write content to file',
    schema: { path: 'string', content: 'string' },
    execute: write
  }],
  ['bash', {
    description: 'Run shell command',
    schema: { cmd: 'string' },
    execute: bash
  }]
])
```

---

## A Complete Tool Implementation

```typescript
async function read(args: Record<string, unknown>): Promise<string> {
  const path = args.path as string
  const text = await Bun.file(path).text()
  const lines = text.split('\n')
  const offset = (args.offset as number) ?? 0
  const limit = (args.limit as number) ?? lines.length
  return lines
    .slice(offset, offset + limit)
    .map((line, i) => `${(offset + i + 1).toString().padStart(4)}| ${line}`)
    .join('\n')
}
```

---
layout: image
image: /copilotWorkshop/agentTools.png
backgroundSize: contain
---

---

## VS Code Copilot Built-in Tools

- ⟨⟩ **agent** — Delegate tasks to other agents
- ⓘ **askQuestions** — Ask questions to clarify requirements
- ✎ **edit** — Edit files in your workspace
- ▷ **execute** — Execute code and applications
- ⧉ **read** — Read files in your workspace
- 🔍 **search** — Search files in your workspace
- ≡ **todo** — Manage and track todo items
- ✕ **vscode** — Use VS Code features
- 🌐 **web** — Fetch information from the web

---

<DemoVideo
  title="Ask the agent what it can do"
  src="/videos/copilot-cli-tools.mp4"
  caption="The Copilot CLI lists the tools available from its system context — shell, file inspection, editing, execution, web/GitHub, and agents."
/>

---
layout: section
---

# Context Engineering

---
layout: image
image: /copilotWorkshop/agentContext.png
backgroundSize: contain
---

---

<ContextWindowVisualizer />

---
layout: quote
---

> "Context engineering is the art and science of filling the context window with just the right information at each step of an agent's trajectory."
>
> — LangChain/Manus webinar

---

## Context Window Utilization

<ContextUtilizationVisualizer />

---

<ContextFillupVisualizer />

---

## Three Long-Horizon Techniques

From [Anthropic's guide](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents):

1. **Compaction** — Summarize history, reset periodically
2. **Structured note-taking** — External memory systems
3. **Sub-agent architectures** — Distribute work across focused contexts

---

## Where Exactly Does It Cut?

<CompactionCutPoint />

<div class="text-xs opacity-50 mt-2">

The summary replaces everything before `firstKeptEntryId`; recent rounds stay verbatim, full history stays on disk.

</div>

---
layout: center
---

<MemorySlide
  icon="🧠"
  title="Working memory"
  accent-class="text-sky-400"
  border-class="border-sky-400/50"
>
<template #description>
What's active in your head <em>right now</em> — the sentence you're reading. <span class="opacity-60">Volatile, small.</span>
</template>

The chat session's <strong>context window</strong>. Watch the fill meter in the chat box — when it fills, Copilot auto-summarizes, or run <code>/compact</code>. Start a <strong>new session</strong> to reset it.
</MemorySlide>

---
layout: center
---

<MemorySlide
  icon="📚"
  title="Semantic memory"
  accent-class="text-green-400"
  border-class="border-green-400/50"
>
<template #description>
Factual knowledge you just <em>know</em> — "Python is interpreted." <span class="opacity-60">No need to re-learn it.</span>
</template>

<strong>Custom instructions</strong> — project facts the agent always loads: <code>.github/copilot-instructions.md</code>, <code>AGENTS.md</code>, and scoped <code>*.instructions.md</code> files (with an <code>applyTo</code> glob).
</MemorySlide>

---
layout: center
---

<MemorySlide
  icon="🛠️"
  title="Procedural memory"
  accent-class="text-amber-400"
  border-class="border-amber-400/50"
>
<template #description>
Learned skills — riding a bike. <span class="opacity-60">You don't re-derive it each time.</span>
</template>

<strong>Agent Skills</strong> — a folder per skill at <code>.github/skills/&lt;name&gt;/SKILL.md</code>. The agent loads one itself when its description matches the task. Portable across Copilot CLI & cloud.
</MemorySlide>

---
layout: center
---

<MemorySlide
  icon="🎞️"
  title="Episodic memory"
  accent-class="text-purple-400"
  border-class="border-purple-400/50"
>
<template #description>
Personal experience — that 3-hour debug session. <span class="opacity-60">Tied to events you lived.</span>
</template>

The <strong>Memory tool</strong> <span class="opacity-60">(preview)</span>. The agent saves notes to <code>/memories/</code> (you) and <code>/memories/repo/</code> (project); the first ~200 lines auto-load each session. Manage via <strong>Chat: Show Memory Files</strong>.
</MemorySlide>

---

## Four types of memory — in VS Code Copilot

| Memory | Human version | In VS Code Copilot |
| --- | --- | --- |
| <span class="text-sky-400 font-bold">🧠 Working</span> | What's in your head now | Context window · `/compact` · new session |
| <span class="text-green-400 font-bold">📚 Semantic</span> | Facts you just know | `.github/copilot-instructions.md` · `AGENTS.md` · `*.instructions.md` |
| <span class="text-amber-400 font-bold">🛠️ Procedural</span> | Learned skills | Agent Skills — `.github/skills/<name>/SKILL.md` |
| <span class="text-purple-400 font-bold">🎞️ Episodic</span> | Lived experiences | Memory tool (preview) — `/memories/` · "Show Memory Files" |

<p class="mt-6 opacity-70">Semantic & procedural are Markdown <em>you</em> write. Episodic is Markdown the <em>agent</em> writes for itself.</p>

---
layout: section
---

# AGENTS.md

---

## What is AGENTS.md?

**What:** An open standard for agent-specific documentation

**Where:** Repository root (works in monorepos too)

**Who:** Works with Copilot, Claude, Cursor, Devin, 20+ agents

> "While README.md targets humans, AGENTS.md contains the extra context coding agents need."

---
layout: iframe
url: https://agents.md/
---

---

## AGENTS.md Structure

```markdown
# AGENTS.md

## Dev Environment
- How to set up and navigate

## Build & Test Commands
- `pnpm install && pnpm dev`
- `pnpm test:unit`

## Code Style
- TypeScript strict mode
- Prefer composition over inheritance

## PR Instructions
- Keep PRs small and focused
```

**Key:** No required fields—use what helps your project.

---
layout: image
image: /copilotWorkshop/bloatedAgent.png
backgroundSize: contain
---

---
layout: two-cols-header
---

## Before vs After: Progressive Disclosure

::left::

<h3 class="text-red-400 font-bold text-xl mb-4">❌ Bloated (847 lines)</h3>

```markdown
# AGENTS.md

## API Endpoints
[200 lines of docs...]
## Testing Strategy
[150 lines of docs...]
## Architecture
[300 lines of docs...]
## Code Style
[100 lines of rules...]
## Deployment
[97 lines of docs...]
```

<p class="text-yellow-400 mt-4 text-sm">40% context consumed before work starts</p>

::right::

<h3 class="text-green-400 font-bold text-xl mb-4">✅ Lean (58 lines)</h3>

```markdown
# AGENTS.md

## Quick Start
pnpm install && pnpm dev

## Docs Reference
| Doc | When to read |
|-----|--------------|
| docs/api.md | API work |
| docs/testing.md | Tests |
| docs/arch.md | Design |
```

<p class="text-cyan-400 mt-4 text-sm">Docs loaded on-demand when needed</p>

---
layout: image
image: /copilotWorkshop/progressiveDisc.png
backgroundSize: contain
---

---

## The /learn Skill

```markdown
# Learn from Conversation

## Phase 1: Deep Analysis
- What patterns or approaches were discovered?
- What gotchas or pitfalls were encountered?
- What architecture decisions were made?

## Phase 2: Categorize & Locate
Read existing docs to find the best home.

## Phase 3: Draft the Learning
Format to match existing doc style.

## Phase 4: User Approval (BLOCKING)
Present changes, wait for explicit approval.

## Phase 5: Save
After approval, save the learning.
```

---
layout: section
---

# Back Pressure

---

## Why Back Pressure Matters

**Back pressure** = automated feedback that validates agent work

- Without back pressure, **you** become the validation layer
- Agents cannot self-correct if nothing tells them something is wrong
- With good back pressure, agents detect mistakes and iterate until correct

> "If you're directly responsible for checking each line is valid, that's time taken away from higher-level goals."

---

## Back Pressure Sources

| Source | What It Validates |
|--------|-------------------|
| **Type system** | Types, interfaces, contracts |
| **Build tools** | Syntax, imports, compilation |
| **Tests** | Logic, behavior, regressions |
| **Linters** | Style, patterns, best practices |

<Callout type="info">

**Key insight:** Expressive type systems + good error messages = agents can self-correct.

</Callout>

---
layout: section
---

# Subagents

---

## Subagents in VS Code

**How to invoke:**

1. Enable tools in Copilot Chat (hammer icon)
2. Call explicitly with `#runSubagent`
3. Or accept when Copilot suggests one

---

## Use Cases

- Specialized searches (explore codebase, web, docs)
- Long-running tasks (data analysis, refactoring)
- TDD workflows (test generation, validation)
- Multi-step processes (research, summarize, act)

---
hideFooter: true
---

## Explore Subagent Flow

<SubagentDiagram task="Find auth files" :files="['Auth.tsx', 'auth.ts', 'authService.ts']" />

Click **Start** to see how the main agent delegates file search to a specialized Explore subagent.

---

## Parallel Subagent Execution

<ParallelSubagentDiagram
  task="Research Vue 3 reactivity"
  :agents="[
    { name: 'Web Agent', icon: '🌐', color: '#3b82f6', domain: 'Docs, GitHub', findings: ['Official guide', 'RFC #123', 'GitHub issue'] },
    { name: 'Community', icon: '💬', color: '#8b5cf6', domain: 'Reddit, SO', findings: ['r/vuejs post', 'Top SO answer', 'Discord tip'] },
    { name: 'Codebase', icon: '📂', color: '#10b981', domain: 'Project files', findings: ['useAuth.ts', 'store.ts', 'api/client.ts'] }
  ]"
/>

Click **Start** to see the fan-out/fan-in pattern where multiple subagents search in parallel.

---

## Nested Subagents: Orchestrator Pattern

<NestedSubagentDiagram
  task="Build user authentication"
  :criteria="[
    { id: 'AC1', title: 'Login form', icon: '🎨', color: '#3b82f6' },
    { id: 'AC2', title: 'Auth API', icon: '🔌', color: '#8b5cf6' },
    { id: 'AC3', title: 'Unit tests', icon: '🧪', color: '#10b981' }
  ]"
/>

Main chat writes a **`spec.md`**, hands it to an **Orchestrator** subagent, which spawns one **implementation subagent per acceptance criterion**.

---

## Subagent in nanocode: Fetch Tool

```shell
nanocode | claude-opus-4-5 | /Users/alexanderopalic/Projects/typescript/nanocode

────────────────────────────────────────────────────────────────────────────────
❯ how does fc bayern played yesterday
────────────────────────────────────────────────────────────────────────────────
[agentLoop] Starting with 1 messages
[agentLoop] Got response, stop_reason: tool_use

⏺ Fetch(https://www.google.com/search?q=fc+bayern+munich+m)
  ⎿  I apologize, but I cannot access real-time sports results or ... +7 lines
[agentLoop] Starting with 3 messages
[agentLoop] Got response, stop_reason: tool_use

⏺ Fetch(https://www.espn.com/soccer/team/_/id/132/bayern-m)
  ⎿  Based on the information in the image, Bayern Munich's most  ... +7 lines
[agentLoop] Starting with 5 messages
[agentLoop] Got response, stop_reason: end_turn

⏺ FC Bayern Munich lost 2-1 to FC Augsburg in the Bundesliga yesterday.
```

The **Fetch tool** uses a subagent to summarize HTML responses before returning.

---
layout: section
---

# Skills

---
layout: image
image: /copilotWorkshop/howAgentSkills.png
backgroundSize: contain
---

---

## Real Skill: Plausible SEO Consultant

```shell
.claude/skills/plausible-insights/
├── skill.md              # Skill definition + quick start
├── scripts/              # Automation scripts
│   └── fetch-data.ts    # Fetch Plausible data CLI
└── references/           # On-demand docs (progressive disclosure)
    ├── quick-ref.md      # Common query patterns
    ├── api/
    │   ├── filters.md    # Filter syntax
    │   └── errors.md     # Error solutions
    └── seo/
        └── thresholds.md # Interpretation guidelines
```

The agent reads `skill.md` first. Reference docs load only when needed.

---

## Skill in Action

**User:** "Why is my bounce rate so high on the Vue posts?"

1. Description matches → skill.md loads (~500 tokens)
2. Agent runs: `bun cli top-pages --range 7d --pattern "/vue/"`
3. Agent reads `references/seo/thresholds.md` for interpretation
4. Agent fetches actual pages with WebFetch
5. Returns specific fixes based on real content

**Key:** Data shows symptoms. Content shows causes.

---

<DemoVideo
  title="The Plausible SEO skill at work"
  src="/videos/skill-in-action.mp4"
  caption="Description match → skill.md loads → CLI script runs → reference doc → WebFetch → specific fixes."
/>

---
layout: section
---

# The Full Picture

---
layout: image
image: /copilotWorkshop/agentSum.png
backgroundSize: contain
---

---
layout: section
---

# Hooks

---

## What are Hooks?

**Skills guide** the agent. **Hooks control** it — deterministically.

- Run **your shell commands** at key lifecycle points of an agent session
- Not a suggestion to the model — **code that always runs**, with guaranteed outcomes
- Each hook gets **JSON on stdin**, can return **JSON on stdout** to influence the agent
- Works across **local, background, and cloud** agents

<Callout type="info">

Instructions *ask* the agent nicely. Hooks **enforce** — block a command, format a file, inject context, no matter how the agent was prompted.

</Callout>

---

## The 8 Lifecycle Events

| Event | Fires when… | Use for |
|-------|-------------|---------|
| `SessionStart` | first prompt of a session | inject project context |
| `UserPromptSubmit` | user sends a prompt | audit, add context |
| `PreToolUse` | **before** a tool runs | **block / approve / deny** |
| `PostToolUse` | **after** a tool succeeds | format, lint, test |
| `PreCompact` | before context is compacted | save state |
| `SubagentStart` / `SubagentStop` | subagent spawns / ends | track nested work |
| `Stop` | session ends | notify, report, cleanup |

---

## How a Hook Works

<HookFlowDiagram class="mt-8" />

---

## Configuration

Drop a JSON file in `.github/hooks/` — VS Code loads it automatically:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "npx prettier --write ."
      }
    ]
  }
}
```

<Callout type="info">

Same format as **Claude Code** & **Copilot CLI** — VS Code also reads `.claude/settings.json`. Or run **`/hooks`** in chat to generate one.

</Callout>

---

## 🔒 The Killer Hook: Block reading `.env`

**Problem:** if the agent reads `.env`, your secrets flow into the LLM context → sent to the cloud, stored in transcripts/logs, maybe echoed back into chat.

- Secrets that **never enter context** can't leak
- A `PreToolUse` guard is a **hard data boundary**, not a style preference
- Inspect the path, return `permissionDecision: "deny"` — the agent is told *why*

---

## 🔒 The Guard Script

```bash
#!/bin/bash
INPUT=$(cat)
PATH_ARG=$(echo "$INPUT" | jq -r '.tool_input.file_path
  // .tool_input.path // .tool_input.command // ""')

if echo "$PATH_ARG" | grep -qiE \
  '(^|/)\.env($|\.)|\.(pem|key|p12|pfx)$|id_rsa|credentials|\.aws/|secrets/'; then
  echo '{"hookSpecificOutput":{"permissionDecision":"deny",
    "permissionDecisionReason":"Blocked: secret file. Use an env var name, not the value."}}'
  exit 0
fi
echo '{"continue":true}'
```

<Callout type="warn">

Also catch the **indirect** path — `cat .env` / `printenv` live in `tool_input.command`, not just file-read tools.

</Callout>

---

## More High-Value Hooks

- 🛑 **Block destructive commands** (`PreToolUse`) — `rm -rf /`, `git push --force`, `DROP TABLE`
- 🎨 **Auto-format & lint** (`PostToolUse`) — clean diffs, zero prompting, zero tokens
- ✅ **Typecheck / test after edits** (`PostToolUse`) — agent fixes its own breakage
- 🧭 **Inject context** (`SessionStart`) — branch, package manager, scripts — always current
- 🛡️ **Protect critical files** — lockfiles, `.github/workflows/`, `main` branch
- 🔔 **"Agent finished" notification** (`Stop`) — walk away, come back when it's done

---

## ...And Plenty More Ideas 💡

<HookIdeas />

---
layout: center
---

## Recommended Starting Set

<div class="text-sm opacity-60 mb-6">Three pure-win safety &amp; quality rails — start here.</div>

<div grid="~ cols-3 gap-5" class="items-stretch starting-set">
  <div class="relative">
    <span class="step-badge">1</span>
    <FeatureCard icon="🔒" title="Secret-file guard" description="Keep .env and credentials out of the agent's context — it can't leak what it never sees." />
  </div>
  <div class="relative">
    <span class="step-badge">2</span>
    <FeatureCard icon="🛑" title="Dangerous-command guard" description="Block the catastrophic shell call before it runs. One rule, zero rm -rf surprises." />
  </div>
  <div class="relative">
    <span class="step-badge">3</span>
    <FeatureCard icon="🎨" title="Auto-format on edit" description="Consistent tree on every write — no nagging, no diff noise, no style debates." />
  </div>
</div>

<Callout type="info">

Tip: bundle all three into <strong>one <code>PreToolUse</code> script</strong> — it already parsed stdin.

</Callout>

<style scoped>
.starting-set > div { display: flex; }
.starting-set :deep(.feature-card) {
  display: flex;
  flex-direction: column;
  width: 100%;
}
.starting-set :deep(.feature-card h3) {
  font-size: 1.15rem;
  min-height: 2.8rem;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
}
.starting-set :deep(.feature-card .text-5xl) { text-align: center; }
.step-badge {
  position: absolute;
  top: -0.6rem;
  left: -0.6rem;
  z-index: 10;
  width: 1.9rem;
  height: 1.9rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 9999px;
  background: #ff6bed;
  color: #1a1a1a;
  font-weight: 700;
  font-size: 0.95rem;
  box-shadow: 0 4px 12px -2px rgba(255, 107, 237, 0.5);
}
</style>

---
layout: section
---

# Live Demo

---

## Prerequisites

The demo uses `npx` (bundled with Node.js) and Python. Install for your platform:

**Mac (Homebrew):**
```bash
brew install node python
```

**Windows (winget):**
```bash
winget install OpenJS.NodeJS Python.Python.3.12
```

**Or download from:** [nodejs.org](https://nodejs.org) | [python.org](https://python.org)

**Verify:**
```bash
node --version && npx --version && python --version
```

---

## Demo: Building a Skill

1. **Enable Skills** in VS Code settings
2. **Install skill-creator** via CLI
3. **Prompt** to generate a new skill

---

## Step 1: Enable Skills

**VS Code Setting:**

```json
{
  "chat.useAgentSkills": true
}
```

Or via UI: `Settings → Search "agent skills" → Enable`

<Callout type="warn">
Still in preview — enable in VS Code Insiders for the latest features.
</Callout>

---
layout: image
image: /copilotWorkshop/settings.png
backgroundSize: contain
---

---

## First: Create a Skill by Hand

```md
---
name: hello
description: 'use it everytime the user writes alex'
---

# Hello Skill

if the user writes "alex", respond with "Hello, Alexander Opalic! How can I assist you today?"
```

---

## Step 2: Install skill-creator

```bash
npx skills add https://github.com/anthropics/skills --skill skill-creator
```

This adds the **skill-creator** skill to your project — a skill that helps you create new skills.

**Project structure after install:**

```
my-project/
└── .github/
    └── skills/
        └── skill-creator/
            └── SKILL.md
```

---

```shell
◇  Source: https://github.com/anthropics/skills.git
│
◇  Repository cloned
│
◇  Found 17 skills (via Well-known Agent Skill Discovery)
│
●  Selected 1 skill: skill-creator
│
◇  Detected 3 agents
│
◇  Install to
│  All agents (Recommended)
│
◇  Installation scope
│  Project
│
◇  Installation method
│  Symlink (Recommended)

│
◇  Installation Summary ──────────────────────────────╮
│                                                     │
│  ~/Projects/workshop/.agents/skills/skill-creator   │
│    symlink → Claude Code, GitHub Copilot, OpenCode  │
│                                                     │
├─────────────────────────────────────────────────────╯
│
◆  Proceed with installation?
│  ● Yes / ○ No
└
```

---

## Step 3: Generate a New Skill

Important Skill name and folder name must match!

**Prompt:**

```
Create a skill that will use https://alexop.dev/llms.txt
and will answer any question regarding Vue or AI.

The skill should fetch the content and use the
#runSubagent command. The subagent should do the
heavy work and then report back to the main agent.
name of the skill is vue-ai-assistant
```

→ **skill-creator generates the SKILL.md for us**

---

## What Gets Generated

````markdown
---
name: vue-ai-assistant
description: Answer questions about Vue.js, Nuxt, and AI topics using Alexander Opalic's knowledge base. Use this skill when the user asks about Vue, Vue 3, Nuxt, Nuxt 3, Composition API, Vue Router, Pinia, Vite, AI, machine learning, LLMs, or related frontend/AI topics.
---

# Vue & AI Assistant

Answer questions about Vue.js ecosystem and AI topics by fetching knowledge from
https://alexop.dev/llms.txt and delegating research to a subagent.

## MANDATORY Workflow

1. **Fetch the knowledge base**: Use `fetch_webpage` to retrieve content from `https://alexop.dev/llms.txt`
2. **REQUIRED - Delegate to subagent**: Use `runSubagent` with the fetched content and user's question.
3. **Return the answer**: Present the subagent's findings to the user
````

---
layout: image
image: /copilotWorkshop/skillExample.png
backgroundSize: contain
---

---

## Bonus: The askQuestions Tool

VS Code Copilot can **ask clarifying questions** mid-task.

```md
help me to create a workout tracking app use the #askQuestions tool to find out how the tech specs should be
```

---

```shell
┌─────────────────────────────────────────────────────────────┐
│                     Platform (1/4)                          │
├─────────────────────────────────────────────────────────────┤
│ What platform should the workout tracking app target?       │
├─────────────────────────────────────────────────────────────┤
│ ★ Web App  Browser-based PWA, accessible anywhere      [✓]  │
├─────────────────────────────────────────────────────────────┤
│   iOS Native  Swift/SwiftUI for iPhone                      │
├─────────────────────────────────────────────────────────────┤
│   Android Native  Kotlin for Android devices                │
├─────────────────────────────────────────────────────────────┤
│   Cross-Platform  React Native or Flutter for iOS & Android │
├─────────────────────────────────────────────────────────────┤
│   Desktop  Electron app for Mac/Windows                     │
├─────────────────────────────────────────────────────────────┤
│ ✎ Other...  Enter custom answer                             │
└─────────────────────────────────────────────────────────────┘
```

---

<DemoVideo
  title="The #askQuestions tool"
  src="/videos/ask-questions.mp4"
  caption="Copilot asks tech-spec questions before scaffolding the workout app."
/>

---

## Subagent Fan-Out Pattern

**Prompt for VS Code Insiders:**

```
#runSubagent run 3 subagents that search the web
and tell me something interesting about Geretsried
```

This demonstrates the **fan-out/fan-in pattern** where multiple agents work in parallel.

---

<DemoVideo
  title="Subagent fan-out"
  src="/videos/subagent-fanout.mp4"
  caption="#runSubagent spins up 3 parallel web-search agents on Geretsried."
/>

---

## Live Action: Excalidraw Skill

**Install the skill:**

```bash
npx skills add https://github.com/softaworks/agent-toolkit --skill excalidraw
```

Install the Excalidraw Extension in VS Code for best experience.

**Prompt to customize with brand colors:**

```
Update the excalidraw skill to use these brand colors:

- Fill: rgb(33, 39, 55)
- Text: rgb(234, 237, 243)
- Accent: rgb(255, 107, 237)
- Card: rgb(52, 63, 96)
- Card Muted: rgb(138, 51, 123)
- Border: rgb(171, 75, 153)
```

→ Agent modifies the skill's SKILL.md to include color instructions

---

## Live Action: A `SessionStart` Hook

**The problem:** the model has no clock and no thermometer — it can't tell you the time or the weather.

**Prompt to build it live:**

```
Create a SessionStart hook in .github/hooks/ that greets me with
the current time and how hot it is in Geretsried, on every session.
```

→ Agent writes `session-greeting.json` + a shell script: `date` + a keyless `wttr.in` call

```bash
TIME=$(date '+%H:%M on %A, %B %-d')
WEATHER=$(curl -s --max-time 6 "https://wttr.in/Geretsried?format=%C+%t")
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",
  \"additionalContext\":\"It is $TIME. In Geretsried: $WEATHER.\"}}"
```

> *"Good day! It is 15:18 on Monday, June 29. In Geretsried right now: Partly cloudy +27°C."*

Every new session opens with the **real time and weather** — deterministically, zero prompting.

---
layout: image
image: /copilotWorkshop/robot.png
backgroundSize: contain
---

---

## More Community Skills

```bash
npx skills add https://github.com/anthropics/skills --skill frontend-design
npx skills add https://github.com/simonwong/agent-skills --skill code-simplifier
```

- **frontend-design** — creates polished, production-grade UI components
- **code-simplifier** — simplifies and refines code for clarity

Browse and discover skills at [agentskills.io](https://agentskills.io/)

---
layout: center
---

## Key Takeaways

1. **Agents = LLM + Tools + Loop** (nanocode shows this simply)
2. **Context is finite** — treat tokens as budget
3. **AGENTS.md** — standardized project context
4. **Subagents** — specialized agents for complex tasks
5. **Skills** — portable workflows that load on demand
6. **Hooks** — deterministic guardrails (keep secrets out of context!)

---

## Resources

- [VS Code: Using Agents](https://code.visualstudio.com/docs/copilot/agents/overview) — Agent types and session management
- [Anthropic: Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Context engineering guide
- [VS Code: Introducing Agent Skills](https://www.youtube.com/watch?v=JepVi1tBNEE) — Agent Skills deep dive
- [VS Code: Agent Hooks (Preview)](https://code.visualstudio.com/docs/agents/concepts/hooks) — Lifecycle hooks for deterministic control
- [VS Code: Context Engineering Guide](https://code.visualstudio.com/docs/copilot/guides/context-engineering-guide) — Microsoft's context engineering workflow
- [AGENTS.md](https://agents.md/) — Open standard for agent documentation
- [Agent Skills Spec](https://agentskills.io/) — Open standard for portable agent skills
- [nanocode](https://github.com/alexanderop/nanocode) — Minimal agent implementation in TypeScript
- [Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — Best practices for agent documentation
- [Plausible SEO Skill](https://github.com/alexanderop/claude-plausible-analytics) — Skills deep dive with Plausible example
- [Don't Waste Your Back Pressure](https://banay.me/dont-waste-your-backpressure/) — Why automated feedback loops make agents more effective
- [Workshop Solution](https://github.com/alexanderop/workshop) — Complete code examples from this workshop
- [Learn Prompt](https://alexop.dev/prompts/claude/claude-learn-command/) — Skill that helps agents learn from conversations

---
layout: end
class: text-center
---

# Thank You! 🙏

<div class="text-2xl opacity-80 mt-2">Questions?</div>

<div class="flex items-center justify-center gap-12 mt-12">
  <div class="text-left">
    <h3>Find me online</h3>
    <div class="text-xl opacity-90 mt-3">
      Tutorials, deep dives &amp; experiments:
    </div>
    <a href="https://alexop.dev" class="text-3xl font-mono mt-4 inline-block">
      alexop.dev
    </a>
  </div>

  <div class="text-center">
    <div class="bg-white p-4 rounded-2xl shadow-lg inline-block">
      <img src="/slides-qr.svg" class="w-52 h-52" alt="QR code to these slides" />
    </div>
    <div class="text-sm opacity-80 mt-3">📱 Scan to open these slides</div>
  </div>
</div>

<div class="text-lg opacity-60 mt-12">Alexander Opalic</div>
