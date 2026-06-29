<script setup lang="ts">
defineProps<{
  image?: string
}>()
</script>

<template>
  <div class="grid grid-cols-2 gap-8 h-full">
    <div class="flex flex-col justify-center items-center">
      <img class="w-75 rounded-full" :src="image ?? 'https://avatars.githubusercontent.com/u/33398393?v=4'" />
      <h2 class="mt-4">Alex Opalic</h2>
    </div>
    <div>
      <VClicks class="space-y-2 mt-10 text-xl">
        <ul>
          <li>🚀 8 years building with Vue</li>
          <li>💼 Developer at Otto Payments</li>
          <li>🏡 Based in Geretsried (south of Munich, Bavaria)</li>
          <li>✍️ Blogger at alexop.dev</li>
          <li>🎤 Sharing & speaking about Vue, testing & GraphQL & Ai</li>
        </ul>
      </VClicks>
    </div>
  </div>
</template>
