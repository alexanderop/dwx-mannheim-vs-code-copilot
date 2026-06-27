<script lang="ts">
/**
 * NestedSubagentDiagram - Interactive nested orchestration animation.
 *
 * The main chat writes a spec.md, hands it to an Orchestrator subagent, and the
 * orchestrator spawns ONE implementation subagent per acceptance criterion (AC).
 * This shows the nested fan-out: main -> orchestrator -> N implementers.
 * Sibling of ParallelSubagentDiagram, same visual language.
 */
export interface Criterion {
  id: string
  title: string
  icon: string
  color: string
}

// Module scope so withDefaults' default factory can reference it.
export const defaultCriteria: Criterion[] = [
  { id: 'AC1', title: 'Login form', icon: '🎨', color: '#3b82f6' },
  { id: 'AC2', title: 'Auth API', icon: '🔌', color: '#8b5cf6' },
  { id: 'AC3', title: 'Unit tests', icon: '🧪', color: '#10b981' },
]
</script>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { motion, AnimatePresence } from 'motion-v'

const props = withDefaults(
  defineProps<{
    task?: string
    criteria?: Criterion[]
    autoStart?: boolean
    speed?: number
  }>(),
  {
    task: 'Build user authentication',
    criteria: () => defaultCriteria,
    autoStart: false,
    speed: 0.6,
  },
)

type Phase =
  | 'idle'
  | 'task-bubble'
  | 'write-spec'
  | 'spawn-orch'
  | 'read-spec'
  | 'spawn-impl'
  | 'implementing'
  | 'done'
  | 'report'
  | 'complete'

const PHASE_ORDER: Phase[] = [
  'idle', 'task-bubble', 'write-spec', 'spawn-orch', 'read-spec',
  'spawn-impl', 'implementing', 'done', 'report', 'complete',
]

function isPhaseAtLeast(current: Phase, threshold: Phase): boolean {
  return PHASE_ORDER.indexOf(current) >= PHASE_ORDER.indexOf(threshold)
}

// --- Layout ----------------------------------------------------------------
const mainX = 400
const mainAgentY = 70
const specTop = 150
const specWidth = 220
const specRowH = 22
const orchY = 320
const implY = 470
const implPositions = [150, 400, 650]

const specHeight = computed(() => 34 + props.criteria.length * specRowH)
const specBottom = computed(() => specTop + specHeight.value)

function getFanOutPath(sx: number, sy: number, tx: number, ty: number): string {
  const midY = (sy + ty) / 2
  const cpX = tx + (sx - tx) * 0.3
  return `M${sx},${sy} Q${cpX},${midY} ${tx},${ty}`
}

function getFanInPath(sx: number, sy: number, tx: number, ty: number): string {
  const midY = (sy + ty) / 2 + 20
  const cpX = sx + (tx - sx) * 0.3
  return `M${sx},${sy} Q${cpX},${midY} ${tx},${ty}`
}

// --- State -----------------------------------------------------------------
const phase = ref<Phase>('idle')
const isAnimating = ref(false)
const visibleDone = ref<Set<number>>(new Set())

const prefersReducedMotion =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

