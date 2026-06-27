<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'

interface Message {
  role: 'system' | 'user' | 'assistant' | 'tool'
  content: string
  tokens: number
}

const INITIAL_MESSAGES: Message[] = [
  { role: 'system', content: 'System prompt + CLAUDE.md', tokens: 3100 },
]

const MAX_TOKENS = 200000

// Simple token estimation: ~4 characters per token
function estimateTokens(text: string): number {
  return Math.max(1, Math.ceil(text.length / 4))
}

function formatTokens(tokens: number): string {
  if (tokens >= 1000) {
    return `${(tokens / 1000).toFixed(1)}k`
  }
  return tokens.toString()
}

function getRoleColor(role: Message['role']): string {
  switch (role) {
    case 'system':
      return 'text-purple-400'
    case 'user':
      return 'text-blue-400'
    case 'assistant':
      return 'text-green-400'
    case 'tool':
      return 'text-yellow-400'
    default:
      return 'text-[rgb(var(--color-text-base))]'
  }
}

function getRoleLabel(role: Message['role']): string {
  switch (role) {
    case 'system':
      return 'System'
    case 'user':
      return 'User'
    case 'assistant':
      return 'Assistant'
    case 'tool':
      return 'Tool result'
    default:
      return role
  }
}

const messages = ref<Message[]>([...INITIAL_MESSAGES])
const input = ref('')
const cursorVisible = ref(true)
const scrollContainer = ref<HTMLDivElement | null>(null)

const totalTokens = computed(() =>
  messages.value.reduce((sum, msg) => sum + msg.tokens, 0),
)
const percentageUsed = computed(() => (totalTokens.value / MAX_TOKENS) * 100)
const percentageRemaining = computed(() => 100 - percentageUsed.value)

let cursorInterval: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  cursorInterval = setInterval(() => {
    cursorVisible.value = !cursorVisible.value
  }, 530)
})

onUnmounted(() => {
  if (cursorInterval) clearInterval(cursorInterval)
})

watch(
  messages,
  () => {
    nextTick(() => {
      if (scrollContainer.value) {
        scrollContainer.value.scrollTop = scrollContainer.value.scrollHeight
      }
    })
  },
  { deep: true },
)

function handleSubmit() {
  if (!input.value.trim()) return

  const userTokens = estimateTokens(input.value)
  const userMessage: Message = {
    role: 'user',
    content: input.value,
    tokens: userTokens,
  }

  const assistantContent = `I'll help you with "${input.value.slice(0, 30)}${input.value.length > 30 ? '...' : ''}"`
  const assistantMessage: Message = {
    role: 'assistant',
    content: assistantContent,
    tokens: estimateTokens(assistantContent),
  }

  messages.value = [...messages.value, userMessage, assistantMessage]
  input.value = ''
}

function handleReset() {
  messages.value = [...INITIAL_MESSAGES]
  input.value = ''
}

function truncate(content: string): string {
  return content.length > 50 ? content.slice(0, 50) + '...' : content
}
</script>

