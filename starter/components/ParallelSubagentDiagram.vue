<script lang="ts">
/**
 * ParallelSubagentDiagram - Interactive fan-out/fan-in animation.
 *
 * One main agent spawns N subagents in parallel, each searches its own domain,
 * findings stream in, then results are synthesised back. Vue port of the
 * original React + framer-motion renderer.
 */
export interface AgentConfig {
  name: string
  icon: string
  color: string
  domain: string
  findings: string[]
}

// Module scope so withDefaults' default factory can reference it (hoisted out
// of setup()).
export const defaultAgents: AgentConfig[] = [
  { name: 'Web Agent', icon: '🌐', color: '#3b82f6', domain: 'Docs, GitHub', findings: ['Official guide', 'RFC #123', 'GitHub issue'] },
  { name: 'Community', icon: '💬', color: '#8b5cf6', domain: 'Reddit, SO', findings: ['r/vuejs post', 'Top SO answer', 'Discord tip'] },
  { name: 'Codebase', icon: '📂', color: '#10b981', domain: 'Project files', findings: ['useAuth.ts', 'store.ts', 'api/client.ts'] },
]
</script>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { motion, AnimatePresence } from 'motion-v'

const props = withDefaults(
  defineProps<{
    task?: string
    agents?: AgentConfig[]
    autoStart?: boolean
    speed?: number
  }>(),
  {
    task: 'Research Vue 3 reactivity',
    agents: () => defaultAgents,
    autoStart: false,
    speed: 0.6,
  },
)

type Phase =
  | 'idle'
  | 'task-bubble'
  | 'spawn-all'
  | 'delegate-all'
  | 'searching'
  | 'findings'
  | 'report-all'
  | 'synthesis'
  | 'complete'

const PHASE_ORDER: Phase[] = [
  'idle', 'task-bubble', 'spawn-all', 'delegate-all',
  'searching', 'findings', 'report-all', 'synthesis', 'complete',
]

function isPhaseAtLeast(current: Phase, threshold: Phase): boolean {
  return PHASE_ORDER.indexOf(current) >= PHASE_ORDER.indexOf(threshold)
}

const agentPositions = [130, 400, 670]
const mainAgentY = 70
const subagentY = 200
const domainBoxY = 280
const synthesisY = 420

function getFanOutPath(mainX: number, mainY: number, targetX: number, targetY: number): string {
  const midY = (mainY + targetY) / 2
  const cpX = targetX + (mainX - targetX) * 0.3
  return `M${mainX},${mainY + 45} Q${cpX},${midY} ${targetX},${targetY - 40}`
}

function getFanInPath(sourceX: number, sourceY: number, targetX: number, targetY: number): string {
  const midY = (sourceY + targetY) / 2 + 20
  const cpX = sourceX + (targetX - sourceX) * 0.3
  return `M${sourceX},${sourceY + 20} Q${cpX},${midY} ${targetX},${targetY - 30}`
}

const phase = ref<Phase>('idle')
const isAnimating = ref(false)
const visibleFindings = ref<Set<string>>(new Set())

const prefersReducedMotion =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

const timing = computed(() => ({
  taskBubble: 400 / props.speed,
  spawnAll: 400 / props.speed,
  delegateAll: 300 / props.speed,
  searchingDuration: 800 / props.speed,
  findingsDelay: 150 / props.speed,
  reportAll: 400 / props.speed,
  synthesis: 500 / props.speed,
}))

const totalFindings = computed(() =>
  props.agents.reduce((sum, agent) => sum + agent.findings.length, 0),
)

let timeouts: ReturnType<typeof setTimeout>[] = []
function clearTimeouts() {
  timeouts.forEach(clearTimeout)
  timeouts = []
}
function later(fn: () => void, ms: number) {
  timeouts.push(setTimeout(fn, ms))
}