const timing = computed(() => ({
  taskBubble: 400 / props.speed,
  writeSpec: 600 / props.speed,
  spawnOrch: 400 / props.speed,
  readSpec: 600 / props.speed,
  spawnImpl: 400 / props.speed,
  implementing: 800 / props.speed,
  doneStagger: 250 / props.speed,
  report: 500 / props.speed,
}))

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
  visibleDone.value = new Set()
  isAnimating.value = true

  if (prefersReducedMotion) {
    visibleDone.value = new Set(props.criteria.map((_, i) => i))
    phase.value = 'complete'
    isAnimating.value = false
    return
  }

  const t = timing.value
  let at = 50

  later(() => (phase.value = 'task-bubble'), at)
  at += t.taskBubble
  later(() => (phase.value = 'write-spec'), at)
  at += t.writeSpec
  later(() => (phase.value = 'spawn-orch'), at)
  at += t.spawnOrch
  later(() => (phase.value = 'read-spec'), at)
  at += t.readSpec
  later(() => (phase.value = 'spawn-impl'), at)
  at += t.spawnImpl
  later(() => (phase.value = 'implementing'), at)
  at += t.implementing

  const doneStart = at
  later(() => (phase.value = 'done'), doneStart)
  props.criteria.forEach((_, i) => {
    later(() => {
      visibleDone.value = new Set([...visibleDone.value, i])
    }, doneStart + i * t.doneStagger)
  })
  at = doneStart + props.criteria.length * t.doneStagger + 200

  later(() => (phase.value = 'report'), at)
  at += t.report
  later(() => {
    phase.value = 'complete'
    isAnimating.value = false
  }, at)
}

