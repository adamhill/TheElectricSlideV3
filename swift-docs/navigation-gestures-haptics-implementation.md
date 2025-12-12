# Navigation Gestures Implementation

## Overview

This document covers the navigation gesture improvements added to The Electric Slide app to improve user experience, especially when zoomed in on the slide rule.

**GitHub Issue:** #61 - "Need better slide rule navigation, especially when zoomed in"

## Features Implemented

### 1. Vertical Swipe to Flip Sides

Swipe up or down across the slide rule body to flip between front and back sides on devices that show one side at a time (iPhone).

### 2. Long-Press Precision Mode

Press and hold for 1 second on either the cursor or slide to activate precision mode, which reduces drag sensitivity by 5× for fine-grained positioning.

### 3. Slide Tick Haptics

Feel haptic feedback when the slide moves and crosses tick marks under the cursor hairline. Uses the C scale when available, otherwise the first scale on the current slide.

### 4. Cursor Tick Haptics

Feel haptic feedback when dragging the cursor (glass indicator) across the slide rule. Triggers when the cursor hairline crosses tick marks on the stationary scales.

---

## 1. Vertical Swipe to Flip Sides

### Purpose
On compact devices (iPhone) where only one side is shown at a time, users can flip between front and back sides with a natural vertical swipe gesture instead of tapping the flip button.

### Implementation: `SideView.swift`

```swift
// Constants
private static let verticalSwipeThreshold: CGFloat = 50

// State
@State private var hasTriggeredFlip: Bool = false

// Gesture
.simultaneousGesture(
    DragGesture(minimumDistance: 30, coordinateSpace: .local)
        .onChanged { gesture in
            guard !hasTriggeredFlip, onFlip != nil else { return }
            
            let verticalDistance = abs(gesture.translation.height)
            let horizontalDistance = abs(gesture.translation.width)
            
            // Require vertical motion to dominate horizontal
            if verticalDistance > Self.verticalSwipeThreshold &&
               verticalDistance > horizontalDistance * 1.5 {
                hasTriggeredFlip = true
                HapticManager.flipFeedback()
                onFlip?()
            }
        }
        .onEnded { _ in
            hasTriggeredFlip = false
        }
)
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| 50pt threshold | Prevents accidental triggers from slight finger movements |
| 1.5× vertical ratio | Ensures intentional vertical motion, not diagonal slide drags |
| `hasTriggeredFlip` flag | Prevents multiple flips during a single gesture |
| `simultaneousGesture` | Allows coexistence with slide drag gesture |

### Callback Chain

```
SideView.onFlip
    ↓
DynamicSlideRuleContent.handleFlip
    ↓
SlideRuleDetailView.handleFlip
    ↓
ContentView.handleFlip() → toggles viewMode (.front ↔ .back)
```

---

## 2. Long-Press Precision Mode

### Purpose
Enable fine-grained positioning of cursor and slide for precise calculations. After holding for 1 second, subsequent drag movements are reduced by 5×.

### Activation Flow

```
Finger down on cursor/slide
    ↓ (1 second hold)
Long press recognized
    ↓
Haptic "long buzz" feedback
    ↓
Precision mode active (5× slower drag)
    ↓
Finger lifts
    ↓
Position committed, cooldown period starts
    ↓ (0.5 seconds)
Normal gestures re-enabled
```

### Implementation Details

See [precision-mode-implementation.md](precision-mode-implementation.md) for complete technical documentation including:
- Finger-lift jitter prevention
- Three-layer gesture blocking strategy
- Shared constants and state management
- Tuning guide

### Quick Reference

| Parameter | Value | Location |
|-----------|-------|----------|
| Long press duration | 1.0s | `PrecisionDragConstants.longPressMinimumDuration` |
| Sensitivity factor | 5.0× | `PrecisionDragConstants.precisionFactor` |
| Cooldown duration | 0.5s | `PrecisionDragConstants.cooldownDuration` |

---

## 3. Slide Tick Haptics

### Purpose
Provide tactile feedback as the slide moves, helping users "feel" when crossing major tick marks. Different intensity haptics for different tick levels.

---

## 4. Cursor Tick Haptics

### Purpose
Provide tactile feedback as the cursor moves across the slide rule, helping users "feel" when the hairline crosses tick marks. Uses the same tick level haptic intensity as slide haptics.

### Callback Architecture

Cursor haptics use a callback pattern to propagate drag events back to ContentView+Gestures.swift, where the tick crossing logic is centralized (DRY principle with slide haptics):

```
CursorOverlay.handleDrag()
    ↓
onCursorDragChanged(normalizedPosition)
    ↓
