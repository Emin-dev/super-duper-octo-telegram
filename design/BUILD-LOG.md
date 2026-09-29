# Build log — page `NEW` (`4007:6935`)

## Verified complete (PASS = 0 violations)

| # | Screen | x | Status |
|---|---|---|---|
| 1 | `Home / Light` | 100 | PASS |
| 2 | `Register / Choose method` | 562 | PASS |
| 3 | `Home / Dark` | 1024 | PASS |
| 4 | `Host / Become a host` | 1486 | PASS |
| 5 | `Register / MyGov handoff` | 1948 | PASS |
| 6 | `Register / MyGov success` | 2410 | PASS |
| 7 | `Register / MyGov failure` | 2872 | PASS |
| 8 | `Register / ID scan` | 3334 | PASS |
| 9 | `Register / Licence scan` | 3796 | PASS |
| 10 | `Register / Selfie` | 4258 | PASS |
| 11 | `Register / Details` | 4720 | PASS |
| 12 | `Register / Review` | 5182 | PASS |
| 13 | `Host / My listed cars` | 5644 | PASS |
| 14 | `Host / List your car` | 6106 | PASS |
| 15 | `Renter / Cars near you` | 6568 | PASS |
| 16 | `Renter / Car detail` | 7030 | PASS |

**16 / 16 passing.** Screens sit in a row at y=100, spaced 462 apart: x = 100 + n*462.
Next free slot: **x = 7492**.

`Home / Dark` is a clone of Light with
`setExplicitVariableModeForCollection(theme, darkId)` — ONE switch flips the whole subtree.
Re-clone it whenever Light changes; do not hand-edit it.
Only override afterwards: the active tab tint must be pure white (RULE B4).

Text styles now 10: the 8 `Type/*` ramp plus `Type/Money large` (40) and `Type/Money row` (17).

## Foundations in place

- `Theme` — `VariableCollectionId:4006:2`, modes **Light** + **Dark**, 30 variables
- `Theme Dark` — `VariableCollectionId:4009:2`, 7 tokens (legacy of the free-tier workaround;
  now redundant since Theme has real modes — DELETE once nothing references it)
- `Type/*` — 8 text styles, Inter. **Swap to SF Pro at handoff.**
- Effect styles — `glassPanel`, `mapGlass`, `backdropMap`
- `SF Symbols` library frame — `4021:2` at (100,1050)

## Revisions 2026-09-17 (session 1, late)

- Icon badges: `brand/bronze` circle + white `icon/on-brand` glyphs (see RULES.md L)
- Tab bar rebuilt as iOS 27 `.clear` Liquid Glass — 30% fill, blur 24,
  darkened OUTSIDE perimeter, bright specular inner shadow
- News cards now use real in-file photography by `imageHash` (RULES.md M)
- 3 new tokens: `icon/on-brand`, `surface/glass-clear`, `line/glass-edge` (Theme now 33 vars)
- Icon badges revised AGAIN to match Emin's reference: cream circle + amber glyph,
  glyph ~60% of circle, tiles 172 tall, soft card elevation (RULES.md N)
- Per-module accent tokens created then REMOVED — reference is one warm family
- Theme now 34 variables
- Both screens re-verified: **PASS**

## SF Symbols injected (14)

`car.fill` `bolt.car.fill` `steeringwheel` `key.fill` `house.fill` `message.fill`
`suitcase.fill` `person.crop.circle.fill` `flag.checkered` `bolt.fill` `chevron.left`
`creditcard` `checkmark.seal.fill` `person.text.rectangle`

Components named `Icon / <sf.symbol.name>`; each description carries
`Image(systemName: "...")` for the dev team.

**TODO:** `Step / Selfie check` currently uses `person.crop.circle.fill`.
It should be `faceid` — extract and swap.

## The build recipe (reuse verbatim)

Every screen-building `use_figma` call starts with:

