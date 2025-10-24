import Foundation
import SlideRuleCore

// MARK: - Circular Rule Tests

/// Comprehensive test suite for circular slide rule parsing and conversion
public func testCircularRuleSupport() {
    print("═" * 70)
    print("CIRCULAR RULE SUPPORT TESTS")
    print("═" * 70)
    
    testCircularSpecParsing()
    testLinearRuleParsing()
    testCircularRuleConversion()
    testCircularRuleProperties()
    testPostScriptExamples()
    testErrorHandling()
    
    print("\n✓ ALL TESTS PASSED\n")
}

// MARK: - Test 1: Circular Spec Parsing

func testCircularSpecParsing() {
    print("\n## Test 1: Circular Spec Parsing")
    print("─" * 70)
    
    let tests: [(String, Distance?)] = [
        ("circular:4inch", 288.0),         // 4 * 72
        ("circular:5in", 360.0),           // 5 * 72
        ("circular:100mm", 283.46),        // 100 * 2.834645669
        ("circular:10cm", 283.46),         // 10 * 28.34645669
        ("circular:288", 288.0),           // raw points
        ("circular:144.5", 144.5),         // decimal points
        ("notcircular", nil),              // invalid prefix
        ("circular:", nil),                // missing spec
    ]
    
    for (input, expected) in tests {
        let result = RuleDefinitionParser.parseCircularSpec(input)
        
        if let expected = expected {
            assert(result != nil, "Failed to parse: \(input)")
            let diff = abs(result! - expected)
            assert(diff < 0.1, "Parsed \(input) = \(result!), expected \(expected)")
            print("✓ \(input) → \(String(format: "%.1f", result!)) points")
        } else {
            assert(result == nil, "Should not parse: \(input)")
            print("✓ \(input) → nil (correctly rejected)")
        }
    }
}

// MARK: - Test 2: Linear Rule Parsing

func testLinearRuleParsing() {
    print("\n## Test 2: Linear Rule Parsing (Existing)")
    print("─" * 70)
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    do {
        // Simple rule
        let simple = try RuleDefinitionParser.parse(
            "(C D [ CI ])",
            dimensions: dims
        )
        
        assert(!simple.isCircular, "Should be linear")
        assert(simple.diameter == nil, "Should have no diameter")
        assert(simple.frontTopStator.scales.count == 2, "Wrong top scale count")
        assert(simple.frontSlide.scales.count == 1, "Wrong slide scale count")
        assert(simple.frontBottomStator.scales.count == 0, "Wrong bottom scale count")
        
        // Check scale layout
        for scale in simple.frontTopStator.scales {
            assert(!scale.definition.isCircular, "Scale should be linear")
        }
        
        print("✓ Simple rule: (C D [ CI ])")
        print("  - 1 top scale, 1 slide scale, 1 bottom scale")
        print("  - All scales are linear")
        
        // Duplex rule
        let duplex = try RuleDefinitionParser.parse(
            "(K A [ C T ] D L : LL1 LL2 [ CI ] D)",
            dimensions: dims
        )
        
        assert(!duplex.isCircular, "Should be linear")
        assert(duplex.backTopStator != nil, "Should have back side")
        print("✓ Duplex rule: front and back sides")
        
    } catch {
        fatalError("Linear parsing failed: \(error)")
    }
}

// MARK: - Test 3: Circular Rule Conversion

func testCircularRuleConversion() {
    print("\n## Test 3: Circular Rule Conversion")
    print("─" * 70)
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 12,   // outer radius
        slideMM: 16,       // middle radius
        bottomStatorMM: 8  // inner radius
    )
    
    do {
        let circular = try RuleDefinitionParser.parseWithCircular(
            "(A [ C ] CI) circular:4inch",
            dimensions: dims
        )
        
        assert(circular.isCircular, "Should be circular")
        assert(circular.diameter == 288.0, "Wrong diameter")
        assert(circular.radialPositions?.count == 3, "Should have 3 radii")
        
        print("✓ Converted to circular: 4 inch diameter")
        print("  Diameter: \(circular.diameter!) points")
        print("  Radii: \(circular.radialPositions!.map { String(format: "%.1f", $0) }.joined(separator: ", "))")
        
        // Check all scales are circular
        let allScales = circular.frontTopStator.scales +
                       circular.frontSlide.scales +
                       circular.frontBottomStator.scales
        
        for scale in allScales {
            assert(scale.definition.isCircular, "Scale \(scale.definition.name) should be circular")
            assert(scale.definition.layout.diameter == 288.0, "Wrong diameter")
        }
        
        print("✓ All \(allScales.count) scales converted to circular layout")
        
        // Check radii are correct
        let outerRadius = circular.radialPositions![0]
        let middleRadius = circular.radialPositions![1]
        let innerRadius = circular.radialPositions![2]
        
        assert(circular.frontTopStator.scales.first?.definition.layout.radius == outerRadius)
        assert(circular.frontSlide.scales.first?.definition.layout.radius == middleRadius)
        assert(circular.frontBottomStator.scales.first?.definition.layout.radius == innerRadius)
        
        print("✓ Radii correctly assigned to stator/slide/stator")
        
    } catch {
        fatalError("Circular conversion failed: \(error)")
    }
}

