# Rentbutik iOS — Design Rebuild

**Read `RULES.md` and `STATE.md` at the start of every session, before touching Figma or code.**

New agent, or working without Figma access? Start with **`FIGMA-ACCESS.md`**.

| File | Purpose |
|---|---|
| `XCODE-TASKS.md` | Live task queue for the Xcode session: logic bugs with file:line, missing Figma screens, production list. Read first. |
| `FIGMA-HANDOFF-NOTES.md` | Every action in the Figma file: motion, haptic, destination (239 rows). |
| `figma-ref/` | 1x image of every Figma screen frame, with node IDs. |
| `RULES.md` | Non-negotiable design laws, sections A–W. Never violate without written sign-off from Emin. |
| `FIGMA-ACCESS.md` | How to work on this project — with or without Figma access. Read before asking for credentials. |
| `FIGMA-MCP-CLIENT-SETUP.md` | Connecting any MCP client (Bionic, Cursor, VS Code) to Figma. OAuth only — a PAT will not authenticate. |
| `BIONIC-BRIEF.md` | Paste-ready brief for a local AI that will **edit** Figma: which endpoint, which file, and the API rules that stop scripts rolling back. |
| `SPEC/` | Every screen exported as text: real copy, text styles, tokens, SF Symbols, geometry. Build from this with no Figma access. |
| `SCREENS.md` | Every screen, its content, its real strings and prices. |
| `SCHEME.md` | The flow — which screen leads where, organised in lanes. |
| `BUILD-PLAN.md` | Ordered build phases for the iOS app. Each ends with a runnable app. |
| `SWIFTUI-README.md` | Token names, asset catalogue, how the code half maps to Figma. |
| `PLAN.md` | Phased design roadmap. |
| `STATE.md` | Where we are right now. Update at the end of every session. |
| `CHECKLIST.md` | Per-screen definition of done. |
| `BUILD-LOG.md` | What was built, and every defect found, with the reason. |
| `ICONS.md` | The SF Symbols actually used, and how they were extracted. |
| `GAPS.md` | What is still missing, in priority order. |

**Authority order when two documents disagree:** `RULES.md` > `SCREENS.md` > `BUILD-LOG.md`.

## Figma target

- File key `pNlCu0GHsvsJ2Uxb2DLghP` — "RentbutikNEW"
- Build page: **`iOS 27 · SCHEME V3`** (page id `4007:6935`). It was renamed from `NEW` —
  older notes in this directory still say `NEW`.
  **Never edit `07 - Scheme` or `08 - Archived`.**
- Variable collection: `Theme`, with real Light and Dark modes.

## Access constraints (corrected 2026-09-18)

- Seat: **Professional**. **200 requests/day, 10/minute.**
- `use_figma` is **NOT exempt** from these limits. An earlier note here claimed it was,
  on the strength of Figma's own docs. That assumption burned a month's quota in an
  afternoon on the previous Starter seat.
- Batch aggressively: one script that builds six screens costs one request.
- Use `await node.screenshot()` inside `use_figma` for visual checks rather than spending
  separate `get_screenshot` calls.
- The document cannot be renamed via API. Emin must do it in the UI.

## Two copies of this directory

`design/` is mirrored in both trees and they must stay identical:

- `/Users/mac/Downloads/AI/figma/design/` — Figma side
- `/Users/mac/Documents/Rentbutik/design/` — Xcode side

If you change one, copy it to the other before you finish.

