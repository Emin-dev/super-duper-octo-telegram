# Current state

**Last updated:** 2026-09-18 (verified live against Figma)

**Live counts:** 13 lanes, **57 screens**, all passing `tools/verify.js`.
(2026-09-19: three registration lanes, 32 screens, replaced by `START`, 5 screens.)
Build page is `iOS 27 · SCHEME V3` (`4007:6935`) — older notes below still call it `NEW`.

**Read `BUILD-LOG.md` first — it has node IDs, the build recipe and the queue.**

## Done

- Figma MCP server installed and authenticated (Emin / eminpromax@icloud.com)
- Write access verified empirically on file `pNlCu0GHsvsJ2Uxb2DLghP`
- Full six-page audit complete; findings recorded in PLAN.md
- Confirmed iPhone 18 Pro = 402x874 pt
- Confirmed SF Pro / SF Pro Rounded / SF Compact available in-file

## BLOCKER: SF Pro does not render here

Re-probed 2026-09-18 — **still blocked.** The file now has SF Pro text styles, which makes it
look fixed; it is not. `SF Pro Display` and `SF Pro Text` do not exist as loadable families,
and `SF Pro` loads but yields zero glyph metrics.

Verified by probe on 2026-09-17, repeated 2026-09-18:

| Font | Result |
|---|---|
| Inter Regular/Bold | w=244/255, h=41 — renders |
| Roboto Regular | w=233, h=40 — renders |
| **SF Pro Bold/Regular** | **w=0, h=15 — DOES NOT RENDER** |
| SF Pro Display / SF Pro Text | family does not exist here |

`loadFontAsync` succeeds silently then yields zero glyph metrics. SF Pro is installed on Emin's
Mac (so Figma lists it) but the server-side renderer executing `use_figma` has no font data.

The file's OWN text styles reference `SF Pro Display` and `SF Pro Text` — Apple's pre-2020 names,
which do not resolve here at all.

**Decision:** build on Inter (metrically close, verified). EVERY text node uses a `Type/*` text
style. At handoff, switching those 8 styles to SF Pro flips the whole file in one pass.
Zero rework, and layout self-corrects because everything hugs or fills.

## In progress — Phase 0 (foundations)

Done (all saved in the file, survives the rate limit):
- Created `Theme` collection (`VariableCollectionId:4006:2`) — 29 variables
  - 16 colour tokens, correctly named (`text/ink`, not `text/ink-light`)
  - 13 numeric tokens (radius, space, size)
- Created 3 effect styles: `glassPanel`, `mapGlass`, `backdropMap` (file previously had zero)
- Created `Theme Dark` collection (`VariableCollectionId:4009:2`) — 7 tokens, free-tier dark mode
- Legacy `Rentbutik` collection left untouched — still bound across ~24k legacy nodes

BLOCKED:
- **Dark mode cannot be built.** Figma Starter limits collections to ONE mode.
  Error verbatim: `Error: in addMode: Limited to 1 modes only`
  Multi-mode variables require Figma Professional. This is why the previous designer
  built dark mode as duplicated frames.
- Workaround in force: correct token NAMES exist now with Light values; each dark value is
  recorded in the variable `description`. Post-upgrade, adding the Dark mode is mechanical,
  with zero rework.

## Built on page NEW (`4007:6935`)

- `Home / Light` (`4013:3`) — 402x874, scrollable, content 1290 tall
  - Header (app mark + wordmark), Welcome block
  - 2x2 module grid at 176x150 — Renter, Electric car, Golf car, Host
  - News carousel, 280-wide cards, opaque label areas
  - Notifications list, 4 rows, unread dot
  - Floating glass tab bar with `glassPanel` effect + 96pt clearance
- `Type/*` text styles x8 (Inter, documented for SF Pro swap)
- All fills bound to `Theme` variables — no raw hex

## Decided 2026-09-17

1. **Canvas** — 402x874 primary (iPhone 18 Pro), verified at 440x956 (Pro Max)
2. **Registration** — two paths: MyGov one-tap, and custom password + driving licence. See RULES.md I
3. **Deliverable** — Figma AND SwiftUI code. Emin runs it on device to see real Liquid Glass
4. **Target OS** — iOS 27 (released 2026-09-14), maximum Liquid Glass. See RULES.md G

## Resolved 2026-09-17 (late)

- **iOS and iPadOS 27 library IS subscribed to the file.** Emin was right; an earlier claim that
  only the 26 kit existed was wrong.
  Key: `lk-3167e7e1386e96621fc3b20782e2ec1b199754eeceff2ef04bf90d28a124be6414b67982dc8fb71ea1896b0310c316f54d7b9f0ac598cb3111748728c039a567`
  Also subscribed: iOS/iPadOS 26, macOS 26 + 27, watchOS 26, visionOS 26, Simple Design System.
- **MyGov returns ALL data in one click**, including licence. So Path A needs NO separate licence
  step. Path B (custom) scans everything ourselves.
- **SF Symbols are not indexed as components** in the iOS 27 library (search returned empty).
  Unfinished: confirm how symbols are exposed. Retry when budget allows.

## Open question for Emin

1. **Figma Professional upgrade** ($16/seat/mo). Now needed for TWO independent reasons:
   (a) dark mode as a variable mode, (b) the 20-call/month ceiling that just stopped all work.

## Assumptions in force (correct me if wrong)

- Build in English first; az/ru applied in Phase 8
- Prototype wiring covers the flows built so far, not the legacy pages
- `07` and `08` are never edited

## Tool-call budget — CORRECTED 2026-09-17

**`use_figma` is NOT exempt.** An earlier assumption that write tools escaped the limit was wrong.
Every MCP call counts: get_metadata, get_libraries, search_design_system AND use_figma.

**The full 20-call monthly Starter budget was exhausted in ONE session** doing foundations only.
Verbatim: `You've reached the Figma MCP tool call limit on the Starter plan.`

Conclusion: 20 calls/month cannot support this project. Figma work is blocked until either
the monthly reset or an upgrade to Professional (200/day, 10/min).

Budget discipline for next session: plan the entire batch of Figma operations on paper FIRST,
then execute in as few `use_figma` calls as possible. Each call should do ~10 logical operations,
not one.

