---
applyTo: "TheElectricSlide/**/*.swift"
---

# TheElectricSlide App Guidelines

## Platform Requirements
- macOS 15+, iOS 18+ (uses `onGeometryChange` from WWDC 2024)

## Performance-Critical Patterns

### 1. Use Pre-computed Tick Marks
```swift
Canvas { context, size in
    drawScale(context: &context, size: size, 
              tickMarks: generatedScale.tickMarks,  // ✅ Pre-computed
              definition: generatedScale.definition)
}
```

### 2. Use `onGeometryChange` NOT GeometryReader
```swift
.onGeometryChange(for: Dimensions.self) { proxy in
    calculateDimensions(availableWidth: proxy.size.width, availableHeight: proxy.size.height)
} action: { newDimensions in
    calculatedDimensions = newDimensions  // Only updates when size changes
}
```

### 3. Equatable Views for Static Content
```swift
struct StatorView: View, Equatable {
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        lhs.width == rhs.width && lhs.scaleHeight == rhs.scaleHeight &&
        lhs.stator.scales.count == rhs.stator.scales.count
    }
}
// Usage: StatorView(...).equatable()
```

### 4. Use `.drawingGroup()` for Complex Canvas
```swift
Canvas { ... }.drawingGroup()  // Metal-accelerated rendering for 200+ tick marks
```

### 5. Separate State
- `sliderOffset` changes shouldn't trigger stator updates
- Keep slide position isolated from window size state

## Device Detection
- Use `@Environment(\.horizontalSizeClass)` (`.compact` = iPhone, `.regular` = iPad/Mac)
- **Don't** use `UIDevice.current.userInterfaceIdiom` in view bodies

## View Hierarchy
- `ContentView` → `StaticHeaderSection` + `DynamicSlideRuleContent`
- `DynamicSlideRuleContent` → `SideView` → `StatorView` + `SlideView` + `StatorView`
- Each `StatorView`/`SlideView` contains multiple `ScaleView` instances
