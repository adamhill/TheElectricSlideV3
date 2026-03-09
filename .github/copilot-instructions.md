# AI Coding Agent Instructions for The Electric Slide

## Project Overview
A modern macOS/iOS slide rule application with a **strict separation** between calculation engine (`SlideRuleCoreV3` Swift package) and SwiftUI rendering (`TheElectricSlide` app). The calculation engine is a pure functional implementation based on PostScript slide rule program and mathematical foundations.

## Physical Makeup of a Slide Rule

            --------
[Top Stator]       |
    <--[Slide]-->  [Cursor]
[Bottom Stator]    |
            --------
- Top Stator - static, does not move
- Slide - slides right and left between the two stators. It is positioned via the index (edge) at either end being positioned at a value under or above another scale.
- Bottom Stators - static, does not move
- Cursor - transparent piece that slides over, on top of the stators and slide. It has a thin hairline that runs horizontally. It allows you to "mark" a scale's value on the slide rule, then read a value off of another scale under the hairline's position.

## Agent Capabilities: Local vs Remote

### Local Agents (Running on Developer's Machine)
**Full Access** - Can build, run, and test everything:
- ✅ **App Development**: Use Xcodebuild MCP server to list simulators, build, and run `TheElectricSlide` app
  - List available simulators: `mcp_xcodebuildmcp_list_sims`
