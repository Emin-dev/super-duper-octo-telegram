# Design Rules — non-negotiable

## A. Brief from Emin (2026-09-17)

1. **Device baseline: iPhone 18 Pro = 402 x 874 pt** (3x, 1206x2622 px). Verified against ios-resolution.com.
   Note: iPhone 18 Pro Max = 440 x 956. Most legacy boards use Pro Max — do not copy their size.
2. **Apple native solutions only.** No invented controls. If iOS has a native pattern, use it.
3. **SF Symbols only. No custom icons.** Ever.
4. **Light + dark mode**, driven by variable modes, never duplicated frames.
5. **Native haptics** specified per interaction.
6. **Production-ready for SwiftUI.** Every component maps to a named SwiftUI view.
7. **Fully clickable prototype in Figma** before handoff to dev.

## B. Laws inherited from the shipping build

These were learned from real shipped bugs. Do not relitigate them.

1. **Never white text on gold.** Measures ~2:1 and fails contrast. Content on any gold fill is fixed dark ink `#14161A`, in BOTH modes.
2. **Photo cards are OPAQUE, never glass.** The glass backdrop ignores `clipShape` and leaks the image past rounded corners. Shipped as a bug once.
3. **Chip text renders directly on glass.** Never put a filled shape inside a `.background` under glass — it rasterises a second layer and the text goes visibly blurry. Shipped once.
4. **Tab bar tint:** pure white in dark mode, `#B4640A` in light. Pure white is invisible on the light glass bar. Shipped as a bug once.
5. **Nav bars are ONE line.** Back button and title share the row. Nothing gets its own line, including on maps.
6. **Only the chat thread hides the tab bar.** Every other root explicitly keeps it visible — hiding it inside a sheet leaks to the presenting tab and the bar vanishes for 2-3s on return.
7. **One button height app-wide: 50.** One shape: capsule. Labels never wrap; they scale to 70% and stop. If it still does not fit, shorten the copy — never grow the button.
8. **`tabBarClearance` = 96pt** bottom padding on every tab-root scroll.
9. **The map backdrop still is STATIC** (blur 75, saturation 0.7). A live/animated blurred map caused real device stutter. Never reintroduce.
10. **Only the SELECTED map pin scales (1.35) and casts a shadow.** Live shadows on every pin cost real frames with 45 pins on screen.
11. **Never size a control to fit the English string.** Check against Azerbaijani, which runs longest.
12. **Figma cannot render Liquid Glass.** It is a real-time refraction material; Figma has only blur, fills, strokes and gradients. See section G for the closest honest stand-in and the fidelity ceiling. Judge real glass on device, never in Figma.

## C. Geometry

- Radius: card 30, tile 26, chip 18, capsule = capsule
- Gap 14 between cards/tiles; screen horizontal padding 18
- Button height 50; circular icon button 44; in-card action capsule 38
- Status dot 7pt; photo colour strip 4pt; pin 26pt icon in 33pt battery ring

## D. Motion (Theme curves — three carry the whole app)

| Token | SwiftUI | Figma |
|---|---|---|
| `Theme.smooth` | `.smooth(duration: 0.45)` | 450ms cubic-bezier(0.4, 0, 0.2, 1) |
| `Theme.snappy` | `.snappy(duration: 0.32, extraBounce: 0.02)` | 320ms cubic-bezier(0.32, 0.72, 0, 1) — THE default |
| `Theme.bouncy` | `.spring(response: 0.5, dampingFraction: 0.82)` | 500ms cubic-bezier(0.34, 1.56, 0.64, 1) |
| `Theme.sheet` | native sheet | 400ms, Move in from bottom |
| `Theme.push` | NavigationStack push | 350ms, Move in from right |

## E. Haptics vocabulary (one-shot only; nothing loops, nothing fires on scroll)

