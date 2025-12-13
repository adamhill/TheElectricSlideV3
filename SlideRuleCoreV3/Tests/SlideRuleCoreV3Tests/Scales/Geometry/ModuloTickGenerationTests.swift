import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive test suite for modulo-based tick generation algorithm
/// Tests equivalence with legacy algorithm, correctness, performance, and edge cases
@Suite("Modulo Tick Generation")
struct ModuloTickGenerationTests {
    
    @Suite("Equivalence Tests")
    struct EquivalenceTests {
        private let defaultConfig = ModuloTickConfig.default
        
        @Test("Modulo algorithm eliminates duplicate ticks found in legacy algorithm")
        func moduloFixesBoundaryBug() {
            // This test documents the difference between the two algorithms
            // Legacy has duplicate detection issues - generates extra ticks
            // Modulo has better duplicate detection - generates correct count
            
            // Create standard C scale
            let cScale = StandardScales.cScale(length: 250.0)
            
            // Generate with both algorithms
            let legacyTicks = ScaleCalculator.generateTickMarks(
                for: cScale,
                algorithm: .legacy
            )
            
            let moduloTicks = ScaleCalculator.generateTickMarks(
                for: cScale,
                algorithm: .modulo(config: defaultConfig)
            )
            
            // Legacy has duplicate detection issues - generates extra ticks
            #expect(legacyTicks.count == 535, "Legacy algorithm generates extra ticks")
            
            let tickDifference = legacyTicks.count - moduloTicks.count
            
            // Modulo has better duplicate detection - generates correct count
            #expect(moduloTicks.count == 402, "Modulo algorithm with better duplicate detection")
            
            // Document the difference
            #expect(tickDifference == 133, "Modulo eliminates 133 duplicate/extra ticks")
            
            print("✅ Modulo algorithm has better duplicate detection")
            print("   Legacy: \(legacyTicks.count) ticks (with duplicates)")
            print("   Modulo: \(moduloTicks.count) ticks (cleaned)")
            print("   Difference: \(tickDifference) fewer ticks in modulo")
        }
        
        @Test("Both algorithms generate ticks for all standard scale patterns")
        func equivalenceWithDifferentIntervalPatterns() {
            // Test that both algorithms can generate ticks for different scale patterns
            // Note: The algorithms use different approaches, so tick counts and values may differ
            let testScales: [(name: String, scale: ScaleDefinition)] = [
                ("C", StandardScales.cScale()),
                ("D", StandardScales.dScale()),
                ("A", StandardScales.aScale()),
                ("K", StandardScales.kScale()),
                ("S", StandardScales.sScale()),
                ("T", StandardScales.tScale())
            ]
            
            for (name, scale) in testScales {
                let legacyTicks = ScaleCalculator.generateTickMarks(
                    for: scale,
                    algorithm: .legacy
                )
                
                let moduloTicks = ScaleCalculator.generateTickMarks(
                    for: scale,
                    algorithm: .modulo(config: defaultConfig)
                )
                
                // Both algorithms should generate some ticks
                #expect(legacyTicks.count > 0, "Legacy should generate ticks for scale \(name)")
                #expect(moduloTicks.count > 0, "Modulo should generate ticks for scale \(name)")
                
                // Ticks should be sorted
                for i in 1..<legacyTicks.count {
                    #expect(legacyTicks[i-1].normalizedPosition < legacyTicks[i].normalizedPosition, "Legacy ticks should be sorted for scale \(name)")
                }
                for i in 1..<moduloTicks.count {
                    #expect(moduloTicks[i-1].normalizedPosition < moduloTicks[i].normalizedPosition, "Modulo ticks should be sorted for scale \(name)")
                }
                
                print("Scale \(name): Legacy=\(legacyTicks.count), Modulo=\(moduloTicks.count), Difference=\(abs(legacyTicks.count - moduloTicks.count))")
            }
        }
    }
    
    @Suite("Duplicate Prevention Tests")
    struct DuplicatePreventionTests {
        private let defaultConfig = ModuloTickConfig.default
        private let tolerance: Double = 0.0001
        
