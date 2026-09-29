# Real Apple Maps in Figma

`tools/mapsnap.swift` renders **genuine Apple Maps imagery** with MapKit's `MKMapSnapshotter`
and writes PNGs. Not a third-party map, not a mockup — Apple's own cartography, licensed for
use while developing an Apple-platform app.

## Requirements
Swift (Command Line Tools is enough — no full Xcode) and `MapKit.framework`. Both present on
this Mac: Swift 6.4, `/Library/Developer/CommandLineTools`.

## Run
```bash
swift tools/mapsnap.swift /path/to/output/dir
```

Edit the `jobs` array for coordinates, radius, size and light/dark.

## Key settings

```swift
o.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat,
                                                      emphasisStyle: .muted)
```
`.muted` is the desaturated treatment RULE B9 asks for — it comes from Apple rather than a
filter applied afterwards.

```swift
o.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
```
Renders the real Apple Maps dark style, so dark-mode screens get a true dark map.

Render at 2x (804 x 1748 for a 402 x 874 screen) so the map stays sharp.

## Coordinates in use

| Map | lat, lon | radius |
|---|---|---|
| Baku centre — Cars near you, EV | 40.3725, 49.8430 | 1800 m |
| Sea Breeze — Golf | 40.5800, 49.9600 | 2200 m |

**Getting coordinates wrong is silent and obvious only in the render.** A first attempt at
40.6420, 49.8200 landed in the Caspian and produced a 28 KB all-blue image. File size is a
quick tell: a real map of a built-up area runs 400 KB+, open water is under 50 KB.

## Getting them into Figma

1. `upload_assets` with `count` and `nodeIds` returns one single-use URL per asset
2. `curl -F "file=@map.png;type=image/png" "<submitUrl>"`
3. **Check the response for `placedOnNodeId`.** If it is absent the image uploaded but was NOT
   attached to the node — take the returned `imageHash` and set the fill yourself:
   `node.fills=[{type:'IMAGE', imageHash:'…', scaleMode:'FILL'}]`

## Still to render
A dark Baku map exists (`baku-dark.png`) but is not yet placed — it is for the dark variants
of Cars near you, EV Unlock and EV Active trip.

