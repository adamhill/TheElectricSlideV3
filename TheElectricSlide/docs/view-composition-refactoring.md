# SlideRule View Composition Refactoring

## Branch: `adamhill/124-refactor-sliderule-view-composition`

## Overview

This document records the analysis, decisions, and implementation of the SlideRule view hierarchy simplification. The goal was to reduce cognitive complexity ("too many pieces") while preserving identical visual behavior and performance characteristics.

## Original View Hierarchy (14 types)

```
ContentView
  └─ SlideRuleDetailView
       └─ DynamicSlideRuleContent
            ├─ SideView (front)
            │    ├─ StatorView (top)      ← wrapper around ScaleContainerView
            │    │    └─ ScaleContainerView<Stator>
            │    │         └─ ScaleView × N
            │    ├─ SlideView             ← wrapper around ScaleContainerView
            │    │    └─ ScaleContainerView<Slide>
            │    │         └─ ScaleView × N
            │    └─ StatorView (bottom)
            │         └─ ScaleContainerView<Stator>
            │              └─ ScaleView × N
            ├─ CursorOverlay (front)
            │    └─ CursorView
            ├─ SideView (back) [same structure]
            └─ CursorOverlay (back)
                 └─ CursorView
```

**Plus:** CursorReadingsContainer → CursorReadingsDisplayView, FlipButton

---

## Prerequisite: Cursor Coordinate System Hardening

Before any view restructuring, we identified and hardened 7 fragile coordinate coupling points.

**See:** `cursor-coordinate-system-hardening.md` for the full architecture document.

**Created:**
- `CursorCoordinateSystem.swift` — centralized constants + math functions
- `CursorCoordinateSystemTests.swift` — 50 contract tests guarding all coupling points

**Modified:** 8 files to use `CursorCoordinateSystem` instead of scattered magic numbers.

---

## Recommendation 1: Collapse StatorView/SlideView into SideView ✅

**Status:** Implemented

**Rationale:** `StatorView` and `SlideView` were thin wrappers (~109 and ~126 lines respectively) that existed only to:
- Pass parameters through to `ScaleContainerView`
- Attach gestures (pan for stators, precision overlay for slide)

All gesture coordination already lived in `SideView`, so these wrappers added indirection without meaningful behavioral separation.

**Changes:**
- **Deleted** `Components/StatorView.swift` and `Components/SlideView.swift`
- **Added** private `@ViewBuilder` methods to `SideView.swift`:
  - `statorContent(stator:)` — ScaleContainerView + pan/tap gestures
  - `slideContent` — ScaleContainerView + precision overlay in ZStack
  - `slidePrecisionOverlay` — gradient edge overlays for precision mode

**Impact:** 2 types eliminated, ~135 net lines saved, ~30 repeated parameters removed.

---

## Recommendation 2: Extract `ruleSideContent()` to De-dup Front/Back ✅

**Status:** Implemented

**Rationale:** `DynamicSlideRuleContent.body` contained nearly identical composition for front and back sides (~80 lines each): `SideView` + `CursorOverlay` + iOS flip transition. The only differences were the data source and `.front`/`.back` enum case.

**Changes:**
- **Added** `ruleSideContent(side:topStator:slide:bottomStator:)` private `@ViewBuilder` method
- **Simplified** `body` from ~120 lines to ~30 lines

**Impact:** ~80 lines of duplication eliminated. Body is now trivially readable.

---

## Recommendation 3: CursorOverlay + CursorView Merge ⚠️ PARTIALLY IMPLEMENTED

### What We Did (Lighter Version) ✅

Moved the 3 cursor gesture math methods from `CursorOverlay` to `GestureHandler`:
- `handleCursorPositionDragChanged()` — zoom/precision correction, clamping, reading updates
- `handleCursorPositionDragEnded()` — final position commit with cleanup
- `handleCursorPrecisionDragEnded()` — anti-jitter precision end

This is consistent with the Phase 7 architecture pattern where all gesture logic lives in `GestureHandler` and views only attach gestures via `@Environment(\.gestureHandler)`.

**Impact:** ~120 lines of coordinate math moved from view to centralized handler. CursorOverlay reduced from ~455 lines to ~320 lines.

### What We Decided NOT To Do ⛔

**Full merge of CursorOverlay into CursorView was rejected.** Here's why:

#### 1. CursorView Would Become a 700+ Line Monster
CursorView is currently a pure visual component (~350 lines of rendering: handles, glass area, gradients, hairline, Canvas-drawn readings). Merging CursorOverlay would add:
- Margin HStack layout (~20 lines)
- Two gesture systems: normal drag + precision long-press-drag (~200 lines)
- `@GestureState`, `@State` for precision tracking
- `isCursorDragEnabled` computed property

This violates the SwiftUI skill's "keep views small" guidance and would make CursorView responsible for both rendering AND gesture coordination AND spatial layout.

#### 2. The Spatial Alignment Contract Is Fragile
CursorOverlay's margin HStack (`leftMarginWidth + 4` spacers) is the critical alignment contract that ensures the cursor hairline aligns with scale ticks. This layout is:
- Tested by the coordinate system contract tests (margin alignment invariant)
- Dependent on `CursorCoordinateSystem.cursorMarginSpacerWidth()`
- Coupled to ScaleView's `HStack(spacing: 4)`

