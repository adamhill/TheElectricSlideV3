---
applyTo: "**/*Test*.swift"
---

# Test Guidelines (Swift Testing Framework)

## Framework
Use Swift Testing framework for **unit tests** (not XCTest).
- XCTest is still appropriate for **UI tests** (`TheElectricSlideUITests`)
- Platform: Xcode 16+, Swift 6

## Test Structure
```swift
@Suite("Scale Position Calculations")
struct ScalePositionCalculationsSuite {
    @Test("C scale at value 2 calculates correct position", arguments: [1.0, 2.0, 5.0, 10.0])
    func cScalePosition(value: Double) async throws {
        #expect(position > 0.0 && position < 1.0)
    }
}
```

## Key Patterns
- Use nested `@Suite` for logical grouping
- Storytelling test names: `@Test("User sees error when...")`
- Parameterized tests with `arguments:` for value ranges
- `#expect` for soft checks, `#require` for critical unwrapping
- Use `@Tag` for filtering: `@Suite("...", .tags(.fast, .regression))`

## Fuzz Testing Pattern
```swift
@Test("Valid combinations parse successfully", arguments: generateCombinations())
func validCombinations(definition: String) throws {
    let rule = try RuleDefinitionParser.parse(definition, ...)
    #expect(!rule.frontTopStator.scales.isEmpty)
}

static func generateCombinations() -> [String] {
    // Generate test cases programmatically
}
```

## Running Tests
```bash
# Swift package tests (fast iteration)
cd SlideRuleCoreV3
swift test

# Run specific test suite with tags
swift test --filter .fast
```
