# Register / MyGov failure — node 4036:118

## Layout from screenshot

Single full-screen frame, `surface/background` fill, no bottom tab bar visible (this is a modal/pushed step, not a tab-bar screen).

Top to bottom, all content left-aligned within 18pt side margins except where noted:

1. **Nav bar** — a left chevron ("<") icon slot (28x28) immediately followed by the title "Verify your identity" (`Type/Headline`), both on one row, top-left of the screen, small top inset.
2. **70pt spacer.**
3. **Hero block**, vertically stacked and **center-aligned** (unlike the nav bar):
   - A circular badge (96x96, `brand/tint` fill, fully rounded r48) containing a centered warning-triangle icon (`exclamationmark.triangle.fill`, coloured `status/danger` — red icon on a pale peach/tan circle).
   - 24pt spacer.
   - Large bold centered title "MyGov did not confirm" (`Type/Large title`), wraps to two lines, centered text alignment.
   - 10pt spacer.
   - Centered body copy in a muted grey (`text/ink-soft`): "The session timed out or was cancelled. Nothing was saved and you can try again." — wraps to three lines, centered.
4. **40pt spacer.**
5. **Primary button** — full-width pill (r25, 366x50), gold/orange horizontal gradient fill (lighter gold at left tapering to a darker amber/orange at right), label "Try MyGov again" (`Type/Headline`, `text/on-gold`, dark text on the gradient).
6. **12pt spacer.**
7. **Secondary button** — full-width pill (r25, 366x50), white/`surface/card` fill with a thin hairline stroke (`line/hairline`), label "Use my documents instead" (`Type/Headline`, `text/gold` — gold-coloured text on a white button, this is the fallback/alternate action).
8. **24pt spacer**, then the rest of the screen below the buttons is empty background — no further content, no footer.

Only the hero block and the two buttons are horizontally centered as a group (each 366pt wide, centered in the 402pt frame via the 18pt side padding); text *inside* the hero block is center-aligned, whereas the nav bar row is left-aligned. The overall visual hierarchy is: navigation → status icon → error headline → explanation → primary recovery action → secondary/alternate action.

## Node tree

```
Register / MyGov failure  [fill surface/background, r 0, 402x874]  (FRAME)
  Content  [auto-layout V, pad T0/R18/B0/L18, gap 0, r 0, 402x549]  (FRAME)
    Nav bar  [auto-layout H, pad T0/R0/B0/L0, gap 8, r 0, 366x28]  (FRAME)
      Icon slot  [r 0, 28x28]  (FRAME)
        Icon / chevron.left  [INSTANCE <Icon / chevron.left>]  10x18
          <Icon/chevron.left>  text/ink
      "Verify your identity"  Type/Headline  text/ink
    spacer-70  [r 0, 1x70]  (FRAME)
    Hero  [auto-layout V, pad T0/R0/B0/L0, gap 0, r 0, 366x275]  (FRAME)
      Icon slot  [fill brand/tint, r 48, 96x96]  (FRAME)
        Icon / exclamationmark.triangle.fill  [INSTANCE <Icon / exclamationmark.triangle.fill>]  50x45
          <Icon/exclamationmark.triangle.fill>  status/danger
      spacer-24  [r 0, 1x24]  (FRAME)
      "MyGov did not confirm"  Type/Large title  text/ink
      spacer-10  [r 0, 1x10]  (FRAME)
      "The session timed out or was cancelled. Nothing was saved and you can try again."  Type/Body  text/ink-soft
    spacer-40  [r 0, 1x40]  (FRAME)
    Button / Primary  [auto-layout H, pad T0/R0/B0/L0, gap 0, fill GRADIENT_LINEAR, r 25, 366x50]  (FRAME)
      "Try MyGov again"  Type/Headline  text/on-gold
    spacer-12  [r 0, 1x12]  (FRAME)
    Button / Secondary  [auto-layout H, pad T0/R0/B0/L0, gap 0, fill surface/card, stroke line/hairline, r 25, 366x50]  (FRAME)
      "Use my documents instead"  Type/Headline  text/gold
    spacer-24  [r 0, 1x24]  (FRAME)
```

Note: the `Button / Primary` fill resolved as `GRADIENT_LINEAR` (a gradient paint, not a bound color variable) — the gradient's own stops were not individually resolved to variable names by this dump; visually it reads as a gold→amber horizontal gradient (see screenshot description above).

## Token inventory

- `surface/background` — screen background fill
- `text/ink` — nav title, hero title colour
- `brand/tint` — icon badge circle fill
- `status/danger` — warning triangle icon colour
- `text/ink-soft` — body/explanation copy colour
- `text/on-gold` — primary button label colour
- `text/gold` — secondary button label colour
- `surface/card` — secondary button fill
- `line/hairline` — secondary button stroke
- `Type/Headline` — text style (nav title, both button labels)
- `Type/Large title` — text style (hero error title)
- `Type/Body` — text style (hero explanation copy)
- `Icon / chevron.left` — SF Symbol instance (back nav)
- `Icon / exclamationmark.triangle.fill` — SF Symbol instance (error badge)
- Unresolved: primary button fill is a raw `GRADIENT_LINEAR` paint, not a bound variable/token — worth flagging to the design team for tokenization.

## Copy inventory

- "Verify your identity"
- "MyGov did not confirm"
- "The session timed out or was cancelled. Nothing was saved and you can try again."
- "Try MyGov again"
- "Use my documents instead"

