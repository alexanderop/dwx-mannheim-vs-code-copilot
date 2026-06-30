<script setup lang="ts">
/**
 * FullPictureDiagram - The recap diagram for "The Full Picture", shown AFTER
 * the Hooks section so it can include them.
 *
 * Extends the original agentSum.png layout (AGENTS.md -> Agent Loop -> Tools,
 * Context Engineering -> Skills / Subagents) with the missing piece: Hooks as a
 * deterministic control boundary that wraps the loop and gates tool calls.
 *
 * Three click-paced stages re-tell the whole talk:
 *   1. The runtime core  - AGENTS.md feeds the Agent Loop; loop calls Tools.
 *   2. Context that GUIDES - just-in-time loading -> Skills / Subagents (soft).
 *   3. Hooks that CONTROL  - a dashed boundary around the loop, a PreToolUse
 *      gate on the Tools arrow, lifecycle tags (SessionStart / Stop). Hard.
 *
 * Built on the Rough.js primitives from @alexop/slidev-addon-utils, matching
 * the deck's other hand-drawn diagrams (CompactionCutPoint, OutlineRoadmap).
 */

// --- Palette ---------------------------------------------------------------
const PINK = 'rgba(255,107,237,'
const PURPLE = 'rgba(192,132,252,'

const NODE = { stroke: PINK + '0.85)', fill: PINK + '0.07)' }
const LOOP = { stroke: PINK + '1)', fill: PINK + '0.16)' }
const CTX = { stroke: PURPLE + '0.9)', fill: PURPLE + '0.16)' }
const BRIGHT = { stroke: PINK + '1)', fill: PINK + '0.88)' }
const HOOK = PINK + '0.95)'

const ARROW = 'rgba(234,237,243,0.82)'
const TEXT_LIGHT = 'rgba(245,246,250,0.96)'
const TEXT_DARK = '#2a0521'
const GUIDE_COLOR = PURPLE + '0.95)'
</script>

<template>
  <div class="fp">
    <RoughSvg :width="1000" :height="652" :padding="14" :roughness="1.05" :seed="9">
      <!-- ===================================================================
           STAGE 1 - the runtime core
      ==================================================================== -->
      <g v-click="1">
        <!-- AGENTS.md -->
        <RoughArrow :x1="500" :y1="76" :x2="500" :y2="166" :stroke="ARROW" :stroke-width="2.8" :arrow-size="15" :seed="11" />
        <RoughRect :x="400" :y="10" :width="200" :height="64" :stroke="NODE.stroke" :fill="NODE.fill" :seed="2" />
        <text x="500" y="35" class="t-node">AGENTS.md</text>
        <text x="500" y="58" class="t-sub">always-loaded context</text>
        <text x="620" y="46" class="t-hand">&#8592; project context</text>

        <!-- User Request -> Agent Loop -> Tools -->
        <RoughArrow :x1="224" :y1="206" :x2="396" :y2="206" :stroke="ARROW" :stroke-width="2.8" :arrow-size="15" :seed="12" />
        <RoughArrow :x1="604" :y1="206" :x2="776" :y2="206" :stroke="ARROW" :stroke-width="2.8" :arrow-size="15" :seed="13" />

        <RoughRect :x="40" :y="170" :width="184" :height="72" :stroke="NODE.stroke" :fill="NODE.fill" :seed="3" />
        <text x="132" y="214" class="t-node">User Request</text>

        <RoughRect :x="400" :y="170" :width="200" :height="72" :stroke="LOOP.stroke" :fill="LOOP.fill" :stroke-width="2.6" :seed="4" />
        <text x="500" y="205" class="t-node">Agent Loop</text>
        <text x="500" y="227" class="t-sub">LLM + tools, iterating</text>

        <RoughRect :x="780" :y="170" :width="160" :height="72" :stroke="NODE.stroke" :fill="NODE.fill" :seed="5" />
        <text x="860" y="214" class="t-node">Tools</text>
      </g>

      <!-- ===================================================================
           STAGE 2 - context that GUIDES (just-in-time, probabilistic)
      ==================================================================== -->
      <g v-click="2">
        <RoughArrow :x1="500" :y1="244" :x2="500" :y2="346" :stroke="ARROW" :stroke-width="2.8" :arrow-size="15" :seed="14" />
        <RoughRect :x="290" :y="350" :width="420" :height="92" :stroke="CTX.stroke" :fill="CTX.fill" :seed="6" />
        <text x="500" y="386" class="t-node">Context Engineering</text>
        <text x="500" y="412" class="t-sub">just-in-time loading</text>

        <RoughArrow :x1="438" :y1="444" :x2="372" :y2="536" :stroke="ARROW" :stroke-width="2.8" :arrow-size="15" :seed="15" />
        <RoughArrow :x1="562" :y1="444" :x2="628" :y2="536" :stroke="ARROW" :stroke-width="2.8" :arrow-size="15" :seed="16" />

        <RoughRect :x="250" :y="540" :width="200" :height="82" :stroke="BRIGHT.stroke" :fill="BRIGHT.fill" :seed="7" />
        <text x="350" y="576" class="t-node-dark">Skills</text>
        <text x="350" y="600" class="t-sub-dark">workflows</text>

        <RoughRect :x="550" :y="540" :width="200" :height="82" :stroke="BRIGHT.stroke" :fill="BRIGHT.fill" :seed="8" />
        <text x="650" y="576" class="t-node-dark">Subagents</text>
        <text x="650" y="600" class="t-sub-dark">specialized</text>

        <text x="500" y="470" class="t-guide">guides &#8595; probabilistic</text>
      </g>

      <!-- ===================================================================
           STAGE 3 - hooks that CONTROL (deterministic) wrap the loop
      ==================================================================== -->
      <g v-click="3">
        <!-- boundary around the runtime loop -->
        <RoughRect
          :x="18" :y="128" :width="944" :height="150"
          :stroke="HOOK" fill="rgba(255,107,237,0.03)"
          :stroke-width="2" stroke-dasharray="9 7" :roughness="1.4" :seed="21"
        />
        <text x="34" y="118" class="t-hooks">&#129693; Hooks &#183; deterministic control</text>

        <!-- PreToolUse gate straddling the Agent Loop -> Tools arrow -->
        <RoughRect
          :x="672" :y="178" :width="38" :height="56"
          :stroke="HOOK" fill="rgba(255,107,237,0.14)"
          stroke-dasharray="6 5" :roughness="1.3" :seed="22"
        />
        <text x="691" y="165" class="t-event">PreToolUse</text>
        <text x="691" y="256" class="t-event-sub">&#9995; can block</text>

        <!-- lifecycle tags on the boundary -->
        <text x="150" y="152" class="t-event">&#9656; SessionStart</text>
        <text x="858" y="270" class="t-event">Stop &#9656; notify</text>
      </g>
    </RoughSvg>

    <p v-click="4" class="fp-caption">
      Context <em>guides</em> the agent &mdash; probabilistic.
      Hooks <strong>enforce</strong> &mdash; deterministic.
    </p>
  </div>