<template>
  <div class="w-full max-w-3xl mx-auto h-full flex flex-col py-2">
    <!-- Terminal Window -->
    <div class="flex flex-col min-h-0 flex-1 rounded-lg overflow-hidden border border-[rgb(var(--color-border))] shadow-2xl">
      <!-- Title Bar -->
      <div class="flex items-center gap-2 px-4 py-3 bg-[rgb(var(--color-card))] border-b border-[rgb(var(--color-border))]">
        <div class="flex gap-2">
          <div class="w-3 h-3 rounded-full bg-red-500/80" />
          <div class="w-3 h-3 rounded-full bg-yellow-500/80" />
          <div class="w-3 h-3 rounded-full bg-green-500/80" />
        </div>
        <div class="flex-1 text-center">
          <span class="text-sm text-[rgb(var(--color-text-base))] opacity-60 font-mono">
            context-window-demo
          </span>
        </div>
        <button
          class="text-xs px-2 py-1 rounded border border-[rgb(var(--color-border))] text-[rgb(var(--color-text-base))] opacity-60 hover:opacity-100 hover:border-[rgb(var(--color-accent))] transition-all"
          @click="handleReset"
        >
          Reset
        </button>
      </div>

      <!-- Terminal Content -->
      <div class="flex flex-col min-h-0 flex-1 bg-[rgb(var(--color-fill))] font-mono text-sm">
        <!-- Token Usage Header -->
        <div class="px-4 py-3 border-b border-[rgb(var(--color-border))]">
          <div class="flex items-center justify-between mb-2">
            <span class="text-[rgb(var(--color-accent))]">CONTEXT WINDOW</span>
            <span class="text-[rgb(var(--color-text-base))] opacity-70">
              {{ formatTokens(totalTokens) }} / {{ formatTokens(MAX_TOKENS) }} tokens ({{ percentageUsed.toFixed(1) }}%)
            </span>
          </div>

          <!-- Progress Bar -->
          <div class="h-2 bg-[rgb(var(--color-card))] rounded-full overflow-hidden">
            <div
              class="h-full bg-[rgb(var(--color-accent))] transition-all duration-300"
              :style="{ width: `${Math.min(percentageUsed, 100)}%` }"
            />
          </div>
          <div class="flex justify-between mt-1 text-xs text-[rgb(var(--color-text-base))] opacity-50">
            <span>Used: {{ percentageUsed.toFixed(1) }}%</span>
            <span>Remaining: {{ percentageRemaining.toFixed(1) }}%</span>
          </div>
        </div>

        <!-- Messages Array Visualization -->
        <div ref="scrollContainer" class="p-4 flex-1 min-h-0 overflow-y-auto">
          <div class="border border-[rgb(var(--color-border))] rounded">
            <!-- Array Header -->
            <div class="px-3 py-2 bg-[rgb(var(--color-card))] border-b border-[rgb(var(--color-border))] text-xs text-[rgb(var(--color-text-base))] opacity-70">
              messages: Message[] = [
            </div>

            <!-- Array Items -->
            <div class="divide-y divide-[rgb(var(--color-border))]">
              <div
                v-for="(msg, index) in messages"
                :key="index"
                class="px-3 py-2 flex items-start gap-3 hover:bg-[rgb(var(--color-card))] transition-colors"
              >
                <span class="text-[rgb(var(--color-text-base))] opacity-50 w-16 flex-shrink-0">
                  [{{ index }}]
                </span>
                <div class="flex-1 min-w-0">
                  <span :class="`${getRoleColor(msg.role)} font-medium`">
                    {{ getRoleLabel(msg.role) }}:
                  </span>
                  <span class="text-[rgb(var(--color-text-base))] ml-2 break-words">
                    "{{ truncate(msg.content) }}"
                  </span>
                </div>
                <span class="text-[rgb(var(--color-text-base))] opacity-50 text-xs flex-shrink-0">
                  {{ msg.tokens }} tok
                </span>
              </div>

              <!-- Current position indicator -->
              <div class="px-3 py-2 flex items-center gap-3 text-[rgb(var(--color-accent))]">
                <span class="opacity-50 w-16 flex-shrink-0">[{{ messages.length }}]</span>
                <span class="flex items-center">
                  <span class="mr-2">← You are here</span>
                  <span
                    class="inline-block w-2 h-4 bg-[rgb(var(--color-accent))] transition-opacity duration-100"
                    :class="cursorVisible ? 'opacity-100' : 'opacity-0'"
                  />
                </span>
              </div>
            </div>

            <!-- Array Footer -->
            <div class="px-3 py-2 bg-[rgb(var(--color-card))] border-t border-[rgb(var(--color-border))] text-xs text-[rgb(var(--color-text-base))] opacity-70">
              ]
            </div>
          </div>

          <!-- Yesterday's Session Box -->
          <div class="mt-4 border border-dashed border-[rgb(var(--color-border))] rounded p-3 text-center">
            <div class="text-[rgb(var(--color-text-base))] opacity-50 text-xs mb-1">
              Yesterday's session?
            </div>
            <div class="text-[rgb(var(--color-text-base))] opacity-70">
              ∅ Not in the array. Doesn't exist.
            </div>
          </div>
        </div>

        <!-- Input Area -->
        <form class="flex-shrink-0 border-t border-[rgb(var(--color-border))]" @submit.prevent="handleSubmit">
          <div class="flex items-center px-4 py-3">
            <span class="text-[rgb(var(--color-accent))] mr-2">❯</span>
            <input
              v-model="input"
              type="text"
              placeholder="Type a message to see context fill up..."
              class="flex-1 bg-transparent text-[rgb(var(--color-text-base))] outline-none placeholder:text-[rgb(var(--color-text-base))] placeholder:opacity-30"
            >
            <button
              type="submit"
              class="ml-2 px-3 py-1 rounded border border-[rgb(var(--color-accent))] text-[rgb(var(--color-accent))] text-sm hover:bg-[rgb(var(--color-accent))] hover:text-[rgb(var(--color-fill))] transition-all"
            >
              Send
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Explanation text -->
    <p class="flex-shrink-0 text-center mt-2 text-sm text-[rgb(var(--color-text-base))] opacity-50">
      Each message you send adds to the array. The context window is just a sliding array of messages.
    </p>
  </div>
</template>
