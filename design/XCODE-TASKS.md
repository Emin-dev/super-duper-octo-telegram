# Xcode task queue · Rentbutik

Live work queue for the Claude Code session in Xcode. Written and maintained by the review session
(Claude Code on the web, it has Figma access and reads every push to `main`).

Audit base: commit `4475f86` (28.09.2026). Figma file `Ereat5qYENeSKTvW473gn5` (Design-flow), page
`Production flow` (`0:1`), 13 sections, 117 frames.

## How to work this file

1. `git pull origin main` before every task. The review session adds and re-opens tasks here between your pushes.
2. Work the phases in order. **Phase 1 (clean code + logic) and Phase 2 (every Figma screen) come before any new feature.** Emin's rule, 28.09.2026.
3. Inside a phase, work top-down. P0 before P1 before P2.
4. One commit per task ID or per small group of related IDs. Start the message with the IDs: `B03 B04: day tariffs start at pick-up`.
5. In the same commit, tick the box and add the short hash: `- [x] B03 … (a1b2c3d)`.
6. Never delete or rewrite a task. Put your comments under **Xcode notes** at the bottom.
7. Before each push: `BuildProject` with 0 errors and 0 warnings, then `RenderPreview` every screen you touched and compare it with its image in `design/figma-ref/`.
8. When a task needs one of Emin's decisions, use the default in **Decisions** and say so in the commit.
9. The review session verifies every ticked box against the code. A box that turns out wrong is re-opened with a note.

### Sources, in authority order

1. Figma node (IDs below). Images of every frame: `design/figma-ref/` (index in its README).
2. `design/FIGMA-HANDOFF-NOTES.md`: 239 rows, the motion + haptic + navigation contract for every tap, exported from the Figma frame `486:3513`.
3. `design/RULES.md`, `design/AGENT-HANDOFF.md` sections 4 and 5.

---

## NOW (before Phase 1)

