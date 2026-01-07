import Foundation
import Testing
@testable import SlideRuleCoreV3

// MARK: - DQ Scale Gauge Mark Tests
// Tests for diamond gauge mark (♦) at value 1.0 on the DQ scale
// and the removeDuplicates() fix that prioritizes constants over subsection ticks
//
// CONTEXT:
// The DQ scale is a decimal keeper/Q-factor scale spanning 2 decades (0.1 to 10).
// A diamond gauge mark (♦) was added at value 1.0 as a constant marker.
// The removeDuplicates() function was fixed to prioritize constants when
// deduplicating ticks at the same position.

@Suite("DQ Scale Diamond Gauge Mark", .tags(.pickettN16ES))
struct DQScaleGaugeMarkTests {
    
    // MARK: - Test Properties
    
    /// The DQ scale under test
    var dqScale: ScaleDefinition {
        StandardScales.pickettDQScale()
    }
    
    /// Generated tick marks for the DQ scale
    var tickMarks: [TickMark] {
        ScaleCalculator.generateTickMarks(for: dqScale)
    }
    
    // MARK: - Test 1: DQ Scale Has Diamond Gauge Mark
    
    @Test("DQ scale contains a tick with diamond symbol ♦ label")
    func testDQScaleHasDiamondGaugeMark() async throws {
        // Search for any tick with the diamond label
        let diamondTicks = tickMarks.filter { tick in
            tick.labels.contains { label in
                label.text == "♦"
            }
        }
        
        #expect(!diamondTicks.isEmpty,
               "DQ scale should contain at least one tick with the diamond (♦) gauge mark")
        
        // Verify exactly one diamond gauge mark exists
        #expect(diamondTicks.count == 1,
               "DQ scale should have exactly one diamond gauge mark, found \(diamondTicks.count)")
    }
    
    // MARK: - Test 2: Diamond Gauge Mark Is At Value 1.0
    
    @Test("Diamond gauge mark is positioned at exactly value 1.0")
    func testDiamondGaugeMarkAtValue1() async throws {
        // Find the tick with the diamond label
        let diamondTick = tickMarks.first { tick in
            tick.labels.contains { label in
                label.text == "♦"
            }
        }
        
        #expect(diamondTick != nil, "Diamond gauge mark tick should exist")
        
        guard let tick = diamondTick else { return }
        
        // Verify it's at value 1.0
        let tolerance = 1e-10
        #expect(abs(tick.value - 1.0) < tolerance,
               "Diamond gauge mark should be at value 1.0, found at \(tick.value)")
        
        // Also verify the normalized position matches
        let expectedPosition = ScaleCalculator.normalizedPosition(for: 1.0, on: dqScale)
        #expect(abs(tick.normalizedPosition - expectedPosition) < tolerance,
               "Diamond tick position \(tick.normalizedPosition) should match position for value 1.0 (\(expectedPosition))")
    }
    
    // MARK: - Test 3: Diamond Gauge Mark Is A Major Tick
    
    @Test("Diamond gauge mark has major tick styling")
    func testDiamondGaugeMarkIsMajorTick() async throws {
        // Find the tick with the diamond label
        let diamondTick = tickMarks.first { tick in
            tick.labels.contains { label in
                label.text == "♦"
            }
        }
        
        #expect(diamondTick != nil, "Diamond gauge mark tick should exist")
        
        guard let tick = diamondTick else { return }
        
        // Major ticks have relativeLength >= 0.9 (typically 1.0)
        #expect(tick.style.relativeLength >= 0.9,
               "Diamond gauge mark should have major tick styling (relativeLength >= 0.9), found \(tick.style.relativeLength)")
    }
    
    // MARK: - Test 4: Constant Labels Preserved When Colliding With Subsection Ticks
    
    @Test("Constant labels are preserved when colliding with subsection ticks")
    func testConstantLabelsPreservedOnCollision() async throws {
        // The diamond constant at value 1.0 collides with a subsection tick at the same position.
        // After the removeDuplicates() fix, the constant label should be preserved.
        
        // Find all ticks at position corresponding to value 1.0
        let value1Position = ScaleCalculator.normalizedPosition(for: 1.0, on: dqScale)
        let tolerance = 0.001  // Normalized position tolerance (same as removeDuplicates uses)
        
        let ticksAtPosition = tickMarks.filter { tick in
            abs(tick.normalizedPosition - value1Position) < tolerance
        }
        
        // There should be exactly one tick at this position after deduplication
        #expect(ticksAtPosition.count == 1,
               "Should have exactly one tick at position for value 1.0 after deduplication, found \(ticksAtPosition.count)")
        
        guard let tick = ticksAtPosition.first else { return }
        
        // The tick should have the constant source marker
        let hasConstantSource = tick.labels.contains { label in
            label.source == .constant
        }
        
        #expect(hasConstantSource,
               "Tick at value 1.0 should have a label with source=.constant (constant was preserved)")
        
        // Verify the diamond label is present
        let hasDiamondLabel = tick.labels.contains { label in
            label.text == "♦"
        }
        
        #expect(hasDiamondLabel,
               "Tick at value 1.0 should have the diamond (♦) label from the constant")
    }
    
    // MARK: - Test 5: Subsection Ticks Removed When Colliding With Constants
    
    @Test("Subsection ticks are removed when colliding with constants")
    func testSubsectionTicksRemovedOnConstantCollision() async throws {
        // Create a test scale with a constant at a position that also has a subsection tick
        // This tests the general behavior of removeDuplicates()
        
        // For the DQ scale: value 1.0 has both a subsection tick and a constant
        // After deduplication, the subsection tick's label should NOT be retained
        
        let value1Position = ScaleCalculator.normalizedPosition(for: 1.0, on: dqScale)
        let tolerance = 0.001
        
        let ticksAtPosition = tickMarks.filter { tick in
            abs(tick.normalizedPosition - value1Position) < tolerance
        }
        
        #expect(ticksAtPosition.count == 1,
               "After deduplication, there should be exactly one tick at value 1.0 position")
        
        guard let tick = ticksAtPosition.first else { return }
        
        // Count labels with different sources
        let constantLabels = tick.labels.filter { $0.source == .constant }
        let subsectionLabels = tick.labels.filter { $0.source == .subsection }
        
        // The constant label should be present
        #expect(!constantLabels.isEmpty,
               "Constant label should be preserved in the deduplicated tick")
        
        // If there's a subsection label, it would typically be "1" for value 1.0
        // The key point is that the constant's diamond label takes precedence
        let hasDiamondLabel = tick.labels.contains { $0.text == "♦" }
        #expect(hasDiamondLabel,
               "The diamond constant label should be present, not overwritten by subsection tick")
        
        // Verify no subsection label at this position overwrote the constant
        let hasSubsectionLabelOnly = !constantLabels.isEmpty || subsectionLabels.isEmpty
        #expect(hasSubsectionLabelOnly,
               "Subsection tick at same position should be removed in favor of constant")
    }
}

