<script setup lang="ts">
/**
 * FourTypesOfMemory - Interactive, step-through visual of the CoALA framework's
 * four agent memory types, mapped to how Claude Code implements each.
 *
 * The core insight it animates: working memory (the context window) is the hub
 * every other type passes through. The three on-disk stores — semantic,
 * procedural, episodic — light up one at a time and stream INTO the context
 * window. The final step shows all four lit = the full coding agent.
 *
 * Self-contained Back / Next / Auto controls, themed with brand CSS vars.
 */
import { ref, computed, onUnmounted } from 'vue'
import { motion } from 'motion-v'

type TypeId = 'working' | 'semantic' | 'procedural' | 'episodic'

interface MemoryType {
  id: TypeId
  name: string
  icon: string
  color: string
  analogy: string
  human: string
  claudeCode: string
  manage: string
}

// Hub (working) first, then the three on-disk stores in reveal order.
const WORKING: MemoryType = {
  id: 'working',
  name: 'Working',
  icon: '🧠',
  color: '#38BDF8',
  analogy: 'RAM',
  human: "What's active in your head right now — the sentence you're reading.",
  claudeCode: 'The context window',
  manage: '/context · /clear · /compact',
}

const STORES: MemoryType[] = [
  {
    id: 'semantic',
    name: 'Semantic',
    icon: '📚',
    color: '#10B981',
    analogy: 'Facts you just know',
    human: '"Python is interpreted." Stable knowledge, no lookup.',
    claudeCode: 'CLAUDE.md hierarchy + @-imports',
    manage: 'Edit the files',
  },
  {
    id: 'procedural',
    name: 'Procedural',
    icon: '🛠️',
    color: '#F59E0B',
    analogy: 'Learned skills',
    human: 'Riding a bike. The steps, not the facts. You don’t re-derive them.',
    claudeCode: 'Skills (SKILL.md) + progressive disclosure',
    manage: 'Author by hand in .claude/skills/',
  },
  {
    id: 'episodic',
    name: 'Episodic',
    icon: '🎞️',
    color: '#A855F7',
    analogy: 'Personal experience',
    human: '"Last time we debugged auth, the bug was in the middleware."',
    claudeCode: 'Auto memory (distilled) + Dreams',
    manage: '/memory',
  },
]

// Steps: 0 = working hub, 1..3 = each store, 4 = all four / summary.
const STEPS = [WORKING, ...STORES]
const SUMMARY_INDEX = STEPS.length // = 4

const stepIndex = ref(0)
const isSummary = computed(() => stepIndex.value === SUMMARY_INDEX)
const lastIndex = SUMMARY_INDEX

const focused = computed<TypeId | null>(() =>
  isSummary.value ? null : STEPS[stepIndex.value].id,
)

// A store (semantic=idx1, procedural=2, episodic=3) is revealed once we reach it.
function storeRevealed(store: MemoryType): boolean {
  const order = STORES.indexOf(store) + 1 // 1..3
  return isSummary.value || stepIndex.value >= order
}
function storeActive(store: MemoryType): boolean {
  return focused.value === store.id
}
// Connector streams when its store is revealed (and on the summary all stream).
function connectorFlowing(store: MemoryType): boolean {
  return storeRevealed(store)
}

const workingActive = computed(() => focused.value === 'working')

// How "full" the context window reads as more stores stream in.
const fillPercentage = computed(() => {
  const revealed = STORES.filter(storeRevealed).length // 0..3
  return [22, 45, 62, 80, 80][Math.min(stepIndex.value, 4)] ?? 22 + revealed * 19
})

const detail = computed<MemoryType | null>(() =>
  isSummary.value ? null : STEPS[stepIndex.value],
)

const caption = computed(() => {
  if (isSummary.value)
    return 'All four together = a coding agent. A thermostat needs only working memory; the richer the job, the more types it wants.'
  switch (focused.value) {
    case 'working':
      return 'The hub every other memory passes through. Volatile, bounded by the context window. Every agent — and every chatbot — has it.'
    case 'semantic':
      return 'Stable facts loaded up front, every session. Without it the agent relearns your project every single time.'
    case 'procedural':
      return 'How-to steps, loaded on demand via progressive disclosure. Authored by hand — rewriting your own procedures is the dangerous kind of learning.'
    case 'episodic':
      return 'Distilled experience the agent writes for itself. The frontier is forgetting — consolidation, the thing Anthropic calls "dreaming".'
    default:
      return ''
  }
})

// --- Controls -----------------------------------------------------------
let autoTimer: ReturnType<typeof setTimeout> | undefined
const isAuto = ref(false)

