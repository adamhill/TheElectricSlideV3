# Scale/Cursor Shift Fix - Implementation Reference

> **Last Updated:** December 2024  
> **Status:** ✅ Fixed - Scale graphics stay aligned with cursor during orientation changes

## Overview

This document captures learnings from investigating and fixing the scale/cursor shift bug where scales would desynchronize from the cursor during device orientation changes.

---

## Problem Statement

When rotating the device between landscape and flat (faceUp), the scale graphics would shift relative to the cursor. The cursor position and readings stayed correct, but the visual alignment was broken.

### Investigation Process

1. **Added logging** to `SideView` body to track width changes:
   ```
   [SideView] body called - side: front, width: 876.0, zoom: 1.0
   [SideView] body called - side: front, width: 856.0, zoom: 1.0
   [SideView] body called - side: front, width: 836.0, zoom: 1.0
   [SideView] body called - side: front, width: 816.0, zoom: 1.0
   [SideView] body called - side: front, width: 796.0, zoom: 1.0
   ```

2. **Discovery:** SwiftUI was animating geometry changes through intermediate values!

3. **Further discovery:** `faceUp`/`faceDown` orientations triggered **cascading** layout changes:
   ```
   [Debounce] Dimensions settled: 760.0 → 840.0
   [Debounce] Dimensions settled: 840.0 → 704.0  ← Additional change!
   [Debounce] Dimensions settled: 704.0 → 680.0  ← And another!
   ```

### Root Causes (Multiple)

1. **faceUp/faceDown are ambiguous orientations** - iOS fires orientation notifications but then does multiple layout passes to decide the actual interface orientation

2. **Manual dimension recalculation** in orientation handler was redundantly triggering updates on top of what `onGeometryChange` already handles

3. **Orientation-dependent margins** created mismatch between immediate orientation reading and animated geometry width

### Solutions Applied

#### 1. Ignore Ambiguous Orientations

```swift
.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
    let orientation = UIDevice.current.orientation
    
    // Ignore faceUp/faceDown - these trigger cascading layout changes
    guard orientation != .faceUp && orientation != .faceDown else {
        return
    }
    // ... rest of handler
}
```

#### 2. Remove Manual Dimension Recalculation

Let `onGeometryChange` handle dimension updates naturally - don't manually recalculate and set `calculatedDimensions` in the orientation handler.

#### 3. Use Symmetric Margins

Changed from orientation-dependent asymmetric margins to tier-based symmetric margins:

```swift
// Before (caused desync):
switch orientation {
case .landscapeLeft:
    leftMarginWidth = 20
    rightMarginWidth = 8
// ...
}

// After (stable):
leftMarginWidth = tier.marginWidth
rightMarginWidth = tier.marginWidth
```

#### 4. Debounced Dimensions (Defense in Depth)

Added `stableDimensions` state that only updates after geometry settles:

```swift
@State private var stableDimensions: Dimensions?
@State private var dimensionUpdateTask: Task<Void, Never>?

private var renderDimensions: Dimensions {
    stableDimensions ?? calculatedDimensions
}

// In view body:
.onChange(of: calculatedDimensions.width) { oldWidth, newWidth in
    dimensionUpdateTask?.cancel()
    dimensionUpdateTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(100))
        if !Task.isCancelled {
            stableDimensions = calculatedDimensions
        }
    }
}
```

---

## Key Learnings for Future AI Agents

### SwiftUI Animation System

> [!CAUTION]
> **SwiftUI animations are viral** - They propagate through the view hierarchy. An animation applied to a parent can affect child state changes. Always use explicit `withTransaction(Transaction(animation: nil))` for gesture-driven updates.

> [!WARNING]
> **`onGeometryChange` receives animated values** - The geometry proxy in `onGeometryChange(for:transform:action:)` reports intermediate animated values, not just the final target. If you need stable values, debounce the updates.

> [!NOTE]
> **Device orientation ≠ Interface orientation** - `UIDevice.current.orientation` reports physical device orientation, which includes `faceUp`/`faceDown`. These are ambiguous and trigger multiple layout passes. The actual interface orientation may differ.

### Debugging Geometry Issues

1. **Add logging to view bodies** - Use `let _ = print(...)` to trace when views rebuild and with what values

2. **Track all dimension changes** - Log both the source (where dimensions are calculated) and the destination (where they're rendered)

3. **Watch for cascading updates** - Multiple rapid dimension changes indicate animation or layout thrashing

4. **Test with flat device orientation** - `faceUp` is particularly problematic because iOS must guess the intended interface orientation

### Patterns That Work

| Pattern | Use Case |
|---------|----------|
| `withTransaction(Transaction(animation: nil))` | All gesture-driven state updates |
| `.transformEffect(CGAffineTransform(...))` | Smooth position updates (better than `.offset()`) |
| Debounced state with Task cancellation | Geometry values that animate through intermediate states |
| Ignore `faceUp`/`faceDown` orientations | Orientation-dependent calculations |
| Symmetric margins | Avoid orientation/geometry timing mismatches |

### Patterns That Don't Work

| Pattern | Why It Fails |
|---------|--------------|
| `.animation(nil, value:)` alone | Animation can leak from parent views |
| Manual dimension recalculation in orientation handler | Redundant with `onGeometryChange`, causes cascading |
| Orientation-dependent margins | `UIDevice.orientation` is immediate but geometry animates |
| `.drawingGroup()` with dynamic content | Metal cache doesn't update correctly during animations |
| `.transaction { $0.animation = nil }` on parent | Doesn't reliably suppress child animations |

---

## Code Locations Reference

| Component | File | Purpose |
|-----------|------|---------|
| `PanPositionModifier` | ContentView.swift ~line 45 | CGAffineTransform-based offset |
| Pan handlers | ContentView.swift ~line 1920 | `handlePanChanged`, `handlePanEnded` |
| Debounce logic | ContentView.swift (DynamicSlideRuleContent) ~line 1145 | `stableDimensions`, `dimensionUpdateTask` |
| Orientation handler | ContentView.swift ~line 1880 | `faceUp`/`faceDown` filtering |
| Margin calculation | ContentView.swift `calculateDimensions()` ~line 1665 | Symmetric margin logic |

---

## Testing Checklist

When making changes to gestures or geometry:

- [ ] Test pan gesture at 1.0×, 1.5×, 2.0×, 3.0× zoom
- [ ] Test orientation changes: portrait ↔ landscape
- [ ] Test faceUp (flat) orientation transitions
- [ ] Verify cursor stays aligned with scales during orientation change
- [ ] Check for cascading dimension logs (should only see one final value)
- [ ] Test on iPhone (compact) and iPad (regular) size classes
