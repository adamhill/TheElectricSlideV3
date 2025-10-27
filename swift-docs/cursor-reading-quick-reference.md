# Cursor Reading Feature - Quick Reference Card

## Overview

Real-time capture of scale values at cursor position. Updates automatically as cursor moves.

**Current Status**: ✅ Core cursor dragging working smoothly (60fps, no vibration)
**Reading Feature**: ✅ Fully implemented with hairline center positioning and slide offset tracking
**Known Issues**: None - readings update correctly for both cursor and slide movement

---

## Current Implementation Details

### Cursor Positioning Architecture

**Key Pattern**: `activeDragOffset` + `normalizedPosition`
- **During drag**: Visual position = `normalizedPosition * width + activeDragOffset`
- **On drag end**: Commit `activeDragOffset` to `normalizedPosition`, reset offset to 0
- **Why**: Separates real-time visual feedback from committed state, prevents animation conflicts

**Critical Detail**: Position Storage vs Hairline
- **Stored position** (`normalizedPosition`): LEFT EDGE of 108pt-wide cursor
- **Reading position**: LEFT EDGE + 54pt (cursor center = hairline)
- **Calculation**: `hairlinePosition = position + (cursorWidth/2) / scaleWidth`

### Custom ViewModifier for Smooth Dragging

```swift
struct CursorPositionModifier: ViewModifier {
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .animation(nil, value: offset)  // Critical: prevents vibration
    }
}
```

### Gesture Handling Pattern

```swift
.gesture(
    DragGesture(minimumDistance: 0, coordinateSpace: .local)
        .onChanged { gesture in
            withTransaction(Transaction(animation: nil)) {
                cursorState.activeDragOffset = gesture.translation.width
            }
        }
        .onEnded { gesture in
            handleDragEnd(gesture, width: effectiveWidth)
            withTransaction(Transaction(animation: nil)) {
                cursorState.activeDragOffset = 0
            }
        }
)
```

**Important**: No `@GestureState` - it's local per overlay, doesn't sync across both cursors.

---

## Core Components

### 1. ScaleReading (Single Reading)

```swift
struct ScaleReading {
    let scaleName: String      // "C", "D", "A", "K", etc.
    let formula: String         // "x", "x²", "x³", etc.
    let value: Double          // Calculated value at cursor
    let displayValue: String   // Formatted for display
    let side: RuleSide        // .front or .back
    let component: ComponentType  // .statorTop, .slide, .statorBottom
}
```

### 2. CursorReadings (Complete Snapshot)

```swift
struct CursorReadings {
    let cursorPosition: Double        // 0.0-1.0
    let timestamp: Date
    let frontReadings: [ScaleReading] // All front scales
    let backReadings: [ScaleReading]  // All back scales
    
    var allReadings: [ScaleReading]   // Combined array
    func reading(forScale: String, side: RuleSide) -> ScaleReading?
}
```

### 3. SlideRuleProvider Protocol

```swift
protocol SlideRuleProvider: AnyObject {
    func getFrontScaleData() -> (Stator, Slide, Stator)?
    func getBackScaleData() -> (Stator, Slide, Stator)?
    func getSlideOffset() -> CGFloat
    func getScaleWidth() -> CGFloat
}
```

---

## Implementation Checklist

### Step 1: Create CursorReadings.swift
- [ ] Create file: `TheElectricSlide/Cursor/CursorReadings.swift`
- [ ] Define `ScaleReading` struct
- [ ] Define `CursorReadings` struct
- [ ] Define `SlideRuleProvider` protocol
- [ ] Add calculation helpers in CursorState extension

### Step 2: Extend CursorState.swift
- [x] Add constant: `private let cursorWidth: CGFloat = 108`
- [x] Add property: `var currentReadings: CursorReadings?`
- [x] Add property: `var enableReadings: Bool = true`
- [x] Add property: `private var slideRuleProvider: SlideRuleProvider?`
- [x] Add method: `func setSlideRuleProvider(_ provider: SlideRuleProvider)`
- [x] Add method: `func updateReadings()` - includes hairline offset calculation
- [x] Add method: `private func queryScales(...) -> [ScaleReading]`
- [x] Modify `setPosition()` to call `updateReadings()` if enabled

### Step 3: Extend ContentView.swift
- [x] Add extension: `extension ContentView: SlideRuleProvider`
- [x] Implement `getFrontScaleData()`
- [x] Implement `getBackScaleData()`
- [x] Implement `getSlideOffset()` - returns `sliderOffset`
- [x] Implement `getScaleWidth()` - returns `calculatedDimensions.width`
- [x] Add `.onAppear { cursorState.setSlideRuleProvider(self) }`
- [x] Add `.onChange(of: sliderOffset) { cursorState.updateReadings() }` - triggers updates when slide moves

