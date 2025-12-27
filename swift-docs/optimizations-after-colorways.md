# Systematic Rendering Optimization Plan for TheElectricSlide

> **Version:** 1.1.0  
> **Last Updated:** December 26, 2025  
> **Status:** ✅ Steps 1-2 & 5 Implemented  
> **Changelog:**
> - v1.1.0 (2025-12-26): Marked Steps 1, 2, 5 as IMPLEMENTED; batched tick drawing live in production
> - v1.0.0 (2025-12-25): Initial optimization plan created

**Target:** iOS 18+, iPadOS 18+, macOS 15+  
**Goal:** Optimize rendering from tick marks → scales → slide rule level

## Research Sources

- **WWDC2024** "Create custom visual effects with SwiftUI" (10151) - Canvas patterns, Metal shaders, `.layerEffect()`
- **WWDC2024** "Demystify SwiftUI containers" (10146) - Container values, subview iteration
- **WWDC2023** "Demystify SwiftUI performance" (10160) - Observable patterns, `Self._printChanges()`, dependency graph
- **WWDC2021** "Demystify SwiftUI" (10022) - Identity, lifetime, structural identity, inert modifiers
- **Apple Docs** - `GraphicsContext`, `Canvas`, `.drawingGroup(opaque:colorMode:)`

---

## Step 1: Audit & Profile Current Tick/Label Rendering ✅ COMPLETED

Use Instruments to profile `ScaleTickRenderer.swift` and `ScaleLabelRenderer.swift` Canvas drawing. Measure per-frame time for scales with 200+ tick marks (LL1, LL2, LL3). Establish baseline metrics before changes.

**Research:** `mcp_sosumi_fetchAppleDocumentation` → `/documentation/swiftui/graphicscontext`

**Status:** Metrics gathered by user.

---

## Step 2: Optimize Canvas Draw Calls in ScaleView ✅ IMPLEMENTED

Reduce `GraphicsContext` state changes by:
1. ✅ Batching tick marks by line width (group similar operations)
2. ✅ Caching resolved colors/strokes outside the draw loop (already done)
3. ✅ Using single `withCGContext` block for all ticks (was per-tick!)
4. ⏳ Evaluating `rendersAsynchronously: true` on Canvas (future consideration)

**Research:** WWDC2024 "Create custom visual effects with SwiftUI" (10151)

**Implementation (December 25, 2025):**

### Changes Made

**ScaleTickRenderer.swift:**
- Added new `drawTicksBatched()` method that draws all ticks in a single `withCGContext` call
- Groups ticks by line width using array of `(width: CGFloat, path: CGMutablePath)` tuples
- Uses `CGMutablePath` directly instead of SwiftUI `Path` → `cgPath` conversion
- Returns `[TickGeometry]` array with pre-computed positions for label rendering
- Original `drawTick()` method preserved for backward compatibility

**ScaleView.swift:**
- Updated `drawScale()` to use `drawTicksBatched()` instead of per-tick loop
- Label rendering now uses pre-computed geometry from batched drawing

### Performance Expectations

| Metric | Before | After (Expected) |
|--------|--------|------------------|
| `withCGContext` calls per scale | N (1 per tick) | 1 (single call) |
| CGContext state changes | N × 3 (color, width, path) | ~3-5 (grouped by width) |
| Path allocations | N SwiftUI Paths | ~3-5 CGMutablePaths |

**Key Insight from WWDC2024:**
> "Make a copy of the context so that individual calls will not affect each other since GraphicsContext has value semantics."

**Key Insight from Apple Docs:**
> "Each context references a particular layer in a tree of transparency layers, and also contains a full copy of the drawing state. You can modify the state of one context without affecting the state of any other."

---

## Step 3: Evaluate Metal Shaders for Tick Rendering

Experiment with `.layerEffect()` Metal shaders (WWDC2024) to render tick marks procedurally on GPU instead of per-path drawing. Profile GPU vs CPU trade-offs.

**Research:** `/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:)`

**Consideration:** Shaders add build complexity (Metal files). Prototype with simple shader first, or skip if Canvas performance is acceptable after Step 2.