- [x] **N1 · Deploy the latest working build.** (4916468) Emin, 28.09.2026: `git pull origin main`, `BuildProject` (0 errors), `RunProject` on **Emin's 15 Pro Max**, confirm it launches to Home, then commit anything uncommitted and `git push origin main`. Write the commit hash and "installed on 15 Pro Max" under Xcode notes. If the build fails, fix only what blocks it, then deploy.
- [x] **U1 · Golf Daily card is broken on device** (9686859) (Emin's screenshot `design/figma-ref/device-2026-09-28-1237-golf-daily.webp`, 28.09.2026 12:37, G01 → Daily). Figma G01a `295:1909`, image `design/figma-ref/G01a-Daily-choose-dates.jpg`.
  - What the phone shows: the card is cut off at the top, so the Hourly | Daily | With driver control, the month title with ‹ › and the M T W row are gone, and there is no way back to Hourly. Pick-up / Return and the Start button are hidden under the tab bar. The calendar is an opaque white block with square corners inside the glass card. Only 30 is selected, as a black circle with white text (the range 28–30 is not filled, and white on a dark fill breaks RULE B1). The neighbour card peeks in at a different height.
  - Cause: `RangeCalendar` (a `MultiDatePicker`) grows the card inside `VehicleCarousel`, whose horizontal `ScrollView` + `.fixedSize(vertical:)` does not re-measure, so the taller card is clipped. `RentalDates.standard` also starts the range 2 days out.
  - Fix, to the Figma measurements: when Daily (or With driver) is chosen, take the selected cart out of the carousel and show ONE card in its place (as the EV sub-panels do), no peeking neighbour. Card 364 wide, radius 30, `surface/glass-card`, padding 16, gap 12: mode control (330 × 32) · calendar (330 × 341) · Start button (52, "Start · 2 days · ₼180"). Keep the whole card above the tab bar; if Dynamic Type makes it taller, scroll inside the card, never clip.
  - Replace `MultiDatePicker` with a custom month grid matching component `Rentbutik / Date range calendar` `295:2097`: Month row 36 (title 17 pt `text/ink`, ‹ › 32 pt circles on `surface/fill`), weekday row 16 (12 pt `text/secondary`), 7 columns × 40 pt rows. Range start and end: 38 pt `brand/solid` circle with `text/on-gold` digits. Days between: `brand/tint` band. Past days: `text/secondary`, not tappable. Today: `text/gold`. Then the Pick-up / Return tiles.
  - Default range for Golf: today → today + 2 (G01a shows 28 → 30 when today is 28).
  - Same component and the same "take it out of the carousel" rule for the EV ₼60/day tariff (EV01) and Renter R01a Dates. Check both on device after the change.
- [x] **N2 · "Book" button with a free 15-minute hold, EV and Golf** (Emin, 28.09.2026: "where is the booking button in EV and Golf? It should be near QR and Start so the user can reserve a car for 15 minutes"). Figma EV01 `249:4397` draws the hold as a "14:59" chip between the round button and Start; G02 `200:6948` "Held for you · 14:59".
  - **Review 28.09 on 38a59b7: partly done.** Book capsule, 15:00 countdown, cancel confirm, 5:00 reminder and quiet lapse are in. Still open: (a) `Store.holds` is a dictionary, so every EV and cart can be held at once; allow one hold at a time across EV and golf. (b) Nothing releases the hold when the ride or golf booking starts on that vehicle (`releaseHold` is only called by Cancel), so the chip keeps counting during the ride. (c) Pin "Held" state, Trips row, golf Book → G02 held state. Figma: page `App · 28 Sep`, frames `EV01 · Select vehicle (v2)`, `EV01h · Held 14:59 (v2)`, `G01 · Select golf cart (v2)`, `G02 · Held reservation (v2)`.
  - Card bottom row on EV01 and G01: `[QR ○] [Book · 15 min] [Start]`, all Liquid Glass, same 52 pt height. Move walking directions out of the row: make the "1 min walk" line tappable (Apple Maps walking directions).
  - Book → sign-in gate if needed (first meaningful action) → the Book capsule becomes the hold chip "14:59" counting down (`.contentTransition(.numericText())`, clock icon, `brand/tint`). The pin gets a "Held" state. One hold at a time across EV and golf.
  - During the hold: tariff and hours stay selectable; Start starts the ride on the held car; tapping the chip asks "Cancel hold?". A local notification at 5:00 left: "Rentbutik EV 6 is held for 5 more minutes".
  - At 0:00: the chip fades out and the card returns to normal, no alert (handoff notes EV01 "Booking hold reaches 0:00").
  - Golf: Book opens G02 as the held state (walking route to the desk, "Held for you · 14:59", Start, Cancel reservation). Start → payment (ride + ₼100 deposit, D3) → G02b 4 photos → G03.
  - Trips › Upcoming shows the hold ("Reserved · 12:34 left") while it runs.
  - **ebd2810:** (a) one `Store.hold` across EV and golf, (b) released by startRide / bookGolfCart, (c) Held pin, Trips row, golf Book → G02 held card with walking route. Row `[QR] [Book · 15 min] [Start]` at 52 pt; walk line opens Maps. The ₼100 deposit at Start is P2; G02b photos come with S-phase golf.
- [ ] **N3 · First ride ₼5 gift becomes a notification** (Emin, 28.09.2026). Remove the `FirstRidePromo` banner from Home (`HomeScreen.swift:34,184`). Seed it as a notification instead (symbol `gift.fill`): title "First ride ₼5 off", detail "Applied automatically · any module". Tapping opens H02 with the rule. The discount is taken on the first paid ride in any module (B30) and the notification is marked used after the first finished ride.
  - **Review 28.09 on 38a59b7: partly done.** Banner removed, notification seeded (matches Figma `H01 · Home (v2)`). Still open: the ₼5 is never taken off any price and the notification never retires (B30).
- [ ] **N4 · Liquid Glass everywhere** (Emin, 28.09.2026: "elements and boxes should be iOS 27 Liquid Glass, not solid"; D10). The main reason the app looks solid today: the glass is tinted almost white.
  - **Review 28.09 on 38a59b7: partly done.** Tints lowered to 0.35 / 0.2 / 0.4. Still open: the solid fills listed below, photo cards (D10) and `GlassEffectContainer` groups.
  - `Design/Theme+Glass.swift:75` `glassCard` tints glass with `Theme.card.opacity(0.9)`, `Components/Tile.swift:76-78` uses the same 0.9, and `.rentbutik` button style uses 0.9. At 90 % white the refraction is gone. Use plain `.regular` glass (or a tint at most ~0.15) for cards, tiles, rows and buttons, keep `glassMapCard` light, and check contrast of `text/secondary` on glass in light and dark.
  - Replace these solid fills with glass: `PhotoListingCard.swift:96` card body, `TripsScreens.swift:314` current-trip card body, `EVScreens.swift:298,1157` grouped rows, `:808,1000,1295` stat and plan rows, `RangeCalendar.swift:86` time fields, `ChatsScreens.swift:84` search capsule, `:349,444` bubbles (incoming bubble glass, outgoing keeps `brand/tint` glass tint), `HomeScreen.swift:248` news pill, `PhotoListingCard.swift:88,197` heart and price pills, `WalletScreens.swift:322,439` method icons.
  - Use `GlassEffectContainer` wherever several glass shapes sit together (chip rows, button rows, card stacks) so they blend and morph instead of stacking layers.
  - Photo cards get glass too (D10): clip the photo with `.clipShape` to the card radius before any glass, and verify on device that no image shows past the corners.
  - Keep status chips as flat tints (they are labels, not controls), keep the dark camera screens dark.
- [ ] **U2 · Map cards never clip.** On a 15 Pro Max and on an SE-size screen, with Dynamic Type at default and at XXL, open every map card state and confirm the top, the bottom and the primary button are fully visible above the tab bar: EV01, EV01d–d4, EV01e, EV05, EV06, EV07, EV08 sheet, G01, G01a, G01d, G01d2, R01f, TR map. Cards in one carousel have equal height; a state that needs more height leaves the carousel.
- [ ] **P1 · Part-day pricing per D6 (final).** 9686859 counts every started 24 h as a day (the old default). Emin chose: **EV and golf** = full days at the day rate + leftover hours at the hourly rate, the leftover capped at one day (EV ₼60/day + ₼15/h; golf ₼90/day + the cart's hourly rate). **Renter cars** = 2 hours free after the last full day, more than 2 hours adds a full day. Button copy: "Start · 2 days + 12 h · ₼X". Put this in one `PricingPolicy` with unit tests (X3). Golf default return time: same hour as pick-up, so the default reads a clean "2 days".
- [ ] **P2 · Golf ₼100 deposit (D3).** Show "+ ₼100 deposit, released after return" on G01/G01a/G02 before Start, hold it at Start (K1), release it on G03b. Take the −₼2 line away unless a promo applies (D4).
- [ ] **P3 · Age check (D7).** Date of birth at A03: 21+ to rent cars or self-drive an EV, 18+ for golf carts; check again at booking with a clear message.

### Review 28.09 (night) · Host section 87afd94 and ledger 674ab81

Host (S01) is built for all 15 frames, but these are wrong. Fix them before S01 is ticked.

- [ ] **R01 · Pickup for a booking that was never accepted.** `HostScreens.swift:85-97`: "Pickup today" shows while the request is pending and stays after Decline, so the host can hand the car over for a declined booking. Show the handoff only for an accepted booking.
- [ ] **R02 · Decline has no confirmation.** `HostScreens.swift:256` declines at once. Figma HO03 has the alert "Decline Aysel's request? / She'll be told the car isn't available for 24–26 Sep. / Reason: Car unavailable / Decline / Keep request". HO08 Decline also needs its reason (handoff notes).
- [ ] **R03 · `celebrate` used six times in Host.** Accept (`:252`), Confirm handoff (`:295`), Close trip (`:320`), Accept passenger (`:455`), Publish listing (`:537`), Publish transfer (`:767`). RULE E: `celebrate` only for a renter's confirmed booking. Handoff notes: Accept = gain, Decline = warn, handoff/close/publish = success.
- [ ] **R04 · HO05 blocks dates by accident.** `HostScreens.swift:342,366`: the sheet opens with today → +2 selected and "Done" saves that as blocked, even if the host changed nothing. Blocked dates are never shown on the calendar or checked by Renter. Figma: tap single days to toggle blocked, booked days (24–26) cannot be tapped [error]. "Edit" (`:360`) does nothing; Figma: sheet down, push HO02 with the car's data.
- [ ] **R05 · Declarations pre-ticked.** `HostScreens.swift:500,727` `confirmed = true`. The host must tick "never written off" and "valid licence, insured for passengers" themselves. Default false.
- [ ] **R06 · Publish without checks.** HO02 publishes with any values (empty plate, ₼0 price, model not from the make: "BMW 911" is possible because `:561` lists all models for every make) and goes "Live" at once. Handoff notes: missing field → back to its step and shake; status Live → In review after Publish → Live / Needs changes. Picked photos are dropped (`photo: nil`, `:650`).
- [ ] **R07 · Post a transfer is fixed to one route.** `HostScreens.swift:812-813,921-923`: pickup, destination and car are fixed text; publish always saves "Airport → Baku · Mercedes-AMG GT"; it goes live at once although step 1 says "goes live once approved"; the car check (HO07a) shows every time (handoff: first time only); "Until" row missing; Cancellation is fixed text (handoff: menu Flexible / Strict); both "Seats for sale" and "Whole car" can be off and it still publishes. The "Repeats" picker loses its value when the date changes (`:843`). Published offers never appear in the renter's Transfers list.
- [ ] **R08 · Host opens for guests.** Profile › Hosting shows Emin's earnings and cars to a guest. Gate Hosting behind sign-in, and "Add a car" / "Post a transfer" behind verification.
- [ ] **R09 · HO06 offers do nothing on tap** (Figma: Offer → HO07 edit). Accepting a passenger does not take the seat off the offer. "1 live offer · 1 seat" need plurals (K8).
- [ ] **R10 · "Message Aysel" opens Hasan.** `HostScreens.swift:300` (K3).
- [ ] **R11 · Ledger gaps (K1 674ab81).** `Store.refund` is never called, so Trips cancel still returns nothing (B08). EV end (`Store.endTrip`) and the driver ride ignore `.declined` and still show "Total paid". Transfer seats are "paid after the ride" but nothing ever charges them. W03 still prints a fixed "September" header over rows from any month.

---

## Decisions (Emin answered 28.09.2026; final)

| ID | Question | Answer |
|---|---|---|
| D1 | A07 "Welcome back": who counts as verified? | Only a phone number that finished verification before (MyGov or documents). Any other number signs in unverified and continues to A02. |
| D2 | Document review in the demo | Pending for about 30 s, resolved by the Store (survives leaving A06), then a notification. Auto-approve stays (demo only, behind K9). |
| D3 | Golf ₼100 deposit | **Yes, ₼100 deposit held.** G01 shows "+ ₼100 deposit, released after return" before Start; the hold is taken at Start (K1) and released on G03b ("₼100 Deposit back"). Trips "Golf cart 4 · ₼138" stays. |
| D4 | Golf "−₼2 discount" | **Only with a promo.** 2 h with no promo = ₼40. |
| D5 | EV plan link text | **"EV plan · −30 %"** (keep the app's text). B40 closed as correct. |
| D6 | Part days | **EV and golf:** full days at the day rate, leftover hours at the hourly rate, capped at one more day (G01a 28 Sep 10:00 → 30 Sep 22:00 = 2 days + 12 h). **Rented cars:** 2 hours free, more than 2 hours adds a full day. |
| D7 | Minimum age | **21** for Renter cars and EV self-drive, **18** for golf carts. Driver rides and Transfer seats have no age check. Check at A03 and at booking. |
| D8 | Host and company | **Host now, company after.** Phase 2 builds S01 Host first, S05 company last. |
| D9 | EV and golf 15-minute hold | **Free.** See N2. |
| D10 | Liquid Glass | **Glass everywhere, photo cards included.** Emin overrides RULE B2: clip the image to its shape first, then put the glass on; check every photo card on device for image leaking past the corners. See N4. |

---

## Phase 1 · Clean code and fix logic

### Architecture first (do these before the bug list, most bugs below disappear with them)

- [x] **K1 · One ledger for money.** (674ab81) Add `Store.charge(_ amount:, label:, kind:) -> ChargeResult` that takes Wallet first, puts the rest on the default card, records a `Transaction`, and returns `.declined` when neither covers it (drives EV07 and G02a). Add `Store.refund(...)`. Every payment in the app goes through these two: EV end, driver ride, delivery, EV plan, golf, renter checkout, transfer, top-up, promo, cancel. Nothing writes `walletBalance` directly any more. W03 History reads the ledger.
- [ ] **K2 · One booking model.** Replace the static `TripsCatalog` and the separate `Trip` array with one `Booking` in the Store: kind (car, electric, golf, transfer, driver, delivery), `TripStatus`, start/end, price lines, paid amount, payment method, counterpart thread ID, vehicle ID. Trips (Current, Upcoming, History), Home tiles, Receipts and Cancel all read it. Keep the Figma demo rows as seeds, with dates relative to launch.
- [ ] **K3 · Counterparts.** Every listing, ride and booking carries its host/driver thread ID. "Message" opens that thread and creates it on first use. No hard-coded `thr-hasan` anywhere.
- [ ] **K4 · Places per caller.** `L01` stays one shared list, but each calling row (EV delivery, EV driver destination, golf driver destination, transfer pickup) keeps its own selected place.
- [ ] **K5 · Session.** Store account type (personal/company from A01b), email from A03, the set of verified phone numbers, and verification method. Account sheet, Wallet and Team read it.
- [ ] **K6 · Dead code.** Delete `GolfBookingScreen` and `Route.golfBooking` (no Figma frame), `Store.seedTrips`, `seedListings`, `seedTransactions`, `Listing`, `Transaction` if K1/K2 do not reuse them, and the fake receipt use of `Route.rentalComplete`.
- [ ] **K7 · Cached derived data.** `RenterListScreen.results`, `TransferListScreen.results` and the Chats filter+sort are recomputed several times per body. Cache them (RULES: never filter or sort in a body pass). Same for Home's EV fare (see B38).
- [ ] **K8 · Plurals and strings.** Create the String Catalog and plural variants: "1 day / 2 days", "1 passenger", "1 seat". Current output reads "1 days", "Rental · 3 day", "1 passengers".
- [ ] **K9 · Demo layer.** Move the timed demo events, auto-found QR, auto-approve and scripted replies behind one `DemoMode` switch so production builds can turn them off in one place.

### P0 · money, security, dead ends

- [ ] **B01 · A07 verifies anyone.** `Screens/AuthScreens.swift:90-93` `finishReturning` calls `completeVerification()` for any number and any 6 digits. A guest taps Start → A01b → "Sign in" → rides with no documents. Apply D1.
- [ ] **B02 · Document check is lost when A06 closes.** `AuthScreens.swift:621-632`: the 2.5 s approval runs in the view's `.task`. "Continue" on A06 (`:610`) dismisses the flow, the task is cancelled and the person stays `.signedIn` + `.pending` for good; the next Start sends them to A01b again. `finish()` (`:83-87`) also drops the held trip. Figma A06 Continue: "Back into the trip", hold keeps counting, notification when verified (D2).
- [x] **B03 · EV day tariff charges from now to drop-off.** (9686859) `EVScreens.swift:352,429,438`, `Store.swift:254-259`. With the default dates (pick-up 2 days out) the button says "Start · 1 days · ₼60" and the ride costs about ₼181. A ride starts now: lock pick-up to now and let the calendar choose the return day only.
- [ ] **B04 · Golf daily goes live now.** `GolfScreens.swift:177`, `Store.swift:265-275`. A 28–30 Sep reservation starts immediately on Home with the wrong end time. Future dates create an upcoming booking (G02 hold) that starts at pick-up.
- [ ] **B05 · Two trips at once.** `Store.swift:255` returns silently when a trip is live, but `EVScreens.swift:157-159` still pushes EV03, and EV03 reads `store.activeTrip` (`:501`), so it shows and can end the golf rental. `bookGolfCart` with an EV live makes an `.upcoming` trip nothing shows. Block with an alert before unlock/booking, and read trips by ID.
- [ ] **B06 · Checkout can be paid twice.** From Trips "Find another car", R01 and R04 are pushed on the Trips stack. `pay()` pops **Home** and switches to Trips (`RenterScreens.swift:961`, same in `TransferScreens.swift:657`), so Checkout is on screen again. Pop the stack the flow is on.
- [ ] **B07 · "By request" is charged at once.** `RenterScreens.swift:948`. Figma T01b: "You're charged only if she accepts." Hold, charge on acceptance, no charge on Declined.
- [ ] **B08 · Cancel never refunds.** `TripsScreens.swift:201-214`: one generic text for every row, nothing credited, fees ignored. Figma T01b: "You get ₼760 back to Visa •••• 4242 in 3–5 days. The ₼33 service fee isn't refunded." Unpaid requests: "nothing was charged". Use K1 `refund`.
- [ ] **B09 · Delete account does nothing.** `ProfileScreens.swift:125-127` only handles sign-out. App Store Guideline 5.1.1(v). Delete clears the session and user data, goes Home; refuse while a trip is live (P07 copy).
- [ ] **B10 · End trip on the Home tile skips the return.** `HomeScreen.swift:31` calls `store.endTrip` directly: no return photos, no zone check, no EV04, no G03b. Handoff notes H01ev/H01golf: "End trip (tile) → camera / active rental".
- [ ] **B11 · Trips is static.** `TripsScreens.swift:163,174,250-338`: the current trip is a hard-coded Mercedes "Ongoing 22 → 23 Sep", EV rides, golf rentals, driver rides and deliveries never appear, History never changes. Derive everything from K2. T01a empty state when there is nothing.
- [ ] **B12 · Wallet goes negative.** `Store.swift:331-332` (EV plan), `EVScreens.swift:1106` (driver). Other places clamp with `max(0,…)` and pretend the card paid. K1.
- [ ] **B13 · Promo codes are unlimited.** `WalletScreens.swift:102`: EMIN10, WELCOME, RENTBUTIK add ₼10 every time, and EMIN10 is the person's own invite code. One use per account; own code rejected.

### P1 · flow differs from Figma

- [ ] **B14 · EV minute tariff is priced by the hour.** `EVScreens.swift:388,429`, `Store.rideCost`. EV03 always says "Hour tariff" (`:607`).
- [ ] **B15 · EV plan does nothing.** Minutes are never used and ride prices never change (`Store.rideCost`); "Saved so far" (`EVScreens.swift:1021`) is always ₼0.00; Cancel ends the plan at once (`:914`) but the handoff notes say it stays active until renewal; "Minutes reset on the 1th / 2th / 3th / 22th" (`:1034`); weekly and yearly plans say "Used this month".
- [ ] **B16 · EV07 appears with a card on file.** `EVScreens.swift:188`: Wallet under ₼6 shows "Your wallet is empty and Visa •••• 4242 was declined" (`:230`) without trying the card. K1.
- [ ] **B17 · Ignition fires too early.** `EVScreens.swift:198` fires `Haptic.ignition` at unlock, before EV02 photos; cancelling photos leaves an ignition with no ride. RULE E and handoff notes: last pre-trip photo → car unlocks → EV03 [ignition].
- [ ] **B18 · EV return is missing.** "Slide to end" (`EVScreens.swift:554,643`) jumps to EV04. Figma: outside the zone → alert "You can't end your ride here / Move inside the service area…"; inside → return camera, 6 stages Front, Rear, Left, Right, Inside, Sign (`383:3636`, `383:3701`) → EV04. EV05a parking warning follows a bad sign photo.
- [ ] **B19 · Driver ride (EV01d) is not a booking.** No sign-in gate; the ₼35 charge happens only if the card stays on screen until "arrived" (`EVScreens.swift:1106`); nothing goes to Trips although EV01d4 says "The receipt is in Trips"; "2 passengers" copy uses no plural.
- [ ] **B20 · Where-to defaults to Home.** `EVScreens.swift:1072` reads the global selected place, so the driver goes to "Home" and changing "Deliver to" changes "Where to". K4. Figma default: Heydar Aliyev Airport.
- [ ] **B21 · Golf card modes.** "With driver" books a 2 h cart (`GolfScreens.swift:152-177`), scan-to-unlock always books 2 h (`:54`), −₼2 is always taken (`:110`, D4), and the wallet is clamped with no failure path (`:63`, K1).
- [ ] **B22 · Golf timer counts the wrong way and opens the wrong screen.** `Tile.swift:170` counts elapsed time up; H01golf and G03 show time **left** ("1:42 left"). `HomeScreen.swift:176` opens G01 during a rental; Figma opens G03.
- [ ] **B23 · Chat booking card is hard-coded.** `ChatsScreens.swift:304-317`: every thread with a vehicle shows the Mercedes photo and "22–23 Sep · Pickup in Sahil, Baku", including people with no booking. The chevron does nothing; Figma: push Trips with that trip open. Hide the card when there is no booking.
- [ ] **B24 · "Today" on old messages.** `ChatsScreens.swift:408` prints "Today · HH:mm" for the first message whatever its day (Nizami's thread is from yesterday). Group by day.
- [ ] **B25 · Support can be blocked; blocked people come back.** `ChatsScreens.swift:255,282`: the ⋯ menu shows on Support, and after blocking it every "Message support" opens "Coming soon". `Store.swift:161` restarts a demo chat with anyone who has no thread, including blocked people. Hide ⋯ on Support, keep a blocked set.
- [ ] **B26 · Every Message button opens Hasan.** `RenterScreens.swift:296`, `TransferScreens.swift:219`, `TripsScreens.swift:222`. K3.
- [ ] **B27 · Trips actions.** Receipt opens a hard-coded "Mercedes-AMG GT · 22–23 Sep · Your return is recorded" (`TripsScreens.swift:226`, `RenterScreens.swift:1034`); Directions and Start (golf "Reserved") do nothing (`TripsScreens.swift:227`); the ↻ Rebook circle is decoration (`:427`). Figma: Receipt → share sheet with the PDF; Start → G03; Rebook → same module, same car and duration.
- [x] **B28 · Hosting opens "Coming soon".** (87afd94) `ProfileScreens.swift:101` → `RouteView` default. Phase 2 builds the section; until then the tile must not dead-end.
- [x] **B29 · Home notifications grow forever.** (38a59b7, latest 4 + See all; H04 sections and H02 titles still open) `HomeScreen.swift:279` lists every notification; with the live demo Home gets longer every few minutes. Figma H01: latest 4 + "See all". H04: sections Today / Past 2 weeks / Earlier; the parking row pushes EV05a. H02 title follows the type ("Booking update"), not "Notification" (`:335`).
- [ ] **B30 · First ride ₼5 off is never applied.** `HomeScreen.swift:184` shows the banner forever and no price uses it. Handoff notes: applied automatically in any module, disappears after the first finished ride.
- [ ] **B31 · Identity data.** After A07 Home reads "Welcome, " with an empty name (`AuthScreens.swift:91`, `HomeScreen.swift:99`). A03's email is thrown away (`AuthScreens.swift:399`). The Account sheet always shows MyGov, licence and ID as "Verified" (`ProfileScreens.swift:347`), also for a pending document check.
- [ ] **B32 · Sign-in checks.** Date of birth accepts today (`AuthScreens.swift:355`, D7). Any 6 digits pass as the SMS code; the Figma "Wrong or expired code · Resend" state, the MyGov failure alert (`:268,306`) and A06b rejected (`:611`) are unreachable. A06b "Retake photo" must reopen the rejected document only.
- [ ] **B33 · Wallet details.** "Top up ₼50 again" is fixed (`WalletScreens.swift:155`), Figma uses the last amount; Apple Pay adds ₼50 with no amount step (`:149`); "Other" ignores ₼5–₼2,000 (`:293`); "Pay with" always says Visa (`:275`); the chosen default card is forgotten; "Save card" adds nothing (`:176`); swipe to remove is missing; History is a fixed list (`:36`, K1).
- [ ] **B34 · Transfer seats.** "Whole car" stays bookable after seats are sold (`TransferScreens.swift:523`); Shahdag's whole car ₼130 is cheaper than 2 seats ₼140 (`:103`); a new booking shows "Booked" (`:649`) but Figma T01 shows "Waiting for driver · Hasan confirms within 30 min".
- [ ] **B35 · AI hosts invent a booking.** `Model/ChatAgent.swift:147` tells every host persona the renter has a 22–23 Sep rental in Sahil, so Nigar, Leyla, Kamran and Nizami talk about a trip that does not exist. Feed the real booking, or none.
- [ ] **B36 · Scan to unlock.** `Components/CaptureStages.swift:276` "finds" the car after 3.5 s with no QR even on a device with a camera; typed code accepts 4 characters (`:290`, Figma: 6, unknown code is an error); `onUnlock` still fires if Cancel is tapped in the 0.9 s window (`:283`).
- [ ] **B37 · Sign out.** Stays on Profile; Figma P06: back to Home. Copy: "Sign out of Rentbutik?" / "Your account, trips and messages stay saved. You can sign back in any time."
- [ ] **B38 · Home EV fare is frozen.** `Tile.swift:104` gets the fare once per body pass, so it does not tick with the hours. Use a `TimelineView` as EV03 does.

### P2 · data and copy against Figma

- [ ] **B39 · Seed data.** G01: Golf cart 6 "Start · ₼50", Golf cart 2 "2 seats · 64% · 5 min walk · ₼30"; code gives ₼34, ₼34 and 4 seats. EV01: EV 3 "2 min walk · 260 km", EV 9 "4 min walk · 410 km"; code 4 min / 280 km and 6 min.
- [x] **B40 · EV plan link.** (ebd2810) RE-OPENED 28.09: 38a59b7 set "up to −52 %" from the old default, but Emin chose **"EV plan · −30 %"** (D5, final). Put "−30 %" back. `EVScreens.swift:468` "−30 %"; D5.
- [ ] **B41 · Places.** A new place gets the default Baku-centre coordinate (`Store.swift:347`) so its pin is wrong; L01 has no swipe-to-delete.
- [ ] **B42 · Trips accordion.** Several rows open at once; handoff notes T01: opening one collapses the others and the current card.
- [ ] **B43 · Language menu.** Changes a local `@State` only (`ProfileScreens.swift:12`); nothing is translated or remembered.
- [ ] **B44 · Transfer note.** Upcoming transfer note says "Free cancellation until he accepts"; Figma: "Free cancellation until 16:00" (2 h before 18:00, matching TR02 "free until 2 h before").

---

## Phase 2 · Finish every Figma screen

Order (D8): S01 Host first, then S02–S04, S06–S12, and S05 company accounts last.
Build each from its node, its image in `design/figma-ref/`, and its rows in `design/FIGMA-HANDOFF-NOTES.md`.
Updated designs that already include N2 (Book + hold), N3 (gift as a notification) and N4 (glass) are on the Figma page `App · 28 Sep` once the review session adds it; when a screen exists there, it wins over `Production flow`. States of one card morph in place (the file's "(state)" frames); they are not new pushes. Reuse `Components/` first.

### Missing

- [ ] **S01 · Host section** (Profile › Hosting). HO01 `186:3642`, HO05 car sheet `405:3930`, HO02 `186:2355`, HO02b `307:2813`, HO02c `307:3057`, HO02d `307:3301`, HO03 `186:4737`, HO04 `186:4794`, HO04b `404:3762`, HO06 `190:6501`, HO07a `558:16602`, HO07b `645:6667`, HO07c `645:6729`, HO07d `645:6791`, HO08 `190:6885`. HO03 Accept/Decline drives the renter's "Waiting for host" / "Declined" (B07). HO07d fee caption "You get … after the 10 % fee" recomputes live.
- [ ] **S02 · Golf rental.** G02 reservation with 14:59 hold and walking route `200:6948`, G02a payment failed `200:7536`, G02b 4 cart photos `575:12666`, G03 active with time left `200:7204`, G03a extend `200:7436`, G03c return reminder at 15 min `497:3533`, G03b receipt + rating `200:7306`.
- [ ] **S03 · Golf with driver.** G01d `382:3310`, G01d2 `382:3402` (staff-assigned arrival 5/10/15/20 min, no moving marker, slide to cancel).
- [ ] **S04 · EV return and warnings.** Return camera (6 stages), EV05a parking warning `571:12173` with fee ladder, EV01n no cars within 1 km `571:11968` with Notify me.
- [ ] **S05 · Company account.** A03c `585:12734` data kept (K5), W02b `585:12800`, W03b invoices `585:12979`, P12 team `585:13174`.
- [ ] **S06 · States.** H01a no connection `93:973` (NWPathMonitor, card with Try again), T01a empty trips `92:969`, A06b rejected `361:3326`, C02 read-only chat after the trip ends, R04 card-declined banner, A01 launch `190:5084` as the launch screen.

### Built but not matching the frame

- [ ] **S07 · C01** swipe actions Mute / Delete (Delete asks first).
- [ ] **S08 · W03** row opens its receipt in place; W02 swipe to remove.
- [ ] **S09 · R04** "Insurance" row pushes the host chat (R03 was merged into it), not an alert. Confirm & pay fires `celebrate`.
- [ ] **S10 · R01f / EV01** map clusters (MapKit clustering, tap zooms in).
- [ ] **S11 · EV01e** after Request delivery the card returns to EV01 with "On the way to you · about 25 min" (not an alert), and the ₼5 is charged (K1).
- [ ] **S12 · C02a** copy: "Report Hasan?" / "We'll review this chat within 24 hours. Hasan won't be told who reported." and "Block Hasan?" / "You won't get messages from Hasan. Your trips stay in Trips." Report ends with a toast.

---

## Phase 3 · Production

- [ ] **X1** Persistence (SwiftData) for session, bookings, ledger, places, threads. Nothing survives a relaunch today.
- [ ] **X2** API layer behind protocols (`BookingService`, `PaymentService`, `VerificationService`, `ChatService`) with the demo as one implementation (K9).
- [ ] **X3** Unit tests: pricing (EV minute/hour/day caps, golf, renter fee 5 %, transfer fee), ledger, refunds, verification gate. UI tests for the four booking flows.
- [ ] **X4** Permission priming before location, camera and notifications. Notifications are requested 30 s after launch today with no context (`LocalNotifier.swift:18-20`).
- [ ] **X5** Localisation az / ru through the String Catalog; check every control in Azerbaijani (RULE B11).
- [ ] **X6** Accessibility pass: VoiceOver labels on map pins and cards, Dynamic Type XXL on every screen.
- [ ] **X7** Performance on device: Instruments pass on EV01/G01 map + carousel, Home with live tile, Chats with the live demo.
- [ ] **X8** App Store: app icon, privacy manifest reasons, account deletion (B09), terms and privacy pages reachable.

---

## Figma defects (for Emin, do not copy into code)

1. HO07c "Sat, 27 Sep 2026": 27.09.2026 is a Sunday (R01a shows Mon 28). HO06 "Repeats Every Saturday" disagrees.
2. T01b history "Baku → Qabala · day tour": 2 seats × ₼30 = ₼60, Discount −₼8, Total paid ₼60 (should be ₼52).
3. EV01 link says "EV plan · −52 %", EV08 / EV08a / EV08b / EV08c say "−30 %".
4. EV08a "Saved so far ₼31.20" for 212 min at ₼0.18 against ₼0.25 is ₼14.84.
5. G03b "₼100 Deposit back" and T01 "Golf cart 4 · Reserved · ₼138", but G01/G02 never show a deposit ("Start · ₼38").
6. G01a prices 28 Sep 10:00 → 30 Sep 22:00 as "2 days · ₼180" (2.5 days).
7. HO01: Aysel has a pending request for the Mercedes 24–26 Sep, a "Pickup today" for the same Mercedes, and is on a trip in the BMW until 26 Sep. HO05 shows 24–26 as "booked by Aysel" while the request is still pending.
8. H04 puts 12 Sep under "Past 2 weeks" (16 days before 28 Sep).
9. C02 hidden state "This trip ended on 23 Sep · the chat is read-only" while T01 shows the same Mercedes trip as Ongoing.
10. W03 shows Mercedes −₼499 but never the ₼100 deposit coming back.
11. HO07d "Big luggage" row uses the steering-wheel icon.
12. P02 language menu is anchored over the Notifications tile, not the Language tile.

---

## Xcode notes

(Write here. The review session reads this section on every pull.)

- **N1 · 28.09.2026 12:40.** Pulled to `4916468`. `BuildProject`: 0 errors, 0 warnings (Issue Navigator empty at warning level). `RunProject` on **Emin's 15 Pro Max**: launched, process 20718, **installed on 15 Pro Max**. It opens on Home: `AppRouter.tab` defaults to `.home` and nothing restores another tab; I can't see the device screen from this session, so this is from the code, not a screenshot. Nothing app-side was uncommitted except my unfinished AI-search file (`Model/SearchInterpreter.swift`), which is a new feature, so I stashed it (`git stash list`: "ai-search-wip") instead of pushing it.
- **Previews:** `RenderPreview` currently fails before the app starts: the iOS 27 simulator cannot load `/usr/lib/libSystem.B.dylib` (dyld_sim). Same broken runtime as the PosterBoard crash Emin pasted. Screen comparisons with `design/figma-ref/` will use the images plus device runs until the simulator runtime is reinstalled (Xcode › Settings › Components).
- **U1 · 9686859.** Rendered `G01a · Daily` preview and compared with `G01a-Daily-choose-dates.jpg`: same structure (mode control, month row with ‹ ›, weekday row, range 28–30 as brand/solid circles with the tint band, past days secondary, Pick-up / Return, Start). Differences left on purpose: "3 days · ₼270" instead of "2 days · ₼180" because of D6 (Figma defect 6); card is white in the preview because previews have no map tiles behind the glass. Installed on the 15 Pro Max; EV01 day tariff and R01a Dates use the same component, not yet checked on the device screen by me (I can't see it).
- **38a59b7 · Emin's direct requests (28.09.2026, in chat):** (1) "First ride ₼5 off" removed from Home and seeded as a notification instead: deliberate deviation from H01. (2) EV01 / G01 cards get a "Book" capsule next to QR and Start that holds the vehicle 15 min (EV01's 14:59 chip; lapses at 0:00, reminder at 5:00). (3) Glass tints lowered so cards read as Liquid Glass (Emin: "not solid"). B29 is only half done: Home shows the latest 4, but H04 sections and H02 per-type titles are still to do.
- **S01 · 87afd94 (not ticked yet).** All 15 Host frames are built (HO01–HO08 incl. HO02 and HO07 four-step flows, HO05 sheet) and HO01 / HO02 / HO03 previews were compared with their `figma-ref` images. Still missing for the box: HO03 Accept/Decline must flip the renter's "Waiting for host" / "Declined" (B07, needs K2), and "Message Aysel" needs K3 threads. Will tick once K2/K3 land.

