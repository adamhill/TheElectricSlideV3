# AI Coding Agent Instructions for The Electric Slide

## Project Overview
A modern macOS/iOS slide rule application with a **strict separation** between calculation engine (`SlideRuleCoreV3` Swift package) and SwiftUI rendering (`TheElectricSlide` app). The calculation engine is a pure functional implementation based on PostScript slide rule algorithms and mathematical foundations.

## Agent Capabilities: Local vs Remote

### Local Agents (Running on Developer's Machine)
**Full Access** - Can build, run, and test everything:
- ✅ **App Development**: Use Xcodebuild MCP server to list simulators, build, and run `TheElectricSlide` app
  - List available simulators: `mcp_xcodebuildmcp_list_sims`
  - Build and run on simulator: `mcp_xcodebuildmcp_build_run_ios_sim` or macOS target
  - Interactive testing with UI feedback
- ✅ **Package Development**: Direct `swift` commands for `SlideRuleCoreV3`
  - `swift test` - Run package tests
  - `swift build` - Build package
  - `swift test --filter .fast` - Run tagged tests
- ✅ **Full debugging** with Xcode, Instruments, breakpoints

### Remote Agents (Cloud/Sandbox Environments)
**Limited Access** - Focus on calculation engine:
- ✅ Can modify and test `SlideRuleCoreV3` package code
- ✅ Can read and analyze `TheElectricSlide` app code
- ❌ Cannot run the SwiftUI app (no simulator/UI access)
- ❌ Cannot use Xcodebuild MCP (no local Xcode installation)
- 💡 **Strategy**: Focus work on `SlideRuleCoreV3Tests/` where changes can be validated

## Architecture: Three-Layer Design

### Layer 1: SlideRuleCoreV3 Package (Calculation Engine) ⭐ PRIMARY FOCUS

**Location:** `SlideRuleCoreV3/Sources/SlideRuleCoreV3/`  
**Type:** Local Swift Package (modifiable by agents)  
**Platform:** iOS 18+, macOS 15+, Swift 6  
**Purpose:** Pure calculation engine for scale creation, manipulation, tick mark calculations, and value-from-position lookups - **NO drawing/rendering code by design**

**⚠️ AGENT CAPABILITY:** This package is where remote agents should focus their work. You can:
- ✅ Add new tests to `SlideRuleCoreV3Tests/`
- ✅ Modify scale logic and calculations
- ✅ Add new scale types and functions
- ✅ Fix bugs in the calculation engine
- ❌ Cannot run the SwiftUI app (remote agents only - no sandbox support)


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
**Location:** `TheElectricSlide/ContentView.swift`  
**Platform:** macOS 15+, iOS 18+ (uses `onGeometryChange` from WWDC 2024)  
**⚠️ AGENT LIMITATION:** Agents cannot run or test this app directly (no sandbox support). Focus on SlideRuleCoreV3 package instead.

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
- See `swift-docs/device-specific-breakpoints-plan.md` for patterns

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

**Using Xcodebuild MCP Server (Recommended for Local Agents):**
```swift
// List available iOS simulators
mcp_xcodebuildmcp_list_sims({ enabled: true })

// Build and run on iOS simulator (iPhone 16)
mcp_xcodebuildmcp_build_run_ios_sim({
    projectPath: "/path/to/TheElectricSlide.xcodeproj",
    scheme: "TheElectricSlide",
    platform: "iOS Simulator",
    simulatorName: "iPhone 16"
})

// Build and run on macOS
mcp_xcodebuildmcp_build_run_mac_proj({
    projectPath: "/path/to/TheElectricSlide.xcodeproj",
    scheme: "TheElectricSlide"
})

// Take screenshot of running simulator
mcp_xcodebuildmcp_screenshot({ simulatorUuid: "<uuid>" })
```

**Using Terminal Commands:**
```bash
# Xcode project (not workspace)
open TheElectricSlide.xcodeproj

# Command line build (app + tests)
xcodebuild -project TheElectricSlide.xcodeproj -scheme TheElectricSlide

# Swift package tests only (fast iteration - works for remote agents)
cd SlideRuleCoreV3
swift test

# Run specific test suite with tags
swift test --filter .fast
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

## Critical "Don'ts"

1. **Don't add drawing code to SlideRuleCoreV3** - It's a calculation engine only
2. **Don't recalculate tick marks in Canvas** - Use pre-computed `generatedScale.tickMarks`
3. **Don't use GeometryReader for dimension tracking** - Use `onGeometryChange`
4. **Don't make stators depend on slider state** - Keep `sliderOffset` isolated
5. **Don't use XCTest** - Project uses Swift Testing framework exclusively

## Reference Materials

**In-Repo Documentation:**
- `reference/postscript-rule-engine-explainer.md` - Original PostScript algorithm (1000+ lines)
- `reference/manthematical-foundations-of-the-slide-rule.md` - Mathematical theory
- `swift-docs/swift-sliderule-rendering-improvements.md` - Performance optimization guide
- `swift-docs/swift-testing-playbook.md` - Testing best practices
- `swift-docs/responsive-margin-implementation.md` - Responsive layout system
- `swift-docs/device-specific-breakpoints-plan.md` - iPhone/iPad detection patterns
- `swift-docs/glass-cursor-master-plan.md` - ⭐ **CRITICAL** - Complete cursor architecture and implementation
- `swift-docs/cursor-reading-quick-reference.md` - Cursor interaction patterns
- `reference/api-examples/initial-README.md` - API usage examples

**External References:**
- WWDC 2024: SwiftUI Essentials (`onGeometryChange`)
- Swift Testing documentation: https://developer.apple.com/documentation/testing

## Quick Start for AI Agents

1. **Understanding a scale:** Read `StandardScales.swift` factory functions (e.g., `cScale()`, `ll1Scale()`)
2. **Parser behavior:** See `SlideRuleAssembly.swift` → `RuleDefinitionParser.parse()`
3. **Performance context:** Read `swift-docs/swift-sliderule-rendering-improvements.md` solutions 1-5
4. **Testing patterns:** Check existing tests in `SlideRuleCoreV3Tests/` for @Suite/@Test examples
5. **Rendering flow:** Trace `ContentView.swift` → `StatorView`/`SlideView` → `ScaleView` → Canvas