Moving this layout into CursorView would make CursorView aware of margins — currently it doesn't care about its coordinate space, which is a clean separation.

#### 3. Separation of Concerns Is Actually Good Here
- **CursorOverlay** = spatial layout shell + gesture attachment (WHERE the cursor lives)
- **CursorView** = visual rendering (WHAT the cursor looks like)

This is a reasonable architectural boundary. The gesture math is now in `GestureHandler` (consistent with all other gestures), so CursorOverlay is genuinely thin — it's just the spatial layout and gesture attachment point.

#### 4. Risk vs. Reward
- **Risk:** High — touching the margin alignment contract could break cursor-to-tick alignment
- **Reward:** Low — eliminates 1 type and ~14 re-passed parameters, but the parameters are all needed by CursorView anyway

### If You Revisit This Decision Later

If you do decide to merge CursorOverlay into CursorView in the future:

1. **Do it in two isolated steps:**
   - Step 1: Move the margin HStack layout into CursorView (add `leftMarginWidth`, `rightMarginWidth` parameters)
   - Step 2: Move gesture attachment into CursorView (add `@GestureState`, `isCursorDragEnabled`)
   
2. **Validate after each step:**
   - Run all 50 cursor coordinate contract tests
   - Manually verify cursor hairline aligns with scale ticks at positions 0.0, 0.5, and 1.0
   - Verify cursor reaches both edges of the scale

3. **The margin spacer width MUST remain `CursorCoordinateSystem.cursorMarginSpacerWidth(marginWidth:)`** — this is the critical alignment contract.

---

## Recommendation 4: SlideRuleLayoutContext Value Type ⏭ SKIPPED

**Status:** Assessed and skipped

**Rationale:** After completing Recommendations 1 and 2, parameter repetition was already substantially reduced:
- StatorView/SlideView init calls eliminated (absorbed into SideView)
- Front/back duplication eliminated (single `ruleSideContent()` method)

Per the SwiftUI expert skill: *"Pass only needed values to views (avoid large 'config' or 'context' objects)"*. The current parameter passing is appropriate — each view receives exactly what it needs.

---

## Recommendation 5: @Environment for Layout Context ⏭ NOT IMPLEMENTED

**Status:** Low priority, deferred

**Rationale:** Only worth doing if parameter threading still feels painful after Recs 1+2. The trade-off per WWDC2025 is that every environment change causes all readers to check if their value changed. Since `Dimensions` only changes on window resize, the cost would be near-zero, but the benefit is also minimal given the current clean state.

---

## Final View Hierarchy (12 types)

```
ContentView
  └─ SlideRuleDetailView
       └─ DynamicSlideRuleContent
            │   (uses ruleSideContent() for both front and back)
            ├─ SideView
            │    ├─ statorContent()     ← private @ViewBuilder (was StatorView)
            │    │    └─ ScaleContainerView<Stator>
            │    │         └─ ScaleView × N
            │    ├─ slideContent         ← private @ViewBuilder (was SlideView)
            │    │    └─ ScaleContainerView<Slide>
            │    │         └─ ScaleView × N
            │    └─ statorContent()
            │         └─ ScaleContainerView<Stator>
            │              └─ ScaleView × N
            ├─ CursorOverlay            ← gesture attachment + spatial layout
            │    └─ CursorView          ← pure visual rendering
            ├─ CursorReadingsContainer
            │    └─ CursorReadingsDisplayView
            └─ FlipButton
```

## Summary of All Changes

| File | Change | Rec |
|------|--------|-----|
| `Components/StatorView.swift` | **Deleted** | 1 |
| `Components/SlideView.swift` | **Deleted** | 1 |
| `Components/SideView.swift` | Inlined stator + slide as private methods | 1 |
| `Components/DynamicSlideRuleContent.swift` | Extracted `ruleSideContent()` | 2 |
| `ContentView.swift` | Updated comments | 1 |
| `Cursor/CursorCoordinateSystem.swift` | **Created** — centralized constants + math | Pre |
| `Cursor/CursorOverlay.swift` | Removed gesture math (delegated to GestureHandler) | 3 |
| `Cursor/CursorView.swift` | Constants delegate to CursorCoordinateSystem | Pre |
| `Cursor/CursorState.swift` | Uses centralized halfCursorWidth | Pre |
| `Components/ScaleView.swift` | Uses CursorCoordinateSystem.scaleHStackSpacing | Pre |
| `Models/LayoutConfiguration.swift` | Uses CursorCoordinateSystem.totalMarginSpacing | Pre |
| `Extensions/ContentView+Gestures.swift` | Uses centralized halfCursorWidth | Pre |
| `Utilities/GestureHandler.swift` | Added cursor position drag handlers | 3 |
| `TheElectricSlideTests/CursorCoordinateSystemTests.swift` | **Created** — 50 contract tests | Pre |
| `docs/cursor-coordinate-system-hardening.md` | **Created** — architecture doc | Pre |
| `docs/view-composition-refactoring.md` | **Created** — this document | — |

**Pre** = Prerequisite (cursor coordinate hardening)
