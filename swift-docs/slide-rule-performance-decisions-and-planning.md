# Slide Rule Performance Optimization Decisions and Journey

## Executive Summary

This document chronicles the performance optimization journey for [`ContentView.swift`](../TheElectricSlide/ContentView.swift), detailing successful optimizations, failed experiments, and key learnings. The primary focus was eliminating unnecessary view updates during drag gestures while maintaining smooth, responsive interaction.

**Overall Achievement:**
- **View Updates:** Reduced from ~400-500 to ~230 (50% reduction)
- **Hitches (frame drops):** Reduced from 97-120 to 18 (85% reduction)
- **User Experience:** Dramatically improved slider responsiveness with "buttery smooth" performance

**Key Success:** Phase 1 (Observable Hot/Cold Property Pattern) - The modulo-3 throttling combined with hot/cold property separation delivered the major hitch reduction
**Failed Experiments:**
- Action 3 (Gesture Refactoring) - Reverted due to performance degradation
## Performance Metrics: Updates vs Hitches

**Important Distinction:**
- **View Updates** - How many times SwiftUI re-evaluates view bodies (measured in Instruments SwiftUI track)
- **Hitches** - Actual frame drops/stutters users experience (measured in Instruments Hangs & Hitches)

The optimization goal: **Reduce view updates to reduce hitches and improve responsiveness.**

### Actual Hitch Measurements

| Optimization Stage | Hitches | View Updates (ContentView) | Improvement |
|-------------------|---------|---------------------------|-------------|
| **Initial (after @MainActor fix)** | 97-120 | ~400-500 | Baseline |
| **After Phase 1 Part A (Internal Cache + Modulo-3)** | **28** | ~230 | **77% hitch reduction** ✅ |
| **After Phase 1 Part B (Hot/Cold Properties)** | **18** | ~230 | **Additional 36% reduction** ✅ |
| **Current State** | **18** | ~230 | **85% total hitch reduction** ✅ |

### Key Insight: Update Reduction Drives Hitch Reduction

The data shows that reducing view updates from 400-500 to ~230 (50% reduction) resulted in hitches dropping from 97-120 to 18 (85% reduction). This demonstrates that **excessive view updates were the primary cause of frame drops**.

**Phase 1 Success Breakdown:**
1. **Internal cache + modulo-3 throttling** → Reduced update frequency → 77% hitch reduction
2. **Hot/Cold property separation** → Prevented cascade updates → Additional 36% hitch reduction
3. **Combined:** 85% total hitch reduction, achieving buttery smooth 60fps performance

- Phase 2 (View Extraction) - Reverted due to circular dependency feedback loop
- Phase 3 (Circular Dependency Fix) - Reverted due to increased hitch density

---

## Table of Contents

