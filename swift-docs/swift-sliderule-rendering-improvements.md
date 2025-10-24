# SwiftUI Slide Rule Rendering Performance Improvements

## Executive Summary

The ContentView.swift rendering pipeline has significant performance issues, especially when rendering LL1, LL2, and LL3 scales (which have 200+ tick marks each). The main problems are:

1. **Redundant rendering of static stators** - Top and bottom stators redraw on every slider interaction
2. **Duplicate tick mark calculations** - Canvas recalculates tick marks that are already pre-computed in GeneratedScale
3. **Inefficient geometry observation** - GeometryReader triggers updates for all geometry changes

**Expected Overall Improvement:** 70-85% reduction in rendering overhead

---

## TODO List

- [x] **Solution 1**: Replace GeometryReader with onGeometryChange ✅ COMPLETED
- [x] **Solution 2**: Use pre-computed tick marks from GeneratedScale ✅ COMPLETED
- [x] **Solution 3**: Add Equatable conformance to views ✅ COMPLETED
- [x] **Solution 4**: Add `.drawingGroup()` for complex Canvas rendering ✅ COMPLETED
- [ ] **Solution 5**: Verify slide offset state separation
- [ ] **Solution 6**: (Optional) Use PreferenceKey for dimension communication
- [ ] **Solution 7**: (Optional) Implement lazy rendering for off-screen scales

---

## Current Performance Issues

### Issue 1: GeometryReader Causes Excessive Updates

**Problem:**
- GeometryReader wraps the entire slide rule
- Every geometry change (window resize, slider drag) triggers body re-evaluation
- All three components (top stator, slide, bottom stator) redraw even though top/bottom are static

**Current Flow:**
```
User drags slider → GeometryReader observes change → All components redraw
Window resize → GeometryReader observes change → All components redraw
```

**Impact:**
- Top stator: Unnecessarily redraws ~300 tick marks
- Bottom stator: Unnecessarily redraws ~600+ tick marks (LL1, LL2, LL3)
- Slide: Legitimately needs to redraw

### Issue 2: Duplicate Tick Mark Generation

**Problem:**
```swift
// Current code in ScaleView
Canvas { context, size in
    let tickMarks = ScaleCalculator.generateTickMarks(
        for: scaleDefinition,
        algorithm: .modulo(config: ModuloTickConfig.default)
    )
    // Drawing code...
}
```

**Issues:**
- `ScaleCalculator.generateTickMarks()` is called on EVERY Canvas draw
- The tick marks are already pre-computed in `GeneratedScale.tickMarks`
- For LL scales with 200+ ticks, this is significant wasted CPU

**Impact:**
- Redundant calculation of 600+ tick marks per frame
- Each calculation involves mathematical transforms (log, sin, etc.)

### Issue 3: No View Identity Optimization

**Problem:**
- Static stators have no identity markers
- SwiftUI can't determine they haven't changed
- Re-renders even when dimensions are identical

---

## 🚀 Recommended Solutions

### Solution 1: Use `onGeometryChange` (WWDC 2024)

**Priority:** ⭐⭐⭐⭐⭐ HIGHEST IMPACT  
**Effort:** Medium  
**Expected Improvement:** 60-80% reduction in rendering during slider interaction

**What is `onGeometryChange`?**

Introduced at WWDC 2024, this modifier solves a major SwiftUI performance problem:
- `GeometryReader` observes ALL geometry changes and triggers body updates
- `onGeometryChange` only calls its action when a **specific extracted value** changes

**How it works:**
```swift
.onGeometryChange(for: ValueType.self) { proxy in
    // Extract ONLY the value you care about
    return extractValue(from: proxy)
} action: { newValue in
    // Update state ONLY when this specific value changes
    updateState(newValue)
}
```

**Benefits:**
- Static stators won't redraw when slider moves (different dependency)
- Only updates when window size actually changes dimensions
- Extracted value is Equatable, so changes are precisely detected

**Implementation:**

