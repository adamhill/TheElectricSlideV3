# Slide Rule Performance Optimization Decisions and Journey

## Executive Summary

This document chronicles the performance optimization journey for [`ContentView.swift`](../TheElectricSlide/ContentView.swift), detailing successful optimizations, failed experiments, and key learnings. The primary focus was eliminating unnecessary view updates during drag gestures while maintaining smooth, responsive interaction.

**Overall Achievement:** Eliminated redundant [`StatorView`](../TheElectricSlide/ContentView.swift:395) updates during slide interactions, improving rendering performance significantly.

**Key Success:** Action 1 (Cached Balanced Properties)  
**Failed Experiment:** Action 3 (Gesture Refactoring) - Reverted due to performance degradation

---

## Table of Contents

1. [Initial Problem: @MainActor Annotation](#initial-problem-mainactor-annotation)
2. [Action 1: Cached Balanced Properties](#action-1-cached-balanced-properties)
3. [Action 3: Attempted Gesture Refactoring](#action-3-attempted-gesture-refactoring)
4. [Key Learnings](#key-learnings)
5. [Current Status](#current-status)
6. [Next Steps](#next-steps)
7. [References](#references)

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

## Action 1: Cached Balanced Properties

### Problem Statement

When displaying both front and back sides of a slide rule simultaneously, [`updateBalancedComponents()`](../TheElectricSlide/ContentView.swift:629) was being called on every body evaluation, recalculating spacer scales to balance different scale counts between sides.

**Performance Impact:**
- Redundant calculations during every render
- Unnecessary object allocations
- [`StatorView`](../TheElectricSlide/ContentView.swift:395) updates even when balance hadn't changed

### Implementation

Moved balanced components from computed properties to cached `@State` variables:

```swift
@State private var balancedFrontTopStator: Stator = Stator(...)
@State private var balancedFrontSlide: Slide = Slide(...)
@State private var balancedFrontBottomStator: Stator = Stator(...)
@State private var balancedBackTopStator: Stator? = nil
@State private var balancedBackSlide: Slide? = nil
@State private var balancedBackBottomStator: Stator? = nil
```

**Update Strategy:**
- Call [`updateBalancedComponents()`](../TheElectricSlide/ContentView.swift:629) only when dependencies change
- Triggered by [`onChange(of: viewMode)`](../TheElectricSlide/ContentView.swift:897)
- Triggered by [`onChange(of: selectedRuleId)`](../TheElectricSlide/ContentView.swift:904) (via [`parseAndUpdateSlideRule()`](../TheElectricSlide/ContentView.swift:1062))

```swift
.onAppear {
    cursorState.setSlideRuleProvider(self)
    cursorState.enableReadings = true
    loadCurrentRule()
    updateBalancedComponents()
}
.onChange(of: viewMode) { _, _ in
    updateBalancedComponents()
}
.onChange(of: selectedRuleId) { oldValue, newValue in
    parseAndUpdateSlideRule()
    sliderOffset = 0
    sliderBaseOffset = 0
    saveCurrentRule()
}
```

### Results

**Measured Impact:**
- ✅ Eliminated [`StatorView`](../TheElectricSlide/ContentView.swift:395) extra updates during slider drag
- ✅ No recalculation during body evaluation
- ✅ Balanced components only update when actually needed

**Why This Helped:**
1. **Prevented Recalculation:** Spacer scale creation moved from every body evaluation to explicit update points
2. **Stable View Identity:** [`StatorView`](../TheElectricSlide/ContentView.swift:395) inputs remain constant during drag gestures
3. **Better Equatable Performance:** Combined with [`View.equatable()`](https://developer.apple.com/documentation/swiftui/view/equatable()), SwiftUI can skip body evaluations

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

---

## Current Status

### Completed Optimizations

✅ **@MainActor Fix:** [`Dimensions`](../TheElectricSlide/ContentView.swift:19) struct properly implements `nonisolated` `Equatable` and `@unchecked Sendable`

✅ **Action 1 (Cached Balanced Properties):** Eliminated redundant [`updateBalancedComponents()`](../TheElectricSlide/ContentView.swift:629) calls
- Balanced components stored in `@State` variables
- Updates only when `viewMode` or `selectedRuleId` changes
- [`StatorView`](../TheElectricSlide/ContentView.swift:395) remains stable during drag gestures

✅ **Action 3 Reverted:** Gesture handling back in optimal position
- Gesture applied directly to [`SlideView`](../TheElectricSlide/ContentView.swift:445) inside [`SideView.body`](../TheElectricSlide/ContentView.swift:517)
- Closures restored to [`SideView`](../TheElectricSlide/ContentView.swift:495) parameters
- No performance regression from rendering layers

### Current Performance Characteristics

**During Drag Gestures:**
- ✅ [`StatorView`](../TheElectricSlide/ContentView.swift:395) (top/bottom): No updates (stable balanced components)
- ✅ [`SlideView`](../TheElectricSlide/ContentView.swift:445): Smooth updates with `.interactiveSpring()` animation
- ✅ Gesture directly coupled with animated content
- ✅ No unnecessary rendering layers

**During View Mode Changes:**
- ✅ [`updateBalancedComponents()`](../TheElectricSlide/ContentView.swift:629) called appropriately
- ✅ All views update as expected
- ✅ Balanced scale spacers computed once per change

---

## Next Steps

### Remaining Optimizations to Explore

#### 1. Profile Complex Scales in Instruments
**Goal:** Measure rendering time for scales with 200+ tick marks (LL1, LL2, LL3)

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
**Goal:** Ensure cached balanced components don't cause memory issues

**Metrics to Track:**
- Memory usage when switching view modes
- Allocations during rule changes
- Retained size of balanced component arrays

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

### WWDC Sessions

- [WWDC 2024: SwiftUI Essentials](https://developer.apple.com/videos/play/wwdc2024/10150/) - Introduction to `onGeometryChange`
- [WWDC 2023: Demystify SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2023/10160/) - Performance best practices
- [WWDC 2021: Discover Concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019/) - Actor isolation patterns

### Related Documentation

- [Swift Concurrency: Sendable](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Sendable-Types)
- [Swift Evolution: SE-0302 Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)

---

## Document History

| Date | Version | Changes |
|------|---------|---------|
| 2025-01-28 | 1.0 | Initial documentation of performance optimization journey |

---

**Last Updated:** January 28, 2025  
**Author:** Performance optimization team  
**Status:** Active - monitoring performance metrics