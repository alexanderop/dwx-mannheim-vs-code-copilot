# Subagent fan-out demo recording

Deterministic VHS recording recreating the `#runSubagent` **fan-out/fan-in**
pattern: the Copilot CLI spins up 3 parallel web-search agents (animated
spinners) that resolve into one merged answer about Geretsried. Drives the
`<DemoVideo src="/videos/subagent-fanout.mp4">` slide.

## Regenerate

```bash
vhs tools/subagent-fanout/subagent-fanout.tape   # writes starter/public/videos/subagent-fanout.{mp4,webm}
```

Requires `vhs`, `ttyd`, and `ffmpeg`.

## Files

- `subagent-fanout.tape` — VHS script (output paths, theme, dimensions, timing).
- `present.sh` — the paced transcript VHS records. Purely cosmetic; the spinner
  rows are updated in place via cursor moves, then resolved to checkmarks.
  The Geretsried facts are accurate; edit them in `present.sh` if needed.
