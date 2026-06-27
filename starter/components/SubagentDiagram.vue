<script setup lang="ts">
/**
 * SubagentDiagram - Interactive animated diagram for the Explore subagent.
 *
 * Main agent -> spawns Explore subagent -> reads files into the subagent's
 * context -> reports a compact summary back. Self-contained Start/Replay button.
 * Vue port of the original React + framer-motion renderer.
 */
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { motion, AnimatePresence } from 'motion-v'

const props = withDefaults(
  defineProps<{
    task?: string
    files?: string[]
    autoStart?: boolean
    speed?: number
  }>(),
  {
    task: 'Find auth files',
    files: () => ['Auth.tsx', 'auth.ts', 'authService.ts'],
    autoStart: false,
    speed: 0.6,
  },
)

type Phase =
  | 'idle'
  | 'task-bubble'
  | 'spawn-subagent'
  | 'delegate-arrow'
  | 'searching'
  | 'read-files'
  | 'report-arrow'
  | 'summary-bubble'
  | 'complete'

const PHASE_ORDER: Phase[] = [
  'idle', 'task-bubble', 'spawn-subagent', 'delegate-arrow',
  'searching', 'read-files', 'report-arrow', 'summary-bubble', 'complete',
]

function isPhaseAtLeast(current: Phase, threshold: Phase): boolean {
  return PHASE_ORDER.indexOf(current) >= PHASE_ORDER.indexOf(threshold)
}

interface ReadCallState {
  file: string
  status: 'pending' | 'reading' | 'complete'
}

interface FileNode {
  path: string
  type: 'folder' | 'file'
  depth: number
  highlight?: boolean
}

function buildFileTree(highlightFiles: string[]): FileNode[] {
  return [
    { path: 'src/', type: 'folder', depth: 0 },
    { path: 'components/', type: 'folder', depth: 1 },
    { path: 'Auth.tsx', type: 'file', depth: 2, highlight: highlightFiles.includes('Auth.tsx') },
    { path: 'Button.tsx', type: 'file', depth: 2 },
    { path: 'utils/', type: 'folder', depth: 1 },
    { path: 'auth.ts', type: 'file', depth: 2, highlight: highlightFiles.includes('auth.ts') },
    { path: 'helpers.ts', type: 'file', depth: 2 },
    { path: 'services/', type: 'folder', depth: 1 },
    { path: 'authService.ts', type: 'file', depth: 2, highlight: highlightFiles.includes('authService.ts') },
  ]
}

const phase = ref<Phase>('idle')
const highlightedFiles = ref<Set<string>>(new Set())
const isAnimating = ref(false)
const readCalls = ref<ReadCallState[]>([])
const contextUsage = ref(0)

const prefersReducedMotion =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

const fileTree = computed(() => buildFileTree(props.files))
const filesToHighlight = computed(() =>
  fileTree.value.filter(f => f.highlight).map(f => f.path),
)

const timing = computed(() => ({
  taskBubble: 300 / props.speed,
  spawnSubagent: 300 / props.speed,
  delegateArrow: 200 / props.speed,
  searchDelay: 400 / props.speed,
  readCallDelay: 600 / props.speed,
  fileHighlight: 200 / props.speed,
  reportArrow: 300 / props.speed,
  summaryBubble: 400 / props.speed,
}))

let timeouts: ReturnType<typeof setTimeout>[] = []
function clearTimeouts() {
  timeouts.forEach(clearTimeout)
  timeouts = []
}
function later(fn: () => void, ms: number) {
  timeouts.push(setTimeout(fn, ms))
}

function skipToComplete() {
  highlightedFiles.value = new Set(filesToHighlight.value)
  readCalls.value = filesToHighlight.value.map(f => ({ file: f, status: 'complete' as const }))
  contextUsage.value = 100
  phase.value = 'complete'
  isAnimating.value = false
}

