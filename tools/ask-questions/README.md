# askQuestions picker demo recording

Deterministic VHS recording recreating the `#askQuestions` **option picker**:
the box renders, the selection moves through the options and lands on
"Web App", then the agent confirms and continues. Drives the
`<DemoVideo src="/videos/ask-questions.mp4">` slide.

## Regenerate

```bash
vhs tools/ask-questions/ask-questions.tape   # writes starter/public/videos/ask-questions.{mp4,webm}
```

Requires `vhs`, `ttyd`, and `ffmpeg`.

## Files

- `ask-questions.tape` — VHS script (output paths, theme, dimensions, timing).
- `present.sh` — the paced transcript VHS records. `draw_box` redraws the whole
  box on each selection move via cursor-up; `BOX_LINES` must match the number
  of lines it prints (6 chrome + N options). Selection is shown with `★` +
  highlight (no checkmark glyph — it renders double-width and breaks borders).
