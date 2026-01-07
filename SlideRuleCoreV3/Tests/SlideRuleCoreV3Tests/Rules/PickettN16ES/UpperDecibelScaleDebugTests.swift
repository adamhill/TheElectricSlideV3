import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Debug tests for the Upper dB Scale (>DB) positioning issue
/// This scale should:
/// - Start at position 0.0 (left edge) with value 20 dB
/// - End at position 1.0 (right edge) with value 60 dB
/// - Use LINEAR spacing (not logarithmic)
@Suite("Upper Decibel Scale Debug Tests", .tags(.pickettN16ES))
struct UpperDecibelScaleDebugTests {
    
    // MARK: - LinearDecibelFunction Transform Tests
    
    @Test("LinearDecibelFunction: transform(20) returns 0.0")
    func testTransform20ReturnsZero() {
        let function = LinearDecibelFunction(minDB: 20.0, maxDB: 60.0)
        let result = function.transform(20.0)
        #expect(abs(result - 0.0) < 0.0001)
    }
    
    @Test("LinearDecibelFunction: transform(40) returns 0.5")
    func testTransform40ReturnsHalf() {
        let function = LinearDecibelFunction(minDB: 20.0, maxDB: 60.0)
        let result = function.transform(40.0)
        #expect(abs(result - 0.5) < 0.0001)
    }
    
    @Test("LinearDecibelFunction: transform(60) returns 1.0")
    func testTransform60ReturnsOne() {
        let function = LinearDecibelFunction(minDB: 20.0, maxDB: 60.0)
        let result = function.transform(60.0)
        #expect(abs(result - 1.0) < 0.0001)
    }
    
    @Test("LinearDecibelFunction: inverseTransform(0.0) returns 20")
    func testInverseTransformZeroReturns20() {
        let function = LinearDecibelFunction(minDB: 20.0, maxDB: 60.0)
        let result = function.inverseTransform(0.0)
        #expect(abs(result - 20.0) < 0.0001)
    }
    
    @Test("LinearDecibelFunction: inverseTransform(0.5) returns 40")
    func testInverseTransformHalfReturns40() {
        let function = LinearDecibelFunction(minDB: 20.0, maxDB: 60.0)
        let result = function.inverseTransform(0.5)
        #expect(abs(result - 40.0) < 0.0001)
    }
    
    @Test("LinearDecibelFunction: inverseTransform(1.0) returns 60")
    func testInverseTransformOneReturns60() {
        let function = LinearDecibelFunction(minDB: 20.0, maxDB: 60.0)
        let result = function.inverseTransform(1.0)
        #expect(abs(result - 60.0) < 0.0001)
    }
    
    @Test("LinearDecibelFunction: round-trip transform/inverse")
    func testRoundTripTransform() {
        let function = LinearDecibelFunction(minDB: 20.0, maxDB: 60.0)
        
        for value in [20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0] {
            let position = function.transform(value)
            let recovered = function.inverseTransform(position)
            #expect(abs(recovered - value) < 0.0001)
        }
    }
    
    // MARK: - upperDecibelLinearScale Definition Tests
    