```js
const page = await figma.getNodeByIdAsync('4007:6935');
await figma.setCurrentPageAsync(page);
for (const st of ['Regular','Medium','Semi Bold','Bold'])
  await figma.loadFontAsync({family:'Inter',style:st});
const theme=(await figma.variables.getLocalVariableCollectionsAsync()).find(c=>c.name==='Theme');
const V={}; for(const id of theme.variableIds){const v=await figma.variables.getVariableByIdAsync(id); if(v)V[v.name]=v;}
const S={}; for(const s of await figma.getLocalTextStylesAsync()) S[s.name]=s;
const E={}; for(const e of await figma.getLocalEffectStylesAsync()) E[e.name]=e;
function paint(n,o){let p={type:'SOLID',color:{r:0,g:0,b:0}}; if(o!==undefined)p.opacity=o;
  return figma.variables.setBoundVariableForPaint(p,'color',V[n]);}
async function T(chars,style,colorVar,width){
  const t=figma.createText(); t.fontName={family:'Inter',style:'Regular'}; t.characters=chars;
  await t.setTextStyleIdAsync(S[style].id); t.fills=[paint(colorVar)];
  if(width){t.textAutoResize='HEIGHT'; t.resize(width,t.height);} else t.textAutoResize='WIDTH_AND_HEIGHT';
  return t;}
function spacer(h){const f=figma.createFrame(); f.name='spacer-'+h; f.resize(1,h); f.fills=[]; return f;}
```

### Hard-won gotchas

1. **Never set text properties before characters.** Create -> fontName -> characters ->
   `setTextStyleIdAsync` -> fix autoResize. Any other order collapses the node to w=0,h=15.
2. **SF Pro does not render here.** Inter only. See STATE.md.
3. Icons: `figma.createNodeFromSvg()` then `rescale()`, then recolour every vector child,
   then `createComponentFromNode`. Rename `Vector` children or the verifier flags them.
4. `use_figma` rolls back cleanly on a thrown error — a failed call leaves nothing behind.
5. Every MCP call counts against the plan limit, `use_figma` included.

## Verification

`tools/verify.js` — paste as a `use_figma` body with `SCREEN_ID` replaced.
Checks: device geometry, default names, unbound fills/strokes, missing or wrong text styles,
collapsed text, tab-bar clearance, white-on-gold contrast, SF Symbol instances in icon slots.

**A screen is not done until the verifier returns `PASS: true`.**

## Queue

1. `Home / Dark` — duplicate Home, switch the frame to Theme's Dark mode
2. `Register / MyGov handoff`, `MyGov success`, `MyGov failure`
3. `Register / ID scan`, `Licence scan`, `Selfie`, `Details`, `Review`, `Pending`
4. Promote tile / news card / notification row / tab bar / button into variant sets
5. Then the flows: EV, GOLF, RENTER, HOST

## Content corrections from reading the real app (2026-09-17)

Reading page 07 corrected two things I had invented:

- "Golf car" -> **"Golf cart"**
- Golf subtitle "By the minute, hour or day" -> **"Available in SeaBreeze"**
  (it is location-gated, not a pricing line)
- Module order is **Host, Renter, Electric car, Golf cart** — Host leads, per Emin's reference

**Always read the real screen on page 07 before building its replacement.**
`SCREENS.md` holds the extracted content and node IDs for all the major flows.

## Scheme layout (2026-09-17, rebuilt)

Page `NEW` reads as a real scheme: giant lane titles, branching connectors, designer notes.
Lanes are Sections that genuinely contain their screens. See `SCHEME.md`.

**Shift+1 to zoom to fit** — the scheme spans 4022 x 8144.

Lane 05 · EV added: Unlock -> Vehicle detail -> Payment -> Pre-trip photos -> Active trip.
The swipe-to-start control lives INSIDE the vehicle card, never on its own page.
Battery rings use `arcData` so the ring genuinely encodes charge level.

## Next in queue

1. `Register / MyGov handoff` + success + failure
2. `Register / ID scan` -> `Licence scan` -> `Selfie` -> `Details` -> `Review`
3. `Host / My listed cars` (`2152:9450`) and `Host / List your car` form (`2152:9172`)
4. `Renter / Cars near you` (`2152:9802`), `Car detail` (`2152:9978`)
5. EV flow EV001-EV007 (`SCREENS.md` has all IDs)
6. Promote tile / news card / notification row / button / tab bar into variant sets