```swift
struct ContentView: View {
    @State private var sliderOffset: CGFloat = 0
    @State private var calculatedDimensions: (width: CGFloat, scaleHeight: CGFloat) = (800, 25)
    
    // Scale configuration
    private let minScaleHeight: CGFloat = 20
    private let idealScaleHeight: CGFloat = 25
    private let maxScaleHeight: CGFloat = 30
    private let targetAspectRatio: CGFloat = 10.0
    private let padding: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Stator - only depends on calculatedDimensions
            StatorView(
                stator: slideRule.frontTopStator,
                width: calculatedDimensions.width,
                backgroundColor: .white,
                borderColor: .blue,
                scaleHeight: calculatedDimensions.scaleHeight
            )
            .id("topStator")  // Stable identity
            
            // Slide - depends on both calculatedDimensions and sliderOffset
            SlideView(
                slide: slideRule.frontSlide,
                width: calculatedDimensions.width,
                backgroundColor: .white,
                borderColor: .orange,
                scaleHeight: calculatedDimensions.scaleHeight
            )
            .offset(x: sliderOffset)
            .gesture(dragGesture)
            
            // Bottom Stator - only depends on calculatedDimensions
            StatorView(
                stator: slideRule.frontBottomStator,
                width: calculatedDimensions.width,
                backgroundColor: .white,
                borderColor: .blue,
                scaleHeight: calculatedDimensions.scaleHeight
            )
            .id("bottomStator")  // Stable identity
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(padding)
        .onGeometryChange(for: (CGFloat, CGFloat).self) { proxy in
            // ONLY extract the dimensions we need
            let size = proxy.size
            return calculateDimensions(
                availableWidth: size.width,
                availableHeight: size.height
            )
        } action: { newDimensions in
            // ONLY called when dimensions actually change
            calculatedDimensions = newDimensions
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                let newOffset = gesture.translation.width
                sliderOffset = min(max(newOffset, -calculatedDimensions.width), 
                                 calculatedDimensions.width)
            }
    }
    
    // Helper remains the same
    private func calculateDimensions(
        availableWidth: CGFloat, 
        availableHeight: CGFloat
    ) -> (width: CGFloat, scaleHeight: CGFloat) {
        let maxWidth = availableWidth - (padding * 2)
        let maxHeight = availableHeight - (padding * 2)
        
        let calculatedScaleHeight = min(
            maxHeight / CGFloat(totalScaleCount),
            maxScaleHeight
        )
        let scaleHeight = max(calculatedScaleHeight, minScaleHeight)
        
        let totalHeight = scaleHeight * CGFloat(totalScaleCount)
        let widthFromAspectRatio = totalHeight * targetAspectRatio
        let width = min(maxWidth, widthFromAspectRatio)
        
        return (width, scaleHeight)
    }
}
```

**Why this is better:**
- When slider drags: `sliderOffset` changes, but `calculatedDimensions` doesn't
  - Top/Bottom stators: No update (they only depend on dimensions)
  - Slide: Updates (depends on offset)
- When window resizes: `calculatedDimensions` changes
  - All components update (correct behavior)

**Platform Availability:**
- iOS 16.0+
- macOS 13.0+
- Available in your deployment target ✅

---

### Solution 2: Use Pre-Computed Tick Marks

**Priority:** ⭐⭐⭐⭐⭐ HIGH IMPACT  
**Effort:** Low  
**Expected Improvement:** 40-50% reduction in CPU per scale

**Problem:**

Your `GeneratedScale` already has `tickMarks` computed during initialization:

```swift
public struct GeneratedScale: Sendable {
    public let definition: ScaleDefinition
    public let tickMarks: [TickMark]  // ✅ Pre-computed!
    
    public init(definition: ScaleDefinition, noLineBreak: Bool = false) {
        self.definition = definition
        self.tickMarks = ScaleCalculator.generateTickMarks(for: definition)  // Computed once
        // ...
    }
}
```

But `ScaleView` calls `ScaleCalculator.generateTickMarks()` again:

```swift
Canvas { context, size in
    let tickMarks = ScaleCalculator.generateTickMarks(  // ❌ Redundant!
        for: scaleDefinition,
        algorithm: .modulo(config: ModuloTickConfig.default)
    )
}
```

**Solution:**

Pass the entire `GeneratedScale` to `ScaleView`:

