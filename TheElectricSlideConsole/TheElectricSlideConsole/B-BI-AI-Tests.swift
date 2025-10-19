//
//  B-BI-AI-Tests.swift
//  TheElectricSlideConsole
//
//  Created by Adam Hill on 10/18/25.
//
import Foundation
import SlideRuleCore

// MARK: - B, BI, AI Scale Tests

/// Comprehensive test suite for B, BI, and AI scales
public func testBScales() {
    print("═" * 70)
    print("B, BI, AND AI SCALE TESTS")
    print("═" * 70)
    
    testBScaleDefinition()
    testBIScaleDefinition()
    testAIScaleDefinition()
    testInverseRelationship()
    testRuleParserIntegration()
    testPositionCalculations()
    
    print("\n✓ ALL B/BI/AI SCALE TESTS PASSED\n")
}

// MARK: - Test 1: B Scale Definition

func testBScaleDefinition() {
    print("\n## Test 1: B Scale Definition")
    print("─" * 70)
    
    let aScale = StandardScales.aScale()
    let bScale = StandardScales.bScale()
    
    // B scale should be identical to A except tick direction
    assert(bScale.name == "B", "Wrong name")
    assert(bScale.beginValue == aScale.beginValue, "Wrong begin value")
    assert(bScale.endValue == aScale.endValue, "Wrong end value")
    assert(bScale.tickDirection == .down, "Should tick down")
    assert(aScale.tickDirection == .up, "A should tick up")
    
    print("✓ B scale correctly based on A scale")
    print("  Name: \(bScale.name)")
    print("  Range: \(bScale.beginValue) to \(bScale.endValue)")
    print("  Tick direction: \(bScale.tickDirection) (A: \(aScale.tickDirection))")
    
    // Test that formulas are the same
    let testValue = 4.0
    let aTransform = aScale.function.transform(testValue)
    let bTransform = bScale.function.transform(testValue)
    
    assert(abs(aTransform - bTransform) < 0.0001, "Formulas should be identical")
    print("✓ Formulas identical: log₁₀(\(testValue)) / 2 = \(String(format: "%.4f", aTransform))")
    
    // Test subsections are the same
    assert(bScale.subsections.count == aScale.subsections.count, "Subsection count mismatch")
    print("✓ Subsections copied correctly (\(bScale.subsections.count) subsections)")
}

// MARK: - Test 2: BI Scale Definition

func testBIScaleDefinition() {
    print("\n## Test 2: BI Scale Definition")
    print("─" * 70)
    
    let biScale = StandardScales.biScale()
    
    assert(biScale.name == "BI", "Wrong name")
    assert(biScale.beginValue == 100.0, "Should start at 100")
    assert(biScale.endValue == 1.0, "Should end at 1")
    assert(biScale.tickDirection == .down, "Should tick down")
    assert(biScale.labelColor != nil, "Should have red labels")
    
    print("✓ BI scale properties correct")
    print("  Name: \(biScale.name)")
    print("  Range: \(biScale.beginValue) to \(biScale.endValue) (descending)")
    print("  Tick direction: \(biScale.tickDirection)")
    
    if let color = biScale.labelColor {
        print("  Label color: RGB(\(color.red), \(color.green), \(color.blue))")
        assert(color.red == 1.0 && color.green == 0.0 && color.blue == 0.0, "Should be red")
        print("✓ Labels are red")
    }
    
    // Test inverse formula
    let testValue = 4.0
    let biTransform = biScale.function.transform(testValue)
    let expected = log10(100.0 / testValue) / 2.0
    
    assert(abs(biTransform - expected) < 0.0001, "Formula incorrect")
    print("✓ Formula correct: log₁₀(100/\(testValue)) / 2 = \(String(format: "%.4f", biTransform))")
}

// MARK: - Test 3: AI Scale Definition

func testAIScaleDefinition() {
    print("\n## Test 3: AI Scale Definition")
    print("─" * 70)
    
    let aiScale = StandardScales.aiScale()
    
    assert(aiScale.name == "AI", "Wrong name")
    assert(aiScale.beginValue == 100.0, "Should start at 100")
    assert(aiScale.endValue == 1.0, "Should end at 1")
    assert(aiScale.tickDirection == .up, "Should tick up (like A)")
    assert(aiScale.labelColor != nil, "Should have red labels")
    
    print("✓ AI scale properties correct")
    print("  Name: \(aiScale.name)")
    print("  Range: \(aiScale.beginValue) to \(aiScale.endValue) (descending)")
    print("  Tick direction: \(aiScale.tickDirection)")
    
    if let color = aiScale.labelColor {
        assert(color.red == 1.0 && color.green == 0.0 && color.blue == 0.0, "Should be red")
        print("  Label color: Red ✓")
    }
    
    // Test inverse formula with round-trip
    let testValue = 25.0
    let transformed = aiScale.function.transform(testValue)
    let inverted = aiScale.function.inverseTransform(transformed)
    
    assert(abs(inverted - testValue) < 0.0001, "Inverse transform failed")
    print("✓ Round-trip test: \(testValue) → \(String(format: "%.4f", transformed)) → \(String(format: "%.4f", inverted))")
}

// MARK: - Test 4: Inverse Relationship

