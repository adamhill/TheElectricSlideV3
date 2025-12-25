---
applyTo: "TheElectricSlide/**/*.swift"
---

# TheElectricSlide App Guidelines

## Platform Requirements
- macOS 15+, iOS 18+ (uses enhanced `onGeometryChange` modifier)
- **Note**: SwiftUI app requires Xcode and simulators - cannot be run or tested on Linux runners (CI/CD environments like GitHub Actions)
- Remote agents can still read, analyze, and understand SwiftUI code for architectural context

## Architecture Overview

The app uses a clean component-based architecture with strict separation of concerns:

### Entry Point & Data Layer
- `TheElectricSlideApp.swift` - App entry, SwiftData container setup
- `ContentView.swift` - Root view orchestrator, state management, gesture coordination
- `CurrentSlideRule.swift` - SwiftData model for persisted current rule selection
- `SlideRuleLibrary.swift` - Factory methods for standard rule definitions (K&E, Hemmi, etc.)
- `SlideRuleViewModel.swift` - Hot/cold property pattern for performance-optimized state

### Component Hierarchy (`Components/`)
**Top Level:**
- `SlideRuleDetailView.swift` - Main slide rule display container
- `DynamicSlideRuleContent.swift` - Responsive layout for view modes (front/back/both)
- `SlideRuleSidebarView.swift` - Rule selection sidebar (macOS/iPad)

**Rule Rendering:**
- `SideView.swift` - Single side container (front or back), manages stator-slide-stator layout
- `StatorView.swift` - Renders fixed stator with multiple scales
- `SlideView.swift` - Renders movable slide with multiple scales
- `ScaleView.swift` - Single scale rendering via Canvas API
- `ScaleLabelRenderer.swift` - Separate label rendering logic
- `ScaleTickRenderer.swift` - Separate tick mark rendering logic
- `ScaleContainerView.swift` - Scale wrapper with hit testing support

**UI Controls:**
- `FlipButton.swift` - iPhone-specific flip button (front/back toggle)
- `CursorReadingsContainer.swift` - Displays cursor values above/below rule

### Cursor System (`Cursor/`)
Provides precision reading across all scales simultaneously:
- `CursorState.swift` - Observable cursor state (@Observable class)
- `CursorOverlay.swift` - Draggable glass cursor with gradient overlays
- `CursorReadings.swift` - Value computation at cursor position for all visible scales

### Models (`Models/`)
- `LayoutConfiguration.swift` - `Dimensions`, `LayoutTier` (4 responsive breakpoints)
- `ViewMode.swift` - Front/Back/Both display modes
- `CursorDisplayMode.swift` - Cursor display options (gradients/values/both), reading cycle modes
- `RuleSide.swift` - Front/Back enumeration
- `ScaleContainer.swift` - Scale metadata wrapper
- `GestureTypes.swift` - Gesture-related type definitions

### Extensions (`Extensions/`)
- `ContentView+Gestures.swift` - Drag, zoom, pan gesture handlers
- `ContentView+Persistence.swift` - SwiftData load/save/parse logic

### Utilities (`Utilities/`)
- `GestureHandler.swift` - Centralized gesture coordination (Phase 4 refactor)
- `PrecisionDragCoordinator.swift` - Unified precision mode for slide/cursor
- `TickHapticCoordinator.swift` - Haptic feedback when cursor crosses tick marks
- `DeviceDetection.swift` - Device category detection (iPhone/iPad/Mac)
- `ScrollWheelZoomModifier.swift` - Mouse wheel zoom support (macOS)
- `SlideRuleColorScheme.swift` - ⭐ **Centralized color system** for all manufacturer colors and precision mode colors

## Color System (Design Pattern)

**Single Source of Truth:** All colors are defined in `SlideRuleColorScheme.swift`

### Manufacturer Color Schemes
Each manufacturer has a complete color scheme with:
- Background colors (stator, slide, alternate)
- Scale highlight colors (primary, secondary, tertiary)
- Marking colors (standard, inverted, special)
- Label colors (standard, inverted, formula)
- Material appearance (body material, wood grain, cursor frame)
- **Precision mode colors** (overlay and cursor gradients)

### Precision Mode Colors
**Centralized Properties:**
- `precisionOverlayColor` - Slide overlay gradient color (appears when scale highlights disabled)
  - Faber-Castell: `Color(red: 0.2, green: 0.85, blue: 0.4)` - Green
  - All others: `Color(red: 1.0, green: 0.4, blue: 0.3)` - Red-orange
- `cursorPrecisionColor` - Cursor gradient color (matches overlay)
  - Same values as precisionOverlayColor per manufacturer

**Usage Pattern:**
```swift
// ✅ CORRECT - Use centralized color
let precisionColor = colorScheme?.precisionOverlayColor ?? Color(red: 1.0, green: 0.4, blue: 0.3)

// ❌ WRONG - Never hardcode
let precisionColor = Color(red: 1.0, green: 0.4, blue: 0.3)
```

**Documentation Pattern:**
When referencing color values in documentation or comments, always include source:
```swift
/// **Color Source:** SlideRuleColorScheme.faberCastell.precisionOverlayColor
```

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
    let size = proxy.size
    return Dimensions.calculate(
        availableWidth: size.width,
        availableHeight: size.height,
        viewMode: viewMode,
        slideRule: currentSlideRule
    )
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
- Use `@Environment(\.horizontalSizeClass)` for layout adaptation
  - `.compact` = constrained width (iPhones portrait, iPad Split View)
  - `.regular` = spacious width (iPads full screen, large iPhones landscape)
- **Don't** use `UIDevice.current.userInterfaceIdiom` in view bodies

## View Hierarchy
- `ContentView` → `StaticHeaderSection` + `DynamicSlideRuleContent`
- `DynamicSlideRuleContent` → `SideView` → `StatorView` + `SlideView` + `StatorView`
- Each `StatorView`/`SlideView` contains multiple `ScaleView` instances
