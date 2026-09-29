# Agent handoff — continue building Rentbutik

Written for the next AI agent picking this up. Read this file top to bottom
before touching anything. Everything here was learned by doing it; where a
mistake was made, it is recorded so you do not repeat it.

---

## Start here: the live task queue

`git pull origin main`, then open **`design/XCODE-TASKS.md`**. It is the ordered work queue kept by the
review session (Claude Code on the web, with Figma access), audited against Figma `Ereat5qYENeSKTvW473gn5`.
Phase 1 (clean code and logic), then Phase 2 (every Figma screen), before any new feature. Pull again before
each task: new tasks and re-opened boxes arrive between your pushes. Screen images: `design/figma-ref/`.
Every tap's motion, haptic and destination: `design/FIGMA-HANDOFF-NOTES.md`.

---

## 0a. Before anything: you will not be given a Figma token

If you find yourself about to ask Emin for a Figma personal access token, stop and read
`design/FIGMA-ACCESS.md`. The short version: **never ask for one**, it is a standing
instruction from day one of this project, and **you do not need Figma access to build** —
the contract is written down in this directory. If your harness can host an MCP server,
`claude mcp login figma` is the supported path and no token is typed anywhere.

---

## 0. The prompt to paste

> You are continuing an in-progress iOS app build. Read
> `design/AGENT-HANDOFF.md` first, in full, then `design/RULES.md`,
> `design/HOME-SPEC.md` and `design/GAPS.md`.
>
> The app is Rentbutik, a vehicle rental app for Baku. It is built in SwiftUI
> against a Figma file that is the design contract. The Figma file is the
> source of truth for every screen — never build a screen from memory, a
> description, or a screenshot someone pasted. Read the Figma node first.
>
> Work one screen at a time using the loop in section 3 of the handoff. After
> each screen: build, render, and LOOK at the result before moving on. Never
> mark a screen done without seeing it.
>
> Start at the top of the queue in section 8. Do not re-order it, do not skip
> ahead, and do not start a phase while an earlier one has unchecked items.
> Tell me what you changed and what you could not verify.

---

## 1. What this project is

| | |
|---|---|
| App | Rentbutik — car, EV and golf-cart rental in Baku, Azerbaijan |
| Repo | `git@github.com:Emin-dev/figma.git`, branch `main` |
| Xcode project | `/Users/mac/Documents/Rentbutik/Rentbutik.xcodeproj` |
| Target | iOS 27.0 minimum, iPhone only |
| Owner | Emin (`@Emin-dev`) |

The design work came first and is extensive: 67 screens across 14 lanes in
Figma, plus a written rule set in `design/`. The app is being built to match
it. **The design is not a suggestion — it is a contract**, and `RULES.md`
calls its rules "non-negotiable" because several were learned from bugs that
actually shipped.

---

## 2. Environment facts

These are verified, not assumed. Getting any of them wrong wastes a session.

### Figma

| Fact | Value |
|---|---|
| File key | `pNlCu0GHsvsJ2Uxb2DLghP` |
| Live page | `iOS 27 · SCHEME V3` = node `4007:6935` |
| Seat | Full, tier `pro` — 200 calls/day, 10/min |
| Other pages | `01 · Cover`, `04 · Screens`, `05 · Prototype`, `06 - UX Flows`, `07 - Scheme`, `08 - Archived Scheme V1` |

- **Only build from `iOS 27 · SCHEME V3`.** `07 - Scheme` is the old shipping
  design and contains known defects (see section 6). `08` is archived.
- `whoami` is the only rate-limit-exempt call. Use it to check budget.
- `get_metadata` **under-reports pages**. To enumerate pages use
  `use_figma` with `return figma.root.children.map(p => p.name)`.
- You **must** load the `/figma-use` skill before every `use_figma` call.
- You **must** load `/figma-design-to-code` before every `get_design_context`.

### Claude Code config

The Figma MCP token lives in the **Xcode agent config directory**, not
`~/.claude`. If Figma tools are missing, this is why:

```bash
CLAUDE_CONFIG_DIR="/Users/mac/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig" \
  claude mcp login plugin:figma:figma
```

Must be run from a real terminal (needs a TTY), then restart the session —
MCP tools bind at session start.

### Device and git

- Run destination is **`Emin's 15 Pro Max`** over SSH-authenticated git.
  Keep it. Do not switch to a simulator without saying so.