## Verifier gained an overflow rule (2026-09-17)

`layout/overflow` — any direct child of a screen ending past y=878 is flagged.
This caught a real bug: `Renter / Cars near you` had its card strip at y=620 with 300-tall
cards, ending at 920 — 46pt off the bottom of the frame and running under the tab bar.
Cards are now 236 tall at y=532, clearing the bar by one gap unit.

Two more defects the verifier caught that manual review would likely have missed:
- `rescale()` on the selected map pin **stripped its text style**. Anything rescaled must have
  its text styles re-applied afterwards.
- The search bar's icon slot was created but never filled.

## Icon library: 19 SF Symbols

car.fill · bolt.car.fill · steeringwheel · key.fill · house.fill · message.fill · suitcase.fill
person.crop.circle.fill · flag.checkered · bolt.fill · chevron.left · creditcard
checkmark.seal.fill · person.text.rectangle · exclamationmark.triangle.fill · arrow.clockwise
magnifyingglass · slider.horizontal.3

## Known issues to resolve with Emin

1. **Photo assignment is unverified.** Images are applied by `imageHash` from page 04, but the
   hashes were picked by layer NAME, not by looking at each photo. `Renter / Car detail` is
   titled "Porsche 911 Carrera" and shows what appears to be a Mercedes. Emin should review
   and reassign — these are his photos and his call.
2. **Map backdrop is a placeholder.** `Renter / Cars near you` uses a flat tint with drawn
   road lines. RULE B9 requires a pre-blurred desaturated map still (blur 75, saturation 0.7),
   STATIC. No suitable map image was found in the file.
3. `Register / Selfie` step icon uses `person.crop.circle.fill`; it should be `faceid`.
4. `EV / Pre-trip photos` uses `bolt.fill` in the capture slots; it should be `camera.fill`.
5. EV map backdrops are flat tints, same placeholder issue as Cars near you.

## Scheme layout (2026-09-17, rebuilt)

Page `NEW` reads as a real scheme: giant lane titles, branching connectors, designer notes.
Lanes are Sections that genuinely contain their screens. See `SCHEME.md`.

**Shift+1 to zoom to fit** — the scheme spans 4022 x 8144.

Lane 05 · EV added: Unlock -> Vehicle detail -> Payment -> Pre-trip photos -> Active trip.
The swipe-to-start control lives INSIDE the vehicle card, never on its own page.
Battery rings use `arcData` so the ring genuinely encodes charge level.

## Next in queue

1. EV flow: EV001 swipe-to-start, EV002 detail, EV003 payment, EV005/007 pre-trip, EV006 active trip
2. Trips, Chats, Wallet / Top up (**fix the ₦ naira currency bug**)
3. Golf flow
4. Promote tile / news card / notification row / button / tab bar / car card into variant sets
5. Dark variants for all screens (clone + setExplicitVariableModeForCollection)
6. Prototype wiring

## Session 1 final state (2026-09-17)

**30 screens, 9 lanes, 30/30 passing.**

| Lane | Screens |
|---|---|
| ONBOARDING | Choose method, MyGov handoff/success/failure, ID scan, Licence scan, Selfie, Details, Review |
| HOME | Light, Dark |
| HOST | Become a host, My listed cars, List your car |
| RENTER | Cars near you, Car detail |
| EV | Unlock, Vehicle detail, Payment, Pre-trip photos, Active trip |
| TRIPS | My trips, Trip detail |
| CHATS | Messages, Thread |
| WALLET | Balance, Top up |
| GOLF | Map, Booking |

### Photo identification — resolved by LOOKING, not by layer name

Rendering each source image settled it:

| Hash | Actually depicts |
|---|---|
| `0a3cdf5d` `mercedes-hero` | Silver Mercedes-AMG GT, city at night — name was accurate |
| `2d3ac2b9` `VIP Premium Golf Cart` | A real white golf cart on grass — name was accurate |
| `dbe385cf` `car-thumbnail` | White hatchback |
| `3417fc1d` `car-image-container` | Red Mustang, night, with "Inactive / 19 views" overlay — a listing CARD, not a clean photo |
| `03285410` `car-image-container` | White/silver sedan |

