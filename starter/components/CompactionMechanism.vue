<script setup lang="ts">
/**
 * CompactionMechanism - Simplified 3-step view of how VS Code Copilot Chat
 * compacts agent conversation history.
 *
 *  1. Over budget  -> context blew the budget, history rendered newest-first
 *  2. Summarize    -> keep recent rounds verbatim, fold the rest into one
 *                     LLM-generated <summary> (same model, temp 0)
 *  3. Under budget -> re-insert as a <conversation-summary> + a breadcrumb to
 *                     the full on-disk transcript
 *
 * One Next / Replay button. No Back / Auto.
 */
import { ref, computed } from 'vue'
import { motion, AnimatePresence } from 'motion-v'

type Phase = 'over' | 'summarize' | 'done'

const PHASES: { id: Phase; label: string; caption: string }[] = [
  {
    id: 'over',
    label: 'Over budget',
    caption:
      'Context blew the budget. History is rendered newest-first to decide what to keep.',
  },
  {
    id: 'summarize',
    label: 'Summarize',
    caption:
      'Keep the most recent rounds verbatim; fold everything older into one LLM-generated <summary> (same model, temperature 0).',
  },
  {
    id: 'done',
    label: 'Under budget',
    caption:
      'Re-insert as a <conversation-summary> turn plus a breadcrumb to the full on-disk transcript — read exact details on demand.',
  },
]

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
const SUMMARIZE_IDS = ['R4', 'R5'] // folded into the summary
const OVERFLOW_ID = 'R8'

const ACCENT = 'rgb(var(--color-accent))'
const GREEN = '#10B981'
const RED = '#EF4444'
const AMBER = '#F59E0B'

const phaseIndex = ref(0)
const phase = computed<Phase>(() => PHASES[phaseIndex.value].id)

const displayBlocks = computed(() =>
  phase.value === 'done' ? COMPACTED : ORIGINAL,
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

  if (phase.value === 'summarize') {
    if (KEPT_IDS.includes(block.id)) {
      base.borderColor = GREEN
      base.color = GREEN
    } else if (SUMMARIZE_IDS.includes(block.id)) {
      base.borderColor = AMBER
      base.color = AMBER
    } else if (block.id === OVERFLOW_ID) {
      base.opacity = '0.35'
      base.borderColor = RED
      base.color = RED
    }
  }
  return base
}

function blockTag(block: Block): { text: string; color: string } | null {
  if (phase.value === 'summarize') {
    if (block.id === OVERFLOW_ID) return { text: 'overflowed', color: RED }
    if (KEPT_IDS.includes(block.id))
      return { text: 'kept verbatim', color: GREEN }
    if (SUMMARIZE_IDS.includes(block.id))
      return { text: 'to summarize', color: AMBER }
  }
  if (block.id === 'S2' && phase.value === 'done')
    return { text: '8-section <summary>', color: ACCENT }
  return null
}

// --- Controls -----------------------------------------------------------
const atEnd = computed(() => phaseIndex.value >= PHASES.length - 1)

function next() {
  if (phaseIndex.value < PHASES.length - 1) phaseIndex.value += 1
  else phaseIndex.value = 0
}
</script>

<template>
  <div class="my-6 rounded-lg bg-[rgb(var(--color-fill))] p-5">
    <!-- Header + control -->
    <div class="mb-4 flex flex-wrap items-center justify-between gap-2">
      <h3 class="text-base font-semibold text-[rgb(var(--color-text-base))]">
        Compaction: the cut-point mechanic
      </h3>
      <button
        class="rounded bg-[rgb(var(--color-accent))] px-3 py-1 text-sm text-[rgb(var(--color-fill))] transition hover:opacity-80"
        @click="next"
      >
        {{ atEnd ? '↻ Replay' : 'Next ›' }}
      </button>
    </div>

    <!-- Step progress -->
    <div class="mb-4 flex flex-wrap items-center gap-1.5 text-xs">
      <template v-for="(p, i) in PHASES" :key="p.id">
        <span
          class="rounded-full px-2.5 py-0.5 transition-all duration-300"
          :class="
            i === phaseIndex
              ? 'font-semibold'
              : i < phaseIndex
                ? 'opacity-50'
                : 'opacity-30'
          "
          :style="
            i === phaseIndex
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
          :animate="{ opacity: 1, scale: 1, y: 0 }"
          :exit="{ opacity: 0, scale: 0.6, y: 8 }"
          :transition="{ type: 'spring', stiffness: 260, damping: 22 }"
          class="flex flex-col items-center justify-center rounded-lg border-2 px-4 py-3 text-center"
          :style="blockStyle(block)"
        >
          <span
            class="text-sm font-semibold"
            :class="phase === 'summarize' && block.id === OVERFLOW_ID ? 'line-through' : ''"
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
        >{{ phaseIndex + 1 }}. {{ PHASES[phaseIndex].label }}</span
      >
      — {{ PHASES[phaseIndex].caption }}
    </p>
  </div>
</template>
