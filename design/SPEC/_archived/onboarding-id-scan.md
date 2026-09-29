# Register / ID scan — node 4037:55

## Layout from screenshot

Full-bleed screen, light background (`surface/background`), 402x874, content padded 18pt left/right.

Top to bottom, all left-aligned unless noted:

1. **Nav bar** — horizontal row: back chevron (`<`, SF Symbol `chevron.left`) at far left, then "Step 1 of 4" headline text immediately to its right (8pt gap). Sits at the very top of the content area.
2. 18pt spacer.
3. **Step indicator** — a thin 4-segment progress bar spanning the full content width. 4 equal-width pill segments with 6pt gaps between them. Segment 1 is filled gold/brand (`brand/solid`); segments 2–4 are pale gray (`line/hairline`) — i.e. step 1 of 4 is active/complete, the rest are pending.
4. 22pt spacer.
5. **Title** — "Scan your ID", large bold black title, left-aligned.
6. 6pt spacer.
7. **Subtitle** — "Place your passport or national ID inside the frame. Hold steady.", two-line gray body text, left-aligned, directly under the title.
8. 22pt spacer.
9. **Viewfinder card** — large black rounded-rectangle panel (366x310, r30) acting as the camera preview:
   - Centered inside it: a white-stroked rounded rectangle ("Guide", 300x190, r18) — the actual scan-frame outline, with visible margin of black on all sides (roughly centered horizontally, sits in the upper-middle of the card).
   - Below the guide frame, small centered caption text "Both edges must be visible" in light/white color, near the bottom of the black card.
10. 26pt spacer.
11. **Shutter button** — centered horizontally (not left-aligned, unlike everything else): a circular button (72x72, r36) with a light/card-colored ring stroke (`line/hairline`) and a smaller filled gold/brand circle (`Shutter core`, 58x58 ellipse) inside it — the camera capture button.
12. 24pt spacer, then end of content frame. Remaining space below is empty background.

Hierarchy summary: Nav (back + step label) → progress bar (4 segments) → title → subtitle → viewfinder (dark card with white guide outline + caption) → centered shutter button.

## Node tree

```
Register / ID scan  [FRAME fill=surface/background 402x874]
  Content  [FRAME VERTICAL gap=0 pad(T0/R18/B0/L18) 402x615]
    Nav bar  [FRAME HORIZONTAL gap=8 pad(T0/R0/B0/L0) 366x28]
      Icon slot  [FRAME 28x28]
        Icon / chevron.left  [INSTANCE 10x18 INSTANCE-OF:Icon / chevron.left]
          chevron.left  [VECTOR fill=text/ink 10x18]
      Step 1 of 4  [TEXT fill=text/ink 87x21]
        "Step 1 of 4"  style=Type/Headline  fontSize=17
    spacer-18  [FRAME 1x18]
    Step indicator  [FRAME HORIZONTAL gap=6 pad(T0/R0/B0/L0) 366x4]
      Step 1  [FRAME fill=brand/solid r2 87x4]
      Step 2  [FRAME fill=line/hairline r2 87x4]
      Step 3  [FRAME fill=line/hairline r2 87x4]
      Step 4  [FRAME fill=line/hairline r2 87x4]
    spacer-22  [FRAME 1x22]
    Scan your ID  [TEXT fill=text/ink 366x41]
      "Scan your ID"  style=Type/Large title  fontSize=34
    spacer-6  [FRAME 1x6]
    Place your passport or national ID inside the frame. Hold steady.  [TEXT fill=text/ink-soft 366x42]
      "Place your passport or national ID inside the frame. Hold steady."  style=Type/Body  fontSize=17
    spacer-22  [FRAME 1x22]
    Viewfinder  [FRAME fill=text/ink r30 366x310]
      Guide  [FRAME stroke=icon/on-brand r18 300x190]
      Both edges must be visible  [TEXT fill=icon/on-brand 300x15]
        "Both edges must be visible"  style=Type/Caption  fontSize=12
    spacer-26  [FRAME 1x26]
    Shutter row  [FRAME HORIZONTAL gap=0 pad(T0/R0/B0/L0) 366x72]
      Button / Shutter  [FRAME fill=surface/card stroke=line/hairline r36 72x72]
        Shutter core  [ELLIPSE fill=brand/solid 58x58]
    spacer-24  [FRAME 1x24]
```

## Token inventory

- `surface/background` (fill)
- `surface/card` (fill)
- `text/ink` (fill)
- `text/ink-soft` (fill)
- `brand/solid` (fill)
- `line/hairline` (fill + stroke)
- `icon/on-brand` (fill + stroke)
- `Type/Headline`
- `Type/Large title`
- `Type/Body`
- `Type/Caption`
- SF Symbol: `chevron.left` (via `Icon / chevron.left` component instance)

## Copy inventory

- "Step 1 of 4"
- "Scan your ID"
- "Place your passport or national ID inside the frame. Hold steady."
- "Both edges must be visible"