- Device interaction sessions (`DeviceInteraction*`) are **simulator-only**.
  You cannot drive taps on the physical phone. Use `RenderPreview` to see
  screens, and ask Emin to confirm interactions.
- Git remote is **SSH**: `git@github.com:Emin-dev/figma.git`. Do **not** add an
  HTTPS remote and do **not** install `gh` — SSH is already authenticated.
- `origin/claude/figma-mcp-setup-793ffv` is an **unrelated history** (the
  original design repo). Do not merge it without discussing; `main` is the app.

---

## 3. The method — the loop that actually works

This is the single most important section. Four screens were built from
documents alone early on and **every one of them was wrong** in ways that were
invisible until compared against Figma.

For each screen, in this order:

1. **Read the Figma node.** `get_screenshot` for layout, and `use_figma` to
   read the actual data when colour or text matters.
2. **Read the variable bindings, not the pixels.** Colours in a rendered
   thumbnail lie. Resolve `fills[0].boundVariables.color` to a variable name
   and map that to a `Theme` token.
3. **Build it** from the existing components. Check `Components/` first —
   do not write a new component when one exists.
4. **Build the project.** `BuildProject`.
5. **Render it.** `RenderPreview` on the screen's file, then actually read the
   image. Compare against the Figma screenshot side by side.
6. **Fix what differs**, then re-render. Only then move on.
7. **Run on device** (`RunProject`) at the end of a group of screens.

### Why step 2 is not optional

`RULES.md` records a vision-check note: at 0.5 scale gold glyphs read as
near-black, and an agent nearly "fixed" a non-existent bug. The reverse also
happened during this build — the selected filter chip on
`Renter / Cars near you` *looks* like white text on orange, which would break
RULE B1. The data says `text/on-gold` = RGB(20,22,26). Reading the data
prevented a wrong "fix".

### Useful read snippet

```js
// Resolve every text colour on a screen to its variable name.
const page = await figma.getNodeByIdAsync('4007:6935');
await figma.setCurrentPageAsync(page);
const screen = await figma.getNodeByIdAsync('<NODE_ID>');
const ids = new Set(); const rows = [];
for (const t of screen.findAllWithCriteria({ types: ['TEXT'] })) {
  const f = (t.fills || [])[0];
  const p = t.parent;
  const pf = (p && Array.isArray(p.fills)) ? p.fills[0] : null;
  const fv = f?.boundVariables?.color?.id ?? null;
  const pv = pf?.boundVariables?.color?.id ?? null;
  if (fv) ids.add(fv); if (pv) ids.add(pv);
  rows.push({ chars: t.characters.slice(0,40), textVar: fv,
              parent: p?.name, parentVar: pv });
}
const names = {};
for (const id of ids) {
  const v = await figma.variables.getVariableByIdAsync(id);
  if (v) names[id] = v.name;
}
return rows.map(r => ({ ...r, textVar: names[r.textVar] || r.textVar,
                             parentVar: names[r.parentVar] || r.parentVar }));
```

---

## 4. Design rules — non-negotiable

Full text in `design/RULES.md`. These are the ones that bite. Rule letters
match that file so you can look them up.

### Learned from shipped bugs — never relitigate

- **B1. Never white text on gold.** ~2:1 contrast. Content on any gold fill is
  `text/on-gold` `#14161A`, in **both** modes. Icons on *bronze* may be white
  (3:1 threshold for glyphs); text never.
- **B2. Photo cards are OPAQUE, never glass.** Glass ignores `clipShape` and
  leaks the image past rounded corners.
- **B3. Chip text renders directly on the surface.** Never a filled shape
  inside a `.background` under glass — it rasterises and blurs the text.
- **B4. Tab bar tint:** pure white in dark, `#B4640A` in light. White is
  invisible on the light glass bar.
- **B6. Only the chat thread hides the tab bar.** Hiding it inside a sheet
  leaks to the presenting tab; the bar vanishes for 2–3s on return.
- **B7. One button height app-wide: 50. One shape: capsule.** Labels never
  wrap — they scale to 70% and stop. If it still does not fit, shorten the
  copy. Never grow the button.
- **B9. Map backdrops are STATIC.** An animated blurred map caused real device
  stutter.
- **B11. Never size a control to fit the English string.** Check Azerbaijani,
  which runs longest.
- **B12. Figma cannot render Liquid Glass.** Judge glass on device only. Do not
  tune it from a simulator render.

