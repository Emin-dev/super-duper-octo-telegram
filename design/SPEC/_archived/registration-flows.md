# Archived 2026-09-19 — the three registration flows, before they were replaced

Emin asked for `AUTH`, `ONBOARDING` and `REGISTRATION · CONNECTED UX FLOW` to be removed and
replaced by **one simple flow**. This file is what they said, captured immediately before
deletion, so nothing is lost.

**Why there were three.** They accumulated:

| Lane | Screens | Origin |
|---|---|---|
| `AUTH` | 5 | splash, welcome, sign up, sign in, verification pending |
| `ONBOARDING` | 9 | the MyGov / documents identity flow |
| `REGISTRATION · CONNECTED UX FLOW` | 18 | built later by another agent; re-covered the same ground |

32 screens for "make an account". The replacement is `START`, 5 screens.

The good ideas worth keeping are recorded below and were carried into `START`: the MyGov vs
documents choice as two bento tiles, the four-step indicator, the viewfinder with its guide
rectangle and caption, and the "you can keep browsing meanwhile" promise.

---

## ONBOARDING — full structure

### Register / Choose method

```
Nav bar: <chevron.left> "Verify your identity"
"One tap, or your documents"  Type/Large title  text/ink
"You can browse freely. Verification is only needed before your first ride."  Type/Body  text/ink-soft

Path / MyGov  [vertical surface/card r30 366x222]
  <checkmark.seal.fill> brand/solid
  "Continue with MyGov"  Type/Headline
  "Recommended · one tap"  Type/Caption  text/ink-soft
  "MyGov returns your identity and driving licence in a single step. Nothing to scan or type."
  Button / Primary  "Open MyGov"

Path / Documents  [vertical surface/glass r30 366x337]
  "Use my documents"  Type/Headline
  "Four steps, about two minutes."
  Steps: <person.text.rectangle> "ID document" · <creditcard> "Driving licence"
         <person.crop.circle.fill> "Selfie check" · <checkmark.seal.fill> "Your details"
  Button / Secondary  "Start with documents"
```

### Register / MyGov handoff

```
Nav bar: <chevron.left> "Verify your identity"
<checkmark.seal.fill> brand/solid
"Opening MyGov"  Type/Large title
"Confirm your identity in the MyGov app. You will return here automatically."
Progress: 3 dots, first brand/solid, rest text/ink-faint
Button / Secondary  "Cancel"
```

### Register / MyGov success

```
Nav bar: <chevron.left> "Verified"
<checkmark.seal.fill> brand/solid
"You are verified"  Type/Large title
"MyGov confirmed your identity and driving licence."

Card / Returned data  [vertical surface/card r30 366x143]
  "Returned by MyGov"  Type/Caption  text/ink-soft
  Full name       -> "Emin Mammadov"
  ID number       -> "AZE ******* 42"
  Driving licence -> "B · valid to 2031"

Button / Primary  "Continue"
```

### Register / MyGov failure

```
Nav bar: <chevron.left> "Verify your identity"
<exclamationmark.triangle.fill>  status/danger
"MyGov did not confirm"  Type/Large title
"The session timed out or was cancelled. Nothing was saved and you can try again."
Button / Primary    "Try MyGov again"
Button / Secondary  "Use my documents instead"
```

### Register / ID scan  ·  Licence scan  ·  Selfie

All three share one structure — this is the pattern worth keeping:

```
Nav bar: <chevron.left> "Step N of 4"
Step indicator  [horizontal 366x4]   four 87x4 bars, r2
                completed = brand/solid, pending = line/hairline
"<title>"  Type/Large title
"<instruction>"  Type/Body  text/ink-soft
Viewfinder  [text/ink r30 366x310]      <- opaque dark canvas
  Guide  [r18 300x190]                  <- r110 220x220 for the selfie
  "<caption>"  Type/Caption  icon/on-brand
Shutter row
  Button / Shutter  [surface/card r36 72x72]
    Shutter core  [brand/solid 58x58]
```

| Screen | Step | Title | Instruction | Viewfinder caption |
|---|---|---|---|---|
| ID scan | 1 of 4 | Scan your ID | Place your passport or national ID inside the frame. Hold steady. | Both edges must be visible |
| Licence scan | 2 of 4 | Driving licence | Front side first. We check the category and expiry date. | Front side · 1 of 2 |
| Selfie | 3 of 4 | Selfie check | We match your face to the ID. Look straight at the camera. | Centre your face, then hold still |

### Register / Details

```
Nav bar: <chevron.left> "Step 4 of 4"    Step indicator: all four brand/solid
"Your details"  Type/Large title
"Check what we read from your documents."
Field / Full name      "Emin Mammadov"
Field / Date of birth  "14.03.1994"
Field / Phone          "+994 __ ___ __ __"
Field / Email          "name@example.com"
Button / Primary  "Continue"
```

### Register / Review

```
Nav bar: <chevron.left> "Review"
"Almost done"  Type/Large title
"We'll review your documents and notify you when your status changes. You can keep browsing meanwhile."

Card / Checklist  [vertical surface/card r30 366x222]
  <person.text.rectangle>      "ID document"      "Captured"
  <creditcard>                 "Driving licence"  "Captured"
  <person.crop.circle.fill>    "Selfie check"     "Matched"
  <checkmark.seal.fill>        "Your details"     "Confirmed"

Button / Primary  "Submit for verification"
```