`tick` light 0.7 - swipe quarter-marks, small toggles ·
`click` selection - pin taps, chips, calendar days, carousel settle ·
`open` soft 0.8 - card expanding, sheet opening ·
`grab` rigid - holds, drag ends, pinning a chat ·
`gain` medium 0.6 then 1.0 at 110ms - money arriving, date range closing ·
`celebrate` success + three-beat tail 160/120/90ms - ONLY a confirmed booking ·
`ignition` heavy then rigid 0.9 at 140ms - a keyless ride starting ·
`warn` warning - low balance, destructive confirmations ·
`error` error - dates already taken

## F. Trip status vocabulary (fixed and exhaustive)

`waitingForHost`, `upcoming`, `ongoing`, `completed`, `declined`, `cancelled`

Trip tiles repeat status three ways: 4pt colour strip on the photo, 7pt truth dot (honey = riding now, gold = new/upcoming), and the chip.

## G. iOS 27 + Liquid Glass (added 2026-09-17)

Target OS is **iOS 27**, released 2026-09-14. Maximise Liquid Glass wherever iOS itself would use it.

### What changed in iOS 27 vs iOS 26

| Change | Design consequence |
|---|---|
| Better diffusion of complex content | Glass stays legible over photos and maps; less need to fall back to opaque |
| **Darkened perimeter** around glass elements | Add a dark outer edge — this is new, and absent from our iOS 26 recipe |
| **Brighter specular highlights** | Stronger top-edge light catch than iOS 26 |
| Transparency slider (ultra clear -> fully tinted) | Glass opacity is user-controlled. Never rely on a single opacity for legibility |
| Scroll edge effect | A uniform bar appears at the top when content scrolls under a floating toolbar |
| Icons sharper, optional refraction, multi-layer Glass in Icon Composer | App icon work is a separate track |

### Figma stand-in recipe — iOS 27

Supersedes the iOS 26 recipe in rule B12.

1. Background blur 20 (diffusion)
2. Fill 55% — `surface/glass` token, mode-aware
3. **Darkened perimeter:** 1px outer stroke, black, low opacity (NEW in 27)
4. **Specular highlight:** inner stroke, white gradient concentrated on the top edge, brighter than the flat 40% used for iOS 26
5. Optional inner shadow for depth

### Fidelity ceiling — state this plainly to Emin, do not oversell

Figma **cannot** reproduce Liquid Glass. It has no refraction, no real-time specular response,
no adaptive tinting, and cannot honour the user's transparency slider.

What CAN be made production-identical in Figma: layout, spacing, type, colour, components,
hierarchy, iconography, states.
What CANNOT: the glass material itself.

Therefore: photo cards stay OPAQUE (rule B2), and glass surfaces are judged on device.
Any claim that a Figma board is "identical to production" excludes the glass material.

## H. Naming conventions (cross-discipline)

Same name in design and code matters more than the case convention. Slash creates hierarchy.

| Thing | Pattern | Example |
|---|---|---|
| Variable | `group/name` | `text/ink`, `radius/card`, `space/gap` |
| Component | `Component/Name/Variant` | `Component/Button/Primary` |
| Icon | `Icon/Name` | `Icon/car.fill` (SF Symbol name verbatim) |
| Screen | `Flow/NN Name` | `Renter/03 Car detail` |
| Effect style | camelCase matching code | `glassPanel`, `mapGlass` |

- Name every layer that carries structural meaning. No `Frame 23530`, `Vector 12`, `bg`, `ref`.
- Icon layers use the **exact** SF Symbol name so dev can paste it straight into `Image(systemName:)`.
- Token names match `Theme` properties in `DesignSystem.swift`.

## I. Registration — two paths (decided 2026-09-17)

**Path A — MyGov (primary).** Azerbaijan government identity app. One tap: our app -> MyGov -> back
to our app, verified. Fewest screens, strongest identity guarantee.
Design needs: entry choice, the hand-off moment, the return/success state, and a failure/timeout state.

