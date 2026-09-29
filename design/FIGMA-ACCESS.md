# How to work on this project without a Figma token

Written for the next AI agent — local, Xcode, or otherwise — picking this up.

## 1. Never ask Emin for a Figma personal access token

This is a standing instruction from day one of the project, not a preference:

> "Do not paste a Figma personal access token as a workaround. The remote server's support
> for bearer tokens is unverified, and `claude mcp login` is the supported path. A token in
> a shell command ends up in shell history and process listings."

It has already gone wrong once on this project with a **GitHub** token pasted into a chat
window. Do not repeat it with Figma.

**It also would not work.** Verified 2026-09-18: Figma's official remote MCP server is
**OAuth only** and does not accept a personal access token in any header. An unauthenticated
POST to `https://mcp.figma.com/mcp` returns 401, and a PAT does not change that. The day-one
instruction called bearer-token support "unverified"; it is now verified as unsupported.
See `FIGMA-MCP-CLIENT-SETUP.md`.

Why a PAT is the wrong tool here even when offered:

- It lands in `~/.zsh_history` and in `ps` output for every process on the machine.
- Figma PATs are **account-wide**, not file-scoped. A token for one file is a token for
  every file, team and draft on the account.
- It ends up pasted into a transcript, which is stored, synced and summarised.
- It is not needed. See §2.

If you find yourself writing "give me a token and I'll…", stop and read §2 instead.

## 2. You do not need Figma access to build this app

**The design is already written down.** That is the entire purpose of `design/`. The Figma
file is the picture; these files are the contract, and the contract is authoritative:

| File | What it gives you |
|---|---|
| `RULES.md` | The design laws, sections A–W. Read this first, every session. |
| `SCREENS.md` | Every screen, its content, its real strings and prices. |
| `SCHEME.md` | The flow — which screen leads where, organised in lanes. |
| `BUILD-PLAN.md` | Ordered phases. Each ends with a runnable app. |
| `BUILD-LOG.md` | What was built, and every defect found and why. |
| `SWIFTUI-README.md` | Token names, the asset catalogue, how the code half maps. |
| `CHECKLIST.md` | Per-screen definition of done. |

**Authority order when two documents disagree:** `RULES.md` > `SCREENS.md` > `BUILD-LOG.md`.

Fetching frames over the REST API and re-deriving colours and spacing from geometry gives
you *worse* information than `RULES.md` already contains, because the rules encode the
**reasons** — which combinations were tried, shipped and found broken. An API dump cannot
tell you that white text on gold measures about 2:1 and must never be used. `RULES.md` can,
in one line, in section B.

## 3. If you genuinely need to see the Figma file

Use the **Figma MCP server**, not the REST API.

- **Configuring a non-Claude-Code MCP client** (Bionic, Cursor, VS Code, Zed): read
  `FIGMA-MCP-CLIENT-SETUP.md` — both endpoints, the exact JSON, and how to tell which one
  your client can actually use.
- **Claude Code**: the plugin is already installed at user scope on this Mac and enabled in
  both projects. Full notes, including where the official docs are wrong, are in
  `../FIGMA-MCP-SETUP.md`. The short version:

```
claude mcp login figma
```

Browser-based OAuth. No token is typed, stored or transmitted through a chat window.

If your harness cannot host an MCP server, then you cannot see the file — and that is
fine. Build from §2 and ask Emin to screenshot anything ambiguous.

## 4. How the Figma side is actually built

Not by hand, and not through the REST API:

- **`use_figma`** runs JavaScript against the live document via the Figma Plugin API.
  Everything — frames, variables, components, prototype links — is scripted.
- **`design/tools/verify.js`** audits every screen: geometry, unbound fills, missing text
  styles, collapsed text, tab-bar clearance, white-on-gold contrast, lane containment,
  bento violations, paint base mismatches.
- **Vision on every screen, every time.** `await node.screenshot()` inside `use_figma`, then
  actually look at it. This is not optional. Six defects passed every automated check and
  were caught only by eye — multi-path SF Symbols rendering as blobs, review stars
  rendering white on cream, photo labels naming the wrong car.

**The rule that follows from that:** automated checks prove a screen is well-formed. They
cannot prove it is right. Look at every screen you touch.

## 5. Rate limits — the corrected numbers

An earlier version of these notes claimed `use_figma` was exempt from read limits because
Figma's own documentation implies it. **It is not exempt.** That assumption burned a
month's quota in an afternoon.

Current state: **Professional seat, 200 requests/day, 10/minute.** Batch aggressively —
one script that builds six screens costs one request; six scripts cost six.

## 6. The laws most likely to bite you

Full text in `RULES.md`. The ones that have already cost real rework:

1. **Never white text on gold.** Roughly 2:1 contrast. Section B.
2. **Photo cards are opaque, never glass.** The backdrop filter ignores `clipShape`.
3. **Bento is the layout law.** Does tapping it go somewhere? Then it is a tile, never a
   row with a chevron. Section U.
4. **Tab bar sits above everything, always**, and never scrolls with content.
5. **Maps are canvases, not panels.** Full-bleed, with content floating over them in
   bottom-anchored glass. Section P.
6. **Never size a control to English.** Check Azerbaijani, which runs longest.
7. **A bound paint still needs a matching base colour.** The base is the fallback; if it
   disagrees with the variable, the node renders the wrong colour in some contexts.
   This was latent on 368 nodes. Section W.

## 7. Before you finish a session

Update `STATE.md` and `BUILD-LOG.md`. The next agent reads them first and will trust them.
Both trees carry an identical copy of `design/` — if you change one, copy it to the other:

- `/Users/mac/Downloads/AI/figma/design/` — Figma side
- `/Users/mac/Documents/Rentbutik/design/` — Xcode side

They drifted once already: the Xcode copy sat 21 lines behind on `RULES.md` and was missing
the paint base-colour law entirely, so the app was being built against a stale contract.

## 8. Two agents, one repo — the collision that already happened

Both projects push to `git@github.com:Emin-dev/figma.git`, and their histories are
**unrelated**: the design branch `claude/figma-mcp-setup-793ffv` and the app branch `main`
share no common ancestor. They cannot be merged or compared, only kept side by side.

On 2026-09-18 an agent created `bionic/rentbutik-app` tracking `origin/main` and checked it
out **inside the design working tree** at `/Users/mac/Downloads/AI/figma`. Because the two
histories are unrelated, that replaced `design/` with the app branch's older snapshot —
RULES.md lost section X, BUILD-LOG.md lost 121 lines. Separately, `design/` inside the Xcode
project was overwritten with the same stale copies: 336 deletions against `HEAD`.

Nothing was lost, because both states were committed and pushed first. Recovery was
`git checkout <branch>` in one tree and `git checkout -- design/` in the other.

**The rules that follow:**

1. **Do not switch branches in a working tree you did not create.** Check
   `git rev-parse --show-toplevel` and `git status -sb` before any checkout. If the branch
   does not belong to your project, you are in the wrong directory.
2. **Commit and push before any git operation that moves HEAD.** That is the only reason
   this was recoverable.
3. **`design/` is mirrored, not shared.** Copy it deliberately; never restore it by checking
   out a branch that happens to contain an older copy.
4. **Check `git status` before assuming a file is stale.** A missing section is more often
   an uncommitted reversion in the working tree than a document that was never written.

