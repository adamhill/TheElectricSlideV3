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

#### Slide Precision Mode: Intensified Scale Colors
When precision mode is active on the slide, the existing manufacturer scale colors become **more saturated**:

```swift
// Normal gradient (from scaleBackgroundGradient)
LinearGradient(
    stops: [
        .init(color: color.opacity(0.4), location: 0.0),
        .init(color: color.opacity(0.85), location: 0.12),
        .init(color: color.opacity(0.85), location: 0.88),
        .init(color: color.opacity(0.4), location: 1.0)
    ],
    startPoint: .top,
    endPoint: .bottom
)

// Precision gradient (from precisionScaleBackgroundGradient) - HIGHER OPACITY
LinearGradient(
    stops: [
        .init(color: color.opacity(0.6), location: 0.0),   // 40% → 60%
        .init(color: color.opacity(0.95), location: 0.12), // 85% → 95%
        .init(color: color.opacity(0.95), location: 0.88), // 85% → 95%
        .init(color: color.opacity(0.6), location: 1.0)    // 40% → 60%
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

**Slide Color Behavior**:
- **Faber-Castell Green scales** (C, D, CF, DF): Green becomes more intense green
- **Faber-Castell Blue scales** (A, B): Blue becomes more intense blue
- **Pickett/K&E/Hemmi** (no highlight colors): No visual change (requires manufacturer colors ON)
- Only affects scales that have manufacturer highlighting; non-highlighted scales unchanged

#### Cursor Precision Mode: Manufacturer-Specific Gradients
The cursor gradient varies by manufacturer, both in normal and precision modes:

```swift
// Faber-Castell normal: Green gradient
static let green = GradientConfig(
    colors: [
        Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.3),
        Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.15),
        Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.05),
        Color.clear
    ],
    startPoint: .leading,
    endPoint: .trailing,
    opacity: 1.0
)

// Faber-Castell precision: INTENSE green gradient
static let precisionGreen = GradientConfig(
    colors: [
        Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.7),
        Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.5),
        Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.25),
        Color.clear
    ],
    startPoint: .leading,
    endPoint: .trailing,
    opacity: 1.0
)

// Pickett & all others normal: Yellow gradient (default)
static let `default` = GradientConfig(
    colors: [
        Color.yellow.opacity(0.3),
        Color.yellow.opacity(0.15),
        Color.yellow.opacity(0.05),
        Color.clear
    ],
    startPoint: .leading,
    endPoint: .trailing,
    opacity: 1.0
)

