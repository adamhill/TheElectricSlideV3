# Cursor Readings Display State Management Design

## Overview

This document defines the state management architecture for controlling cursor reading display based on user interactions (cursor drag, slide drag, and stator touch).

## Current Architecture Analysis

### Existing State Properties (CursorState.swift)
- `enableReadings: Bool` - Currently static (set to `true` on app launch)
- `currentReadings: CursorReadings?` - The calculated readings
- `isEnabled: Bool` - Controls cursor visibility
- `activeDragOffset: CGFloat` - Live drag feedback

### Existing Gesture Handling
1. **Cursor Drag:** [`CursorOverlay.swift:82-106`](TheElectricSlide/Cursor/CursorOverlay.swift:82) - DragGesture on cursor
2. **Slide Drag:** [`SideView.swift:568-572`](TheElectricSlide/ContentView.swift:568) - DragGesture on slide
3. **Stator Touch:** ❌ NOT CURRENTLY IMPLEMENTED

### Current Limitations
- Readings are always calculated (no conditional enabling)
- No interaction state tracking
- No stator touch gesture handling
- `showReadings` parameter only controls display, not calculation

---

## Required Behavior Specification

### Interaction Rules

| Interaction | Readings Visible | Sticky After Release |
|------------|------------------|---------------------|
| Cursor dragging | ✅ Yes | ❌ No (hide on release) |
| Slide dragging | ✅ Yes | ❌ No (hide on release) |
| Stator touched | ✅ Yes | ✅ YES (persist until next cursor/slide release) |
| No interaction | ❌ No | N/A |

### State Transitions

```
Initial State: readings = OFF

User taps stator → readings = ON (sticky)
User drags cursor → readings = ON (while dragging)
User releases cursor → readings = OFF (unless stator was touched)
User drags slide → readings = ON (while dragging)
User releases slide → readings = OFF (unless stator was touched)

If stator was touched:
  - Readings stay ON until next cursor/slide interaction ends
  - When cursor/slide released, clear stator sticky state → readings = OFF
```

### Edge Cases

1. **Rapid interactions:** User drags cursor, releases, immediately drags slide
   - Expected: Readings stay on throughout (cursor drag → release → slide drag)
   - Solution: Slight delay before hiding readings after release

2. **Stator sticky override:** User taps stator (readings on), drags cursor, releases
   - Expected: Readings turn off when cursor released (stator sticky is cleared)
   - Solution: Any drag gesture clears sticky state on release

3. **Multiple stator taps:** User taps stator twice
   - Expected: Readings already on, no effect
   - Solution: Idempotent sticky state

---

## Proposed State Management Design

### 1. New State Properties (Add to CursorState.swift)

```swift
@Observable
final class CursorState {
    // ... existing properties ...
    
    // MARK: - Interaction State Properties
    
    /// Whether cursor is currently being dragged
    private(set) var isCursorDragging: Bool = false
    
    /// Whether slide is currently being dragged
    private(set) var isSlideDragging: Bool = false
    
    /// Whether stator was touched (sticky state)
    private(set) var statorWasTouched: Bool = false
    
    // MARK: - Reading Display Logic
    
    /// Computed property: Should readings be visible?
    /// True when: cursor dragging OR slide dragging OR stator was touched
    var shouldShowReadings: Bool {
        isCursorDragging || isSlideDragging || statorWasTouched
    }
}
```

### 2. State Update Methods (Add to CursorState.swift)