DynamicSlideRuleContent.handleCursorDragChanged
    ↓
SlideRuleDetailView.handleCursorDragChanged
    ↓
ContentView.handleCursorDragChanged()
    ↓
ContentView+Gestures.handleCursorDragChanged(_:)
    ↓
tickHapticCoordinator.checkTickCrossing(...)
```

### Implementation: `CursorOverlay.swift`

```swift
/// Callback for tick haptics during cursor drag (passes normalized cursor position)
var onCursorDragChanged: ((CGFloat) -> Void)? = nil

/// Callback when cursor drag ends (for resetting tick haptic coordinator)
var onCursorDragEnded: (() -> Void)? = nil

private func handleDrag(_ value: DragGesture.Value) {
    // ... cursor position calculation ...
    
    // Notify parent for tick haptics
    onCursorDragChanged?(clampedPosition)
}

private func handleDragEnd(_ value: DragGesture.Value) {
    // ... finalize cursor position ...
    
    // Reset tick haptic coordinator for next drag
    onCursorDragEnded?()
}
```

### Integration: `ContentView+Gestures.swift`

```swift
func handleCursorDragChanged(_ cursorNormalizedPosition: CGFloat) {
    // Select scale based on view mode (same DRY logic as slide haptics)
    let hapticScale: GeneratedScale? = {
        switch viewMode {
        case .front:
            return currentSlideRule.frontSlide.scales.first(where: { $0.definition.name == "C" })
                ?? currentSlideRule.frontSlide.scales.first
        case .back:
            return currentSlideRule.backSlide?.scales.first(where: { $0.definition.name == "C" })
                ?? currentSlideRule.backSlide?.scales.first
        case .both:
            // iPad: prioritize C scale from either slide, preferring front
            if let cScale = currentSlideRule.frontSlide.scales.first(where: { $0.definition.name == "C" }) {
                return cScale
            }
            if let cScale = currentSlideRule.backSlide?.scales.first(where: { $0.definition.name == "C" }) {
                return cScale
            }
            return currentSlideRule.frontSlide.scales.first
                ?? currentSlideRule.backSlide?.scales.first
        }
    }()
    
    if let scale = hapticScale {
        let hairlinePosition = cursorNormalizedPosition + halfCursorWidthNormalized
        
        tickHapticCoordinator.checkTickCrossing(
            cursorNormalizedPosition: hairlinePosition,
            slideOffset: viewModel.sliderOffset,
            scaleWidth: scaleWidth,
            cScale: scale
        )
    }
}

func handleCursorDragEnded() {
    tickHapticCoordinator.reset()
}
```

### Key Design Decisions

| Decision | Rationale |
|----------|----------|
| Callback closure pattern | Allows CursorOverlay to remain decoupled from tick haptic logic |
| Shared scale selection logic | DRY - same viewMode-based logic as slide haptics |
| Same TickHapticCoordinator | Reuses existing binary search and throttling infrastructure |
| Reset on drag end | Ensures fresh state for next cursor gesture |

---

## Shared Tick Haptics Infrastructure

### Scale Selection

The tick haptic system uses different selection logic based on the current view mode:

| View Mode | Device | Scale Selection Priority |
|-----------|--------|-------------------------|
| `.front` | iPhone/iPad | C scale on front slide → first scale on front slide |
| `.back` | iPhone/iPad | C scale on back slide → first scale on back slide |
| `.both` | iPad only | C scale on front slide → C scale on back slide → first scale on front slide → first scale on back slide |

In `.both` mode (iPad showing both sides), the **C scale takes precedence** regardless of which slide it's on. The front slide is checked first.

This ensures tick haptics work on all sides of the slide rule, even those without a C scale.

### Tick Levels

| Tick Type | Relative Length | Haptic Intensity |
|-----------|-----------------|------------------|
| Primary (1, 10) | 1.0 | Heavy (strong pop) |
| Secondary | 0.75+ | Medium (normal pop) |
| Tertiary | 0.4+ | Light (short pop) |
| Minor | < 0.4 | None (ignored) |

### Implementation: `TickHapticCoordinator.swift`

```swift
final class TickHapticCoordinator {
    private var lastCrossedTickIndex: Int?
    
