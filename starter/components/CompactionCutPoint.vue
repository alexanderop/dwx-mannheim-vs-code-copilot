<script setup lang="ts">
/**
 * CompactionCutPoint - Excalidraw-style, entry-by-entry view of the compaction
 * cut-point mechanic in VS Code Copilot Chat's agent history.
 *
 * Three stepped phases (Next / Replay, mirrors <CompactionMechanism>):
 *
 *  1. Before compaction  -> the entry array is split at `firstKeptEntryId`:
 *                           entries before it (messagesToSummarize) get folded,
 *                           entries from it onward are kept verbatim.
 *  2. After compaction    -> a new `cmp` entry is appended holding the summary;
 *                           entries before the cut are no longer sent, everything
 *                           from the cut onward is.
 *  3. What the LLM sees    -> system prompt + summary (from cmp) + kept messages
 *                           starting at firstKeptEntryId.
 *
 * Built on the Rough.js primitives from @alexop/slidev-addon-utils
 * (RoughSvg / RoughRect / RoughLine / RoughArrow).
 */
import { ref, computed } from 'vue'
import { motion } from 'motion-v'

// --- Palette ---------------------------------------------------------------
type Tone = 'accent' | 'success' | 'danger' | 'muted'

const TONE: Record<Tone, { stroke: string; fill: string; text: string }> = {
  accent: { stroke: 'rgba(255,107,237,0.9)', fill: 'rgba(255,107,237,0.16)', text: 'rgba(255,107,237,0.95)' },
  success: { stroke: 'rgba(52,211,153,0.85)', fill: 'rgba(52,211,153,0.12)', text: 'rgba(52,211,153,0.95)' },
  danger: { stroke: 'rgba(248,113,113,0.8)', fill: 'rgba(248,113,113,0.10)', text: 'rgba(248,113,113,0.95)' },
  muted: { stroke: 'rgba(255,255,255,0.32)', fill: 'rgba(255,255,255,0.04)', text: 'rgba(255,255,255,0.45)' },
}

const MONO = "'Geist Mono', monospace"

// --- Phase model -----------------------------------------------------------
interface Cell { label: string; tone: Tone; dim?: boolean }
interface Group { from: number; to: number; label: string; tone: Tone }
interface Pointer { index: number; label: string }
interface Caption { index: number; label: string }

interface Phase {
  id: string
  label: string
  showIndex: boolean
  cells: Cell[]
  groups: Group[]
  pointer?: Pointer
  captions?: Caption[]
  caption: string
}

const KEPT: Cell[] = [
  { label: 'usr', tone: 'success' },
  { label: 'ass', tone: 'success' },
  { label: 'tool', tone: 'success' },
  { label: 'tool', tone: 'success' },
  { label: 'ass', tone: 'success' },
  { label: 'tool', tone: 'success' },
]

const PHASES: Phase[] = [
  {
    id: 'before',
    label: 'Before compaction',
    showIndex: true,
    cells: [
      { label: 'hdr', tone: 'danger' },
      { label: 'usr', tone: 'danger' },
      { label: 'ass', tone: 'danger' },
      { label: 'tool', tone: 'danger' },
      ...KEPT,
    ],
    groups: [
      { from: 0, to: 3, label: 'messagesToSummarize', tone: 'danger' },
      { from: 4, to: 9, label: 'kept messages', tone: 'success' },
    ],
    pointer: { index: 4, label: 'firstKeptEntryId (entry 4)' },
    caption:
      'The entry array is split at firstKeptEntryId. Entries before it (messagesToSummarize) get folded; entries from it onward are kept verbatim.',
  },
  {
    id: 'after',
    label: 'After compaction — new entry appended',
    showIndex: true,
    cells: [
      { label: 'hdr', tone: 'muted', dim: true },
      { label: 'usr', tone: 'muted', dim: true },
      { label: 'ass', tone: 'muted', dim: true },
      { label: 'tool', tone: 'muted', dim: true },
      ...KEPT,
      { label: 'cmp', tone: 'accent' },
    ],
    groups: [
      { from: 0, to: 3, label: 'not sent to LLM', tone: 'muted' },
      { from: 4, to: 10, label: 'sent to LLM', tone: 'success' },
    ],
    pointer: { index: 4, label: 'starts from firstKeptEntryId' },
    caption:
      'A new cmp entry is appended holding the summary. Entries before the cut are no longer sent; everything from firstKeptEntryId onward is.',
  },
  {
    id: 'sees',
    label: 'What the LLM sees',
    showIndex: false,
    cells: [
      { label: 'system', tone: 'muted' },
      { label: 'summary', tone: 'accent' },
      ...KEPT,
    ],
    groups: [{ from: 2, to: 7, label: 'messages from firstKeptEntryId', tone: 'success' }],
    captions: [
      { index: 0, label: 'prompt' },
      { index: 1, label: 'from cmp' },
    ],
    caption:
      'System prompt, then the summary pulled from cmp, then the kept messages starting at firstKeptEntryId — full history still readable on disk.',
  },
]