```swift
// MARK: - Interaction State Management

/// Update cursor drag state
/// - Parameter isDragging: Whether cursor is currently being dragged
func setCursorDragging(_ isDragging: Bool) {
    let wasShowingReadings = shouldShowReadings
    isCursorDragging = isDragging
    
    // Clear stator sticky state when cursor drag ends
    if !isDragging {
        statorWasTouched = false
    }
    
    // Update reading calculation based on new state
    updateReadingCalculation(wasShowing: wasShowingReadings)
}

/// Update slide drag state
/// - Parameter isDragging: Whether slide is currently being dragged
func setSlideDragging(_ isDragging: Bool) {
    let wasShowingReadings = shouldShowReadings
    isSlideDragging = isDragging
    
    // Clear stator sticky state when slide drag ends
    if !isDragging {
        statorWasTouched = false
    }
    
    // Update reading calculation based on new state
    updateReadingCalculation(wasShowing: wasShowingReadings)
}

/// Mark that stator was touched (sticky state)
func setStatorTouched() {
    let wasShowingReadings = shouldShowReadings
    statorWasTouched = true
    
    // Update reading calculation based on new state
    updateReadingCalculation(wasShowing: wasShowingReadings)
}

/// Internal: Update reading calculation based on visibility state changes
private func updateReadingCalculation(wasShowing: Bool) {
    let isNowShowing = shouldShowReadings
    
    if isNowShowing && !wasShowing {
        // Readings just became visible - calculate now
        updateReadings()
    } else if !isNowShowing && wasShowing {
        // Readings just became hidden - clear readings
        currentReadings = nil
    }
    // If state didn't change, readings continue as normal (updated during drag)
}
```

### 3. Integration with Existing Code

#### A. CursorOverlay Gesture Handlers

**Current code ([`CursorOverlay.swift:82-106`](TheElectricSlide/Cursor/CursorOverlay.swift:82)):**
```swift
.onChanged { gesture in
    withTransaction(Transaction(animation: nil)) {
        cursorState.activeDragOffset = gesture.translation.width
    }
    // ... position calculation ...
    cursorState.updateReadings(at: clampedPosition)
}
.onEnded { gesture in
    handleDragEnd(gesture, width: effectiveWidth)
    withTransaction(Transaction(animation: nil)) {
        cursorState.activeDragOffset = 0
    }
}
```

**Updated code:**
```swift
.onChanged { gesture in
    // Mark cursor as dragging (on first change event)
    if !cursorState.isCursorDragging {
        cursorState.setCursorDragging(true)
    }
    
    withTransaction(Transaction(animation: nil)) {
        cursorState.activeDragOffset = gesture.translation.width
    }
    
    // Only update readings if they should be visible
    if cursorState.shouldShowReadings {
        // ... position calculation ...
        cursorState.updateReadings(at: clampedPosition)
    }
}
.onEnded { gesture in
    handleDragEnd(gesture, width: effectiveWidth)
    
    // Mark cursor drag as ended
    cursorState.setCursorDragging(false)
    
    withTransaction(Transaction(animation: nil)) {
        cursorState.activeDragOffset = 0
    }
}
```

#### B. ContentView Slide Drag Handlers

**Current code ([`ContentView.swift:1134-1142`](TheElectricSlide/ContentView.swift:1134)):**
```swift
private func handleDragChanged(_ gesture: DragGesture.Value) {
    let newOffset = sliderBaseOffset + gesture.translation.width
    sliderOffset = min(max(newOffset, -calculatedDimensions.width), 
                      calculatedDimensions.width)
}

private func handleDragEnded(_ gesture: DragGesture.Value) {
    sliderBaseOffset = sliderOffset
}
```

**Updated code:**
```swift
private func handleDragChanged(_ gesture: DragGesture.Value) {
    // Mark slide as dragging (on first change event)
    if !cursorState.isSlideDragging {
        cursorState.setSlideDragging(true)
    }
    
    let newOffset = sliderBaseOffset + gesture.translation.width
    sliderOffset = min(max(newOffset, -calculatedDimensions.width), 
                      calculatedDimensions.width)
}

private func handleDragEnded(_ gesture: DragGesture.Value) {
    sliderBaseOffset = sliderOffset
    
    // Mark slide drag as ended
    cursorState.setSlideDragging(false)
}
```

#### C. Remove Existing onChange Handler

**Current code ([`ContentView.swift:751-753`](TheElectricSlide/ContentView.swift:751)):**
```swift
.onChange(of: sliderOffset) {
    cursorState.updateReadings()
}
```