function runAnimation() {
  if (isAnimating.value) return

  clearTimeouts()
  phase.value = 'idle'
  visibleFindings.value = new Set()
  isAnimating.value = true

  if (prefersReducedMotion) {
    const all = new Set<string>()
    props.agents.forEach((agent, i) => {
      agent.findings.forEach((_, j) => all.add(`${i}-${j}`))
    })
    visibleFindings.value = all
    phase.value = 'complete'
    isAnimating.value = false
    return
  }

  const t = timing.value

  later(() => (phase.value = 'task-bubble'), 50)
  later(() => (phase.value = 'spawn-all'), t.taskBubble + 50)
  later(() => (phase.value = 'delegate-all'), t.taskBubble + t.spawnAll + 50)

  const searchStartTime = t.taskBubble + t.spawnAll + t.delegateAll + 50
  later(() => (phase.value = 'searching'), searchStartTime)

  const findingsStartTime = searchStartTime + t.searchingDuration
  later(() => (phase.value = 'findings'), findingsStartTime)

  let findingIndex = 0
  props.agents.forEach((agent, agentIndex) => {
    agent.findings.forEach((_, findingIdx) => {
      const delay = findingsStartTime + findingIndex * t.findingsDelay
      later(() => {
        visibleFindings.value = new Set([...visibleFindings.value, `${agentIndex}-${findingIdx}`])
      }, delay)
      findingIndex++
    })
  })

  const reportTime = findingsStartTime + totalFindings.value * t.findingsDelay + 200
  later(() => (phase.value = 'report-all'), reportTime)
  later(() => (phase.value = 'synthesis'), reportTime + t.reportAll)
  later(() => {
    phase.value = 'complete'
    isAnimating.value = false
  }, reportTime + t.reportAll + t.synthesis)
}

function handleStart() {
  if (phase.value === 'complete') {
    phase.value = 'idle'
    visibleFindings.value = new Set()
    setTimeout(runAnimation, 100)
    return
  }
  if (phase.value === 'idle') {
    runAnimation()
  }
}

onMounted(() => {
  if (props.autoStart && phase.value === 'idle') {
    later(runAnimation, 500)
  }
})

onUnmounted(clearTimeouts)

const buttonLabel = computed(() => {
  if (phase.value === 'idle') return '▶ Start'
  if (phase.value === 'complete') return '↻ Replay'
  return 'Running...'
})

const showTaskBubble = computed(() => isPhaseAtLeast(phase.value, 'task-bubble'))
const showSubagents = computed(() => isPhaseAtLeast(phase.value, 'spawn-all'))
const showDelegateArrows = computed(() => isPhaseAtLeast(phase.value, 'delegate-all'))
const showSearching = computed(() => isPhaseAtLeast(phase.value, 'searching'))
const showDomainBoxes = computed(() => isPhaseAtLeast(phase.value, 'findings'))
const showReportArrows = computed(() => isPhaseAtLeast(phase.value, 'report-all'))
const showSynthesis = computed(() => isPhaseAtLeast(phase.value, 'synthesis'))

function boxHeight(agent: AgentConfig): number {
  return 20 + agent.findings.length * 18
}
function fanOutPath(index: number): string {
  return getFanOutPath(400, mainAgentY, agentPositions[index], subagentY)
}
function fanInPath(agent: AgentConfig, index: number): string {
  return getFanInPath(agentPositions[index], domainBoxY + boxHeight(agent), 400, synthesisY)
}
</script>

