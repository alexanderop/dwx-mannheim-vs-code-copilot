<script setup lang="ts">
import { ref, computed, watch, onUnmounted } from 'vue'

interface Block {
  id: string
  type: 'system' | 'doc' | 'memory' | 'tool' | 'user' | 'history' | 'summary'
  label: string
  tokens: number
  isVisible: boolean
  isFadingOut: boolean
}

const BLOCK_COLORS: Record<Block['type'], string> = {
  system: '#3B82F6', // Blue
  doc: '#10B981', // Green
  memory: '#8B5CF6', // Purple
  tool: '#F97316', // Orange
  user: '#EAB308', // Yellow
  history: '#6B7280', // Gray
  summary: 'linear-gradient(135deg, #6366F1 0%, #8B5CF6 50%, #A855F7 100%)',
}

const INITIAL_BLOCKS: Block[] = [
  {
    id: 'system',
    type: 'system',
    label: 'System Prompt',
    tokens: 2000,
    isVisible: true,
    isFadingOut: false,
  },
]

const BLOCKS_TO_ADD: Omit<Block, 'isVisible' | 'isFadingOut'>[] = [
  { id: 'doc1', type: 'doc', label: 'Doc 1', tokens: 3000 },
  { id: 'doc2', type: 'doc', label: 'Doc 2', tokens: 2500 },
  { id: 'memory', type: 'memory', label: 'Memory File', tokens: 1500 },
  { id: 'tool1', type: 'tool', label: 'Tool 1', tokens: 800 },
  { id: 'tool2', type: 'tool', label: 'Tool 2', tokens: 700 },
  { id: 'user1', type: 'user', label: 'User Message 1', tokens: 500 },
  { id: 'history1', type: 'history', label: 'Message History 1', tokens: 2000 },
  { id: 'user2', type: 'user', label: 'User Message 2', tokens: 600 },
  { id: 'history2', type: 'history', label: 'Message History 2', tokens: 2500 },
  { id: 'user3', type: 'user', label: 'User Message 3', tokens: 700 },
  { id: 'history3', type: 'history', label: 'Message History 3', tokens: 3000 },
]

const MAX_TOKENS = 20000
const COMPACTION_THRESHOLD = 0.9

const blocks = ref<Block[]>(INITIAL_BLOCKS.map(b => ({ ...b })))
const isPlaying = ref(false)
const isCompacting = ref(false)
const blockIndex = ref(0)
const speed = ref(1)

const totalTokens = computed(() =>
  blocks.value
    .filter(b => b.isVisible && !b.isFadingOut)
    .reduce((sum, b) => sum + b.tokens, 0),
)

const fillPercentage = computed(() => (totalTokens.value / MAX_TOKENS) * 100)

const progressColor = computed(() => {
  if (fillPercentage.value >= 90) return '#EF4444' // Red
  if (fillPercentage.value >= 75) return '#F59E0B' // Amber
  return '#10B981' // Green
})

const visibleBlocks = computed(() => blocks.value.filter(b => b.isVisible))
const legendEntries = Object.entries(BLOCK_COLORS) as [Block['type'], string][]

let compactionTimeout: ReturnType<typeof setTimeout> | undefined

function performCompaction() {
  isCompacting.value = true

  // Mark compactible blocks (history and older user messages) as fading out
  const compactibleTypes = ['history', 'user']
  const compactibleIds = blocks.value
    .filter(b => compactibleTypes.includes(b.type) && b.isVisible)
    .slice(0, -1) // Keep the most recent one
    .map(b => b.id)

  blocks.value = blocks.value.map(b =>
    compactibleIds.includes(b.id) ? { ...b, isFadingOut: true } : b,
  )

  // After fade out, replace with summary
  compactionTimeout = setTimeout(() => {
    const compactedTokens = blocks.value
      .filter(b => b.isFadingOut)
      .reduce((sum, b) => sum + b.tokens, 0)

    const withoutFaded = blocks.value.filter(b => !b.isFadingOut)
    const existingSummary = withoutFaded.find(b => b.type === 'summary')

    if (existingSummary) {
      blocks.value = withoutFaded.map(b =>
        b.type === 'summary'
          ? {
              ...b,
              tokens: b.tokens + Math.floor(compactedTokens * 0.2),
              label: 'Conversation Summary (expanded)',
            }
          : b,
      )
    } else {
      const fixedTypes = ['system', 'doc', 'memory', 'tool']
      const fixedBlocks = withoutFaded.filter(b => fixedTypes.includes(b.type))
      const otherBlocks = withoutFaded.filter(b => !fixedTypes.includes(b.type))

      const summaryBlock: Block = {
        id: `summary-${Date.now()}`,
        type: 'summary',
        label: 'Conversation Summary',
        tokens: Math.floor(compactedTokens * 0.2), // Compressed to 20%
        isVisible: true,
        isFadingOut: false,
      }

      blocks.value = [...fixedBlocks, summaryBlock, ...otherBlocks]
    }

    isCompacting.value = false
  }, 800 / speed.value)
}

function addNextBlock() {
  if (blockIndex.value >= BLOCKS_TO_ADD.length) {
    isPlaying.value = false
    return
  }

  const blockToAdd = BLOCKS_TO_ADD[blockIndex.value]
  const projectedTokens = totalTokens.value + blockToAdd.tokens

  // Check if we need to compact before adding
  if (
    projectedTokens / MAX_TOKENS >= COMPACTION_THRESHOLD &&
    !isCompacting.value
  ) {
    performCompaction()
    return // Don't increment index, try again after compaction
  }

  blocks.value = [
    ...blocks.value,
    { ...blockToAdd, isVisible: true, isFadingOut: false },
  ]
  blockIndex.value += 1
}