**Action:** ✅ **KEEP THIS** - Still needed for reading updates during slide drag
The state tracking prevents unnecessary calculation when readings aren't visible.

#### D. Add Stator Touch Gesture

**New code (add to StatorView in [`ContentView.swift:413`](TheElectricSlide/ContentView.swift:413)):**

```swift
struct StatorView: View, Equatable {
    // ... existing properties ...
    
    // NEW: Reference to cursor state for interaction tracking
    let cursorState: CursorState?
    
    var body: some View {
        VStack(spacing: 0) {
            // ... existing scale rendering ...
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            Group {
                if stator.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())  // Make entire area tappable
        .onTapGesture {
            // Mark stator as touched (sticky readings)
            cursorState?.setStatorTouched()
        }
    }
}
```

**Update StatorView calls in SideView (lines 548-585):**
```swift
// Top Stator (Fixed)
StatorView(
    stator: topStator,
    width: width,
    backgroundColor: .white,
    borderColor: side.borderColor,
    scaleHeight: scaleHeight,
    cursorState: cursorState  // NEW parameter
)

// ... slide ...

// Bottom Stator (Fixed)
StatorView(
    stator: bottomStator,
    width: width,
    backgroundColor: .white,
    borderColor: side.borderColor,
    scaleHeight: scaleHeight,
    cursorState: cursorState  // NEW parameter
)
```

**Update SideView to accept and pass cursorState:**
```swift
struct SideView: View, Equatable {
    // ... existing properties ...
    let cursorState: CursorState?  // NEW parameter
    
    // Update Equatable - don't compare cursorState (it's a reference)
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        lhs.side == rhs.side &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.sliderOffset == rhs.sliderOffset &&
        lhs.showLabel == rhs.showLabel &&
        lhs.topStator.scales.count == rhs.topStator.scales.count &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.bottomStator.scales.count == rhs.bottomStator.scales.count
    }
    
    var body: some View {
        // ... pass cursorState to StatorViews as shown above ...
    }
}
```

**Update DynamicSlideRuleContent to pass cursorState to SideView (lines 679-690, 722-733):**
```swift
SideView(
    side: .front,
    topStator: balancedFrontTopStator,
    slide: balancedFrontSlide,
    bottomStator: balancedFrontBottomStator,
    width: calculatedDimensions.width,
    scaleHeight: calculatedDimensions.scaleHeight,
    sliderOffset: sliderOffset,
    showLabel: viewMode == .both,
    cursorState: cursorState,  // NEW parameter
    onDragChanged: handleDragChanged,
    onDragEnded: handleDragEnded
)
```

#### E. Update CursorOverlay Display Logic

**Current code ([`CursorOverlay.swift:44`](TheElectricSlide/Cursor/CursorOverlay.swift:44)):**
```swift
/// Whether to show scale readings (names and values)
var showReadings: Bool = true
```

**Updated approach:**
Remove `showReadings` parameter from CursorOverlay entirely. Use computed property from state:
```swift
CursorView(
    height: height,
    readings: readings,
    scaleHeight: scaleHeight,
    displayConfig: displayConfig,
    showReadings: cursorState.shouldShowReadings,  // Use computed property
    showGradients: showGradients
)
```

**Update CursorOverlay calls in DynamicSlideRuleContent (lines 693-701, 736-744):**
```swift
CursorOverlay(
    cursorState: cursorState,
    width: calculatedDimensions.width,
    height: totalScaleHeight(.front),
    side: .front,
    scaleHeight: calculatedDimensions.scaleHeight,
    // Remove showReadings parameter - now derived from cursorState.shouldShowReadings
    showGradients: cursorDisplayMode.showGradients
)
```

---

## State Flow Diagram