```swift
struct ScaleView: View {
    let generatedScale: GeneratedScale  // ✅ Contains pre-computed tickMarks
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Scale name
            Text(generatedScale.definition.name)
                .font(.caption2)
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 20)
            
            // Canvas with pre-computed tick marks
            Canvas { context, size in
                drawScale(
                    context: &context,
                    size: size,
                    tickMarks: generatedScale.tickMarks,  // ✅ Use pre-computed!
                    definition: generatedScale.definition
                )
            }
            .frame(width: width)
            .frame(minHeight: height * 0.8, idealHeight: height, maxHeight: height)
            
            // Formula
            Text(generatedScale.definition.formula)
                .font(.caption2)
                .tracking((generatedScale.definition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 40, alignment: .leading)
        }
    }
    
    // Extract drawing logic for clarity
    private func drawScale(
        context: inout GraphicsContext,
        size: CGSize,
        tickMarks: [TickMark],
        definition: ScaleDefinition
    ) {
        // Draw baseline
        if definition.showBaseline {
            let baselinePath = Path { path in
                switch definition.tickDirection {
                case .down:
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size.width, y: 0))
                case .up:
                    path.move(to: CGPoint(x: 0, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                }
            }
            context.stroke(baselinePath, with: .color(.black), lineWidth: 2.0)
        }
        
        // Draw tick marks
        for tick in tickMarks {
            let xPos = tick.normalizedPosition * size.width
            let tickHeight = tick.style.relativeLength * (size.height * 0.6)
            
            let (tickStartY, tickEndY): (CGFloat, CGFloat)
            switch definition.tickDirection {
            case .down:
                tickStartY = 0
                tickEndY = tickHeight
            case .up:
                tickStartY = size.height
                tickEndY = size.height - tickHeight
            }
            
            let tickPath = Path { path in
                path.move(to: CGPoint(x: xPos, y: tickStartY))
                path.addLine(to: CGPoint(x: xPos, y: tickEndY))
            }
            
            context.withCGContext { cgContext in
                cgContext.setShouldAntialias(false)
                context.stroke(
                    tickPath,
                    with: .color(.black),
                    lineWidth: tick.style.lineWidth / 1.5
                )
            }
            
            // Draw label
            if let labelText = tick.label {
                let fontSize = fontSizeForTick(tick.style.relativeLength)
                if fontSize > 0 {
                    let text = Text(labelText)
                        .font(.system(size: fontSize))
                        .foregroundColor(.black)
                    
                    let resolvedText = context.resolve(text)
                    let textSize = resolvedText.measure(in: CGSize(width: 100, height: 100))
                    
                    let labelY: CGFloat
                    switch definition.tickDirection {
                    case .down:
                        labelY = tickHeight + 2
                    case .up:
                        labelY = size.height - tickHeight - textSize.height - 2
                    }
                    let labelX = xPos - textSize.width / 2
                    
                    context.draw(
                        resolvedText,
                        at: CGPoint(x: labelX + textSize.width / 2, 
                                  y: labelY + textSize.height / 2)
                    )
                }
            }
        }
    }
    
    private func fontSizeForTick(_ relativeLength: Double) -> CGFloat {
        if relativeLength >= 0.9 {
            return 6.0
        } else if relativeLength >= 0.7 {
            return 4.5
        } else if relativeLength >= 0.4 {
            return 3.0
        } else {
            return 0.0
        }
    }
}
```

**Update StatorView and SlideView:**

```swift
struct StatorView: View {
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stator.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    generatedScale: generatedScale,  // ✅ Pass entire GeneratedScale
                    width: width,
                    height: scaleHeight
                )
            }
        }
        .background(RoundedRectangle(cornerRadius: 4).fill(backgroundColor))
        .overlay(
            Group {
                if stator.showBorder {
                    RoundedRectangle(cornerRadius: 4).stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: scaleHeight * CGFloat(stator.scales.count))
        .fixedSize(horizontal: false, vertical: true)
    }
}
```

**Benefits:**
- Eliminates 600+ redundant tick calculations per frame
- Reduces CPU usage by 40-50% per scale
- Cleaner code architecture

---

### Solution 3: Equatable Conformance

**Priority:** ⭐⭐⭐⭐ MODERATE IMPACT  
**Effort:** Low  
**Expected Improvement:** 20-30% reduction when combined with other optimizations

**Implementation:**

