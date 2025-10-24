// ... existing code ...
# SlideRule Test Coverage Plan
*Following Swift Testing Playbook 2024 Best Practices*

## Executive Summary

This document outlines a comprehensive testing strategy for the SlideRuleCore package, focusing on untested functionality and edge cases. The plan follows WWDC 2024 Swift Testing best practices including nested suites, parameterized tests, storytelling test names, and extensive use of fuzz testing.

## Current Test Coverage Analysis

### ✅ Well-Covered Areas
- **ScalePositionCalculationsSuite.swift** - Comprehensive position calculations (474 lines)
- **ScaleFunctionImplementationsSuite.swift** - All scale function types tested (467 lines)
- **ModuloTickGenerationTests.swift** - Modulo algorithm extensively tested (664 lines)
- **ParserAndErrorHandlingTests.swift** - Parser validation and error paths (679 lines)

### ⚠️ Coverage Gaps Identified

#### Priority 1: CRITICAL (Untested Code)
1. **ScaleUtilities.swift** - 0% coverage
   - `ConcurrentScaleGenerator` actor (lines 7-54)
   - `ScaleInterpolation` utilities (lines 59-95)
   - `ScaleValidator` validation logic (lines 100-194)
   - `ScaleAnalysis` statistics (lines 199-277)
   - `ScaleExporter` CSV/JSON export (lines 282-346)

#### Priority 2: HIGH (Function Coverage Gaps)
2. **StandardScales.swift** - 52.38% coverage
   - Only 11 of 21 scale lookup functions tested
   - Missing: PA, P scale variants, Hyperbolic scales
   - Missing: Extended LL scales (LL01, LL02, LL03)
   - Missing: Circular scale variations with precision

3. **ScaleCalculator.swift** - Precision helpers untested
   - `ModuloTickConfig.recommendedPrecisionMultiplier` (lines 32-69)
   - Automatic xfactor calculation
   - Interval-based precision recommendations

#### Priority 3: MEDIUM (Edge Cases)
4. **ScaleDefinition.swift** - 60% coverage
   - Boundary condition handling
   - Edge case validation
   - Complex subsection scenarios

---

## Priority 1: ScaleUtilities Test Suite

### Test File: `ScaleUtilitiesTests.swift`

```swift
@Suite("Scale Utilities - Comprehensive Coverage")
struct ScaleUtilitiesTests {
    
    /// STORY: "Generating multiple scales concurrently"
    @Suite("Concurrent Scale Generation")
    struct ConcurrentGenerationTests {
        
        @Test("Concurrent generator produces scales in original order")
        @Test("Concurrent generation with 10 scales completes successfully")
        @Test("Concurrent generation maintains scale definition integrity")
        @Test("Actor-based generation is thread-safe under stress")
        @Test("Empty scale array returns empty results")
        @Test("Single scale generation works correctly")
    }
    
    /// STORY: "Interpolating values between tick marks"
    @Suite("Scale Interpolation Utilities")
    struct InterpolationTests {
        
        @Test("Interpolation finds value at normalized position", arguments: [
            (position: 0.0, expectedValue: 1.0),
            (position: 0.5, expectedValue: 3.162),
            (position: 1.0, expectedValue: 10.0)
        ])
        @Test("Nearest labeled tick is found correctly")
        @Test("Major divisions are identified properly")
        @Test("Interpolation works on circular scales")
    }
    
    /// STORY: "Validating scale mathematical correctness"
    @Suite("Scale Validation")
    struct ValidationTests {
        
        @Test("Valid scale passes all validation checks")
        @Test("Invalid range throws appropriate error", arguments: [
            "infinite begin value",
            "infinite end value",
            "equal begin and end values",
            "NaN values"
        ])
        @Test("Function round-trip validation catches inaccuracies")
        @Test("Empty subsections throw validation error")
        @Test("Overlapping subsections detected")
        @Test("Slide rule validation collects all errors")
    }
    
    /// STORY: "Analyzing scale statistics and density"
    @Suite("Scale Analysis")
    struct AnalysisTests {
        
        @Test("Scale statistics computed correctly")
        @Test("Tick density varies across scale regions")
        @Test("Highest density region identified")
        @Test("Statistics handle edge cases", arguments: [
            "scale with 0 ticks",
            "scale with 1 tick",
            "scale with all same-size ticks"
        ])
    }
    
    /// STORY: "Exporting scale data to external formats"
    @Suite("Scale Export Utilities")
    struct ExportTests {
        
        @Test("CSV export produces valid format")
        @Test("CSV export handles special characters in labels")
        @Test("JSON export produces parseable output")
        @Test("JSON export maintains all scale metadata")
        @Test("Export handles scales with no labels")
        @Test("Export handles circular scales correctly")
    }
}
```