### Step 4: Test Reading Accuracy
- [ ] Test C scale at known positions (0.0→1.0, 0.301→2.0, 0.5→3.162, 1.0→10.0)
- [ ] Test inverted scale (CI reciprocal of C)
- [ ] Test square scale (A reads √value shown on D)
- [ ] Test cube scale (K reads ∛value shown on D)
- [ ] Test all scale types available in your rule

---

## Key Formulas

### Position → Value Calculation
```swift
// Core algorithm (from ScaleCalculator.swift:174-189)
let fL = function.transform(beginValue)
let fR = function.transform(endValue)
let fx = fL + position * (fR - fL)
let value = function.inverseTransform(fx)
```

### Slide Offset Handling
```swift
// For slide scales only
let slideOffsetNormalized = slideOffset / scaleWidth
let effectivePosition = cursorPosition - slideOffsetNormalized
let clampedPosition = min(max(effectivePosition, 0.0), 1.0)
```

### Value Formatting
```swift
// Priority: scale formatter → smart default
if let formatter = definition.labelFormatter {
    return formatter(value)
} else {
    return formatSmartDefault(value)  // Adaptive precision
}
```

---

## Performance Targets

| Metric | Target | Expected |
|--------|--------|----------|
| Single scale query | <0.01ms | ~0.002ms |
| Full update (20 scales) | <0.3ms | ~0.08ms |
| Memory per snapshot | <10 KB | ~5 KB |
| Impact on cursor drag | None | 60fps maintained |

---

## Common Pitfalls

### ❌ Don't Do This
```swift
// DON'T iterate through tick marks to find value
for tick in scale.tickMarks {
    if abs(tick.normalizedPosition - position) < tolerance {
        return tick.value  // SLOW! O(n) per scale
    }
}
```

### ✅ Do This Instead
```swift
// DO use direct calculation
let value = ScaleCalculator.value(at: position, on: definition)  // O(1)
```

### ❌ Don't Forget Slide Offset
```swift
// DON'T use cursor position directly for slide scales
let reading = calculateReading(at: cursorPosition, for: slideScale, ...)  // WRONG
```

### ✅ Remember to Adjust
```swift
// DO account for slide offset
let slidePos = cursorPosition - (slideOffset / scaleWidth)
let clampedSlidePos = min(max(slidePos, 0.0), 1.0)
let reading = calculateReading(at: clampedSlidePos, for: slideScale, ...)  // CORRECT
```

### ❌ Don't Use Left Edge Position for Readings
```swift
// DON'T use cursor position directly (it's the left edge!)
let reading = calculateReading(at: normalizedPosition, ...)  // WRONG - off by 54pt
```

### ✅ Calculate Hairline Center Position
```swift
// DO adjust for hairline center
let halfCursorWidthNormalized = (cursorWidth / 2.0) / scaleWidth
let hairlinePosition = normalizedPosition + halfCursorWidthNormalized
let reading = calculateReading(at: hairlinePosition, ...)  // CORRECT
```

### ❌ Don't Process Spacer Scales
```swift
// DON'T calculate readings for empty scales
for scale in stator.scales {
    let reading = calculateReading(...)  // Includes spacers!
}
```

### ✅ Filter Spacers First
```swift
// DO skip spacer scales
for scale in stator.scales {
    guard !scale.definition.name.isEmpty else { continue }  // Skip spacers
    let reading = calculateReading(...)
}
```

### ❌ Don't Forget Slide Movement Updates
```swift
// DON'T only update on cursor drag
func setPosition(...) {
    normalizedPosition = position
    updateReadings()  // Only updates when cursor moves - misses slide movement!
}
```

### ✅ Track Slide Offset Changes
```swift
// DO observe slide offset in ContentView
.onChange(of: sliderOffset) { oldValue, newValue in
    cursorState.updateReadings()  // Update when slide moves too!
}
```

---

## Testing Quick Reference

### Unit Test Template
```swift
@Test("Reading at known position")
func readingAccuracy() {
    let cScale = StandardScales.cScale(length: 250.0)
    let generated = GeneratedScale(definition: cScale)
    
    let reading = calculateReading(at: 0.301, for: generated, ...)
    
    #expect(abs(reading.value - 2.0) < 0.01)  // log₁₀(2) = 0.301
    #expect(reading.scaleName == "C")
}
```

