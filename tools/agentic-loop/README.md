# Agentic loop demo recording

Deterministic VHS recording that animates the **nanocode agent-loop** transcript
from the "Agentic Loop (nanocode)" slide: prompt → `[agentLoop]` → `Write` tool →
results fed back → loop → done. Drives the
`<DemoVideo src="/videos/agentic-loop.mp4">` slide.

## Regenerate

```bash
vhs tools/agentic-loop/agentic-loop.tape   # writes starter/public/videos/agentic-loop.{mp4,webm}
```

Requires `vhs`, `ttyd`, and `ffmpeg`.

## Files

- `agentic-loop.tape` — VHS script (output paths, theme, dimensions, timing).
- `present.sh` — the paced transcript VHS records. Purely cosmetic; mirrors the
  real nanocode output with a `🔁` marker on the recursive call.
