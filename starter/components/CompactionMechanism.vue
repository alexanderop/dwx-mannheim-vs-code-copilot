<script setup lang="ts">
/**
 * CompactionMechanism - Interactive, step-through animation of the *cut-point*
 * mechanic VS Code Copilot Chat uses to compact agent conversation history.
 *
 * A row of conversation rounds steps through the 5 "how it works" steps:
 *  1. Pick the cut point  -> keep recent rounds verbatim
 *  2. Exclude the overflowing round (the last one blew the budget)
 *  3. Stop at the previous summary (compaction compounds)
 *  4. Generate the summary (same model, temp 0, 8-section <summary>)
 *  5. Re-insert as <conversation-summary> + breadcrumb to the on-disk transcript
 *
 * Self-contained Next / Back / Replay controls + optional auto-play.
 */
import { ref, computed, onUnmounted } from 'vue'
import { motion, AnimatePresence } from 'motion-v'

type Phase = 'idle' | 'cut' | 'exclude' | 'compound' | 'summarize' | 'done'

const PHASES: { id: Phase; label: string; caption: string }[] = [
  {
    id: 'idle',
    label: 'Over budget',
    caption:
      'Context is over budget. Compaction renders history newest-first and decides what to keep.',
  },
  {
    id: 'cut',
    label: 'Cut point',
    caption:
      'Pick the cut point — keep the most recent rounds verbatim so the model resumes mid-task.',
  },
  {
    id: 'exclude',
    label: 'Exclude overflow',
    caption:
      'Exclude the overflowing round — the last round (R8) is what blew the budget; drop it from the summary.',
  },
  {
    id: 'compound',
    label: 'Compound',
    caption:
      'Stop at the previous summary — walk back, break at the first round that already has one. Compaction compounds; it never re-summarizes from scratch.',
  },
  {
    id: 'summarize',
    label: 'Summarize',
    caption:
      'Generate the summary — one LLM call, same model, temperature 0 → an 8-section handoff inside a <summary> block. Old rounds fold into the existing summary.',
  },
  {
    id: 'done',
    label: 'Re-insert',
    caption:
      'Re-insert as a <conversation-summary> turn + a breadcrumb to the full on-disk transcript. Read exact details on demand. Context is back under budget.',
  },
]

const SUMMARIZE_INDEX = PHASES.findIndex(p => p.id === 'summarize')

interface Block {
  id: string
  label: string
  kind: 'summary' | 'round'
  overflow?: boolean
}

// Oldest -> newest. `S` is a pre-existing summary from an earlier compaction.
const ORIGINAL: Block[] = [
  { id: 'S', label: 'Summary', kind: 'summary' },
  { id: 'R4', label: 'R4', kind: 'round' },
  { id: 'R5', label: 'R5', kind: 'round' },
  { id: 'R6', label: 'R6', kind: 'round' },
  { id: 'R7', label: 'R7', kind: 'round' },
  { id: 'R8', label: 'R8', kind: 'round', overflow: true },
]

// After compaction: S + R4 + R5 fold into one expanded summary; R6/R7 kept.
const COMPACTED: Block[] = [
  { id: 'S2', label: 'Conversation Summary', kind: 'summary' },
  { id: 'R6', label: 'R6', kind: 'round' },
  { id: 'R7', label: 'R7', kind: 'round' },
]

const KEPT_IDS = ['R6', 'R7'] // recent, kept verbatim
const SUMMARIZE_IDS = ['R4', 'R5'] // between the prev summary and the kept rounds
const OVERFLOW_ID = 'R8'
const PREV_SUMMARY_ID = 'S'

const ACCENT = 'rgb(var(--color-accent))'
const GREEN = '#10B981'
const RED = '#EF4444'
const AMBER = '#F59E0B'

const phaseIndex = ref(0)
const phase = computed<Phase>(() => PHASES[phaseIndex.value].id)
const phaseIdx = computed(() => phaseIndex.value)

const displayBlocks = computed(() =>
  phaseIndex.value >= SUMMARIZE_INDEX ? COMPACTED : ORIGINAL,
)

// Context fill bar: over budget until the summary is re-inserted.
const fillPercentage = computed(() => {
  switch (phase.value) {
    case 'summarize':
      return 70
    case 'done':
      return 45
    default:
      return 97
  }
})
const fillColor = computed(() =>
  fillPercentage.value >= 90 ? RED : fillPercentage.value >= 75 ? AMBER : GREEN,
)

