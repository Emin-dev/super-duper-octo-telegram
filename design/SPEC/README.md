# Screen specs — the design, readable without Figma

One file per lane. Every screen is dumped as its real node tree with the actual
text, the text style, the colour token, the SF Symbol and the geometry.

This exists so an agent with **no Figma access** can build the app correctly.
Read the lane file for the screen you are building. Do not ask for a Figma
token — see `../FIGMA-ACCESS.md`.

## How to read a line

```
Button / Primary  [horizontal gradient r25 300x50]
  "Try again"  Type/Headline  text/on-gold
```

| Part | Meaning |
|---|---|
| `Button / Primary` | layer name — mirror it in SwiftUI |
| `[horizontal …]` | auto-layout direction, fill token, corner radius, size in pt |
| `"Try again"` | the literal string, already final copy |
| `Type/Headline` | the text style — see SWIFTUI-README.md for the SF Pro mapping |
| `text/on-gold` | the colour token — never a hex value |
| `<Icon / wifi.slash>` | an SF Symbol instance, by its real SF Symbols name |
| `spacer-20` | a 20pt gap |

Tab bar entries show which tab is selected: the selected one carries
`surface/glass-clear` and `text/gold`, the rest `text/ink-soft`.

`_archived/` holds specs for screens that have been deleted. Do not build from those.

Regenerate with `tools/spec-export.js` when screens change.

