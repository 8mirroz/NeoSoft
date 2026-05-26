# Visual Acceptance Criteria (from p1.md)

Use this checklist in Phase C and before MVP freeze.

## Gem Readability

- Every gem type must remain distinguishable at `64x64` and `96x96`.
- Recognition target in blind test: at least `90%` correct classification across base gem set.
- Distinction must come from structure/motion, not color alone.

## Contrast and Separation

- White/light spheres must remain visible against board and background.
- Board edge and gem contour separation must be visible at normal gameplay zoom.
- No hard black outlines; separation uses glow/ambient occlusion/subtle edges.

## Animation Timing

- Idle cycle: `3.0s` to `6.0s`, low amplitude.
- Select response: `0.18s` to `0.35s`.
- Swap response: `0.22s` to `0.35s`.
- Match dissolve: `0.35s` to `0.60s`.
- Spawn reveal: `0.25s` to `0.45s`.

## Performance Constraints

- Visual effects must not break target smoothness on MVP devices.
- Shader quality settings must support a reduced mode for weak devices.

