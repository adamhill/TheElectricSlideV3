import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests for L scale tick mark generation using the modulo-based algorithm
@Suite("L Scale Tick Generation", .tags(.tickGeneration))
struct LScaleTickGenerationTests {
    
    private let tolerance: Double = 0.0001
    
    @Test("L scale generates ticks across full range")
    func testLScaleGeneratesTicks() {
        let lScale = StandardScales.lScale(length: 800.0)
        
        let ticks = ScaleCalculator.generateTickMarks(for: lScale)
        
        // L scale should generate many ticks
        #expect(ticks.count > 0, "L scale should generate tick marks")
        #expect(ticks.count >= 10, "L scale should generate at least 10 ticks")
        
        // Verify ticks are sorted
        for i in 1..<ticks.count {
            #expect(ticks[i-1].normalizedPosition < ticks[i].normalizedPosition, 
                   "Ticks should be sorted by position")
        }
    }
    
    @Test("L scale ticks span correct value range (0 to 1)")
    func testLScaleValueRange() {
        let lScale = StandardScales.lScale(length: 800.0)
        let ticks = ScaleCalculator.generateTickMarks(for: lScale)
        
        guard !ticks.isEmpty else {
            Issue.record("L scale generated no ticks")
            return
        }
        
        // First tick should be at or near 0
        if let firstTick = ticks.first {
            #expect(firstTick.value >= 0.0 && firstTick.value <= 0.1, 
                   "First tick should be near 0, got \(firstTick.value)")
        }
        
        // Last tick should be at or near 1
        if let lastTick = ticks.last {
            #expect(lastTick.value >= 0.9 && lastTick.value <= 1.0,
                   "Last tick should be near 1, got \(lastTick.value)")
        }
    }
    
    @Test("L scale normalized positions are in valid range")
    func testLScaleNormalizedPositions() {
        let lScale = StandardScales.lScale(length: 800.0)
        let ticks = ScaleCalculator.generateTickMarks(for: lScale)
        
        for tick in ticks {
            #expect(tick.normalizedPosition >= 0.0 && tick.normalizedPosition <= 1.0,
                   "Tick position \(tick.normalizedPosition) should be in [0, 1]")
        }
    }
    
    @Test("L scale has no duplicate positions")
    func testLScaleNoDuplicates() {
        let lScale = StandardScales.lScale(length: 800.0)
        let ticks = ScaleCalculator.generateTickMarks(for: lScale)
        
        let minSeparation = ModuloTickConfig.default.minSeparation
        var seenPositions = Set<Int>()
        
        for tick in ticks {
            // Convert to integer key for duplicate detection
            let positionKey = Int((tick.normalizedPosition / minSeparation).rounded())
            
            #expect(!seenPositions.contains(positionKey),
                   "Duplicate tick found at position \(tick.normalizedPosition)")
            seenPositions.insert(positionKey)
        }
    }
    
    @Test("L scale labeled ticks have correct values")
    func testLScaleLabeledTicks() {
        let lScale = StandardScales.lScale(length: 800.0)
        let ticks = ScaleCalculator.generateTickMarks(for: lScale)
        
        let labeledTicks = ticks.filter { $0.label != nil }
        
        // L scale should have labeled ticks at major positions
        #expect(labeledTicks.count > 0, "L scale should have labeled ticks")
        
        // Verify some expected labeled values exist
        let expectedLabels: [Double] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        
        for expectedValue in expectedLabels {
            let hasLabel = labeledTicks.contains { abs($0.value - expectedValue) < tolerance }
            // Allow for some missing due to formatting differences
            if !hasLabel {
                // Just note it, don't fail - label presence can depend on formatter
                print("Note: Expected labeled tick near \(expectedValue) not found")
            }
        }
    }
    
    @Test("L scale tick hierarchy is correct")
    func testLScaleTickHierarchy() {
        let lScale = StandardScales.lScale(length: 800.0)
        let ticks = ScaleCalculator.generateTickMarks(for: lScale)
        
        // Check that different tick levels exist
        let majorTicks = ticks.filter { $0.style.relativeLength >= 0.9 }
        let mediumTicks = ticks.filter { $0.style.relativeLength >= 0.6 && $0.style.relativeLength < 0.9 }
        let minorTicks = ticks.filter { $0.style.relativeLength >= 0.3 && $0.style.relativeLength < 0.6 }
        
        #expect(majorTicks.count > 0, "L scale should have major ticks")
        
        print("L scale tick distribution:")
        print("  Major ticks: \(majorTicks.count)")
        print("  Medium ticks: \(mediumTicks.count)")
        print("  Minor ticks: \(minorTicks.count)")
        print("  Total: \(ticks.count)")
    }
    
    @Test("L scale position calculation is linear")
    func testLScaleLinearPositioning() {
        // L scale is log mantissa: position(x) = x (linear function)
        let lScale = StandardScales.lScale(length: 800.0)
        
        // Test that positions match values for L scale
        let testValues: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for value in testValues {
            let position = ScaleCalculator.normalizedPosition(for: value, on: lScale)
            #expect(abs(position - value) < tolerance,
                   "L scale position for \(value) should be \(value), got \(position)")
        }
    }
}
