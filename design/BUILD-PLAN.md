# Rentbutik iOS — build plan

Ordered, step-by-step. Each phase ends with a **runnable app** that is built, launched and
looked at on the iPhone 18 Pro simulator (402x874) before the next phase starts.

Authority order when two documents disagree: `RULES.md` > `SCREENS.md` > `BUILD-LOG.md`.

## Principles for this build

1. **Screen-first, not component-first.** Components are pulled in when a screen needs one,
   not built as a speculative library. Two were needed already (`Badge`, `Chip`); the rest
   (`ListRow`, `Input`, `NavBar`, `SegmentedControl`, `Toggle`, `CarCard`) arrive with their
   first screen.
2. **Real data, not lorem.** Every price, name and string comes from `SCREENS.md`. The app runs
   against an in-memory store shaped like the eventual API, so screens are wired, not static.
3. **Browse first.** App opens on Home. No auth wall. Account at the first meaningful action,
   identity verified before the first ride (RULE K).
4. **Verify by eye.** The Figma work found six defects that passed every automated check.
   After each phase: contrast on gold, clipping at Azerbaijani length, tab bar staying put,
   glass legibility over photos and maps.

---

## Phase 0 — Foundations ✅ DONE

- [x] Asset catalogue: 8 named colours, Light + Dark
- [x] `Theme.swift` — tokens, motion, type, `Haptic`
- [x] `Buttons`, `Tile`, `TripStatus` imported verbatim
- [x] `Badge` (RULES N ratios), `Chip` (RULE B3)
- [x] Built, run, verified on device

## Phase 1 — App shell

The step that turns this into an app. Nothing renders a screen until this exists.

- [ ] `AppRouter` — `@Observable`, one `NavigationStack` path per tab
- [ ] `RentbutikTabView` — Home / Chats / Trips / Profile
- [ ] Floating glass tab bar: `.clear` glass, active pill, `goldText` in light and pure white
      in dark (RULE B4). Inactive `inkSoft` at **opacity 1** (RULE R). Last child, so it stays
      in front while content scrolls under it (RULE O)
- [ ] `Store` — `@Observable` in-memory data seeded from `SCREENS.md`: vehicles, trips,
      threads, notifications, wallet, listings
- [ ] Domain models: `Vehicle`, `Trip`, `Listing`, `Thread`, `Message`, `Notification`,
      `Transaction`. `Identifiable` with stable ids, `Equatable`
- [ ] `Session` — signed-out / signed-in / verified, driving the browse-first gate

**Done when:** four tabs switch, the bar floats correctly over scrolling content, and the
store is readable from every tab.

## Phase 2 — Home

- [ ] 4 module tiles: Host, Renter, Electric car, Golf cart — in that order (RULE Q)
- [ ] News carousel, 280-wide cards, **opaque** label areas (RULE B2)
- [ ] Notifications section, full-width cards with unread dot
- [ ] Notification icon **scrolls** to the Notifications section — `ScrollViewReader` +
      `scrollTo` on `Theme.smooth` with a `click` haptic. It does not navigate (RULE V)
- [ ] `tabBarClearance` 96 bottom padding (RULE B8)

## Phase 3 — Renter flow

The money path. A list, not a map — daily rental is a comparison task.

- [ ] `CarCard` component — opaque photo, price pill, specs, rating
- [ ] Cars near you: search, date range, filter chips, result count, card list
- [ ] `Input` component (arrives here, for search)
- [ ] Filters sheet — "5 cars around Baku", Done / Clear
- [ ] Car detail — Mercedes-AMG GT ₼380/day, host, 4 seats, Automatic, Petrol, rating 4.8 (80)
- [ ] Date picker (named on the prototype, built nowhere — see `GAPS.md`)
- [ ] Booking confirmed — the **only** place `celebrate` fires

## Phase 4 — Auth + Onboarding

Triggered by the first meaningful action from Phase 3, not at launch.

