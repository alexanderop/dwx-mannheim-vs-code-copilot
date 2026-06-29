# Copilot CLI demo recording

Deterministic VHS recording that re-creates a **GitHub Copilot CLI** (`copilot`
v1.0.65) session: the welcome banner, a typed prompt, and the agent streaming
back the tools available from its system context. Drives the
`<DemoVideo src="/videos/copilot-cli-tools.mp4">` slide right after the
**VS Code Copilot Built-in Tools** slide.

## Regenerate

From the repo root:

```bash
vhs tools/copilot-cli/copilot-cli.tape   # writes starter/public/videos/copilot-cli-tools.{mp4,webm}
```

Requires `vhs`, `ttyd`, and `ffmpeg` (`brew install vhs ttyd ffmpeg`).

## Files

- `copilot-cli.tape` — VHS script (output paths, theme, dimensions, timing).
- `present.sh` — the paced transcript VHS records. Purely cosmetic: it prints a
  styled re-creation of the Copilot CLI (header, typed prompt, streamed answer)
  with ANSI colors and small sleeps for the typing/streaming feel.

This is a **visual re-creation**, not a live capture — the Copilot CLI isn't
scriptable for deterministic recording, so the transcript is hand-authored to
match the real UI. Edit `present.sh` to change the prompt or answer, then
re-run the tape.