---

## Step 4: Verify Identity Stability in Scale Hierarchy

Audit `ScaleView`, `StatorView`, `SlideView` for stable identifiers per WWDC2021 "Demystify SwiftUI". Ensure `.equatable()` comparisons avoid false negatives causing unnecessary redraws.

**Research:** WWDC2021 "Demystify SwiftUI" (10022)

**Key Insight:**
> "An identifier that isn't stable can result in a shorter view lifetime. Having a stable identifier also helps performance, since SwiftUI doesn't need to continually create storage for the view and churn through updating the graph."

**Check for:**
- Computed random identifiers (bad)
- Array indices as identifiers (bad)
- Stable database/property-derived identifiers (good)

---

## Step 5: Optimize Observable Hot/Cold Pattern ✅ FIXED (Dec 25)

Validate `SlideRuleViewModel` and `CursorState` throttling (modulo-3) is optimal. Consider `@ObservationIgnored` for more high-frequency properties. Profile with `Self._printChanges()`.

**Research:** WWDC2023 "Demystify SwiftUI performance" (10160)

**Issue Found (Instruments):**
```
Node label: @Observable CursorState.(Optional<CursorReadings>)
Backtrace: closure #1 in View.onChange(of:initial:_:) → ObservationRegistrar.willSet → CursorOverlay.body
```

**Root Cause:**
`CursorOverlay.body` was calling `getReadingsForSide()` which accessed `cursorState.currentReadings`, creating an Observable dependency. Every time readings updated (even with modulo-3 throttling), the **entire** `CursorOverlay.body` was invalidated - including all its complex gesture handlers.

**Solution Implemented:**
Moved the `currentReadings` dependency from `CursorOverlay` into `CursorView`:

1. **CursorOverlay** now passes `cursorState` and `side` to `CursorView` instead of pre-fetched readings
2. **CursorView** has a computed property `readings` that accesses `cursorState.currentReadings`
3. Only `CursorView.body` (the visual component) is invalidated on reading changes
4. `CursorOverlay.body` (gesture handlers) is no longer invalidated on reading changes

**Files Changed:**
- `CursorOverlay.swift` - Pass `cursorState` + `side` instead of `readings`
- `CursorView.swift` - Accept `cursorState` + `side`, compute readings internally

**WWDC2023 "Demystify SwiftUI performance" Key Insight:**
> "Identity is the backbone of the dependency graph... SwiftUI uses identity and lifetime to form dependencies, which can efficiently update the UI."

By isolating the Observable dependency to a child view, we prevent cascading invalidations up the view hierarchy.

---

## Step 6: Consolidate `.drawingGroup()` Usage

Verify `.drawingGroup()` placement in `ScaleView` is optimal. Test nested drawing groups vs single outer group on `SideView`.

**Research:** `/documentation/swiftui/view/drawinggroup(opaque:colormode:)`

**Key Insight:**
> "The `drawingGroup(opaque:colorMode:)` modifier flattens a subtree of views into a single view before rendering it."

**Test Matrix:**
- [ ] `.drawingGroup()` on each Canvas (current)
- [ ] `.drawingGroup()` on SideView container only
- [ ] `.drawingGroup(opaque: true)` where backgrounds are solid
- [ ] Nested groups vs flat groups

---

## Already Implemented Optimizations (Reference)

From `swift-sliderule-rendering-improvements.md`:
- ✅ Solution 1: `onGeometryChange(for:)` replaces `GeometryReader`
- ✅ Solution 2: Pre-computed tick marks from `GeneratedScale.tickMarks`
- ✅ Solution 3: `Equatable` conformance on views
- ✅ Solution 4: `.drawingGroup()` for Canvas with 200+ tick marks
- ✅ Solution 5: Slide offset state separation

From `slide-rule-performance-decisions-and-planning.md`:
- ✅ Phase 1: Hot/Cold Observable pattern (85% hitch reduction)
- ❌ Phase 2: View extraction (reverted - circular dependency)
- ❌ Phase 3: Circular dependency fix (reverted - made worse)