</template>

<style scoped>
.fp {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
}
.fp :deep(.rough-svg) {
  width: 100%;
  max-width: 880px;
  overflow: visible;
}

/* hand-drawn type, matching the deck's Caveat 'hand' font */
.t-node,
.t-node-dark,
.t-sub,
.t-sub-dark,
.t-hand,
.t-hooks,
.t-guide,
.t-event,
.t-event-sub {
  font-family: 'Caveat', 'Comic Sans MS', cursive;
  text-anchor: middle;
  dominant-baseline: middle;
  pointer-events: none;
}
.t-node { font-size: 27px; font-weight: 700; fill: v-bind('TEXT_LIGHT'); }
.t-node-dark { font-size: 28px; font-weight: 700; fill: v-bind('TEXT_DARK'); }
.t-sub { font-size: 19px; fill: rgba(245, 246, 250, 0.82); }
.t-sub-dark { font-size: 19px; fill: rgba(42, 5, 33, 0.82); }
.t-hand { font-size: 22px; fill: v-bind('HOOK'); text-anchor: start; }
.t-hooks { font-size: 24px; font-weight: 700; fill: v-bind('HOOK'); text-anchor: start; }
.t-guide { font-size: 20px; font-weight: 700; fill: v-bind('GUIDE_COLOR'); }
.t-event { font-size: 20px; font-weight: 700; fill: v-bind('HOOK'); }
.t-event-sub { font-size: 18px; fill: rgba(245, 246, 250, 0.85); }

.fp-caption {
  margin-top: 1.4rem;
  text-align: center;
  font-size: 1.55rem;
  font-family: 'Caveat', 'Comic Sans MS', cursive;
  opacity: 0.9;
}
.fp-caption em { font-style: normal; color: rgb(192, 132, 252); }
.fp-caption strong { color: #ff6bed; }

@media (prefers-reduced-motion: reduce) {
  .fp * { transition: none !important; animation: none !important; }
}
</style>