Labels were changed to match the photos rather than the reverse, using real fleet data:
`Renter / Car detail` is now Mercedes-AMG GT at ₼380 (was Porsche 911 at ₼460 with a
Mercedes photo). Cars near you card 2 is Honda Civic at ₼90 with the hatchback photo.

**Still unidentified:** the other car-thumbnails, `Luxury Vehicle`, `Pilotcar Eco XL`, `Denago XL`.
Only one inline image renders per response, so identifying the rest is one call each.
Emin should confirm the list-row thumbnails.

### Currency bug FIXED
`Wallet / Top up` prices in ₼ manat. The shipping design used ₦ naira.

### Real Apple Maps — DONE
Rendered with MapKit `MKMapSnapshotter` via `tools/mapsnap.swift`. Genuine Apple cartography
of Baku and the Absheron peninsula, `.muted` emphasis for the desaturation RULE B9 requires.
Placed on Cars near you, EV Unlock, EV Active trip and Golf Map.
See `tools/README-maps.md`.

### Remaining
2. `faceid` should replace `person.crop.circle.fill` on the selfie step.
3. `camera.fill` should replace `bolt.fill` in the pre-trip capture slots.
4. Dark variants exist only for Home. Every other screen needs one (clone + mode switch).
   `baku-dark.png` is already rendered for the dark map screens.
5. Components not yet promoted to variant sets.
6. Prototype not wired.

## DARK MODE lane (2026-09-17)

**Deliberately NOT a duplicate of all 29 screens.**

Dark mode here is a variable-mode switch. Duplicating every screen would create 29 more
artifacts to hand-maintain — precisely the trap the original file fell into with its 8
duplicated dark frames and 14 empty placeholders.

Instead: **one representative screen per flow**, 8 total, in a `DARK MODE` lane at y=13020.

| Row | Screens |
|---|---|
| 0 | Register / Choose method, Host / My listed cars, Renter / Cars near you, EV / Unlock |
| 1 | Trips / My trips, Chats / Thread, Wallet / Balance, Golf / Booking |

Each is a clone bound to Theme's Dark mode with
`setExplicitVariableModeForCollection(theme, darkId)` — not a recoloured copy.
**Any other screen flips the same way: select it, switch the mode in Figma.**

Two manual steps dark mode still needs:
1. **Tab bar tint becomes pure white** (RULE B4) — gold is invisible on the dark glass bar
2. **Map images do not flip with variable modes.** `baku-dark.png` was rendered separately
   with `NSAppearance(.darkAqua)` and uploaded to the dark map screens

## FINAL STATE — session 1

**37 screens across 10 lanes. 37/37 passing. 20 SF Symbols, 0 integrity issues.**

| Lane | y | screens |
|---|---|---|
| ONBOARDING | 0 | 9 |
| HOME | 2428 | 2 |
| HOST | 3752 | 3 |
| RENTER | 5076 | 2 |
| EV | 6400 | 5 |
| TRIPS | 7724 | 2 |
| CHATS | 9048 | 2 |
| WALLET | 10372 | 2 |
| GOLF | 11696 | 2 |
| DARK MODE | 13020 | 8 |

Scheme spans 4022 x 15308. **Shift+1 to fit.**

### Still open
1. `faceid` should replace `person.crop.circle.fill` on the selfie step
2. `camera.fill` should replace `bolt.fill` in the pre-trip capture slots
3. List-row car thumbnails are unidentified — Emin to confirm which photo is which vehicle
4. Components not yet promoted to variant sets
5. Prototype not wired
6. Localization (az / ru) not started — check every control against Azerbaijani, which runs longest

## Priority 1 gap screens (2026-09-17)

Built after reading all 57 screens on `07` and comparing against a production checklist.
See `GAPS.md`.

| Screen | Lane | Why it mattered |
|---|---|---|
| `Host / Booking request` | HOST col 3 | **The single biggest hole in the product.** The status vocabulary contains `waitingForHost` and `declined`, so a host-side approval screen MUST exist — and nothing in either design had one. The marketplace cannot function without it. |
| `EV / Trip summary` | EV col 5 | End-of-trip receipt: duration, distance, paused time, charges, rating |
| `Renter / Booking confirmed` | RENTER col 2 | The `celebrate` haptic moment the motion spec describes, with no screen to attach it to |
| `Renter / Date picker` | RENTER col 3 | Named on `05 · Prototype`, built nowhere |