function blockStyle(block: Block): Record<string, string> {
  const p = phase.value
  const base: Record<string, string> = {
    background: 'rgb(var(--color-card))',
    color: 'rgb(var(--color-text-base))',
    borderColor: 'rgb(var(--color-border))',
  }

  if (block.kind === 'summary') {
    base.background =
      'linear-gradient(135deg, #6366F1 0%, #8B5CF6 50%, #A855F7 100%)'
    base.color = '#fff'
    base.borderColor = 'transparent'
    return base
  }

  // Round styling depends on phase.
  const kept = KEPT_IDS.includes(block.id)
  const toSummarize = SUMMARIZE_IDS.includes(block.id)
  const isOverflow = block.id === OVERFLOW_ID

  if (p !== 'idle') {
    if (kept) {
      base.borderColor = GREEN
      base.color = GREEN
    } else if (toSummarize && p !== 'idle') {
      base.borderColor = AMBER
      base.color = AMBER
    }
  }
  if ((p === 'exclude' || p === 'compound') && isOverflow) {
    base.opacity = '0.35'
    base.borderColor = RED
    base.color = RED
  }
  return base
}

function blockTag(block: Block): { text: string; color: string } | null {
  const p = phase.value
  if (block.id === OVERFLOW_ID && (p === 'exclude' || p === 'compound'))
    return { text: 'overflowed', color: RED }
  if (KEPT_IDS.includes(block.id) && p !== 'idle')
    return { text: 'kept verbatim', color: GREEN }
  if (SUMMARIZE_IDS.includes(block.id) && p !== 'idle' && p !== 'done')
    return { text: 'to summarize', color: AMBER }
  if (block.id === 'S2' && (p === 'summarize' || p === 'done'))
    return { text: '8-section <summary>', color: ACCENT }
  return null
}

const pulseSummary = computed(() => phase.value === 'compound')

// --- Controls -----------------------------------------------------------
let autoTimer: ReturnType<typeof setTimeout> | undefined
const isAuto = ref(false)

function clearAuto() {
  if (autoTimer) {
    clearTimeout(autoTimer)
    autoTimer = undefined
  }
  isAuto.value = false
}

function next() {
  if (phaseIndex.value < PHASES.length - 1) phaseIndex.value += 1
  else clearAuto()
}
function back() {
  clearAuto()
  if (phaseIndex.value > 0) phaseIndex.value -= 1
}
function replay() {
  clearAuto()
  phaseIndex.value = 0
}
function toggleAuto() {
  if (isAuto.value) {
    clearAuto()
    return
  }
  if (phaseIndex.value >= PHASES.length - 1) phaseIndex.value = 0
  isAuto.value = true
  tickAuto()
}
function tickAuto() {
  autoTimer = setTimeout(() => {
    if (!isAuto.value) return
    if (phaseIndex.value < PHASES.length - 1) {
      phaseIndex.value += 1
      tickAuto()
    } else {
      isAuto.value = false
    }
  }, 1900)
}

const atEnd = computed(() => phaseIndex.value >= PHASES.length - 1)

onUnmounted(clearAuto)
</script>

