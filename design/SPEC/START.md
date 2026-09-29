# START

> One flow, five screens. Browse first, account only when it buys something, identity only before the first ride.

## Start / Welcome  `4159:385`

```
Content  [vertical 402x815]
  spacer-70
  App mark  [brand/solid r20 72x72]
    <Icon / key.fill>  text/on-gold
  spacer-22
  "Welcome to Rentbutik"  Type/Large title  text/ink
  spacer-8
  "Cars, electric and golf carts across Baku. Look around first — you only need an account to book."  Type/Body  text/ink-soft
  push
  Button / Primary  [horizontal gradient r25 366x50]
    "Continue with MyGov"  Type/Headline  text/on-gold
  spacer-12
  Button / Secondary  [horizontal surface/card r25 366x50]
    "Use phone number"  Type/Headline  text/gold
  spacer-16
  "Browse without an account"  Type/Headline  text/gold
  spacer-14
  "MyGov returns your identity and driving licence in one step."  Type/Caption  text/ink-faint
  spacer-34
```

## Start / Phone  `4159:406`

```
Content  [vertical 402x815]
  Nav bar  [horizontal 366x28]
    <Icon / chevron.left>  text/ink
    "Your number"  Type/Headline  text/ink
  spacer-26
  "What's your number?"  Type/Large title  text/ink
  spacer-6
  "We'll text you a six-digit code. There is no password to remember."  Type/Body  text/ink-soft
  spacer-24
  Field / Phone number  [vertical 366x71]
    "Phone number"  Type/Caption  text/ink-soft
    Input  [horizontal surface/card r18 366x50]
      "+994"  Type/Body  text/ink
      Divider  [line/hairline 1x22]
      "50 123 45 67"  Type/Body  text/ink-faint
  push
  Button / Primary  [horizontal gradient r25 366x50]
    "Send code"  Type/Headline  text/on-gold
  spacer-14
  "By continuing you accept the terms of service and privacy policy."  Type/Caption  text/ink-faint
  spacer-34
```

## Start / Code  `4159:427`

```
Content  [vertical 402x815]
  Nav bar  [horizontal 366x28]
    <Icon / chevron.left>  text/ink
    "Verify"  Type/Headline  text/ink
  spacer-26
  "Enter the code"  Type/Large title  text/ink
  spacer-6
  "Sent to +994 50 123 45 67."  Type/Body  text/ink-soft
  spacer-28
  Code entry  [horizontal 366x60]
    Digit 1..3  [vertical surface/card r16 53x60]   "4" "8" "2"  Type/Title 3  text/ink
    Digit 4     [vertical surface/card r16 53x60]   Caret  [brand/solid r1 2x24]     <- active
    Digit 5..6  [vertical surface/card r16 53x60]   Caret  [line/hairline r1 2x24]
  spacer-20
  "Resend code in 0:24"  Type/Subheadline  text/ink-soft
  push
  Button / Primary  [horizontal gradient r25 366x50]
    "Continue"  Type/Headline  text/on-gold
  spacer-34
```

## Start / Identity  `4159:448`

```
Content  [vertical 402x815]
  Nav bar  [horizontal 366x28]
    <Icon / chevron.left>  text/ink
    "Identity"  Type/Headline  text/ink
  spacer-26
  "Verify once, ride anytime"  Type/Large title  text/ink
  spacer-6
  "A driving licence check is required before your first booking. Browsing needs nothing."  Type/Body  text/ink-soft
  spacer-24
  Tile / MyGov  [vertical surface/card r26 366x132]
    Head  [horizontal 330x48]
      <Icon / checkmark.seal.fill>  brand/solid   (on brand/tint r24 48x48)
      Titles  [vertical 268x38]
        "Continue with MyGov"  Type/Headline  text/ink
        "Recommended · one tap"  Type/Caption  text/gold
    spacer-12
    "Returns your identity and driving licence in a single step. Nothing to scan or type."  Type/Subheadline  text/ink-soft
  spacer-14
  Tile / Documents  [vertical surface/card r26 366x132]
    Head  [horizontal 330x48]
      <Icon / person.text.rectangle>  brand/solid   (on brand/tint r24 48x48)
      Titles  [vertical 268x38]
        "Scan documents"  Type/Headline  text/ink
        "About two minutes"  Type/Caption  text/ink-soft
    spacer-12
    "Your ID, driving licence and a selfie. We check them ourselves."  Type/Subheadline  text/ink-soft
  push
  "You can browse and see prices before this step."  Type/Caption  text/ink-faint
  spacer-34
```

## Start / Ready  `4159:469`

```
Content  [vertical 402x815]
  spacer-90
  Hero  [vertical 366x213]   counterAxisAlignItems CENTER
    <Icon / clock.fill>  brand/solid   (on brand/tint r48 96x96)
    spacer-24
    "You're all set, Emin"  Type/Large title  text/ink
    spacer-10
    "Verification usually clears within a few hours. We'll notify you the moment it does."  Type/Body  text/ink-soft
  spacer-26
  Card / Meanwhile  [horizontal surface/card r26 366x68]
    <Icon / car.fill>  brand/solid   (on brand/tint r20 40x40)
    "You can browse cars and prices while you wait."  Type/Subheadline  text/ink
  push
  Button / Primary  [horizontal gradient r25 366x50]
    "Start browsing"  Type/Headline  text/on-gold
  spacer-34
```

## The flow

```
Welcome ──[Continue with MyGov]──> Identity ──> Ready
   │
   ├──[Use phone number]──> Phone ──> Code ──> Identity ──> Ready
   │
   └──[Browse without an account]──> Home
```

Identity can also be reached later, from the first booking attempt — that is the whole point
of browse-first. Nobody is walked through it on launch.

