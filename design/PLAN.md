# Rentbutik iOS — Rebuild Plan

Multi-week. Order matters: foundations bind everything above them, so nothing skips Phase 0.

## Audit findings (2026-09-17)

| # | Finding | Phase |
|---|---|---|
| 1 | `07 - Scheme` (12,451 nodes) and `08 - Archived Scheme V1` (12,317) are near-identical duplicates — half the file | 2 |
| 2 | Variables use separate `X-light`/`X-dark` tokens instead of one token with two modes. Root cause of manual dark mode | 0 |
| 3 | Cover's Dark mode + Localization sections are **14 empty frames** | 8 |
| 4 | Prototype page: 22 screens, **0 reactions**. "Wired prototype" is not wired | 7 |
| 5 | Frame sizes drift: 402x874, 440x956, 440x966, 390x844, 404x1008, 458x997 | 2 |
| 6 | Default names throughout 07: `Frame 23530`, `Vector 1-22`, `image 227-241`, `bg`, `ref`, `align` | 2 |
| 7 | 389 components + 51 sets on page 07 alone, duplicating the Cover's 13 | 2 |
| 8 | 26 paint styles duplicate the 23 colour variables — two sources of truth | 0 |
| 9 | 0 effect styles; the glass material is documented in prose only | 0 |

## Phase 0 — Foundations

Nothing else starts until this is done and signed off.

- [ ] Collapse the 7 `light`/`dark` variable pairs into single tokens with **Light + Dark modes**
      (`text/gold-on`, `text/ink`, `text/ink-soft`, `status/danger`, `surface/card`, `surface/glass`, `line/hairline`)
- [ ] Keep mode-invariant: `brand/*`, `text/ink-faint`, `text/on-gold`
- [ ] Add missing token groups: spacing, radius, size (from RULES.md section C)
- [ ] Create effect styles: `glassPanel`, `mapGlass` (blur 20, 55% fill, 1px inner white 40%)
- [ ] Verify the 10 text styles against the Foundations ramp; bind font tokens
- [ ] Retire the duplicate paint styles in favour of variables
- [ ] Delete the stray `Text title` STRING variable

## Phase 1 — Pilot: Home + Registration

The proof of approach. Emin reviews this before anything scales.

- [ ] Create page `NEW` (Emin may create it manually in the UI)
- [ ] Home screen @ 402x874, light + dark via mode switch
- [ ] Home: 4 module tiles + news + notifications
- [ ] Registration Path A — MyGov one-tap (returns ALL data incl. licence)
- [ ] Registration Path B — custom: ID scan, licence scan, selfie/liveness, manual details form
- [ ] Entry model: browse freely, account on first meaningful action, identity verified before first ride
- [ ] Every icon an SF Symbol; every control a native iOS pattern
- [ ] Components built as real variant sets, bound to Phase 0 tokens
- [ ] Wire the pilot as a clickable prototype
- [ ] **STOP. Review with Emin before Phase 2.**

## Phase 2 — Naming, sizing, placement

- [ ] Rename every screen to a real name; retire `Frame NNNNN` / `Vector N` / `bg` / `ref`
- [ ] Normalise every board to 402x874
- [ ] Group swimlanes into proper Sections: HOST / RENTER / EV / GOLF
- [ ] Align to a grid; consistent gutters between boards
- [ ] Deduplicate components to one source of truth
- [ ] Decide the fate of `08 - Archived Scheme V1` (version history already covers it)

## Phases 3-6 — Flows, in order

3. [ ] EV (EV001-008, variants V1/V2/V3 — most version sprawl)
4. [ ] GOLF (smallest lane, fastest end-to-end)
5. [ ] RENTER (browse, car detail, booking, reservation — core revenue path)
6. [ ] HOST (list a car, my listed cars, host overview)

Each flow repeats: rebuild screens -> bind tokens -> components -> dark mode -> wire prototype -> checklist.

## Phase 7 — Prototype

- [ ] Wire every flow end to end; no dead ends
- [ ] Apply the motion table from RULES.md section D
- [ ] Annotate haptics per interaction (RULES.md section E)

## Phase 8 — Dark mode + localization

- [ ] Verify every screen in both modes via mode switch, not duplicate frames
- [ ] Fill the 14 empty Cover placeholders, or delete them as stale
- [ ] Check every control against Azerbaijani (longest strings)

## Phase 9 — Handoff

- [ ] Component -> SwiftUI view name mapping table
- [ ] Token -> `Theme` property mapping
- [ ] Redline the motion + haptics spec

