# Zoom Label Shift Fix

## Problem Description

At high zoom levels (2.3x on iPad, 2.7x on iPhone), scale labels would visually shift position while tick marks remained stable. This was a rendering inconsistency that appeared only at specific zoom thresholds.

### Symptoms
- Labels appeared to "jump" or shift horizontally at certain zoom levels
- Tick marks remained perfectly stable at all zoom levels
- The issue was reproducible and consistent at specific zoom thresholds
- Debug logging showed position calculations were mathematically correct

## Root Cause Analysis

Two separate issues combined to cause the visual shifting:

### 1. Sub-Pixel Rendering Precision

Label positions were calculated as floating-point values (e.g., `632.18`, `21.35`). At different zoom levels, the anti-aliasing algorithm handles these sub-pixel positions differently:

- At 1.0x zoom: Sub-pixel position `632.18` renders one way
- At 2.7x zoom: The same position is scaled to `1706.89`, which may round/anti-alias differently
- This creates visible "shifting" even though the mathematical position is consistent

**Why tick marks didn't shift:** Tick marks use `Path` rendering which snaps to pixel boundaries more predictably than text rendering.

### 2. Transform Replacement vs Composition

The label rendering code was using direct assignment for transforms:

```swift
// PROBLEMATIC CODE
var transformedContext = context
transformedContext.transform = transform  // ❌ REPLACES parent transform
transformedContext.draw(resolvedText, at: point)
```

When `.scaleEffect()` is applied to a parent view (in `SlideRuleDetailView`), it adds a transform to the graphics context. By using `=` assignment, we were **replacing** this parent transform rather than **composing** with it.

## Solution

### Fix 1: Round Draw Positions to Integer Pixels

Force all label positions to integer pixel boundaries:

```swift
// In ScaleLabelRenderer.swift - drawLabels()
let drawX = round(labelX + textSize.width / 2)
let drawY = round(labelY + textSize.height / 2)

// In ScaleLabelRenderer.swift - drawSimpleLabel()
let drawX = round(labelX + textSize.width / 2)
let drawY = round(labelY + textSize.height / 2)
```

This ensures consistent pixel alignment regardless of zoom level. The `round()` function snaps to the nearest integer, eliminating sub-pixel variance.

### Fix 2: Use Transform Composition Instead of Replacement

Change from assignment to concatenation:

```swift
// FIXED CODE
var transformedContext = context
transformedContext.concatenate(transform)  // ✅ COMPOSES with parent transform
transformedContext.draw(resolvedText, at: CGPoint(x: drawX, y: drawY))
```

`concatenate()` multiplies the new transform with the existing transform matrix, preserving any parent transforms (like `.scaleEffect()` zoom).

## Files Modified

- **ScaleLabelRenderer.swift** - Applied both fixes (position rounding + concatenate)
- **ScaleView.swift** - Removed `.drawingGroup()` modifier (see below)

## Related Change: Removed .drawingGroup()

During debugging, `.drawingGroup()` was removed from the Canvas in ScaleView. This modifier causes SwiftUI to rasterize the view into a Metal texture, which can cause issues when parent views are scaled:

```swift
// REMOVED - caused caching issues with zoom
Canvas { ... }
    .drawingGroup()  // ❌ Removed
```

The Metal texture cache doesn't automatically update when parent view transforms change, leading to stale or incorrectly scaled content.

## Verification

After applying fixes, debug logging confirmed all draw positions are now integer values:

```
📍 [LABEL DRAW] scale=C label="1" drawAt=(632.00,21.00)  // ✅ Integer position
📍 [LABEL DRAW] scale=C label="2" drawAt=(843.00,21.00)  // ✅ Integer position
```

Labels now remain stable at all zoom levels tested (1.0x through 3.0x).

## Key Learnings

1. **Text rendering is sensitive to sub-pixel positions** - Unlike paths, text anti-aliasing can vary with sub-pixel offsets, especially under zoom transforms.

2. **Transform assignment replaces, concatenation composes** - When working with nested transforms (parent view zoom + child element transforms), always use `concatenate()` to preserve the transform chain.

3. **`.drawingGroup()` caches aggressively** - Avoid using `.drawingGroup()` on content that has dynamic parent transforms, as the Metal texture cache may not update correctly.

4. **Debug logging reveals patterns** - Print statements showing actual draw coordinates helped identify that the positions were mathematically consistent but the rendering was not.

## Debug Flags

For future debugging, these flags can be re-enabled:

```swift
// ScaleLabelRenderer.swift
private let DEBUG_LABEL_RENDERING = false  // Set to true for label position logging

// ScaleView.swift  
private let DEBUG_SCALE_RENDERING = false  // Set to true for Canvas redraw logging
```

## Date
December 1, 2025

## Related Documentation
- [swift-sliderule-rendering-improvements.md](swift-sliderule-rendering-improvements.md) - Performance optimization patterns
- [scale-shift-solution-implementation.md](scale-shift-solution-implementation.md) - Earlier scale shift investigation