function runAnimation() {
  if (isAnimating.value) return

  clearTimeouts()
  highlightedFiles.value = new Set()
  readCalls.value = []
  contextUsage.value = 0
  phase.value = 'idle'
  isAnimating.value = true

  if (prefersReducedMotion) {
    skipToComplete()
    return
  }

  const t = timing.value
  const files = filesToHighlight.value

  later(() => (phase.value = 'task-bubble'), 50)
  later(() => (phase.value = 'spawn-subagent'), t.taskBubble + 50)
  later(() => (phase.value = 'delegate-arrow'), t.taskBubble + t.spawnSubagent + 50)

  const searchStartTime = t.taskBubble + t.spawnSubagent + t.delegateArrow + 50
  later(() => (phase.value = 'searching'), searchStartTime)

  const readFilesStartTime = searchStartTime + t.searchDelay
  later(() => (phase.value = 'read-files'), readFilesStartTime)

  files.forEach((file, index) => {
    later(() => {
      readCalls.value = [...readCalls.value, { file, status: 'reading' }]
    }, readFilesStartTime + index * t.readCallDelay)

    later(() => {
      highlightedFiles.value = new Set([...highlightedFiles.value, file])
    }, readFilesStartTime + index * t.readCallDelay + t.fileHighlight)

    later(() => {
      readCalls.value = readCalls.value.map(rc =>
        rc.file === file ? { ...rc, status: 'complete' as const } : rc,
      )
      contextUsage.value = Math.min(100, ((index + 1) / files.length) * 85 + 10)
    }, readFilesStartTime + index * t.readCallDelay + t.fileHighlight + 100)
  })

  const reportTime =
    readFilesStartTime + files.length * t.readCallDelay + t.fileHighlight + 200
  later(() => (phase.value = 'report-arrow'), reportTime)
  later(() => (phase.value = 'summary-bubble'), reportTime + t.reportArrow)
  later(() => {
    phase.value = 'complete'
    isAnimating.value = false
  }, reportTime + t.reportArrow + t.summaryBubble)
}

function resetState() {
  phase.value = 'idle'
  highlightedFiles.value = new Set()
  readCalls.value = []
  contextUsage.value = 0
}