<template>
  <div class="parallel-subagent-diagram-animated">
    <svg viewBox="0 0 800 480" class="parallel-subagent-diagram-svg">
      <defs>
        <marker id="parallel-arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
          <polygon points="0 0, 10 3.5, 0 7" class="arrowhead-fill" />
        </marker>
        <marker id="parallel-arrowhead-green" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
          <polygon points="0 0, 10 3.5, 0 7" fill="rgb(34, 197, 94)" />
        </marker>
      </defs>

      <!-- Main Agent -->
      <g class="agent-node main-agent">
        <motion.circle
          :cx="400"
          :cy="mainAgentY"
          :r="45"
          class="agent-circle main"
          :initial="{ scale: 1 }"
          :animate="{ scale: showTaskBubble && !showSubagents ? 1.05 : 1 }"
          :transition="{ duration: 0.2 }"
        />
        <text :x="400" :y="mainAgentY - 8" text-anchor="middle" class="agent-icon">🤖</text>
        <text :x="400" :y="mainAgentY + 15" text-anchor="middle" class="agent-label">Main Agent</text>
      </g>

      <!-- Task Bubble -->
      <AnimatePresence>
        <motion.g
          v-if="showTaskBubble"
          :initial="{ opacity: 0, y: -10 }"
          :animate="{ opacity: 1, y: 0 }"
          :exit="{ opacity: 0 }"
          :transition="{ duration: 0.25 }"
        >
          <rect :x="250" :y="mainAgentY - 65" :width="300" :height="35" :rx="8" class="message-bubble task" />
          <text :x="400" :y="mainAgentY - 42" text-anchor="middle" class="message-text task-text">"{{ task }}"</text>
          <polygon points="400,30 390,5 410,5" class="bubble-pointer task" />
        </motion.g>
      </AnimatePresence>

      <!-- Subagents -->
      <template v-for="(agent, index) in agents" :key="agent.name">
        <AnimatePresence>
          <motion.g
            v-if="showSubagents"
            class="agent-node subagent"
            :initial="{ opacity: 0, scale: 0.5, y: -20 }"
            :animate="{ opacity: 1, scale: 1, y: 0 }"
            :exit="{ opacity: 0, scale: 0.5 }"
            :transition="{ duration: 0.3, type: 'spring', stiffness: 200, delay: index * 0.1 }"
          >
            <circle
              :cx="agentPositions[index]"
              :cy="subagentY"
              :r="35"
              class="agent-circle subagent"
              :style="{ fill: `${agent.color}15`, stroke: agent.color }"
            />
            <text :x="agentPositions[index]" :y="subagentY - 5" text-anchor="middle" class="agent-icon">{{ agent.icon }}</text>
            <text :x="agentPositions[index]" :y="subagentY + 18" text-anchor="middle" class="agent-label">{{ agent.name }}</text>
          </motion.g>
        </AnimatePresence>
      </template>

      <!-- Delegation Arrows (fan-out) -->
      <template v-for="(agent, index) in agents" :key="`delegate-${agent.name}`">
        <AnimatePresence>
          <motion.path
            v-if="showDelegateArrows"
            :d="fanOutPath(index)"
            class="arrow-path delegate"
            :style="{ stroke: agent.color }"
            :initial="{ pathLength: 0, opacity: 0 }"
            :animate="{ pathLength: 1, opacity: 0.8 }"
            :transition="{ duration: 0.25, delay: index * 0.08 }"
            marker-end="url(#parallel-arrowhead)"
          />
        </AnimatePresence>
      </template>

      <!-- Searching indicators -->
      <template v-for="(agent, index) in agents" :key="`search-${agent.name}`">
        <AnimatePresence>
          <motion.text
            v-if="showSearching && !showDomainBoxes"
            :x="agentPositions[index]"
            :y="subagentY + 55"
            text-anchor="middle"
            class="searching-label"
            :style="{ fill: agent.color }"
            :initial="{ opacity: 0 }"
            :animate="{ opacity: [0.5, 1, 0.5] }"
            :transition="{ duration: 1, repeat: Infinity }"
          >searching...</motion.text>
        </AnimatePresence>
      </template>

      <!-- Domain boxes with findings -->
      <template v-for="(agent, agentIndex) in agents" :key="`domain-${agent.name}`">
        <AnimatePresence>
          <motion.g
            v-if="showDomainBoxes"
            :initial="{ opacity: 0, y: 10 }"
            :animate="{ opacity: 1, y: 0 }"
            :exit="{ opacity: 0 }"
            :transition="{ duration: 0.25, delay: agentIndex * 0.1 }"
          >
            <rect
              :x="agentPositions[agentIndex] - 70"
              :y="domainBoxY"
              :width="140"
              :height="boxHeight(agent)"
              :rx="6"
              class="domain-box"
              :style="{ stroke: agent.color, fill: `${agent.color}08` }"
            />
            <text
              :x="agentPositions[agentIndex]"
              :y="domainBoxY + 15"
              text-anchor="middle"
              class="domain-header"
              :style="{ fill: agent.color }"
            >{{ agent.domain }}</text>
            <template v-for="(finding, findingIdx) in agent.findings" :key="`finding-${agentIndex}-${findingIdx}`">
              <AnimatePresence>
                <motion.text
                  v-if="visibleFindings.has(`${agentIndex}-${findingIdx}`)"
                  :x="agentPositions[agentIndex]"
                  :y="domainBoxY + 32 + findingIdx * 18"
                  text-anchor="middle"
                  class="finding-item"
                  :initial="{ opacity: 0, x: -5 }"
                  :animate="{ opacity: 1, x: 0 }"
                  :transition="{ duration: 0.15 }"
                >• {{ finding }}</motion.text>
              </AnimatePresence>
            </template>
          </motion.g>
        </AnimatePresence>
      </template>

      <!-- Report Arrows (fan-in) -->
      <template v-for="(agent, index) in agents" :key="`report-${agent.name}`">
        <AnimatePresence>
          <motion.path
            v-if="showReportArrows"
            :d="fanInPath(agent, index)"
            class="arrow-path report"
            :initial="{ pathLength: 0, opacity: 0 }"
            :animate="{ pathLength: 1, opacity: 1 }"
            :transition="{ duration: 0.3, delay: index * 0.1 }"
            marker-end="url(#parallel-arrowhead-green)"
          />
        </AnimatePresence>
      </template>

      <!-- Synthesis bubble -->
      <AnimatePresence>
        <motion.g
          v-if="showSynthesis"
          :initial="{ opacity: 0, y: 10 }"
          :animate="{ opacity: 1, y: 0 }"
          :exit="{ opacity: 0 }"
          :transition="{ duration: 0.3, type: 'spring', stiffness: 150 }"
        >
          <rect :x="300" :y="synthesisY" :width="200" :height="50" :rx="10" class="message-bubble synthesis" />
          <text :x="400" :y="synthesisY + 25" text-anchor="middle" class="synthesis-icon">📊</text>
          <text :x="400" :y="synthesisY + 42" text-anchor="middle" class="message-text success">
            Combined {{ totalFindings }} sources ✓
          </text>
        </motion.g>
      </AnimatePresence>
    </svg>

    <motion.button
      class="parallel-subagent-diagram-button"
      :disabled="isAnimating"
      :while-hover="{ scale: 1.05 }"
      :while-tap="{ scale: 0.95 }"
      @click="handleStart"
    >
      {{ buttonLabel }}
    </motion.button>
  </div>