    func checkTickCrossing(
        cursorNormalizedPosition: CGFloat,
        slideOffset: CGFloat,
        scaleWidth: CGFloat,
        cScale: GeneratedScale
    ) {
        // Calculate effective tick position under cursor
        let slideNormalizedOffset = slideOffset / scaleWidth
        let effectivePosition = cursorNormalizedPosition - slideNormalizedOffset
        
        // Find nearest tick using binary search
        let nearestTickIndex = findNearestTickIndex(
            position: effectivePosition,
            ticks: cScale.tickMarks
        )
        
        // Only trigger if we crossed to a new tick
        guard nearestTickIndex != lastCrossedTickIndex else { return }
        lastCrossedTickIndex = nearestTickIndex
        
        // Get tick and check if it's significant enough
        let tick = cScale.tickMarks[nearestTickIndex]
        guard tick.style.relativeLength >= 0.4 else { return }
        
        // Determine haptic level based on tick prominence
        let level = hapticLevel(for: tick.style.relativeLength)
        HapticManager.tickHaptic(forLevel: level)
    }
    
    func reset() {
        lastCrossedTickIndex = nil
    }
}
```

### Integration: `ContentView+Gestures.swift`

```swift
func handleDragChanged(_ gesture: DragGesture.Value, isPrecision: Bool) {
    // ... slide movement code ...
    
    // Select scale based on view mode, prioritizing C scale
    let hapticScale: GeneratedScale? = {
        switch viewMode {
        case .front:
            return currentSlideRule.frontSlide.scales.first(where: { $0.definition.name == "C" })
                ?? currentSlideRule.frontSlide.scales.first
        case .back:
            return currentSlideRule.backSlide?.scales.first(where: { $0.definition.name == "C" })
                ?? currentSlideRule.backSlide?.scales.first
        case .both:
            // iPad: prioritize C scale from either slide, preferring front
            if let cScale = currentSlideRule.frontSlide.scales.first(where: { $0.definition.name == "C" }) {
                return cScale
            }
            if let cScale = currentSlideRule.backSlide?.scales.first(where: { $0.definition.name == "C" }) {
                return cScale
            }
            return currentSlideRule.frontSlide.scales.first
                ?? currentSlideRule.backSlide?.scales.first
        }
    }()
    
    if let scale = hapticScale {
        let hairlinePosition = cursorState.normalizedPosition + halfCursorWidthNormalized
        
        tickHapticCoordinator.checkTickCrossing(
            cursorNormalizedPosition: hairlinePosition,
            slideOffset: viewModel.sliderOffset,
            scaleWidth: scaleWidth,
            cScale: scale
        )
    }
}

func handleDragEnded(_ gesture: DragGesture.Value, isPrecision: Bool) {
    // ... commit position ...
    tickHapticCoordinator.reset()  // Reset for next drag
}
```

### Performance Considerations

- **Binary search** for finding nearest tick (O(log n) vs O(n) linear scan)
- **Throttling** via `lastCrossedTickIndex` - only triggers once per tick crossing
- **Minimum tick level filter** (0.4) - ignores minor ticks to reduce haptic spam
- **Reset on drag end** - ensures fresh state for next gesture

---

## Haptic Feedback: `HapticManager.swift`

Centralized utility for all haptic feedback in the app:

```swift
enum HapticManager {
    /// Flip between front/back sides
    static func flipFeedback()
    
    /// Long buzz when precision mode activates
    static func longBuzz()
    
    /// Strong pop for major tick marks
    static func strongPop()
    
    /// Normal pop for secondary tick marks
    static func normalPop()
    
    /// Light pop for tertiary tick marks
    static func shortPop()
    
    /// Tick haptic by level (1=strong, 2=normal, 3=light)
    static func tickHaptic(forLevel level: Int)
}
```

### Platform Handling

```swift
#if os(iOS)
import UIKit

enum HapticManager {
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    
    // ... implementation using generators ...
}
#else
// macOS: no-op implementations
enum HapticManager {
    static func flipFeedback() {}
    static func longBuzz() {}
    // ... etc ...
}
#endif
```

---

## Files Overview

| File | Purpose |
|------|---------|
| `Utilities/HapticManager.swift` | Centralized haptic feedback |
| `Utilities/TickHapticCoordinator.swift` | Tick crossing detection for slide and cursor (C scale or fallback) |
| `Utilities/PrecisionDragState.swift` | Shared precision mode constants/state |
| `Components/SideView.swift` | Vertical swipe + slide precision gestures |
| `Cursor/CursorOverlay.swift` | Cursor precision gestures + tick haptic callbacks |
| `Extensions/ContentView+Gestures.swift` | Gesture handlers with slide + cursor tick haptics |

---

## Related Documentation

- [precision-mode-implementation.md](precision-mode-implementation.md) - Deep dive on precision mode
- [glass-cursor-master-plan.md](glass-cursor-master-plan.md) - Overall cursor architecture
- [pan-gesture.md](pan-gesture.md) - Related zoomed content panning
