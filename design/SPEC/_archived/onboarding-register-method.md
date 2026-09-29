# Register / Choose method — node 4024:16

## Layout from screenshot

Full-bleed screen, light background, content inset with side padding.

1. **Nav bar** (top, left-aligned row): back chevron icon, then headline text "Verify your identity" immediately to its right. Single row, small height.
2. **Large title** below, left-aligned, bold, two lines: "One tap, or your documents".
3. **Subtext** directly under the title, left-aligned, muted gray, two lines: "You can browse freely. Verification is only needed before your first ride."
4. **Card 1 — "Continue with MyGov"** (white/card-filled, heavily rounded rectangle, sits full-width):
   - Header row: circular orange-tinted badge icon (checkmark-seal, solid orange glyph) on the left; to its right, stacked title "Continue with MyGov" (bold) over caption "Recommended · one tap" (muted, smaller).
   - Body paragraph below, muted gray, two lines: "MyGov returns your identity and driving licence in a single step. Nothing to scan or type."
   - Full-width pill button at the bottom of the card, orange horizontal gradient fill, centered dark-on-gold text "Open MyGov".
5. Small vertical gap between the two cards.
6. **Card 2 — "Use my documents"** (light glass-gray fill with a hairline border, heavily rounded, full-width, taller than card 1):
   - Heading "Use my documents" (bold), with subtext "Four steps, about two minutes." beneath it (muted gray).
   - Vertical list of 4 steps, each a row of: small circular orange-tinted icon badge + label text, left-aligned, stacked with even gaps:
     1. person.text.rectangle icon — "ID document"
     2. creditcard icon — "Driving licence"
     3. person.crop.circle.fill icon — "Selfie check"
     4. checkmark.seal.fill icon — "Your details"
   - Full-width pill button at the bottom of the card, white/card fill with a hairline stroke, centered gold-colored text "Start with documents" (outlined/secondary style, contrasts with card 1's filled gradient button).
7. Bottom safe-area spacer below card 2.

Both cards are visually similar rounded "surface" containers but card 1 reads as the primary/recommended path (solid card fill, gradient CTA) while card 2 reads as the secondary path (glass/bordered fill, outlined CTA) — establishing a clear visual hierarchy between the one-tap MyGov flow and the four-step manual document flow.

## Node tree

```
Register / Choose method  [NONE, fill surface/background, r 0, 402x874]
  Content  [VERTICAL, fill none, r 0 pad T0/R18/B0/L18 gap 0, 402x813]
    Nav bar  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 8, 366x28]
      Icon slot  [NONE, fill none, r 0, 28x28]
        <Icon / Icon / chevron.left>  none
          chevron.left  text/ink  10x18  r0
      "Verify your identity"  Type/Headline  text/ink
    spacer-28  [NONE, fill none, r 0, 1x28]
    "One tap, or your documents"  Type/Large title  text/ink
    spacer-8  [NONE, fill none, r 0, 1x8]
    "You can browse freely. Verification is only needed before your first ride."  Type/Body  text/ink-soft
    spacer-28  [NONE, fill none, r 0, 1x28]
    Path / MyGov  [VERTICAL, fill surface/card, r 30 pad T18/R18/B18/L18 gap 0, 366x222]
      Head  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 12, 330x52]
        Icon slot  [NONE, fill brand/tint, r 26, 52x52]
          <Icon / Icon / checkmark.seal.fill>  none
            checkmark.seal.fill  brand/solid  32x32  r0
        Titles  [VERTICAL, fill none, r 0 pad T0/R0/B0/L0 gap 2, 266x38]
          "Continue with MyGov"  Type/Headline  text/ink
          "Recommended · one tap"  Type/Caption  text/ink-soft
      spacer-14  [NONE, fill none, r 0, 1x14]
      "MyGov returns your identity and driving licence in a single step. Nothing to scan or type."  Type/Subheadline  text/ink-soft
      spacer-16  [NONE, fill none, r 0, 1x16]
      Button / Primary  [HORIZONTAL, fill GRADIENT_LINEAR, r 25 pad T0/R0/B0/L0 gap 0, 330x50]
        "Open MyGov"  Type/Headline  text/on-gold
    spacer-14  [NONE, fill none, r 0, 1x14]
    Path / Documents  [VERTICAL, fill surface/glass, stroke line/hairline, r 30 pad T18/R18/B18/L18 gap 0, 366x337]
      "Use my documents"  Type/Headline  text/ink
      spacer-6  [NONE, fill none, r 0, 1x6]
      "Four steps, about two minutes."  Type/Subheadline  text/ink-soft
      spacer-14  [NONE, fill none, r 0, 1x14]
      Steps  [VERTICAL, fill none, r 0 pad T0/R0/B0/L0 gap 10, 328x174]
        Step / ID document  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 12, 328x36]
          Icon slot  [NONE, fill brand/tint, r 18, 36x36]
            <Icon / Icon / person.text.rectangle>  none
              person.text.rectangle  brand/solid  22x17  r0
          "ID document"  Type/Subheadline  text/ink
        Step / Driving licence  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 12, 328x36]
          Icon slot  [NONE, fill brand/tint, r 18, 36x36]
            <Icon / Icon / creditcard>  none
              creditcard  brand/solid  22x16  r0
          "Driving licence"  Type/Subheadline  text/ink
        Step / Selfie check  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 12, 328x36]
          Icon slot  [NONE, fill brand/tint, r 18, 36x36]
            <Icon / Icon / person.crop.circle.fill>  none
              person.crop.circle.fill  brand/solid  22x22  r0
          "Selfie check"  Type/Subheadline  text/ink
        Step / Your details  [HORIZONTAL, fill none, r 0 pad T0/R0/B0/L0 gap 12, 328x36]
          Icon slot  [NONE, fill brand/tint, r 18, 36x36]
            <Icon / Icon / checkmark.seal.fill>  none
              checkmark.seal.fill  brand/solid  22x22  r0
          "Your details"  Type/Subheadline  text/ink
      spacer-16  [NONE, fill none, r 0, 1x16]
      Button / Secondary  [HORIZONTAL, fill surface/card, stroke line/hairline, r 25 pad T0/R0/B0/L0 gap 0, 330x50]
        "Start with documents"  Type/Headline  text/gold
    spacer-24  [NONE, fill none, r 0, 1x24]
```

## Token inventory

Colour variables:
- `surface/background`
- `surface/card`
- `surface/glass`
- `text/ink`
- `text/ink-soft`
- `text/on-gold`
- `text/gold`
- `brand/tint`
- `brand/solid`
- `line/hairline`
- `GRADIENT_LINEAR` (Button / Primary fill — unresolved to a single variable name; linear gradient paint, no bound variable reported)

Text styles:
- `Type/Headline`
- `Type/Large title`
- `Type/Body`
- `Type/Caption`
- `Type/Subheadline`

SF Symbols (icons):
- `chevron.left`
- `checkmark.seal.fill` (used twice: MyGov badge, "Your details" step)
- `person.text.rectangle`
- `creditcard`
- `person.crop.circle.fill`

## Copy inventory

- "Verify your identity"
- "One tap, or your documents"
- "You can browse freely. Verification is only needed before your first ride."
- "Continue with MyGov"
- "Recommended · one tap"
- "MyGov returns your identity and driving licence in a single step. Nothing to scan or type."
- "Open MyGov"
- "Use my documents"
- "Four steps, about two minutes."
- "ID document"
- "Driving licence"
- "Selfie check"
- "Your details"
- "Start with documents"

