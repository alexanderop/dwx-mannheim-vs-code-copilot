<script setup lang="ts">
import { ref, computed } from 'vue'
import { motion } from 'motion-v'

interface ZoneConfig {
  name: string
  range: [number, number]
  color: string
  bgColor: string
  description: string
}

const ZONES: ZoneConfig[] = [
  {
    name: 'Smart Zone',
    range: [0, 40],
    color: 'rgb(34, 197, 94)', // green-500
    bgColor: 'rgba(34, 197, 94, 0.2)',
    description: 'Peak performance - full attention to your task',
  },
  {
    name: 'Optimal Zone',
    range: [40, 60],
    color: 'rgb(234, 179, 8)', // yellow-500
    bgColor: 'rgba(234, 179, 8, 0.2)',
    description: 'Good performance - slight context compression',
  },
  {
    name: 'Degraded Zone',
    range: [60, 80],
    color: 'rgb(249, 115, 22)', // orange-500
    bgColor: 'rgba(249, 115, 22, 0.2)',
    description: 'Degraded recall - important details may be missed',
  },
  {
    name: 'Critical Zone',
    range: [80, 100],
    color: 'rgb(239, 68, 68)', // red-500
    bgColor: 'rgba(239, 68, 68, 0.2)',
    description: "Critical - experiencing 'lost in the middle' effects",
  },
]

function getZone(percentage: number): ZoneConfig {
  return (
    ZONES.find(zone => percentage >= zone.range[0] && percentage < zone.range[1]) ||
    ZONES[ZONES.length - 1]
  )
}

// Interpolate between values based on percentage
function lerp(start: number, end: number, t: number): number {
  return start + (end - start) * t
}

interface FaceExpression {
  mouthCurve: number
  eyeOpenness: number
  eyeSize: number
  hasXEyes: boolean
  pupilY: number
  eyebrowAngle: number
}

function getFaceExpression(percentage: number): FaceExpression {
  if (percentage <= 40) {
    // Happy face
    const t = percentage / 40
    return { mouthCurve: lerp(15, 8, t), eyeOpenness: 1, eyeSize: lerp(6, 5, t), hasXEyes: false, pupilY: 0, eyebrowAngle: lerp(-5, 0, t) }
  }
  if (percentage <= 60) {
    // Neutral face
    const t = (percentage - 40) / 20
    return { mouthCurve: lerp(8, 0, t), eyeOpenness: 1, eyeSize: 5, hasXEyes: false, pupilY: 0, eyebrowAngle: 0 }
  }
  if (percentage <= 80) {
    // Worried face
    const t = (percentage - 60) / 20
    return { mouthCurve: lerp(0, -10, t), eyeOpenness: lerp(1, 0.7, t), eyeSize: lerp(5, 4, t), hasXEyes: false, pupilY: lerp(0, 2, t), eyebrowAngle: lerp(0, 10, t) }
  }
  // Dead/overwhelmed face
  const t = (percentage - 80) / 20
  return { mouthCurve: lerp(-10, -5, t), eyeOpenness: lerp(0.7, 0, t), hasXEyes: percentage > 90, eyeSize: 4, pupilY: 3, eyebrowAngle: lerp(10, 15, t) }
}

const percentage = ref(25)

const zone = computed(() => getZone(percentage.value))
const face = computed(() => getFaceExpression(percentage.value))
const zoneColor = computed(() => zone.value.color)

const sliderBackground =
  `linear-gradient(to right,` +
  ` rgb(34, 197, 94) 0%,` +
  ` rgb(34, 197, 94) 40%,` +
  ` rgb(234, 179, 8) 40%,` +
  ` rgb(234, 179, 8) 60%,` +
  ` rgb(249, 115, 22) 60%,` +
  ` rgb(249, 115, 22) 80%,` +
  ` rgb(239, 68, 68) 80%,` +
  ` rgb(239, 68, 68) 100%)`

const transition03 = { duration: 0.3 }

function mouthPath(curve: number): string {
  return `M 30 65 Q 50 ${65 + curve} 70 65`
}
</script>