**45 screens total. 41 light + dark screens verified, 41/41 passing.**

### Two vision-check notes

1. At `scale: 0.5` gold glyphs read as near-black in thumbnails. I nearly "fixed" a
   non-existent bug. **Confirm colour from the data (`fills[0].color`) or a full-scale
   screenshot before changing anything** — the fills were correct at 224,135,31 = #E0871F.
2. Blank `" "` text used as a layout placeholder trips `type/collapsed`. Use an empty
   frame instead; the calendar's trailing cells are now `Day / empty`.

## Scroll, layering and map fixes (2026-09-17)

Emin reported the tab bar scrolling away in Present mode. Root cause and fix in RULES.md O.
Maps made full-bleed per RULES.md P.

Defects found by VISION that the verifier could not see:
1. Tab bar rendered behind content when pinned via `numberOfFixedChildren`
2. "End trip" and fine print floating unreadably over the map on EV / Active trip
3. New map controls colliding with the search bar — "Filters" clipped to "Fil"
4. "SeaBreeze · 6 carts available" clipped by a back button on Golf / Map
5. Placeholder road lines still drawn over the real Apple Maps render
6. Dark clones stale after their light counterparts were rebuilt

New verifier rule: `layout/tabbar-not-front`.

**41 screens, 41 passing.**

## COMPONENTS lane (started 2026-09-17)

At y=15448. Three variant sets so far:

| Set | Variants | Properties |
|---|---|---|
| `Button` | 9 | Style=primary/secondary/destructive x State=Default/Pressed/Disabled |
| `Chip` | 2 | Selected=true/false |
| `TripStatusChip` | 6 | Status= the six fixed trip states |

Each set carries its rule in the component description, so the constraint travels with the
component into dev handoff.

### Still to componentise
List row · Input field · Nav bar · Tab bar · Card · Badge · CarCard · Small action

### Then: the spec DSL
One generic renderer in `use_figma` that interprets compact JSON screen specs, so a screen
drops from ~110 lines of layout code to ~15 lines of data. Expected 3-5x on list/form screens.

## COMPONENTS + spec DSL (2026-09-17)

**7 variant sets** in the COMPONENTS lane (y=15448):

| Set | Variants | Properties |
|---|---|---|
| `Button` | 9 | Style=primary/secondary/destructive x State=Default/Pressed/Disabled |
| `List row` | 4 | Trailing=chevron/value/toggle/none |
| `Input` | 3 | State=empty/filled/error |
| `TripStatusChip` | 6 | Status= the six fixed trip states |
| `Badge` | 3 | Size=36/44/56 |
| `Nav bar` | 2 | Action=none/text |
| `Chip` | 2 | Selected=true/false |

Each set carries its governing rule in the component description, so the constraint travels
into dev handoff instead of living only in a document.

**Spec DSL built and proven** — see `tools/SPEC-DSL.md`. The PROFILE lane's three screens were
rendered from ~20 lines of JSON each instead of ~110 lines of layout code.

## Renter is a list, not a map (2026-09-17)

Emin's call, and the right one. A list suits daily/weekly rental where you compare vehicles;
a map suits short-term location-based pickup. Different jobs, different patterns.

- `Renter / Cars near you` rebuilt as a scrolling list: search with date range, filter chips,
  result count, car cards with photo, price pill, specs and rating. A `Map` chip toggles views.
- EV and Golf keep full-bleed maps — those ARE location-first products.
- `EV / Unlock` card now carries a vehicle photo beside the battery ring, matching Golf.

**44 screens, 44 passing, 12 lanes.**

## Design system v2 (2026-09-17)

**10 variant sets** in COMPONENTS (y=16772):

Button (9) · Tile (2) · List row (4) · Input (3) · TripStatusChip (6) · Segmented control (2) ·
Badge (3) · Nav bar (2) · Chip (2) · Toggle (2)

