# Pan Gesture Implementation

> **Last Updated:** December 2024  
> **Status:** ✅ Working - Jitter-free implementation achieved

## Overview

Pan gesture allows users to move zoomed-in slide rule content by dragging on the stators (fixed parts). The gesture is only active when `currentZoomScale > 1.0`.

## Architecture

### Three Gesture Systems That Must Coexist

The slide rule has three gesture systems that must work together without interference:

1. **Slide drag** - Horizontal drag on the SlideView to move the slide left/right
2. **Cursor drag** - Drag on the CursorOverlay to position the reading hairline  
3. **Pan gesture** - Drag on stators to pan zoomed-in content

> [!IMPORTANT]
> **Pan gesture must stay on StatorView** - Moving it to a container level interferes with slide and cursor gestures. Keeping it on StatorView (the fixed parts) allows all three gestures to coexist.

### State Variables

Located in `ContentView.swift` (in the main view struct):

```swift
// Pan offset for moving zoomed-in content
@State private var panOffset: CGSize = .zero      // Current pan offset
@State private var basePanOffset: CGSize = .zero  // Base offset at start of gesture
```

### Pan Handlers

Located in `ContentView.swift`:

```swift
/// Handles pan gesture changes during drag to pan zoomed content
/// Uses withTransaction to suppress animations for smooth, jitter-free tracking
private func handlePanChanged(_ gesture: DragGesture.Value) {
    withTransaction(Transaction(animation: nil)) {
        panOffset = CGSize(
            width: basePanOffset.width + gesture.translation.width,
            height: basePanOffset.height + gesture.translation.height
        )
    }
}

/// Handles pan gesture end and commits the new base offset
/// Uses withTransaction to suppress animations for immediate response
private func handlePanEnded(_ gesture: DragGesture.Value) {
    withTransaction(Transaction(animation: nil)) {
        basePanOffset = panOffset
    }
}
```

> [!CAUTION]
> **Always use `withTransaction(Transaction(animation: nil))`** for pan updates. Without this, SwiftUI may apply implicit animations that cause visible jitter during fast panning.

### Gesture Attachment

Located in `StatorView` (on the stator container):

```swift
.highPriorityGesture(
    // Pan gesture only enabled when zoomed in (>1.0x)
    (currentZoomScale > 1.0 && onPanChanged != nil && onPanEnded != nil) ?
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in onPanChanged?(gesture) }
            .onEnded { gesture in onPanEnded?(gesture) }
        : nil
)
```

**Key Configuration:**
- `.highPriorityGesture()` - Reduces conflicts with other gestures
- `minimumDistance: 0` - Immediate response without delay
- Conditional activation only when `currentZoomScale > 1.0`

### Offset Application with Custom Modifier

Located in `SlideRuleDetailView`:

```swift
DynamicSlideRuleContent(...)
    .modifier(PanPositionModifier(offset: panOffset))  // Custom modifier for jitter-free pan
    .scaleEffect(currentZoomScale, anchor: .top)
```

The `PanPositionModifier` uses `CGAffineTransform` instead of SwiftUI's `.offset()` for better performance:

```swift
/// Custom view modifier for applying pan offset without jitter
/// Uses CGAffineTransform instead of SwiftUI offset for smoother performance
struct PanPositionModifier: ViewModifier {
    let offset: CGSize
    
    func body(content: Content) -> some View {
        content
            .transformEffect(CGAffineTransform(translationX: offset.width, y: offset.height))
    }
}
```

> [!TIP]
> Using `CGAffineTransform` via `.transformEffect()` provides smoother, more immediate updates compared to SwiftUI's `.offset()` modifier, which can be affected by the layout system.

## Parameter Threading

Pan-related parameters are threaded through the view hierarchy:

```
ContentView
    ├── panOffset: @State
    ├── basePanOffset: @State  
    ├── handlePanChanged()
    └── handlePanEnded()
            │
            ▼
SlideRuleDetailView
    ├── panOffset: Binding
    ├── handlePanChanged: closure
    └── handlePanEnded: closure
            │
            ▼
DynamicSlideRuleContent
    ├── currentZoomScale
    ├── handlePanChanged: closure
    └── handlePanEnded: closure
            │
            ▼
SideView
    ├── currentZoomScale
    ├── onPanChanged: closure
    └── onPanEnded: closure
            │
            ▼
StatorView (×2: top and bottom)
    ├── currentZoomScale
    ├── onPanChanged: closure
    └── onPanEnded: closure
    └── .highPriorityGesture(DragGesture...)
```

## Zoom Reset (Triple-Tap)

Triple-tap on stators, slide, or cursor resets zoom to 1.0×:

```swift
/// Resets zoom scale and pan offset to default values
/// Called by triple-tap gesture on stators, slide, and cursor
private func handleResetZoom() {
    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
        currentZoomScale = 1.0
        panOffset = .zero
        basePanOffset = .zero
    }
}
```

## Admonitions for Future AI Agents

> [!WARNING]
> **Do NOT remove `withTransaction(Transaction(animation: nil))`** from pan handlers. This is critical for preventing jitter. SwiftUI's default animation behavior causes visible stuttering during rapid pan updates.

> [!WARNING]
> **Do NOT move pan gesture to DynamicSlideRuleContent or higher**. This will break slide drag and cursor drag gestures. The gesture must stay on StatorView.

> [!NOTE]
> If you see jitter during panning, check:
> 1. `withTransaction` is wrapping all pan state updates
> 2. `PanPositionModifier` is being used (not `.offset()`)
> 3. No implicit animations are being applied to panOffset
> 4. The `.animation()` modifier isn't accidentally targeting panOffset

> [!TIP]
> The `currentZoomScale > 1.0` check disables pan when not zoomed. This is intentional - at 1.0× zoom, the entire slide rule is visible and panning serves no purpose.

## Related Documentation

- [Pan Gesture Jitter Solutions](pan-gesture-jitter-solutions.md) - Detailed jitter investigation and solutions
- [swift-sliderule-rendering-improvements.md](swift-sliderule-rendering-improvements.md) - Performance optimization guide
- [glass-cursor-master-plan.md](glass-cursor-master-plan.md) - Cursor gesture implementation

## Code Locations

| Component | File | Approximate Line |
|-----------|------|------------------|
| Pan State Variables | ContentView.swift | ~1580 |
| Pan Handlers | ContentView.swift | ~1920 |
| PanPositionModifier | ContentView.swift | ~45 |
| Gesture Attachment | ContentView.swift (StatorView) | ~730 |
| Offset Application | ContentView.swift (SlideRuleDetailView) | ~1480 |
