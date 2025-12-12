# Precision Mode Implementation

## Overview

Precision mode provides fine-grained control for both the **cursor** and **slide** by reducing drag sensitivity after a long-press gesture. This enables users to position elements with sub-pixel accuracy, critical for precise slide rule calculations.

**GitHub Issue:** #61 - "Need better slide rule navigation, especially when zoomed in"

## Features

### 1. Long-Press to Activate (1 second)
- Hold finger for 1 second on cursor or slide
- Haptic "long buzz" confirms activation
- Subsequent drag movements are reduced by 5× (configurable)

### 2. Reduced Sensitivity Drag
- Normal drag: 1:1 finger-to-cursor/slide movement
- Precision drag: 5:1 finger movement required for same distance
- Enables positioning within 0.001 of normalized scale position

### 3. Finger-Lift Jitter Prevention
- Tracks `lastAppliedTranslation` during `onChanged` events
- Uses tracked value in `onEnded` instead of gesture's final translation
- Eliminates micro-movement on release (see "Technical Deep Dive" below)

### 4. Cooldown Period (0.5 seconds)
- After precision mode ends, normal gestures blocked briefly
- Prevents stale SwiftUI gesture events from firing
- Configurable duration for tuning

## Architecture

### Shared Constants: `PrecisionDragConstants`

Located in `TheElectricSlide/Utilities/PrecisionDragState.swift`:

```swift
enum PrecisionDragConstants {
    /// Long press duration to activate (seconds)
    static let longPressMinimumDuration: TimeInterval = 1.0
    
    /// Drag sensitivity reduction factor
    static let precisionFactor: CGFloat = 5.0
    
    /// Cooldown after precision mode ends (seconds)
    static let cooldownDuration: TimeInterval = 0.5
    
    /// Minimum movement threshold (normalized, 0.0-1.0)
    static let minimumMovementThreshold: CGFloat = 0.0005
}
```

**Conversion to Pixels:**
| Threshold | 400px scale | 800px scale | 1200px scale |
|-----------|-------------|-------------|--------------|
| 0.0001    | 0.04 px     | 0.08 px     | 0.12 px      |
| 0.0005    | 0.20 px     | 0.40 px     | 0.60 px      |
| 0.001     | 0.40 px     | 0.80 px     | 1.20 px      |

### Shared State: `PrecisionDragState`

Observable class for tracking precision gesture state:

```swift
@Observable
final class PrecisionDragState {
    var isSequenceActive: Bool = false      // Blocks normal gestures
    var sessionID: UUID? = nil              // Invalidates stale events
    var lastAppliedTranslation: CGFloat = 0 // Prevents finger-lift jitter
    
    func beginSession()                     // Start precision mode
    func endSession(cooldownDuration:)      // End with cooldown
    func trackTranslation(_ translation:)   // Store last applied value
}
```

## Implementation by Component

### Cursor: `CursorOverlay.swift`

Uses inline state (predates `PrecisionDragState` class but uses shared constants):

```swift
// State
@GestureState private var isPrecisionDragging: Bool = false
@State private var isPrecisionSequenceActive: Bool = false
@State private var lastAppliedPrecisionTranslation: CGFloat = 0

// Gesture structure
.gesture(normalDragGesture)           // Blocked during precision
.simultaneousGesture(
    LongPressGesture(minimumDuration: PrecisionDragConstants.longPressMinimumDuration)
        .sequenced(before: DragGesture())
        .onChanged { ... }
        .onEnded { ... }
)
```

### Slide: `SideView.swift`

Uses `PrecisionDragState` class:

```swift
@State private var slidePrecisionState = PrecisionDragState()
@GestureState private var isSlidePrecisionDragging: Bool = false

// Same gesture pattern as cursor
.gesture(normalDragGesture)
.simultaneousGesture(precisionGesture)
```

### Gesture Handlers: `ContentView+Gestures.swift`

Callbacks now accept `isPrecision: Bool`:

```swift
func handleDragChanged(_ gesture: DragGesture.Value, isPrecision: Bool) {
    let translationWidth = isPrecision
        ? gesture.translation.width / PrecisionDragConstants.precisionFactor
        : gesture.translation.width
    
    viewModel.handleSliderDragChanged(translation: translationWidth)
}
```

## Technical Deep Dive: Finger-Lift Jitter

### The Problem

SwiftUI's `DragGesture.onEnded` receives a **final translation value** that can differ from the last `onChanged` translation. When lifting a finger, tiny movements are captured only in `onEnded`:

```
Console logs showing the issue:
🎯 [Precision.onChanged] translation=0.00    ← Last update shows 0
🎯 [Precision.onEnded] translation=-0.94     ← But final has movement!
```