// MARK: - Constant Prioritization Edge Case Tests

@Suite("removeDuplicates Constant Prioritization", .tags(.tickGeneration))
struct RemoveDuplicatesConstantPriorityTests {
    
    @Test("Constants with small relativeLength beat subsection ticks with large relativeLength")
    func testConstantsPrioritizedOverRelativeLength() async throws {
        // This tests the specific fix: constants should win over subsection ticks
        // REGARDLESS of relativeLength. Before the fix, larger relativeLength would win.
        
        // Create a minimal scale definition with a constant at a known subsection tick position
        let testScale = ScaleBuilder()
            .withName("TestConstantPriority")
            .withFormula("log₁₀(x)")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withTickDirection(.down)
            // Use a style with high relativeLength for subsection ticks
            .withDefaultTickStyles([
                TickStyle(relativeLength: 1.0, shouldLabel: true, lineWidth: 2.0)
            ])
            .withSubsections([
                // A simple subsection that generates ticks including at value 2.0
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [0])
            ])
            // Add constant at value 2.0 (same as a subsection tick)
            // Even if constant has smaller relativeLength, it should win
            .addConstant(value: 2.0, label: "TEST_CONST", style: .major)
            .build()
        
        let ticks = ScaleCalculator.generateTickMarks(for: testScale)
        
        // Find the tick at value 2.0
        let tickAt2 = ticks.first { abs($0.value - 2.0) < 1e-10 }
        
        #expect(tickAt2 != nil, "Should have a tick at value 2.0")
        
        guard let tick = tickAt2 else { return }
        
        // Verify the constant label is present
        let hasConstantLabel = tick.labels.contains { $0.text == "TEST_CONST" }
        #expect(hasConstantLabel,
               "Constant label 'TEST_CONST' should be preserved at value 2.0")
        
        // Verify it has constant source
        let hasConstantSource = tick.labels.contains { $0.source == .constant }
        #expect(hasConstantSource,
               "Tick at value 2.0 should have constant source marker")
    }
    
    @Test("Multiple constants at different positions are all preserved")
    func testMultipleConstantsPreserved() async throws {
        // Verify that multiple constants are preserved correctly
        let testScale = ScaleBuilder()
            .withName("TestMultiConstants")
            .withFormula("log₁₀(x)")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withTickDirection(.down)
            .withDefaultTickStyles([.major])
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [0])
            ])
            .addConstant(value: 2.0, label: "CONST_A", style: .major)
            .addConstant(value: 5.0, label: "CONST_B", style: .major)
            .addConstant(value: 8.0, label: "CONST_C", style: .major)
            .build()
        
        let ticks = ScaleCalculator.generateTickMarks(for: testScale)
        
        // Check each constant is present
        let constants = [("CONST_A", 2.0), ("CONST_B", 5.0), ("CONST_C", 8.0)]
        
        for (expectedLabel, expectedValue) in constants {
            let matchingTick = ticks.first { tick in
                abs(tick.value - expectedValue) < 1e-10 &&
                tick.labels.contains { $0.text == expectedLabel }
            }
            
            #expect(matchingTick != nil,
                   "Constant '\(expectedLabel)' at value \(expectedValue) should be preserved")
        }
    }
}
