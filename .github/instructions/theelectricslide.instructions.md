---
applyTo: "TheElectricSlide/**/*.swift"
---

# TheElectricSlide App Guidelines

## Platform Requirements
- macOS 15+, iOS 18+ (uses enhanced `onGeometryChange` modifier)
- **Note**: SwiftUI app requires Xcode and simulators - cannot be run or tested on Linux runners (CI/CD environments like GitHub Actions)
- Remote agents can still read, analyze, and understand SwiftUI code for architectural context

## ⚠️ MANDATORY: macOS is the PRIMARY Testing Platform

**ALWAYS use macOS (`mcp_xcodebuildmcp_build_run_macos`) as your FIRST and DEFAULT choice when:**
- Running the app to test UI changes
- Validating layouts, rendering, or visual appearance
- Testing gesture interactions (slide dragging, cursor movement, taps)
- Taking screenshots for verification
- Inspecting UI hierarchy with `mcp_xcodebuildmcp_describe_ui`
- Debugging any visual or interaction issues

**Why macOS MUST be primary:**
- ✅ **Fastest build/run cycle** - No simulator boot time, native execution
- ✅ **Most reliable results** - Direct hardware, no virtualization quirks
- ✅ **Best debugging experience** - Full Xcode/Instruments integration
- ✅ **Developer preference** - User manually tests on real iOS devices for iOS-specific validation

**iOS/iPad simulators are SECONDARY - Use ONLY when:**
- Testing iPhone-only UI (e.g., `FlipButton`, `.compact` size class layouts)
- Validating iPad-specific features (sidebar, split view)
- User explicitly requests simulator testing for a specific device

```swift
// ✅ CORRECT - Always start with macOS
mcp_xcodebuildmcp_build_run_macos()

// ❌ WRONG - Don't jump to iOS simulator by default
mcp_xcodebuildmcp_build_run_sim()  // Only use for iPhone-specific features!
```

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

## CRITICAL: SlideRuleLibrary Version Bumping

**⚠️ ALWAYS bump `libraryVersion` when modifying SlideRuleLibrary.swift**

When adding, removing, or modifying any slide rule definition (`definitionString`, scale overrides, manufacturer, etc.):

1. **Increment `libraryVersion`** - This triggers SwiftData to refresh cached rules
2. **Add version comment** - Document what changed in the version history

```swift
// ❌ WRONG - Forgetting to bump version
static func standardRules() -> [SlideRuleDefinitionModel] {
    // Added new rule but didn't bump version - users won't see it!
}

// ✅ CORRECT - Always bump and document
/// Version 27: Added Pickett N-16 ES Annotation Test
static let libraryVersion = 27  // Bumped from 26
```

**Why this matters:**
- SwiftData caches slide rule definitions
- Without version bump, existing users never see new/modified rules
- The app compares `libraryVersion` against stored version to detect updates
- New rules simply won't appear in the sidebar until version is bumped

## CRITICAL: NO @Transient Properties for Persisted Data

**⚠️ NEVER use `@Transient` for data that must survive app restart**

`@Transient` properties in SwiftData models are **never saved to the database**. They reset to default values when the model is loaded from storage.

```swift
// ❌ WRONG - @Transient resets on load
@Model
final class SlideRuleDefinitionModel {
    @Transient var showFormulas: Bool = true  // Always resets to true!
    @Transient var annotations: [ComponentAnnotation] = []  // Always empty!
}

// ✅ CORRECT - Use persisted properties
@Model
final class SlideRuleDefinitionModel {
    var showFormulas: Bool = true  // Persisted!
    var annotationsJSON: String?   // JSON-encode complex types
}
```

**For complex types** (arrays, custom structs) that SwiftData can't store directly:
1. Store as JSON-encoded `String?`
2. Add computed property to decode on access
3. Encode in factory methods before saving

```swift
// Store complex types as JSON
var backSlideAnnotationsJSON: String?

// Decode on access
var backSlideAnnotations: [ComponentAnnotation] {
    guard let json = backSlideAnnotationsJSON,
          let data = json.data(using: .utf8) else { return [] }
    return (try? JSONDecoder().decode([ComponentAnnotation].self, from: data)) ?? []
}
```

## CRITICAL: Sync New Model Properties in Library Update Logic

**⚠️ When adding NEW properties to `SlideRuleDefinitionModel`, you MUST update BOTH:**

1. `SlideRulePicker.swift` - Update logic around line 127-145
2. `SlideRuleSidebarView.swift` - Update logic around line 210-230

The library update logic copies properties from standard rules to existing rules. If a new property isn't copied, existing users' cached rules won't get the new values even after a version bump.

```swift
// ❌ WRONG - Added new property but forgot to sync
existingRule.libraryVersion = standardRule.libraryVersion
// showFormulas is NOT copied - existing rules keep default value!

// ✅ CORRECT - Always sync ALL properties
existingRule.libraryVersion = standardRule.libraryVersion
existingRule.showScaleNames = standardRule.showScaleNames
existingRule.showFormulas = standardRule.showFormulas
existingRule.suppressEvenScaleNames = standardRule.suppressEvenScaleNames
existingRule.backSlideAnnotationsJSON = standardRule.backSlideAnnotationsJSON
```

## View Hierarchy
- `ContentView` → `StaticHeaderSection` + `DynamicSlideRuleContent`
- `DynamicSlideRuleContent` → `SideView` → `StatorView` + `SlideView` + `StatorView`
- Each `StatorView`/`SlideView` contains multiple `ScaleView` instances