- Build and run on simulator: `mcp_xcodebuildmcp_build_run_sim` or macOS target
  - Interactive testing with UI feedback
  
  ### ⚠️ MANDATORY: Use macOS as PRIMARY Platform for UI Testing
  
  **ALWAYS use macOS (`mcp_xcodebuildmcp_build_run_macos`) as the PRIMARY platform when:**
  - Testing UI changes, layouts, or visual rendering
  - Validating gesture interactions (drag, tap, swipe)
  - Inspecting UI hierarchy with `mcp_xcodebuildmcp_describe_ui`
  - Taking screenshots for verification
  - Running the app to observe behavior
  - Debugging visual issues or layout problems
  
  **Why macOS First:**
  - ✅ **Fastest iteration** - Native execution, no simulator overhead
  - ✅ **Most reliable** - Direct hardware access, consistent behavior
  - ✅ **Best debugging** - Full Xcode integration, Instruments support
  - ✅ **User preference** - ⚠️ **Developer manually tests on REAL iOS/iPadOS devices** (iPhone, iPad hardware)
  
  **iOS/iPad simulators are SECONDARY** - Use only when:
  - Specifically testing iPhone-only features (FlipButton, compact layouts)
  - Validating device-specific breakpoints or size classes
  - User explicitly requests simulator testing
  - ⚠️ **Note**: Simulators cannot test haptics - haptic feedback requires physical devices
  
  **Real Device Testing (Developer's Responsibility):**
  - **Agents build and run on macOS** for rapid iteration and automated testing
  - **User manually tests on real hardware** for haptics, gestures, and device-specific validation
  - **Pattern**: Agents verify functionality on macOS → User validates on physical iPhone/iPad
  
  - **Platform priority (in order):**
    - 🥇 **macOS: My Mac (native)** ← DEFAULT CHOICE
    - 🥈 iOS: iPhone 17 Pro Max (only for iPhone-specific features)
    - 🥉 iPadOS: iPad 13-inch (M5) (only for iPad-specific features)
  - Use `mcp_xcodebuildmcp_screenshot` to capture UI state
  - Use `mcp_xcodebuildmcp_describe_ui` to inspect accessibility hierarchy and UI element structure
  - Use `mcp_xcodebuildmcp_tap`, `mcp_xcodebuildmcp_swipe`, `mcp_xcodebuildmcp_type_text` to interact with simulator
  - **Accessibility annotations**: Add `.accessibilityLabel()` and `.accessibilityIdentifier()` to UI elements for better visibility in describe_ui output
- ✅ **Package Development**: Direct `swift` commands for `SlideRuleCoreV3`
  - `swift test` - Run package tests
  - `swift build` - Build package
  - `swift test --filter .fast` - Run tagged tests
- ✅ **Full debugging** with Xcode, Instruments, breakpoints
- ✅ **Apple Documentation Access**: Use MCP servers for API lookup, best practices, and WWDC sessions
  - **Sosumi MCP** (`mcp_sosumi_*`):
    - `searchAppleDocumentation` - Quick search across Apple Developer docs and HIG
    - `fetchAppleDocumentation` - Retrieve specific documentation pages
    - **Use for**: SwiftUI API questions, HIG patterns, quick API reference lookups
    - **Example**: "How does `onGeometryChange` work?" → `mcp_sosumi_searchAppleDocumentation("onGeometryChange SwiftUI")`
  - **Apple Docs MCP** (`mcp_apple-docs_*`):
    - `get_apple_doc_content` - Detailed API documentation pages with full descriptions
    - `get_related_apis` - Discover related APIs and alternatives (e.g., "What can I use instead of GeometryReader?")
    - `get_platform_compatibility` - Check API availability across iOS/macOS versions
    - `get_sample_code` - Browse official Apple sample code projects
    - `search_wwdc_content` / `get_wwdc_video` - WWDC session transcripts and code examples
    - **Use for**: Deep API understanding, migration guides, WWDC session lookups, best practices
    - **Example**: "Show me WWDC sessions about SwiftUI performance" → `mcp_apple-docs_search_wwdc_content("SwiftUI performance")`
  - **Dash API MCP** (`mcp_dash-api_*`):
    - `search_documentation` - Search locally installed Dash docsets (Swift, SwiftUI, UIKit, Foundation)
    - `list_installed_docsets` - See available offline documentation
    - **Use for**: Fast offline lookups, standard library APIs, Foundation types
    - **Example**: "Swift Sendable documentation" → `mcp_dash-api_search_documentation("Sendable")`
  
  **When to Use Which MCP:**
  - **Quick API lookups**: Sosumi MCP (fastest, searches Apple docs directly)
  - **Deep understanding**: Apple Docs MCP (full pages, related APIs, WWDC sessions)
  - **Offline/fast reference**: Dash API MCP (local docsets, standard library)
  - **WWDC research**: Apple Docs MCP (transcripts, code examples, session videos)
  - **Pattern validation**: Any MCP → "Is this the idiomatic SwiftUI approach?"

### Remote Agents (Cloud/Sandbox Environments - Linux Runners)
**Swift Package Development** - Full capability for calculation engine:
- ✅ **Swift 6.2+ available** - Can build and test Swift packages on Linux (compile code, execute tests)
- ✅ Can modify and test `SlideRuleCoreV3` package code using `swift build` and `swift test`
- ✅ Can read and analyze `TheElectricSlide` app code
- ✅ Can run all `SlideRuleCoreV3Tests/` unit tests in Linux environment
- ✅ Can validate calculation logic, scale functions, and parser behavior
- ❌ Cannot run the SwiftUI app (no simulator/UI access - iOS/macOS only)
- ❌ Cannot use Xcodebuild MCP (no local Xcode installation)
- 💡 **Strategy**: Focus work on `SlideRuleCoreV3` package where changes can be fully validated via `swift test`

## Architecture: Three-Layer Design

### Layer 1: SlideRuleCoreV3 Package (Calculation Engine) ⭐ PRIMARY FOCUS

**Location:** `SlideRuleCoreV3/Sources/SlideRuleCoreV3/`  
**Type:** Local Swift Package (modifiable by agents)  
**Platform:** iOS 18+, macOS 15+, Swift 6  
**Purpose:** Pure calculation engine for scale creation, manipulation, tick mark calculations, and value-from-position lookups - **NO drawing/rendering code by design**

**⚠️ AGENT CAPABILITY:** This package is where remote agents should focus their work. You can:
- ✅ **Build with `swift build`** - Compiles on Linux runners (Swift 6.2+)
- ✅ **Test with `swift test`** - Full test suite runs on Linux
- ✅ Add new tests to `SlideRuleCoreV3Tests/`
- ✅ Modify scale logic and calculations
- ✅ Add new scale types and functions
- ✅ Fix bugs in the calculation engine
- ✅ Validate all changes via automated tests in CI/CD
- ❌ Cannot run the SwiftUI app (remote agents only - requires Xcode/simulators)


**Core Files (read these first):**
- `SlideRuleModels.swift` - Core types: `ScaleFunction`, `TickMark`, `TickStyle`, `ScaleLayout`
- `ScaleDefinition.swift` - Scale configuration, formula strings (changed from AttributedString to String)
- `ScaleCalculator.swift` - Tick mark generation using modulo algorithm
- `StandardScales.swift` - ⭐ **MOST IMPORTANT** - Factory functions for all standard scales (C, D, CI, A, K, LL1-3, S, T, L, Log-Log scales, trigonometric scales, electrical engineering scales)
- `SlideRuleAssembly.swift` - `Stator`, `Slide`, `SlideRule` assembly, `RuleDefinitionParser`

**Scale Importance Hierarchy:**
1. **Core Standard Scales** (`StandardScales.swift`) - Essential foundation, most heavily used
2. **Electrical Engineering Scales** (`ElectricalEngineeringScalesExtension.swift`) - Specialized but complete
3. **Hyperbolic Scales** (`HyperbolicScalesExtension.swift`) - Advanced mathematical functions
4. **Circular Scales** - ⚠️ Not yet implemented (future work, see `circularSpec` in models)

**Key Pattern - Pre-computed Tick Marks:**
```swift
// GeneratedScale contains PRE-COMPUTED tick marks - NEVER recalculate
public struct GeneratedScale: Sendable {
    public let definition: ScaleDefinition
    public let tickMarks: [TickMark]  // Already computed during init
}
```

**Parser Pattern - PostScript-style DSL:**
```swift
// Parentheses = stators (fixed), Brackets = slide (movable)
// Example: "(DF [ CF CIF CI C ] D ST)" 
let rule = try RuleDefinitionParser.parse(
    "(DF [ CF CIF CI C ] D ST)",
    dimensions: RuleDefinitionParser.Dimensions(topStatorMM: 14, slideMM: 13, bottomStatorMM: 14),
    scaleLength: 1000
)
```

**Critical Design Decisions:**
1. **Sendable Everywhere** - All types conform to `Sendable` for Swift 6 concurrency
2. **Value Semantics** - Immutable structs, no classes except actors
3. **Protocol-Oriented** - `ScaleFunction` protocol for extensibility
4. **No Drawing** - Calculations return data; rendering is separate responsibility

### Layer 2: TheElectricSlide App (SwiftUI Rendering)
**Location:** `TheElectricSlide/`  
**Platform:** macOS 15+, iOS 18+ (uses `onGeometryChange` from WWDC 2024)  
**⚠️ AGENT LIMITATION:** Remote agents cannot run or test this app directly (requires Xcode/simulators). Focus on SlideRuleCoreV3 package instead.

**Architecture Overview:**
The app follows a clean MVVM-inspired architecture with separate concerns:

**Entry Point & Data:**
- `TheElectricSlideApp.swift` - App entry, SwiftData container setup (`CurrentSlideRule`, `SlideRuleDefinitionModel`)
- `ContentView.swift` - Root view orchestrating all components, gesture handling, state management
- `SlideRuleViewModel.swift` - Hot/cold property pattern for performance-optimized state

**Core Components** (`Components/`):
- `SlideRuleDetailView.swift` - Main slide rule display container
- `DynamicSlideRuleContent.swift` - Responsive layout handler for different view modes (front/back/both)
- `SideView.swift` - Single side container (front or back), manages stator-slide-stator layout
- `StatorView.swift` / `SlideView.swift` - Individual stator/slide rendering with multiple scales
- `ScaleView.swift` - Single scale rendering via Canvas, tick marks, labels
- `ScaleLabelRenderer.swift` / `ScaleTickRenderer.swift` - Separate rendering concerns
- `ScaleContainerView.swift` - Scale wrapper with hit testing
- `FlipButton.swift` - iPhone-specific flip control
- `SlideRuleSidebarView.swift` - Rule selection sidebar (macOS/iPad)
- `CursorReadingsContainer.swift` - Cursor value display

**Cursor System** (`Cursor/`):
- `CursorState.swift` - Observable cursor state (@Observable class)
- `CursorOverlay.swift` - Draggable glass cursor view with gradients
- `CursorReadings.swift` - Value computation at cursor position
- See "Glass Cursor System" section below for detailed patterns

**Models** (`Models/`):
- `LayoutConfiguration.swift` - Dimensions, LayoutTier (4 responsive breakpoints)
- `ViewMode.swift` - Front/Back/Both display modes
- `CursorDisplayMode.swift` - Cursor display options (gradients/values/both)
- `RuleSide.swift` - Front/Back enumeration
- `ScaleContainer.swift` - Scale metadata wrapper
- `GestureTypes.swift` - Gesture-related type definitions

**Extensions** (`Extensions/`):
- `ContentView+Gestures.swift` - Drag, zoom, pan gesture handlers
- `ContentView+Persistence.swift` - SwiftData load/save/parse logic

**Utilities** (`Utilities/`):
- `GestureHandler.swift` - Centralized gesture coordination (Phase 4 refactor)
- `PrecisionDragCoordinator.swift` - Unified precision mode for slide/cursor
- `TickHapticCoordinator.swift` - Haptic feedback on tick mark crossings (slide AND cursor movement)
- `DeviceDetection.swift` - Device category detection (iPhone/iPad/Mac)
- `ScrollWheelZoomModifier.swift` - Mouse wheel zoom support (macOS)

**Haptic Feedback System:**

The app provides tactile feedback when the cursor crosses tick marks during slide or cursor dragging:

**Architecture:** `Utilities/TickHapticCoordinator.swift`
- **Observable State**: `@Observable` class tracks tick crossings
- **Unified Integration**: Both slide dragging AND cursor dragging trigger haptics via same coordinator
- **Scale Selection**: Prioritizes C scale, falls back to first available scale
- **Hairline Position**: Uses cursor position + half cursor width for accurate tick detection
- **Tick Threshold**: Only major ticks (relativeLength ≥ 0.4) trigger haptics
- **Position Tolerances**: 0.0001 normalized units prevent duplicate haptics; 0.01 normalized units are used to find nearby ticks
- **Reset on Drag End**: Clears state so each new drag starts fresh

**Implementation Pattern:**
```swift
// Both slide and cursor use identical haptic pattern:
let hapticScale = TickHapticCoordinator.selectHapticScale(viewMode, currentSlideRule)
if let scale = hapticScale {
    let hairlinePosition = cursorNormalizedPosition + halfCursorWidthNormalized
    tickHapticCoordinator.checkTickCrossing(
        cursorNormalizedPosition: hairlinePosition,
        slideOffset: viewModel.sliderOffset,
        scaleWidth: scaleWidth,
        cScale: scale
    )
}

// On drag end: tickHapticCoordinator.reset()
```

**Integration Points:**
- **Slide Dragging**: `ContentView+Gestures.swift` → `handleDragChanged()` → direct `checkTickCrossing()` call
- **Cursor Dragging**: `CursorOverlay.swift` → `GestureHandler.handleCursorPositionDragChanged()` → `handleCursorDragChanged()` → `checkTickCrossing()` call
- **Precision Mode**: Same haptic behavior during precision dragging (5× slower movement, same tick feedback)

**HapticService Protocol:**
- Default implementation uses `UIImpactFeedbackGenerator` / `NSHapticFeedbackManager`
- Injectable for testing via protocol
- Event types: `.tickCrossed(level: .major/.medium/.minor)`, `.longBuzz` (precision mode activation)

**Performance-Critical Patterns (see `swift-docs/swift-sliderule-rendering-improvements.md`):**

1. **Use Pre-computed Tick Marks** - Pass `GeneratedScale` to views, access `.tickMarks` array directly:
```swift
Canvas { context, size in
    drawScale(context: &context, size: size, 
              tickMarks: generatedScale.tickMarks,  // ✅ Pre-computed
              definition: generatedScale.definition)
}
```

2. **`onGeometryChange` not GeometryReader** - Avoid GeometryReader triggering excessive redraws:
```swift
.onGeometryChange(for: Dimensions.self) { proxy in
    calculateDimensions(availableWidth: proxy.size.width, availableHeight: proxy.size.height)
} action: { newDimensions in
    calculatedDimensions = newDimensions  // Only updates when size changes
}
```

3. **Equatable Views** - Stators are static; prevent unnecessary re-renders:
```swift
struct StatorView: View, Equatable {
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        lhs.width == rhs.width && lhs.scaleHeight == rhs.scaleHeight &&
        lhs.stator.scales.count == rhs.stator.scales.count
    }
}
// Usage: StatorView(...).equatable()
```

4. **`.drawingGroup()` for Complex Canvas** - Offload to Metal for 200+ tick marks:
```swift
Canvas { ... }.drawingGroup()  // Metal-accelerated rendering
```

5. **Separate State** - `sliderOffset` changes shouldn't trigger stator updates:
```swift
@State private var sliderOffset: CGFloat = 0           // Slide position
@State private var calculatedDimensions: Dimensions = ... // Window size
```

**Responsive Layout System (4 Breakpoint Tiers):**
```swift
enum LayoutTier {
    case extraLarge  // 640pt+ width  → 64pt margins, .body font
    case large       // 480-639pt     → 56pt margins, .callout font
    case medium      // 320-479pt     → 48pt margins, .caption font
    case small       // <320pt         → 40pt margins, .caption2 font
}
```
See `swift-docs/responsive-margin-implementation.md` for implementation details.

**Device Detection (iPhone vs iPad/Mac):**
- Use `@Environment(\.horizontalSizeClass)` (`.compact` = iPhone, `.regular` = iPad/Mac)
- **Don't** use `UIDevice.current.userInterfaceIdiom` in view bodies
- See `swift-docs/device-specific-breakpoints-implementation.md` for implementation
- **Implementation**: `StaticHeaderSection` conditionally shows `FlipButton` (iPhone) vs segmented picker (iPad/Mac)
- **iPhone behavior**: Shows single side only (front or back), starts on front, round flip button inline with cursor selector
- **iPad/Mac behavior**: Shows all elements (front/back/both selector), current full UI preserved

**View Hierarchy:**
- `ContentView` → `StaticHeaderSection` + `DynamicSlideRuleContent`
- `DynamicSlideRuleContent` → `SideView` (front/back) → `StatorView` + `SlideView` + `StatorView`
- Each `StatorView`/`SlideView` contains multiple `ScaleView` instances
- Scale labels use Unicode directly: "x²", "e⁰·⁰¹ˣ", "100/x²" (String, not AttributedString)

**Glass Cursor System (Critical Feature):**

The cursor provides precision reading across all visible scales simultaneously.

**Architecture:** `Cursor/CursorOverlay.swift`, `Cursor/CursorState.swift`, `Cursor/CursorReadings.swift`

**Key Components:**
```swift
// CursorState - Observable state management (@Observable class)
@Observable class CursorState {
    var position: CGFloat              // Normalized position (0.0-1.0)
    var isEnabled: Bool                // Cursor visibility
    var currentReadings: CursorReadings?  // Values at cursor position
    var activeDragOffset: CGFloat      // Active drag translation
}

// CursorOverlay - Draggable glass cursor view
CursorOverlay(
    cursorState: cursorState,
    width: scaleWidth,
    height: totalHeight,
    side: .front,
    showReadings: true,
    showGradients: true
)
```

**Critical Patterns:**
1. **Position Storage** - Cursor position stored as normalized value (0.0-1.0), not pixels
2. **Drag Clamping** - Translation clamped to slide bounds during drag, committed on end
3. **Reading Updates** - Values computed by querying each scale's `valueAt(normalizedPosition:)`
4. **No Animation on Drag** - `.animation(nil, value: offset)` prevents vibration during active drag
5. **Layout Alignment** - HStack with spacers matches `ScaleView` geometry exactly for pixel-perfect alignment

**Interaction Modes:**
- **Gradients Only** - Vertical hairline + gradient overlays
- **Values Only** - Numerical readings without visual lines
- **Both** - Full cursor experience (default)

**Reading Display:**
- `CursorReadingsDisplayView` shows computed values above/below slide rule
- Readings include scale name, value, and scientific notation where appropriate
- Supports sticky readings (tap stator) vs live readings (continuous update)

See `swift-docs/glass-cursor-master-plan.md` and `swift-docs/cursor-reading-quick-reference.md` for full implementation details.

### Layer 3: SwiftData Persistence

**Models:** `CurrentSlideRule.swift`
- `SlideRuleDefinitionModel` - Stores rule configurations (name, definition string, dimensions)
- `CurrentSlideRule` - Tracks currently selected rule

**Key Pattern - Definition String Parsing:**
```swift
// SwiftData model stores PostScript-style definition
@Model
final class SlideRuleDefinitionModel {
    var definitionString: String  // "(DF [ CF CIF CI C ] D ST)"
    
    func parseSlideRule(scaleLength: Distance = 1000.0) throws -> SlideRule {
        try RuleDefinitionParser.parse(definitionString, dimensions: ..., scaleLength: scaleLength)
    }
}
```

**Library System:** `SlideRuleLibrary.swift` provides factory methods for standard rules:
- `keuffelEsser4081_3()` - K&E Log-Log Duplex Decitrig
- `hemmi266()` - Japanese precision rule with EE scales
- `circularCR3()` - Circular rule for time/speed/distance
- All return `SlideRuleDefinitionModel` instances ready for SwiftData persistence

## Testing Strategy (Swift Testing Framework)

**Platform:** Xcode 16+, Swift 6, Swift Testing (not XCTest)  
**Docs:** `swift-docs/swift-testing-playbook.md`, `swift-docs/test-coverage-plan.md`

**Key Patterns:**
```swift
@Suite("Scale Position Calculations")
struct ScalePositionCalculationsSuite {
    @Test("C scale at value 2 calculates correct position", arguments: [1.0, 2.0, 5.0, 10.0])
    func cScalePosition(value: Double) async throws {
        #expect(position > 0.0 && position < 1.0)
    }
}
```

**Test Organization:**
- Use nested `@Suite` for logical grouping
- Storytelling test names: `@Test("User sees error when...")`
- Parameterized tests with `arguments:` for value ranges
- `#expect` for soft checks, `#require` for critical unwrapping
- Use `@Tag` for filtering: `@Suite("...", .tags(.fast, .regression))`

**Fuzz Testing Pattern (see `SlideRuleAssemblyFuzzTests.swift`):**
```swift
@Test("Valid combinations parse successfully", arguments: generateCombinations())
func validCombinations(definition: String) throws {
    let rule = try RuleDefinitionParser.parse(definition, ...)
    #expect(!rule.frontTopStator.scales.isEmpty)
}

static func generateCombinations() -> [String] {
    // Generate 100+ test cases programmatically
}
```

**Coverage Gaps (Priority):**
1. `ScaleUtilities.swift` - 0% coverage (ConcurrentScaleGenerator, ScaleValidator, ScaleExporter)
2. `StandardScales.swift` - 52% coverage (missing PA, P, hyperbolic, LL01-03 scales)
3. Precision helpers in `ScaleCalculator.swift`

## Development Workflows

### Building (Local Agents)

**⚠️ CRITICAL: Always prefer Terminal commands FIRST for syntax checks and builds**

**Terminal-First Workflow (Fastest Feedback Loop):**
```bash
# 1. Build app to check for compilation errors (FAST - no UI launch)
cd /Users/adamhill/dev/apple/TheElectricSlideV3/sources/TheElectricSlide
xcodebuild -project TheElectricSlide.xcodeproj -scheme TheElectricSlide -destination 'platform=macOS' build

# 2. Run Swift package tests (calculation engine only)
cd SlideRuleCoreV3
swift test

# 3. Build Swift package to verify changes
swift build

# 4. Run specific test suites
swift test --filter .fast
swift test --filter "Hemmi|H266"
```

**When to Use XcodeBuild MCP (After Terminal Build Succeeds):**

Only use MCP tools when you need to:
- **Visual verification** - See the UI actually running
- **Interactive testing** - Drag, tap, swipe gestures
- **Screenshot capture** - Document UI state
- **UI hierarchy inspection** - Read accessibility tree with `describe_ui`

### ⚠️ ALWAYS START WITH macOS - THIS IS MANDATORY

```swift
// ========================================
// 🥇 STEP 1: BUILD AND RUN ON macOS FIRST
// ========================================
// This is the PRIMARY and DEFAULT choice for ALL UI testing.
// iPad is next in priority if macOS testing is failing
// Do NOT skip to iOS simulators unless specifically needed.

mcp_xcodebuildmcp_build_run_macos()

// ========================================
// 🥉 STEP 2: iPad Simulator (ONLY IF NEEDED)  
// ========================================
// Use ONLY when testing iPad-specific features:
// - Split view layouts
// - Sidebar behavior on iPad
// - Regular size class with different dimensions than Mac
// macOS simulator is not working for some reason

mcp_xcodebuildmcp_build_run_sim()  // For iPad 13-inch (M5)

// ========================================
// 🥈 STEP 3: iOS Simulator (ONLY IF NEEDED)
// ========================================
// Use ONLY when testing iPhone-specific features:
// - FlipButton behavior (iPhone-only control)
// - Compact size class layouts
// - Touch-specific gestures

mcp_xcodebuildmcp_build_run_sim()  // For iPhone 17 Pro Max


// Interactive simulator testing workflow:
// 1. Take screenshot to observe current state
mcp_xcodebuildmcp_screenshot({ simulatorUuid: "<uuid>" })

// 2. Inspect UI hierarchy and accessibility elements
mcp_xcodebuildmcp_describe_ui({ simulatorUuid: "<uuid>" })

// 3. Interact with UI elements
mcp_xcodebuildmcp_tap({ simulatorUuid: "<uuid>", x: 200, y: 300 })
mcp_xcodebuildmcp_swipe({ simulatorUuid: "<uuid>", x1: 100, y1: 400, x2: 300, y2: 400 })
mcp_xcodebuildmcp_type_text({ simulatorUuid: "<uuid>", text: "test input" })

// 4. Take another screenshot to verify changes
mcp_xcodebuildmcp_screenshot({ simulatorUuid: "<uuid>" })
```

**Using Terminal Commands (Production Workflow):**
```bash
# ====== Local Agents (macOS with Xcode) ======
# Xcode project (not workspace)
open TheElectricSlide.xcodeproj

# Command line build (app + tests) - FASTEST for syntax validation
xcodebuild -project TheElectricSlide.xcodeproj -scheme TheElectricSlide

# ====== Remote Agents (Linux Runners) & Local Agents ======
# Swift package tests only (fast iteration - works everywhere)
cd SlideRuleCoreV3
swift test

# Build package to verify compilation
swift build

# Run specific test suite with tags
swift test --filter .fast

# Verbose test output
swift test --verbose

# Note: Test execution times differ significantly by platform
# macOS: 10-20 seconds | Linux runners: >60 seconds (due to virtualization/limited resources)
```

### Performance Profiling
- Use Instruments with SwiftUI template
- Key metrics: View body updates, Canvas render time, CPU during slider drag
- Target: <10 view updates/sec, <16ms Canvas render (60fps)

### Console App for Testing
`TheElectricSlideConsole/` - Standalone CLI for visual inspection of test outputs. Not a primary development tool.

## Project Conventions

### File Naming
- Core types: Singular noun (`ScaleDefinition.swift`, `ScaleCalculator.swift`)
- Extensions: `*Extension.swift` (`HyperbolicScalesExtension.swift`)
- Tests: `*Tests.swift` or `*Suite.swift`

### Documentation Style
- Rich markdown docs in `swift-docs/` and `reference/`
- Code comments focus on "why" not "what"
- Reference external sources: PostScript engine, mathematical foundations PDF

### Code Style
- **Functional over imperative** - Prefer pure functions, immutable data
- **No force-unwrapping** - Use `#require` in tests, guard/if-let in production
- **Explicit types on public APIs** - Avoid type inference in signatures
- **Sendable compliance** - Mark closure parameters `@Sendable` for Swift 6

### String Formatting (Recent Change)
- ScaleDefinition `name` and `formula` are `String` (not `AttributedString`)
- Use Unicode directly: `"x²"`, `"x³"`, `"e⁰·⁰¹ˣ"`, `"100/x²"`
- No AttributedString helper functions

### Color Centralization (Design System)
- **All manufacturer colors centralized** in `SlideRuleColorScheme.swift`
- **Precision mode colors** defined per manufacturer:
  - `precisionOverlayColor` - Slide overlay color (green for Faber-Castell, red-orange for others)
  - `cursorPrecisionColor` - Cursor gradient color (matches overlay color)
- **Never hardcode RGB values** - Always reference `SlideRuleColorScheme` properties
- **Pattern**: `colorScheme?.precisionOverlayColor ?? Color(red: 1.0, green: 0.4, blue: 0.3)` (fallback only)
- **Documentation**: Add `**Color Source:**` comments referencing `SlideRuleColorScheme` property

## Current Feature Status

### ✅ Fully Implemented & Tested
- **Core Calculation Engine** - `SlideRuleCoreV3` package with 100+ scales
- **SwiftUI Rendering** - Canvas-based rendering with Metal acceleration
- **Glass Cursor System** - Draggable cursor with live readings across all scales
- **Haptic Feedback** - Tick crossing haptics for both slide AND cursor movement
- **Precision Mode** - 5× slower dragging with long-press activation
- **Gesture System** - Pinch zoom, pan, slide/cursor drag, vertical flick navigation
- **Responsive Layout** - 4-tier breakpoint system (small/medium/large/extraLarge)
- **Device Detection** - iPhone vs iPad/Mac conditional UI (FlipButton, sidebars)
- **SwiftData Persistence** - Rule definitions and current selection saved
- **Multiple Manufacturer Themes** - K&E, Hemmi, Faber-Castell color schemes

### 🚧 Known Gaps & Future Work
- **Circular Scales** - Not yet implemented (see `circularSpec` in models)
- **Test Coverage** - Some scale types need additional test cases
- **Documentation** - Some advanced scale functions need more examples
- **Performance** - Minor optimization opportunities for very large rule definitions

## Testing on Real Devices vs Simulators

**Agent Responsibility:**
- ✅ Build and run on macOS for rapid iteration
- ✅ Test logic, calculations, layout, rendering
- ✅ Verify UI state with screenshots and describe_ui
- ✅ Run unit tests for calculation engine

**User Responsibility (Manual Testing):**
- 📱 Test haptics on real iPhone/iPad (simulators can't test haptics)
- 📱 Validate gestures on physical touchscreen
- 📱 Verify device-specific behavior (Face ID, haptic engines, sensors)
- 📱 Test across different device sizes (iPhone Pro Max vs SE, iPad 11" vs 13")

**Why This Division:**
- Haptic feedback requires actual haptic hardware (Taptic Engine)
- Gesture refinement benefits from real touch input
- macOS provides fastest iteration for development
- Physical devices provide final validation

## Critical "Don'ts"

1. **Don't add drawing code to SlideRuleCoreV3** - It's a calculation engine only
2. **Don't recalculate tick marks in Canvas** - Use pre-computed `generatedScale.tickMarks`
3. **Don't use GeometryReader for dimension tracking** - Use `onGeometryChange`
4. **Don't make stators depend on slider state** - Keep `sliderOffset` isolated
5. **Don't use XCTest** - Project uses Swift Testing framework exclusively
6. **Don't skip terminal builds** - Always run `xcodebuild` or `swift test` BEFORE using MCP tools
7. **Don't test on iOS simulator first** - Always start with macOS for UI verification
8. **Don't assume haptics work in simulator** - Real device testing required
9. **Don't hardcode RGB values** - Use `SlideRuleColorScheme` properties for all colors
10. **Don't implement without checking MCP** - Verify modern Swift/SwiftUI patterns first

## Reference Materials

**In-Repo Documentation:**
- `reference/postscript-rule-engine-explainer.md` - Original PostScript algorithm (1000+ lines)
- `reference/manthematical-foundations-of-the-slide-rule.md` - Mathematical theory on why as slide rule work / how it works
- `swift-docs/swift-sliderule-rendering-improvements.md` - Performance optimization guide
- `swift-docs/swift-testing-playbook.md` - Testing best practices
- `swift-docs/responsive-margin-implementation.md` - Responsive layout system
- `swift-docs/device-specific-breakpoints-plan.md` - iPhone/iPad detection patterns
- `swift-docs/glass-cursor-master-plan.md` - ⭐ **CRITICAL** - Complete cursor architecture and implementation
- `swift-docs/cursor-reading-quick-reference.md` - Cursor interaction patterns
- `swift-docs/navigation-gestures-haptics-implementation.md` - Complete gesture and haptic system documentation
- `reference/api-examples/initial-README.md` - API usage examples

**External References - Use MCP Servers for Live Documentation:**

**Pattern: Always verify modern Swift/SwiftUI patterns via MCP before implementing**

### When to Use MCP Servers:

1. **Before implementing new features**: "What's the idiomatic SwiftUI way to handle X?"
   ```
   mcp_sosumi_searchAppleDocumentation("SwiftUI X pattern")
   mcp_apple-docs_get_related_apis("SwiftUI.X")
   ```

2. **When encountering deprecated APIs**: "Is there a better alternative?"
   ```
   mcp_apple-docs_get_platform_compatibility("GeometryReader")
   mcp_apple-docs_get_related_apis("SwiftUI.GeometryReader")
   ```

3. **For performance optimization**: "What did Apple recommend at WWDC?"
   ```
   mcp_apple-docs_search_wwdc_content("SwiftUI performance Canvas")
   mcp_apple-docs_get_wwdc_video(<video_id>)
   ```

4. **For design patterns**: "What does the HIG say about X?"
   ```
   mcp_sosumi_fetchAppleDocumentation("Human Interface Guidelines X")
   ```

### Key MCP Tools Reference:

| Task | MCP Tool | Example |
|------|----------|---------|
| Quick API search | `mcp_sosumi_searchAppleDocumentation` | `("onGeometryChange SwiftUI")` |
| Full API docs | `mcp_apple-docs_get_apple_doc_content` | `("SwiftUI/View/onGeometryChange")` |
| Find alternatives | `mcp_apple-docs_get_related_apis` | `("SwiftUI.GeometryReader")` |
| WWDC sessions | `mcp_apple-docs_search_wwdc_content` | `("Canvas rendering performance")` |
| Local docsets | `mcp_dash-api_search_documentation` | `("Sendable Swift")` |
| Sample code | `mcp_apple-docs_get_sample_code` | `("SwiftUI state management")` |

**Don't hardcode assumptions** - Verify modern patterns via MCP servers, especially for:
- Swift 6 concurrency (`@Sendable`, `@MainActor`)
- SwiftUI lifecycle (iOS 18+, macOS 15+)
- Performance best practices (Canvas, `.drawingGroup()`, modifiers)
- Gesture handling and coordination

**Example MCP Usage Flow:**
```
User asks: "Should I use GeometryReader for tracking view size?"
↓
Agent searches: mcp_sosumi_searchAppleDocumentation("GeometryReader alternatives SwiftUI")
↓
Agent finds: onGeometryChange (iOS 18+) is preferred
↓
Agent confirms: mcp_apple-docs_get_apple_doc_content("SwiftUI/View/onGeometryChange")
↓
Agent implements using modern API + documents reason in code comment
```

## Quick Start for AI Agents

1. **Understanding a scale:** Read `StandardScales.swift` factory functions (e.g., `cScale()`, `ll1Scale()`)
2. **Parser behavior:** See `SlideRuleAssembly.swift` → `RuleDefinitionParser.parse()`
3. **Performance context:** Read `swift-docs/swift-sliderule-rendering-improvements.md` solutions 1-5
4. **Testing patterns:** Check existing tests in `SlideRuleCoreV3Tests/` for @Suite/@Test examples
5. **Rendering flow:** Trace `ContentView.swift` → `StatorView`/`SlideView` → `ScaleView` → Canvas
6. **Haptics system:** Read `TickHapticCoordinator.swift` to understand tick crossing detection for slide AND cursor
7. **Interactive testing workflow (⚠️ ALWAYS USE macOS FIRST):**
   - **🥇 PRIMARY:** Build and run on macOS: `mcp_xcodebuildmcp_build_run_macos()` ← START HERE
   - Take screenshots: `mcp_xcodebuildmcp_screenshot` to observe UI state
   - Inspect deterministically: `mcp_xcodebuildmcp_describe_ui` to read scale names, formulas, annotations, and UI text
   - Interact: `mcp_xcodebuildmcp_tap`, `mcp_xcodebuildmcp_swipe`, `mcp_xcodebuildmcp_type_text`
   - Verify: Take another screenshot to confirm expected behavior
   - **Only use iOS simulator** if testing iPhone-specific features (FlipButton, compact layout)
   - **Remember**: Haptics require real devices - user tests those manually
8. **API documentation lookup (REQUIRED for modern Swift/SwiftUI):**
   - Quick search: `mcp_sosumi_searchAppleDocumentation("API name SwiftUI")`
   - Detailed docs: `mcp_apple-docs_get_apple_doc_content("SwiftUI/View/APIName")`
   - Find alternatives: `mcp_apple-docs_get_related_apis("SwiftUI.OldAPI")`
   - WWDC sessions: `mcp_apple-docs_search_wwdc_content("topic keywords")`
   - Local docsets: `mcp_dash-api_search_documentation("Swift type")`

**Best Practice Flow:**
```
New feature request
↓
1. Research idiomatic pattern via MCP (sosumi/apple-docs)
↓
2. Read relevant in-repo docs (swift-docs/, reference/)
↓
3. Implement following established patterns
↓
4. Build and test on macOS (mcp_xcodebuildmcp_build_run_macos)
↓
5. Verify with screenshots/describe_ui
↓
6. User validates haptics/gestures on real device
```

**Note**: UI testing via MCP can be flaky - use screenshots and describe_ui for verification, but expect occasional inconsistencies.
