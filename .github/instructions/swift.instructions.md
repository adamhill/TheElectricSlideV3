---
applyTo: "**/*.swift"
---

# Swift Code Guidelines

## Code Style
- Use **functional over imperative** patterns - prefer pure functions and immutable data
- **No force-unwrapping** - use `guard`/`if-let` in production code, `#require` in tests
- **Explicit types on public APIs** - avoid type inference in function signatures
- **Sendable compliance** - mark closure parameters `@Sendable` for Swift 6 concurrency
- All types should conform to `Sendable` where possible

## String Formatting
- Use Unicode directly for mathematical notation: `"x²"`, `"x³"`, `"e⁰·⁰¹ˣ"`, `"100/x²"`
- `ScaleDefinition` `name` and `formula` properties are `String` (not `AttributedString`)

## Testing (Swift Testing Framework)
- Use Swift Testing framework exclusively (**not XCTest**)
- Use `@Suite` for logical grouping and `@Test` for individual tests
- Storytelling test names: `@Test("User sees error when...")`
- Use `#expect` for soft checks, `#require` for critical unwrapping
- Parameterized tests with `arguments:` for value ranges
- Use `@Tag` for filtering: `@Suite("...", .tags(.fast, .regression))`

## Architecture Constraints
- **SlideRuleCoreV3** is a calculation engine only - NO drawing/rendering code
- **TheElectricSlide** handles all SwiftUI rendering
- Use pre-computed tick marks from `GeneratedScale.tickMarks` - never recalculate in Canvas