function handleStart() {
  if (phase.value === 'complete') {
    resetState()
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
const showSubagent = computed(() => isPhaseAtLeast(phase.value, 'spawn-subagent'))
const showDelegateArrow = computed(() => isPhaseAtLeast(phase.value, 'delegate-arrow'))
const showSearchArrow = computed(() => isPhaseAtLeast(phase.value, 'searching'))
const showContextWindow = computed(() => isPhaseAtLeast(phase.value, 'read-files'))
const showReportArrow = computed(() => isPhaseAtLeast(phase.value, 'report-arrow'))
const showSummaryBubble = computed(() => isPhaseAtLeast(phase.value, 'summary-bubble'))

const contextBoxHeight = computed(() =>
  readCalls.value.length > 0 ? 70 + readCalls.value.length * 16 : 70,
)

function nodeIcon(node: FileNode): string {
  return node.type === 'folder' ? '📁' : '📄'
}
</script>

<template>
  <div class="subagent-diagram-animated">
    <svg viewBox="0 0 620 420" class="subagent-diagram-svg-animated">
      <defs>
        <marker id="arrowhead-animated" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
          <polygon points="0 0, 10 3.5, 0 7" class="arrowhead-fill" />
        </marker>
      </defs>

      <!-- Main Agent -->
      <g class="agent-node main-agent">
        <motion.circle
          :cx="100"
          :cy="80"
          :r="45"
          class="agent-circle main"
          :initial="{ scale: 1 }"
          :animate="{ scale: showTaskBubble && !showSubagent ? 1.05 : 1 }"
          :transition="{ duration: 0.2 }"
        />
        <text :x="100" :y="72" text-anchor="middle" class="agent-icon">🤖</text>
        <text :x="100" :y="95" text-anchor="middle" class="agent-label">Main Agent</text>
      </g>

      <!-- Task Bubble -->
      <AnimatePresence>
        <motion.g
          v-if="showTaskBubble"
          :initial="{ opacity: 0, x: -10 }"
          :animate="{ opacity: 1, x: 0 }"
          :exit="{ opacity: 0 }"
          :transition="{ duration: 0.2 }"
        >
          <rect :x="155" :y="55" :width="140" :height="35" :rx="8" class="message-bubble task" />
          <text :x="225" :y="78" text-anchor="middle" class="message-text">"{{ task }}"</text>
          <polygon points="155,70 145,75 155,80" class="bubble-pointer task" />
        </motion.g>
      </AnimatePresence>

      <!-- Explore Subagent -->
      <AnimatePresence>
        <motion.g
          v-if="showSubagent"
          class="agent-node explore-agent"
          :initial="{ opacity: 0, scale: 0.5, y: -20 }"
          :animate="{ opacity: 1, scale: 1, y: 0 }"
          :exit="{ opacity: 0, scale: 0.5 }"
          :transition="{ duration: 0.3, type: 'spring', stiffness: 200 }"
        >
          <circle :cx="100" :cy="230" :r="40" class="agent-circle explore" />
          <text :x="100" :y="222" text-anchor="middle" class="agent-icon">🔍</text>
          <text :x="100" :y="245" text-anchor="middle" class="agent-label">Explore</text>
          <text :x="100" :y="260" text-anchor="middle" class="agent-sublabel">Subagent</text>
        </motion.g>
      </AnimatePresence>

      <!-- Delegation Arrow -->
      <AnimatePresence>
        <motion.g v-if="showDelegateArrow">
          <motion.path
            d="M100,130 L100,185"
            class="arrow-path delegate"
            :initial="{ pathLength: 0, opacity: 0 }"
            :animate="{ pathLength: 1, opacity: 1 }"
            :transition="{ duration: 0.2 }"
            marker-end="url(#arrowhead-animated)"
          />
          <motion.text
            :x="115" :y="158" class="arrow-label"
            :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :transition="{ delay: 0.1 }"
          >spawn</motion.text>
        </motion.g>
      </AnimatePresence>

      <!-- Context Window Box -->
      <AnimatePresence>
        <template v-if="showContextWindow">
          <motion.path
            d="M100,272 L100,288"
            class="arrow-path delegate"
            stroke-dasharray="3 2"
            :initial="{ opacity: 0 }"
            :animate="{ opacity: 0.5 }"
            :exit="{ opacity: 0 }"
          />
          <!-- Static translate stays on a plain <g>; motion-v's animated `y`
               would otherwise clobber an SVG transform attribute on the same node. -->
          <g transform="translate(30, 290)">
          <motion.g
            :initial="{ opacity: 0, y: 10 }"
            :animate="{ opacity: 1, y: 0 }"
            :exit="{ opacity: 0 }"
            :transition="{ duration: 0.25 }"
          >
            <rect :x="0" :y="0" :width="180" :height="contextBoxHeight" class="context-window-box" :rx="6" />

            <text :x="10" :y="18" class="context-window-header">
              <tspan class="context-window-header-icon">📋</tspan>
              {{ ' Subagent Context' }}
            </text>

            <line :x1="8" :y1="26" :x2="172" :y2="26" class="context-divider" />

            <motion.g
              v-for="(rc, index) in readCalls"
              :key="rc.file"
              :initial="{ opacity: 0, x: -5 }"
              :animate="{ opacity: 1, x: 0 }"
              :transition="{ duration: 0.15 }"
            >
              <text
                :x="12" :y="42 + index * 16"
                :class="['context-read-entry', rc.status === 'reading' ? 'active' : '']"
              >{{ rc.status === 'reading' ? '→ ' : '> ' }}Read({{ rc.file }})</text>
              <motion.text
                v-if="rc.status === 'complete'"
                :x="160" :y="42 + index * 16" class="context-checkmark"
                :initial="{ scale: 0 }" :animate="{ scale: 1 }" :transition="{ type: 'spring', stiffness: 400 }"
              >✓</motion.text>
            </motion.g>

            <g v-if="readCalls.length > 0" :transform="`translate(8, ${50 + readCalls.length * 16})`">
              <text :x="0" :y="0" class="context-progress-label">Context:</text>
              <rect :x="50" :y="-8" :width="115" :height="10" class="context-progress-track" />
              <motion.rect
                :x="50" :y="-8" :height="10" class="context-progress-bar"
                :initial="{ width: 0 }"
                :animate="{ width: (contextUsage / 100) * 115 }"
                :transition="{ duration: 0.2 }"
              />
            </g>
          </motion.g>
          </g>
        </template>
      </AnimatePresence>

      <!-- File Tree -->
      <g class="file-tree" transform="translate(340, 50)">
        <text :x="0" :y="0" class="tree-header">File Tree</text>
        <line :x1="0" :y1="10" :x2="180" :y2="10" class="tree-header-line" />
        <motion.g
          v-for="(node, index) in fileTree"
          :key="node.path"
          :initial="{ opacity: 0.7 }"
          :animate="{
            opacity: highlightedFiles.has(node.path) ? 1 : 0.7,
            scale: highlightedFiles.has(node.path) ? 1.02 : 1,
            x: highlightedFiles.has(node.path) ? 3 : 0,
          }"
          :transition="{ duration: 0.15 }"
        >
          <text
            :x="node.depth * 16"
            :y="35 + index * 26"
            :class="['tree-node', node.type, highlightedFiles.has(node.path) ? 'highlighted' : '']"
          >{{ nodeIcon(node) }} {{ node.path }}</text>
          <motion.circle
            v-if="highlightedFiles.has(node.path)"
            :cx="node.depth * 16 - 8"
            :cy="35 + index * 26 - 4"
            :r="4"
            class="highlight-dot"
            :initial="{ scale: 0 }"
            :animate="{ scale: 1 }"
            :transition="{ type: 'spring', stiffness: 300 }"
          />
        </motion.g>
      </g>

      <!-- Search Arrow -->
      <AnimatePresence>
        <motion.g v-if="showSearchArrow">
          <motion.path
            d="M145,220 Q250,220 320,150"
            class="arrow-path search"
            :initial="{ pathLength: 0, opacity: 0 }"
            :animate="{ pathLength: 1, opacity: 1 }"
            :transition="{ duration: 0.3 }"
            marker-end="url(#arrowhead-animated)"
          />
          <motion.text
            :x="220" :y="235" class="arrow-label search"
            :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :transition="{ delay: 0.15 }"
          >searching...</motion.text>
        </motion.g>
      </AnimatePresence>

      <!-- Report Arrow -->
      <AnimatePresence>
        <motion.g v-if="showReportArrow">
          <motion.path
            d="M60,215 Q20,150 60,95"
            class="arrow-path report"
            :initial="{ pathLength: 0, opacity: 0 }"
            :animate="{ pathLength: 1, opacity: 1 }"
            :transition="{ duration: 0.25 }"
            marker-end="url(#arrowhead-animated)"
          />
          <motion.text
            :x="15" :y="155" class="arrow-label"
            :initial="{ opacity: 0 }" :animate="{ opacity: 1 }" :transition="{ delay: 0.1 }"
          >report</motion.text>
        </motion.g>
      </AnimatePresence>

      <!-- Summary Bubble -->
      <AnimatePresence>
        <motion.g
          v-if="showSummaryBubble"
          :initial="{ opacity: 0, y: 10 }"
          :animate="{ opacity: 1, y: 0 }"
          :exit="{ opacity: 0 }"
          :transition="{ duration: 0.25, type: 'spring', stiffness: 150 }"
        >
          <rect :x="155" :y="95" :width="175" :height="45" :rx="8" class="message-bubble summary" />
          <text :x="242" :y="113" text-anchor="middle" class="message-text success">
            Found {{ files.length }} files ✓
          </text>
          <text :x="242" :y="130" text-anchor="middle" class="message-text" style="font-size: 10px; opacity: 0.7">
            (just summary, not content!)
          </text>
          <polygon points="155,112 145,117 155,122" class="bubble-pointer summary" />
        </motion.g>
      </AnimatePresence>
    </svg>

    <motion.button
      class="subagent-diagram-button"
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
.subagent-diagram-animated {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  width: 100%;
  padding: 1rem;
}

.subagent-diagram-svg-animated {
  width: 100%;
  max-width: 540px; /* 540 * 420/620 ≈ 366px tall — fits a slide with the button */
  height: auto;
  overflow: visible;
}

.agent-circle {
  stroke-width: 3;
  transition: all 0.2s ease;
}
.agent-circle.main {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
}
.agent-circle.explore {
  fill: rgba(var(--color-accent), 0.08);
  stroke: rgba(var(--color-accent), 0.85);
  stroke-dasharray: 6 3;
}
.agent-icon {
  font-size: 32px;
  pointer-events: none;
}
.agent-label {
  fill: rgb(var(--color-text-base));
  font-size: 15px;
  font-weight: 600;
  pointer-events: none;
}
.agent-sublabel {
  fill: rgba(var(--color-text-base), 0.75);
  font-size: 11px;
  pointer-events: none;
}

.message-bubble {
  stroke-width: 2;
  transition: all 0.2s ease;
}
.message-bubble.task {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
}
.message-bubble.summary {
  fill: rgba(34, 197, 94, 0.15);
  stroke: rgb(34, 197, 94);
}
.bubble-pointer {
  transition: all 0.2s ease;
}
.bubble-pointer.task {
  fill: rgba(var(--color-accent), 0.15);
  stroke: rgb(var(--color-accent));
  stroke-width: 2;
}
.bubble-pointer.summary {
  fill: rgba(34, 197, 94, 0.15);
  stroke: rgb(34, 197, 94);
  stroke-width: 2;
}
.message-text {
  fill: rgb(var(--color-text-base));
  font-size: 13px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  pointer-events: none;
}
.message-text.success {
  fill: rgb(34, 197, 94);
  font-weight: 600;
}

.arrow-path {
  fill: none;
  stroke-width: 2.5;
  stroke-linecap: round;
}
.arrow-path.delegate {
  stroke: rgba(var(--color-accent), 0.8);
}
.arrow-path.search {
  stroke: rgba(var(--color-accent), 0.7);
  stroke-dasharray: 8 4;
}
.arrow-path.report {
  stroke: rgb(34, 197, 94);
  stroke-dasharray: 6 3;
}
.arrow-label {
  fill: rgba(var(--color-text-base), 0.85);
  font-size: 11px;
  font-style: italic;
  pointer-events: none;
}
.arrow-label.search {
  fill: rgba(var(--color-accent), 0.8);
  font-weight: 500;
}
.arrowhead-fill {
  fill: rgba(var(--color-text-base), 0.8);
}

.tree-header {
  fill: rgb(var(--color-text-base));
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.5px;
}
.tree-header-line {
  stroke: rgba(var(--color-text-base), 0.2);
  stroke-width: 1;
}
.tree-node {
  font-size: 14px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  pointer-events: none;
  transition: all 0.15s ease;
}
.tree-node.folder {
  fill: rgb(var(--color-text-base));
}
.tree-node.file {
  fill: rgba(var(--color-text-base), 0.7);
}
.tree-node.file.highlighted {
  fill: rgb(var(--color-accent));
  font-weight: 600;
}
.highlight-dot {
  fill: rgb(var(--color-accent));
}

.context-window-box {
  fill: rgba(var(--color-fill), 0.9);
  stroke: rgba(var(--color-accent), 0.5);
  stroke-width: 2;
}
.context-window-header {
  fill: rgba(var(--color-text-base), 0.9);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.3px;
}
.context-window-header-icon {
  font-size: 12px;
}
.context-read-entry {
  fill: rgba(var(--color-text-base), 0.8);
  font-size: 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}
.context-read-entry.active {
  fill: rgb(var(--color-accent));
  font-weight: 500;
}
.context-checkmark {
  fill: rgb(34, 197, 94);
  font-size: 10px;
}
.context-progress-track {
  fill: rgba(var(--color-text-base), 0.15);
  rx: 2;
}
.context-progress-bar {
  fill: rgba(var(--color-accent), 0.7);
  rx: 2;
}
.context-progress-label {
  fill: rgba(var(--color-text-base), 0.7);
  font-size: 9px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}
.context-divider {
  stroke: rgba(var(--color-text-base), 0.15);
  stroke-width: 1;
}

.subagent-diagram-button {
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
.subagent-diagram-button:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(var(--color-accent), 0.4);
}
.subagent-diagram-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (prefers-reduced-motion: reduce) {
  .subagent-diagram-animated * {
    transition: none !important;
    animation: none !important;
  }
}
</style>
