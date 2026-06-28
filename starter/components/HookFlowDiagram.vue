<script setup lang="ts">
/**
 * HookFlowDiagram - Clean, branded flow diagram for "How a Hook Works".
 *
 * Agent -> PreToolUse hook -> your script, which forks into the allow path
 * (Tool runs -> PostToolUse) and the deny/ask path (blocked / needs approval).
 * Staggered fade-in on mount via motion-v; respects prefers-reduced-motion.
 */
import { motion } from 'motion-v'

const reduce =
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

/** Staggered entrance: each step appears a beat after the previous. */
function step(i: number) {
  return {
    initial: reduce ? { opacity: 1 } : { opacity: 0, y: 8 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.35, delay: reduce ? 0 : 0.12 * i },
  }
}
</script>

<template>
  <div class="hook-flow">
    <svg viewBox="0 0 1180 340" class="hook-flow-svg">
      <defs>
        <marker id="hf-arrow" markerWidth="9" markerHeight="7" refX="8" refY="3.5" orient="auto">
          <polygon points="0 0, 9 3.5, 0 7" class="hf-arrowhead" />
        </marker>
        <marker id="hf-arrow-allow" markerWidth="9" markerHeight="7" refX="8" refY="3.5" orient="auto">
          <polygon points="0 0, 9 3.5, 0 7" class="hf-arrowhead allow" />
        </marker>
        <marker id="hf-arrow-deny" markerWidth="9" markerHeight="7" refX="8" refY="3.5" orient="auto">
          <polygon points="0 0, 9 3.5, 0 7" class="hf-arrowhead deny" />
        </marker>
      </defs>

      <!-- 1. Agent -->
      <motion.g v-bind="step(0)">
        <rect x="16" y="132" width="170" height="76" rx="14" class="hf-node neutral" />
        <text x="101" y="164" text-anchor="middle" class="hf-icon">🤖</text>
        <text x="101" y="190" text-anchor="middle" class="hf-label">Agent wants a tool</text>
      </motion.g>

      <!-- Agent -> PreToolUse -->
      <motion.path v-bind="step(1)" d="M188 170 H242" class="hf-arrow" marker-end="url(#hf-arrow)" />

      <!-- 2. PreToolUse -->
      <motion.g v-bind="step(1)">
        <rect x="244" y="132" width="186" height="76" rx="14" class="hf-node accent" />
        <text x="337" y="164" text-anchor="middle" class="hf-icon">🪝</text>
        <text x="337" y="190" text-anchor="middle" class="hf-label">PreToolUse hook</text>
      </motion.g>

      <!-- PreToolUse -> script (JSON on stdin) -->
      <motion.g v-bind="step(2)">
        <path d="M432 170 H504" class="hf-arrow" marker-end="url(#hf-arrow)" />
        <rect x="431" y="148" width="74" height="20" rx="6" class="hf-pill" />
        <text x="468" y="162" text-anchor="middle" class="hf-pill-text">JSON · stdin</text>
      </motion.g>

      <!-- 3. Your script (decision) -->
      <motion.g v-bind="step(2)">
        <rect x="506" y="132" width="166" height="76" rx="14" class="hf-node decision" />
        <text x="589" y="164" text-anchor="middle" class="hf-icon">📜</text>
        <text x="589" y="190" text-anchor="middle" class="hf-label">Your script</text>
      </motion.g>

      <!-- allow branch -->
      <motion.g v-bind="step(3)">
        <path d="M672 156 C 712 120, 720 78, 758 70" class="hf-arrow allow" marker-end="url(#hf-arrow-allow)" />
        <text x="700" y="104" text-anchor="middle" class="hf-edge allow">allow</text>
      </motion.g>

      <!-- 4. Tool runs -->
      <motion.g v-bind="step(3)">
        <rect x="760" y="34" width="158" height="72" rx="14" class="hf-node allow" />
        <text x="839" y="66" text-anchor="middle" class="hf-icon">✅</text>
        <text x="839" y="92" text-anchor="middle" class="hf-label">Tool runs</text>
      </motion.g>

      <!-- Tool runs -> PostToolUse -->
      <motion.path v-bind="step(4)" d="M920 70 H960" class="hf-arrow allow" marker-end="url(#hf-arrow-allow)" />

      <!-- 5. PostToolUse -->
      <motion.g v-bind="step(4)">
        <rect x="962" y="28" width="200" height="84" rx="14" class="hf-node accent" />
        <text x="1062" y="58" text-anchor="middle" class="hf-icon">🎨</text>
        <text x="1062" y="83" text-anchor="middle" class="hf-label">PostToolUse hook</text>
        <text x="1062" y="101" text-anchor="middle" class="hf-sub">format · lint · test</text>
      </motion.g>

      <!-- deny / ask branch -->
      <motion.g v-bind="step(3)">
        <path d="M672 184 C 712 222, 720 258, 758 266" class="hf-arrow deny" marker-end="url(#hf-arrow-deny)" />
        <text x="700" y="244" text-anchor="middle" class="hf-edge deny">deny / ask</text>
      </motion.g>

      <!-- 6. Blocked -->
      <motion.g v-bind="step(4)">
        <rect x="760" y="232" width="206" height="84" rx="14" class="hf-node deny" />
        <text x="863" y="262" text-anchor="middle" class="hf-icon">🛑</text>
        <text x="863" y="288" text-anchor="middle" class="hf-label">Blocked or</text>
        <text x="863" y="306" text-anchor="middle" class="hf-label">needs approval</text>
      </motion.g>
    </svg>

    <!-- Exit-code legend -->
    <motion.div class="hf-legend" v-bind="step(5)">
      <span class="hf-legend-title">Exit codes</span>
      <span class="hf-chip"><code class="hf-code">0</code> success — parse stdout</span>
      <span class="hf-chip deny"><code class="hf-code">2</code> block &amp; tell the model why</span>
      <span class="hf-chip muted"><code class="hf-code">*</code> warn, continue</span>
    </motion.div>
  </div>
