import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive test suite for modulo-based tick generation algorithm
/// Tests correctness, edge cases, and integration scenarios
@Suite("Modulo Tick Generation", .tags(.tickGeneration))
struct ModuloTickGenerationTests {
    
    @Suite("Tick Quality Tests")
    struct TickQualityTests {
        private let tolerance: Double = 0.0001
        
        @Test("Standard scales generate appropriate tick counts")
        func standardScalesGenerateTicks() {
            let testScales: [(name: String, scale: ScaleDefinition)] = [
                ("C", StandardScales.cScale()),
                ("D", StandardScales.dScale()),
                ("A", StandardScales.aScale()),
                ("K", StandardScales.kScale()),
                ("S", StandardScales.sScale()),
                ("T", StandardScales.tScale()),
                ("L", StandardScales.lScale())
            ]
            
            for (name, scale) in testScales {
                let ticks = ScaleCalculator.generateTickMarks(for: scale)
                
                // All scales should generate ticks
                #expect(ticks.count > 0, "Scale \(name) should generate ticks")
                
                // Ticks should be sorted
                for i in 1..<ticks.count {
                    #expect(ticks[i-1].normalizedPosition < ticks[i].normalizedPosition,
                           "Ticks should be sorted for scale \(name)")
                }
                
                print("Scale \(name): \(ticks.count) ticks")
            }
        }
        