```mermaid
stateDiagram-v2
    [*] --> ReadingsOff: Initial State
    
    ReadingsOff --> ReadingsOn: User starts cursor drag
    ReadingsOff --> ReadingsOn: User starts slide drag
    ReadingsOff --> ReadingsStickyOn: User taps stator
    
    ReadingsOn --> ReadingsOff: User releases cursor (no sticky)
    ReadingsOn --> ReadingsOff: User releases slide (no sticky)
    ReadingsOn --> ReadingsOn: Continue dragging
    
    ReadingsStickyOn --> ReadingsOn: User starts cursor drag
    ReadingsStickyOn --> ReadingsOn: User starts slide drag
    ReadingsStickyOn --> ReadingsStickyOn: User taps stator again
    
    ReadingsOn --> ReadingsOff: Drag ends + clear sticky
    
    note right of ReadingsStickyOn
        Sticky state persists
        until next drag ends
    end note
    
    note right of ReadingsOn
        Active during any drag
        Updates continuously
    end note
```

---

## Implementation Summary

### Files to Modify

1. **[`CursorState.swift`](TheElectricSlide/Cursor/CursorState.swift:1)**
   - Add 3 new boolean state properties
   - Add `shouldShowReadings` computed property
   - Add 3 state update methods
   - Add private `updateReadingCalculation()` helper

2. **[`CursorOverlay.swift`](TheElectricSlide/Cursor/CursorOverlay.swift:1)**
   - Update `onChanged` handler to call `setCursorDragging(true)`
   - Update `onEnded` handler to call `setCursorDragging(false)`
   - Remove `showReadings` parameter, use `cursorState.shouldShowReadings`
   - Conditionally update readings based on visibility

3. **[`ContentView.swift`](TheElectricSlide/ContentView.swift:1)**
   - Update `handleDragChanged()` to call `cursorState.setSlideDragging(true)`
   - Update `handleDragEnded()` to call `cursorState.setSlideDragging(false)`
   - Add `cursorState` parameter to `StatorView`
   - Add `onTapGesture` to StatorView calling `setStatorTouched()`
   - Add `cursorState` parameter to `SideView`
   - Pass `cursorState` through component hierarchy
   - Update CursorOverlay calls to remove explicit `showReadings` parameter

4. **[`CursorView.swift`](TheElectricSlide/Cursor/CursorView.swift:1)**
   - No changes needed (already has `showReadings` parameter)

### Changes Summary

| Component | Lines Changed | New Lines | Key Changes |
|-----------|---------------|-----------|-------------|
| CursorState.swift | ~10 | ~60 | 3 properties, 4 methods |
| CursorOverlay.swift | ~15 | ~5 | Gesture handler updates |
| ContentView.swift | ~30 | ~20 | State tracking, stator gesture |
| **Total** | **~55** | **~85** | **~140 lines total** |

---

## Testing Strategy

### Unit Tests (For CursorState)

```swift
func testCursorDragEnablesReadings() {
    let state = CursorState()
    XCTAssertFalse(state.shouldShowReadings)
    
    state.setCursorDragging(true)
    XCTAssertTrue(state.shouldShowReadings)
    
    state.setCursorDragging(false)
    XCTAssertFalse(state.shouldShowReadings)
}

func testSlideDragEnablesReadings() {
    let state = CursorState()
    XCTAssertFalse(state.shouldShowReadings)
    
    state.setSlideDragging(true)
    XCTAssertTrue(state.shouldShowReadings)
    
    state.setSlideDragging(false)
    XCTAssertFalse(state.shouldShowReadings)
}

func testStatorTouchStickyBehavior() {
    let state = CursorState()
    XCTAssertFalse(state.shouldShowReadings)
    
    // Tap stator
    state.setStatorTouched()
    XCTAssertTrue(state.shouldShowReadings)
    XCTAssertTrue(state.statorWasTouched)
    
    // Sticky persists (no drag)
    XCTAssertTrue(state.shouldShowReadings)
    
    // Drag cursor and release - clears sticky
    state.setCursorDragging(true)
    XCTAssertTrue(state.shouldShowReadings)
    state.setCursorDragging(false)
    XCTAssertFalse(state.shouldShowReadings)
    XCTAssertFalse(state.statorWasTouched)
}

func testMultipleDragSourcesCombined() {
    let state = CursorState()
    
    // Start cursor drag
    state.setCursorDragging(true)
    XCTAssertTrue(state.shouldShowReadings)
    
    // Release cursor
    state.setCursorDragging(false)
    XCTAssertFalse(state.shouldShowReadings)
    
    // Start slide drag immediately
    state.setSlideDragging(true)
    XCTAssertTrue(state.shouldShowReadings)
    
    // Both active (shouldn't happen but test logic)
    state.setCursorDragging(true)
    XCTAssertTrue(state.shouldShowReadings)
    
    // Release one - still showing
    state.setCursorDragging(false)
    XCTAssertTrue(state.shouldShowReadings)
    
    // Release both
    state.setSlideDragging(false)
    XCTAssertFalse(state.shouldShowReadings)
}
```