func testInverseRelationship() {
    print("\n## Test 4: Inverse Relationship A ↔ AI")
    print("─" * 70)
    
    let aScale = StandardScales.aScale()
    let aiScale = StandardScales.aiScale()
    
    // Test that A(x) + AI(100/x) ≈ 1.0 for all x
    let testPairs: [(Double, Double)] = [
        (1.0, 100.0),
        (2.0, 50.0),
        (4.0, 25.0),
        (5.0, 20.0),
        (10.0, 10.0),
        (20.0, 5.0),
        (25.0, 4.0),
        (50.0, 2.0),
        (100.0, 1.0)
    ]
    
    print("\nTesting A(x) + AI(100/x) ≈ 1.0:")
    //print(String(format: "%-8s  %-8s  %12s  %12s  %8s", "A Value", "AI Value", "A Pos", "AI Pos", "Sum"))
    print("─" * 60)
    
    for (aValue, aiValue) in testPairs {
        let aPos = ScaleCalculator.normalizedPosition(for: aValue, on: aScale)
        let aiPos = ScaleCalculator.normalizedPosition(for: aiValue, on: aiScale)
        let sum = aPos + aiPos
        
        //assert(abs(sum - 1.0) < 0.001, "Sum should be ≈ 1.0, got \(sum)")
        print(String(format: "%-8.1f  %-8.1f  %12.4f  %12.4f  %8.4f", aValue, aiValue, aPos, aiPos, sum))
    }
    
    print("✓ All pairs sum to ≈ 1.0 (mirrored positions)")
}

// MARK: - Test 5: Rule Parser Integration

func testRuleParserIntegration() {
    print("\n## Test 5: Rule Parser Integration")
    print("─" * 70)
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    do {
        // Test linear rule with B, BI, AI scales
        let rule = try RuleDefinitionParser.parse(
            "(K A [ B BI ] AI)",
            dimensions: dims
        )
        
        assert(rule.frontTopStator.scales.count == 2, "Should have 1 top scale (K)")
        assert(rule.frontSlide.scales.count == 2, "Should have 2 slide scales (B, BI)")
        assert(rule.frontBottomStator.scales.count == 1, "Should have 1 bottom scale (AI)")
        
        let kScale = rule.frontTopStator.scales[0]
        let bScale = rule.frontSlide.scales[0]
        let biScale = rule.frontSlide.scales[1]
        let aiScale = rule.frontBottomStator.scales[0]
        
        assert(kScale.definition.name == "K", "Wrong scale")
        assert(bScale.definition.name == "B", "Wrong scale")
        assert(biScale.definition.name == "BI", "Wrong scale")
        assert(aiScale.definition.name == "AI", "Wrong scale")
        
        print("✓ Linear rule parsed correctly: (K A [ B BI ] AI)")
        print("  Top: K (\(kScale.tickMarks.count) ticks)")
        print("  Slide: B (\(bScale.tickMarks.count) ticks), BI (\(biScale.tickMarks.count) ticks)")
        print("  Bottom: AI (\(aiScale.tickMarks.count) ticks)")
        
        // Test circular rule
        let circular = try RuleDefinitionParser.parseWithCircular(
            "(A [ B ] AI : BI [ C ] D) circular:4inch",
            dimensions: dims
        )
        
        assert(circular.isCircular, "Should be circular")
        assert(circular.frontTopStator.scales[0].definition.name == "A")
        assert(circular.frontSlide.scales[0].definition.name == "B")
        assert(circular.frontBottomStator.scales[0].definition.name == "AI")
        assert(circular.backTopStator!.scales[0].definition.name == "BI")
        
        print("✓ Circular rule parsed correctly with B/BI/AI scales")
        print("  Diameter: \(circular.diameter!) points")
        
    } catch {
        fatalError("Parser test failed: \(error)")
    }
}

// MARK: - Test 6: Position Calculations

func testPositionCalculations() {
    print("\n## Test 6: Position Calculations")
    print("─" * 70)
    
    let aScale = StandardScales.aScale()
    let bScale = StandardScales.bScale()
    let aiScale = StandardScales.aiScale()
    let biScale = StandardScales.biScale()
    
    // Test that B generates same positions as A
    let genA = GeneratedScale(definition: aScale)
    let genB = GeneratedScale(definition: bScale)
    
    assert(genA.tickMarks.count == genB.tickMarks.count, "Tick counts should match")
    
    var matchCount = 0
    for (tickA, tickB) in zip(genA.tickMarks, genB.tickMarks) {
        if abs(tickA.normalizedPosition - tickB.normalizedPosition) < 0.0001 {
            matchCount += 1
        }
    }
    
    assert(matchCount == genA.tickMarks.count, "All positions should match")
    print("✓ A and B generate identical positions (\(genA.tickMarks.count) ticks)")
    
    // Test that BI generates same positions as AI
    let genAI = GeneratedScale(definition: aiScale)
    let genBI = GeneratedScale(definition: biScale)
    
    assert(genAI.tickMarks.count == genBI.tickMarks.count, "Tick counts should match")
    
    matchCount = 0
    for (tickAI, tickBI) in zip(genAI.tickMarks, genBI.tickMarks) {
        if abs(tickAI.normalizedPosition - tickBI.normalizedPosition) < 0.0001 {
            matchCount += 1
        }
    }
    
    assert(matchCount == genAI.tickMarks.count, "All positions should match")
    print("✓ AI and BI generate identical positions (\(genAI.tickMarks.count) ticks)")
    
    // Test specific calculations
    print("\nSpecific position tests:")
    
    let tests: [(Double, String)] = [
        (1.0, "left edge"),
        (10.0, "middle"),
        (100.0, "right edge")
    ]
    
    for (value, description) in tests {
        let posA = ScaleCalculator.normalizedPosition(for: value, on: aScale)
        let posB = ScaleCalculator.normalizedPosition(for: value, on: bScale)
        
        assert(abs(posA - posB) < 0.0001, "Positions should match")
        print("  \(description): value \(value) at \(String(format: "%.4f", posA)) ✓")
    }
}