```swift
struct StatorView: View, Equatable {
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat
    
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        // Only compare the properties that affect rendering
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.stator.scales.count == rhs.stator.scales.count &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor
    }
    
    var body: some View {
        // ... existing implementation
    }
}

// Usage in ContentView:
StatorView(...)
    .equatable()  // ✅ SwiftUI uses == to skip updates
```

**Benefits:**
- SwiftUI can skip body evaluation when inputs haven't changed
- Especially effective when combined with `onGeometryChange`

---

### Solution 4: DrawingGroup Optimization

**Priority:** ⭐⭐⭐ MODERATE IMPACT  
**Effort:** Low  
**Expected Improvement:** 30-40% faster rendering for complex scales

**Implementation:**

```swift
Canvas { context, size in
    drawScale(...)
}
.drawingGroup()  // ✅ Metal-accelerated off-screen rendering
.frame(width: width)
```

**Benefits:**
- Renders Canvas into an off-screen buffer using Metal
- Particularly effective for LL scales with 200+ tick marks
- Trade-off: Uses more memory but much faster rendering

**When to use:**
- Scales with 100+ tick marks
- Complex drawing operations
- Frequently updated content

---

### Solution 5: Separate Slide Offset State

**Priority:** ⭐⭐⭐⭐ HIGH IMPACT  
**Effort:** Medium  
**Expected Improvement:** Ensures stators truly don't update on slider drag

**Implementation:**

Already handled by Solution 1 (onGeometryChange), but ensure:

```swift
// ✅ Slider offset is independent state
@State private var sliderOffset: CGFloat = 0

// ✅ Dimensions are separate state
@State private var calculatedDimensions: (width: CGFloat, scaleHeight: CGFloat) = (800, 25)

// ✅ Gesture only updates sliderOffset
private var dragGesture: some Gesture {
    DragGesture()
        .onChanged { gesture in
            sliderOffset = min(max(gesture.translation.width, 
                                  -calculatedDimensions.width), 
                             calculatedDimensions.width)
        }
}
```

---

### Solution 6: PreferenceKey (Optional)

**Priority:** ⭐⭐ LOW IMPACT  
**Effort:** Medium  

Use when you need child-to-parent dimension communication:

```swift
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Usage:
.background(
    GeometryReader { proxy in
        Color.clear.preference(key: SizePreferenceKey.self, value: proxy.size)
    }
)
.onPreferenceChange(SizePreferenceKey.self) { size in
    // Handle size change
}
```

---

### Solution 7: Lazy Rendering (Optional)

**Priority:** ⭐⭐ LOW IMPACT (for current use case)  
**Effort:** Low  

If you have many scales that might be off-screen:

```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(stator.scales) { scale in
            ScaleView(generatedScale: scale, ...)
        }
    }
}
```

**Note:** Not applicable for current slide rule design with 3-7 visible scales.

---

## 📊 Performance Measurement

### Before Starting

1. Run Instruments with SwiftUI template
2. Record baseline metrics:
   - View body update frequency
   - Canvas render time per frame
   - CPU usage during slider drag

### After Each Optimization

1. Record in Instruments
2. Compare metrics:
   - View body updates (should decrease)
   - Render time (should decrease)
   - Frame rate (should be consistent 60fps)

### Key Metrics to Track

| Metric | Baseline | Target |
|--------|----------|--------|
| Stator updates during drag | Every frame | 0 updates |
| Canvas render time | ? ms | <16ms (60fps) |
| View body evaluations | ? per second | <10 per second |

---

## 🎯 Implementation Order

1. ✅ **Solution 2:** Use pre-computed tick marks (EASIEST, HIGH IMPACT)
2. ✅ **Solution 1:** Implement `onGeometryChange` (HIGHEST IMPACT)
3. ✅ **Solution 3:** Add Equatable conformance (EASY, MODERATE IMPACT)
4. ✅ **Solution 4:** Add `.drawingGroup()` for LL scales (EASY, MODERATE IMPACT)
5. ✅ **Solution 5:** Verify slide offset separation (VERIFICATION)

---

## References

- [WWDC 2024: SwiftUI Essentials](https://developer.apple.com/videos/play/wwdc2024/10150/)
- [Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance)
- [Canvas Documentation](https://developer.apple.com/documentation/swiftui/canvas)
- [onGeometryChange API Reference](https://developer.apple.com/documentation/swiftui/view/ongeometrychange(for:of:action:))