### Geometry (C)

Radius: card 30, tile 26, chip 18. Gap 14. Screen padding 18.
Button 50, circular icon button 44, **in-card action capsule 38**.
Status dot 7, photo colour strip 4. Tile 176×172 half, 366×172 full.

### Layout language (Q, U) — bento is law

One test: **does tapping it go somewhere?**

| Content | Form |
|---|---|
| Navigation destination | **Tile.** Never a row with a chevron |
| Repeating record (trip, car, listing, message) | **Separate full-width card**, own shadow |
| Label → value data | **Rows inside ONE card** |
| Actions inside a sheet | Rows inside one card |

A row with a chevron is the anti-pattern. Sheets are exempt.

### Information architecture (V)

- **One support chat for all.** There is no Help *destination*. The Help
  *sheet* holds contact options plus Sign out and Delete account.
- **Notifications live on Home**, not Profile. Profile holds only their settings.
- **The notification icon does not navigate.** It scrolls Home to the
  Notifications section — `ScrollViewReader` + `scrollTo` on `Theme.smooth`.

### Other decisions already made — do not reopen

- **S1.** Registration is **4 steps**: ID scan → licence scan → selfie →
  details. The 2-step version on page `07` is superseded.
- **S2.** Two sign-up paths only: **MyGov and email. Google is removed.**
  MyGov returns identity *and* licence, so it verifies in one hop.
- **K.** Browse-first. App opens on Home, no wall. Account at the first
  meaningful action; identity verified before the first *ride*, not before
  browsing. "Continue without an account" is prominent, not buried.
- **F.** Trip status vocabulary is fixed and exhaustive: `waitingForHost`,
  `upcoming`, `ongoing`, `completed`, `declined`, `cancelled`. Shown three
  ways: 4pt strip on the photo, 7pt dot, chip. Honey = riding now,
  gold = new/upcoming.
- **Renter is a list, EV and Golf are maps.** Daily rental is a comparison
  task; short-term pickup is a location task.

### Motion (D) and haptics (E)

Three curves carry the app: `Theme.smooth` (0.45), `Theme.snappy` (0.32, **the
default**), `Theme.bouncy`.

Haptics: one-shot only, nothing loops, **nothing fires on scroll**.
`tick` `click` `open` `grab` `gain` `celebrate` `ignition` `warn` `error`.
`celebrate` fires **only** on a confirmed booking. `ignition` only when a
keyless ride actually starts.

---

## 5. Swift and SwiftUI rules for this codebase

Decisions Emin made explicitly. Follow them.

- **Apple-native patterns only.** No custom controls where iOS has one. The
  tab bar is the **native** `TabView` with `Tab(_:systemImage:value:)`,
  `.tint(Theme.goldText)` and **`.tabBarMinimizeBehavior(.never)`** — Emin
  wants it always full size. `SegmentedControl` is the one justified custom
  control, because `Picker(.segmented)` cannot carry the brand pill.
- **SF Symbols only. No custom icons, ever.**
- **Haptics:** native `.sensoryFeedback` for the six one-shot feels via
  `Haptic.sensory`; the three sequenced feels (`celebrate`, `gain`,
  `ignition`) stay on `Haptic.fire()` because `SensoryFeedback` is one shot per
  trigger. Every button gets its feel from `PressScale(haptic:)` — a button
  physically cannot forget it.
- **SF Symbol animation:** `.symbolEffect(.bounce, value:)` on every tappable
  symbol, fired alongside the haptic.
- **Typography:** `Theme.Font` maps onto Dynamic Type **text styles**, not
  fixed point sizes. Heights are `minHeight` so controls grow instead of
  clipping. Do not reintroduce `.system(size:)` for body text.
- **Localisation:** view-facing text params are `LocalizedStringKey`;
  non-view types carrying user text use `LocalizedStringResource`. A `String`
  passed to `Text` does **not** localise. Three languages are planned
  (en/az/ru), so this matters.
- **Data flow:** `@Observable` models (not `ObservableObject`). Never filter or
  sort inside `ForEach` — cache the derived collection with `didSet`. Use
  KeyPath bindings (`$model.field` via `@Bindable`), never closure bindings.
  Pass views only the fields they read.
- **View structure:** one `View` struct per section, not `private var`
  computed properties — a computed property shares the parent's invalidation
  boundary and saves nothing.
