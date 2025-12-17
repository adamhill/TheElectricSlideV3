# Precision Mode Visual Feedback Design

## Overview

This document specifies the visual feedback system for precision gesture activation in The Electric Slide. The design provides clear, non-intrusive visual indicators during long-press activation and while precision mode is active, working seamlessly at extreme zoom levels.

## Current Implementation Analysis

### Precision Mode Mechanics
- **Activation**: 1.0-second long press on cursor or slide (from [`PrecisionDragConstants.longPressMinimumDuration`](../TheElectricSlide/Utilities/PrecisionDragState.swift:17))
- **Sensitivity**: 5× reduction (1/5th normal speed) via [`PrecisionDragConstants.precisionFactor`](../TheElectricSlide/Utilities/PrecisionDragState.swift:20)
- **Current Feedback**: Haptic only - long buzz when activated ([`CursorOverlay.swift:204`](../TheElectricSlide/Cursor/CursorOverlay.swift:204), [`SideView.swift:178`](../TheElectricSlide/Components/SideView.swift:178))
- **State Management**: Centralized via [`PrecisionDragCoordinator`](../TheElectricSlide/Utilities/PrecisionDragCoordinator.swift) with `.activeTarget` property

### Visual Components

#### Cursor System
- **Glass Frame**: 144pt wide transparent rectangle with 2pt gray border ([`CursorView.swift:338-343`](../TheElectricSlide/Cursor/CursorView.swift:338-343))
- **Hairline**: True 1-pixel black vertical line at center ([`CursorView.swift:387-390`](../TheElectricSlide/Cursor/CursorView.swift:387-390))
- **Gradients**: Configurable horizontal gradients per scale row, default yellow fade ([`CursorView.swift:347-383`](../TheElectricSlide/Cursor/CursorView.swift:347-383))
  - Name gradient: Left side, `startPoint: .leading, endPoint: .trailing`
  - Value gradient: Right side, mirrored direction
- **Handles**: Top and bottom gray bars (16pt height) with drag indicators ([`CursorView.swift:299-330`](../TheElectricSlide/Cursor/CursorView.swift:299-330))

#### Slide System
- **Container**: [`SlideView`](../TheElectricSlide/Components/SlideView.swift) wraps [`ScaleContainerView`](../TheElectricSlide/Components/ScaleContainerView.swift)
- **Background**: White with orange border, rounded corners (4pt radius) ([`SideView.swift:119-130`](../TheElectricSlide/Components/SideView.swift:119-130))
- **Scales**: Multiple horizontal scale rows stacked vertically ([`ScaleContainerView.swift:41-66`](../TheElectricSlide/Components/ScaleContainerView.swift:41-66))

## Design Solution

### Principle: Contextual Color Shift
Use gradient color changes to indicate precision mode activation. The existing gradient system provides a perfect foundation without adding new UI elements.

### Color Specification

#### Precision Indicator Color: Light Orange-Red
```swift
// Replaces the default yellow gradient with same intensity
static let precisionOrangeRed = Color(red: 1.0, green: 0.4, blue: 0.3)

// Gradient configuration (mirrors yellow gradient structure)
static let precisionGradient = FontConfig.GradientConfig(
    colors: [
        Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.3),  // Light orange-red
        Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.15),
        Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.05),
        Color.clear
    ],
    startPoint: .leading,
    endPoint: .trailing,
    opacity: 1.0
)
```

**Color Choice Rationale**:
- **RGB(1.0, 0.4, 0.3)**: Warm, alert-evoking without being alarming
- **Intensity Match**: Same opacity values as yellow (0.3, 0.15, 0.05) for consistency
- **Contrast**: Clearly distinguishable from default yellow at all zoom levels
- **Psychology**: Orange-red indicates "special mode" or "caution" (slower speed)

### Visual Feedback Behavior

#### 1. Cursor Precision Mode
**Trigger**: Long press on cursor glass or handles

**Visual Change**:
- **Target**: Horizontal gradients in [`CursorView`](../TheElectricSlide/Cursor/CursorView.swift:347-383)
- **Transition**: Yellow → Light orange-red (0.2s ease-in)
- **Duration**: While precision mode active (`precisionCoordinator.activeTarget == .cursor`)
- **Reset**: Orange-red → Yellow (0.2s ease-out) when finger lifts

**Implementation Location**:
- Modify gradient colors in `CursorView.body` based on `precisionCoordinator.activeTarget`
- Apply to both name gradient (left) and value gradient (right)

#### 2. Slide Precision Mode
**Trigger**: Long press on slide component

