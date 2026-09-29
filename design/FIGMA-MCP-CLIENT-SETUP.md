# Connecting any MCP client to Figma

For an AI app that supports MCP (Bionic, Cursor, VS Code, Zed, or anything with an
`mcpServers` config) and needs to read this project's Figma file.

Verified 2026-09-18 against Figma's own docs and by probing the endpoints from this Mac.

## The headline: a personal access token will not work

The official remote server is **OAuth only**. Figma does not accept a personal access
token for MCP — not as `Authorization: Bearer figd_…`, not as `X-Figma-Token`.

Probed from this machine:

```
GET  https://mcp.figma.com/mcp  -> 405   (alive; the endpoint wants POST)
POST https://mcp.figma.com/mcp  -> 401   (unauthenticated; OAuth required)
```

So the day-one instruction — "the remote server's support for bearer tokens is
unverified" — is now **verified: not supported**. A PAT would not merely be unsafe to
paste, it would not authenticate. Asking for one gets you nothing.

Third-party MCP servers do accept a PAT. They also mean handing an account-wide Figma
credential to someone else's host. Don't.

---

## Option A — remote server (Figma's recommendation)

No Figma desktop app needed. Requires the client to support **OAuth for remote MCP
servers**; it opens a browser, you approve, the client stores the grant. No token is
typed anywhere.

```json
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    }
  }
}
```

Some clients want the key `httpUrl` instead of `url`, and some need `"oauth": { "enabled": true }`.
Both spellings are in use; if one is rejected, try the other:

```json
{ "mcpServers": { "figma": { "httpUrl": "https://mcp.figma.com/mcp", "oauth": { "enabled": true } } } }
```

**If the client cannot do OAuth, Option A is impossible.** Go to Option B.

---

## Option B — desktop server (no OAuth flow in the client)

Authentication rides on the signed-in Figma desktop app, so the client needs nothing but
a URL. This is usually the easier path for a local app.

**Prerequisite: Figma desktop is NOT installed on this Mac.** Checked — `/Applications/Figma.app`
does not exist and nothing listens on port 3845. Install it from figma.com/downloads first.

Then:

1. Open the Figma desktop app and open the file (`pNlCu0GHsvsJ2Uxb2DLghP`).
2. Switch to **Dev Mode** — `Shift+D`.
3. In the inspect panel, find the **MCP server** section and click
   **Enable desktop MCP server**.

```json
{
  "mcpServers": {
    "figma-desktop": {
      "url": "http://127.0.0.1:3845/mcp"
    }
  }
}
```

Confirm it is actually up before wiring anything:

```
lsof -nP -iTCP:3845 -sTCP:LISTEN
```

Listening means it works. Nothing means the toggle is still off, or Figma desktop is closed.
The server only runs while the app is running.

---

## Which one to choose

| | Remote | Desktop |
|---|---|---|
| Figma desktop app | not needed | **required, and not installed here** |
| Client must support OAuth | **yes** | no |
| Works headless / in CI | yes | no |
| Token typed anywhere | never | never |
| Feature coverage | broadest | narrower, read-focused |

Try Option A first. If the client has no OAuth support, install Figma desktop and use B.

## Before you configure anything: check what you already have

On this Mac the Claude Code Figma plugin is installed at **user scope**
(`~/.claude/plugins/installed_plugins.json`, `"scope": "user"`) and the Xcode project's
`.claude/settings.json` already enables `figma@knowledge-work-plugins`. Any client that
reads Claude Code plugin config therefore already has these tools.

So enumerate your real tools before concluding you have no Figma access:

> List every tool you have whose name contains "figma". Do not guess — enumerate your
> actual tools. Then call `whoami`.

## Rate limits

Professional seat: **200 requests/day, 10/minute**, shared across every client connected
to this account. `use_figma` is **not** exempt. Two agents hammering the file will exhaust
it. Batch, and prefer `SPEC/` (the design exported as text) for anything that does not
need live pixels.

## Still no access?

Build from `SPEC/` and `RULES.md`. See `FIGMA-ACCESS.md` — the contract is written down,
and it carries the reasons that a node dump cannot.