// Pickett & all others precision: Red-orange gradient  
static let precision = GradientConfig(
    colors: [
        Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.5),
        Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.3),
        Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.12),
        Color.clear
    ],
    startPoint: .leading,
    endPoint: .trailing,
    opacity: 1.0
)
```

**Cursor Color Behavior**:
- **Faber-Castell Normal**: GREEN gradient (matches their color scheme)
- **Faber-Castell Precision**: INTENSE GREEN gradient (more saturated)
- **Pickett/Others Normal**: YELLOW gradient (default)
- **Pickett/Others Precision**: RED-ORANGE gradient

### Visual Feedback Behavior

#### 1. Cursor Precision Mode
**Trigger**: Long press on cursor glass or handles

**Visual Change**:
- **Target**: Horizontal gradients in [`CursorView`](../TheElectricSlide/Cursor/CursorView.swift:347-383)
- **Faber-Castell**: Green → INTENSE GREEN (0.2s ease-in)
- **Pickett/Others**: Yellow → RED-ORANGE (0.2s ease-in)
- **Duration**: While precision mode active (`precisionCoordinator.activeTarget == .cursor`)
- **Reset**: Returns to normal gradient (0.2s ease-out) when finger lifts

**Implementation Location**:
- `CursorView.manufacturer` property determines gradient color
- Gradient selection in `CursorView.body` checks manufacturer enum
- Apply to both name gradient (left) and value gradient (right)

#### 2. Slide Precision Mode
**Trigger**: Long press on slide component

**Visual Change**:
- **Target**: Scale background gradients in [`ScaleContainerView`](../TheElectricSlide/Components/ScaleContainerView.swift)
- **Effect**: Existing scale colors become MORE SATURATED (not an overlay)
- **Faber-Castell Green scales**: Green opacity increases (40%→60% edges, 85%→95% body)
- **Faber-Castell Blue scales**: Blue opacity increases (same pattern)
- **No Manufacturer Colors**: No visual change (precision still works, just no color feedback)
- **Duration**: While precision mode active (`precisionCoordinator.activeTarget == .slide`)
- **Reset**: Colors return to normal intensity (0.2s ease-out) when finger lifts

**Implementation Location**:
- `ScaleContainerView.isPrecisionActive` property passed from `SlideView`
- `scaleBackground(for:)` helper selects `precisionScaleBackgroundGradient` when active
- Colors intensify in-place; no separate overlay needed

### Progress Indication (Optional - Deferred)

The current design **does not show 0-100% progress** during the 1-second long press. This is intentional:

**Rationale**:
- **Simplicity**: Instant color change on activation is clearer than animated progress
- **Reduced Complexity**: No additional state tracking or animation timers needed
- **Haptic Primary**: The long buzz provides clear activation confirmation
- **Future Enhancement**: Progress could be added via opacity fade-in (0% → 100% brightness) if user testing shows need

### Extreme Zoom Visibility

**Zoom Scenarios**:
1. **Zoomed to cursor only**: Manufacturer-appropriate gradient visible (green for F-C, red-orange for others)
2. **Zoomed to slide only**: Scale colors intensify in-place (green greener, blue bluer)
3. **Zoomed to scale detail**: Individual scale shows intensified color
4. **Normal view**: Both indicators visible simultaneously

**Guaranteed Visibility**:
- Cursor gradients are percentage-based, scale with zoom level
- Slide color intensification affects the actual scale, always visible when scale is visible
- No separate overlay means no pixel-perfect elements that could disappear
- Requires manufacturer colors ON for slide visual feedback

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

**Pass Precision State to ScaleContainerView**:
```swift
struct SlideView: View, Equatable {
    // ... existing properties ...
    
    /// Whether THIS slide is in precision mode
    var isPrecisionActive: Bool = false
    
    // ... existing equatable ...
    