**Visual Change**:
- **Target**: Slide background via overlay gradients
- **Transition**: Add vertical gradients from top and bottom edges (0.2s ease-in)
- **Gradient Structure**:
  ```
  Top Edge:    Orange-red (opacity 0.3) → Clear (over 20% of height)
  Bottom Edge: Orange-red (opacity 0.3) → Clear (over 20% of height)
  Center:      Original white background visible
  ```
- **Duration**: While precision mode active (`precisionCoordinator.activeTarget == .slide`)
- **Reset**: Fade out gradients (0.2s ease-out) when finger lifts

**Implementation Location**:
- Add conditional overlay to [`SlideView`](../TheElectricSlide/Components/SlideView.swift:40-54)
- Use `ZStack` with `VStack` containing top and bottom gradients

### Progress Indication (Optional - Deferred)

The current design **does not show 0-100% progress** during the 1-second long press. This is intentional:

**Rationale**:
- **Simplicity**: Instant color change on activation is clearer than animated progress
- **Reduced Complexity**: No additional state tracking or animation timers needed
- **Haptic Primary**: The long buzz provides clear activation confirmation
- **Future Enhancement**: Progress could be added via opacity fade-in (0% → 100% brightness) if user testing shows need

### Extreme Zoom Visibility

**Zoom Scenarios**:
1. **Zoomed to cursor only**: Horizontal gradient visible across full cursor glass
2. **Zoomed to slide only**: Vertical edge gradients visible on slide background
3. **Zoomed to scale detail**: Whichever component is visible shows its gradient
4. **Normal view**: Both indicators visible simultaneously

**Guaranteed Visibility**:
- Gradients are percentage-based, scale with zoom level
- Color contrast (yellow vs orange-red) remains distinct at any zoom
- No pixel-perfect elements that disappear at extreme magnification

## Component Modifications Required

### 1. [`CursorView.swift`](../TheElectricSlide/Cursor/CursorView.swift)

**Add State Observation**:
```swift
struct CursorView: View {
    // ... existing properties ...
    
    /// Whether THIS cursor is in precision mode
    var isPrecisionActive: Bool = false
    
    // ... rest of struct ...
}
```

**Modify Gradient Section** (lines 346-384):
```swift
// Gradient backgrounds for each scale row (if configured and enabled)
if showGradients {
    let activeGradient: FontConfig
.GradientConfig = isPrecisionActive 
        ? .precisionGradient  // Orange-red when precision active
        : displayConfig.scaleNameFont.gradient ?? .default  // Yellow normally
    
    VStack(spacing: 0) {
        ForEach(Array(readings.enumerated()), id: \.element.id) { index, reading in
            ZStack {
                // Scale name gradient (left side) - use active gradient color
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: activeGradient.colors,
                        startPoint: activeGradient.startPoint,
                        endPoint: activeGradient.endPoint
                    )
                    .opacity(activeGradient.opacity)
                    .frame(width: Self.cursorWidth / 2)
                    
                    Spacer()
                }
                
                // Scale value gradient (right side) - use active gradient color
                HStack(spacing: 0) {
                    Spacer()
                    
                    LinearGradient(
                        colors: activeGradient.colors,
                        startPoint: activeGradient.endPoint,  // Flip for right side
                        endPoint: activeGradient.startPoint
                    )
                    .opacity(activeGradient.opacity)
                    .frame(width: Self.cursorWidth / 2)
                }
            }
            .frame(width: Self.cursorWidth, height: scaleHeight)
        }
    }
    .animation(.easeInOut(duration: 0.2), value: isPrecisionActive)
}
```

### 2. [`CursorOverlay.swift`](../TheElectricSlide/Cursor/CursorOverlay.swift)

**Pass Precision State to CursorView** (line 111):
```swift
CursorView(
    height: height,
    readings: readings,
    scaleHeight: scaleHeight,
    displayConfig: displayConfig,
    showReadings: showReadings,
    showGradients: showGradients,
    zoomScale: currentZoomScale,
    cursorDisplayMode: $cursorDisplayMode,
    highlightedScaleIndex: highlightedScaleIndex,
    isPrecisionActive: precisionCoordinator.activeTarget == .cursor  // NEW
)
```

### 3. [`SlideView.swift`](../TheElectricSlide/Components/SlideView.swift)

**Add Precision Overlay**:
```swift
struct SlideView: View, Equatable {
    // ... existing properties ...
    
    /// Whether THIS slide is in precision mode
    var isPrecisionActive: Bool = false
    
    // ... existing equatable ...
    
    var body: some View {
        ZStack {
            // Original slide rendering
            ScaleContainerView(
                container: slide,
                width: width,
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: nameFont,
                formulaFont: formulaFont,
                ruleId: ruleId,
                scaleCount: slide.scales.count
            )
            .equatable()
            
            // Precision mode gradient overlay
            if isPrecisionActive {
                VStack(spacing: 0) {
                    // Top edge gradient
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.3),
                            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: slideHeight * 0.2)
                    .allowsHitTesting(false)
                    
                    Spacer()
                    
                    // Bottom edge gradient
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.15),
                            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: slideHeight * 0.2)
                    .allowsHitTesting(false)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isPrecisionActive)
            }
        }
    }
    
    /// Calculate total height of all scales in slide
    private var slideHeight: CGFloat {
        scaleHeight * CGFloat(slide.scales.count)
    }
}
```

