# Iconography

## Rule
SF Symbols only. No custom icons. No mixed icon sets.

## Audit of the existing file (page 07)

The file currently mixes FOUR icon systems:

| Set | Evidence | Verdict |
|---|---|---|
| SF Symbols | `car.2.fill`, `xmark`, `bolt`, `dollarsign`, `flag`, `calendar.day.timeline.leading` (pasted as vectors, names kept) | KEEP — reuse these |
| vuesax | `vuesax/linear/message` | REMOVE |
| svgrepo | `home-smile-angle-svgrepo-com 1` | REMOVE |
| Lucide / Feather | `chevrons-up-down`, `message-square`, `message-circle`, `chevron-left`, `settings` | REMOVE |

## Why SF Symbols cannot be generated from here

SF Pro does NOT render in the MCP execution environment (see STATE.md). SF Symbols delivered
as FONT glyphs therefore cannot be created programmatically. The symbols already in the file work
because they were pasted as VECTORS — vectors have no font dependency.

## Method

1. Reuse the SF Symbol vectors already in the file by cloning them.
2. For anything missing, Emin pastes it from the free SF Symbols app (macOS):
   open SF Symbols -> search -> Cmd-C -> paste into Figma. It arrives as a vector.
3. Each pasted symbol is named with its EXACT SF Symbol name so dev can write
   `Image(systemName: "car.fill")` with no translation step.

## Symbols needed for Phase 1 (Home + registration)

Paste these into a frame named `SF Symbols` on page `NEW`:

**Home modules**
- `car.fill` — Renter
- `bolt.car.fill` — Electric car
- `steeringwheel` — Golf car
- `key.fill` — Host

**Tab bar**
- `house.fill` — Home
- `message.fill` — Chats
- `suitcase.fill` — Trips
- `person.crop.circle.fill` — Profile

**Notifications**
- `flag.checkered` — ride ended
- `bolt.fill` — ride started

**Registration**
- `person.text.rectangle` — ID scan
- `creditcard` — driving licence
- `faceid` — selfie / liveness
- `checkmark.seal.fill` — verified
- `chevron.right`, `chevron.left`, `xmark`

Already present, reuse: `car.2.fill`, `xmark`, `bolt`, `dollarsign`, `flag`, `calendar.day.timeline.leading`

## SOLVED — automated extraction (2026-09-17)

SF Symbols.app is installed and ships a CLI at
`/Applications/SF Symbols.app/Contents/Executables/sfsymbols` with an `export` command.

`tools/sfsymbols.py` wraps it: export -> pull the `Regular-S` variant out of Apple's
design template -> tight bbox -> rounded path data -> compact JSON ready for
`figma.createNodeFromSvg()`.

```bash
venv/bin/python tools/sfsymbols.py car.fill house.fill bolt.fill
```

Symbols arrive as VECTORS, so the SF Pro rendering problem does not apply.

**Do NOT try to inject all ~9,000 symbols.** At roughly 700 bytes of path data each that is
~6MB, far past the 50,000-char limit on a single `use_figma` call, and it would bloat the file.
Extract on demand, ~15 per call.

### Done
`car.fill`, `bolt.car.fill`, `steeringwheel`, `key.fill` — components under `Icon / <name>`
in the `SF Symbols` frame on page `NEW`, placed in the Home module tiles.
Each component description carries `Image(systemName: "<name>")` for the dev team.

### Extracted, not yet injected
`house.fill`, `message.fill`, `suitcase.fill`, `person.crop.circle.fill`, `flag.checkered`,
`bolt.fill`, `chevron.right`, `chevron.left`, `person.text.rectangle`, `creditcard`,
`faceid`, `checkmark.seal.fill`

## Added 2026-09-18 — state screens

| Symbol | Component | Used by |
|---|---|---|
| `wifi.slash` | 4125:315 | States / No network |
| `location.slash.fill` | 4125:318 | States / Location denied |
| `creditcard.trianglebadge.exclamationmark` | 4125:321 | States / Payment declined |

All three are multi-path symbols. Extracted with `tools/sfsymbols.py`, then joined into a
**single** `<path fill-rule="evenodd" clip-rule="evenodd">` before `figma.createNodeFromSvg()`.
Filling the sub-paths separately renders a solid blob — the slash and the badge disappear.

Verified by screenshot at 5-6x before being placed on any screen. Automated checks cannot
catch a blob; only looking at it can.