### Corrections from Emin's Profile reference
1. **Bento, not lists.** Profile rebuilt as a 2x2 tile grid + full-width Wallet tile, matching
   the Home modules. My first version used settings rows — wrong language for this app.
   `Tile` is now a component so the pattern is enforced. See RULES.md Q.
2. **Centred nav title** on tab-root screens.
3. **Tab bar reflects context** — 21 screens retinted, 84 tabs normalised. See RULES.md R.
4. **Inactive tab opacity bug** — a leftover 0.55 paint opacity made Home read lighter than
   Chats and Trips on the same bar. Caught by eye, not by the verifier.

### Renter is a list, EV and Golf are maps
Daily/weekly rental is a comparison task — list. Short-term pickup is a location task — map.

**44 screens, 44 passing, 12 lanes, scheme 4022 x 18788.**

## Profile interaction states (2026-09-17)

Five more screens from Emin's reference screenshots, which revealed interactions I had no
knowledge of. See RULES.md T.

| Screen | State |
|---|---|
| `Profile / Language menu` | Native menu, single choice, 4 languages |
| `Profile / Appearance menu` | Native menu, Dark / Light / System (auto) |
| `Profile / Notifications menu` | Native menu, MULTI select |
| `Profile / Help sheet` | Sheet + Done. Contact rows, then Sign out / Delete account in danger |
| `Profile / Wallet sheet` | Sheet. Balance, Top up, This month, 2-column Activity grid |

New token `surface/scrim` — the dim behind a sheet, heavier in dark mode. Theme is now 35 variables.

Two verifier catches on the new screens:
- `Scrim` used a raw black fill instead of a token
- Two containers were left named `Group`

**49 screens, 49 passing. 12 lanes.**

### Notable
`Delete account` now exists, which was listed in GAPS.md as an App Store review blocker.
Apple has required in-app account deletion since 2022. Emin's own design already had it —
in the Help sheet, which is an unusual but defensible placement.

## Bento becomes law + IA corrections (2026-09-17)

**RULES.md U** makes bento the default for every screen, with one precise test:

> Does tapping it go somewhere? Then it is a **tile**, never a row with a chevron.

Three forms, each with a job:
- **Tile** — navigation destination
- **Separate card** — a repeating record (trip, car, listing, message, notification)
- **Rows inside one card** — label -> value data, or actions inside a sheet

A 27-screen audit found only three violations. `EV / Vehicle detail` was converted from four
chevron rows to a bento grid. The other two were removed outright.

New verifier rule `bento/row-with-chevron`, with sheets exempt.

**RULES.md V** records Emin's IA corrections:
- One support chat for all — no Help destination
- Notifications belong to Home; Profile holds only their settings
- The notification icon SCROLLS Home down, it does not navigate

**47 screens, 47 passing.**

## AUTH lane (2026-09-17)

Placed at **y=0, above everything** — it is the first thing a user sees, so it should read
first in the scheme. All 12 other lanes shifted down.

| Screen | Notes |
|---|---|
| `Auth / Splash` | Gold gradient, white mark, wordmark. The only full-bleed brand moment. |
| `Auth / Welcome` | Create account / Sign in / **Continue without an account** |
| `Auth / Sign up` | MyGov (recommended, one tap) and email+documents. **Google dropped** per decision. |
| `Auth / Sign in` | +994 prefixed phone, password, forgot link, "Use MyGov instead" |
| `Auth / Verification pending` | "Usually a few hours" + a card saying browsing continues meanwhile |

Two decisions visible in the design itself:

1. **"Continue without an account" is a real, prominent option**, not buried. The browse-first
   rule says pricing is the hook and nothing may block it — so the wall is opt-in.
2. **Verification pending does not trap the user.** A card states they can keep browsing,
   and the primary action is "Go to home" rather than a dead-end wait.

The existing `07` design has a Sign In screen with Turkish placeholder names ("Elif",
"Yılmaz") and a verification screen naming a different user ("Nazila"). Both replaced with
consistent Azerbaijani-market content.

**52 screens, 52 passing. 13 lanes. Scheme 4022 x 21076.**

## HOST second row (2026-09-17, late)