### 4. [`SideView.swift`](../TheElectricSlide/Components/SideView.swift)

**Pass Precision State to SlideView** (line 119):
```swift
SlideView(
    slide: slide,
    width: width,
    backgroundColor: .white,
    borderColor: .orange,
    scaleHeight: scaleHeight,
    leftMarginWidth: leftMarginWidth,
    rightMarginWidth: rightMarginWidth,
    nameFont: nameFont,
    formulaFont: formulaFont,
    ruleId: ruleId,
    isPrecisionActive: precisionCoordinator.activeTarget == .slide  // NEW
)
```

### 5. [`FontConfig.swift`](../TheElectricSlide/Cursor/CursorView.swift) (Add to FontConfig.GradientConfig)

**Add Precision Gradient Preset**:
```swift
extension FontConfig.GradientConfig {
    /// Precision mode gradient: light orange-red with same intensity as default yellow
    static let precision = GradientConfig(
        colors: [
            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.3),
            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.15),
            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.05),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing,
        opacity: 1.0
    )
}
```

## Platform Support

### iOS
- Full support for all visual indicators
- Haptic + visual feedback combined
- Touch-optimized gradients

### macOS
- Full support for all visual indicators
- Trackpad/mouse long-press detection
- No haptic feedback, visual becomes primary indicator

## Testing Strategy

### Visual Verification
1. **Normal State**: Yellow gradients visible on cursor, white slide
2. **Cursor Precision**: Long-press cursor → Orange-red gradients appear
3. **Slide Precision**: Long-press slide → Vertical edge gradients appear
4. **State Isolation**: Activating cursor precision doesn't affect slide, and vice versa
5. **Reset**: Lifting finger returns gradients to normal state

### Zoom Level Testing
1. **Cursor-only zoom**: Verify horizontal gradient visible and color distinguishable
2. **Slide-only zoom**: Verify vertical edge gradients visible and clear
3. **Extreme magnification (5×)**: Confirm gradients scale proportionally
4. **Mixed zoom**: Both visible when both components in view

### Edge Cases
1. **Rapid activation**: Long-press then immediately lift → Gradients should fade in/out cleanly
2. **Mode switching**: Activate cursor precision, then slide precision → Only active target shows indicator
3. **Gesture conflicts**: Precision + pinch zoom → Precision indicators disabled (as per [`isSlideDragEnabled`](../TheElectricSlide/Components/SideView.swift:71-74))

## Performance Considerations

### Optimization
- **Gradient Reuse**: `.precisionGradient` computed once, reused across all scales
- **Conditional Rendering**: Overlay only rendered when `isPrecisionActive == true`
- **Animation Target**: Single property (`isPrecisionActive`) drives all animations
- **No State Thrashing**: Precision state managed by [`PrecisionDragCoordinator`](../TheElectricSlide/Utilities/PrecisionDragCoordinator.swift), updates once per activation/deactivation

### SwiftUI Best Practices
- Use `.animation(_:value:)` to scope animations to state changes only
- `.allowsHitTesting(false)` on overlays prevents gesture interference
- `.transition(.opacity)` for smooth fade effects
- `@Observable` on `PrecisionDragCoordinator` minimizes view updates

## Accessibility

### VoiceOver
**Current Behavior**: No announcement when precision mode activates

**Recommended Additions**:
```swift
// In CursorOverlay.swift, after precisionCoordinator.activate()
.accessibilityAnnouncement("Precision cursor mode activated")

// In SideView.swift, after precisionCoordinator.activate()
.accessibilityAnnouncement("Precision slide mode activated")
```

