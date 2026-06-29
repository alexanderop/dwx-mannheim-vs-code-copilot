<script setup lang="ts">
/**
 * OutlineRoadmap - Excalidraw-style hand-drawn roadmap of the talk outline.
 *
 * Eight rough-sketched cards laid out as a snake (left->right, then right->left)
 * and wired together with hand-drawn arrows in talk order. The final stop,
 * "Live Demo", is the accent-highlighted finale. Cards stagger in on mount via
 * motion-v; respects prefers-reduced-motion.
 *
 * Built on the Rough.js primitives from @alexop/slidev-addon-utils
 * (RoughSvg / RoughRect / RoughCircle / RoughArrow / RoughText).
 */
import { motion } from 'motion-v'

interface Stop {
  n: number
  icon: string
  title: string
  sub: string
  col: number
  row: number
  accent?: boolean
}

// Snake order: top row 1->4 (left to right), bottom row 5->8 (right to left).
const stops: Stop[] = [
  { n: 1, icon: '🤖', title: 'What is an Agent?', sub: 'LLM → Agent', col: 0, row: 0 },
  { n: 2, icon: '🧩', title: 'Context Engineering', sub: 'the real skill', col: 1, row: 0 },
  { n: 3, icon: '🔁', title: 'Back Pressure', sub: 'validation', col: 2, row: 0 },
  { n: 4, icon: '📄', title: 'AGENTS.md', sub: 'open standard', col: 3, row: 0 },
  { n: 5, icon: '🤝', title: 'Subagents', sub: 'specialized invocation', col: 3, row: 1 },
  { n: 6, icon: '🧰', title: 'Skills', sub: 'portable workflows', col: 2, row: 1 },
  { n: 7, icon: '🪝', title: 'Hooks', sub: 'deterministic control', col: 1, row: 1 },
  { n: 8, icon: '🎬', title: 'Live Demo', sub: 'putting it together', col: 0, row: 1, accent: true },
]

// --- Layout ----------------------------------------------------------------
const CARD_W = 210
const CARD_H = 110
const COL_GAP = 245
const ROW_GAP = 210

const xOf = (col: number) => col * COL_GAP
const yOf = (row: number) => row * ROW_GAP

// Hand-drawn arrows between consecutive stops (follows the snake).
interface Edge { x1: number; y1: number; x2: number; y2: number; seed: number }
const edges: Edge[] = [
  { x1: 210, y1: 55, x2: 245, y2: 55, seed: 11 },   // 1 -> 2
  { x1: 455, y1: 55, x2: 490, y2: 55, seed: 12 },   // 2 -> 3
  { x1: 700, y1: 55, x2: 735, y2: 55, seed: 13 },   // 3 -> 4
  { x1: 840, y1: 110, x2: 840, y2: 210, seed: 14 }, // 4 -> 5 (down)
  { x1: 735, y1: 265, x2: 700, y2: 265, seed: 15 }, // 5 -> 6
  { x1: 490, y1: 265, x2: 455, y2: 265, seed: 16 }, // 6 -> 7
  { x1: 245, y1: 265, x2: 210, y2: 265, seed: 17 }, // 7 -> 8
]

const reduce =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

/** Staggered entrance: each element appears a beat after the previous. */
function step(i: number) {
  return {
    initial: reduce ? { opacity: 1 } : { opacity: 0, y: 10 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.35, delay: reduce ? 0 : 0.1 * i },
  }
}
</script>

<template>
  <div class="outline-roadmap">
    <RoughSvg :width="945" :height="320" :padding="28" :roughness="1.1">
      <!-- Arrows first, so cards sit on top -->
      <motion.g v-for="(e, i) in edges" :key="`e-${i}`" v-bind="step(i + 0.5)">
        <RoughArrow
          :x1="e.x1" :y1="e.y1" :x2="e.x2" :y2="e.y2"
          :seed="e.seed" :stroke-width="2" :arrow-size="13"
        />
      </motion.g>

      <!-- Cards -->
      <motion.g v-for="s in stops" :key="s.n" v-bind="step(s.n - 1)">
        <RoughRect
          :x="xOf(s.col)" :y="yOf(s.row)" :width="CARD_W" :height="CARD_H"
          :variant="s.accent ? 'accent' : 'default'"
          :seed="s.n * 7 + 3"
          :fill-style="s.accent ? 'hachure' : 'solid'"
        />

        <!-- Number badge -->
        <RoughCircle
          :x="xOf(s.col) + 26" :y="yOf(s.row) + 24" :diameter="34"
          variant="accent" :seed="s.n * 13 + 1"
        />
        <RoughText :x="xOf(s.col) + 26" :y="yOf(s.row) + 25" variant="label">
          {{ s.n }}
        </RoughText>

        <!-- Icon -->
        <text
          :x="xOf(s.col) + CARD_W / 2" :y="yOf(s.row) + 44"
          text-anchor="middle" class="or-icon"
        >{{ s.icon }}</text>

        <!-- Title + subtitle -->
        <RoughText
          :x="xOf(s.col) + CARD_W / 2" :y="yOf(s.row) + 76" variant="label"
        >{{ s.title }}</RoughText>
        <RoughText
          :x="xOf(s.col) + CARD_W / 2" :y="yOf(s.row) + 96" variant="detail"
        >{{ s.sub }}</RoughText>
      </motion.g>
    </RoughSvg>
  </div>
</template>

<style scoped>
.outline-roadmap {
  width: 100%;
  display: flex;
  justify-content: center;
  padding-top: 0.5rem;
}

.outline-roadmap :deep(.rough-svg) {
  width: 100%;
  max-width: 1000px;
}

.or-icon {
  font-size: 28px;
  pointer-events: none;
}

@media (prefers-reduced-motion: reduce) {
  .outline-roadmap * {
    animation: none !important;
    transition: none !important;
  }
}
</style>