</template>

<style scoped>
.hook-flow {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.75rem;
  width: 100%;
  padding-top: 0.5rem;
}

.hook-flow-svg {
  width: 100%;
  max-width: 1000px;
  height: auto;
  overflow: visible;
}

/* Nodes */
.hf-node {
  stroke-width: 2;
}
.hf-node.neutral {
  fill: rgba(var(--color-card), 0.55);
  stroke: rgba(var(--color-text-base), 0.25);
}
.hf-node.accent {
  fill: rgba(var(--color-accent), 0.14);
  stroke: rgb(var(--color-accent));
}
.hf-node.decision {
  fill: rgba(var(--color-accent), 0.08);
  stroke: rgba(var(--color-accent), 0.85);
  stroke-dasharray: 7 4;
}
.hf-node.allow {
  fill: rgba(34, 197, 94, 0.14);
  stroke: rgb(34, 197, 94);
}
.hf-node.deny {
  fill: rgba(248, 113, 113, 0.14);
  stroke: rgb(248, 113, 113);
}

.hf-icon {
  font-size: 26px;
  pointer-events: none;
}
.hf-label {
  fill: rgb(var(--color-text-base));
  font-size: 17px;
  font-weight: 600;
  pointer-events: none;
}
.hf-sub {
  fill: rgba(var(--color-text-base), 0.7);
  font-size: 13px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  pointer-events: none;
}

/* Arrows */
.hf-arrow {
  fill: none;
  stroke: rgba(var(--color-text-base), 0.55);
  stroke-width: 2.5;
  stroke-linecap: round;
}
.hf-arrow.allow {
  stroke: rgba(34, 197, 94, 0.85);
}
.hf-arrow.deny {
  stroke: rgba(248, 113, 113, 0.85);
}
.hf-arrowhead {
  fill: rgba(var(--color-text-base), 0.55);
}
.hf-arrowhead.allow {
  fill: rgba(34, 197, 94, 0.85);
}
.hf-arrowhead.deny {
  fill: rgba(248, 113, 113, 0.85);
}

/* Edge labels */
.hf-edge {
  font-size: 14px;
  font-weight: 600;
  pointer-events: none;
}
.hf-edge.allow {
  fill: rgb(34, 197, 94);
}
.hf-edge.deny {
  fill: rgb(248, 113, 113);
}

/* JSON pill */
.hf-pill {
  fill: rgba(var(--color-fill), 0.95);
  stroke: rgba(var(--color-text-base), 0.2);
  stroke-width: 1;
}
.hf-pill-text {
  fill: rgba(var(--color-text-base), 0.85);
  font-size: 12px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  pointer-events: none;
}

/* Legend */
.hf-legend {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 0.65rem;
  font-size: 1rem;
}
.hf-legend-title {
  color: rgb(var(--color-accent));
  font-weight: 700;
}
.hf-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.3rem 0.7rem;
  border-radius: 9999px;
  background: rgba(var(--color-card), 0.5);
  border: 1px solid rgba(var(--color-text-base), 0.12);
}
.hf-chip.deny {
  border-color: rgba(248, 113, 113, 0.4);
}
.hf-chip.muted {
  opacity: 0.75;
}
.hf-code {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-weight: 700;
  background: rgba(var(--color-accent), 0.18);
  color: rgb(var(--color-accent));
  padding: 0.05rem 0.45rem;
  border-radius: 6px;
}

@media (prefers-reduced-motion: reduce) {
  .hook-flow * {
    transition: none !important;
    animation: none !important;
  }
}
</style>
