<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{
  /** Path under `public/`, e.g. "/videos/hello-skill.mp4" */
  src: string
  /** Title shown above the player */
  title: string
  /** Optional one-line description of what the clip shows */
  caption?: string
}>()

// Flips to true once the recording actually exists and can play.
// Until then we show the placeholder frame.
const ready = ref(false)
</script>

<template>
  <div class="h-full flex flex-col py-2">
    <!-- Header -->
    <div class="mb-3 flex flex-wrap items-center gap-2 flex-shrink-0">
      <span class="text-2xl">🎥</span>
      <h3 class="text-xl font-semibold text-[rgb(var(--color-text-base))]">
        {{ title }}
      </h3>
      <span
        class="ml-1 rounded-full border border-[rgb(var(--color-accent))] px-2 py-0.5 text-xs uppercase tracking-wide text-[rgb(var(--color-accent))]"
      >
        Recorded demo
      </span>
    </div>

    <!-- Video / placeholder frame -->
    <div
      class="relative flex-1 min-h-0 overflow-hidden rounded-lg border border-[rgb(var(--color-border))] bg-[rgb(var(--color-card))]"
    >
      <video
        :src="src"
        class="absolute inset-0 h-full w-full bg-black object-contain transition-opacity duration-300"
        :class="ready ? 'opacity-100' : 'opacity-0 pointer-events-none'"
        controls
        playsinline
        preload="metadata"
        @canplay="ready = true"
      />

      <!-- Shown until the recording exists -->
      <div
        v-if="!ready"
        class="absolute inset-0 flex flex-col items-center justify-center gap-3 px-6 text-center"
      >
        <div class="text-5xl opacity-70">🎬</div>
        <div class="text-lg text-[rgb(var(--color-text-base))]">
          Record &amp; drop your clip here
        </div>
        <code class="rounded bg-[rgb(var(--color-fill))] px-2 py-1 text-sm text-[rgb(var(--color-accent))]">
          starter/public{{ src }}
        </code>
        <div class="text-xs text-[rgb(var(--color-text-base))] opacity-50">
          The video appears automatically once the file exists.
        </div>
      </div>
    </div>

    <!-- Caption -->
    <p
      v-if="caption"
      class="mt-3 flex-shrink-0 text-center text-sm text-[rgb(var(--color-text-base))] opacity-60"
    >
      {{ caption }}
    </p>
  </div>
</template>