The supply side was the biggest business gap: hosts could see an *estimated* ₼440/week with
no way to see actual money, withdraw it, or stop double-booking.

| Screen | What it fixes |
|---|---|
| `Host / Earnings` | Real withdrawable balance (₼1,240.50) vs still-clearing, trip-by-trip payouts |
| `Host / Payout` | Withdraw to a bank card, fee breakdown, arrival time |
| `Host / Availability` | Calendar distinguishing **booked** (gold, immovable) from **blocked** (grey, host's choice) |

`Host / Availability` is the one that prevents double-booking. Booked dates cannot be blocked —
changing a confirmed trip goes through the renter, not the calendar.

## VERIFIED STATE 2026-09-18

Audited live against Figma, not from memory.

**Page `iOS 27 · SCHEME V3` — 55 screens, 13 lanes.**

| Lane | Screens | | Lane | Screens |
|---|---|---|---|---|
| AUTH | 5 | | TRIPS | 2 |
| ONBOARDING | 9 | | CHATS | 2 |
| HOME | 2 | | WALLET | 2 |
| HOST | 7 | | GOLF | 2 |
| RENTER | 4 | | DARK MODE | 8 |
| EV | 6 | | PROFILE | 6 |
| | | | COMPONENTS | 10 variant sets |

Foundations: `Theme` 35 variables with Light+Dark modes · 10 `Type/*` text styles ·
3 effect styles · **34 SF Symbols** · 10 variant sets.

Legacy still present and untouched: `Rentbutik` (24 vars, 1 mode) bound to pages 04/07/08,
and `Theme Dark` (7 vars) — now redundant since `Theme` has real modes. **`Theme Dark` can be
deleted once nothing references it.**

## Trip lifecycle completed (2026-09-18)

Three holes in TRIPS, all of them things a real user hits:

| Screen | |
|---|---|
| `Trips / Leave review` | 5-star input, quick tags, note. A 4.8 rating showed everywhere with no way to produce one. |
| `Trips / Cancel trip` | Refund maths (paid ₼499, fee ₼50, refund ₼449), policy line, reason chips. Destructive action last. |
| `Trips / Damage report` | Issue type, 6 photo slots, description, insurance confirmation. Pre-trip photos attach automatically. |

`Trips / Cancel trip` puts **"Keep my trip" above** the destructive action, and states the
refund before asking for confirmation — no one should discover the fee after cancelling.

### Paint base-colour repair
Vision caught review stars rendering white. Root cause in RULES.md W: a bound paint falls back
to its base colour. **368 nodes repaired file-wide.** New verifier rule `tokens/base-mismatch`.

**58 screens, 58 passing.**

---

## Session 2026-09-18 (continued) — STATES lane

**Lane:** `STATES` section `4124:293`, page `iOS 27 · SCHEME V3` (`4007:6935`), y=22320, 4022x2288.
**Result:** 9 screens, 9 passing. File total **67 screens across 14 lanes**.

| Screen | Node | Icon | Glyph |
|---|---|---|---|
| States / No network | 4124:296 | wifi.slash | amber |
| States / No chats | 4124:380 | bubble.left.and.text.bubble.right.fill | amber |
| States / No trips | 4124:464 | suitcase.fill | amber |
| States / No listings | 4124:548 | car.fill | amber |
| States / Search no results | 4124:632 | magnifyingglass | amber |
| States / Payment declined | 4128:318 | creditcard.trianglebadge.exclamationmark | danger |
| States / Location denied | 4128:349 | location.slash.fill | amber |
| States / Wallet empty | 4128:380 | wallet.bifold.fill | amber |
| States / Something went wrong | 4128:411 | exclamationmark.triangle.fill | danger |

Pattern and copy rules are now RULES.md section X.

### Build recipe used (fast, and worth repeating)

Building a screen from primitives is slow and drifts from convention. Two cheaper moves:

1. **Clone a finished screen, strip its `Content`, rebuild.** The frame, background binding,
   clipping and tab bar all come along correct for free.
2. **Once one state screen exists, clone *it* and mutate in place** — swap the icon instance
   with `inst.swapComponent()`, retype three strings, swap the button. Roughly six operations
   per screen instead of twenty.

Contextual tab bars were fixed by cloning the `Tab bar` frame out of the screen the user would
actually have been on (`Chats / Messages`, `Wallet / Balance`, …) rather than restyling pills.

### Three SF Symbols added

`wifi.slash` (4125:315), `location.slash.fill` (4125:318),
`creditcard.trianglebadge.exclamationmark` (4125:321).

All three are multi-path symbols and were built as a **single path with `fill-rule="evenodd"`**,
per the blob bug in ICONS.md. Verified by eye at 5-6x zoom before use — the cutouts render.

### Two tooling changes

- **`verify.js` now runs over a whole lane** — set `LANE_ID` to a Section id and it reports
  every screen in it plus a pass/fail summary. Nine screens in one request instead of nine.
- **The tab-clearance rule now tests the outcome, not the mechanism.** It required a node named
  `spacer-96`; a container with `paddingBottom >= 96` satisfies the same requirement and the
  new state screens use exactly that. A rule that encodes one implementation of a requirement
  will fail correct work — it now accepts either.

### SF Pro re-probed — still does not render

The file now carries SF Pro text styles (`Large title`, `Headline`, …), which looked like the
blocker had lifted. It has not:

| Font | Result |
|---|---|
| SF Pro Regular | w=0, h=15 — does not render |
| SF Pro Display Bold | family does not exist |
| SF Pro Text Medium | family does not exist |
| Inter Regular | w=227, h=41 — renders |

The Inter + `Type/*` strategy stands, and so does the one-pass swap at handoff.

---

## Session 2026-09-19 — three registration lanes replaced by one

**Emin:** *"in figma remove AUTH, ONBOARDING, REGISTRATION, and create one simple flow all in
one simple in ios27 scheme page"*

### What was there

Three lanes covering the same ground, 32 screens:

| Lane | Screens |
|---|---|
| `AUTH` | 5 — splash, welcome, sign up, sign in, verification pending |
| `ONBOARDING` | 9 — MyGov handoff/success/failure, ID + licence + selfie scan, details, review |
| `REGISTRATION · CONNECTED UX FLOW` | 18 — built later by another agent, re-covering both |

Plus one orphan, `Register / Choose method · Dark`, in the DARK MODE lane.

### Archived before deleting

`SPEC/_ARCHIVED-registration-flows.md` — full structure for AUTH and ONBOARDING, copy for
all 18 REGISTRATION screens. Deletion in Figma is recoverable only through version history;
this puts the words in git. Worth keeping from the archive: the viewfinder + step-indicator
capture pattern, and the camera-permission screen (the only permission priming that existed
anywhere).

### What replaced it — lane `START` (`4159:382`), 5 screens

| Screen | Node |
|---|---|
| Start / Welcome | 4159:385 |
| Start / Phone | 4159:406 |
| Start / Code | 4159:427 |
| Start / Identity | 4159:448 |
| Start / Ready | 4159:469 |

5 passing, verified by rule and by eye. File total: **13 lanes, 57 screens.**

Rationale and the one-entry-flow rule are RULES.md section Y.

### Two things worth remembering

**The buttons I cloned from lived in the lanes I deleted.** `Button / Primary` was `4036:115`,
inside ONBOARDING. Hardcoding node ids across a destructive change breaks silently. The build
now finds buttons by traversal from a lane that is not being touched:

```js
const states = await figma.getNodeByIdAsync('4124:293');
const primary = states.children.find(c => c.name === 'States / No network')
                      .findOne(n => n.name === 'Button / Primary');
```

**`node.fill` throws on a FRAME.** A helper that accepted either a raw node or a config object
probed `item.fill` to decide which it had. On a spacer frame that is not a missing property,
it is `TypeError: node.fill: no such property 'fill' on FRAME node`, and the whole script
rolls back. Detect the wrapper by a key that only the wrapper has (`item.node`), never by
probing a key that the node might reject.

### Bottom inset corrected

The first build ended screens with `spacer-24`. Screens without a tab bar need **34** — the
home indicator. The verifier found nothing because there was no overflow; only looking at the
render showed the fine print crowding the bottom edge. Now RULES.md section Y.

