# Missing screens — gap analysis

Read of all 57 screens on `07 - Scheme` plus the 22 named screens on `05 · Prototype`,
compared against the 29 light screens built on `NEW`.

## A. Content defects found in the existing design

These are wrong in the shipping design, not just missing.

| # | Defect | Where |
|---|---|---|
| 1 | **Currency is ₦ naira in TWO places**, not just top-up | `top-up-screen` 2152:10086 AND `wallet-ios27` 2169:16621 ("BALANCE ₦500", "This month ₦0") |
| 2 | **Foreign addresses** — "Midland Road, London NW1 2DB" and "700 Atlantic Ave, Boston, MA 02110" | `EV008` 2166:9895, `EV004` 2283:10580 |
| 3 | **Turkish placeholder names** — "Elif", "Yılmaz" | Sign In 2274:4523 |
| 4 | **User name inconsistent** — "Nazila" on the verification screen, "Emin" everywhere else | 2248:4510 |
| 5 | **A third sign-up method exists** — Google Account, alongside MyGov and Email | 2244:4842 |

Item 5 matters: Emin specified TWO paths (MyGov, custom). The existing design offers three.
Either Google is dropped, or the brief needs updating. **Needs a decision.**

Item 2 matters more than it looks — London and Boston addresses mean those screens were
built from a template and never localised to Baku.

## B. In the existing design, NOT yet rebuilt

### Auth (a whole flow I did not know existed)
- `0 splash` 2208:10187 — launch screen
- **Sign In / Sign Up chooser** 2209:7536 — includes **"Continue without sign-up"**, which is
  exactly the browse-first rule Emin chose
- **Sign Up methods** 2244:4842 — MyGov / Email / Google
- **Sign In** 2274:4523 — phone number + password
- **Email sign-up form** 2254:9952 — "STEP 1 OF 2 · PERSONAL DETAILS"
- **Upload Documents** 2208:10284 — "STEP 2 OF 2": ID front+back, licence front+back,
  selfie with licence, "Privacy protected"
- **Verification in progress** 2248:4510 — "Typically takes a few hours"

**Note the structure difference.** The existing flow is **2 steps** (details, then documents).
I built **4 steps** (ID, licence, selfie, details). Mine is more granular; theirs is fewer
screens. Worth deciding which is right before building more.

### EV
- **EV008 trip summary** 2166:9895 — duration, distance, usage time, time paused.
  The end-of-trip receipt. Significant omission.
- **EV004 change trip** 2283:10580 — edit dates, pickup/dropoff addresses
- **Pre-trip complete** 2285:10580 — "Exterior photos approved", "Liability Protection,
  Zero deductible"

### Other
- **My trips — empty state** 2168:15242 — "No trips yet / Find a car"
- **Golf cart near you** 2167:10243 — the golf equivalent of Cars near you
- **Filters sheet** 2152:9931 — "5 cars around Baku", Done / Clear
- **Profile / Settings** 2169:16621 — Profile, Settings, Notifications, Wallet, Activity

### Named on `05 · Prototype`, absent everywhere
Notification detail · All notifications · News detail · Card expanded · Date picker ·
Booking confirmation · Stays · City map · Profile · Help

## C. Missing from BOTH — required for production

### Blocks App Store review
- **Account deletion.** Apple has required in-app account deletion since 2022.
  Neither design has it.
- **Permission priming** — location, notifications, camera. Going straight to the system
  prompt without context costs a large share of grants.
- **Privacy policy / terms** as reachable screens, not just a signup checkbox.

### Blocks the business model
- **Host booking request — accept / decline.** The status vocabulary contains
  `waitingForHost` and `declined`, so a host-side approval screen MUST exist.
  **Nothing in either design shows a host accepting a booking.** This is the single
  largest gap: the marketplace cannot function without it.
- **Host earnings / payout** — hosts are shown estimated earnings but have no way to see
  actual earnings or withdraw.
- **Host availability calendar** — no way to block dates, so double-booking is possible.

### Ordinary but absent
- Date / time picker for booking (named on 05, built nowhere)
- Booking confirmation + the `celebrate` haptic moment the motion spec describes
- Cancellation flow and refund rules
- Reviews — leave one, read them. A 4.8 rating is shown with no way to produce it.
- Payment methods management, add card
- **Language switcher.** Three transcreated languages (en/az/ru) and no UI to change them.
- Damage report — the EV flow takes pre-trip photos, implying a dispute path that does not exist
- Error states: no network, payment declined, booking failed, vehicle unavailable
- Empty states beyond My trips: no chats, no notifications, empty wallet, no listings
- Loading / skeleton states

## D. Suggested build order

**Priority 1 — the flow cannot function without these — ALL BUILT 2026-09-17**
1. ~~Host / Booking request (accept, decline)~~ BUILT — HOST lane col 3
2. ~~EV / Trip summary (end-of-trip receipt)~~ BUILT — EV lane col 5
3. ~~Booking confirmation~~ BUILT — RENTER lane col 2
4. ~~Date picker~~ BUILT — RENTER lane col 3

**Priority 2 — completes flows already started**
5. Auth: splash, chooser with "Continue without sign-up", Sign In
6. Filters sheet
7. Profile / Settings (with language switcher and account deletion)
8. All notifications + Notification detail
9. News detail

**Priority 3 — production hardening**
10. Empty states (chats, notifications, listings)
11. Error states (network, payment, booking)
12. Cancellation + refund
13. Reviews
14. Permission priming
15. Host earnings / payout, availability calendar

## E. Rough total

29 built. Roughly **35-40 more** for a genuinely complete app, of which about
12 are already designed in `07` and need rebuilding, and about 25 do not exist at all.

---

## Closed 2026-09-18 — error and empty states

Built as lane `STATES` (9 screens). This was the top remaining priority. See BUILD-LOG.md
for node IDs and RULES.md section X for the pattern.

Covered: no network, no chats, no trips, no listings, no search results, payment declined,
location denied, empty wallet, generic failure.

## Remaining, in priority order

| # | Item | Why it matters |
|---|---|---|
| 1 | **Prototype wiring** | 67 screens and no clickable flow. Includes the notification icon, which must **scroll to an anchor on Home**, not navigate. |
| 2 | **az / ru localisation audit** | Every control was sized against English. Azerbaijani runs longest and will break buttons and tab labels first. |
| 3 | **Permission priming** | Location, notifications and camera all jump straight to the system prompt. A priming screen before each one is the difference between a grant and a permanent denial. |
| 4 | **SwiftUI build-out** | 26 Swift files against 67 screens. Now a real Xcode project at `/Users/mac/Documents/Rentbutik`, running on device. |
| 5 | **Delete `Theme Dark` collection** | Redundant since `Theme` gained real Light/Dark modes. Cleanup only. |

## Closed 2026-09-19 — three registration lanes collapsed into one

`AUTH` + `ONBOARDING` + `REGISTRATION · CONNECTED UX FLOW` (32 screens) replaced by `START`
(5 screens). See RULES.md section Y.

### Re-opened by that change

| # | Item | Note |
|---|---|---|
| 1 | **Document capture screens** | The ID / licence / selfie viewfinder flow now has no screens. It is reachable from the `Scan documents` tile on `Start / Identity` and needs rebuilding when that path is designed. Pattern preserved in `SPEC/_ARCHIVED-registration-flows.md`. |
| 2 | **Dark variant of the entry flow** | `Register / Choose method · Dark` was deleted as an orphan. DARK MODE is down to 7 screens and has no START screen. |
| 3 | **Permission priming** | The archived `Register / Camera permission` was the only priming screen in the file. Still missing — and now not even archived in the live design. |