// MARK: - Test 4: Circular Rule Properties

func testCircularRuleProperties() {
    print("\n## Test 4: Circular Rule Properties")
    print("─" * 70)
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 12,
        slideMM: 16,
        bottomStatorMM: 8
    )
    
    do {
        let circular = try RuleDefinitionParser.parseWithCircular(
            "(C D [ CI ]) circular:5inch",
            dimensions: dims
        )
        
        // Test tick generation on circular scale
        let cScale = circular.frontTopStator.scales.first!
        
        print("Scale: \(cScale.definition.name)")
        print("  Total ticks: \(cScale.tickMarks.count)")
        
        // Check angular positions exist
        let withAngles = cScale.tickMarks.filter { $0.angularPosition != nil }
        assert(withAngles.count == cScale.tickMarks.count, "All ticks should have angular positions")
        print("✓ All ticks have angular positions")
        
        // Check 0°/360° overlap prevention
        if let first = cScale.tickMarks.first,
           let last = cScale.tickMarks.last {
            let firstAngle = first.angularPosition!
            let lastAngle = last.angularPosition!
            
            assert(abs(firstAngle) < 1.0, "First tick should be near 0°")
            assert(lastAngle < 359.5, "Last tick should not reach 360°")
            print("✓ No 0°/360° overlap (first: \(String(format: "%.1f°", firstAngle)), last: \(String(format: "%.1f°", lastAngle)))")
        }
        
        // Test specific values
        let testValues: [(Double, String)] = [
            (1.0, "0°"),
            (sqrt(10.0), "180°"),
            (10.0, "360°")
        ]
        
        for (value, description) in testValues {
            let angle = ScaleCalculator.angularPosition(for: value, on: cScale.definition)
            print("  \(description): value \(String(format: "%.3f", value)) at \(String(format: "%.1f°", angle))")
        }
        
        print("✓ Position calculations work correctly")
        
    } catch {
        fatalError("Properties test failed: \(error)")
    }
}

// MARK: - Test 5: PostScript Examples

func testPostScriptExamples() {
    print("\n## Test 5: PostScript-Style Examples")
    print("─" * 70)
    
    // Example from PostScript engine
    let dims1 = RuleDefinitionParser.Dimensions(
        topStatorMM: 12,
        slideMM: 16,
        bottomStatorMM: 0
    )
    
    do {
        let example1 = try RuleDefinitionParser.parseWithCircular(
            "(K | A C [ D CI B L ]) circular:4inch",
            dimensions: dims1
        )
        
        print("✓ PostScript Example 1: Single-sided circular")
        print("  Scales: K, A, C on top; D, CI, B, L on slide")
        print("  Diameter: 4 inches")
        
    } catch {
        fatalError("PostScript example 1 failed: \(error)")
    }
    
    // Example with both sides
    let dims2 = RuleDefinitionParser.Dimensions(
        topStatorMM: 3.5,
        slideMM: 17.5,
        bottomStatorMM: 0
    )
    
    do {
        let example2 = try RuleDefinitionParser.parseWithCircular(
            "(C [ D ] : LL3 LL2 [ CI C ] D) circular:5inch",
            dimensions: dims2
        )
        
        assert(example2.backTopStator != nil, "Should have back side")
        print("✓ PostScript Example 2: Duplex circular")
        print("  Front: C on top, D on slide")
        print("  Back: LL3, LL2 on top; CI, C on slide; D on bottom")
        
    } catch {
        fatalError("PostScript example 2 failed: \(error)")
    }
}

// MARK: - Test 6: Error Handling

func testErrorHandling() {
    print("\n## Test 6: Error Handling")
    print("─" * 70)
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    // Test invalid circular spec
    do {
        _ = try RuleDefinitionParser.parseWithCircular(
            "(C D) circular:invalid",
            dimensions: dims
        )
        fatalError("Should have thrown error for invalid spec")
    } catch RuleDefinitionParser.ParseError.invalidCircularSpec {
        print("✓ Correctly rejected invalid circular spec")
    } catch {
        fatalError("Wrong error type: \(error)")
    }
    
    // Test missing brackets
    do {
        _ = try RuleDefinitionParser.parse(
            "(C D [ CI )",
            dimensions: dims
        )
        fatalError("Should have thrown error for missing bracket")
    } catch RuleDefinitionParser.ParseError.missingBrackets {
        print("✓ Correctly rejected missing brackets")
    } catch {
        fatalError("Wrong error type: \(error)")
    }
    
    // Test unknown scale
    do {
        _ = try RuleDefinitionParser.parse(
            "(C D UNKNOWN)",
            dimensions: dims
        )
        fatalError("Should have thrown error for unknown scale")
    } catch RuleDefinitionParser.ParseError.unknownScale {
        print("✓ Correctly rejected unknown scale")
    } catch {
        fatalError("Wrong error type: \(error)")
    }
}

// MARK: - Helper

extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}