- **Money:** always `.currency(code: Currency.code)` (= `"AZN"`, ₼ manat).
  Never hardcode a currency symbol.
- `public` is pointless in this app target. Two build failures came from
  `public` inits referencing internal types.

---

## 6. Mistakes already made — do not repeat these

Each of these actually happened during this build.

1. **Built four screens from docs instead of Figma.** Home had the wrong Host
   glyph (`house.fill`, actually `key.fill`), a nav-bar title instead of an
   inline header, and no "See all". `Renter / Cars near you` had invented
   filter labels, the wrong chip colours, and the wrong card layout. **Read
   the node first.**
2. **Exported photos with Figma's UI baked in.** `contentsOnly: true` excludes
   overlapping *siblings*, not *children*, so price badges came along and the
   news cards read "Premium" and "0 /day". **Fix:** create a temp off-canvas
   frame of plain rectangles carrying only the image fills, export those, then
   delete the temp frame and verify it is gone.
3. **Grabbed the wrong logo twice.** The file has three marks: Welcome
   (72×72, gold gradient + dark key — **the real one**), Splash (96×96,
   inverted for the gold background), and Home / Light (32×32, `brand/solid`
   with **no key at all** — a design inconsistency). Use the Welcome mark.
4. **Seeded a live timer with a fixed past date.** Home's elapsed time read
   `738:56:32`. Anything feeding `Text(_, style: .timer)` must be seeded
   relative to `.now`.
5. **Assumed a subtitle was a host name.** `Sahil · 4 seats · Automatic` —
   `Sahil`, `Nizami`, `Yasamal` are **Baku districts**, not people.
6. **Trusted `HOME-SPEC.md` over later documents.** Authority order is
   **`RULES.md` > `SCREENS.md` > `BUILD-LOG.md` > `HOME-SPEC.md`**. HOME-SPEC
   says Host goes last and tiles are 150 tall; both were later overridden
   (Host leads, tiles are 172).
7. **Assigned photos by position instead of looking.** `bmwX5` may be the
   wrong vehicle. `BUILD-LOG.md` already warns about this. **Open, unresolved
   — ask Emin which photo belongs to which vehicle.**

### Known content defects in the OLD design (page `07`) — do not copy

- Currency is **₦ naira** in two places; everything must be **₼ manat**.
- Foreign addresses: "Midland Road, London NW1", "700 Atlantic Ave, Boston".
- Turkish placeholder names "Elif", "Yılmaz" on Sign In.
- User named "Nazila" on verification, "Emin" everywhere else.
- A third sign-up method (Google) that RULE S2 removed.

---

## 7. Per-screen checklist

Do not mark a screen done until every box is true. Adapted from
`design/CHECKLIST.md` for code.

**Fidelity**
- [ ] Figma node was read before building — screenshot AND variable data
- [ ] Every colour is a `Theme` token; no raw hex, no `.gray`, no `.orange`
- [ ] Every font is from `Theme.Font`; no `.system(size:)` for text
- [ ] Copy matches the file exactly, including separators and spacing
      (e.g. `₼380 /day` has a space before the slash)
- [ ] Icons are SF Symbols and match the names in the file

**Rules**
- [ ] No white text on any gold fill (B1)
- [ ] Photo areas opaque, never glass (B2)
- [ ] Buttons 50 tall and capsule; in-card actions 38 (B7, C)
- [ ] Tab bar visible unless this is the chat thread (B6)
- [ ] Navigation destinations are tiles, not chevron rows (U)
- [ ] Repeating records are separate cards with their own shadow (U)
- [ ] Label→value data is rows inside one card (U)

**Code**
- [ ] Reused existing components; no duplicate component created
- [ ] Each section is its own `View` struct with narrow inputs
- [ ] Text params are `LocalizedStringKey` / `LocalizedStringResource`
- [ ] No filtering or sorting inside `ForEach`
- [ ] `ForEach` ids are stable and cheap, never array indices
- [ ] Money via `.currency(code: Currency.code)`
- [ ] Every tappable thing has a haptic via `PressScale(haptic:)`
- [ ] Tappable symbols have `.symbolEffect(.bounce, value:)`
- [ ] No `public` on anything

**Verification**
- [ ] `BuildProject` passes with zero errors
- [ ] `RenderPreview` was run **and the image was actually looked at**
- [ ] Compared against the Figma screenshot; differences fixed or recorded
- [ ] Checked at a large Dynamic Type size for clipping
- [ ] Anything unverifiable (device-only interactions) stated explicitly