<template>
  <div class="my-6 rounded-lg bg-[rgb(var(--color-fill))] p-5">
    <!-- Header + controls -->
    <div class="mb-4 flex flex-wrap items-center justify-between gap-2">
      <h3 class="text-base font-semibold text-[rgb(var(--color-text-base))]">
        Compaction: the cut-point mechanic
      </h3>
      <div class="flex items-center gap-2">
        <button
          class="rounded border border-[rgb(var(--color-border))] px-3 py-1 text-sm text-[rgb(var(--color-text-base))] transition hover:opacity-80 disabled:opacity-30"
          :disabled="phaseIdx === 0"
          @click="back"
        >
          ‹ Back
        </button>
        <button
          class="rounded bg-[rgb(var(--color-accent))] px-3 py-1 text-sm text-[rgb(var(--color-fill))] transition hover:opacity-80"
          @click="atEnd ? replay() : next()"
        >
          {{ atEnd ? '↻ Replay' : 'Next ›' }}
        </button>
        <button
          class="rounded border border-[rgb(var(--color-border))] px-3 py-1 text-sm text-[rgb(var(--color-text-base))] transition hover:opacity-80"
          @click="toggleAuto"
        >
          {{ isAuto ? '❚❚ Pause' : '▶ Auto' }}
        </button>
      </div>
    </div>

    <!-- Step progress -->
    <div class="mb-4 flex flex-wrap items-center gap-1.5 text-xs">
      <template v-for="(p, i) in PHASES" :key="p.id">
        <span
          class="rounded-full px-2.5 py-0.5 transition-all duration-300"
          :class="
            i === phaseIdx
              ? 'font-semibold'
              : i < phaseIdx
                ? 'opacity-50'
                : 'opacity-30'
          "
          :style="
            i === phaseIdx
              ? { background: 'rgb(var(--color-accent))', color: 'rgb(var(--color-fill))' }
              : { background: 'rgb(var(--color-card))', color: 'rgb(var(--color-text-base))' }
          "
        >
          {{ i + 1 }}. {{ p.label }}
        </span>
      </template>
    </div>

    <!-- Context fill bar -->
    <div class="mb-1 flex justify-between text-xs text-[rgb(var(--color-text-base))] opacity-60">
      <span>conversation history</span>
      <span>{{ fillPercentage }}% of budget</span>
    </div>
    <div class="mb-5 h-2.5 overflow-hidden rounded-full bg-[rgb(var(--color-card))]">
      <div
        class="h-full transition-all duration-500"
        :style="{ width: `${fillPercentage}%`, backgroundColor: fillColor }"
      />
    </div>

    <!-- Rounds row -->
    <div
      class="flex min-h-[96px] flex-wrap items-center gap-2 rounded-lg border-2 border-dashed border-[rgb(var(--color-border))] bg-[rgb(var(--color-card))] p-4"
    >
      <AnimatePresence mode="popLayout">
        <motion.div
          v-for="block in displayBlocks"
          :key="block.id"
          layout
          :initial="{ opacity: 0, scale: 0.6, y: -8 }"
          :animate="
            pulseSummary && block.kind === 'summary'
              ? { opacity: 1, scale: [1, 1.06, 1], y: 0 }
              : { opacity: 1, scale: 1, y: 0 }
          "
          :exit="{ opacity: 0, scale: 0.6, y: 8 }"
          :transition="
            pulseSummary && block.kind === 'summary'
              ? { duration: 0.7, repeat: Infinity }
              : { type: 'spring', stiffness: 260, damping: 22 }
          "
          class="flex flex-col items-center justify-center rounded-lg border-2 px-4 py-3 text-center"
          :style="blockStyle(block)"
        >
          <span
            class="text-sm font-semibold"
            :class="phase === 'exclude' && block.id === OVERFLOW_ID ? 'line-through' : ''"
          >
            {{ block.kind === 'summary' ? '📄 ' : '' }}{{ block.label }}
          </span>
          <span
            v-if="blockTag(block)"
            class="mt-1 text-[10px] font-medium leading-none"
            :style="{ color: blockTag(block)!.color }"
          >
            {{ blockTag(block)!.text }}
          </span>
        </motion.div>
      </AnimatePresence>

      <!-- Breadcrumb to the on-disk transcript -->
      <AnimatePresence>
        <motion.div
          v-if="phase === 'done'"
          :initial="{ opacity: 0, x: -12 }"
          :animate="{ opacity: 1, x: 0 }"
          :exit="{ opacity: 0 }"
          :transition="{ duration: 0.4 }"
          class="ml-1 flex items-center gap-1.5 rounded-lg border border-dashed px-3 py-2 font-mono text-xs"
          :style="{ borderColor: ACCENT, color: ACCENT }"
        >
          → transcript.md
          <span class="opacity-60">(read full history on demand)</span>
        </motion.div>
      </AnimatePresence>
    </div>

    <!-- Caption -->
    <p
      class="mt-4 min-h-[3rem] text-sm leading-relaxed text-[rgb(var(--color-text-base))]"
    >
      <span class="font-semibold text-[rgb(var(--color-accent))]"
        >{{ phaseIdx + 1 }}. {{ PHASES[phaseIdx].label }}</span
      >
      — {{ PHASES[phaseIdx].caption }}
    </p>
  </div>
</template>