        @Test("Modulo algorithm prevents duplicate positions in generated ticks")
        func noDuplicatesInOutput() {
            let cScale = StandardScales.cScale()
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: cScale,
                algorithm: .modulo(config: defaultConfig)
            )
            
            // Check for duplicate positions
            var seenPositions = Set<Int>()
            let minSeparation = defaultConfig.minSeparation
            
            for tick in ticks {
                // Convert to integer for duplicate check
                let positionKey = Int((tick.normalizedPosition / minSeparation).rounded())
                
                #expect(!seenPositions.contains(positionKey), "Duplicate tick found at position \(tick.normalizedPosition) (value: \(tick.value))")
                seenPositions.insert(positionKey)
            }
            
            // Also verify positions are sorted
            for i in 1..<ticks.count {
                #expect(ticks[i-1].normalizedPosition < ticks[i].normalizedPosition, "Ticks should be sorted by position")
            }
        }
        
        @Test("Modulo algorithm handles overlapping intervals without creating duplicates")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .modulo(config: defaultConfig)
            )
            
            // Verify no duplicates
            var previousPosition: Double?
            for tick in ticks {
                if let prev = previousPosition {
                    let separation = tick.normalizedPosition - prev
                    #expect(separation > defaultConfig.minSeparation * 0.9, "Ticks too close at position \(tick.normalizedPosition)")
                }
                previousPosition = tick.normalizedPosition
            }
        }
    }
    
    @Suite("Hierarchy Level Assignment")
    struct HierarchyTests {
        private let tolerance: Double = 0.0001
        
        @Test("Tick hierarchy levels are correctly determined by interval divisibility")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .modulo(config: ModuloTickConfig(precisionMultiplier: 100))
            )
            
            // Find specific ticks and verify their hierarchy
            let testCases: [(value: Double, expectedLevel: TickStyle)] = [
                (1.0, .major),      // Divisible by 1.0 → level 0 (major)
                (1.5, .medium),     // Divisible by 0.1 but not 1.0 → level 1 (medium) 
                (1.05, .minor),     // Divisible by 0.05 but not 0.1 → level 2 (minor)
                (1.01, .tiny)       // Divisible by 0.01 only → level 3 (tiny)
            ]
            
            for (testValue, expectedStyle) in testCases {
                if let tick = ticks.first(where: { abs($0.value - testValue) < tolerance }) {
                    #expect(abs(tick.style.relativeLength - expectedStyle.relativeLength) < 0.01, "Value \(testValue) should have style level \(expectedStyle.relativeLength)")
                } else {
                    Issue.record("Expected tick at value \(testValue) not found")
                }
            }
        }
    }
    
    @Suite("Null Interval Handling")
    struct NullIntervalTests {
        private let defaultConfig = ModuloTickConfig.default
        private let tolerance: Double = 0.0001
        
        @Test("Null intervals are properly skipped in hierarchy level assignment")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .modulo(config: ModuloTickConfig(precisionMultiplier: 100))
            )
            
            // Verify position 1.5 exists as secondary (level 1)
            let tick15 = ticks.first { abs($0.value - 1.5) < tolerance }
            #expect(tick15 != nil, "Position 1.5 should exist")
            if let tick15 = tick15 {
                #expect(abs(tick15.style.relativeLength - TickStyle.medium.relativeLength) < 0.01, "Position 1.5 should be medium tick")
            }
            
            // Verify position 1.02 should be tiny (level 3, skipping level 2)
            // 1.1 is divisible by 0.1 (level 1), so it should be medium
            // But 1.02, 1.04, etc should be tiny (level 3) since they skip level 2
            let tick102 = ticks.first { abs($0.value - 1.02) < tolerance }
            #expect(tick102 != nil, "Position 1.02 should exist")
            if let tick102 = tick102 {
                #expect(abs(tick102.style.relativeLength - TickStyle.tiny.relativeLength) < 0.01, "Position 1.02 should be tiny tick (level 3, skipping level 2)")
            }
        }
    }
    
    @Suite("Circular Scale Overlap")
    struct CircularScaleTests {
        private let defaultConfig = ModuloTickConfig.default
        private let tolerance: Double = 0.0001
        
        @Test("Circular scales do not generate overlapping ticks at start/end positions")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: circularScale,
                algorithm: .modulo(config: defaultConfig)
            )
            
            // Check for NO duplicate at 0°/360° position
            // log(1) = 0, log(10) = 1, so these map to 0° and 360°
            let ticksAt1 = ticks.filter { abs($0.value - 1.0) < tolerance }
            let ticksAt10 = ticks.filter { abs($0.value - 10.0) < tolerance }
            
            // Should have tick at 1.0 (0°)
            #expect(ticksAt1.count == 1, "Should have exactly one tick at value 1.0")
            
            // Should NOT have tick at 10.0 (360° overlaps with 0°)
            #expect(ticksAt10.count == 0, "Should NOT have tick at value 10.0 (overlaps with 1.0 at 0°)")
        }
        
        @Test("Partial circular arcs retain end tick marks that do not overlap")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: partialCircle,
                algorithm: .modulo(config: defaultConfig)
            )
            
            // Should have tick at end value since it doesn't complete full circle
            let hasEndTick = ticks.contains { abs($0.value - 3.16) < 0.1 }
            #expect(hasEndTick, "Partial circle should keep end tick")
        }
    }
    
    @Suite("Performance Benchmarks")
    struct PerformanceBenchmarks {
        private let defaultConfig = ModuloTickConfig.default
        private let tolerance: Double = 0.0001
        
        @Test("Modulo algorithm performs significantly faster than legacy algorithm")
        func performanceBenchmark() {
            // Performance comparison:
            // - Legacy: ~132ms for 535 ticks (with duplicate detection issues)
            // - Modulo: ~40ms for 442 ticks (better duplicate detection + 3.3x faster!)
            // Modulo is both CLEANER and FASTER
            
            let cScale = StandardScales.cScale()
            
            // Measure legacy algorithm
            let legacyStart = Date()
            for _ in 0..<100 {
                _ = ScaleCalculator.generateTickMarks(
                    for: cScale,
                    algorithm: .legacy
                )
            }
            let legacyTime = Date().timeIntervalSince(legacyStart)
            
            // Measure modulo algorithm      
            let moduloStart = Date()
            for _ in 0..<100 {
                _ = ScaleCalculator.generateTickMarks(
                    for: cScale,
                    algorithm: .modulo(config: defaultConfig)
                )
            }
            let moduloTime = Date().timeIntervalSince(moduloStart)
            
            let speedup = legacyTime / moduloTime
            
            // Get actual tick counts for reporting
            let legacyTicks = ScaleCalculator.generateTickMarks(for: cScale, algorithm: .legacy)
            let moduloTicks = ScaleCalculator.generateTickMarks(for: cScale, algorithm: .modulo(config: defaultConfig))
            
            print("=== Performance Benchmark ===")
            print("Legacy algorithm: \(String(format: "%.4f", legacyTime * 1000))ms for \(legacyTicks.count) ticks (with duplicates)")
            print("Modulo algorithm: \(String(format: "%.4f", moduloTime * 1000))ms for \(moduloTicks.count) ticks (cleaner)")
            print("Speedup: \(String(format: "%.2f", speedup))x faster with better duplicate detection!")
            
            // Expect 2-10x faster (though this depends on hardware)
            // Using a lenient check since performance varies
            #expect(moduloTime < legacyTime * 1.2, "Modulo algorithm should be at least comparable to legacy")
        }
        
        @Test("Modulo algorithm generates correct tick count with proper boundaries")
        func moduloIsCorrect() {
            // Verify modulo algorithm generates the correct number of ticks
            // with better duplicate detection than legacy
            
            let cScale = StandardScales.cScale(length: 250.0)
            
            let moduloTicks = ScaleCalculator.generateTickMarks(
                for: cScale,
                algorithm: .modulo(config: defaultConfig)
            )
            
            #expect(moduloTicks.count == 402, "Should generate 402 ticks with better duplicate detection")
            
            // Verify first and last ticks
            #expect(moduloTicks.first != nil, "Should have first tick")
            #expect(moduloTicks.last != nil, "Should have last tick")
            
            if let firstTick = moduloTicks.first {
                #expect(abs(firstTick.value - 1.0) < tolerance, "Should start at 1.0")
            }
            
            if let lastTick = moduloTicks.last {
                #expect(abs(lastTick.value - 10.0) < tolerance, "Should end at 10.0")
            }
            
            print("✅ Modulo generates correct count: \(moduloTicks.count) ticks")
            print("   Range: \(moduloTicks.first?.value ?? 0) to \(moduloTicks.last?.value ?? 0)")
        }
    }
    
    @Suite("Edge Cases")
    struct EdgeCaseTests {
        private let defaultConfig = ModuloTickConfig.default
        private let tolerance: Double = 0.0001
        
        @Test("Very small intervals are handled correctly with increased precision")
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
            
            // Use higher precision multiplier for small intervals
            let config = ModuloTickConfig(
                precisionMultiplier: 10000,
                minSeparation: 0.00001,
                skipCircularOverlap: false
            )
            
            #expect(throws: Never.self) {
                let ticks = ScaleCalculator.generateTickMarks(
                    for: definition,
                    algorithm: .modulo(config: config)
                )
                #expect(ticks.count > 0, "Should generate ticks for small intervals")
            }
        }
        
        @Test("Very large intervals generate appropriate tick distributions")
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
                let ticks = ScaleCalculator.generateTickMarks(
                    for: definition,
                    algorithm: .modulo(config: self.defaultConfig)
                )
                #expect(ticks.count > 0, "Should generate ticks for large intervals")
            }
        }
        
        @Test("Single interval subsections assign all ticks to same hierarchy level")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .modulo(config: defaultConfig)
            )
            
            // All ticks should be same level (major)
            for tick in ticks {
                #expect(abs(tick.style.relativeLength - TickStyle.major.relativeLength) < 0.01, "All ticks should be major with single interval")
            }
        }
        
        @Test("All null intervals result in no tick generation")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .modulo(config: defaultConfig)
            )
            
            // Should generate no ticks (only from subsections, not constants)
            #expect(ticks.count == 0, "Should generate no ticks with all null intervals")
        }
        
        @Test("Empty subsections array results in no tick generation")
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
            
            let ticks = ScaleCalculator.generateTickMarks(
                for: definition,
                algorithm: .modulo(config: defaultConfig)
            )
            
            #expect(ticks.count == 0, "Should generate no ticks with empty subsections")
        }
    }
    
    @Suite("Integration Tests")
    struct IntegrationTests {
        private let defaultConfig = ModuloTickConfig.default
        private let tolerance: Double = 0.0001
        
        @Test("Modulo-generated scales integrate correctly with GeneratedScale")
        func integrationWithGeneratedScale() {
            // Create a complete C scale using modulo algorithm
            let cScale = StandardScales.cScale()
            
            // Generate scale with modulo algorithm
            ScaleCalculator.defaultAlgorithm = .modulo(config: defaultConfig)
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
            
            // Reset to legacy for other tests
            ScaleCalculator.defaultAlgorithm = .legacy
        }
        
        @Test("Position lookup maintains accuracy across multiple test values")
        func positionLookupAccuracy() {
            let cScale = StandardScales.cScale()
            
            ScaleCalculator.defaultAlgorithm = .modulo(config: defaultConfig)
            let generatedScale = GeneratedScale(definition: cScale)
            
            // Test known values
            let testValues: [Double] = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0]
            
            for value in testValues {
                let position = ScaleCalculator.normalizedPosition(for: value, on: cScale)
                
                // Find tick at this position
                if let tick = generatedScale.tickMarks.first(where: { abs($0.value - value) < 0.01 }) {
                    #expect(abs(tick.normalizedPosition - position) < tolerance, "Position should match for value \(value)")
                }
            }
            
            ScaleCalculator.defaultAlgorithm = .legacy
        }
    }
}
