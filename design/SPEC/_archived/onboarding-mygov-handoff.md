# Register / MyGov handoff — node 4036:53

## Layout from screenshot

Full-screen frame, `surface/background` fill, 402x874 (iPhone-width canvas).

Top to bottom, all content inset 18pt left/right (`Content` container):

1. **Nav bar** — horizontal row, left-aligned, 8pt gap: a 28x28 icon slot holding a `chevron.left` back icon, then the title `"Verify your identity"` (Headline style) immediately to its right, vertically centered with the icon. This is a standard back-nav header, not centered.
2. **80pt spacer** below the nav bar.
3. **Hero block** — vertically stacked, centered content (icon, title, body, dots all appear horizontally centered within the 366pt-wide column even though the parent frame itself has no explicit centering property — treat as center-aligned in the SwiftUI build):
   - Circular icon badge, 96x96, `brand/tint` fill, fully rounded (r48), containing a centered `checkmark.seal.fill` icon at 50x50 colored `brand/solid` (orange checkmark-in-seal glyph, matches the screenshot's orange badge).
   - 24pt spacer.
   - Large title `"Opening MyGov"`, bold, centered.
   - 10pt spacer.
   - Body text `"Confirm your identity in the MyGov app. You will return here automatically."`, `text/ink-soft`, centered, wraps to 3 lines in the screenshot.
   - 28pt spacer.
   - Progress dots row: 3 small dots, 8pt gap, centered — dot 1 is solid brand orange (active/current step), dots 2 and 3 are faint gray (upcoming steps). This is a step indicator, not a loading spinner.
4. **120pt spacer** pushing the button to the bottom of the screen.
5. **Cancel button** — full-width (366pt) pill-shaped secondary button, 50pt tall, r25, `surface/card` fill with a `line/hairline` stroke (outlined/white pill look in the screenshot), label `"Cancel"` in `text/gold` (orange text on white pill).
6. **24pt spacer** at the very bottom (safe-area padding).

Nothing else is visible below the Cancel button — nav bar, hero content, and one bottom button is the entire screen. No image fills, no additional icons.

## Node tree

```
Register / MyGov handoff  [NONE, fill surface/background, r 0, 402x874]
  Content  [VERTICAL, fill none, r 0 pad T0/R18/B0/L18 gap 0, 402x572]
    Nav bar  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 8, 366x28]
      Icon slot  [NONE, fill none, r 0, 28x28]
        Icon / chevron.left  INSTANCE <Icon / chevron.left>    10x18
          chevron.left  <shape:VECTOR>  text/ink  10x18
      "Verify your identity"  Type/Headline  text/ink
    spacer-80  [NONE, fill none, r 0, 1x80]
    Hero  [VERTICAL, fill none, r 0 pad T0/R0/B0/L0 gap 0, 366x270]
      Icon slot  [NONE, fill brand/tint, r 48, 96x96]
        Icon / checkmark.seal.fill  INSTANCE <Icon / checkmark.seal.fill>    50x50
          checkmark.seal.fill  <shape:VECTOR>  brand/solid  50x50
      spacer-24  [NONE, fill none, r 0, 1x24]
      "Opening MyGov"  Type/Large title  text/ink
      spacer-10  [NONE, fill none, r 0, 1x10]
      "Confirm your identity in the MyGov app. You will return here automatically."  Type/Body  text/ink-soft
      spacer-28  [NONE, fill none, r 0, 1x28]
      Progress  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 8, 40x8]
        Dot 1  <shape:ELLIPSE>  brand/solid  8x8
        Dot 2  <shape:ELLIPSE>  text/ink-faint  8x8
        Dot 3  <shape:ELLIPSE>  text/ink-faint  8x8
    spacer-120  [NONE, fill none, r 0, 1x120]
    Button / Secondary  [HORIZONTAL, fill surface/card stroke line/hairline, r 25 pad T0/R0/B0/L0 gap 0, 366x50]
      "Cancel"  Type/Headline  text/gold
    spacer-24  [NONE, fill none, r 0, 1x24]
```

## Token inventory

- `surface/background`
- `surface/card`
- `line/hairline`
- `brand/tint`
- `brand/solid`
- `text/ink`
- `text/ink-soft`
- `text/ink-faint`
- `text/gold`
- `Type/Headline`
- `Type/Large title`
- `Type/Body`
- `Icon / chevron.left` (SF Symbol: `chevron.left`)
- `Icon / checkmark.seal.fill` (SF Symbol: `checkmark.seal.fill`)

## Copy inventory

- "Verify your identity"
- "Opening MyGov"
- "Confirm your identity in the MyGov app. You will return here automatically."
- "Cancel"