let playInterval: ReturnType<typeof setInterval> | undefined

function clearPlayInterval() {
  if (playInterval) {
    clearInterval(playInterval)
    playInterval = undefined
  }
}

// Mirrors the React effect: (re)start the tick whenever play state, compaction
// state, or speed changes.
watch(
  [isPlaying, isCompacting, speed],
  () => {
    clearPlayInterval()
    if (!isPlaying.value || isCompacting.value) return
    playInterval = setInterval(() => {
      addNextBlock()
    }, 1200 / speed.value)
  },
  { immediate: true },
)

onUnmounted(() => {
  clearPlayInterval()
  if (compactionTimeout) clearTimeout(compactionTimeout)
})

function togglePlay() {
  isPlaying.value = !isPlaying.value
}

function reset() {
  blocks.value = INITIAL_BLOCKS.map(b => ({ ...b }))
  blockIndex.value = 0
  isPlaying.value = false
  isCompacting.value = false
}

function blockMinWidth(block: Block): string {
  return `${Math.max(30, (block.tokens / MAX_TOKENS) * 100)}%`
}
</script>

<template>
  <div class="my-8 rounded-lg bg-[rgb(var(--color-fill))] p-4">
    <!-- Header with controls -->
    <div class="mb-4 flex flex-wrap items-center justify-between gap-2">
      <h3 class="text-lg font-semibold text-[rgb(var(--color-text-base))]">
        Context Window Visualization
      </h3>
      <div class="flex items-center gap-2">
        <select
          v-model.number="speed"
          class="rounded border border-[rgb(var(--color-border))] bg-[rgb(var(--color-card))] px-2 py-1 text-sm text-[rgb(var(--color-text-base))]"
        >
          <option :value="0.5">0.5x</option>
          <option :value="1">1x</option>
          <option :value="2">2x</option>
          <option :value="3">3x</option>
        </select>
        <button
          class="rounded bg-[rgb(var(--color-accent))] px-3 py-1 text-sm text-[rgb(var(--color-fill))] transition hover:opacity-80"
          @click="togglePlay"
        >
          {{ isPlaying ? 'Pause' : 'Play' }}
        </button>
        <button
          class="rounded border border-[rgb(var(--color-border))] px-3 py-1 text-sm text-[rgb(var(--color-text-base))] transition hover:opacity-80"
          @click="reset"
        >
          Reset
        </button>
      </div>
    </div>

    <!-- Progress bar -->
    <div class="mb-4">
      <div class="mb-1 flex justify-between text-xs text-[rgb(var(--color-text-base))] opacity-60">
        <span>
          {{ totalTokens.toLocaleString() }} / {{ MAX_TOKENS.toLocaleString() }} tokens
        </span>
        <span>{{ fillPercentage.toFixed(1) }}%</span>
      </div>
      <div class="h-3 overflow-hidden rounded-full bg-[rgb(var(--color-card))]">
        <div
          class="h-full transition-all duration-300"
          :style="{
            width: `${Math.min(fillPercentage, 100)}%`,
            backgroundColor: progressColor,
          }"
        />
      </div>
    </div>

    <!-- Context window container -->
    <div class="relative max-h-[400px] min-h-[300px] overflow-y-auto rounded-lg border-2 border-dashed border-[rgb(var(--color-border))] bg-[rgb(var(--color-card))] p-4">
      <div class="flex flex-col gap-2">
        <div
          v-for="block in visibleBlocks"
          :key="block.id"
          class="flex items-center justify-between rounded-full px-4 py-2 text-sm font-medium text-white"
          :class="block.isFadingOut ? 'block-fade-out' : 'block-fade-in'"
          :style="{
            background: BLOCK_COLORS[block.type],
            minWidth: blockMinWidth(block),
          }"
        >
          <span>{{ block.label }}</span>
          <span class="ml-2 text-xs opacity-80">
            {{ block.tokens.toLocaleString() }}
          </span>
        </div>
      </div>

      <!-- Compaction indicator -->
      <div v-if="isCompacting" class="absolute inset-x-0 bottom-4 flex justify-center">
        <div class="scissors-animate flex items-center gap-2 rounded-full bg-red-500 px-4 py-2 text-sm text-white">
          <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              :stroke-width="2"
              d="M14.121 14.121L19 19m-7-7l7-7m-7 7l-2.879 2.879M12 12L9.121 9.121m0 5.758a3 3 0 10-4.243 4.243 3 3 0 004.243-4.243zm0-5.758a3 3 0 10-4.243-4.243 3 3 0 004.243 4.243z"
            />
          </svg>
          Compacting...
        </div>
      </div>
    </div>

    <!-- Legend -->
    <div class="mt-4 flex flex-wrap gap-3 text-xs">
      <div v-for="[type, color] in legendEntries" :key="type" class="flex items-center gap-1">
        <div class="h-3 w-3 rounded-full" :style="{ background: color }" />
        <span class="text-[rgb(var(--color-text-base))] opacity-60">
          {{ type === 'summary' ? 'conversation summary' : type }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
@keyframes fadeOut {
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.8);
  }
}
@keyframes pulse {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}
.block-fade-in {
  animation: fadeIn 0.4s ease-out forwards;
}
.block-fade-out {
  animation: fadeOut 0.6s ease-in forwards;
}
.scissors-animate {
  animation: pulse 0.5s ease-in-out infinite;
}
</style>
