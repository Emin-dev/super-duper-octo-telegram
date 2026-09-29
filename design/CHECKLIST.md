# Per-screen definition of done

A screen is not done until every box is ticked.

## Structure
- [ ] Frame is exactly 402 x 874
- [ ] Real name, not `Frame NNNNN`
- [ ] Auto-layout throughout; no absolute positioning inside containers
- [ ] Sits in the correct Section for its flow
- [ ] `tabBarClearance` 96pt bottom padding on tab-root scrolls

## Tokens
- [ ] Every fill bound to a variable — no raw hex
- [ ] Every text style from the ramp — no ad-hoc sizes
- [ ] Renders correctly in Light AND Dark by mode switch alone

## iOS fidelity
- [ ] Every icon is an SF Symbol
- [ ] Every control is a native iOS pattern
- [ ] Nav bar is ONE line
- [ ] Tab bar visible (unless chat thread)
- [ ] Buttons are height 50, capsule, label scaling to 70%

## Contrast + copy
- [ ] No white on gold anywhere — dark ink `#14161A` on gold fills
- [ ] Photo cards opaque, never glass
- [ ] Longest Azerbaijani string fits without growing the control

## Prototype
- [ ] Every interactive element wired
- [ ] Correct motion curve per RULES.md section D
- [ ] Haptic annotated per RULES.md section E
- [ ] No dead ends

## Handoff
- [ ] Maps to a named SwiftUI view
- [ ] Component description filled in