---

## Priority 2: StandardScales & Precision Helpers

### Test File: `StandardScalesComprehensiveTests.swift`

```swift
@Suite("Standard Scales - Complete Function Coverage")
struct StandardScalesComprehensiveTests {
    
    /// STORY: "Testing all scale lookup functions"
    @Suite("Individual Scale Lookups")
    struct ScaleLookupTests {
        
        @Test("All 42 standard scale names resolve", arguments: [
            "C", "D", "CI", "CF", "DF", "CIF",
            "A", "B", "K", "AI", "BI",
            "LL1", "LL2", "LL3",
            "S", "T", "ST", "L", "LN",
            "KE-S", "KE-T", "SRT",
            "C10-100", "C100-1000", "D10-100",
            "CAS", "TIME", "TIME2", "CR3S",
            "R1", "R2", "SQ1", "SQ2",
            "Q1", "Q2", "Q3",
            // Add more...
        ])
        
        @Test("Scale variations with different lengths")
        @Test("Case-insensitive lookup works")
    }
    
    /// STORY: "Testing weird and exotic scales"
    @Suite("Exotic Scale Implementations")
    struct ExoticScalesTests {
        
        @Test("PA (Power of A) scale generation", arguments: [
            (begin: 1.0, end: 100.0),
            (begin: 1.0, end: 1000.0)
        ])
        
        @Test("P (Pythagoran) scale calculations")
        
        @Test("Hyperbolic scales", arguments: [
            "Sh - Hyperbolic sine",
            "Ch - Hyperbolic cosine", 
            "Th - Hyperbolic tangent"
        ])
        
        @Test("Extended LL scales with precision", arguments: [
            (name: "LL01", range: (1.01, 1.105)),
            (name: "LL02", range: (1.105, 2.72)),
            (name: "LL03", range: (2.72, 21000.0))
        ])
    }
    
    /// STORY: "Testing circular scale positioning"
    @Suite("Circular Scale Variations")
    struct CircularScaleTests {
        
        @Test("Circular C scale with full 360° coverage")
        @Test("Circular LL scales maintain precision at boundaries")
        @Test("Circular trig scales handle angle wrapping")
        @Test("Partial circular arcs (90°, 180°, 270°)")
    }
}

@Suite("Precision Multiplier Helpers")
struct PrecisionMultiplierTests {
    
    @Test("Recommended xfactor for fine intervals", arguments: [
        (interval: 0.001, expectedXfactor: 10000),
        (interval: 0.01, expectedXfactor: 1000),
        (interval: 0.1, expectedXfactor: 100),
        (interval: 1.0, expectedXfactor: 10)
    ])
    
    @Test("Xfactor calculation for subsection")
    @Test("Xfactor calculation for entire scale definition")
    @Test("Edge case: all zero intervals returns default")
}
```

---

## Priority 3: ScaleDefinition Edge Cases

### Test File: `ScaleDefinitionEdgeCasesTests.swift`

```swift
@Suite("Scale Definition Edge Cases")
struct ScaleDefinitionEdgeCasesTests {
    
    @Suite("Boundary Condition Handling")
    struct BoundaryTests {
        
        @Test("Scale with extreme value ranges")
        @Test("Subsection boundaries at scale limits")
        @Test("Zero-width subsections")
        @Test("Overlapping vs. adjacent subsections")
    }
    
    @Suite("Complex Subsection Scenarios")
    struct ComplexSubsectionTests {
        
        @Test("Many subsections (>10)")
        @Test("Single subsection covering full range")
        @Test("Subsections with null intervals")
        @Test("Non-contiguous subsections")
    }
    
    @Suite("Label Formatter Edge Cases")
    struct LabelFormatterTests {
        
        @Test("Formatter handling very large values")
        @Test("Formatter handling very small values")
        @Test("Formatter with scientific notation")
        @Test("Custom formatters with unicode")
    }
}
```

---

## Parameterized Test Strategy: Fuzz Testing Scale Assembly

### Test File: `ScaleAssemblyFuzzTests.swift`