        @Test("Tick positions are within valid normalized range")
        func tickPositionsInValidRange() {
            let scales = [
                StandardScales.cScale(),
                StandardScales.dScale(),
                StandardScales.aScale()
            ]
            
            for scale in scales {
                let ticks = ScaleCalculator.generateTickMarks(for: scale)
                
                for tick in ticks {
                    #expect(tick.normalizedPosition >= 0.0 && tick.normalizedPosition <= 1.0,
                           "Tick position \(tick.normalizedPosition) out of range for scale \(scale.name)")
                }
            }
        }
    }
    
    @Suite("Duplicate Prevention Tests")
    struct DuplicatePreventionTests {
        private let defaultConfig = ModuloTickConfig.default
        
        @Test("No duplicate positions in generated ticks")
        func noDuplicatesInOutput() {
            let cScale = StandardScales.cScale()
            let ticks = ScaleCalculator.generateTickMarks(for: cScale)
            
            // Check for duplicate positions
            var seenPositions = Set<Int>()
            let minSeparation = defaultConfig.minSeparation
            
            for tick in ticks {
                // Convert to integer for duplicate check
                let positionKey = Int((tick.normalizedPosition / minSeparation).rounded())
                
                #expect(!seenPositions.contains(positionKey),
                       "Duplicate tick found at position \(tick.normalizedPosition) (value: \(tick.value))")
                seenPositions.insert(positionKey)
            }
            
            // Also verify positions are sorted
            for i in 1..<ticks.count {
                #expect(ticks[i-1].normalizedPosition < ticks[i].normalizedPosition,
                       "Ticks should be sorted by position")
            }
        }
        
        @Test("Overlapping intervals handled without duplicates")
        func noDuplicatesWithOverlappingIntervals() {
            // Test with intervals that could create overlaps: [1, 0.5, 0.1, 0.01]
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1, 0.01],
                labelLevels: [0]
            )
            
            let definition = ScaleDefinition(
                name: "Test",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 3.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [subsection],
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: definition)
            
            // Verify no duplicates
            var previousPosition: Double?
            for tick in ticks {
                if let prev = previousPosition {
                    let separation = tick.normalizedPosition - prev
                    #expect(separation > defaultConfig.minSeparation * 0.9,
                           "Ticks too close at position \(tick.normalizedPosition)")
                }
                previousPosition = tick.normalizedPosition
            }
        }
    }
    
    @Suite("Hierarchy Level Assignment")
    struct HierarchyTests {
        private let tolerance: Double = 0.0001
        
        @Test("Tick hierarchy levels determined by interval divisibility")
        func correctHierarchyDetermination() {
            // Create scale with intervals [1, 0.1, 0.05, 0.01]
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.1, 0.05, 0.01],
                labelLevels: [0]
            )
            
            let definition = ScaleDefinition(
                name: "Test",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 2.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [subsection],
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: definition)
            
            // Find specific ticks and verify their hierarchy
            let testCases: [(value: Double, expectedLevel: TickStyle)] = [
                (1.0, .major),      // Divisible by 1.0 → level 0 (major)
                (1.5, .medium),     // Divisible by 0.1 but not 1.0 → level 1 (medium) 
                (1.05, .minor),     // Divisible by 0.05 but not 0.1 → level 2 (minor)
                (1.01, .tiny)       // Divisible by 0.01 only → level 3 (tiny)
            ]
            
            for (testValue, expectedStyle) in testCases {
                if let tick = ticks.first(where: { abs($0.value - testValue) < tolerance }) {
                    #expect(abs(tick.style.relativeLength - expectedStyle.relativeLength) < 0.01,
                           "Value \(testValue) should have style level \(expectedStyle.relativeLength)")
                } else {
                    Issue.record("Expected tick at value \(testValue) not found")
                }
            }
        }
    }
    
    @Suite("Null Interval Handling")
    struct NullIntervalTests {
        private let tolerance: Double = 0.0001
        
        @Test("Null intervals (0.0) are skipped in hierarchy")
        func nullIntervalHandling() {
            // Test intervals [1, .5, 0, .02] - skip tertiary level
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.0, 0.02],  // 0.0 is null
                labelLevels: [0]
            )
            
            let definition = ScaleDefinition(
                name: "Test",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 2.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [subsection],
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: definition)
            
            // Verify position 1.5 exists as secondary (level 1)
            let tick15 = ticks.first { abs($0.value - 1.5) < tolerance }
            #expect(tick15 != nil, "Position 1.5 should exist")
            if let tick15 = tick15 {
                #expect(abs(tick15.style.relativeLength - TickStyle.medium.relativeLength) < 0.01,
                       "Position 1.5 should be medium tick")
            }
            
            // Verify position 1.02 should be tiny (level 3, skipping level 2)
            let tick102 = ticks.first { abs($0.value - 1.02) < tolerance }
            #expect(tick102 != nil, "Position 1.02 should exist")
            if let tick102 = tick102 {
                #expect(abs(tick102.style.relativeLength - TickStyle.tiny.relativeLength) < 0.01,
                       "Position 1.02 should be tiny tick (level 3, skipping level 2)")
            }
        }
    }
    
    @Suite("Circular Scale Overlap")
    struct CircularScaleTests {
        private let tolerance: Double = 0.0001
        
        @Test("Full circular scales avoid duplicate at 0°/360°")
        func circularScaleNoOverlap() {
            // Create circular C scale (1-10, full circle)
            let circularScale = ScaleDefinition(
                name: "C-Circular",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .circular(diameter: 400.0, radiusInPoints: 100.0),
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.01],
                        labelLevels: [0]
                    )
                ],
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: circularScale)
            
            // Check for NO duplicate at 0°/360° position
            // log(1) = 0, log(10) = 1, so these map to 0° and 360°
            let ticksAt1 = ticks.filter { abs($0.value - 1.0) < tolerance }
            let ticksAt10 = ticks.filter { abs($0.value - 10.0) < tolerance }
            
            // Should have tick at 1.0 (0°)
            #expect(ticksAt1.count == 1, "Should have exactly one tick at value 1.0")
            
            // Should NOT have tick at 10.0 (360° overlaps with 0°)
            #expect(ticksAt10.count == 0, "Should NOT have tick at value 10.0 (overlaps with 1.0 at 0°)")
        }
        
        @Test("Partial circular arcs retain end ticks")
        func partialCircleKeepsEndTick() {
            // Create partial circle (90° arc) - should keep end tick
            let partialCircle = ScaleDefinition(
                name: "Partial",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 3.16,  // sqrt(10), covers 1/4 circle
                scaleLengthInPoints: 250.0,
                layout: .circular(diameter: 400.0, radiusInPoints: 100.0),
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.01],
                        labelLevels: [0]
                    )
                ],
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: partialCircle)
            
            // Should have tick at end value since it doesn't complete full circle
            let hasEndTick = ticks.contains { abs($0.value - 3.16) < 0.1 }
            #expect(hasEndTick, "Partial circle should keep end tick")
        }
    }
    
    @Suite("Edge Cases")
    struct EdgeCaseTests {
        
        @Test("Very small intervals handled with precision")
        func verySmallIntervals() {
            let subsection = ScaleSubsection(
                startValue: 0.001,
                tickIntervals: [0.001, 0.0005, 0.0001],
                labelLevels: [0]
            )
            
            let definition = ScaleDefinition(
                name: "SmallInterval",
                function: LinearFunction(),
                beginValue: 0.001,
                endValue: 0.01,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [subsection],
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            #expect(throws: Never.self) {
                let ticks = ScaleCalculator.generateTickMarks(for: definition)
                #expect(ticks.count > 0, "Should generate ticks for small intervals")
            }
        }
        
        @Test("Very large intervals generate ticks")
        func veryLargeIntervals() {
            let subsection = ScaleSubsection(
                startValue: 1000,
                tickIntervals: [1000, 500, 100],
                labelLevels: [0]
            )
            
            let definition = ScaleDefinition(
                name: "LargeInterval",
                function: LinearFunction(),
                beginValue: 1000,
                endValue: 10000,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [subsection],
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            #expect(throws: Never.self) {
                let ticks = ScaleCalculator.generateTickMarks(for: definition)
                #expect(ticks.count > 0, "Should generate ticks for large intervals")
            }
        }
        
        @Test("Single interval subsection works correctly")
        func singleIntervalSubsection() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.1],  // Only one level
                labelLevels: [0]
            )
            
            let definition = ScaleDefinition(
                name: "Single",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 2.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [subsection],
                defaultTickStyles: [.major],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: definition)
            
            // All ticks should be same level (major)
            for tick in ticks {
                #expect(abs(tick.style.relativeLength - TickStyle.major.relativeLength) < 0.01,
                       "All ticks should be major with single interval")
            }
        }
        
        @Test("All null intervals produce no ticks")
        func allNullIntervals() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.0, 0.0, 0.0],  // All null
                labelLevels: []
            )
            
            let definition = ScaleDefinition(
                name: "AllNull",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 2.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [subsection],
                defaultTickStyles: [.major, .medium, .minor],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: definition)
            
            // Should generate no ticks (only from subsections, not constants)
            #expect(ticks.count == 0, "Should generate no ticks with all null intervals")
        }
        
        @Test("Empty subsections array results in no ticks")
        func emptySubsectionsArray() {
            let definition = ScaleDefinition(
                name: "Empty",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [],  // Empty
                defaultTickStyles: [.major, .medium, .minor, .tiny],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: definition)
            
            #expect(ticks.count == 0, "Should generate no ticks with empty subsections")
        }
    }
    
    @Suite("Precision Tests")
    struct PrecisionTests {
        private let tolerance: Double = 0.0001
        
        @Test("Integer arithmetic precision is maintained")
        func integerArithmeticPrecision() {
            // Verify the xfactor conversion preserves precision
            let testValues: [Double] = [0.01, 0.02, 0.05, 0.1, 0.25, 0.5, 1.0]
            let xfactor = 1000
            
            for value in testValues {
                let intValue = Int((value * Double(xfactor)).rounded())
                let recovered = Double(intValue) / Double(xfactor)
                
                #expect(abs(recovered - value) < 1e-10,
                       "Value \(value) should round-trip through integer conversion")
            }
        }
        
        @Test("Modulo operations produce correct divisibility")
        func moduloDivisibilityCorrect() {
            // Test that modulo correctly identifies divisibility
            let xfactor = 100
            
            // 0.5 should be divisible by 0.1 but not 1.0
            let pos50 = Int((0.5 * Double(xfactor)).rounded())  // 50
            let int100 = Int((1.0 * Double(xfactor)).rounded()) // 100
            let int10 = Int((0.1 * Double(xfactor)).rounded())  // 10
            
            #expect(pos50 % int100 != 0, "0.5 should NOT be divisible by 1.0")
            #expect(pos50 % int10 == 0, "0.5 SHOULD be divisible by 0.1")
        }
        
        @Test("Recommended precision multiplier is adequate")
        func recommendedPrecisionAdequate() {
            // Test that recommended precision handles various interval sizes
            let testCases: [(interval: Double, expectedMin: Int)] = [
                (1.0, 100),      // Integer needs at least 100
                (0.1, 100),      // One decimal needs at least 100
                (0.01, 1000),    // Two decimals needs at least 1000
                (0.001, 10000),  // Three decimals needs at least 10000
            ]
            
            for (interval, expectedMin) in testCases {
                let subsection = ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [interval],
                    labelLevels: []
                )
                
                let recommended = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
                
                #expect(recommended >= expectedMin,
                       "Precision for interval \(interval) should be >= \(expectedMin), got \(recommended)")
            }
        }
    }
    
    @Suite("Multi-Subsection Tests")
    struct MultiSubsectionTests {
        
        @Test("Multiple subsections generate continuous ticks")
        func multipleSubsectionsContinuous() {
            // Create scale with two subsections
            let subsections = [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 5.0,
                    tickIntervals: [1.0, 0.2],  // Different intervals
                    labelLevels: [0]
                )
            ]
            
            let definition = ScaleDefinition(
                name: "MultiSub",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: subsections,
                defaultTickStyles: [.major, .medium, .minor],
                labelFormatter: nil,
                labelColor: nil,
                constants: []
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: definition)
            
            // Should have ticks from both subsections
            #expect(ticks.count > 0, "Should generate ticks from multiple subsections")
            
            // Verify ticks span the full range
            if let first = ticks.first, let last = ticks.last {
                #expect(first.value >= 1.0 && first.value <= 1.5,
                       "First tick should be near start")
                #expect(last.value >= 9.5 && last.value <= 10.0,
                       "Last tick should be near end")
            }
            
            // Verify no duplicates at boundary (5.0)
            let ticksAt5 = ticks.filter { abs($0.value - 5.0) < 0.001 }
            #expect(ticksAt5.count <= 1, "Should not have duplicate ticks at subsection boundary")
        }
    }
    
    @Suite("Integration Tests")
    struct IntegrationTests {
        private let tolerance: Double = 0.0001
        
        @Test("GeneratedScale integration works correctly")
        func integrationWithGeneratedScale() {
            // Create a complete C scale
            let cScale = StandardScales.cScale()
            
            // Generate scale
            let generatedScale = GeneratedScale(definition: cScale)
            
            // Verify it can be used in GeneratedScale
            #expect(generatedScale.definition.name == "C")
            #expect(generatedScale.tickMarks.count > 0, "Generated scale should have tick marks")
            
            // Test position lookups work correctly
            let position5 = ScaleCalculator.normalizedPosition(for: 5.0, on: cScale)
            #expect(position5 > 0.0)
            #expect(position5 < 1.0)
            
            // Test nearestTick function works
            let nearestTo5 = generatedScale.nearestTick(to: position5)
            #expect(nearestTo5 != nil, "Should find nearest tick")
            if let nearest = nearestTo5 {
                #expect(abs(nearest.value - 5.0) <= 0.5, "Nearest tick should be close to 5.0")
            }
            
            // Test ticks in range
            let ticksInRange = generatedScale.ticks(in: 0.3...0.7)
            #expect(ticksInRange.count > 0, "Should find ticks in middle range")
            
            // Verify all ticks in range are actually in range
            for tick in ticksInRange {
                #expect(tick.normalizedPosition >= 0.3)
                #expect(tick.normalizedPosition <= 0.7)
            }
        }
        
        @Test("Position lookup accuracy for known values")
        func positionLookupAccuracy() {
            let cScale = StandardScales.cScale()
            let generatedScale = GeneratedScale(definition: cScale)
            
            // Test known values
            let testValues: [Double] = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0]
            
            for value in testValues {
                let position = ScaleCalculator.normalizedPosition(for: value, on: cScale)
                
                // Find tick at this position
                if let tick = generatedScale.tickMarks.first(where: { abs($0.value - value) < 0.01 }) {
                    #expect(abs(tick.normalizedPosition - position) < tolerance,
                           "Position should match for value \(value)")
                }
            }
        }
    }
    
    @Suite("Scale Family Tests")
    struct ScaleFamilyTests {
        
        @Test("All standard scale families generate valid output",
              arguments: [
                ("C", StandardScales.cScale()),
                ("D", StandardScales.dScale()),
                ("A", StandardScales.aScale()),
                ("B", StandardScales.bScale()),
                ("K", StandardScales.kScale()),
                ("L", StandardScales.lScale()),
                ("S", StandardScales.sScale()),
                ("T", StandardScales.tScale())
              ])
        func scaleFamilyGeneratesValidOutput(name: String, scale: ScaleDefinition) {
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            
            // Every scale should produce ticks
            #expect(ticks.count > 0, "Scale \(name) should generate ticks")
            
            // No duplicate positions
            var positions = Set<Int>()
            for tick in ticks {
                let key = Int((tick.normalizedPosition * 10000).rounded())
                #expect(!positions.contains(key),
                       "Scale \(name) has duplicate at position \(tick.normalizedPosition)")
                positions.insert(key)
            }
            
            // All positions in valid range
            for tick in ticks {
                #expect(tick.normalizedPosition >= 0.0 && tick.normalizedPosition <= 1.0,
                       "Scale \(name) tick out of range: \(tick.normalizedPosition)")
            }
        }
    }
}
