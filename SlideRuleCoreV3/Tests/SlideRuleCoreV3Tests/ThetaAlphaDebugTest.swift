import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("ThetaSmall 5°-4° Tick Count Debug", .tags(.debugging))
struct ThetaSmallTickCountTests {
    
    @Test("Count ticks by relativeLength between 5° and 4°")
    func countTicksByStyle() {
        // GIVEN: ThetaSmall scale with current configuration
        let thetaSmall = PickettN16ESScales.thetaSmall(length: 250.0)
        let generated = GeneratedScale(definition: thetaSmall)
        
        // Filter ticks in the 5°-4° range
        let ticksIn5to4 = generated.tickMarks.filter { $0.value >= 4.0 && $0.value <= 5.0 }
        
        print("\n=== ThetaSmall 5°-4° Tick Analysis ===")
        print("Total ticks in range: \(ticksIn5to4.count)")
        
        // Count by relativeLength
        let tinyTicks = ticksIn5to4.filter { $0.style.relativeLength == 0.25 }
        let minorTicks = ticksIn5to4.filter { $0.style.relativeLength == 0.5 }
        let mediumTicks = ticksIn5to4.filter { $0.style.relativeLength == 0.75 }
        let majorTicks = ticksIn5to4.filter { $0.style.relativeLength >= 0.9 }
        
        print("\nBreakdown by style:")
        print("  Major (≥0.9):   \(majorTicks.count) ticks")
        print("  Medium (0.75):  \(mediumTicks.count) ticks")
        print("  Minor (0.5):    \(minorTicks.count) ticks")
        print("  Tiny (0.25):    \(tinyTicks.count) ticks")
        
        print("\nExpected visible ticks (relativeLength ≥ 0.4):")
        let visibleTicks = ticksIn5to4.filter { $0.style.relativeLength >= 0.4 }
        print("  Count: \(visibleTicks.count)")
        
        print("\nFiltered out ticks (relativeLength < 0.4):")
        let filteredTicks = ticksIn5to4.filter { $0.style.relativeLength < 0.4 }
        print("  Count: \(filteredTicks.count)")
        print("  Values: \(filteredTicks.map { String(format: "%.2f°", $0.value) }.joined(separator: ", "))")
        
        // Verify the hypothesis
        #expect(tinyTicks.count == 10, "Should have 10 tiny ticks (0.05° intervals)")
        #expect(minorTicks.count == 8, "Should have 8 minor ticks (0.1° intervals)")
        #expect(mediumTicks.count == 1, "Should have 1 medium tick (0.5° interval)")
        #expect(visibleTicks.count == 9, "Only 9 ticks visible (missing 10 tiny ticks)")
        
        print("\n✅ DIAGNOSIS: Tiny ticks (0.05° intervals) are generated but filtered by 0.4 threshold")
    }
    
    @Test("Verify tick intervals configuration")
    func verifyIntervalConfiguration() {
        let thetaSmall = PickettN16ESScales.thetaSmall(length: 250.0)
        
        // Find the 5°-4° subsection
        let subsection = thetaSmall.subsections.first { $0.startValue == 5.0 }
        
        #expect(subsection != nil, "Should have subsection starting at 5°")
        
        if let sub = subsection {
            print("\n=== Subsection Configuration ===")
            print("Start value: \(sub.startValue)°")
            print("Tick intervals: \(sub.tickIntervals)")
            print("Label levels: \(sub.labelLevels)")
            
            #expect(sub.tickIntervals.count == 4, "Should have 4 interval levels")
            #expect(sub.tickIntervals == [1.0, 0.5, 0.1, 0.05], "Intervals should be 1.0, 0.5, 0.1, 0.05")
        }
        
        print("\n=== Tick Styles Configuration ===")
        print("Default tick styles: \(thetaSmall.defaultTickStyles)")
        print("  Level 0 (1.0°):  relativeLength = \(thetaSmall.defaultTickStyles[0].relativeLength)")
        print("  Level 1 (0.5°):  relativeLength = \(thetaSmall.defaultTickStyles[1].relativeLength)")
        print("  Level 2 (0.1°):  relativeLength = \(thetaSmall.defaultTickStyles[2].relativeLength)")
        print("  Level 3 (0.05°): relativeLength = \(thetaSmall.defaultTickStyles[3].relativeLength)")
        
        #expect(thetaSmall.defaultTickStyles.count == 4, "Should have 4 tick styles")
        #expect(thetaSmall.defaultTickStyles[3].relativeLength == 0.25, "Level 3 should be .tiny (0.25)")
    }
}
