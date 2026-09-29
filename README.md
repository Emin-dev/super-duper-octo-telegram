# Rentbutik v2

Independent iOS app copy with clearer pricing, recoverable payments and trip state that reflects user actions.

- **New design:** [Rentbutik v2](https://www.figma.com/design/xHHYrk0LxIUHo0IOadFCMD)
- **Source snapshot:** `Emin-dev/figma` at `773484691144a96a867ae778a0c1f9a2a74096ea`
- **Originals:** unchanged. This repository is the only code write target.

## Improvements

- One Decimal-based fare calculator for minute, hour and day tariffs; started hours, per-24-hour caps and plan minutes are consistent at settlement.
- Failed EV payments keep a visible payment-needed trip and a frozen total. Retry uses the same payment identifier.
- Wallet/card receipts retain the original funding split. Refunds and repeat charges are idempotent.
- Golf shows the ₼100 refundable deposit before Start and records it separately. Driver requests go to the desk rather than starting a self-drive rental.
- Trips uses actual session/persisted bookings, active rides and receipts. Cancellation updates the booking and the payment ledger.
- Six return-photo steps precede completion. Secondary EV options are collapsed; map cards have an opaque Reduce Transparency alternative.
- Trip, booking, wallet, receipt and plan data are saved atomically on device. Unreadable saved data is preserved for recovery.

## Run

Open `Rentbutik.xcodeproj` in an Xcode version with the iOS 27 SDK. Select the `Rentbutik` scheme and a simulator. For a device, set your own signing team. Three large source photos could not be transferred by the connector; those photo areas use SF Symbols (see handoff notes). The independent bundle identifier is `rentbutik.RentbutikV2`.

Debug builds are explicitly labeled **Demo**. Payments, authentication, QR unlock and capture/return confirmation remain simulated. Release builds block these simulated mutations; production services are not connected.

```sh
swift test
```

The package tests the Foundation domain layer independently of SwiftUI. GitHub Actions also runs app-state and UI tests in an iOS 27 simulator, plus Release-build safety checks. In Xcode, choose the `Rentbutik` scheme and **Product → Test**. See [testing instructions and coverage](TESTING.md) and the workflow result for actual validation status.

## Handoff

See [v2 notes](design/v2/IMPROVEMENTS.md). Older files under `design/` are inherited historical references and may describe earlier behavior or original Figma node IDs; v2 notes take precedence. Figma screens describe the improved key states, not a simulator capture of the full app.
