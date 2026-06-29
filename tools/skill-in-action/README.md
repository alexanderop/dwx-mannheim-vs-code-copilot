# Skill in action demo recording

Deterministic VHS recording recreating the **Plausible SEO skill** running
end-to-end: description match → `skill.md` loads → CLI script runs → reference
doc → WebFetch → specific fixes. Drives the
`<DemoVideo src="/videos/skill-in-action.mp4">` slide.

## Regenerate

```bash
vhs tools/skill-in-action/skill-in-action.tape   # writes starter/public/videos/skill-in-action.{mp4,webm}
```

Requires `vhs`, `ttyd`, and `ffmpeg`.

## Files

- `skill-in-action.tape` — VHS script (output paths, theme, dimensions, timing).
- `present.sh` — the paced transcript VHS records. Purely cosmetic; the page
  metrics and findings are illustrative — edit them in `present.sh`.
