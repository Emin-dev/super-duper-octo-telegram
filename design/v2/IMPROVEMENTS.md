# Rentbutik v2 — implementation notes

## Provenance and scope

Copied application source, Xcode project and runtime assets from `Emin-dev/figma` commit `773484691144a96a867ae778a0c1f9a2a74096ea`. User-specific Xcode settings and old screenshot exports were excluded. The new repository is public; the original code and Figma file were not edited.

The design focuses on eight key states: Home, EV selection, active trip, payment recovery, Golf booking, rental checkout, return photos, receipt. It uses editable layers, SF Pro, SF Symbols and Apple native components. It is a handoff specification, not a claim that every original screen was redrawn.

## Important behavior

- A stopped EV ride retains `paymentPending` on decline. The meter freezes at its first settlement attempt, including the plan minutes used then. Successful retry cannot charge twice.
- Golf rental and refundable deposit have separate payment IDs. The local demo refunds the deposit once on return completion; production requires server-confirmed inspection/settlement.
- Request-to-book car rentals do not charge before acceptance. This copy does not implement a remote host-acceptance/payment workflow.
- Actual records replace seeded trip history in the live Trips tab. Empty states are honest. Catalog examples remain available to previews.
- Rental dates retain the original two-hour grace rule; EV/Golf use their own block-pricing rules. These policy values need business approval before production launch.
- Payment and booking state persists locally in an atomic, protected JSON snapshot. This is demo durability, not server reconciliation or a crash-safe financial transaction database.
- New threads route to the selected host instead of a fixed unrelated host. Message contents, notifications, authentication and hold timers are not persisted in the financial snapshot.
- Debug retains simulated flows with a global demo label. Release blocks simulated verification, unlock and payment. Real identity, SMS, gateway, vehicle locking, location/return validation, insurance excess terms and photo upload/storage remain integration work.
- Signing team is cleared and bundle ID is isolated so this copy does not replace the original app on a device.

## Validation

GitHub run [36625835710](https://github.com/Emin-dev/super-duper-octo-telegram/actions/runs/36625835710) passed all seven Swift package tests. These tests cover minute rates, plan coverage, hourly boundaries, daily caps, rental grace, declined wallet/card splits, idempotent retry/refund, and conflicting payment IDs. CI also attempts an iOS simulator build. This execution environment has no Swift or Xcode runtime; CI results are authoritative for the checks that run there.

Manual device checks still required: Dynamic Type, VoiceOver, Reduce Transparency, light/dark mode, background/relaunch during a ride, cancellation, return capture and declined-card recovery. The current Figma spec does not replace those device checks.

## Asset transfer limitation

The connector returned empty content for three source images larger than 1 MB: `evSuv.png`, `golfCartVentura.png` and `mercedesAMGGT.png`. They are excluded instead of shipping corrupt files; `PhotoFill` displays the existing SF Symbol fallback. Restore those images into their original asset sets from the pinned source commit to restore the photography. No different car photograph is substituted.

## Validation results at app import

- Commit `8270d5f`: all 46 Swift files parse; seven domain tests pass in [run 36626914735](https://github.com/Emin-dev/super-duper-octo-telegram/actions/runs/36626914735).
- The initial simulator build was blocked before compilation: the default macOS runner selected Xcode 26.6, which cannot read project format 110. The iOS job now uses the official `xcode-27` preview runner label, retaining the app’s iOS 27 target.
- Eight Figma screens were visually reviewed. Six primary prototype actions connect the key states. The Figma screens are editable specifications rather than simulator screenshots.