    var body: some View {
        // Slide rendering - precision mode intensifies scale colors via ScaleContainerView
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
            scaleCount: slide.scales.count,
            useManufacturerColors: useManufacturerColors,
            colorScheme: colorScheme,
            isPrecisionActive: isPrecisionActive  // Passed to intensify scale colors
        )
        .equatable()
    }
}
```

**ScaleContainerView uses precision-intensity gradients**:
```swift
/// Creates a background view for a scale, applying manufacturer-specific gradients when enabled
/// When precision mode is active, uses intensified (more saturated) versions of the gradients
@ViewBuilder
private func scaleBackground(for scaleName: String) -> some View {
    if useManufacturerColors, let scheme = colorScheme {
        // Use precision-intensity gradient when precision mode is active
        if isPrecisionActive,
           let precisionGradient = scheme.precisionScaleBackgroundGradient(for: scaleName) {
            precisionGradient
        } else if let gradient = scheme.scaleBackgroundGradient(for: scaleName) {
            gradient
        } else {
            Color.clear
        }
    } else {
        Color.clear
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

**Add Gradient Presets**:
```swift
extension FontConfig.GradientConfig {
    /// Default gradient: yellow (for Pickett and others normal mode)
    static let `default` = GradientConfig(
        colors: [
            Color.yellow.opacity(0.3),
            Color.yellow.opacity(0.15),
            Color.yellow.opacity(0.05),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing,
        opacity: 1.0
    )
    
    /// Green gradient for Faber-Castell (normal mode)
    static let green = GradientConfig(
        colors: [
            Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.3),
            Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.15),
            Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.05),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing,
        opacity: 1.0
    )
    
    /// Precision mode gradient for Pickett and others: red-orange
    static let precision = GradientConfig(
        colors: [
            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.5),
            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.3),
            Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.12),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing,
        opacity: 1.0
    )
    
    /// Precision mode gradient for Faber-Castell: INTENSE green
    static let precisionGreen = GradientConfig(
        colors: [
            Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.7),
            Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.5),
            Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.25),
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
1. **Normal State (F-C)**: Green gradients on cursor, normal green/blue scale colors on slide
2. **Normal State (Pickett/others)**: Yellow gradients on cursor, normal slide colors
3. **Cursor Precision (Faber-Castell)**: Long-press cursor → INTENSE GREEN gradients appear
4. **Cursor Precision (Pickett/others)**: Long-press cursor → RED-ORANGE gradients appear
5. **Slide Precision (F-C colors ON)**: Long-press slide → Green/blue scales intensify to 100%
6. **Slide Precision (F-C colors OFF)**: Long-press slide → GREEN overlay appears (matches F-C brand)
7. **Slide Precision (Pickett/others)**: Long-press slide → Red-orange overlay appears
8. **State Isolation**: Activating cursor precision doesn't affect slide, and vice versa
9. **Reset**: Lifting finger returns all colors to normal state

### Manufacturer Testing
1. **Faber-Castell 62/83 N (colors ON)**: Cursor=green→intense green, slide=intensified green/blue scales
2. **Faber-Castell 62/83 N (colors OFF)**: Cursor=green→intense green, slide=GREEN overlay
3. **Pickett N-16 ES**: Cursor=yellow→red-orange, slide=red-orange overlay
4. **K&E 4081-3**: Cursor=yellow→red-orange, slide=red-orange overlay
5. **Hemmi 266**: Cursor=yellow→red-orange, slide=red-orange overlay
6. **No manufacturer set**: Cursor=yellow→red-orange (default), slide=red-orange overlay

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
│  CursorView.isPrecisionActive   │  ScaleContainerView              │
│  = true                         │  .isPrecisionActive = true       │
│          ↓                      │           ↓                      │
│  Check manufacturer:            │  If useManufacturerColors:       │
│  • F-C → GREEN gradient         │  • Use precisionScaleBackground  │
│  • Others → RED-ORANGE          │  • Opacity: 40→60%, 85→95%       │
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
│  CursorView.isPrecisionActive   │  ScaleContainerView              │
│  = false                        │  .isPrecisionActive = false      │
│          ↓                      │           ↓                      │
│  Return to pale yellow          │  Return to normal opacity        │
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

**Document Version**: 1.4  
**Date**: 2025-12-24  
**Author**: Kilo Code (Architect Mode)  
**Status**: Design Complete - Implemented

**Revision History**:
- v1.4 (2025-12-24): Faber-Castell slide precision now ALWAYS uses GREEN-based treatment:
  - F-C with colors ON: Scales intensify in-place (no overlay)
  - F-C with colors OFF: GREEN overlay appears
  - Other manufacturers: Red-orange overlay (unchanged)
- v1.3 (2025-12-24): Manufacturer-aware cursor gradients in normal AND precision modes:
  - Faber-Castell: green normally → intense green for precision
  - Pickett/others: yellow normally → red-orange for precision
  - Slide: intensified scale colors (F-C) or red-orange overlay (others)
- v1.2 (2025-12-24): Manufacturer-aware precision colors:
  - Slide: Intensifies existing scale colors (green→greener, blue→bluer) instead of overlay
  - Cursor: Green for Faber-Castell, red-orange for Pickett and all others
- v1.1 (2025-12-24): Changed precision colors - cursor uses saturated yellow, slide uses Faber-Castell blue for colorway compatibility
- v1.0 (2025-12-17): Initial design with orange-red for both cursor and slide
