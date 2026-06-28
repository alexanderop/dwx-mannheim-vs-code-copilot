<template>
  <div grid="~ cols-2 gap-x-8" class="text-sm">
    <div>
      <strong>Quality &amp; safety gates</strong>
      <ul>
        <li>🟢 <strong>Loop until green</strong> (<code>Stop</code>) — refuse to finish while tests fail</li>
        <li>🚫 <strong>Pre-commit gate</strong> (<code>PreToolUse</code>) — no commit if lint fails</li>
        <li>📦 <strong>Dependency guard</strong> — block un-reviewed prod installs</li>
      </ul>
    </div>

    <div>
      <strong>Observability &amp; control</strong>
      <ul>
        <li>📜 <strong>Audit log</strong> (<code>PostToolUse</code>) — every tool call on record</li>
        <li>🛡️ <strong>Prompt governance</strong> (<code>UserPromptSubmit</code>) — catch secrets / PII</li>
        <li>💾 <strong>Backup before compaction</strong> (<code>PreCompact</code>)</li>
        <li>🌐 <strong>Central policy server</strong> (HTTP hook) — one rule set, whole team</li>
      </ul>
    </div>
  </div>

  <Callout type="info">
    The point isn't the list — it's that <strong>anything you can script, you can enforce</strong>.
  </Callout>
</template>
