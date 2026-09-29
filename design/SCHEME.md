# Scheme layout — page `NEW`

Built to read like `07 - Scheme`: giant lane titles, branching connectors, designer notes.
Not a row of artboards.

## Lanes

Each lane is a Figma **Section** that genuinely CONTAINS its screens, connectors and notes.

| Lane | y | screens |
|---|---|---|
| `ONBOARDING` | 0 | 9 (two rows — the paths are alternatives, not a sequence) |
| `HOME` | 2568 | 2 |
| `HOST` | 4032 | 3 |
| `RENTER` | 5496 | 2 |
| `EV` | 6960 | 5 |
| `TRIPS` | 8424 | 2 |
| `CHATS` | 9888 | 2 |
| `WALLET` | 11352 | 2 |
| `GOLF` | 12816 | 2 |

**9 lanes, 30 screens, all passing.** Scheme spans y=0 to ~13960, width 4022.
**Press Shift+1 in Figma to zoom to fit.**

## Geometry

```
SCREEN_W 402   SCREEN_H 874
GAP_X    130   GAP_Y    230
PITCH_X  532   PITCH_Y 1104
TITLE_X   90   SCREEN_X0 820
PAD_TOP  170   PAD_BOT   140
LANE_W  4022 (fits 6 columns) — all lanes share it so left edges align
Lane spacing 280
```

## What each lane carries

- **Giant lane title**, Inter Bold, auto-shrunk from 112pt until it clears the first screen column
- **Lane note** at title+150 — one line stating that flow's governing rule
- **Screens** at `x = 820 + col*532`, `y = laneY + 170 + row*1104`
- **Connectors**: straight `LINE` within a row; `VECTOR` elbow when the flow branches to another row
- **Designer notes** under the screen they annotate, 402 wide

Connector colours carry meaning: `brand/solid` for the happy path,
`status/danger` **dashed** for failure branches.

## Two mistakes worth not repeating

1. **`fontSize` must be a number, not a string.** Passing `'150'` throws
   `Expected number, received string` — and because `use_figma` rolls back, the whole
   script is lost. Nothing was corrupted, but the work had to be re-run.
2. **Positioning a node over a Section does NOT make it a child.** Screens sat visually
   inside the lanes but stayed page children, so `section.screenshot()` rendered empty lanes.
   Sections must be populated with `appendChild`, then coordinates re-applied.

## Adding the next lane

1. `y` = previous lane y + previous height + 280
2. `figma.createSection()`, size `4022 x (170 + rows*874 + (rows-1)*230 + 140)`
3. Place screens, then **appendChild them into the section** and restore x/y
4. Add the giant title, lane note, connectors and designer notes — also into the section

## Third gotcha: once parented, screens leave `page.children`

After screens are adopted into Sections, `page.children.find(...)` no longer finds them.
A whole batch of photo corrections silently did nothing and returned an empty change list —
no error, just no effect.

Always search with `page.findAll(n => n.type==='FRAME' && Math.round(n.width)===402)`,
never `page.children`.

## Fourth gotcha: SECTION CHILDREN ARE RELATIVE — this is the one that bit hardest

**A Section child's `x`/`y` are relative to the section, not the page.**
Read the true position with `node.absoluteTransform[1][2]`.

Consequences, learned the hard way:

1. **Moving a section DOES carry its children.** Set `section.y` and the contents follow,
   because their coordinates are relative. No delta shift is needed.
2. **Shifting children by the section delta double-moves them.** Doing
   `s.y = newY; for (const c of s.children) c.y += dy;` pushes every child out by `dy`
   a second time. The lanes render as empty boxes with the screens piled far below.
3. A screen's correct lane-relative `y` is simply `PAD_TOP + row*PITCH_Y` — 170, 1274, …

The failure is silent. A lane-relative offset check looks correct while the absolute position
is wrong, so **verify with `absoluteTransform`, and screenshot the section**:

```js
const abs = Math.round(node.absoluteTransform[1][2]);
const inside = abs >= s.y && abs + 874 <= s.y + s.height;
```

An earlier version of this file claimed section children keep absolute coordinates.
That was wrong, and it caused exactly the bug above.

## Test after every change

Structural edits fail silently in Figma — no error, just wrong geometry. After any move,
resize or reparent:

1. Check `absoluteTransform`, not `x`/`y`
2. `await section.screenshot({scale: 0.17})` and LOOK at it
3. Re-run the verifier over every screen

Three separate layout bugs this session produced no error at all: unparented screens,
double-shifted children, and an unattached image upload.

## Vision testing is mandatory, not optional

The programmatic verifier checks rules. It cannot see that something LOOKS wrong.

A full visual pass found a defect that passed every automated check on every screen:
**multi-path SF Symbols rendered as solid blobs.** `checkmark.seal.fill` had no checkmark,
`exclamationmark.triangle.fill` had no exclamation mark, `person.crop.circle.fill` had no
person. Seven of twenty icons were affected, across most screens. Every one of them
"passed" verification.

Standard process after any change:

1. `await node.screenshot({scale: 0.5})` and actually LOOK at the result
2. Run the verifier
3. For structural moves, check `absoluteTransform` and screenshot the Section

Batches of four screens at `scale: 0.5` render reliably. Larger batches drop images.

## Fifth gotcha: setBoundVariableForPaint keeps the base colour as a fallback

```js
let p = { type:'SOLID', color:{r:0,g:0,b:0} };          // black base
p = figma.variables.setBoundVariableForPaint(p,'color',V['surface/glass-clear']);
```

Where the binding does not fully resolve — cloned subtrees are one case — the paint falls
back to its BASE colour. A black base renders an opaque black block instead of 30% white.

**Always give the base paint a colour close to the token's own value**, so a partial
resolution degrades to something nearly right rather than to black:

```js
p = { type:'SOLID', color:{r:1,g:1,b:1}, opacity:0.3 };  // matches the token
```

Symptom: a cloned tab bar rendered its active pill as a solid black rectangle while the
original rendered correctly, with identical fill structure.

