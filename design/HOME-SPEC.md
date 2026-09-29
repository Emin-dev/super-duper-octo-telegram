# Home screen — rebuild spec

Structure confirmed by Emin and by screenshots: **4 modules -> News -> Notifications**.
Keep the UX. Fix the execution.

## Observed problems in the current build

| # | Problem | Evidence | Severity |
|---|---|---|---|
| 1 | **Content runs under the floating tab bar.** "Notifications" header and a notification row are visibly ghosted behind the bar in both screenshots | Violates `space/tab-bar-clearance` 96 (RULES.md B8) | HIGH — it is a bug, not a taste call |
| 2 | **Module tiles are ~400pt tall with a tiny icon and a huge empty middle** | Icon sits top-left, text bottom-left, ~200pt of nothing between | HIGH — costs the whole fold |
| 3 | **Icons are custom illustrations, not SF Symbols** | Peach circle + bespoke orange glyph | HIGH — breaks the brief |
| 4 | **Host occupies the top-left**, the most prominent slot in LTR reading order | Host targets vehicle owners, a minority. Renter is the revenue path | MEDIUM |
| 5 | **News card truncates mid-word** — "Earn by ho" | No ellipsis, arbitrary clip at screen edge | MEDIUM |
| 6 | **Inconsistent surfaces** — some notification rows read white, others carry a blue glass tint | Two materials for one component | MEDIUM |
| 7 | **Backdrop gradient bleeds unevenly** — blue cast at bottom-right and edges | Reads accidental rather than designed | MEDIUM |
| 8 | **Section headers are larger than the documented ramp** | "News"/"Notifications" look ~28; Foundations specifies Title 3 20/Bold for section headers | LOW |
| 9 | **No active-trip surface** | Notifications show rides starting and ending; an ongoing ride should appear at the top of Home | MEDIUM |

## Target layout — 402 x 874 (iPhone 18 Pro)

Content width = 402 - (2 x `space/screen-padding` 18) = **366**
Tile width = (366 - `space/gap` 14) / 2 = **176**

### Module tile — 176 x 150

Currently ~400 tall. At 150 the four tiles occupy 314pt instead of ~814pt,
which brings News AND Notifications above the fold without scrolling.

```
padding 16
icon            SF Symbol, 24pt, in a 44 circle (size/icon-button)
gap 12
title           Headline 17/Semibold   -> text/ink
gap 4
subtitle        Caption 12/Regular     -> text/ink-soft, max 2 lines
radius          radius/tile 26
fill            surface/card  (OPAQUE — rule B2)
```

### Reading order (top-left is the strongest slot)

1. **Renter** — `car.fill` — "Rent a car by day, week or month"
2. **Electric car** — `bolt.car.fill` — "By the minute, hour or day"
3. **Golf car** — `steeringwheel` — "By the minute, hour or day"
4. **Host** — `key.fill` — "Rent out your vehicles and earn"

Host moves to the last slot. It is not demoted in importance — it is a different
audience, and the majority arrive to rent, not to list.

SF Symbol names above are PROPOSED and must be verified against the installed
SF Symbols set before use. Do not ship an unverified symbol name.

### Vertical rhythm

```
status bar                       59
header  logo 32 + wordmark       44
Large title "Welcome, Emin"      41
subtitle Body 17                 22
gap                              24
module grid 2x2                  314   (150 + 14 + 150)
gap                              32
"News" Title 3 20/Bold           25
news carousel                    200
gap                              32
"Notifications" + See all        25
notification rows                n x 76
tab-bar clearance                96    <- NON-NEGOTIABLE
```

### News carousel

- Card 280 wide, 16 peek of the next card at the right edge
- Photo 280 x 140, `radius/card` 30, OPAQUE label area beneath (rule B2)
- Title Headline 17/Semibold, ONE line, true ellipsis — never a mid-word clip
- Category badge: glass capsule, `radius/chip` 18, Footnote 13/Semibold

### Notification row

- Height 76, `radius/tile` 26, `surface/card`, ONE material for every row
- Leading SF Symbol 20 in a 40 circle
- Body Subheadline 15/Medium -> `text/ink`, max 2 lines
- Timestamp Caption 12 -> `text/ink-soft`
- Unread: 7pt dot (`size/status-dot`), `brand/amber`, trailing

### Active trip (new)

When a ride is ongoing, insert ABOVE the module grid:
`mapGlass` card, status dot honey, elapsed time, live cost, "End ride" action.
This is the one thing a user opens the app to find mid-ride.

## Dark mode

Bind the 7 differing colours to `Theme Dark`; everything else stays on `Theme`.
Tab bar tint: pure white in dark, `#B4640A` in light (rule B4).