// --- Geometry --------------------------------------------------------------
const CELL_W = 64
const GAP = 8
const PITCH = CELL_W + GAP
const CELL_Y = 30
const CELL_H = 50
const CELL_BOTTOM = CELL_Y + CELL_H
const BRACKET_Y = 96
const SVG_W = 11 * PITCH - GAP // widest phase (11 cells)
const SVG_H = 178

const xOf = (i: number) => i * PITCH
const cxOf = (i: number) => xOf(i) + CELL_W / 2

// --- Stepper ---------------------------------------------------------------
const phaseIndex = ref(0)
const phase = computed(() => PHASES[phaseIndex.value])
const atEnd = computed(() => phaseIndex.value >= PHASES.length - 1)

function next() {
  phaseIndex.value = atEnd.value ? 0 : phaseIndex.value + 1
}

const reduce =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

function step(i: number) {
  return {
    initial: reduce ? { opacity: 1 } : { opacity: 0, y: 8 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.3, delay: reduce ? 0 : 0.04 * i },
  }
}
</script>

<template>
  <div class="my-6 rounded-lg bg-[rgb(var(--color-fill))] p-5">
    <!-- Header + control -->
    <div class="mb-4 flex flex-wrap items-center justify-between gap-2">
      <h3 class="text-base font-semibold text-[rgb(var(--color-text-base))]">
        Compaction: the cut-point, entry by entry
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
      <span
        v-for="(p, i) in PHASES"
        :key="p.id"
        class="rounded-full px-2.5 py-0.5 transition-all duration-300"
        :class="i === phaseIndex ? 'font-semibold' : i < phaseIndex ? 'opacity-50' : 'opacity-30'"
        :style="
          i === phaseIndex
            ? { background: 'rgb(var(--color-accent))', color: 'rgb(var(--color-fill))' }
            : { background: 'rgb(var(--color-card))', color: 'rgb(var(--color-text-base))' }
        "
      >
        {{ i + 1 }}. {{ p.label.split(' —')[0] }}
      </span>
    </div>

    <!-- Hand-drawn entry strip -->
    <div class="cutpoint-stage">
      <RoughSvg :width="SVG_W" :height="SVG_H" :padding="22" :roughness="1.15" :seed="7">
        <g :key="phase.id">
          <!-- Cells -->
          <motion.g
            v-for="(cell, i) in phase.cells"
            :key="`${phase.id}-cell-${i}`"
            v-bind="step(i)"
            :style="{ opacity: cell.dim ? 0.45 : 1 }"
          >
            <!-- entry index above the cell -->
            <text
              v-if="phase.showIndex"
              :x="cxOf(i)"
              y="14"
              text-anchor="middle"
              :font-family="MONO"
              fill="rgba(255,255,255,0.4)"
              style="font-size: 11px !important"
            >{{ i }}</text>

            <RoughRect
              :x="xOf(i)"
              :y="CELL_Y"
              :width="CELL_W"
              :height="CELL_H"
              :stroke="TONE[cell.tone].stroke"
              :fill="TONE[cell.tone].fill"
              fill-style="solid"
              :seed="i * 7 + 3"
            />
            <text
              :x="cxOf(i)"
              :y="CELL_Y + CELL_H / 2 + 1"
              text-anchor="middle"
              dominant-baseline="middle"
              :font-family="MONO"
              :fill="TONE[cell.tone].text"
              style="font-size: 13px !important"
            >{{ cell.label }}</text>

            <!-- per-cell caption (phase 3) -->
            <text
              v-for="cap in (phase.captions ?? []).filter((c) => c.index === i)"
              :key="`cap-${cap.index}`"
              :x="cxOf(i)"
              :y="BRACKET_Y + 18"
              text-anchor="middle"
              :font-family="MONO"
              :fill="TONE.accent.text"
              style="font-size: 11px !important"
            >↑ {{ cap.label }}</text>
          </motion.g>

          <!-- Group brackets -->
          <motion.g
            v-for="(grp, gi) in phase.groups"
            :key="`${phase.id}-grp-${gi}`"
            v-bind="step(phase.cells.length + gi)"
          >
            <RoughLine
              :x1="xOf(grp.from) + 2"
              :y1="BRACKET_Y"
              :x2="xOf(grp.to) + CELL_W - 2"
              :y2="BRACKET_Y"
              :stroke="TONE[grp.tone].stroke"
              :seed="gi * 5 + 21"
            />
            <RoughLine
              :x1="xOf(grp.from) + 2"
              :y1="BRACKET_Y"
              :x2="xOf(grp.from) + 2"
              :y2="BRACKET_Y - 7"
              :stroke="TONE[grp.tone].stroke"
              :seed="gi * 5 + 22"
            />
            <RoughLine
              :x1="xOf(grp.to) + CELL_W - 2"
              :y1="BRACKET_Y"
              :x2="xOf(grp.to) + CELL_W - 2"
              :y2="BRACKET_Y - 7"
              :stroke="TONE[grp.tone].stroke"
              :seed="gi * 5 + 23"
            />
            <text
              :x="(xOf(grp.from) + xOf(grp.to) + CELL_W) / 2"
              :y="BRACKET_Y + 18"
              text-anchor="middle"
              :font-family="MONO"
              :fill="TONE[grp.tone].text"
              style="font-size: 12px !important"
            >{{ grp.label }}</text>
          </motion.g>

          <!-- firstKeptEntryId pointer -->
          <motion.g v-if="phase.pointer" :key="`${phase.id}-ptr`" v-bind="step(phase.cells.length + 4)">
            <RoughArrow
              :x1="cxOf(phase.pointer.index)"
              :y1="SVG_H - 18"
              :x2="cxOf(phase.pointer.index)"
              :y2="BRACKET_Y + 26"
              :stroke="TONE.accent.stroke"
              :arrow-size="11"
              :seed="71"
            />
            <text
              :x="cxOf(phase.pointer.index)"
              :y="SVG_H - 2"
              text-anchor="middle"
              :font-family="MONO"
              :fill="TONE.accent.text"
              style="font-size: 12px !important"
            >{{ phase.pointer.label }}</text>
          </motion.g>
        </g>
      </RoughSvg>
    </div>

    <!-- Caption -->
    <p class="mt-3 min-h-[3rem] text-sm leading-relaxed text-[rgb(var(--color-text-base))]">
      <span class="font-semibold text-[rgb(var(--color-accent))]">{{ phaseIndex + 1 }}. {{ phase.label }}</span>
      — {{ phase.caption }}
    </p>
  </div>
</template>

<style scoped>
.cutpoint-stage {
  width: 100%;
  display: flex;
  justify-content: center;
}

.cutpoint-stage :deep(.rough-svg) {
  width: 100%;
  max-width: 920px;
}

@media (prefers-reduced-motion: reduce) {
  .cutpoint-stage * {
    animation: none !important;
    transition: none !important;
  }
}
</style>