### Reduce Motion
**Consideration**: Users with reduced motion enabled should still see color change, but without animation

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// Apply animation conditionally
.animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isPrecisionActive)
```

## Future Enhancements

### Phase 2: Progress Indication (If requested)
- **Method**: Fade-in gradient opacity from 0% to 100% over 1-second long press
- **Implementation**: Add `@State var progressOpacity: Double = 0.0` and animate via `Timer.publish()`
- **Reset**: Snap to 100% on activation, fade out on release

### Phase 3: Customizable Indicator Colors
- Add user preferences for precision indicator color
- Store in `UserDefaults` or SwiftData
- Default: Light orange-red (current design)

### Phase 4: Intensity Indicator
- Show "5×" or "PRECISION" label near touch point during drag
- Floating badge that follows cursor/slide position
- Only if user testing shows confusion about mode being active

## Migration Path

### Backward Compatibility
- All changes are additive (new optional parameters)
- Existing behavior unchanged if `isPrecisionActive` not provided
- Gradual rollout: Implement cursor first, then slide

### Rollback Strategy
- If visual feedback deemed too intrusive, simply pass `isPrecisionActive: false`
- Original gradient system remains intact as fallback
- No database migrations or breaking changes

## Success Criteria

### User Experience Goals
1. **Clarity**: Users know when precision mode is activating (haptic confirmed)
2. **Visibility**: Indicator visible at any zoom level where component is visible
3. **Non-Intrusive**: Doesn't obscure scale content or cursor readings
4. **Responsive**: Visual feedback feels immediate (< 200ms perceived latency)

### Technical Goals
1. **Performance**: No dropped frames during gradient transitions
2. **Consistency**: Cursor and slide indicators feel visually harmonious
3. **Maintainability**: Changes isolated to 5 files, clear separation of concerns
4. **Testable**: Visual states can be verified in Xcode Previews and SwiftUI Inspector

## Implementation Checklist

- [ ] Add `.precisionGradient` to `FontConfig.GradientConfig` presets
- [ ] Add `isPrecisionActive` property to `CursorView`
- [ ] Modify cursor gradient rendering to use precision color when active
- [ ] Update `CursorOverlay` to pass precision state to `CursorView`
- [ ] Add `isPrecisionActive` property to `SlideView`
- [ ] Implement vertical gradient overlay in `SlideView`
- [ ] Update `SideView` to pass precision state to `SlideView`
- [ ] Test cursor precision visual feedback at normal zoom
- [ ] Test slide precision visual feedback at normal zoom
- [ ] Test at extreme zoom levels (cursor-only, slide-only)
- [ ] Verify color contrast in light and dark modes
- [ ] Add VoiceOver announcements (Phase 1.5)
- [ ] Test with reduced motion accessibility setting
- [ ] Performance profiling with Instruments
- [ ] Update user documentation

## Diagram: Visual Feedback Flow

```
User Action: Long Press (1 second)
        ↓
PrecisionDragCoordinator.activate(for: .cursor | .slide)
        ↓
precisionCoordinator.activeTarget = .cursor | .slide | .none
        ↓
View Observes activeTarget via @Environment
        ↓
┌─────────────────────────────────┬──────────────────────────────────┐
│  Cursor Precision               │  Slide Precision                 │
│  (activeTarget == .cursor)      │  (activeTarget == .slide)        │
├─────────────────────────────────┼──────────────────────────────────┤
│  CursorView.isPrecisionActive   │  SlideView.isPrecisionActive     │
│  = true                         │  = true                          │
│          ↓                      │           ↓                      │
│  Horizontal gradients           │  Vertical edge gradients         │
│  Yellow → Orange-Red            │  Top + Bottom overlays           │
│  (0.2s ease-in)                 │  (0.2s ease-in)                  │
└─────────────────────────────────┴──────────────────────────────────┘
                    ↓
        User performs drag with 5× precision
                    ↓
        User lifts finger
                    ↓
     PrecisionDragCoordinator.deactivate()
                    ↓
    precisionCoordinator.activeTarget = .none
                    ↓
┌─────────────────────────────────┬──────────────────────────────────┐
│  CursorView.isPrecisionActive   │  SlideView.isPrecisionActive     │
│  = false                        │  = false                         │
│          ↓                      │           ↓                      │
│  Orange-Red → Yellow            │  Gradients fade out              │
│  (0.2s ease-out)                │  (0.2s ease-out)                 │
└─────────────────────────────────┴──────────────────────────────────┘
```

## Related Documentation

- [Precision Mode Implementation](./precision-mode-implementation.md) - Technical details of gesture handling
- [Navigation Gestures and Haptics](./navigation-gestures-haptics-implementation.md) - Comprehensive gesture system
- [Glass Cursor Architecture](./glass-cursor-architecture.md) - Cursor rendering system
- [Cursor Overlay (Source)](../TheElectricSlide/Cursor/CursorOverlay.swift)
- [CursorView (Source)](../TheElectricSlide/Cursor/CursorView.swift)
- [SlideView (Source)](../TheElectricSlide/Components/SlideView.swift)
- [SideView (Source)](../TheElectricSlide/Components/SideView.swift)
- [PrecisionDragCoordinator (Source)](../TheElectricSlide/Utilities/PrecisionDragCoordinator.swift)

---

**Document Version**: 1.0  
**Date**: 2025-12-17  
**Author**: Kilo Code (Architect Mode)  
**Status**: Design Complete - Ready for Implementation
