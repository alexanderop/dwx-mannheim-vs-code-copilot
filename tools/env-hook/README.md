# `.env` guard demo recording

Deterministic VHS recording of the `.env` PreToolUse guard
(`.github/hooks/scripts/block-secrets.sh`) denying secret reads. Drives the
`<DemoVideo src="/videos/env-hook-guard.mp4">` slide in the Hooks section.

## Regenerate

From the repo root:

```bash
vhs tools/env-hook/env-hook.tape   # writes starter/public/videos/env-hook-guard.{mp4,webm}
```

Requires `vhs`, `ttyd`, `ffmpeg`, and `jq` (`brew install vhs ttyd ffmpeg jq`).

## Files

- `env-hook.tape` — VHS script (output paths, theme, timing).
- `present.sh` — the paced walkthrough VHS records. Pipes representative tool
  calls into the real guard and pretty-prints the deny/allow decisions.

This shows the **guard mechanism** with real script output. To capture the
agent itself being blocked, record VS Code Copilot live (CLI hooks weren't
honored by Copilot CLI 1.0.65 at the time of writing).