<template>
  <div class="w-full max-w-2xl mx-auto my-8">
    <div class="rounded-lg overflow-hidden border border-[rgb(var(--color-border))] shadow-2xl">
      <!-- Content -->
      <div class="bg-[rgb(var(--color-fill))] font-mono text-sm p-6">
        <!-- Zone Bar -->
        <div class="mb-8">
          <div class="relative">
            <!-- Background zones -->
            <div class="h-10 flex rounded-lg overflow-hidden border border-[rgb(var(--color-border))]">
              <div
                v-for="z in ZONES"
                :key="z.name"
                class="h-full flex items-center justify-center text-xs font-medium transition-opacity"
                :style="{
                  width: `${z.range[1] - z.range[0]}%`,
                  backgroundColor: z.bgColor,
                  color: z.color,
                  opacity: percentage >= z.range[0] && percentage < z.range[1] ? 1 : 0.4,
                }"
              >
                {{ z.name.split(' ')[0] }}
              </div>
            </div>

            <!-- Percentage markers -->
            <div class="flex justify-between mt-1 text-xs text-[rgb(var(--color-text-base))] opacity-50">
              <span>0%</span>
              <span style="margin-left: 30%">40%</span>
              <span style="margin-left: 10%">60%</span>
              <span style="margin-left: 10%">80%</span>
              <span>100%</span>
            </div>

            <!-- Current position indicator -->
            <motion.div
              class="absolute top-0 w-1 h-10 bg-white rounded-full shadow-lg"
              :style="{ boxShadow: `0 0 8px ${zone.color}` }"
              :animate="{ left: `calc(${percentage}% - 2px)` }"
              :transition="{ type: 'spring', stiffness: 300, damping: 30 }"
            />
          </div>
        </div>

        <!-- Face and Percentage Display -->
        <div class="flex items-center justify-center gap-8 mb-8">
          <svg viewBox="0 0 100 100" class="w-24 h-24">
            <!-- Face circle -->
            <motion.circle
              cx="50"
              cy="50"
              r="45"
              :fill="zone.bgColor"
              :stroke="zone.color"
              stroke-width="3"
              :animate="{ fill: zone.bgColor, stroke: zone.color }"
              :transition="transition03"
            />

            <!-- Left eye -->
            <g v-if="face.hasXEyes">
              <motion.line x1="28" y1="35" x2="38" y2="45" :stroke="zone.color" stroke-width="3" stroke-linecap="round" :animate="{ stroke: zone.color }" :transition="transition03" />
              <motion.line x1="38" y1="35" x2="28" y2="45" :stroke="zone.color" stroke-width="3" stroke-linecap="round" :animate="{ stroke: zone.color }" :transition="transition03" />
            </g>
            <g v-else>
              <motion.ellipse
                cx="33"
                cy="40"
                :rx="face.eyeSize"
                :ry="face.eyeSize * face.eyeOpenness"
                :fill="zone.color"
                :animate="{ ry: face.eyeSize * face.eyeOpenness, fill: zone.color }"
                :transition="transition03"
              />
              <motion.circle
                v-if="face.eyeOpenness > 0.3"
                cx="33"
                r="2"
                fill="white"
                :animate="{ cy: 38 + face.pupilY }"
                :transition="transition03"
              />
            </g>

            <!-- Right eye -->
            <g v-if="face.hasXEyes">
              <motion.line x1="62" y1="35" x2="72" y2="45" :stroke="zone.color" stroke-width="3" stroke-linecap="round" :animate="{ stroke: zone.color }" :transition="transition03" />
              <motion.line x1="72" y1="35" x2="62" y2="45" :stroke="zone.color" stroke-width="3" stroke-linecap="round" :animate="{ stroke: zone.color }" :transition="transition03" />
            </g>
            <g v-else>
              <motion.ellipse
                cx="67"
                cy="40"
                :rx="face.eyeSize"
                :ry="face.eyeSize * face.eyeOpenness"
                :fill="zone.color"
                :animate="{ ry: face.eyeSize * face.eyeOpenness, fill: zone.color }"
                :transition="transition03"
              />
              <motion.circle
                v-if="face.eyeOpenness > 0.3"
                cx="67"
                r="2"
                fill="white"
                :animate="{ cy: 38 + face.pupilY }"
                :transition="transition03"
              />
            </g>

            <!-- Eyebrows -->
            <motion.line
              x1="25"
              x2="40"
              :stroke="zone.color"
              stroke-width="2"
              stroke-linecap="round"
              :animate="{ y1: 28 - face.eyebrowAngle * 0.3, y2: 28 + face.eyebrowAngle * 0.3, stroke: zone.color }"
              :transition="transition03"
            />
            <motion.line
              x1="60"
              x2="75"
              :stroke="zone.color"
              stroke-width="2"
              stroke-linecap="round"
              :animate="{ y1: 28 + face.eyebrowAngle * 0.3, y2: 28 - face.eyebrowAngle * 0.3, stroke: zone.color }"
              :transition="transition03"
            />

            <!-- Mouth -->
            <motion.path
              :d="mouthPath(face.mouthCurve)"
              fill="none"
              :stroke="zone.color"
              stroke-width="3"
              stroke-linecap="round"
              :animate="{ d: mouthPath(face.mouthCurve), stroke: zone.color }"
              :transition="transition03"
            />

            <!-- Sweat drop when stressed -->
            <motion.ellipse
              v-if="percentage > 70"
              cx="78"
              cy="35"
              rx="4"
              ry="6"
              fill="rgba(96, 165, 250, 0.6)"
              :initial="{ opacity: 0, y: -5 }"
              :animate="{ opacity: percentage > 70 ? 0.8 : 0, y: 0 }"
              :transition="transition03"
            />
          </svg>

          <div class="text-center">
            <div class="text-4xl font-bold mb-1" :style="{ color: zone.color }">
              {{ percentage }}%
            </div>
            <div class="text-sm font-medium" :style="{ color: zone.color }">
              {{ zone.name }}
            </div>
          </div>
        </div>

        <!-- Interactive Slider -->
        <div>
          <input
            v-model.number="percentage"
            type="range"
            min="0"
            max="99"
            class="utilization-slider w-full h-3 rounded-lg appearance-none cursor-pointer"
            :style="{ background: sliderBackground }"
          >
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.utilization-slider::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: white;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
  border: 2px solid v-bind(zoneColor);
  transition: border-color 0.3s;
}
.utilization-slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: white;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
  border: 2px solid v-bind(zoneColor);
}
</style>