**Path B — Custom registration.** Password-based, plus driving licence check and full personal details.
Design needs: account creation, password rules, personal details, licence capture + verification,
review/submit, pending state.

Both paths converge on the same verified-account state. Driving licence check is mandatory for
renting regardless of path — if MyGov does not supply licence data, Path A still needs the licence step.
CONFIRM with Emin.

## J. Free-tier dark mode (built 2026-09-17)

Figma Starter allows ONE mode per collection, so native light/dark switching is unavailable.
The free workaround, already built:

- `Theme` (`VariableCollectionId:4006:2`) — 29 tokens, Light values
- `Theme Dark` (`VariableCollectionId:4009:2`) — the 7 tokens whose values actually differ

Mode-invariant tokens (`brand/*`, `text/ink-faint`, `text/on-gold`, all `radius/*`, `space/*`,
`size/*`) exist ONLY in `Theme` and are shared by both modes. No duplication to maintain.

A dark screen binds its 7 differing colours to `Theme Dark` and everything else to `Theme`.
Components should carry a `Mode=Light|Dark` variant property so a screen flips at instance level.

On upgrade to Professional: merge `Theme Dark` into `Theme` as a second mode and delete it.
Token names are already identical, so the merge is mechanical.

**Note:** SwiftUI has no such limitation. Dark mode in code is done properly with semantic colours
regardless of what Figma can express.

## K. Product decisions (2026-09-17)

**Build page:** `NEW`. Never `07 - Scheme` or `08 - Archived Scheme V1`.

**Home composition:** 4 module tiles + news + notifications. Bento layout, `radius/tile` 26.

**Registration gate — browse first, verify early:**
1. App opens straight to Home. No wall. Anyone can browse cars and see prices.
2. Account is created at the first meaningful action (favourite, chat, booking).
3. Identity verification is required before the FIRST RIDE, not before browsing.

This ordering is deliberate: pricing is the hook, so nothing may block it.

**Path A — MyGov.** One tap, returns ALL data including driving licence. No separate licence step.
Screens: entry choice, hand-off moment, return/success, failure/timeout.

**Path B — Custom.** We capture everything ourselves, in this order:
1. ID document scan
2. Driving licence scan (front + back, expiry + category)
3. Selfie / liveness check, matched to the ID
4. Manual personal details form — confirms what was scanned, and the fallback when scanning fails

Both paths converge on the same verified-account state.

## L. Icon colour + iOS 27 glass (revised 2026-09-17)

### SUPERSEDED 2026-09-17 — see "Icon badges (final)" below

*The white-on-bronze rule below was replaced after Emin shared the shipping app as the
visual reference. Kept for the contrast arithmetic, which still holds.*

### Icons are white — on bronze, not gold

Emin asked for white icons. Rule B1 forbids white on gold, but B1 is about **text**.
WCAG thresholds differ:

| Content | Required contrast | White on `brand/solid` #E0871F | White on `brand/bronze` #B07C16 |
|---|---|---|---|
| Text | 4.5:1 | ~2.8:1 FAIL | ~3.9:1 FAIL |
| Icons / UI objects | 3:1 | ~2.8:1 FAIL | ~3.9:1 **PASS** |