</template>

<style scoped>
.parallel-subagent-diagram-animated {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  width: 100%;
  padding: 1rem;
}

.parallel-subagent-diagram-svg {
  width: 100%;
  max-width: 620px; /* 620 * 480/800 = 372px tall — fits a slide with the button */
  height: auto;
  overflow: visible;
}

.parallel-subagent-diagram-svg .agent-circle {
  stroke-width: 3;
  transition: all 0.2s ease;
}
.parallel-subagent-diagram-svg .agent-circle.main {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
}
.parallel-subagent-diagram-svg .agent-circle.subagent {
  stroke-dasharray: 6 3;
}
.parallel-subagent-diagram-svg .agent-icon {
  font-size: 32px;
  pointer-events: none;
}
.parallel-subagent-diagram-svg .agent-label {
  fill: rgb(var(--color-text-base));
  font-size: 15px;
  font-weight: 600;
  pointer-events: none;
}

.parallel-subagent-diagram-svg .message-bubble {
  stroke-width: 2;
  transition: all 0.2s ease;
}
.parallel-subagent-diagram-svg .message-bubble.task {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
}
.parallel-subagent-diagram-svg .message-bubble.synthesis {
  fill: rgba(34, 197, 94, 0.15);
  stroke: rgb(34, 197, 94);
}
.parallel-subagent-diagram-svg .bubble-pointer {
  transition: all 0.2s ease;
}
.parallel-subagent-diagram-svg .bubble-pointer.task {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
  stroke-width: 2;
}
.parallel-subagent-diagram-svg .message-text {
  fill: rgb(var(--color-text-base));
  font-size: 13px;
  pointer-events: none;
}
.parallel-subagent-diagram-svg .message-text.task-text {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}
.parallel-subagent-diagram-svg .message-text.success {
  fill: rgb(34, 197, 94);
  font-weight: 600;
}
.parallel-subagent-diagram-svg .synthesis-icon {
  font-size: 20px;
  pointer-events: none;
}

.parallel-subagent-diagram-svg .arrow-path {
  fill: none;
  stroke-width: 2.5;
  stroke-linecap: round;
}
.parallel-subagent-diagram-svg .arrow-path.delegate {
  stroke-dasharray: none;
}
.parallel-subagent-diagram-svg .arrow-path.report {
  stroke: rgb(34, 197, 94);
  stroke-dasharray: 6 3;
}
.parallel-subagent-diagram-svg .arrowhead-fill {
  fill: rgba(var(--color-text-base), 0.8);
}

.parallel-subagent-diagram-svg .searching-label {
  font-size: 11px;
  font-style: italic;
  pointer-events: none;
}

.parallel-subagent-diagram-svg .domain-box {
  stroke-width: 2;
  transition: all 0.2s ease;
}
.parallel-subagent-diagram-svg .domain-header {
  font-size: 14px;
  font-weight: 600;
  pointer-events: none;
}
.parallel-subagent-diagram-svg .finding-item {
  fill: rgba(var(--color-text-base), 0.85);
  font-size: 12px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  pointer-events: none;
}

.parallel-subagent-diagram-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem 2rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: white;
  background: linear-gradient(135deg, rgb(var(--color-accent)), rgba(var(--color-accent), 0.8));
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(var(--color-accent), 0.3);
}
.parallel-subagent-diagram-button:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(var(--color-accent), 0.4);
}
.parallel-subagent-diagram-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (prefers-reduced-motion: reduce) {
  .parallel-subagent-diagram-animated * {
    transition: none !important;
    animation: none !important;
  }
}
</style>