---

## 8. Build queue

`design/BUILD-PLAN.md` has the phase rationale. This is the ordered work.

### Done — 26 of 55 screens

Shell (router, store, session, native tab bar) · Home · Renter list ·
Car detail · Trips + Trip detail · Chats + Thread · Profile + Help sheet +
Wallet sheet · Auth welcome / sign up / sign in / verification pending ·
design system (Tile, Badge, Chip, Buttons, Input, SegmentedControl, CarCard,
PhotoFill, TripStatusChip)

### Next — in this order

**1. Onboarding — 9 screens.** The biggest hole; nobody can complete signup.
| Screen | Node |
|---|---|
| Register / Choose method | `4024:16` |
| Register / MyGov handoff | `4036:53` |
| Register / MyGov success | `4036:79` |
| Register / MyGov failure | `4036:118` |
| Register / ID scan | `4037:55` |
| Register / Licence scan | `4037:81` |
| Register / Selfie | `4037:107` |
| Register / Details | `4037:133` |
| Register / Review | `4037:174` |

Selfie step must use `faceid`, not `person.crop.circle.fill` — an open TODO
in `BUILD-LOG.md`.

**2. Renter completion — 2 screens.**
`Renter / Date picker` `4075:342` · `Renter / Booking confirmed` `4075:306`
(the only `celebrate` moment).

**3. Host — 7 screens.** `GAPS.md` calls Booking request the single largest
gap: `waitingForHost` and `declined` are meaningless without it.
| Screen | Node |
|---|---|
| Host / Become a host | `4035:42` |
| Host / My listed cars | `4038:67` |
| Host / List your car | `4038:164` |
| Host / Booking request | `4075:169` |
| Host / Earnings | `4101:267` |
| Host / Payout | `4101:345` |
| Host / Availability | `4101:406` |

**4. EV — 6 screens.** Full-bleed static map (B9, P). Swipe-to-start lives
**inside** the vehicle card, never on its own screen. `ignition` fires only on
real start. Pre-trip capture slots use `camera.fill`, not `bolt.fill`.
| Screen | Node |
|---|---|
| EV / Unlock | `4043:85` |
| EV / Vehicle detail | `4043:131` |
| EV / Payment | `4043:186` |
| EV / Pre-trip photos | `4043:223` |
| EV / Active trip | `4043:264` |
| EV / Trip summary | `4075:243` |

**5. Golf — 2 screens.** `Golf / Map` `4052:245` · `Golf / Booking` `4052:289`.
"SeaBreeze · 6 carts available" is location-gated, not a pricing line.

**6. Verify already-built screens against Figma.** Several were built before
the read-first loop was adopted: Trip detail `4051:198`,
Chats Messages `4051:264`, Thread `4051:332`, Profile Settings `4090:254`,
Wallet Balance `4052:135`, Top up `4052:213`, and the Profile menus
`4093:246` / `4093:334` / `4093:419`, Help sheet `4094:259`,
Wallet sheet `4094:380`.

**7. Dark mode.** 8 reference screens exist: `4071:126` `4071:182` `4071:388`
`4071:473` `4071:503` `4071:576` `4084:189` `4084:244`. Every token already
has a dark value, so most of this is auditing, not rebuilding. Maps do **not**
flip with modes — `bakuMap` needs a dark counterpart.

**8. Localisation.** en / az / ru, transcreated. Audit every control against
Azerbaijani (B11). A String Catalog does not exist yet — create one.

**9. Production hardening.** Error states (no network, payment declined,
booking failed), empty states, loading states, permission priming,
cancellation/refunds, reviews. See `GAPS.md` section C.

### Known blockers, not screens

- **No backend.** `Store` is in-memory; nothing survives a relaunch.
- **Photo identity unconfirmed** (mistake 7 above).
- **Only 5 photos + 1 map exported.** More vehicles need images.
- **App icon** is still the template placeholder.

---

## 9. Git

```bash
# SSH only. Never add an HTTPS remote. Never install gh.
git remote -v          # origin  git@github.com:Emin-dev/figma.git
git add -A && git commit && git push origin main
```

Commit per coherent group of screens, not per file. End commit messages with:

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

Do not force-push. Do not touch `origin/claude/figma-mcp-setup-793ffv` — it is
an unrelated history holding the original design repo.

