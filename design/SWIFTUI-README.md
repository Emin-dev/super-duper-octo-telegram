# Rentbutik — SwiftUI

The code half of the design contract. Every token here matches the `Theme` variable
collection in Figma (`pNlCu0GHsvsJ2Uxb2DLghP`) by name and value.

## Status

| File | Purpose |
|---|---|
| `Design/Theme.swift` | Colour, geometry, motion, type, haptics. 150 lines, parses clean. |
| `Components/Buttons.swift` | `RentbutikPrimaryButton`, `RentbutikSecondaryButton`, `PressScale` |
| `Components/Tile.swift` | `RentbutikTile` — the bento unit |
| `Components/TripStatus.swift` | `TripStatus` enum + `TripStatusChip` |

## Running it

**Xcode is NOT installed on this Mac** — only Command Line Tools. The code is written and
syntax-checked with `swiftc -parse`, but building and running needs full Xcode (~10 GB,
free from the App Store).

Once installed: File -> New -> Project -> iOS App (SwiftUI), then drag `Sources/Rentbutik`
in. The colour tokens expect an asset catalogue with these named colours, each with a
Light and Dark appearance:

`ink` `inkSoft` `goldText` `danger` `card` `background` `hairline` `brandTint`

Values are in the doc comments in `Theme.swift`.

## Why SwiftUI matters here

Figma cannot render Liquid Glass — it has no refraction, no adaptive tinting, and cannot
honour the user's transparency slider. It also cannot show real haptics or real spring
motion. Running this on device is the only way to judge those.

## The contract

Changing a value in `Theme.swift` without changing the matching Figma variable breaks the
contract, and vice versa. The mapping is 1:1 and deliberate.

