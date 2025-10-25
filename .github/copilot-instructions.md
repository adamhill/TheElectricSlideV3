# AI Coding Agent Instructions for The Electric Slide

## Project Overview
A modern macOS/iOS slide rule application with a **strict separation** between calculation engine (`SlideRuleCoreV3` Swift package) and SwiftUI rendering (`TheElectricSlide` app). The calculation engine is a pure functional implementation based on PostScript slide rule algorithms and mathematical foundations.

## Architecture: Two-Layer Design

### Layer 1: SlideRuleCoreV3 Package (Calculation Engine) ⭐ PRIMARY FOCUS

**Location:** `SlideRuleCoreV3/Sources/SlideRuleCoreV3/`  
**Type:** Local Swift Package (modifiable by agents)  
**Platform:** iOS 18+, macOS 15+, Swift 6  
**Purpose:** Pure calculation engine for scale creation, manipulation, tick mark calculations, and value-from-position lookups - **NO drawing/rendering code by design**

**⚠️ AGENT CAPABILITY:** This package is where agents should focus their work. You can:
- ✅ Add new tests to `SlideRuleCoreV3Tests/`
- ✅ Modify scale logic and calculations
- ✅ Add new scale types and functions
- ✅ Fix bugs in the calculation engine
- ❌ Cannot run the SwiftUI app (no sandbox support)

**Core Files (read these first):**
- `SlideRuleModels.swift` - Core types: `ScaleFunction`, `TickMark`, `TickStyle`, `ScaleLayout`
- `ScaleDefinition.swift` - Scale configuration, formula strings (changed from AttributedString to String)
- `ScaleCalculator.swift` - Tick mark generation using modulo algorithm
- `StandardScales.swift` - Factory functions for C, D, CI, A, K, LL1-3, S, T scales
- `SlideRuleAssembly.swift` - `Stator`, `Slide`, `SlideRule` assembly, `RuleDefinitionParser`

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
**Platform:** macOS 13+, iOS 16+ (uses `onGeometryChange` from WWDC 2024)  
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

**View Hierarchy:**
- `ContentView` → VStack → `StatorView` (top) + `SlideView` + `StatorView` (bottom)
- Each contains multiple `ScaleView` instances rendering individual scales
- Scale labels are plain `String` (not AttributedString) with Unicode superscripts: "x²", "e⁰·⁰¹ˣ"

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

**Coverage Gaps (Priority):**
1. `ScaleUtilities.swift` - 0% coverage (ConcurrentScaleGenerator, ScaleValidator, ScaleExporter)
2. `StandardScales.swift` - 52% coverage (missing PA, P, hyperbolic, LL01-03 scales)
3. Precision helpers in `ScaleCalculator.swift`

**Test Organization:**
- Use nested `@Suite` for logical grouping
- Storytelling test names: `@Test("User sees error when...")`
- Parameterized tests with `arguments:` for value ranges
- `#expect` for soft checks, `#require` for critical unwrapping

## Development Workflows

### Building
```bash
# Xcode project (not workspace)
open TheElectricSlide.xcodeproj

# Command line build
xcodebuild -project TheElectricSlide.xcodeproj -scheme TheElectricSlide

# Swift package tests only
cd SlideRuleCoreV3
swift test
```

### Performance Profiling
```bash
# Use Instruments with SwiftUI template
# Key metrics: View body updates, Canvas render time, CPU during slider drag
# Target: <10 view updates/sec, <16ms Canvas render (60fps)
```

### Console App for Testing
**Location:** `TheElectricSlideConsole/` - Standalone CLI for visual inspection of test outputs from older workflows and lightweight smoke tests. Not a primary development tool.

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
