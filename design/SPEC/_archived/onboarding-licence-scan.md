# Register / Licence scan — node 4037:81

## Layout from screenshot

Full-bleed screen on `surface/background`, content column inset with side
padding, laid out top to bottom, everything left-aligned except the shutter
button which is horizontally centred:

1. **Nav bar** — top row: a left chevron ("back") icon at the far left,
   followed by "Step 2 of 4" as a headline-weight label, same baseline.
2. **Step indicator** — a 4-segment progress bar directly under the nav bar,
   full width, thin rounded bars with small gaps between them. Segments 1 and
   2 are solid brand-orange (filled/complete), segments 3 and 4 are pale grey
   (not yet reached).
3. **Title** — "Driving licence" in large bold black title type, left-aligned.
4. **Subtitle** — "Front side first. We check the category and expiry date."
   directly below the title in soft grey body text, left-aligned, wraps to
   two lines.
5. **Viewfinder card** — a large black rounded-rectangle panel spanning the
   full content width. Inside it, centred, is a white-outlined rounded
   rectangle (the document guide/frame) sized like a licence card in
   landscape orientation, with generous empty margin around it inside the
   black panel. Below the guide rectangle, centred, small white/light caption
   text reads "Front side · 1 of 2".
6. **Shutter button** — below the viewfinder card, horizontally centred (not
   left-aligned like the rest of the column): a circular button, white/card
   ring with a hairline border, containing a smaller solid brand-orange
   filled circle (the shutter core).
7. Remaining space below the shutter button is empty background down to the
   bottom of the screen (no tab bar / home indicator visible in this frame).

Hierarchy: nav bar → progress → title block → subtitle → viewfinder (dominant
visual element, dark and large) → shutter control (accent color, draws the
eye as the primary action). No other icons, buttons, or text appear on
screen.

## Node tree

```
Register / Licence scan  [no-auto-layout, fill surface/background, , 402x874]
  Content  [vertical, pad T0/R18/B0/L18, gap 0, no-fill, , 402x615]
    Nav bar  [horizontal, pad T0/R0/B0/L0, gap 8, no-fill, , 366x28]
      Icon slot  [no-auto-layout, no-fill, , 28x28]
        INSTANCE <Icon / chevron.left>  Icon / chevron.left    10x18
          chevron.left  text/ink  10x18
      "Step 2 of 4"  Type/Headline  text/ink
    spacer-18  [no-auto-layout, no-fill, , 1x18]
    Step indicator  [horizontal, pad T0/R0/B0/L0, gap 6, no-fill, , 366x4]
      Step 1  [no-auto-layout, fill brand/solid, r2, 87x4]
      Step 2  [no-auto-layout, fill brand/solid, r2, 87x4]
      Step 3  [no-auto-layout, fill line/hairline, r2, 87x4]
      Step 4  [no-auto-layout, fill line/hairline, r2, 87x4]
    spacer-22  [no-auto-layout, no-fill, , 1x22]
    "Driving licence"  Type/Large title  text/ink
    spacer-6  [no-auto-layout, no-fill, , 1x6]
    "Front side first. We check the category and expiry date."  Type/Body  text/ink-soft
    spacer-22  [no-auto-layout, no-fill, , 1x22]
    Viewfinder  [no-auto-layout, fill text/ink, r30, 366x310]
      Guide  [no-auto-layout, no-fill, stroke icon/on-brand, r18, 300x190]
      "Front side · 1 of 2"  Type/Caption  icon/on-brand
    spacer-26  [no-auto-layout, no-fill, , 1x26]
    Shutter row  [horizontal, pad T0/R0/B0/L0, gap 0, no-fill, , 366x72]
      Button / Shutter  [no-auto-layout, fill surface/card, stroke line/hairline, r36, 72x72]
        Shutter core  brand/solid  58x58
    spacer-24  [no-auto-layout, no-fill, , 1x24]
```

Notes on the dump:
- `Icon slot` wraps an `INSTANCE <Icon / chevron.left>`, whose sole child
  vector is named `chevron.left`, filled with `text/ink`.
- `Guide` is a stroke-only frame (no fill) — the white document outline seen
  in the screenshot — drawn with `icon/on-brand` as the stroke colour.
- `Shutter row` is a horizontal auto-layout with zero gap/padding at
  366x72 but only holds one child (`Button / Shutter`, 72x72); the row's
  own alignment centres that single child — this is how the button reads as
  horizontally centred in the screenshot despite `Content`'s column being
  left/edge-aligned overall.
- `Shutter core` is a plain filled shape (no stroke) nested inside
  `Button / Shutter`, which itself carries the ring's hairline stroke.

## Token inventory

- `surface/background` — screen fill
- `text/ink` — nav label text, title text, chevron icon fill
- `brand/solid` — step-indicator filled segments, shutter core fill
- `line/hairline` — step-indicator unfilled segments, shutter button stroke
- `text/ink-soft` — subtitle text
- `icon/on-brand` — viewfinder guide stroke, caption text colour
- `surface/card` — shutter button fill

Text styles used: `Type/Headline`, `Type/Large title`, `Type/Body`,
`Type/Caption`.

Icon: `Icon / chevron.left` (SF Symbol `chevron.left`).

## Copy inventory

- "Step 2 of 4"
- "Driving licence"
- "Front side first. We check the category and expiry date."
- "Front side · 1 of 2"