So: icon badges use a **`brand/bronze` circle with `icon/on-brand` (#FFFFFF) glyphs**.
B1 still stands for text — white TEXT on any gold fill must never ship.

**Exception — the tab bar.** Its icons sit on glass, not on a fill. Pure white is invisible
on the light glass bar (rule B4, shipped as a bug once), so tab icons stay
`text/gold` when active and `text/ink-soft` when not.

### iOS 27 glass variants

Apple exposes `.regular` (medium transparency, the default) and `.clear` (high transparency).
The floating tab bar uses **`.clear`**.

| Token | Light | Dark | Use |
|---|---|---|---|
| `surface/glass` | #FFFFFF 55% | #14161A 55% | `.regular` — cards, sheets, chips |
| `surface/glass-clear` | #FFFFFF 30% | #14161A 30% | `.clear` — floating tab bar |
| `line/glass-edge` | #000000 12% | #000000 35% | darkened perimeter, NEW in iOS 27 |
| `icon/on-brand` | #FFFFFF | #FFFFFF | icons on bronze or darker |

Tab bar recipe: `surface/glass-clear` fill, `line/glass-edge` 1px **OUTSIDE** stroke,
background blur 24, inner shadow white 85% at y+1 (specular), drop shadow y+8 blur 24 spread -4.

Glass only reads as glass when there is content behind it. A floating bar over an empty
background looks like a flat panel — always let content scroll underneath.

## M. Imagery

Reuse the photography already in the file rather than importing stock. Page `04 · Screens`
holds 45 unique image fills; apply them by `imageHash`:

```js
node.fills = [{ type:'IMAGE', imageHash:'<hash>', scaleMode:'FILL' }];
```

In use: `mercedes-hero` `0a3cdf5dee4315cca2f46f6078ae2b2a0aa94ab8`,
`Luxury Vehicle` `6387c08ad7fa700eee7d1ac0d53cb34801e21d12`.
Also available: `car-image-container`, `VIP Premium Golf Cart`, `Denago XL`, `Pilotcar Eco XL`.

Badges over a photo use `surface/card` at 92% with `text/ink` — NOT `text/on-gold`,
which is only correct over a gold fill.

## N. Icon badges (final — matches the shipping app)

Emin's reference screenshot is the target. What makes it work:

1. **One warm family, not per-module hues.** A multi-colour experiment (green EV, teal golf,
   indigo host) was built and removed — it fought the brand.
2. **Light cream circle, saturated amber glyph.** `brand/tint` #FDEFD9 behind `brand/solid` #E0871F.
3. **The glyph fills ~60% of the circle.** This was the real defect in the first attempt —
   a 22pt glyph in a 44pt circle reads weak and washed out regardless of colour.

| Context | Circle | Glyph |
|---|---|---|
| Home module tile | 56 | 34 |
| Notification row | 44 | 26 |
| Registration card head | 52 | 32 |
| Registration step row | 36 | 22 |

Tile height is **172** (not 150) — closer to the reference's generous proportions while still
keeping News above the fold.

**Card elevation:** drop shadow, black 6%, y+6, blur 18, spread -2. Applied to module tiles,
news cards and notification rows.

`brand/tint` in dark mode is `brand/amber` at 18%, so badges stay warm without glowing.

## O. Scrolling and floating chrome (2026-09-17)

Figma's `scrollBehavior` property does NOT exist in this plugin API build. The legacy
`numberOfFixedChildren` does, but it pins the FIRST N children — which are the BACK-most
layers — so a pinned tab bar renders behind the content. Verified by screenshot.

**Use structure instead, exactly as SwiftUI would:**

```
Screen (overflowDirection NONE)
├─ Map            ← full-bleed background, if any
├─ Scroll area    ← FRAME, clipsContent, overflowDirection VERTICAL
│   └─ Content    ← the tall column
└─ Tab bar        ← LAST child = front-most, outside the scroll area
```

A Scroll area is only created when content actually exceeds 874.

**The tab bar must always be the last child.** The verifier now checks this
(`layout/tabbar-not-front`).

## P. Maps are canvases, not panels

A map that occupies part of a screen is a panel. A map that fills the screen is a canvas you
float over — and that is the iOS convention (Apple Maps, Uber, Lime).

- The map is **402 x 874 at 0,0**, the back-most child
- Everything else floats over it **inside a glass container**
- Nothing sits loose on a map. Bare text over cartography is unreadable, and this was a real
  defect on EV / Active trip: "End trip" and the fine print floated over streets.
- One bottom-anchored glass panel gathers all controls, bottom edge at
  `874 - 68 - 24 - 14 = 768`, clearing the tab bar by one gap unit
- Screens that already carry top chrome (a search bar, a location chip) must NOT also get
  back/recenter controls — they collide and clip the text

## Q. Bento is the layout language (from Emin's reference, 2026-09-17)

The app uses **bento card grids**, not settings lists. Home modules and Profile settings share
one unit: the `Tile`.

```
Tile  176 (half) or 366 (full) x 172,  radius 26,  surface/card
  padding 16
  Badge 56 at the top
  push (FILL)                ← pins the text to the bottom
  Title      Type/Headline   -> text/ink
  Supporting Type/Caption    -> text/ink-soft
```

A settings screen is a 2x2 grid of half tiles plus a full-width tile, NOT a list of rows.
`List row` still exists for genuinely list-shaped content — help topics, notifications,
transactions — but never for primary navigation.

**Nav title is CENTRED** on tab-root screens (Profile), left-aligned with a back button on
pushed screens.

## R. The tab bar reflects context

The active tab follows the screen, never defaults to Home:

| Screen prefix | Active tab |
|---|---|
| `Chats /` | Chats |
| `Trips /` | Trips |
| `Profile /`, `Wallet /` | Profile |
| everything else | Home |

Active = `surface/glass-clear` pill + `line/glass-edge` stroke + `text/gold`
(pure white `icon/on-brand` in dark, RULE B4). Inactive = `text/ink-soft`, **opacity 1**.

Inactive tabs previously carried a 0.55 paint opacity, which made Home read lighter than
Chats and Trips on the same bar. Every tab is now opacity 1 at every level —
tab, slot, instance, vector and fill.

## S. Decisions 2026-09-17 (session 1 close)

1. **Registration is 4 steps**: ID scan -> licence scan -> selfie -> details.
   The 2-step version in `07` (details, then all documents together) is SUPERSEDED.
   One capture per screen: clearer progress, and a failed scan retries only that step.
2. **Two sign-up paths only: MyGov and custom.** Google is REMOVED from the rebuild.
   If a third-party login is ever added, App Store guidelines require Sign in with Apple
   alongside it — so the cheaper route is Apple, not Google.
3. **SwiftUI is written in parallel** with the Figma work.
4. **Everything remaining is in scope**: host earnings/payout/calendar, auth flow,
   reviews/cancellation/damage, error and empty states.

## T. Interaction states (from Emin's reference, 2026-09-17)

A tile does one of two things when tapped, and which one depends on the content:

| Content | Presentation |
|---|---|
| A small set of exclusive or toggleable choices | **Native iOS menu** anchored to the tile |
| Richer content with its own actions | **Bottom sheet** |

### Menu
~232 wide, radius 22, `surface/card` at 97%, drop shadow y+10 blur 30 spread -4.
Rows are 18pt leading tick slot + Body label, 11pt vertical padding.
A checkmark marks the current choice; unchecked rows keep the empty slot so labels align.

Language: System / Azərbaycan / Русский / English — single choice.
Appearance: Dark / Light / System (auto) — single choice.
Notifications: Push notifications / Trip updates / Email — MULTI select, several ticks at once.

### Sheet
Scrim `surface/scrim` (black 28% light, 45% dark), sheet with 30pt top corners,
40x5 grab handle, centred title. A `Done` capsule top-right when the sheet has no
other dismissal. **The sheet covers the tab bar** — the bar is removed, not layered under.
Motion: `Theme.sheet`, 400ms, move in from bottom.

### Sign out and Delete account live in the Help sheet
Both in `status/danger`, grouped separately from the contact rows.
This satisfies Apple's in-app account deletion requirement.

### Wallet sheet
BALANCE caption + `Type/Money large` + a `brand/tint` Top up button.
"This month" shows spend and earn side by side.
Activity is a **2-column card grid**, not list rows — bento again.

## U. BENTO IS THE LAYOUT LAW (2026-09-17)

**Bento is the default for every screen.** Cards on a background, never a grouped list with
dividers. This is the single most recognisable thing about the app and it is not negotiable.

### The test: does tapping it go somewhere?

| Content | Form | Why |
|---|---|---|
| **Navigation destination** — tapping opens another screen | **Bento tile** | The reason bento exists. Never a row with a chevron. |
| **Repeating record** — a trip, a car, a listing, a message, a notification, a transaction | **Separate full-width card**, or a 2-column card grid when the text is short | Each record is its own object with its own shadow. Never one card with dividers inside. |
| **Label → value data** — "Daily rate  ₼380", "ID number  AZE ***42" | **Rows INSIDE one card** | These are tabular. Tapping does nothing. A row is correct here. |
| **Actions inside a sheet** — "Email support", "Sign out" | **Rows inside one card** | Emin's own Help sheet does this, and iOS sheets conventionally do. |

**The anti-pattern: a row with a chevron.** If it has a chevron it navigates, and if it
navigates it is a tile. Convert it.

### Tile geometry
Half 176 x 172, full 366 x 172, radius 26, `surface/card`, shadow black 6% y+6 blur 18.
Badge 56 at the top, title and supporting line pinned to the bottom with a FILL spacer.
Two per row with `space/gap` 14.

### Card grid geometry
Two columns for short text (Wallet activity), one column full width for long text
(notifications, trips, listings, threads). `space/gap` 14 between cards, each with its own shadow.

### Screens audited 2026-09-17
Correct already: Home, Profile / Settings, Cars near you, My listed cars, My trips,
Chats / Messages, Wallet / Balance, Wallet sheet.
Data rows, correctly NOT bento: MyGov success, Register / Review, Trip detail, Booking request,
Trip summary, Golf / Booking, Become a host, Booking confirmed, Date picker, EV / Payment.
**Converted:** EV / Vehicle detail.
(Profile / Help and Profile / All notifications were converted, then removed entirely — see RULES.md V.)

## V. Information architecture (Emin, 2026-09-17)

**One support chat for all.** There is no Help screen. "Help" opens the single support
conversation. The Help SHEET stays — it holds contact options plus Sign out and Delete account —
but a separate Help destination does not exist.

**Notifications live on Home, not Profile.** Profile holds only their *settings*
(the Notifications menu: Push / Trip updates / Email). The notification feed itself is a
section of the Home screen.

**The notification icon does not navigate.** Tapping it **scrolls Home down** to the
Notifications section. It is a scroll anchor, not a link. In SwiftUI:
`ScrollViewReader` + `proxy.scrollTo(.notifications, anchor: .top)` on `Theme.smooth`,
with a `click` haptic.

This matters for the prototype: wire it as a scroll-to, never as a navigate.

### Consequence
`Profile / Help` and `Profile / All notifications` were built and then REMOVED.
Both duplicated somewhere the information already lived.

## W. Bound paints must carry a matching base colour (2026-09-18)

`setBoundVariableForPaint` keeps the paint's BASE colour as a fallback. Wherever the binding
does not fully resolve — cloned subtrees are one case — the base is what renders.

This produced two opposite bugs in one session:
- Base black -> an active tab pill rendered as a solid **black** rectangle
- Base white -> review stars rendered **white on cream**, effectively invisible

A blanket base colour cannot fix this. **The base must equal the token's own value.**

```js
const val = variable.valuesByMode[lightModeId];        // the token's real colour
let p = { type:'SOLID', color:{ r:val.r, g:val.g, b:val.b } };
p = figma.variables.setBoundVariableForPaint(p, 'color', variable);
```

Verifier rule `tokens/base-mismatch` now flags any bound paint whose base differs from its
token by more than 2%. A one-off repair across the file corrected **368 nodes**, so this was
latent almost everywhere, not only where it happened to be visible.

## X. Empty and error states (2026-09-18)

Every state screen answers three questions in this order: **what happened, what it cost you,
and what to do next.** If a screen cannot answer all three it is not finished.

### The pattern

One centred block, never a list, never a bento grid — there is nothing to navigate to:

```
Nav bar (the screen's own title, unchanged — the user has not left)
[ flexible space ]
Icon badge  88pt circle, surface/card, glyph 52pt (~60%)
20pt
Title       Type/Title 3, text/ink, centred, 300pt wide
8pt
Body        Type/Subheadline, text/ink-soft, centred, 300pt wide
24pt
Action      one button, 300x50
[ flexible space, 96pt bottom padding for the tab bar ]
```

### Glyph colour carries the meaning

| State | Glyph token | Meaning |
|---|---|---|
| Empty | `brand/amber` | Nothing here **yet**. This is normal and expected. |
| Error | `status/danger` | Something **failed**. Red is earned, never decorative. |

A permission that is merely off (location, notifications) is **empty, not error** — the user
made a choice and can unmake it. Reserve red for failure.

### One way forward

Exactly one button. Two buttons make the user choose before they understand what happened.
The button is **Primary** whenever the action is the obvious next move, including on errors
("Try again", "Use another card"). Secondary is only for a state where doing nothing is a
reasonable option ("Clear filters" — the results are legitimately empty).

### The body copy rules

1. **Say what it cost.** "Nothing was taken and the car is held for 10 more minutes" is the
   whole message. "An error occurred" is not.
2. **Never blame the user.** "That didn't work on our side, not yours."
3. **Give a real number when one exists.** "34 cars are available nearby this week" turns a
   dead end into a hint.
4. **Keep the nav title.** The user has not navigated anywhere; replacing the title with
   "Error" loses their place.

### Tab bar

State screens keep the tab bar, selected for the context the user was in — Home for a
checkout failure, Profile for the wallet, Chats for messages. The state is a condition of
the current screen, not a new destination.

## Y. One flow in, and the bottom inset (2026-09-19)

### One way in, not three

Emin: *"remove AUTH, ONBOARDING, REGISTRATION, and create one simple flow all in one."*

Three lanes had accumulated covering the same ground — 32 screens for "make an account",
including two separate MyGov handoffs and two separate welcome screens. They were replaced
by `START`: **five screens**.

```
Welcome ──[Continue with MyGov]──> Identity ──> Ready
   ├──────[Use phone number]─────> Phone ──> Code ──> Identity ──> Ready
   └──────[Browse without an account]───────> Home
```

**The rule:** there is exactly one entry flow. A screen that lets someone in belongs in
`START` or it does not exist. If a new sign-in idea needs a screen, it replaces one of the
five — it does not open a second lane.

What survived from the 32, because it was genuinely better:

- MyGov vs documents as **two bento tiles**, not a list (RULE U)
- the promise that browsing needs nothing, repeated on every screen that could feel like a wall
- "You can browse cars and prices while you wait" on the pending screen

What did not survive: passwords (the code replaces them), a separate splash, a separate sign-in,
the four-step scan wizard as part of the entry flow. Document capture is now behind the
**Scan documents** tile, reached only by someone who has chosen it. The archived copy for all
32 screens is in `SPEC/_ARCHIVED-registration-flows.md`, including the viewfinder and
step-indicator patterns, which are worth rebuilding if document capture returns.

### The bottom inset — 34, not 24

A screen **with** a tab bar ends with `spacer-96` (or >= 96 bottom padding). RULE B8.

A screen **without** a tab bar ends with **`spacer-34`** — the home indicator. Anything less
and the last line of fine print sits under the indicator on a real device. The first build of
`Start / Welcome` used 24 and the caption crowded the bottom edge; the verifier reported no
overflow because there was none. Measure against the *device*, not against the frame.

