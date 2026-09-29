# Xcode validation

Open `Rentbutik.xcodeproj` in Xcode 27, select the shared `Rentbutik` scheme and an iOS 27 iPhone simulator, then choose **Product → Test** (⌘U).

The workflow runs these suites on every push and pull request:

| Suite | Coverage |
| --- | --- |
| Swift package: 7 tests | Fare boundaries, plan minutes, payment declines, idempotency and refunds |
| Debug app: 19 tests | Trip lifecycle, settlement recovery, deposits, cancellation, persistence/corrupt data, registration gate and navigation |
| Debug UI: 12 tests | Tabs, browse-first registration, EV photos/lock/extension/return, relaunch, payment recovery, Golf, renter/transfer bookings, host navigation, chat and larger text |
| Release app: 3 tests | Demo charges, ride starts and verification stay blocked; demo snapshots are not loaded |

Command-line equivalents (replace the destination with an installed iPhone simulator):

```sh
swift test
xcodebuild -project Rentbutik.xcodeproj -scheme Rentbutik -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
xcodebuild -project Rentbutik.xcodeproj -scheme Rentbutik -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:RentbutikTests ENABLE_TESTABILITY=YES CODE_SIGNING_ALLOWED=NO test
```

GitHub Actions discovers an available simulator rather than relying on that example device name. Download the `Xcode-*-results` and `Screenshots-*` artifacts from a run to inspect failures or screenshots. `.xcresult` bundles open in Xcode.

UI fixtures require `--ui-testing` and are compiled only into Debug. They use a separate temporary snapshot, never the ordinary demo snapshot. Individual flow tests can seed a verified demo identity or a failed payment; the guest test exercises the actual registration gate. Screens and Store methods are the same ones used by the app.

## Limits

Passing these suites is not full production certification. They test the current demo and selected important paths, not every possible interaction. Real camera/QR recognition, location accuracy, vehicle hardware, backend authentication, payment provider callbacks, interruptions, VoiceOver and physical-device behavior still require integration/device testing. Larger-text testing checks reachability, not comprehensive visual or accessibility compliance. Azerbaijani/Russian translations and the three unavailable vehicle photos remain incomplete.
