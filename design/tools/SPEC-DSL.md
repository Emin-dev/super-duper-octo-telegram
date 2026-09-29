# Screen spec DSL

A generic renderer turns compact JSON into a finished screen. A list/form screen drops from
~110 lines of layout code to ~20 lines of data. Built and proven on
`Profile / Settings`, `Profile / Help`, `Profile / All notifications`.

## Spec shape

```js
{
  name: 'Profile / Settings',
  tabbar: true,                          // adds 96pt clearance + the tab bar
  nav: { title: 'Profile', back: false, action: 'Done' },
  blocks: [
    { t:'gap', h:18 },
    { t:'title',   text:'How can we help?' },      // Type/Large title
    { t:'section', text:'Account' },               // Type/Title 3
    { t:'body',    text:'…' },                     // Type/Body, ink-soft
    { t:'caption', text:'…', align:'CENTER' },     // Type/Caption, ink-faint
    { t:'card', rows:[
        { icon:'creditcard', title:'Payment methods',
          sub:'optional second line', value:'•••• 4242',
          trailing:'chevron' | 'toggle', on:true, danger:false }
    ]},
    { t:'button', label:'Message support', style:'primary'|'secondary'|'destructive' }
  ]
}
```

Rendered with `render(spec, section, col, row)`. Screens land at
`x = 820 + col*532`, `y = 170 + row*1104`, matching SCHEME.md.

## What the renderer guarantees

- Every text node gets a `Type/*` style — never an ad-hoc size
- Every fill is variable-bound — never a raw hex
- `icon` names are SF Symbol names, resolved from the `SF Symbols` library
- Card rows get automatic hairline dividers between them, none after the last
- `tabbar: true` adds the 96pt clearance AND the bar, with the bar as the last child
- Content taller than 874 is wrapped in a Scroll area so the bar stays put

Because of this, **DSL-rendered screens pass the verifier by construction.**

## What it does NOT cover

Bespoke layouts: maps, calendars, camera viewfinders, chat bubbles, photo grids,
swipe controls. Those are still hand-built — no DSL saves you there, and trying to
generalise them would make the renderer worse than the code it replaces.

Roughly 60% of the remaining screens are list/form shaped and suit the DSL.

## The renderer

Lives inline in the `use_figma` call. Copy it from the call that built the PROFILE lane,
or rebuild it from this spec — it is ~90 lines and depends only on `Type/*` styles,
the `Theme` collection and the `SF Symbols` library.