This caused visible cursor jumps on release, even with the user holding perfectly still.

### The Solution

1. **Track applied translation** in `onChanged`:
   ```swift
   case .second(true, let drag):
       lastAppliedPrecisionTranslation = drag.translation.width  // Store it
       handleDrag(drag, effectiveWidth: effectiveWidth, isPrecision: true)
   ```

2. **Use tracked value in `onEnded`**:
   ```swift
   .onEnded { value in
       // Use lastAppliedPrecisionTranslation, NOT gesture's final value
       handlePrecisionDragEnd(
           lastAppliedTranslation: lastAppliedPrecisionTranslation,
           width: effectiveWidth
       )
   }
   ```

3. **Dedicated handler** for precision end:
   ```swift
   private func handlePrecisionDragEnd(lastAppliedTranslation: CGFloat, width: CGFloat) {
       let translationWidth = lastAppliedTranslation / PrecisionDragConstants.precisionFactor
       // ... calculate and commit position
   }
   ```

## Gesture Blocking Strategy

### Three-Layer Protection

1. **`isSequenceActive` flag** - Primary block during precision mode
2. **Session UUID** - Identifies which gesture session is valid
3. **Movement threshold** - Rejects micro-movements below 0.0005 normalized

### Blocking Flow

```
User begins long-press
  │
  ├─→ Normal drag events still fire (finger down triggers both)
  │   └─→ IGNORED: below minimumMovementThreshold (translation ≈ 0)
  │
  ▼
Long press completes (1s)
  │
  ├─→ isPrecisionSequenceActive = true
  ├─→ sessionID = UUID()
  ├─→ Haptic: longBuzz()
  │
  ▼
Precision drag active
  │
  ├─→ Normal drag events blocked by isSequenceActive check
  ├─→ Precision onChanged applies 5× reduction
  │
  ▼
User lifts finger
  │
  ├─→ Precision onEnded commits with lastAppliedTranslation
  ├─→ Normal onEnded blocked by isSequenceActive
  │
  ▼
Cooldown period (0.5s)
  │
  ├─→ isSequenceActive still true
  ├─→ Any stale normal events blocked
  │
  ▼
Cooldown ends
  │
  └─→ isSequenceActive = false (normal gestures allowed)
```

## Debug Logging

Enable with `#if DEBUG` - logs are automatically included:

```
📍 [NormalDrag.onChanged] ALLOWED - translation=5.23
⚠️ [NormalDrag.onChanged] BLOCKED - precision sequence active
🎯 [Precision] MODE ACTIVATED - session=18650900
🎯 [Precision.onChanged] .second - dragging, translation=2.45
🎯 [Precision.onEnded] Using last applied translation=2.45
🎯 [Precision] SEQUENCE ENDED - ready for normal gestures
```

## Tuning Guide

### Adjusting Precision Factor

In `PrecisionDragState.swift`:

```swift
static let precisionFactor: CGFloat = 5.0  // Higher = more precision, slower movement
```

| Value | Behavior |
|-------|----------|
| 3.0   | Light precision, faster positioning |
| 5.0   | Default, good balance |
| 10.0  | Extreme precision, very slow |

### Adjusting Long-Press Duration

```swift
static let longPressMinimumDuration: TimeInterval = 1.0  // Seconds
```

| Value | Behavior |
|-------|----------|
| 0.5   | Quick activation, may trigger accidentally |
| 1.0   | Default, deliberate activation |
| 1.5   | Slow, prevents all accidental activation |

### Adjusting Cooldown Duration

```swift
static let cooldownDuration: TimeInterval = 0.5  // Seconds
```

| Value | Behavior |
|-------|----------|
| 0.25  | Minimal cooldown, may have edge-case jitter |
| 0.5   | Default, reliable |
| 0.75  | Conservative, longer delay before normal gestures |

## Files Modified

| File | Purpose |
|------|---------|
| `Utilities/PrecisionDragState.swift` | **NEW** - Shared constants and state class |
| `Cursor/CursorOverlay.swift` | Precision mode for cursor, uses shared constants |
| `Components/SideView.swift` | Precision mode for slide, uses `PrecisionDragState` |
| `Extensions/ContentView+Gestures.swift` | Handler callbacks with `isPrecision` param |
| `Components/DynamicSlideRuleContent.swift` | Updated callback type signatures |
| `Components/SlideRuleDetailView.swift` | Updated callback type signatures |

## Related Documentation

- [glass-cursor-master-plan.md](glass-cursor-master-plan.md) - Overall cursor architecture
- [cursor-reading-quick-reference.md](cursor-reading-quick-reference.md) - Cursor interaction patterns
- [pan-gesture.md](pan-gesture.md) - Related gesture handling for zoomed content