```swift
@Suite("Scale Assembly - Fuzz Testing with Parameterization")
struct ScaleAssemblyFuzzTests {
    
    /// STORY: "Parsing hundreds of scale combinations"
    @Suite("Assembly Definition Fuzzing")
    struct AssemblyFuzzTests {
        
        @Test("Valid scale combinations", arguments: generateValidCombinations())
        func validCombinations(definition: String) throws {
            let dims = RuleDefinitionParser.Dimensions(topStatorMM: 14, slideMM: 13, bottomStatorMM: 14)
            let rule = try RuleDefinitionParser.parse(definition, dimensions: dims)
            
            #expect(rule.frontTopStator.scales.count >= 0)
            #expect(rule.frontSlide.scales.count >= 0)
            #expect(rule.frontBottomStator.scales.count >= 0)
        }
        
        @Test("Exotic scale combinations", arguments: generateExoticCombinations())
        @Test("Circular rule variations", arguments: generateCircularCombinations())
        @Test("Front and back side combinations", arguments: generateTwoSidedCombinations())
    }
    
    /// Generate 100+ test cases programmatically
    static func generateValidCombinations() -> [String] {
        let scales = ["C", "D", "CI", "A", "K", "S", "T", "L", "LL1", "LL2", "LL3"]
        var combinations: [String] = []
        
        // Generate 2-scale combinations
        for i in 0..<scales.count {
            for j in i+1..<scales.count {
                combinations.append("(\(scales[i]) [ \(scales[j]) ])")
            }
        }
        
        // Generate 3-scale combinations  
        for i in 0..<min(5, scales.count) {
            for j in i+1..<min(6, scales.count) {
                for k in j+1..<min(7, scales.count) {
                    combinations.append("(\(scales[i]) [ \(scales[j]) ] \(scales[k]))")
                }
            }
        }
        
        return combinations
    }
    
    static func generateExoticCombinations() -> [String] {
        [
            "(LL01 LL02 [ LL03 ])",
            "(Sh Ch [ Th ])",
            "(PA [ P ] PA)",
            "(KE-S KE-T [ KE-ST ])",
            "(TIME [ TIME2 ])",
            // ... more exotic combinations
        ]
    }
}
```

---

## Circular Scale Boundary Testing

### Key Test Scenarios

1. **Full Circle Overlap Prevention** (0°/360°)
   - Test that scales don't duplicate ticks at start/end
   - Verify `skipCircularOverlap` configuration

2. **Partial Arcs with Precision**
   - 90° arcs with fine intervals
   - 180° arcs with LL scale precision
   - 270° arcs with trig scales

3. **LL Scales on Circular Rules**
   - LL01 (1.01 to 1.105) on 4-inch diameter
   - LL02 (1.105 to 2.72) with precision boundaries
   - LL03 (2.72 to 21000) extreme range handling

---

## Implementation Timeline

### Phase 1: Priority 1 Tests (This Session)
- [ ] Create `ScaleUtilitiesTests.swift`
- [ ] Implement concurrent generation tests
- [ ] Implement interpolation tests
- [ ] Implement validation tests
- [ ] Implement analysis tests
- [ ] Implement export tests

### Phase 2: Priority 2 Tests  
- [ ] Create `StandardScalesComprehensiveTests.swift`
- [ ] Implement all scale lookup tests
- [ ] Implement exotic scale tests
- [ ] Implement circular scale tests
- [ ] Create `PrecisionMultiplierTests.swift`

### Phase 3: Priority 3 Tests
- [ ] Create `ScaleDefinitionEdgeCasesTests.swift`
- [ ] Implement boundary tests
- [ ] Implement complex subsection tests

### Phase 4: Fuzz Testing
- [ ] Create `ScaleAssemblyFuzzTests.swift`
- [ ] Generate 100+ test combinations
- [ ] Run coverage analysis

---

## Code Coverage Goals

| Component | Current | Target | Priority |
|-----------|---------|--------|----------|
| ScaleUtilities | 0% | 85%+ | P1 |
| StandardScales | 52% | 90%+ | P2 |
| ScaleCalculator (precision) | ~30% | 80%+ | P2 |
| ScaleDefinition | 60% | 85%+ | P3 |
| Parser (fuzz) | 70% | 95%+ | P4 |

---

## Testing Principles Applied

✅ **F.I.R.S.T Principles**
- **Fast**: Parallel execution by default
- **Isolated**: Fresh suite instance per test
- **Repeatable**: Deterministic test data
- **Self-Validating**: `#expect` assertions
- **Timely**: Tests written alongside features

✅ **Swift Testing Best Practices**
- Nested suites for organization
- Storytelling test names
- Parameterized tests to reduce duplication
- `#expect` over `#require` (soft checks)
- Async/await for concurrency tests
- `confirmation` for async events

---

## Next Steps

1. **Run this plan session**: Implement Priority 1 tests
2. **Code review**: Verify test quality and coverage
3. **Run code coverage**: Use Xcode coverage tools
4. **Iterate**: Adjust based on actual coverage numbers
5. **Document gaps**: Update this plan with findings

---

*Document Version: 1.0*  
*Last Updated: 2025-01-19*  
*Author: Kilo Code (Architect Mode)*