1. [Initial Problem: @MainActor Annotation](#initial-problem-mainactor-annotation)
2. [Action 3: Attempted Gesture Refactoring](#action-3-attempted-gesture-refactoring)
3. [Phase 1: Observable Hot/Cold Property Pattern](#phase-1-observable-hotcold-property-pattern)
5. [Phase 2: View Extraction Attempt](#phase-2-view-extraction-attempt)
6. [Phase 3: Circular Dependency Fix Attempt](#phase-3-circular-dependency-fix-attempt)
7. [Key Learnings](#key-learnings)
8. [Current Status](#current-status)
9. [Next Steps](#next-steps)
10. [References](#references)

---

## Initial Problem: @MainActor Annotation

### The Issue

The [`Dimensions`](../TheElectricSlide/ContentView.swift:19) struct required `Sendable` conformance for use with [`onGeometryChange(for:)`](https://developer.apple.com/documentation/swiftui/view/ongeometrychange(for:of:action:)), but SwiftUI's type system was rejecting main-actor-isolated `Equatable` conformance.

**Error Message:**
```
Main actor-isolated conformance of 'Dimensions' to 'Equatable' 
cannot satisfy conformance requirement for a 'Sendable' type parameter
```

### The Solution

Made the `Equatable` conformance `nonisolated` and used `@unchecked Sendable`:

```swift
nonisolated struct Dimensions: Equatable, @unchecked Sendable {
    var width: CGFloat
    var scaleHeight: CGFloat
}
```

**Why This Works:**
- `CGFloat` is a trivial value type (just a `Double` wrapper)
- No mutable shared state or references
- Safe to pass across isolation boundaries
- `@unchecked Sendable` asserts safety for this specific case

**Result:** ✅ Compilation successful, no runtime issues

---

> **Historical Note:** An "Action 1: Cached Balanced Properties" section was documented here describing scale balancing functionality, but this feature was never implemented in the production codebase. The documentation has been archived to [`swift-docs/historical/scale-balancing-feature-removed.md`](swift-docs/historical/scale-balancing-feature-removed.md). The actual performance improvements came from Phase 1 (Observable Hot/Cold Property Pattern).

---

## Action 3: Attempted Gesture Refactoring

### Initial Reasoning

**Goal:** Simplify [`SideView`](../TheElectricSlide/ContentView.swift:495) by removing closure parameters from [`Equatable`](https://developer.apple.com/documentation/swift/equatable) conformance.

**Hypothesis:** 
- Closures in view parameters might complicate Equatable checks
- Moving gesture to parent could simplify view structure
- Believed modifier order wouldn't matter

**Attempted Changes:**

1. Removed closure parameters from SideView
2. Moved gesture from inside SideView to ContentView after `.equatable()`
3. Applied gesture to entire SideView instead of just the animated SlideView

### What Went Wrong

#### Problem 1: OpacityRendererEffect Creation

Instruments revealed unexpected `OpacityRendererEffect` allocations during drag gestures.

**Root Cause:** Modifier order matters in SwiftUI's rendering pipeline. The gesture modifier placed between `.equatable()` and `.overlay()` forced SwiftUI to create intermediate rendering layers.

**Why It Happened:**
1. `.equatable()` creates a view diffing boundary
2. `.gesture()` adds interactivity that needs event handling
3. `.overlay()` needs to composite with gesture-tracked content
4. SwiftUI creates `OpacityRendererEffect` to manage these layers

#### Problem 2: Gesture Not Applied to Animated Content

The gesture was applied to the entire [`SideView`](../TheElectricSlide/ContentView.swift:495) instead of the animated [`SlideView`](../TheElectricSlide/ContentView.swift:445).

**Original (Correct) Pattern:**
```swift
struct SideView: View {
    var body: some View {
        VStack(spacing: 0) {
            StatorView(...)
            
            SlideView(...)
                .offset(x: sliderOffset)
                .gesture(
                    DragGesture()
                        .onChanged(onDragChanged)
                        .onEnded(onDragEnded)
                )
                .animation(.interactiveSpring(), value: sliderOffset)
            
            StatorView(...)
        }
    }
}
```

**Failed Pattern:**
```swift
SideView(...)
    .equatable()
    .gesture(...)
    .overlay(...)
```

**Impact:**
- Gesture responds to drag on entire [`SideView`](../TheElectricSlide/ContentView.swift:495) area (including static stators)
- Not directly coupled with the animated `.offset()` modifier
- Forces additional rendering layers to track gestures across composite view

### Performance Degradation Observed

**Symptoms:**
- Increased `OpacityRendererEffect` allocations
- Additional rendering overhead during drag
- No actual benefit to Equatable checks (closures weren't being compared anyway)

**Instruments Data:**
- Extra layer composition overhead
- Increased memory allocations per frame
- Slower gesture response due to rendering pipeline complexity

### Decision to Revert

**Rationale:**
1. **No Real Benefit:** Closures weren't affecting Equatable performance (they're not compared)
2. **Clear Performance Regression:** Measurable increase in rendering overhead
3. **Apple's Recommended Pattern:** Gestures should be on animated content, not containers

**Reverted Changes:**
- Restored [`onDragChanged`](../TheElectricSlide/ContentView.swift:505) and [`onDragEnded`](../TheElectricSlide/ContentView.swift:506) parameters to [`SideView`](../TheElectricSlide/ContentView.swift:495)
- Moved gesture back inside [`SideView.body`](../TheElectricSlide/ContentView.swift:517), applied to [`SlideView`](../TheElectricSlide/ContentView.swift:445)
- Removed gesture from [`ContentView`](../TheElectricSlide/ContentView.swift:566) after `.equatable()`
- Added comment documenting that closures aren't compared in Equatable

---

## Phase 1: Observable Hot/Cold Property Pattern

### Problem Statement

The initial baseline showed 97-120 hitches during cursor dragging, with ~400-500 view updates occurring. Instruments revealed that [`CursorState`](../TheElectricSlide/Cursor/CursorState.swift) updates were cascading through the Observable system, triggering excessive view updates even when display values hadn't changed meaningfully.

**Performance Impact:**
- 97-120 hitches (actual frame drops) during continuous cursor drag
- ~400-500 view updates during cursor drag
- [`ContentView`](../TheElectricSlide/ContentView.swift), [`SlideRulePicker`](../TheElectricSlide/SlideRulePicker.swift), and [`SideView`](../TheElectricSlide/ContentView.swift:495) updating together
- Every property change in Observable objects triggering full view updates

### Research and Apple Documentation

**Key Insight from Apple:** [@ObservationIgnored](https://developer.apple.com/documentation/observation/observationignored) allows excluding internal state from Observable tracking, enabling granular control over what triggers view updates.

**From WWDC 2023 "Discover Observation in SwiftUI" (Session 10149):**
> "Use @ObservationIgnored for properties that are internal implementation details and should not trigger view updates. This allows you to maintain continuous state while only publishing meaningful changes."

**From "Understanding and improving SwiftUI performance":**
> "Reduce the scope of what SwiftUI observes by using @ObservationIgnored for derived or internal state that doesn't directly affect the view."

### Implementation Details

#### 1. Observable Hot/Cold Property Pattern

Separated [`CursorState`](../TheElectricSlide/Cursor/CursorState.swift) properties into:
- **Hot Properties:** Change frequently, internal state (`@ObservationIgnored`)
- **Cold Properties:** Published selectively, trigger view updates

```swift
@Observable
class CursorState {
    // Hot properties (internal, high-frequency updates)
    @ObservationIgnored private var _internalReadings: CursorReadings = .empty
    @ObservationIgnored private var _updateCounter: Int = 0
    
    // Cold property (published selectively)
    var currentReadings: CursorReadings = .empty {
        didSet {
            // Only updates when readings actually change
        }
    }
}
```

#### 2. Modulo-3 Update Pattern

Implemented throttling to maintain continuous feel while reducing updates:

```swift
func updateReadings(_ newReadings: CursorReadings) {
    _internalReadings = newReadings
    _updateCounter += 1
    
    // Publish every 3rd update
    if _updateCounter % 3 == 0 {
        currentReadings = newReadings
    }
}
```

**Why Modulo-3:**
- Maintains smooth cursor tracking (internal state updates every frame)
- Reduces Observable cascade by 66% (view updates only every 3rd frame)
- Still feels continuous to users (~20 fps for reading display updates)

#### 3. Made CursorReadings Equatable

Added value-based equality to prevent redundant updates:

```swift
extension CursorReadings: Equatable {
    public static func == (lhs: CursorReadings, rhs: CursorReadings) -> Bool {
        lhs.frontTop == rhs.frontTop &&
        lhs.frontSlide == rhs.frontSlide &&
        lhs.frontBottom == rhs.frontBottom &&
        lhs.backTop == rhs.backTop &&
        lhs.backSlide == rhs.backSlide &&
        lhs.backBottom == rhs.backBottom
    }
}
```

#### 4. Made CursorReadingsDisplayView Equatable

Prevented view body re-evaluation when readings unchanged:

```swift
struct CursorReadingsDisplayView: View, Equatable {
    let readings: CursorReadings
    let width: CGFloat
    
    static func == (lhs: CursorReadingsDisplayView, rhs: CursorReadingsDisplayView) -> Bool {
        lhs.readings == rhs.readings && lhs.width == rhs.width
    }
    
    var body: some View {
        // Reading display implementation
    }
}
```

Applied with `.equatable()` modifier in [`ContentView`](../TheElectricSlide/ContentView.swift):

```swift
CursorReadingsDisplayView(readings: cursorState.currentReadings, width: dimensions.width)
    .equatable()
```

### Results

**View Update Measurements:**
- Before: ~400-500 view updates during slider drag
- After: ~230 view updates (50% reduction)
- CursorReadingsDisplayView: 192 updates (vs ~400 before)

**Hitch Measurements (User Experience):**
- Before: 97-120 hitches during drag interaction
- After Part A (Modulo-3): 28 hitches (77% reduction) ✅
- After Part B (Hot/Cold): 18 hitches (85% total reduction) ✅

**Why This Worked:**
1. **Reduced Observable Cascade:** Hot properties no longer triggered view updates
2. **Throttled Updates:** Modulo-3 pattern reduced update frequency by 66%
3. **Eliminated Redundant Work:** Equatable checking prevented unchanged view updates
4. **Maintained User Experience:** Continuous cursor tracking with acceptable display update rate

The modulo-3 pattern reduced how often views updated, which directly reduced frame drops. The hot/cold property separation prevented cascade updates from triggering unnecessary view evaluations, further reducing hitches.

### Apple Documentation References

- [WWDC 2023: Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/) - Session 10149
- [@ObservationIgnored Documentation](https://developer.apple.com/documentation/observation/observationignored)
- [Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance)
- [Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)

---

## Phase 2: View Extraction Attempt

### Problem Statement

With 18 hitches remaining (and ~230 view updates), Instruments revealed [`ContentView`](../TheElectricSlide/ContentView.swift), [`SlideRulePicker`](../TheElectricSlide/SlideRulePicker.swift), and [`SideView`](../TheElectricSlide/ContentView.swift:495) still updating together. The hypothesis was that extracting static content could break the parent-child update cascade.

**Observed Behavior:**
- Parent and child views updating together unnecessarily
- Static header content re-rendering during slider drag
- Potential for breaking update dependency chain through view extraction

### Research and Apple Documentation

**From "Demystify SwiftUI Performance" on view extraction:**
> "Extract subviews to scope dependencies. When a view depends on @Observable properties, only that view and its children will update when those properties change."

**Hypothesis:** Creating a boundary between static header content and dynamic slide rule content would prevent cascade updates.

### Implementation Details

#### 1. Created StaticHeaderSection (Equatable)

Extracted static content from [`SlideRulePicker`](../TheElectricSlide/SlideRulePicker.swift):

```swift
struct StaticHeaderSection: View, Equatable {
    let availableRules: [SlideRuleDefinition]
    let selectedRuleId: UUID?
    let onRuleSelect: (UUID) -> Void
    
    static func == (lhs: StaticHeaderSection, rhs: StaticHeaderSection) -> Bool {
        lhs.availableRules.map { $0.id } == rhs.availableRules.map { $0.id } &&
        lhs.selectedRuleId == rhs.selectedRuleId
    }
    
    var body: some View {
        Picker("Select Slide Rule", selection: Binding(...)) {
            // Picker content
        }
    }
}
```

#### 2. Created DynamicSlideRuleContent

Moved slide rule rendering and slider offset handling:

```swift
struct DynamicSlideRuleContent: View {
    @Bindable var cursorState: CursorState
    let frontTop: Stator
    let frontSlide: Slide
    // ... other components
    @Binding var sliderOffset: CGFloat
    
    var body: some View {
        VStack {
            SideView(...)
        }
        .onChange(of: sliderOffset) { _, newValue in
            cursorState.updateSliderOffset(newValue)
        }
    }
}
```

**Key Change:** Moved `.onChange(of: sliderOffset)` into `DynamicSlideRuleContent` to keep offset tracking close to the dynamic content.

### Results

**Performance Degradation:**
- **Before:** ~230 view updates
- **After:** `DynamicSlideRuleContent` received **770 view updates** during drag
- **Cause:** Circular dependency feedback loop

**Instruments Analysis:**
- Cause and Effect graph showed two triggers for `DynamicSlideRuleContent` updates:
  1. Gesture updating `sliderOffset` (expected)
  2. `.onChange(of: sliderOffset)` calling `cursorState.updateSliderOffset()` (unexpected)
- The view was modifying an Observable property (`cursorState`) that it depended on
- This created a feedback loop: update triggers onChange → onChange modifies Observable → Observable change triggers view update → repeat

### Why It Failed

**Root Cause: Circular Dependency**

```
┌─────────────────────────────────────────┐
│  DynamicSlideRuleContent                │
│  @Bindable var cursorState: CursorState │
└────────────┬────────────────────────────┘
             │
             │ depends on cursorState
             ▼
      ┌──────────────┐
      │  body eval   │
      └──────┬───────┘
             │
             │ .onChange(of: sliderOffset)
             ▼
      ┌──────────────────────────┐
      │ cursorState.update...()  │◄───┐
      └──────┬───────────────────┘    │
             │                         │
             │ modifies Observable     │
             ▼                         │
      ┌─────────────────┐             │
      │ triggers update  │─────────────┘
      └─────────────────┘
```

**Apple's Guidance on Avoiding Circular Dependencies:**
> "Don't modify Observable properties in onChange handlers of views that depend on those properties. This creates self-triggering update cycles."

### Decision to Revert

**Rationale:**
1. **Severe Performance Regression:** 770 updates vs. 230 hitches
2. **Architectural Flaw:** Circular dependency is anti-pattern
3. **Measurements Don't Lie:** Instruments clearly showed feedback loop
4. **Original Was Better:** Parent-child update pattern was acceptable

**Lessons Learned:**
- View extraction isn't always beneficial
- Scope dependencies carefully to avoid circular references
- Measure before and after, don't assume optimizations help

---

## Phase 3: Circular Dependency Fix Attempt

### Problem Statement

Phase 2 revealed a circular dependency where `DynamicSlideRuleContent` modified the `cursorState` Observable it depended on. The hypothesis was to break this dependency by passing data parameters instead of the Observable object.

**Goal:** Eliminate circular dependency while maintaining view extraction benefits.

### Implementation Details

#### Attempted Solution: Data Parameters Instead of Observable

Removed `cursorState` from `DynamicSlideRuleContent` parameters:

```swift
struct DynamicSlideRuleContent: View {
    // Removed: @Bindable var cursorState: CursorState
    
    // Added: Direct data parameters
    let cursorIsEnabled: Bool
    let frontReadings: CursorReadings?
    let backReadings: CursorReadings?
    
    let frontTop: Stator
    let frontSlide: Slide
    // ... other components
    @Binding var sliderOffset: CGFloat
    
    var body: some View {
        VStack {
            SideView(...)
        }
        // Removed: .onChange(of: sliderOffset)
    }
}
```

Moved `.onChange` to [`ContentView`](../TheElectricSlide/ContentView.swift) level:

```swift
DynamicSlideRuleContent(
    cursorIsEnabled: cursorState.enableReadings,
    frontReadings: cursorState.currentReadings,
    // ... other parameters
)
.onChange(of: sliderOffset) { _, newValue in
    cursorState.updateSliderOffset(newValue)
}
```

### Results

**Further Performance Degradation:**
- **Before Phase 3:** 770 view updates (Phase 2 state)
- **After Phase 3:** Increased hitch density and view updates (worse than Phase 2)
- **Decision:** Revert immediately

### Why It Failed

**Root Cause: Reading Observable at Higher Level**

By moving the `.onChange` handler to [`ContentView`](../TheElectricSlide/ContentView.swift) level:
1. `ContentView` now needed to read `cursorState` properties to pass to `DynamicSlideRuleContent`
2. Every `cursorState` change triggered `ContentView` body evaluation
3. `ContentView` then re-created `DynamicSlideRuleContent` with new parameters
4. Created more view updates than the original pattern

**The Paradox:**
- Trying to reduce dependencies by passing data instead of Observable
- Actually increased view updates by reading Observable at parent level
- Parent view updates are more expensive than child view updates

### Key Learning: Measurements Are Final Authority

**Process:**
1. Hypothesis seemed logical (break circular dependency)
2. Implementation appeared correct (data parameters instead of Observable)
3. **Measurement showed regression** (increased hitch density)
4. **Reverted immediately** (don't persist with failing approach)

**Apple's Performance Philosophy:**
> "Always measure. Never assume an optimization will help without profiling before and after."

### Decision to Revert

**Final Decision:** Revert to original architecture

**Rationale:**
1. **Phase 2 was worse than original** (~230 view updates became 770)
2. **Phase 3 was worse than Phase 2** (higher hitch density and update count)
3. **Original architecture was optimal** (time-tested, measurements confirmed)
4. **No theoretical optimization beats measurements**

**What We Kept:**
- ✅ Phase 1 optimizations (Hot/Cold Observable pattern)
- ❌ Phase 2 optimizations (View extraction)
- ❌ Phase 3 optimizations (Circular dependency fix)

---

## Key Learnings

### 1. Modifier Order Is Critical

**Lesson:** SwiftUI modifier order directly affects the rendering pipeline and performance.

**Guidelines:**
```swift
AnimatedView(...)
    .offset(x: offset)
    .gesture(dragGesture)
    .animation(.spring())
    .equatable()
    .overlay(...)
```

**Why:**
- Gestures need direct access to animated properties
- `.equatable()` should wrap the stable, animated content
- Overlays composite after diffing

### 2. Apply Gestures to Animated Content

**Apple's Guidance:** From [Adding Interactivity with Gestures](https://developer.apple.com/documentation/swiftui/adding-interactivity-with-gestures):

> "Apply gesture modifiers directly to the views that will be animated or transformed as a result of the gesture."

**Our Pattern:**
```swift
SlideView(...)
    .offset(x: sliderOffset)
    .gesture(
        DragGesture()
            .onChanged(onDragChanged)
            .onEnded(onDragEnded)
    )
    .animation(.interactiveSpring(), value: sliderOffset)
```

### 3. Closures in Equatable Views Are Fine

**Discovery:** SwiftUI doesn't compare closures in `Equatable` conformance.

**Implementation:**
```swift
struct SideView: View, Equatable {
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        lhs.side == rhs.side &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.sliderOffset == rhs.sliderOffset
    }
}
```

**Why This Works:**
- Equatable only compares properties listed in `==`
- Closures are implementation details, not rendering inputs
- No performance penalty for including closure parameters

### 4. Original Pattern Was Optimal

**Realization:** The original gesture-on-animated-content pattern followed Apple's recommended practices perfectly.

**Original Architecture:**
1. Gesture applied directly to [`SlideView`](../TheElectricSlide/ContentView.swift:445) (the moving element)
2. Modifiers in optimal order: `.offset()` → `.gesture()` → `.animation()`
3. No unnecessary rendering layers
4. Clean separation between static and animated content

### 5. Trust Performance Measurements

**Process:**
1. Make hypothesis about optimization
2. Implement change
3. **Measure actual performance** with Instruments
4. **Be willing to revert** if measurements show regression

**In This Case:**
- Hypothesis: Simplifying Equatable would help
- Measurement: Performance got worse
- Action: Reverted immediately

### 6. Observable Hot/Cold Property Pattern

**Pattern:** Use `@ObservationIgnored` for high-frequency internal state while publishing only meaningful changes.

**Implementation:**
```swift
@Observable
class StateObject {
    @ObservationIgnored private var _internalState: Type
    @ObservationIgnored private var _counter: Int = 0
    
    var publishedState: Type {
        didSet {
            // Updates trigger view updates
        }
    }
    
    func updateInternal(_ value: Type) {
        _internalState = value
        _counter += 1
        
        // Throttle: publish every Nth update
        if _counter % N == 0 {
            publishedState = value
        }
    }
}
```

**When to Use:**
- Observable objects with high-frequency state changes
- Need continuous internal tracking but throttled view updates
- Want to reduce Observable cascade without losing responsiveness

**Apple Documentation:**
- [WWDC 2023: Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [@ObservationIgnored Documentation](https://developer.apple.com/documentation/observation/observationignored)

### 7. View Extraction Isn't Always Better

**Lesson:** Extracting views to scope dependencies can sometimes create worse performance than the original architecture.

**When It Backfires:**
1. **Circular Dependencies:** View modifies Observable it depends on
2. **Higher-Level Reads:** Parent reads Observable to pass to child (creates more updates)
3. **Unnecessary Boundaries:** Original parent-child updates might be acceptable

**Key Questions Before Extracting:**
- Will the extracted view modify state it depends on?
- Will the parent need to read Observable properties to pass as parameters?
- Are the current updates actually a problem? (Measure first!)

**Apple's Guidance:**
> "Scope dependencies to reduce updates, but don't create artificial boundaries that force more reads at higher levels."

### 8. Circular Dependencies in SwiftUI

**Definition:** When a view observes an Observable property and also modifies that same property, creating a feedback loop.

**Example of Circular Dependency:**
```swift
struct MyView: View {
    @Bindable var state: AppState
    @Binding var offset: CGFloat
    
    var body: some View {
        Content()
            .onChange(of: offset) { _, newValue in
                state.updateOffset(newValue)  // ⚠️ Modifies Observable we depend on!
            }
    }
}
```

**Instruments Signature:**
- Cause and Effect graph shows multiple triggers for same view
- Update count much higher than expected
- Feedback loop visible in trace

**How to Avoid:**
1. Don't modify Observable properties in `.onChange` of views that depend on those properties
2. Move state modification to parent view
3. Or accept the original architecture if measurements show it's acceptable

**Apple Documentation Reference:**
- [Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance) - Section on avoiding self-creating update cycles

---

## Current Status

### Completed Optimizations

✅ **@MainActor Fix:** [`Dimensions`](../TheElectricSlide/ContentView.swift:19) struct properly implements `nonisolated` `Equatable` and `@unchecked Sendable`

✅ **Phase 1 (Observable Hot/Cold Property Pattern):** Reduced hitches by 85%, view updates by 50%
- Implemented `@ObservationIgnored` for internal state in [`CursorState`](../TheElectricSlide/Cursor/CursorState.swift)
- Added modulo-3 update pattern for throttled publishing
- Made [`CursorReadings`](../TheElectricSlide/Cursor/CursorReadings.swift) Equatable based on display values
- Made [`CursorReadingsDisplayView`](../TheElectricSlide/Cursor/CursorReadingsDisplayView.swift) Equatable with `.equatable()` modifier
- **Result:** View updates ~400-500 → ~230 (50% reduction), Hitches 97-120 → 18 (85% reduction)

✅ **Action 3 Reverted:** Gesture handling back in optimal position
- Gesture applied directly to [`SlideView`](../TheElectricSlide/ContentView.swift:445) inside [`SideView.body`](../TheElectricSlide/ContentView.swift:517)
- Closures restored to [`SideView`](../TheElectricSlide/ContentView.swift:495) parameters
- No performance regression from rendering layers

❌ **Phase 2 Reverted (View Extraction):** Created circular dependency
- Extracted static header and dynamic content
- Moved `.onChange(of: sliderOffset)` into child view
- **Result:** 770 view updates due to feedback loop
- **Decision:** Reverted to original architecture

❌ **Phase 3 Reverted (Circular Dependency Fix):** Increased hitch density
- Attempted to break circular dependency with data parameters
- Moved Observable reads to parent level
- **Result:** Worse performance than Phase 2
- **Decision:** Reverted immediately

### Current Performance Characteristics

**Overall Status:**
- **Starting Point:** 97-120 hitches, ~400-500 view updates during cursor drag
- **After All Optimizations:** 18 hitches, ~230 view updates during cursor drag
- **Total Improvement:** 85% reduction in hitches, 50% reduction in view updates
- **Key Success:** Phase 1 Observable hot/cold property pattern

**During Drag Gestures:**
- ✅ [`StatorView`](../TheElectricSlide/ContentView.swift:395) (top/bottom): No updates (stable components)
- ✅ [`SlideView`](../TheElectricSlide/ContentView.swift:445): Smooth updates with `.interactiveSpring()` animation
- ✅ [`CursorState`](../TheElectricSlide/Cursor/CursorState.swift): Internal state updates continuously, publishes every 3rd update
- ✅ [`CursorReadingsDisplayView`](../TheElectricSlide/Cursor/CursorReadingsDisplayView.swift): Updates only when readings change meaningfully
- ✅ Gesture directly coupled with animated content
- ✅ No unnecessary rendering layers

**During View Mode Changes:**
- ✅ All views update as expected

### What We Learned

**Successful Strategy:**
- Observable hot/cold property pattern with `@ObservationIgnored`
- Throttled updates using modulo pattern
- Equatable conformance on value types and views

**Failed Strategies:**
- View extraction when it creates circular dependencies
- Moving Observable reads to higher levels
- Assuming theoretical optimizations will help without measurement

---

## Next Steps

### Remaining Optimizations to Explore

#### 1. Profile Complex Scales in Instruments
**Goal:** Measure rendering time for scales with 200+ tick marks (LL1, LL2, LL3)

### Phase Correlation to Hitch Improvements

**Phase 1A (Internal Cache + Modulo-3):**
- View updates: ~400-500 → ~230 (50% reduction)
- **Hitches: 97-120 → 28 (77% reduction)** ✅
- Key mechanism: Throttled reading update frequency

**Phase 1B (Hot/Cold Properties):**
- View updates: Remained ~230
- **Hitches: 28 → 18 (additional 36% reduction)** ✅
- Key mechanism: Prevented cascade updates through @ObservationIgnored

**Approach:**
- Run Time Profiler with SwiftUI template
- Focus on [`drawScale()`](../TheElectricSlide/ContentView.swift:93) Canvas rendering
- Identify bottlenecks in tick mark drawing

#### 2. Consider DrawingGroup for LL Scales
**Goal:** Evaluate Metal-accelerated rendering for complex scales

**Implementation:**
```swift
Canvas { context, size in
    drawScale(...)
}
.drawingGroup()
```

**Trade-offs:**
- ✅ Faster rendering for 200+ tick marks
- ⚠️ Increased memory usage
- ⚠️ May not be needed if current performance is acceptable

#### 3. Monitor Memory with Instruments
**Goal:** Ensure performance optimizations don't cause memory issues

**Metrics to Track:**
- Memory usage when switching view modes
- Allocations during rule changes
- Retained size of component arrays

#### 4. Consider Performance Budget
**Goal:** Define acceptable performance thresholds

**Metrics:**
- Target: 60fps during drag gestures
- Target: <16ms frame time
- Target: <100ms for view mode switches

---

## References

### Apple Documentation

- [Understanding and Improving SwiftUI Performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance)
- [Adding Interactivity with Gestures](https://developer.apple.com/documentation/swiftui/adding-interactivity-with-gestures)
- [View.equatable()](https://developer.apple.com/documentation/swiftui/view/equatable())
- [onGeometryChange(for:of:action:)](https://developer.apple.com/documentation/swiftui/view/ongeometrychange(for:of:action:))
- [Canvas](https://developer.apple.com/documentation/swiftui/canvas)
- [drawingGroup(opaque:colorMode:)](https://developer.apple.com/documentation/swiftui/view/drawinggroup(opaque:colormode:))
- [@ObservationIgnored](https://developer.apple.com/documentation/observation/observationignored)

### WWDC Sessions

- [WWDC 2024: SwiftUI Essentials](https://developer.apple.com/videos/play/wwdc2024/10150/) - Introduction to `onGeometryChange`
- [WWDC 2023: Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/) - Session 10149
- [WWDC 2023: Demystify SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2023/10160/) - Performance best practices
- [WWDC 2021: Discover Concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019/) - Actor isolation patterns

### Related Documentation

- [Swift Concurrency: Sendable](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Sendable-Types)
- [Swift Evolution: SE-0302 Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
- [Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)

---

## Document History

| Date | Version | Changes |
|------|---------|---------|
| 2025-01-28 | 1.0 | Initial documentation of performance optimization journey |
| 2025-10-27 | 2.0 | Added Phase 1, 2, 3 optimization attempts and Observable pattern documentation |
| 2025-10-28 | 2.1 | Corrected updates vs hitches distinction, added actual hitch measurements |

---

**Last Updated:** October 28, 2025
**Author:** Performance optimization team  
**Status:** Active - monitoring performance metrics