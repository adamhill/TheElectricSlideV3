# Dual-Side Slide Rule Display - DRY Implementation Plan

**Date**: October 26, 2025  
**Branch**: adamhill/#4-scale-drawing-ux-typography  
**Status**: Design Phase

## Executive Summary

Modify `ContentView.swift` to display both sides (front and back) of a slide rule simultaneously while maximizing code reuse through DRY (Don't Repeat Yourself) principles. The `SlideRule` data structure already supports both sides via optional `backTopStator`, `backSlide`, and `backBottomStator` properties.

## Current State Analysis

### Existing Architecture
```swift
// SlideRule structure (SlideRuleAssembly.swift)
public struct SlideRule: Sendable {
    // Front side (side A) ✅ Currently displayed
    public let frontTopStator: Stator
    public let frontSlide: Slide
    public let frontBottomStator: Stator
    
    // Back side (side B) ⚠️ NOT currently displayed
    public let backTopStator: Stator?
    public let backSlide: Slide?
    public let backBottomStator: Stator?
}
```

### Current ContentView Structure
```
ContentView
├── VStack (spacing: 0)
│   ├── StatorView (frontTopStator) - FIXED
│   ├── SlideView (frontSlide) - MOVABLE with drag gesture
│   └── StatorView (frontBottomStator) - FIXED
```

### Current Implementation Strengths
1. ✅ **Component reuse**: `StatorView` and `SlideView` are already reusable
2. ✅ **Equatable optimization**: Views implement `Equatable` to prevent unnecessary redraws
3. ✅ **Responsive dimensions**: `onGeometryChange` pattern efficiently handles window resizing
4. ✅ **Separated state**: `sliderOffset` isolated from dimension calculations
5. ✅ **Pre-computed scales**: `GeneratedScale` contains pre-computed tick marks

### Current Implementation Challenges
1. ⚠️ **No back side display**: Optional back components ignored
2. ⚠️ **Hardcoded layout**: VStack structure is single-sided only
3. ⚠️ **No side toggle**: No UI mechanism to switch between front/back
4. ⚠️ **Duplicate gesture logic**: Would require duplication if both sides shown

## Design Goals

### Functional Requirements
1. **Display both sides simultaneously** - Show front and back in a single view
2. **Maintain DRY principles** - Reuse existing `StatorView`, `SlideView`, `ScaleView`
3. **Synchronized slide movement** - Front and back slides move together
4. **Responsive layout** - Adapt to window size changes efficiently
5. **Performance** - No regression in rendering performance
6. **Backward compatibility** - Support rules with only front side

### UX Requirements
1. **Visual separation** - Clear distinction between front and back sides
2. **Space efficiency** - Maximize use of screen real estate
3. **Label clarity** - Side labels (A/B or Front/Back) when both sides present
4. **Consistent interaction** - Drag gesture works identically on both sides

## Proposed Solution: Generic Side Component

### Architecture Overview

```
ContentView
├── VStack (spacing: 20) - Outer container
│   ├── SideView (side: .front) - Front side (A)
│   │   ├── Text("Side A / Front") - Header
│   │   ├── StatorView (topStator)
│   │   ├── SlideView (slide) + drag gesture
│   │   └── StatorView (bottomStator)
│   │
│   └── SideView (side: .back) - Back side (B) [if present]
│       ├── Text("Side B / Back") - Header
│       ├── StatorView (topStator)
│       ├── SlideView (slide) + drag gesture
│       └── StatorView (bottomStator)
```

### Key Design Pattern: Generic `SideView` Component

```swift
/// Renders one complete side of a slide rule (top stator, slide, bottom stator)
struct SideView: View, Equatable {
    let side: RuleSide
    let topStator: Stator
    let slide: Slide
    let bottomStator: Stator
    let width: CGFloat
    let scaleHeight: CGFloat
    let sliderOffset: Binding<CGFloat>  // Shared binding for synchronized movement
    let onDragGesture: (DragGesture.Value) -> Void
    let onDragEnd: (DragGesture.Value) -> Void
    
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        // Only compare properties affecting rendering (not closures)
        lhs.side == rhs.side &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.topStator.scales.count == rhs.topStator.scales.count &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.bottomStator.scales.count == rhs.bottomStator.scales.count
    }
}
```

### RuleSide Enum

```swift
enum RuleSide: String, Sendable {
    case front = "Front (Side A)"
    case back = "Back (Side B)"
    
    var displayName: String { rawValue }
}
```

## Implementation Plan

### Phase 1: Extract Side Component ⏳ PLANNED

**File**: `ContentView.swift`

**Changes**:
1. Create `RuleSide` enum at file level
2. Extract current VStack structure into new `SideView` component
3. Move drag gesture logic into `SideView`
4. Add `Equatable` conformance to `SideView`

**Estimated Lines**: ~80-100 lines (new component)

**Benefits**:
- Single source of truth for side layout
- Testable component in isolation
- Easier to maintain gesture logic

### Phase 2: Update ContentView for Dual Display ⏳ PLANNED

**File**: `ContentView.swift`

**Changes**:
1. Replace direct VStack with conditional rendering:
   ```swift
   VStack(spacing: 20) {
       // Front side - always present
       SideView(
           side: .front,
           topStator: slideRule.frontTopStator,
           slide: slideRule.frontSlide,
           bottomStator: slideRule.frontBottomStator,
           ...
       )
       
       // Back side - conditional
       if let backTop = slideRule.backTopStator,
          let backSlide = slideRule.backSlide,
          let backBottom = slideRule.backBottomStator {
           SideView(
               side: .back,
               topStator: backTop,
               slide: backSlide,
               bottomStator: backBottom,
               ...
           )
       }
   }
   ```

2. Update dimension calculations to account for two sides
3. Share `sliderOffset` binding between both `SideView` instances

**Estimated Changes**: ~50 lines modified

**Benefits**:
- Backward compatible (single-sided rules work unchanged)
- No code duplication
- Both sides use identical rendering pipeline

### Phase 3: Update Dimension Calculations ⏳ PLANNED

**File**: `ContentView.swift` - `calculateDimensions()` function

**Current Logic**:
```swift
private var totalScaleCount: Int {
    slideRule.frontTopStator.scales.count +
    slideRule.frontSlide.scales.count +
    slideRule.frontBottomStator.scales.count
}
```

**New Logic**:
```swift
private var totalScaleCount: Int {
    var count = slideRule.frontTopStator.scales.count +
                slideRule.frontSlide.scales.count +
                slideRule.frontBottomStator.scales.count
    
    // Add back side scales if present
    if let backTop = slideRule.backTopStator,
       let backSlide = slideRule.backSlide,
       let backBottom = slideRule.backBottomStator {
        count += backTop.scales.count +
                 backSlide.scales.count +
                 backBottom.scales.count
    }
    
    return count
}
```

**Additional Considerations**:
- Account for vertical spacing between sides (e.g., 20pt gap)
- Adjust `targetAspectRatio` if needed (may want wider display for two sides)
- Update padding calculations

**Estimated Changes**: ~15 lines

### Phase 4: Shared Gesture Handling ⏳ PLANNED

**Challenge**: Both front and back slides should move together, but drag gesture should work on either.

**Solution**: Shared state with binding pattern

```swift
// In ContentView
@State private var sliderOffset: CGFloat = 0
@State private var sliderBaseOffset: CGFloat = 0

// Pass to SideView as binding
SideView(
    ...,
    sliderOffset: $sliderOffset,
    onDragGesture: handleDragChange,
    onDragEnd: handleDragEnd
)

// Gesture handlers in ContentView (DRY - single implementation)
private func handleDragChange(_ gesture: DragGesture.Value) {
    let newOffset = sliderBaseOffset + gesture.translation.width
    sliderOffset = min(max(newOffset, -calculatedDimensions.width), 
                      calculatedDimensions.width)
}

private func handleDragEnd(_ gesture: DragGesture.Value) {
    sliderBaseOffset = sliderOffset
}
```

**Benefits**:
- Single gesture handler for both sides
- Synchronized movement guaranteed
- No duplicated gesture logic

**Estimated Changes**: ~20 lines

### Phase 5: Visual Polish ⏳ PLANNED

**Enhancements**:
1. **Side headers** - Add labels "Front (Side A)" and "Back (Side B)"
2. **Separator** - Visual divider between sides (e.g., thin gray line or spacer)
3. **Border styling** - Different border colors per side (front=blue, back=green)
4. **Optional toggle** - Future: Tab view or button to show one side at a time

**Example Header**:
```swift
// In SideView
VStack(spacing: 0) {
    // Side label
    Text(side.displayName)
        .font(.headline)
        .padding(.bottom, 4)
    
    // Stators and slide (existing layout)
    StatorView(...)
    SlideView(...)
    StatorView(...)
}
```

**Estimated Changes**: ~30 lines

## Testing Strategy

### Unit Tests (if testable)
- `RuleSide` enum cases and display names
- Dimension calculations with single/dual sides
- `SideView` Equatable conformance

### Visual Testing Checklist
- [ ] Single-sided rule displays correctly (backward compatibility)
- [ ] Dual-sided rule shows both sides vertically stacked
- [ ] Front and back slides move together when dragging
- [ ] Window resize maintains proper layout for both sides
- [ ] Headers/labels clearly identify each side
- [ ] No performance regression (smooth 60fps scrolling)

### Test Cases
1. **K&E 4081-3 Rule** - Has back side with LL scales
2. **Hemmi 266** - Dual-sided with different scale sets
3. **Simple C/D Rule** - Single-sided (backward compat test)

## Performance Considerations

### Optimization Strategies
1. ✅ **Maintain Equatable** - Both `SideView` and child views use `Equatable`
2. ✅ **Stable IDs** - Use `.id()` modifier for SwiftUI identity
3. ✅ **Separate state** - `sliderOffset` separate from `calculatedDimensions`
4. ✅ **Pre-computed ticks** - No change to `GeneratedScale` approach
5. ✅ **Canvas drawingGroup** - Keep Metal acceleration for Canvas

### Expected Performance
- **No regression**: Same rendering pipeline, just duplicated structure
- **Memory**: Minimal increase (two VStacks vs one, but shared `GeneratedScale` data)
- **Layout**: SwiftUI efficiently handles conditional rendering

## Code Metrics Estimate

| Phase | Lines Added | Lines Modified | Lines Deleted |
|-------|-------------|----------------|---------------|
| Phase 1 | ~100 | ~10 | 0 |
| Phase 2 | ~30 | ~50 | ~20 |
| Phase 3 | ~5 | ~15 | ~5 |
| Phase 4 | ~20 | ~10 | ~10 |
| Phase 5 | ~30 | ~10 | 0 |
| **Total** | **~185** | **~95** | **~35** |

**Net Change**: ~245 lines (ContentView.swift currently ~617 lines → ~862 lines)

## Alternative Designs Considered

### Alternative 1: TabView (Rejected)
```swift
TabView {
    SideView(...).tag(0)
    SideView(...).tag(1)
}
```
**Pros**: Clean separation, one side at a time  
**Cons**: Can't see both sides simultaneously, less like physical slide rule

### Alternative 2: ScrollView (Rejected)
```swift
ScrollView(.vertical) {
    VStack { ... }
}
```
**Pros**: Handles many sides gracefully  
**Cons**: Adds unnecessary scrolling complexity, not responsive

### Alternative 3: HStack Layout (Rejected)
```swift
HStack {
    SideView(.front)
    SideView(.back)
}
```
**Pros**: Side-by-side comparison  
**Cons**: Not enough horizontal space, breaks aspect ratio, harder to read

### Alternative 4: Accordion/Disclosure (Rejected)
```swift
DisclosureGroup("Back Side") {
    SideView(.back)
}
```
**Pros**: Saves space when not needed  
**Cons**: Extra interaction required, hides information by default

## Migration Path

### Backward Compatibility
All changes maintain backward compatibility:
- Rules with only front side work unchanged
- Optional back components gracefully handled
- No breaking changes to `SlideRule` structure

### Rollback Strategy
If issues arise:
1. Keep old ContentView in git history
2. Feature flag could control dual-side display
3. Fallback to single-side rendering if needed

## Success Criteria

### Definition of Done
- [ ] Both front and back sides render when present in `SlideRule`
- [ ] Single-sided rules render correctly (backward compat)
- [ ] Drag gesture synchronizes both slides
- [ ] Window resize handles both sides responsively
- [ ] Side labels clearly identify front/back
- [ ] No performance regression vs single-sided display
- [ ] Code passes existing tests (no regressions)
- [ ] Visual verification on macOS matches expectations

### Quality Gates
- Code review: DRY principles followed
- Performance test: 60fps maintained during drag
- Visual test: Both sides clearly distinguishable
- Accessibility: VoiceOver correctly identifies sides

## Timeline Estimate

| Phase | Estimated Time | Dependencies |
|-------|----------------|--------------|
| Phase 1 | 1-2 hours | None |
| Phase 2 | 1 hour | Phase 1 |
| Phase 3 | 30 minutes | Phase 2 |
| Phase 4 | 1 hour | Phase 2 |
| Phase 5 | 1 hour | Phases 1-4 |
| **Testing** | 2 hours | All phases |
| **Total** | **6.5-7.5 hours** | - |

## Future Enhancements (Out of Scope)

1. **Independent slide movement** - Allow front/back slides to move separately
2. **Side flip animation** - Animated transition between front/back
3. **Comparison mode** - Overlay front/back for alignment checks
4. **Export both sides** - PDF/image export includes both sides
5. **3D visualization** - Rotate between front/back in 3D space

## References

- **Existing Code**: `ContentView.swift` lines 1-617
- **Data Structure**: `SlideRuleAssembly.swift` lines 1-559
- **PostScript Reference**: `reference/postscript-rule-engine-explainer.md`
- **Performance Guide**: `swift-docs/swift-sliderule-rendering-improvements.md`
- **Testing Patterns**: `swift-docs/swift-testing-playbook.md`

## Approval & Sign-off

**Prepared by**: GitHub Copilot AI Agent  
**Review Required**: Yes  
**Breaking Changes**: No  
**Performance Impact**: Minimal (positive - better code organization)  
**Ready for Implementation**: Yes ✅
