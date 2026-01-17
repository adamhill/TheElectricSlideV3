---
applyTo: "**/*Test*.swift"
---

# Test Guidelines (Swift Testing Framework)

## Framework
Use Swift Testing framework for **unit tests** (not XCTest).
- XCTest is still appropriate for **UI tests** (`TheElectricSlideUITests`)
- Platform: Xcode 16+, Swift 6
- **Linux Compatible**: Tests run on Linux runners via `swift test` (Swift 6.2+)

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

## Parametric Testing Patterns

### Single Parameter
```swift
@Test("Round-trip accuracy", arguments: ScaleTestData.allFunctions)
func roundTripAccuracy(testCase: FunctionTestCase) {
    FunctionRoundTripTester.testRoundTrip(testCase.function, values: testCase.testValues)
}

@Test("All foods available", arguments: Food.allCases)
func foodAvailable(food: Food) { /* test */ }

@Test("Can make large orders", arguments: 1 ... 100)
func largeOrders(quantity: Int) { /* test */ }
```

### Multiple Parameters (Cartesian Product)
```swift
@Test("Cross-product testing", arguments: Food.allCases, 1 ... 100)
func crossProduct(food: Food, quantity: Int) {
    // Tests all combinations: every food × every quantity
}
```

### Zipped Parameters (Paired Values)
```swift
@Test("Paired values", arguments: zip(["A", "B", "C"], [1, 2, 3]))
func pairedTest(name: String, value: Int) {
    // Tests only: ("A", 1), ("B", 2), ("C", 3)
}
```

## TestUtilities Infrastructure

The `TestUtilities/` directory provides reusable test helpers:

### Tolerance Constants (`TestTolerance.swift`)
```swift
TestTolerance.standard      // 0.01 (1%) - most calculations
TestTolerance.strict        // 0.001 (0.1%) - high precision
TestTolerance.relaxed       // 0.05 (5%) - complex calculations
TestTolerance.eeScale       // 0.05 - electrical engineering scales
TestTolerance.veryRelaxed   // 0.1 (10%) - sampling/approximations
```

### Round-Trip Testing (`RoundTripTester.swift`)
Test bidirectional conversion accuracy (value→position→value):
```swift
RoundTripTester.testRoundTrip(value: 5.0, on: cScale, tolerance: TestTolerance.standard)
RoundTripTester.testRoundTrips(values: [1.0, 2.0, 5.0], on: scale)
RoundTripTester.testPositionRoundTrips(positions: [0.0, 0.5, 1.0], on: scale)
```

### Boundary Testing (`BoundaryTester.swift`)
Verify scale endpoints map correctly:
```swift
BoundaryTester.expectCorrectBoundaries(scale, tolerance: 0.01)
BoundaryTester.expectCorrectBoundaryValues(scale, tolerance: 0.01)
```

### Parity Testing (`ParityTestHelper.swift`)
Test scales that should produce identical positions (C/D, CI/DI, A/B, etc.):
```swift
ParityTestHelper.testCompleteParity(scalePair, length: 250.0)
ParityTestHelper.testAllParityPairs()  // Tests all predefined pairs

// Access predefined parity pairs
ParityTestHelper.parityPairs  // [ScalePair(C/D, CI/DI, A/B, AI/BI, CF/DF, CIF/DIF)]
```

### Scale Comparison (`ScaleComparator.swift`)
Compare related scales:
```swift
ScaleComparator.expectIdenticalPositions(scale1, scale2, at: testValues, tolerance: 0.0001)
ScaleComparator.expectMatchingPrecision(scale1, scale2, at: testValues)
ScaleComparator.expectSimilarTickCounts(scale1, scale2, allowedDifference: 5)
```

### Standard Test Values (`TestValues.swift`)
Predefined value sets for consistency:
```swift
TestValues.logarithmic           // [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0]
TestValues.logarithmicExtended   // [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
TestValues.squared               // [1.0, 3.162..., 10.0, 25.0, 64.0, 100.0]
TestValues.folded                // [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159]
TestValues.inverted              // [1.0, 2.0, 4.0, 5.0, 7.5, 10.0]
TestValues.positions             // [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
```

### Test Scale Data (`ScaleTestData/`)
Comprehensive scale test data organized by type:
- `ScaleTestData+StandardScales.swift` - C, D, CI, A, K, etc.
- `ScaleTestData+LogLogScales.swift` - LL1, LL2, LL3, etc.
- `ScaleTestData+TrigScales.swift` - S, T, ST, etc.
- `ScaleTestData+EEScales.swift` - Electrical engineering scales
- `ScaleTestData+HyperbolicScales.swift` - Sh, Th, sinh, cosh
- `ScaleTestData+PowerScales.swift` - Squared, cubed scales
- `ScaleTestData+FoldedScales.swift` - CF, DF, CIF, DIF
- `ScaleTestData+ScaleFunctions.swift` - Function test cases with tolerance

### Scale Factory (`TestScaleFactory.swift`)
Type-safe scale retrieval for tests:
```swift
TestScaleFactory.getScale(named: "C", length: 250.0)  // Returns Optional
TestScaleFactory.getScaleOrFail(named: "C", length: 250.0)  // Records Issue if not found
```

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
# Swift package tests (fast iteration - works on Linux and macOS)
cd SlideRuleCoreV3
swift test

# Run specific test suite with tags
swift test --filter .fast

# Build before testing (verify compilation)
swift build && swift test

# Note: Linux runners (CI/CD environments) may execute tests slower due to virtualization
# and limited CPU resources compared to local macOS development machines. Test execution
# times may vary significantly, but correctness should be consistent across platforms.
# Expect: macOS 10-20 seconds, Linux runners >60 seconds for full test suite.
```
