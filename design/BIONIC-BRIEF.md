# Brief for a local AI that will EDIT the Figma file

Paste `## The prompt` below into Bionic. Everything after it is the detail that prompt refers to.

Verified 2026-09-22 by reading the Figma MCP server manifest on this Mac.

## Read first: editing needs the REMOTE server

The two endpoints are not interchangeable.

| | Remote `https://mcp.figma.com/mcp` | Desktop `http://127.0.0.1:3845/mcp` |
|---|---|---|
| Write tools | **`use_figma`**, `create_new_file`, `generate_figma_design`, `upload_assets`, `add_code_connect_map`, `send_code_connect_mappings`, `generate_diagram` | none — read-focused |
| Read tools | `get_design_context`, `get_metadata`, `get_screenshot`, `get_variable_defs`, `get_libraries`, `search_design_system`, `whoami`, … | a narrower set |
| Auth | OAuth, browser flow, no token typed | rides on the signed-in desktop app |
| Figma desktop app | not needed | required, and **not installed on this Mac** |

18 tools on the remote server, 7 of them write-capable. **`use_figma` is the one that edits
anything**, and it is remote-only. So: to edit, Bionic must complete the OAuth flow. There is
no token path — see `FIGMA-ACCESS.md`.

---

## The prompt

> You have Figma MCP access. Configure the **remote** server — editing requires it:
>
> ```json
> { "mcpServers": { "figma": { "type": "http", "url": "https://mcp.figma.com/mcp" } } }
> ```
>
> Some clients want `httpUrl` instead of `url`, plus `"oauth": { "enabled": true }`. Complete
> the OAuth flow in the browser. **Never ask Emin for a personal access token** — mcp.figma.com
> is OAuth only and returns 401 for a PAT, so it would not work even if he gave you one.
>
> Confirm you are connected by calling `whoami` before anything else.
>
> **Ask Emin which file before you edit anything.** There are two, and they do not share a
> design system:
>
> | File | Key | Page |
> |---|---|---|
> | RentbutikNEW | `pNlCu0GHsvsJ2Uxb2DLghP` | `iOS 27 · SCHEME V3`, id `4007:6935` |
> | Design flow Final (Copy) | `wNrzVtYCjkYsOLORM3sgVv` | `Production flow`, id `0:1` |
>
> In RentbutikNEW, **never touch pages `07 - Scheme` or `08 - Archived Scheme V1`** — the old
> design, kept for reference.
>
> **The token and style names in `RULES.md` apply to RentbutikNEW only.** Read the other
> file's own collections and styles before writing to it — see "The two files are not the
> same" below.
>
> **Before your first edit, read in this order:** `design/RULES.md` (all of it — sections A
> through Y are non-negotiable and several were learned from bugs that shipped),
> `design/SPEC/` for the screen you are touching, then `design/BUILD-LOG.md` for the node ids
> and the mistakes already made.
>
> **Every edit goes through `use_figma`**, which runs JavaScript against the live document.
> The rules in `design/BIONIC-BRIEF.md` under "Writing to Figma without breaking it" are not
> optional — each one corresponds to a script that already failed here.
>
> **Look at every screen you touch.** Call `await node.screenshot()` at the end of the script
> and actually read the image. Six defects in this file passed every automated check and were
> caught only by eye.
>
> **Tell Emin what you changed and what you could not verify.**

---

## Writing to Figma without breaking it

Each of these cost a rolled-back script here. `use_figma` is all-or-nothing: one throw and the
whole script reverts.

1. **Colours are 0–1, not 0–255.** `{r:1,g:0,b:0}` is red.
2. **`figma.currentPage = page` throws.** Use `await figma.setCurrentPageAsync(page)`, and at
   most once per script. Page context resets to the first page on every call, so set it every
   time.
3. **Fills and strokes are read-only arrays.** Clone, modify, reassign — never mutate in place.
4. **`setBoundVariableForPaint` returns a NEW paint.** Capture and reassign it, and give the
   paint a base colour equal to the token's own resolved value. A base that disagrees with the
   variable renders the wrong colour in some contexts — that was latent on 368 nodes here.
   RULES section W.
5. **Load the font before touching text.** `await figma.loadFontAsync(node.fontName)` before
   writing `characters`, or you get `Cannot write to node with unloaded font`. Inter is the
   build font; the style is `Semi Bold`, not `SemiBold`.
6. **SF Pro does not render in this environment.** Every text node uses a `Type/*` style bound
   to Inter. Do not "fix" this by switching to SF Pro — it returns zero glyph metrics. The swap
   happens once, at handoff.
