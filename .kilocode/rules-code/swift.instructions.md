---
applyTo: "**/*.swift"
---

# Swift Code Guidelines

## Platform Compatibility
- **Swift 6** language mode with strict concurrency checking
- **Linux Compatible**: `SlideRuleCoreV3` package builds and tests on Linux (Swift 6.2+)
- SwiftUI components (`TheElectricSlide`) require macOS/iOS with Xcode

## Code Style
- Use **functional over imperative** patterns - prefer pure functions and immutable data
- **No force-unwrapping** - use `guard`/`if-let` in production code, `#require` in tests
- **Explicit types on public APIs** - avoid type inference in function signatures
- **Sendable compliance** - mark closure parameters `@Sendable` for Swift 6 concurrency
- All types should conform to `Sendable` where possible
- Type erasure (aka, AnyView) for SwiftUI pieces ONLY WHEN ABSOLUTELY NECESSARY.
## String Formatting
- Use Unicode directly for mathematical notation: `"x²"`, `"x³"`, `"e⁰·⁰¹ˣ"`, `"100/x²"`
- `ScaleDefinition` `name` and `formula` properties are `String` (not `AttributedString`)

## Testing (Swift Testing Framework)
- Use Swift Testing framework for **unit tests** (not XCTest)
- XCTest is still used for **UI tests** (`TheElectricSlideUITests`)
- **Linux Compatible**: Tests run via `swift test` on Linux runners
- Use `@Suite` for logical grouping and `@Test` for individual tests
- Storytelling test names: `@Test("User sees error when...")`
- Use `#expect` for soft checks, `#require` for critical unwrapping
- Parameterized tests with `arguments:` for value ranges
- Use `@Tag` for filtering: `@Suite("...", .tags(.fast, .regression))`
- Leverage `TestUtilities/` helpers (RoundTripTester, BoundaryTester, etc.) for common patterns

## Architecture Constraints
- **SlideRuleCoreV3** is a calculation engine only - NO drawing/rendering code
- **TheElectricSlide** handles all SwiftUI rendering
- Use pre-computed tick marks from `GeneratedScale.tickMarks` - never recalculate in Canvas