### Performance Test Template
```swift
@Test("Reading update performance")
func updatePerformance() async {
    let state = CursorState()
    // ... setup with 20 scales ...
    
    let start = ContinuousClock.now
    state.updateReadings()
    let duration = start.duration(to: .now)
    
    #expect(duration < .milliseconds(0.3))
}
```

### Mathematical Verification
```swift
// Test scale relationships at same position
let pos = 0.5
let cValue = ScaleCalculator.value(at: pos, on: cScale)   // C: ~3.162
let dValue = ScaleCalculator.value(at: pos, on: dScale)   // D: ~3.162 (same)
let aValue = ScaleCalculator.value(at: pos, on: aScale)   // A: ~3.162 (same)
let ciValue = ScaleCalculator.value(at: pos, on: ciScale) // CI: ~0.316 (reciprocal)

#expect(abs(cValue - dValue) < 0.001)      // C = D at same position
#expect(abs(ciValue - 1.0/cValue) < 0.01)  // CI = 1/C
```

---

## File Locations

| File | Purpose | Lines Added |
|------|---------|-------------|
| `Cursor/CursorReadings.swift` | Data structures + helpers | ~180 new |
| `Cursor/CursorState.swift` | Reading methods | ~180 added |
| `ContentView.swift` | SlideRuleProvider conformance | ~33 added |

**Total**: ~393 lines for complete reading feature

---

## Quick Integration Steps

1. **Create** `CursorReadings.swift` with structs and protocol
2. **Extend** `CursorState.swift` with reading properties and methods
3. **Add** `SlideRuleProvider` conformance to `ContentView`
4. **Wire** up provider in `ContentView.onAppear`
5. **Test** reading accuracy for all scale types
6. **Verify** performance < 0.3ms

---

## Troubleshooting

### Readings Not Updating
1. Check `enableReadings == true`
2. Verify `setSlideRuleProvider()` called
3. Confirm provider methods return non-nil
4. Ensure `setPosition()` calls `updateReadings()`
5. **Verify slide offset tracking**: Check `.onChange(of: sliderOffset)` triggers updates

### Readings Off by ~54pt (Half Cursor Width)
1. **Verify hairline calculation**: Must add `(cursorWidth/2) / scaleWidth` to position
2. Check `updateReadings(at:)` uses `hairlinePosition`, not raw `position`
3. Confirm cursor width constant matches `CursorView` (108pt)

### Slide Readings Wrong
1. Verify offset normalization: `slideOffset / scaleWidth`
2. Check position clamping: `min(max(pos, 0.0), 1.0)`
3. Confirm offset subtracted from **hairline** position (not left edge)
4. **Check slide movement tracking**: Verify `.onChange(of: sliderOffset)` exists

### Performance Issues
1. Profile with Instruments Time Profiler
2. Verify no tick mark iteration (use direct calculation)
3. Check formatter isn't allocating repeatedly
4. Consider disabling during rapid drag if needed

### Invalid Values
1. Check for `NaN` or `Inf`: `value.isFinite`
2. Handle gracefully: display as "—" (em dash)
3. Verify scale function domain validity

---

## Expected Reading Examples

| Scale | Position | Expected Value | Formatted Display |
|-------|----------|----------------|-------------------|
| C | 0.0 | 1.0 | "1" |
| C | 0.301 | 2.0 | "2.0" |
| C | 0.5 | 3.162 | "3.16" |
| C | 1.0 | 10.0 | "10" |
| D | 0.5 | 3.162 | "3.16" |
| CI | 0.5 | 0.316 | "0.32" |
| A | 0.5 | 3.162 | "3.16" |
| K | 0.333 | 2.154 | "2" (compact) |
| L | 0.5 | 0.5 | "0.5" |
| S | varies | angle | "30" (angle fmt) |

---

## Reference Documents

- **Architecture**: [`glass-cursor-architecture.md`](glass-cursor-architecture.md:1) - Section 16
- **Implementation**: [`glass-cursor-implementation-plan.md`](glass-cursor-implementation-plan.md:1) - Steps 6A-6D
- **Master Plan**: [`glass-cursor-master-plan.md`](glass-cursor-master-plan.md:1) - Updated timelines
- **Core Calculator**: [`ScaleCalculator.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleCalculator.swift:174) - value(at:on:)

---

**Document Version**: 1.0  
**Created**: October 26, 2025  
**Purpose**: Quick reference for implementing cursor reading feature