7. **`node.fill` throws on a FRAME.** It is not a missing property, it is a TypeError. Never
   probe a property to work out what kind of node you have.
8. **`appendChild` first, then `layoutSizingHorizontal = 'FILL'`.** FILL and HUG are rejected
   until the node is inside an auto-layout parent.
9. **Wrapping text needs `textAutoResize = 'HEIGHT'` and an explicit width.** FILL alone
   collapses the node to near-zero width.
10. **Section children use RELATIVE coordinates.** Positioning a frame over a Section does not
    put it in the Section — `appendChild` does.
11. **Never hardcode a node id across a destructive change.** Find nodes by traversal from
    something stable. Buttons cloned by id broke here when the lane holding them was deleted.
12. **`figma.notify()` throws. `console.log` is invisible.** Return a value — it is the only
    output channel. Always return the ids of everything you created or mutated.

## Rate limits

Professional seat: **200 requests/day, 10 per minute**, shared across every client on this
account. `use_figma` is **not** exempt. One script that builds six screens costs one request;
six scripts cost six. Batch. Prefer `design/SPEC/` over live reads for anything that does not
need current pixels.

## Verify before you call it done

```
node design/tools/verify.js      # set LANE_ID, paste as a use_figma body
```

It checks geometry, unbound fills, missing text styles, collapsed text, tab-bar clearance,
white-on-gold contrast, icon integrity, lane containment and paint base mismatches. Passing it
means a screen is well-formed. **It does not mean the screen is right** — that is what your
eyes are for.

## Git: do not move HEAD in a tree you did not create

Both projects push to `git@github.com:Emin-dev/figma.git` and their histories are **unrelated**:

| Tree | Branch |
|---|---|
| `/Users/mac/Downloads/AI/figma` | `claude/figma-mcp-setup-793ffv` — the design |
| `/Users/mac/Documents/Rentbutik` | `main` — the Xcode app |

Checking one branch out inside the other tree replaces `design/` with the wrong snapshot. That
happened on 2026-09-18 and cost RULES.md its newest section in both trees. Run
`git rev-parse --show-toplevel` and `git status -sb` before any checkout, and commit before any
command that moves HEAD. `FIGMA-ACCESS.md` section 8.

## `design/` is mirrored in both trees

If you change it in one, copy it to the other before you finish. They must stay identical.


---

## The two files are not the same

Probed 2026-09-22. If you carry names from one into the other, every binding silently misses.

| | RentbutikNEW `pNlCu0GHsvsJ2Uxb2DLghP` | Design flow Final (Copy) `wNrzVtYCjkYsOLORM3sgVv` |
|---|---|---|
| Pages | 7 | 1 — `Production flow` |
| Text styles | `Type/*` on Inter (`Type/Headline`, `Type/Body`…) | `iOS · *` (`iOS · Large Title / Bold`, `iOS · Headline`, `iOS · Callout`…) |
| Variable collections | `Theme` (35 vars, Light + Dark), `Rentbutik`, `Theme Dark` | `Home · Page10 reference` (19 vars, Light + Dark), `Prototype · Preferences` (23 vars) |
| Colour tokens | `text/ink`, `surface/card`, `brand/solid`, `status/danger`… | different set — read them, do not assume |
| Organisation | 13 lanes, every screen inside a Section | 7 sections **plus loose frames sitting directly on the canvas** |

**Discover before you write.** One read-only call answers it:

```js
const cols = await figma.variables.getLocalVariableCollectionsAsync();
const vars = await figma.variables.getLocalVariablesAsync();
const styles = await figma.getLocalTextStylesAsync();
return {
  collections: cols.map(c => ({ id: c.id, name: c.name, modes: c.modes.map(m => m.name) })),
  variables: vars.map(v => ({ id: v.id, name: v.name, type: v.resolvedType })),
  textStyles: styles.map(s => ({ id: s.id, name: s.name }))
};
```

### Known untidiness in Design flow Final (Copy)

Not defects to "fix" unprompted — tell Emin and ask:

- **Six frames named `T01 · Trips`**, several of them loose on the canvas rather than inside
  `01 · Main tabs`. Duplicates, or variants that were never named apart.
- **`EV01 · Select vehicle` and a `status-pill`** also sit loose on the canvas.
- **A stray 4x4 frame named `Frame`** — the default-name pattern the verifier flags.

The verifier in `tools/verify.js` will report `scheme/not-in-lane` for every loose frame,
because in the RentbutikNEW convention a screen outside a Section is a bug. That convention
may simply not be this file's convention. **Ask before reorganising someone's canvas.**

