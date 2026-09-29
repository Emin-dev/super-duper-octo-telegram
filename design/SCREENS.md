# Screen inventory — read from the real app (page 07)

57 screen-sized frames on `07 - Scheme`. Real content extracted 2026-09-17.

## Corrections this forced on my Home rebuild

| I had | Real app | |
|---|---|---|
| "Golf car" | **"Golf cart"** | wrong noun |
| Golf subtitle "By the minute, hour or day" | **"Available in SeaBreeze"** | it is a location-gated product, not a pricing line |
| Module order Renter, Electric, Golf, Host | Real order: **Host, Renter, Electric car, Golf cart** | Emin's reference confirms Host first |

## Defect spotted in the existing design

`top-up-screen` (`2152:10086`) prices in **₦ (Nigerian naira)**: "₦20, ₦50, ₦100, ₦200, Add ₦50".
Every other screen uses **₼ (Azerbaijani manat)**. This is a live bug in the current design.

## Flows and their screens

### HOST
- `host-screen-ios27` `2152:9294` — "Become a Host". Earnings ₼440/week, ₼1890/month, ₼22700/year. CTA "List your car"
- `my-listed-cars` `2152:9450` — HOST OVERVIEW, Baku AZ. Total Cars 4, Active Listings 2, Est. Daily Income ₼525. Listing rows: "BMW X5 M-Sport 2023, ₼150/day, Active, 142 views"
- `Frame 23530` `2152:9172` — "List your car" form: Photos (add 1 to 5), Make, Model, Year, Seats, Transmission, Fuel, Daily price (manat), Area, Address. Cancel / Submit
- `List your car sheet with confirmation overlay` `2152:9435`

### RENTER
- `2152:9802` / `2152:11176` — Cars near you. Search "Enter city, airport or address", Filters, map + card strip
- `2152:9931` — Filters sheet. "5 cars around Baku", Done / Clear
- `2152:9978` — Car detail. "Premium", "Porsche 911 Carrera", host "Sahil", 4 seats, Automatic, Petrol, 460 ₼/day, rating 4.8 (80). Actions: Dates, Details, Book

### EV
- `EV001` `2166:8785` — Rentbutik EV, ₼15/h · ₼0.25/min, Electric fleet, 1 min walk, **Swipe to start**
- `EV001.2` / `EV301` — swipe START states
- `EV002` `2166:8842` — detail: 4.8, 87% (380 km), Guidelines, Insurance, Reports, Fines, Get direction, "Go to Payment"
- `EV003` `2274:5298` — Payment: Wallet / Card, Total Pay
- `EV005` `2166:9247` / `EV007` `2166:9508` — Pre-trip: "Take exterior car photos", 4 or 6 slots, Submit photos
- `EV006` `2166:9395` — Active trip: Booking time 9:00-10:00 AM, Honda Civic ABC123, Current Tariff 0.15 manats/min, Pause Tariff 0.20, Unlock / Lock / End trip / Report / Extend the Tariff

### TRIPS
- `2152:10286` — My trips. Upcoming / Active booking / Past trips.
  "Mercedes-AMG GT, Aug 21 to Aug 21 · ₼380", "Rentbutik EV 6 · ₼120 Completed",
  "Golf cart 4, Aug 14 · ₼45", "Porsche 911 Carrera, Aug 08 · ₼460 Cancelled"

### CHATS
- `2152:10232` — Thread. "Salam Emin, welcome to Rentbutik.", "On my way, 10 minutes.",
  "Hasan Nabiyev — Host • Tesla Model Y", "Write a message..."
- `Frame 23460` `2152:10173` — Messages list. "Rentbutik Support", search

### WALLET
- `top-up-screen` `2152:10086` — Rentbutik card •••• 4242, amount chips. **Fix the currency.**

## SF Symbols already used as font glyphs in the real screens

`􀊫` magnifyingglass · `􀊱` slider.horizontal.3 · `􀆊` chevron.right · `􀆄` xmark · `􀉬` (a/c)

These are private-use characters in TEXT nodes — they need SF Pro to render and so will NOT
survive the Inter build. Replace each with an `Icon / <name>` vector component.

## STATES (lane 14)

Empty and error states. Pattern and copy rules: RULES.md section X.

| Screen | Title | Body | Action |
|---|---|---|---|
| No network | No connection | Rentbutik can't reach the network. Your trips and messages are saved and sync as soon as you're back online. | Try again |
| No chats | No messages yet | Book a car or list one of your own, and your conversations with hosts and renters appear here. | Browse cars |
| No trips | No trips yet | Book a car and it appears here — with your dates, your host and your keys. | Find a car |
| No listings | No cars listed | List your first car and start earning. Most hosts in Baku earn ₼400 to ₼900 a month. | List your car |
| Search no results | No cars match | Try widening your dates or clearing a filter. 34 cars are available nearby this week. | Clear filters (secondary) |
| Payment declined | Payment declined | Your bank declined the ₼499 charge. Nothing was taken and the car is held for 10 more minutes. | Use another card |
| Location denied | Location is off | Turn on location to see the cars closest to you. You can also search by address instead. | Open Settings |
| Wallet empty | Nothing in your wallet | Top up once and checkout is one tap. You can still pay by card on any booking. | Top up |
| Something went wrong | Something went wrong | That didn't work on our side, not yours. Nothing was charged and nothing was lost. | Try again |

## START (lane 13) — the single entry flow

Replaced `AUTH`, `ONBOARDING` and `REGISTRATION · CONNECTED UX FLOW` (32 screens) on
2026-09-19. Full spec: `SPEC/START.md`. Archived predecessors:
`SPEC/_ARCHIVED-registration-flows.md`.

| Screen | Title | Body | Actions |
|---|---|---|---|
| Welcome | Welcome to Rentbutik | Cars, electric and golf carts across Baku. Look around first — you only need an account to book. | Continue with MyGov · Use phone number · Browse without an account |
| Phone | What's your number? | We'll text you a six-digit code. There is no password to remember. | +994 field · Send code |
| Code | Enter the code | Sent to +994 50 123 45 67. | 6 digit boxes · Resend code in 0:24 · Continue |
| Identity | Verify once, ride anytime | A driving licence check is required before your first booking. Browsing needs nothing. | Tile: Continue with MyGov · Tile: Scan documents |
| Ready | You're all set, Emin | Verification usually clears within a few hours. We'll notify you the moment it does. | Start browsing |