---

## AUTH — full structure

### Auth / Splash

```
App mark  [text/on-gold r27 96x96]   <key.fill> brand/amber
"Rentbutik"  Type/Large title  text/on-gold
"Renting made simple"  Type/Body  text/on-gold
```

### Auth / Welcome

```
App mark  [gradient r20 72x72]  <key.fill> text/on-gold
"Welcome to Rentbutik"  Type/Large title  text/ink
"Cars, electric and golf carts across Baku. Look around first — you only need an account to book."
Button / primary    "Create account"
Button / secondary  "Sign in"
Button / plain      "Continue without an account"
"You can browse and see prices without signing up."  Type/Caption  text/ink-faint
```

### Auth / Sign up

```
Nav bar: <chevron.left> "Create account"
"How would you like to sign up?"  Type/Large title

Tile / MyGov  [vertical surface/card r26 366x150]
  <checkmark.seal.fill> on brand/tint r24 48x48
  "Continue with MyGov" / "Recommended · one tap"  (Type/Caption text/gold)
  "MyGov returns your identity and driving licence in a single step. Nothing to scan or type."

Tile / Email  [vertical surface/card r26 366x132]
  <envelope.fill> on brand/tint r24 48x48
  "Use email and documents" / "About two minutes"
  "We scan your ID, driving licence and a selfie ourselves. Four steps."

"By continuing you accept the terms of service and privacy policy."  Type/Caption  text/ink-faint
```

### Auth / Sign in

```
Nav bar: <chevron.left> "Sign in"
"Welcome back"  Type/Large title
"Sign in with the number on your account."
Field / Phone number   Input: "+994" | divider | "__ ___ __ __"
Field / Password       Input: "••••••••"
"Forgot password?"  Type/Subheadline  text/gold
Button / primary    "Sign in"
Button / secondary  "Use MyGov instead"
```

### Auth / Verification pending

```
<clock.fill> brand/solid on brand/tint r48 96x96
"You are all set, Emin"  Type/Large title
"Verification is in progress. It usually takes a few hours — we will notify you the moment it clears."
Card / Meanwhile  [horizontal surface/card r26 366x68]
  <car.fill> on brand/tint r20 40x40
  "You can browse cars and prices while you wait."
Button / primary  "Go to home"
```

---

## REGISTRATION · CONNECTED UX FLOW — copy only

18 screens. Structure not preserved: it duplicated the two lanes above. The copy below is
kept because some of it is better than what it duplicated — particularly the camera
permission screen and the document review loop, neither of which existed elsewhere.

### Register / Camera permission  (worth keeping — see GAPS "permission priming")

```
"Camera access"  ·  "Allow camera access"
"Use your camera to capture your ID, licence and selfie. You can return to browsing at any time."
Button / Primary "Open Settings"   Button / Secondary "Continue browsing"
```

### Register / Document preview  ·  Review licence front  ·  Review licence back

```
"Review photo"  ·  "Check your photo"
"Make sure every detail is sharp and all four corners are visible."
Viewfinder caption: "Document preview" / "Licence front · captured" / "Licence back · captured"
Button / Primary "Use photo"   Button / Secondary "Retake photo"
```

### Register / Licence back

```
"Step 2 of 4"  ·  "Back of your licence"
"Turn your licence over. Keep all four corners visible and avoid reflections."
Viewfinder caption: "Back side · 2 of 2"
```

### Register / Create account

```
"Create account"  ·  "Your account"
"Use your phone number and a password to save your progress."
Phone number: "+994" | "__ ___ __ __"      Create password: "••••••••"
"Use at least 8 characters."  Type/Subheadline  text/gold
Button / Primary "Create account"   Button / Secondary "I already have an account"
```

### Register / Confirm phone

```
"Verify number"  ·  "Check your messages"
"Enter the six-digit code sent to your phone."
Phone number: "+994" | "50 123 45 67"      Verification code: "— — — — — —"
"Resend code · 00:30"  Type/Subheadline  text/gold
Button / Primary "Verify number"   Button / Secondary "Change phone number"
```

### Register / Code error

```
"Verify number"  ·  "Try that code again"
"That code is incorrect or has expired. Enter a new code to continue."
Verification code: "0 0 0 0 0 0"    "Send a new code"  text/gold
Button / Primary "Verify number"   Button / Secondary "Change phone number"
```

### Register / Recover password  ·  New password

```
"Reset password"  ·  "Forgot your password?"
"Enter your account number. We will send a code to confirm it is you."
Button / Primary "Reset password"   Button / Secondary "Back to sign in"

"Save password"  ·  "Choose a password"
"Create a new password for your account."
New password / Confirm password: "••••••••"    "Use at least 8 characters."
Button / Primary "Save password"   Button / Secondary "Back to sign in"
```

### 01 / Welcome · 02 / Choose registration method · 05 / MyGov handoff · 06 / MyGov success · 08 / Capture ID · 10 / Capture licence front · 14 / Capture selfie

Duplicates of the AUTH and ONBOARDING screens above, same copy.

### 07 / Return to browsing

A duplicate of the Home screen (Host / Renter / Electric car / Golf cart tiles, News,
Notifications, tab bar). Home already exists in the `HOME` lane — see `SPEC/HOME.md`.

