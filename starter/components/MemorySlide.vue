<script setup lang="ts">
withDefaults(
  defineProps<{
    icon: string
    title: string
    accentClass: string
    borderClass: string
  }>(),
  {},
)
</script>

<template>
  <div>
    <h2>{{ icon }} {{ title }}</h2>

    <div class="text-xl opacity-80 mb-6 max-w-3xl">
      <slot name="description" />
    </div>

    <div class="rounded-lg border-2 p-5 max-w-3xl" :class="borderClass">
      <div class="font-bold mb-2" :class="accentClass">In VS Code Copilot</div>
      <slot />
    </div>
  </div>
</template>