function handleStart() {
  if (phase.value === 'complete') {
    phase.value = 'idle'
    visibleDone.value = new Set()
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

// --- Derived visibility ----------------------------------------------------
const showTaskBubble = computed(() => isPhaseAtLeast(phase.value, 'task-bubble'))
const showSpec = computed(() => isPhaseAtLeast(phase.value, 'write-spec'))
const showOrch = computed(() => isPhaseAtLeast(phase.value, 'spawn-orch'))
const showReadSpec = computed(() => isPhaseAtLeast(phase.value, 'read-spec'))
const showImpl = computed(() => isPhaseAtLeast(phase.value, 'spawn-impl'))
const showImplementing = computed(() => isPhaseAtLeast(phase.value, 'implementing'))
const showReport = computed(() => isPhaseAtLeast(phase.value, 'report'))
const showResult = computed(() => isPhaseAtLeast(phase.value, 'complete'))

function fanOutPath(index: number): string {
  return getFanOutPath(mainX, orchY + 40, implPositions[index], implY - 38)
}
function fanInPath(index: number): string {
  return getFanInPath(implPositions[index], implY - 38, mainX, orchY + 40)
}
</script>

<template>
  <div class="nested-subagent-diagram-animated">
    <svg viewBox="0 0 800 560" class="nested-subagent-diagram-svg">
      <defs>
        <marker id="nested-arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
          <polygon points="0 0, 10 3.5, 0 7" class="arrowhead-fill" />
        </marker>
        <marker id="nested-arrowhead-green" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
          <polygon points="0 0, 10 3.5, 0 7" fill="rgb(34, 197, 94)" />
        </marker>
      </defs>

      <!-- Main Agent -->
      <g class="agent-node main-agent">
        <motion.circle
          :cx="mainX"
          :cy="mainAgentY"
          :r="40"
          class="agent-circle main"
          :initial="{ scale: 1 }"
          :animate="{ scale: showTaskBubble && !showSpec ? 1.05 : 1 }"
          :transition="{ duration: 0.2 }"
        />
        <text :x="mainX" :y="mainAgentY - 6" text-anchor="middle" class="agent-icon">💬</text>
        <text :x="mainX" :y="mainAgentY + 16" text-anchor="middle" class="agent-label">Main Chat</text>
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
          <rect :x="mainX - 150" :y="mainAgentY - 62" :width="300" :height="32" :rx="8" class="message-bubble task" />
          <text :x="mainX" :y="mainAgentY - 41" text-anchor="middle" class="message-text task-text">"{{ task }}"</text>
          <polygon :points="`${mainX},32 ${mainX - 10},8 ${mainX + 10},8`" class="bubble-pointer task" />
        </motion.g>
      </AnimatePresence>

      <!-- spec.md document -->
      <AnimatePresence>
        <motion.g
          v-if="showSpec"
          :initial="{ opacity: 0, scale: 0.8, y: -10 }"
          :animate="{ opacity: 1, scale: 1, y: 0 }"
          :exit="{ opacity: 0 }"
          :transition="{ duration: 0.3, type: 'spring', stiffness: 180 }"
        >
          <!-- connector main -> spec -->
          <line :x1="mainX" :y1="mainAgentY + 40" :x2="mainX" :y2="specTop" class="connector" />
          <rect
            :x="mainX - specWidth / 2"
            :y="specTop"
            :width="specWidth"
            :height="specHeight"
            :rx="8"
            class="spec-doc"
          />
          <text :x="mainX - specWidth / 2 + 12" :y="specTop + 20" class="spec-title">📄 spec.md</text>
          <line
            :x1="mainX - specWidth / 2 + 10"
            :y1="specTop + 28"
            :x2="mainX + specWidth / 2 - 10"
            :y2="specTop + 28"
            class="spec-divider"
          />
          <template v-for="(c, i) in criteria" :key="`spec-${c.id}`">
            <text
              :x="mainX - specWidth / 2 + 14"
              :y="specTop + 46 + i * specRowH"
              class="spec-row"
              :style="{ fill: c.color }"
            >☐ {{ c.id }}: {{ c.title }}</text>
          </template>
        </motion.g>
      </AnimatePresence>

      <!-- spec -> orchestrator connector -->
      <AnimatePresence>
        <motion.line
          v-if="showOrch"
          :x1="mainX"
          :y1="specBottom"
          :x2="mainX"
          :y2="orchY - 40"
          class="arrow-path delegate"
          :initial="{ pathLength: 0, opacity: 0 }"
          :animate="{ pathLength: 1, opacity: 0.8 }"
          :transition="{ duration: 0.3 }"
          marker-end="url(#nested-arrowhead)"
        />
      </AnimatePresence>

      <!-- Orchestrator subagent -->
      <AnimatePresence>
        <motion.g
          v-if="showOrch"
          class="agent-node subagent"
          :initial="{ opacity: 0, scale: 0.5 }"
          :animate="{ opacity: 1, scale: 1 }"
          :exit="{ opacity: 0, scale: 0.5 }"
          :transition="{ duration: 0.3, type: 'spring', stiffness: 200 }"
        >
          <circle :cx="mainX" :cy="orchY" :r="40" class="agent-circle orchestrator" />
          <text :x="mainX" :y="orchY - 6" text-anchor="middle" class="agent-icon">🧭</text>
          <text :x="mainX" :y="orchY + 16" text-anchor="middle" class="agent-label">Orchestrator</text>
        </motion.g>
      </AnimatePresence>

      <!-- reading spec indicator -->
      <AnimatePresence>
        <motion.text
          v-if="showReadSpec && !showImpl"
          :x="mainX"
          :y="orchY + 60"
          text-anchor="middle"
          class="status-label reading"
          :initial="{ opacity: 0 }"
          :animate="{ opacity: [0.5, 1, 0.5] }"
          :transition="{ duration: 1, repeat: Infinity }"
        >reading spec.md...</motion.text>
      </AnimatePresence>

      <!-- Delegation arrows (orchestrator fan-out, one per AC) -->
      <template v-for="(c, index) in criteria" :key="`delegate-${c.id}`">
        <AnimatePresence>
          <motion.g v-if="showImpl">
            <motion.path
              :d="fanOutPath(index)"
              class="arrow-path delegate"
              :style="{ stroke: c.color }"
              :initial="{ pathLength: 0, opacity: 0 }"
              :animate="{ pathLength: 1, opacity: 0.85 }"
              :transition="{ duration: 0.3, delay: index * 0.1 }"
              marker-end="url(#nested-arrowhead)"
            />
            <motion.text
              :x="(mainX + implPositions[index]) / 2"
              :y="(orchY + 40 + implY - 38) / 2 - 6"
              text-anchor="middle"
              class="ac-tag"
              :style="{ fill: c.color }"
              :initial="{ opacity: 0 }"
              :animate="{ opacity: 1 }"
              :transition="{ duration: 0.2, delay: index * 0.1 + 0.15 }"
            >{{ c.id }}</motion.text>
          </motion.g>
        </AnimatePresence>
      </template>

      <!-- Implementation subagents -->
      <template v-for="(c, index) in criteria" :key="`impl-${c.id}`">
        <AnimatePresence>
          <motion.g
            v-if="showImpl"
            class="agent-node subagent"
            :initial="{ opacity: 0, scale: 0.5, y: -10 }"
            :animate="{ opacity: 1, scale: 1, y: 0 }"
            :exit="{ opacity: 0, scale: 0.5 }"
            :transition="{ duration: 0.3, type: 'spring', stiffness: 200, delay: index * 0.1 }"
          >
            <circle
              :cx="implPositions[index]"
              :cy="implY"
              :r="34"
              class="agent-circle impl"
              :style="{ fill: `${c.color}15`, stroke: c.color }"
            />
            <text :x="implPositions[index]" :y="implY - 4" text-anchor="middle" class="agent-icon small">{{ c.icon }}</text>
            <text :x="implPositions[index]" :y="implY + 16" text-anchor="middle" class="agent-label small">{{ c.title }}</text>

            <!-- status under each impl -->
            <motion.text
              v-if="visibleDone.has(index)"
              :x="implPositions[index]"
              :y="implY + 56"
              text-anchor="middle"
              class="status-label done"
              :initial="{ opacity: 0, scale: 0.8 }"
              :animate="{ opacity: 1, scale: 1 }"
              :transition="{ duration: 0.2, type: 'spring', stiffness: 250 }"
            >✓ done</motion.text>
            <motion.text
              v-else-if="showImplementing"
              :x="implPositions[index]"
              :y="implY + 56"
              text-anchor="middle"
              class="status-label working"
              :style="{ fill: c.color }"
              :initial="{ opacity: 0 }"
              :animate="{ opacity: [0.5, 1, 0.5] }"
              :transition="{ duration: 0.9, repeat: Infinity }"
            >implementing...</motion.text>
          </motion.g>
        </AnimatePresence>
      </template>

      <!-- Report arrows (impl -> orchestrator) -->
      <template v-for="(c, index) in criteria" :key="`report-${c.id}`">
        <AnimatePresence>
          <motion.path
            v-if="showReport"
            :d="fanInPath(index)"
            class="arrow-path report"
            :initial="{ pathLength: 0, opacity: 0 }"
            :animate="{ pathLength: 1, opacity: 1 }"
            :transition="{ duration: 0.3, delay: index * 0.08 }"
            marker-end="url(#nested-arrowhead-green)"
          />
        </AnimatePresence>
      </template>

      <!-- Result bubble -->
      <AnimatePresence>
        <motion.g
          v-if="showResult"
          :initial="{ opacity: 0, scale: 0.8 }"
          :animate="{ opacity: 1, scale: 1 }"
          :exit="{ opacity: 0 }"
          :transition="{ duration: 0.3, type: 'spring', stiffness: 160 }"
        >
          <rect :x="mainX + 60" :y="orchY - 22" :width="200" :height="44" :rx="10" class="message-bubble synthesis" />
          <text :x="mainX + 160" :y="orchY + 6" text-anchor="middle" class="message-text success">
            {{ criteria.length }}/{{ criteria.length }} ACs shipped ✓
          </text>
        </motion.g>
      </AnimatePresence>
    </svg>

    <motion.button
      class="nested-subagent-diagram-button"
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
.nested-subagent-diagram-animated {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.25rem;
  width: 100%;
  padding: 0.5rem;
}

.nested-subagent-diagram-svg {
  width: 100%;
  max-width: 560px;
  height: auto;
  overflow: visible;
}

.nested-subagent-diagram-svg .agent-circle {
  stroke-width: 3;
  transition: all 0.2s ease;
}
.nested-subagent-diagram-svg .agent-circle.main {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
}
.nested-subagent-diagram-svg .agent-circle.orchestrator {
  fill: rgba(245, 158, 11, 0.15);
  stroke: rgb(245, 158, 11);
}
.nested-subagent-diagram-svg .agent-circle.impl {
  stroke-dasharray: 6 3;
}
.nested-subagent-diagram-svg .agent-icon {
  font-size: 30px;
  pointer-events: none;
}
.nested-subagent-diagram-svg .agent-icon.small {
  font-size: 26px;
}
.nested-subagent-diagram-svg .agent-label {
  fill: rgb(var(--color-text-base));
  font-size: 15px;
  font-weight: 600;
  pointer-events: none;
}
.nested-subagent-diagram-svg .agent-label.small {
  font-size: 13px;
}

.nested-subagent-diagram-svg .connector {
  stroke: rgba(var(--color-text-base), 0.3);
  stroke-width: 2;
  stroke-dasharray: 4 3;
}

.nested-subagent-diagram-svg .spec-doc {
  fill: rgba(var(--color-text-base), 0.04);
  stroke: rgba(var(--color-text-base), 0.4);
  stroke-width: 2;
}
.nested-subagent-diagram-svg .spec-title {
  fill: rgb(var(--color-text-base));
  font-size: 14px;
  font-weight: 700;
  pointer-events: none;
}
.nested-subagent-diagram-svg .spec-divider {
  stroke: rgba(var(--color-text-base), 0.2);
  stroke-width: 1;
}
.nested-subagent-diagram-svg .spec-row {
  font-size: 13px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  pointer-events: none;
}

.nested-subagent-diagram-svg .message-bubble {
  stroke-width: 2;
  transition: all 0.2s ease;
}
.nested-subagent-diagram-svg .message-bubble.task {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
}
.nested-subagent-diagram-svg .message-bubble.synthesis {
  fill: rgba(34, 197, 94, 0.15);
  stroke: rgb(34, 197, 94);
}
.nested-subagent-diagram-svg .bubble-pointer.task {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
  stroke-width: 2;
}
.nested-subagent-diagram-svg .message-text {
  fill: rgb(var(--color-text-base));
  font-size: 13px;
  pointer-events: none;
}
.nested-subagent-diagram-svg .message-text.task-text {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}
.nested-subagent-diagram-svg .message-text.success {
  fill: rgb(34, 197, 94);
  font-weight: 600;
}

.nested-subagent-diagram-svg .arrow-path {
  fill: none;
  stroke-width: 2.5;
  stroke-linecap: round;
}
.nested-subagent-diagram-svg .arrow-path.report {
  stroke: rgb(34, 197, 94);
  stroke-dasharray: 6 3;
}
.nested-subagent-diagram-svg .arrowhead-fill {
  fill: rgba(var(--color-text-base), 0.8);
}

.nested-subagent-diagram-svg .ac-tag {
  font-size: 12px;
  font-weight: 700;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  pointer-events: none;
}

.nested-subagent-diagram-svg .status-label {
  font-size: 12px;
  pointer-events: none;
}
.nested-subagent-diagram-svg .status-label.reading,
.nested-subagent-diagram-svg .status-label.working {
  font-style: italic;
}
.nested-subagent-diagram-svg .status-label.reading {
  fill: rgb(245, 158, 11);
}
.nested-subagent-diagram-svg .status-label.done {
  fill: rgb(34, 197, 94);
  font-weight: 700;
}

.nested-subagent-diagram-button {
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
.nested-subagent-diagram-button:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(var(--color-accent), 0.4);
}
.nested-subagent-diagram-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (prefers-reduced-motion: reduce) {
  .nested-subagent-diagram-animated * {
    transition: none !important;
    animation: none !important;
  }
}
</style>