function clearAuto() {
  if (autoTimer) clearTimeout(autoTimer)
  autoTimer = undefined
  isAuto.value = false
}
function next() {
  if (stepIndex.value < lastIndex) stepIndex.value += 1
  else clearAuto()
}
function back() {
  clearAuto()
  if (stepIndex.value > 0) stepIndex.value -= 1
}
function replay() {
  clearAuto()
  stepIndex.value = 0
}
function toggleAuto() {
  if (isAuto.value) return clearAuto()
  if (stepIndex.value >= lastIndex) stepIndex.value = 0
  isAuto.value = true
  tickAuto()
}
function tickAuto() {
  autoTimer = setTimeout(() => {
    if (!isAuto.value) return
    if (stepIndex.value < lastIndex) {
      stepIndex.value += 1
      tickAuto()
    } else {
      isAuto.value = false
    }
  }, 2100)
}
const atEnd = computed(() => stepIndex.value >= lastIndex)
onUnmounted(clearAuto)
</script>

<template>
  <div class="my-2 rounded-lg bg-[rgb(var(--color-fill))] p-4">
    <!-- Header + controls -->
    <div class="mb-2 flex flex-wrap items-center justify-between gap-2">
      <h3 class="text-base font-semibold text-[rgb(var(--color-text-base))]">
        Four types of memory → the context window
      </h3>
      <div class="flex items-center gap-2">
        <button
          class="rounded border border-[rgb(var(--color-border))] px-3 py-1 text-sm text-[rgb(var(--color-text-base))] transition hover:opacity-80 disabled:opacity-30"
          :disabled="stepIndex === 0"
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
    <div class="mb-3 flex flex-wrap items-center gap-1.5 text-xs">
      <template v-for="(s, i) in STEPS" :key="s.id">
        <span
          class="rounded-full px-2.5 py-0.5 transition-all duration-300"
          :class="i === stepIndex ? 'font-semibold' : i < stepIndex ? 'opacity-50' : 'opacity-30'"
          :style="
            i === stepIndex
              ? { background: s.color, color: 'rgb(var(--color-fill))' }
              : { background: 'rgb(var(--color-card))', color: 'rgb(var(--color-text-base))' }
          "
        >
          {{ s.icon }} {{ s.name }}
        </span>
      </template>
      <span
        class="rounded-full px-2.5 py-0.5 transition-all duration-300"
        :class="isSummary ? 'font-semibold' : 'opacity-30'"
        :style="
          isSummary
            ? { background: 'rgb(var(--color-accent))', color: 'rgb(var(--color-fill))' }
            : { background: 'rgb(var(--color-card))', color: 'rgb(var(--color-text-base))' }
        "
      >
        ✦ All four
      </span>
    </div>

    <!-- Stage: stores (left) stream into working memory (right) -->
    <div class="grid grid-cols-[1fr_auto_1.1fr] items-stretch gap-3">
      <!-- Stores on disk -->
      <div class="flex flex-col gap-2">
        <div class="text-[10px] font-semibold uppercase tracking-wider text-[rgb(var(--color-text-base))] opacity-40">
          On disk · stores
        </div>
        <motion.div
          v-for="store in STORES"
          :key="store.id"
          layout
          :animate="{
            opacity: storeRevealed(store) ? 1 : 0.25,
            scale: storeActive(store) ? 1.02 : 1,
          }"
          :transition="{ type: 'spring', stiffness: 280, damping: 24 }"
          class="rounded-lg border-2 px-3 py-1.5"
          :style="{
            background: 'rgb(var(--color-card))',
            borderColor: storeRevealed(store) ? store.color : 'rgb(var(--color-border))',
            boxShadow: storeActive(store) ? `0 0 0 3px ${store.color}55` : 'none',
          }"
        >
          <div class="flex items-center gap-2">
            <span class="text-lg leading-none">{{ store.icon }}</span>
            <span class="text-sm font-semibold" :style="{ color: store.color }">{{ store.name }}</span>
            <span class="ml-auto text-[10px] opacity-50 text-[rgb(var(--color-text-base))]">{{ store.analogy }}</span>
          </div>
          <div class="mt-1 font-mono text-[11px] leading-tight text-[rgb(var(--color-text-base))] opacity-80">
            {{ store.claudeCode }}
          </div>
        </motion.div>
      </div>

      <!-- Connectors -->
      <div class="flex flex-col justify-center gap-2 pt-5">
        <div
          v-for="store in STORES"
          :key="store.id"
          class="connector relative h-9"
          :class="connectorFlowing(store) ? 'is-on' : ''"
          :style="{ '--wire': store.color } as any"
        >
          <span class="arrow" :style="{ color: connectorFlowing(store) ? store.color : 'rgb(var(--color-border))' }">▸</span>
        </div>
      </div>

      <!-- Working memory hub -->
      <motion.div
        layout
        :animate="{ scale: workingActive ? 1.015 : 1 }"
        :transition="{ type: 'spring', stiffness: 280, damping: 24 }"
        class="flex flex-col rounded-xl border-2 p-3"
        :style="{
          background: 'rgb(var(--color-card))',
          borderColor: WORKING.color,
          boxShadow: workingActive ? `0 0 0 3px ${WORKING.color}55` : `0 0 22px ${WORKING.color}22`,
        }"
      >
        <div class="flex items-center gap-2">
          <span class="text-xl leading-none">{{ WORKING.icon }}</span>
          <div class="leading-tight">
            <div class="text-sm font-bold" :style="{ color: WORKING.color }">Working memory</div>
            <div class="text-[10px] opacity-50 text-[rgb(var(--color-text-base))]">the context window · RAM</div>
          </div>
        </div>

        <!-- fill bar -->
        <div class="mt-2 flex justify-between text-[10px] text-[rgb(var(--color-text-base))] opacity-50">
          <span>loaded into context</span>
          <span>{{ fillPercentage }}%</span>
        </div>
        <div class="mt-1 h-2 overflow-hidden rounded-full bg-[rgb(var(--color-fill))]">
          <div
            class="h-full transition-all duration-500"
            :style="{ width: `${fillPercentage}%`, background: WORKING.color }"
          />
        </div>

        <!-- what's loaded -->
        <div class="mt-2.5 flex flex-1 flex-wrap content-start gap-1.5">
          <span class="chip" :style="{ borderColor: WORKING.color, color: WORKING.color }">system prompt</span>
          <span class="chip" :style="{ borderColor: WORKING.color, color: WORKING.color }">conversation</span>
          <motion.span
            v-for="store in STORES.filter(storeRevealed)"
            :key="store.id"
            :initial="{ opacity: 0, x: -10, scale: 0.8 }"
            :animate="{ opacity: 1, x: 0, scale: 1 }"
            :transition="{ type: 'spring', stiffness: 320, damping: 22 }"
            class="chip"
            :style="{ borderColor: store.color, color: store.color }"
          >
            {{ store.icon }} {{ store.name.toLowerCase() }}
          </motion.span>
        </div>
      </motion.div>
    </div>

    <!-- Detail panel -->
    <div
      class="mt-3 min-h-[4.5rem] rounded-lg border-l-4 bg-[rgb(var(--color-card))] px-4 py-2"
      :style="{ borderColor: detail ? detail.color : 'rgb(var(--color-accent))' }"
    >
      <template v-if="detail">
        <div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
          <span class="text-base font-bold" :style="{ color: detail.color }">
            {{ detail.icon }} {{ detail.name }} memory
          </span>
          <span class="text-xs italic text-[rgb(var(--color-text-base))] opacity-70">
            human: {{ detail.human }}
          </span>
        </div>
        <div class="mt-1.5 grid grid-cols-2 gap-x-4 text-xs text-[rgb(var(--color-text-base))]">
          <div><span class="opacity-50">In Claude Code:</span> <span class="font-mono opacity-90">{{ detail.claudeCode }}</span></div>
          <div><span class="opacity-50">Manage with:</span> <span class="font-mono opacity-90">{{ detail.manage }}</span></div>
        </div>
        <p class="mt-1.5 text-sm leading-snug text-[rgb(var(--color-text-base))] opacity-90">{{ caption }}</p>
      </template>
      <template v-else>
        <div class="text-base font-bold text-[rgb(var(--color-accent))]">✦ Match the memory to the job</div>
        <p class="mt-1 text-sm leading-snug text-[rgb(var(--color-text-base))] opacity-90">{{ caption }}</p>
        <div class="mt-2 flex flex-wrap gap-2 text-[11px]">
          <span class="chip" :style="{ borderColor: WORKING.color, color: WORKING.color }">Thermostat → working</span>
          <span class="chip" :style="{ borderColor: STORES[1].color, color: STORES[1].color }">Support bot → working + procedural</span>
          <span class="chip" :style="{ borderColor: 'rgb(var(--color-accent))', color: 'rgb(var(--color-accent))' }">Coding agent → all four</span>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.chip {
  border-width: 1px;
  border-style: solid;
  border-radius: 9999px;
  padding: 1px 8px;
  font-size: 11px;
  line-height: 1.4;
  white-space: nowrap;
}

.connector {
  display: flex;
  align-items: center;
}
.connector::before {
  content: '';
  flex: 1;
  height: 2px;
  border-radius: 2px;
  background: rgb(var(--color-border));
  opacity: 0.4;
  transition: opacity 0.4s;
}
.connector.is-on::before {
  opacity: 1;
  background: linear-gradient(
    90deg,
    transparent,
    var(--wire) 20%,
    var(--wire) 80%,
    transparent
  );
  background-size: 200% 100%;
  animation: flow 1.3s linear infinite;
}
.arrow {
  margin-left: 2px;
  font-size: 13px;
  transition: color 0.4s;
}
@keyframes flow {
  from {
    background-position: 200% 0;
  }
  to {
    background-position: 0% 0;
  }
}
</style>