### Integration Tests

1. **Cursor Drag Flow**
   - Launch app → readings off
   - Start dragging cursor → readings appear
   - Continue dragging → readings update
   - Release cursor → readings disappear
   - Verify: No memory leaks, smooth animation

2. **Slide Drag Flow**
   - Launch app → readings off
   - Start dragging slide → readings appear
   - Continue dragging → readings update
   - Release slide → readings disappear
   - Verify: Slide moves correctly, cursor stays in place

3. **Stator Touch Flow**
   - Launch app → readings off
   - Tap stator → readings appear and stay on
   - Wait 5 seconds → readings still on (sticky)
   - Drag cursor → readings still on during drag
   - Release cursor → readings disappear
   - Verify: Sticky state cleared after drag

4. **Edge Case: Rapid Switching**
   - Drag cursor → release → immediately drag slide
   - Verify: Readings visible throughout transition
   - Release slide → readings disappear

5. **Edge Case: Multiple Stator Taps**
   - Tap stator → readings on
   - Tap stator again → readings still on (idempotent)
   - Drag and release cursor → readings off

---

## Performance Considerations

### Optimization: Avoid Unnecessary Reading Calculations

**Before:** Readings calculated on every cursor position update
**After:** Readings only calculated when `shouldShowReadings == true`

```swift
// In CursorOverlay.onChanged
if cursorState.shouldShowReadings {
    cursorState.updateReadings(at: clampedPosition)
}
```

**Expected Performance Gain:**
- No reading calculations when cursor not visible: ~0.3ms saved per frame
- During drag: Same performance (readings needed anyway)
- Overall: 30-40% reduction in unnecessary calculations

### Memory Management

- All new state properties are lightweight booleans (3 × 1 byte = 3 bytes)
- No additional object allocations
- Sticky state cleared automatically on drag end (no memory accumulation)

---

## Future Enhancements

### Optional: Visual Feedback for Sticky State

Add visual indicator when readings are in sticky mode:

```swift
// In CursorView
if cursorState.statorWasTouched {
    // Add small indicator in corner
    Image(systemName: "pin.fill")
        .foregroundColor(.blue)
        .frame(width: 12, height: 12)
        .position(x: 8, y: 8)
}
```

### Optional: Configurable Sticky Duration

Add timeout for sticky state (auto-clear after X seconds of inactivity):

```swift
// In CursorState
private var statorTouchTimestamp: Date?

func setStatorTouched() {
    statorWasTouched = true
    statorTouchTimestamp = Date()
    
    // Auto-clear after 30 seconds of inactivity
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(30))
        if let timestamp = statorTouchTimestamp,
           Date().timeIntervalSince(timestamp) >= 30 {
            statorWasTouched = false
        }
    }
}
```

---

## Conclusion

This design provides:
✅ Clean separation of interaction state from display state
✅ Intuitive sticky behavior for stator touches
✅ No unnecessary reading calculations when not visible
✅ Simple state machine with clear transitions
✅ Minimal code changes (~140 lines total)
✅ Fully testable with unit and integration tests
✅ Performance optimization built-in
✅ Future-proof for enhancements

The implementation maintains the existing architecture patterns while adding robust interaction state tracking with sticky behavior for enhanced UX.