    @Test("upperDecibelLinearScale: scale definition has correct range")
    func testScaleDefinitionRange() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        #expect(abs(scale.beginValue - 20.0) < 0.0001)
        #expect(abs(scale.endValue - 60.0) < 0.0001)
    }
    
    @Test("upperDecibelLinearScale: scale has correct name")
    func testScaleDefinitionName() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        #expect(scale.name == ">db")
    }
    
    @Test("upperDecibelLinearScale: subsection starts at 20.0")
    func testSubsectionStartsAt20() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        guard let firstSubsection = scale.subsections.first else {
            Issue.record("Scale has no subsections")
            return
        }
        #expect(abs(firstSubsection.startValue - 20.0) < 0.0001)
    }
    
    // MARK: - Tick Generation Tests
    
    @Test("upperDecibelLinearScale: tick generation produces ticks from position 0 to 1")
    func testTickGenerationRange() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: scale)
        
        guard !ticks.isEmpty else {
            Issue.record("No ticks generated")
            return
        }
        
        // Find the position range of generated ticks
        let positions = ticks.map { $0.normalizedPosition }
        let minPosition = positions.min()!
        let maxPosition = positions.max()!
        
        print("DEBUG: Generated \(ticks.count) ticks")
        print("DEBUG: Position range: \(minPosition) to \(maxPosition)")
        
        // First tick should be near position 0.0
        #expect(minPosition < 0.05)
        
        // Last tick should be near position 1.0
        #expect(maxPosition > 0.95)
    }
    
    @Test("upperDecibelLinearScale: first tick is at value 20 dB")
    func testFirstTickValue() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: scale)
        
        guard let firstTick = ticks.first else {
            Issue.record("No ticks generated")
            return
        }
        
        print("DEBUG: First tick - value: \(firstTick.value), position: \(firstTick.normalizedPosition)")
        
        // First tick should be at 20 dB (the beginValue)
        #expect(abs(firstTick.value - 20.0) < 0.5)
    }
    
    @Test("upperDecibelLinearScale: last tick is at value 60 dB")
    func testLastTickValue() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: scale)
        
        guard let lastTick = ticks.last else {
            Issue.record("No ticks generated")
            return
        }
        
        print("DEBUG: Last tick - value: \(lastTick.value), position: \(lastTick.normalizedPosition)")
        
        // Last tick should be at 60 dB (the endValue)
        #expect(abs(lastTick.value - 60.0) < 0.5)
    }
    
    @Test("upperDecibelLinearScale: ticks are uniformly spaced")
    func testTicksUniformlySpaced() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: scale)
        
        // Get major ticks (every 5 dB)
        let majorTicks = ticks.filter { tick in
            let value = tick.value
            let rounded = value.rounded()
            return abs(value - rounded) < 0.1 && Int(rounded) % 5 == 0
        }.sorted { $0.normalizedPosition < $1.normalizedPosition }
        
        print("DEBUG: Major tick positions:")
        for tick in majorTicks {
            print("  \(tick.value) dB -> position \(tick.normalizedPosition)")
        }
        
        // For a linear scale, major ticks (at 5 dB intervals) should be evenly spaced
        // 20, 25, 30, 35, 40, 45, 50, 55, 60 = 9 major ticks
        // Expected positions: 0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0
        let expectedPositions = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]
        
        #expect(majorTicks.count >= 9)
        
        if majorTicks.count >= 9 {
            for (index, expectedPos) in expectedPositions.enumerated() {
                let actualPos = majorTicks[index].normalizedPosition
                #expect(abs(actualPos - expectedPos) < 0.02)
            }
        }
    }
    
    // MARK: - Parser Integration Tests
    
    @Test("Parser: >DB resolves to upperDecibelLinearScale")
    func testParserResolvesUpperDB() {
        let scale = StandardScales.scale(named: ">DB", length: 250.0)
        #expect(scale != nil)
        
        if let scale = scale {
            #expect(scale.name == ">db")
            #expect(abs(scale.beginValue - 20.0) < 0.0001)
            #expect(abs(scale.endValue - 60.0) < 0.0001)
        }
    }
    
    @Test("Parser: UPPERDB resolves to same scale")
    func testParserResolvesUpperDBAlias() {
        let scale1 = StandardScales.scale(named: ">DB", length: 250.0)
        let scale2 = StandardScales.scale(named: "UPPERDB", length: 250.0)
        
        #expect(scale1 != nil && scale2 != nil)
        
        if let s1 = scale1, let s2 = scale2 {
            #expect(s1.name == s2.name)
            #expect(abs(s1.beginValue - s2.beginValue) < 0.0001)
        }
    }
    
    // MARK: - ScaleCalculator Position Tests
    
    @Test("ScaleCalculator: normalizedPosition for 20 dB returns 0.0")
    func testNormalizedPositionAt20() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let position = ScaleCalculator.normalizedPosition(for: 20.0, on: scale)
        print("DEBUG: Position for 20 dB = \(position)")
        #expect(abs(position - 0.0) < 0.0001)
    }
    
    @Test("ScaleCalculator: normalizedPosition for 40 dB returns 0.5")
    func testNormalizedPositionAt40() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let position = ScaleCalculator.normalizedPosition(for: 40.0, on: scale)
        print("DEBUG: Position for 40 dB = \(position)")
        #expect(abs(position - 0.5) < 0.0001)
    }
    
    @Test("ScaleCalculator: normalizedPosition for 60 dB returns 1.0")
    func testNormalizedPositionAt60() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let position = ScaleCalculator.normalizedPosition(for: 60.0, on: scale)
        print("DEBUG: Position for 60 dB = \(position)")
        #expect(abs(position - 1.0) < 0.0001)
    }
    
    @Test("ScaleCalculator: value at position 0.0 returns 20 dB")
    func testValueAtPosition0() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let value = ScaleCalculator.value(at: 0.0, on: scale)
        print("DEBUG: Value at position 0.0 = \(value)")
        #expect(abs(value - 20.0) < 0.0001)
    }
    
    @Test("ScaleCalculator: value at position 0.5 returns 40 dB")
    func testValueAtPosition05() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let value = ScaleCalculator.value(at: 0.5, on: scale)
        print("DEBUG: Value at position 0.5 = \(value)")
        #expect(abs(value - 40.0) < 0.0001)
    }
    
    @Test("ScaleCalculator: value at position 1.0 returns 60 dB")
    func testValueAtPosition1() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let value = ScaleCalculator.value(at: 1.0, on: scale)
        print("DEBUG: Value at position 1.0 = \(value)")
        #expect(abs(value - 60.0) < 0.0001)
    }
    
    // MARK: - Full Pipeline Test
    
    @Test("Full Pipeline: upperDecibelLinearScale generates correct tick positions")
    func testFullPipeline() {
        let scale = StandardScales.upperDecibelLinearScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: scale)
        
        print("\n=== FULL PIPELINE DEBUG ===")
        print("Scale: \(scale.name)")
        print("Range: \(scale.beginValue) to \(scale.endValue)")
        print("Function: \(scale.function.name)")
        print("Subsections: \(scale.subsections.count)")
        
        for (index, subsection) in scale.subsections.enumerated() {
            print("  Subsection \(index): startValue=\(subsection.startValue), intervals=\(subsection.tickIntervals)")
        }
        
        print("\nGenerated \(ticks.count) ticks:")
        
        // Print first 10 and last 10 ticks
        let sortedTicks = ticks.sorted { $0.normalizedPosition < $1.normalizedPosition }
        let firstTicks = sortedTicks.prefix(10)
        let lastTicks = sortedTicks.suffix(10)
        
        print("First 10 ticks:")
        for tick in firstTicks {
            print("  value=\(tick.value), position=\(tick.normalizedPosition), style=\(tick.style)")
        }
        
        print("Last 10 ticks:")
        for tick in lastTicks {
            print("  value=\(tick.value), position=\(tick.normalizedPosition), style=\(tick.style)")
        }
        
        // Assertions
        guard let firstTick = sortedTicks.first, let lastTick = sortedTicks.last else {
            Issue.record("No ticks generated")
            return
        }
        
        // The scale should generate ticks starting at position 0 and ending at position 1
        #expect(firstTick.normalizedPosition < 0.01)
        #expect(lastTick.normalizedPosition > 0.99)
        // Value checks
        #expect(abs(firstTick.value - 20.0) < 0.5)
        #expect(abs(lastTick.value - 60.0) < 0.5)
    }
    
    // MARK: - Pickett N-16 ES Integration Test
    
    @Test("Pickett N-16 ES: >DB scale in back stator has correct positioning")
    func testPickettN16ESUpperDBScale() throws {
        // This is the EXACT definition from SlideRuleLibrary.swift line 124
        let definitionString = "(SH1 SH2- TH DF [ CF L S Cos ST T CI C ] D LL3 LL2 LL1 Ln : Θ₁^ Θ₂ α >DB D XL Xc [ L PF λ ω τ Cr ] Lr db CosΘ)"
        
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let rule = try RuleDefinitionParser.parse(
            definitionString,
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        print("\n=== PICKETT N-16 ES BACK SIDE DEBUG ===")
        
        // Check back top stator
        guard let backTopStator = rule.backTopStator else {
            Issue.record("Back top stator not found")
            return
        }
        
        print("Back top stator has \(backTopStator.scales.count) scales:")
        for (index, scale) in backTopStator.scales.enumerated() {
            let def = scale.definition
            print("  \(index): \(def.name) - begin=\(def.beginValue), end=\(def.endValue), splitSegment=\(String(describing: def.splitSegment))")
        }
        
        // Find the >DB scale (should be named >db based on upperDecibelLinearScale)
        let upperDBScale = backTopStator.scales.first { scale in
            scale.definition.name == ">db" || scale.definition.name == ">DB"
        }
        
        guard let dbScale = upperDBScale else {
            Issue.record(">DB scale not found in back top stator")
            return
        }
        
        print("\n>DB Scale Details:")
        print("  Name: \(dbScale.definition.name)")
        print("  Begin: \(dbScale.definition.beginValue)")
        print("  End: \(dbScale.definition.endValue)")
        print("  Function: \(dbScale.definition.function.name)")
        print("  Split segment: \(String(describing: dbScale.definition.splitSegment))")
        print("  Tick count: \(dbScale.tickMarks.count)")
        
        // Check tick positions
        let sortedTicks = dbScale.tickMarks.sorted { $0.normalizedPosition < $1.normalizedPosition }
        
        if let firstTick = sortedTicks.first, let lastTick = sortedTicks.last {
            print("\n  First tick: value=\(firstTick.value), position=\(firstTick.normalizedPosition)")
            print("  Last tick: value=\(lastTick.value), position=\(lastTick.normalizedPosition)")
            
            // CRITICAL ASSERTIONS
            #expect(firstTick.normalizedPosition < 0.01, "First tick should be at position ~0.0")
            #expect(lastTick.normalizedPosition > 0.99, "Last tick should be at position ~1.0")
            #expect(abs(firstTick.value - 20.0) < 0.5, "First tick should be at value ~20 dB")
            #expect(abs(lastTick.value - 60.0) < 0.5, "Last tick should be at value ~60 dB")
        } else {
            Issue.record("No ticks found on >DB scale")
        }
        
        // Check that the scale is NOT a split scale
        #expect(dbScale.definition.splitSegment == nil, ">DB should NOT be a split scale")
    }
    
    @Test("Pickett N-16 ES: >DB scale positions major ticks correctly")
    func testPickettN16ESUpperDBMajorTicks() throws {
        let definitionString = "(SH1 SH2- TH DF [ CF L S Cos ST T CI C ] D LL3 LL2 LL1 Ln : Θ₁^ Θ₂ α >DB D XL Xc [ L PF λ ω τ Cr ] Lr db CosΘ)"
        
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let rule = try RuleDefinitionParser.parse(
            definitionString,
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        guard let backTopStator = rule.backTopStator else {
            Issue.record("Back top stator not found")
            return
        }
        
        let upperDBScale = backTopStator.scales.first { scale in
            scale.definition.name == ">db" || scale.definition.name == ">DB"
        }
        
        guard let dbScale = upperDBScale else {
            Issue.record(">DB scale not found")
            return
        }
        
        // Get major ticks (every 5 dB)
        let majorTicks = dbScale.tickMarks.filter { tick in
            let value = tick.value
            let rounded = value.rounded()
            return abs(value - rounded) < 0.1 && Int(rounded) % 5 == 0
        }.sorted { $0.normalizedPosition < $1.normalizedPosition }
        
        print("\n=== MAJOR TICK POSITIONS (PARSED RULE) ===")
        for tick in majorTicks {
            print("  \(tick.value) dB -> position \(tick.normalizedPosition)")
        }
        
        // Expected positions: 20→0.0, 25→0.125, 30→0.25, ..., 60→1.0
        let expectedPositions: [(value: Double, position: Double)] = [
            (20.0, 0.0), (25.0, 0.125), (30.0, 0.25), (35.0, 0.375),
            (40.0, 0.5), (45.0, 0.625), (50.0, 0.75), (55.0, 0.875), (60.0, 1.0)
        ]
        
        #expect(majorTicks.count >= 9, "Should have at least 9 major ticks (20, 25, 30, ..., 60)")
        
        for (index, expected) in expectedPositions.enumerated() {
            if index < majorTicks.count {
                let actual = majorTicks[index]
                #expect(abs(actual.value - expected.value) < 0.1,
                       "Major tick \(index) should be at \(expected.value) dB, got \(actual.value)")
                #expect(abs(actual.normalizedPosition - expected.position) < 0.02,
                       "Major tick at \(expected.value) dB should be at position \(expected.position), got \(actual.normalizedPosition)")
            }
        }
    }
}