- [ ] Splash (gold gradient), Welcome (Create account / Sign in / **Continue without an account**)
- [ ] Sign up — MyGov recommended + email. Google is dropped (RULE S2)
- [ ] Sign in — +994 phone, password, "Use MyGov instead"
- [ ] MyGov handoff / success / failure. Success returns identity **and** licence, so no
      separate licence step on this path
- [ ] Custom path, 4 steps: ID scan → Licence scan → Selfie → Details → Review
- [ ] Verification pending — does not trap the user; browsing continues

## Phase 5 — Trips

- [ ] My trips — Upcoming / Active / Past, using the existing `TripStatusChip`
- [ ] Status shown three ways: 4pt photo strip, 7pt dot, chip (RULE F)
- [ ] Trip detail — label → value rows inside one card (correctly not bento, RULE U)

## Phase 6 — EV

Full-bleed map — this is a location-first product (RULE P).

- [ ] Map canvas, 402x874, back-most, **static** backdrop (RULE B9)
- [ ] Unlock — vehicle card with battery ring and photo, swipe-to-start **inside the card**.
      `ignition` haptic only when the ride actually starts
- [ ] Vehicle detail — bento grid, 87% (380 km), Guidelines / Insurance / Reports / Fines
- [ ] Payment — Wallet / Card, Total Pay
- [ ] Pre-trip photos — capture slots use `camera.fill`
- [ ] Active trip — all controls in ONE bottom glass panel, nothing loose on the map
- [ ] Trip summary — duration, distance, paused time, charges, rating

## Phase 7 — Chats

- [ ] Messages list — one support conversation for all; there is no Help destination (RULE V)
- [ ] Thread — Hasan Nabiyev, Host • Tesla Model Y. **The only screen that hides the tab bar**
      (RULE B6)

## Phase 8 — Wallet + Profile

- [ ] Profile — 2x2 tile grid + full-width Wallet tile, **centred** nav title (RULE Q)
- [ ] Language / Appearance / Notifications — native menus; Notifications is multi-select (RULE T)
- [ ] Help sheet — contact rows, then Sign out / Delete account in `danger`
- [ ] Wallet balance + Top up — **₼ manat, not ₦ naira.** Activity is a 2-column card grid
- [ ] `gain` haptic when money arrives

## Phase 9 — Golf

- [ ] Map — "SeaBreeze · 6 carts available". Location-gated, not a pricing line
- [ ] Booking — ₼15/h

## Phase 10 — Host

- [ ] Become a host — ₼440/week, ₼1890/month, ₼22700/year
- [ ] My listed cars — Total Cars 4, Active 2, Est. Daily Income ₼525
- [ ] List your car — photos 1–5, make, model, year, seats, transmission, fuel, price, area
- [ ] **Booking request** — host-side approval. `GAPS.md` calls this the single biggest hole
      in the product; `waitingForHost` and `declined` are meaningless without it

## Phase 11 — Polish

- [ ] Dark mode pass over every screen
- [ ] Localisation en / az / ru, transcreated. Audit every control against Azerbaijani
- [ ] Fix the localization gap: `Buttons`/`Tile` take `String`, so labels never localize.
      Needs `LocalizedStringKey`; `TripStatus.label` needs `LocalizedStringResource`
- [ ] Dynamic Type — `Theme.Font` uses fixed point sizes today
- [ ] Error and empty states: no network, payment declined, no results
- [ ] Reviews, cancellation and refunds, damage report (not designed — build to RULES.md)

---

## Open discrepancies to settle

1. **Badge glyph ratio.** `Tile.swift` uses `badge * 0.5` = 28pt in a 56pt circle. RULES N
   specifies **34** and calls 0.5 "the real defect in the first attempt". `Badge.swift` follows
   RULES; `Tile.swift` still has the old ratio. One of them is wrong.
2. **Docs are a revision behind.** `BUILD-LOG.md` ends at 52 screens / 13 lanes; the handoff
   says 55 / 14 with a PROFILE lane.
3. **No physical device.** Real Liquid Glass can only be judged on hardware (RULE B12).

