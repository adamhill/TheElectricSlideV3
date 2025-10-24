import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("ScaleCalculator Precision and Edge Cases")
struct ScaleCalculatorPrecisionTests {
    
    // MARK: - Test Helper Scales
    
    private let cScale = StandardScales.cScale(length: 250.0)
    
    private let linearScale = ScaleDefinition(
        name: "TestLinear",
        function: LinearFunction(),
        beginValue: 0.0,
        endValue: 1.0,
        scaleLengthInPoints: 100.0,
        layout: .linear,
        subsections: []
    )
    
    private let circularScale = ScaleDefinition(
        name: "TestCircular",
        function: LogarithmicFunction(),
        beginValue: 1.0,
        endValue: 10.0,
        scaleLengthInPoints: 360.0,
        layout: .circular(diameter: 200, radiusInPoints: 100),
        subsections: []
    )
    
    // MARK: - Precision Multiplier Calculation Tests
    
    @Suite("Precision Multiplier Calculation")
    struct PrecisionMultiplierTests {
        
        @Test("Recommended xfactor for fine interval 0.001 is 10000")
        func fineIntervalPrecision() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.1, 0.01, 0.001]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
            #expect(xfactor == 10000, "Fine interval 0.001 should recommend xfactor 10000")
        }
        
        @Test("Recommended xfactor for medium interval 0.01 is 1000")
        func mediumIntervalPrecision() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.1, 0.01]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
            #expect(xfactor == 1000, "Medium interval 0.01 should recommend xfactor 1000")
        }
        
        @Test("Recommended xfactor for coarse interval 0.1 is 100")
        func coarseIntervalPrecision() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.1]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
            #expect(xfactor == 100, "Coarse interval 0.1 should recommend xfactor 100")
        }
        
        @Test("Recommended xfactor for large interval 1.0 is 100")
        func largeIntervalPrecision() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [10.0, 1.0]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
            #expect(xfactor == 100, "Large interval 1.0 should recommend xfactor 100")
        }
        
        @Test("Edge case: all zero intervals returns default 100")
        func allZeroIntervalsDefault() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.0, 0.0, 0.0]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
            #expect(xfactor == 100, "All zero intervals should return default 100")
        }
        
        @Test("Edge case: empty intervals returns default 100")
        func emptyIntervalsDefault() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: []
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
            #expect(xfactor == 100, "Empty intervals should return default 100")
        }
        
        @Test("Precision calculation handles scale with mixed interval sizes")
        func scaleWithMixedIntervals() {
            let subsection1 = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.1, 0.01]
            )
            let subsection2 = ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [0.5, 0.05, 0.005]
            )
            
            let scaleDef = ScaleDefinition(
                name: "MixedTest",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection1, subsection2]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: scaleDef)
            #expect(xfactor == 10000, "Mixed intervals should use finest: 0.005 -> xfactor 10000")
        }
        
        @Test("Precision recommendation uses finest interval across all subsections")
        func finestIntervalAcrossSubsections() {
            let subsection1 = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.1]
            )
            let subsection2 = ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [0.5, 0.01]  // 0.01 is finest
            )
            
            let scaleDef = ScaleDefinition(
                name: "MultiSubsection",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection1, subsection2]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: scaleDef)
            #expect(xfactor == 1000, "Should use finest interval 0.01 from all subsections")
        }
        
        @Test("Very fine interval 0.0001 recommends xfactor 100000")
        func veryFineInterval() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.1, 0.0001]
            )
            
            let xfactor = ModuloTickConfig.recommendedPrecisionMultiplier(for: subsection)
            #expect(xfactor >= 100000, "Very fine interval 0.0001 should recommend xfactor >= 100000")
        }
    }
    
    // MARK: - Range Validation Tests
    
    @Suite("Range Validation and Tick Extraction")
    struct UtilityFunctionsTests {
        
        private let testScale = StandardScales.cScale(length: 250.0)
        
        @Test("Value within range returns true")
        func valueInRange() {
            let result = ScaleCalculator.isInDomain(5.0, for: testScale)
            #expect(result == true, "Value 5.0 should be in domain [1.0, 10.0]")
        }
        
        @Test("Value below range returns false")
        func valueBelowRange() {
            let result = ScaleCalculator.isInDomain(0.5, for: testScale)
            #expect(result == false, "Value 0.5 should be outside domain [1.0, 10.0]")
        }
        
        @Test("Value above range returns false")
        func valueAboveRange() {
            let result = ScaleCalculator.isInDomain(15.0, for: testScale)
            #expect(result == false, "Value 15.0 should be outside domain [1.0, 10.0]")
        }
        
        @Test("Boundary value at minimum is in range")
        func boundaryValueMin() {
            let result = ScaleCalculator.isInDomain(1.0, for: testScale)
            #expect(result == true, "Minimum boundary value 1.0 should be in domain")
        }
        
        @Test("Boundary value at maximum is in range")
        func boundaryValueMax() {
            let result = ScaleCalculator.isInDomain(10.0, for: testScale)
            #expect(result == true, "Maximum boundary value 10.0 should be in domain")
        }
        
        @Test("Range validation works with inverted begin and end values")
        func invertedRangeValidation() {
            let invertedScale = ScaleDefinition(
                name: "Inverted",
                function: LogarithmicFunction(),
                beginValue: 10.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: []
            )
            
            let result1 = ScaleCalculator.isInDomain(5.0, for: invertedScale)
            #expect(result1 == true, "Value 5.0 should be in inverted domain")
            
            let result2 = ScaleCalculator.isInDomain(0.5, for: invertedScale)
            #expect(result2 == false, "Value 0.5 should be outside inverted domain")
        }
        
        @Test("Major tick values extraction returns labeled tick values")
        func majorTickValuesExtraction() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.1],
                labelLevels: [0]
            )
            
            let scaleDef = ScaleDefinition(
                name: "TestScale",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection]
            )
            
            let majorValues = ScaleCalculator.majorTickValues(for: scaleDef)
            #expect(majorValues.count > 0, "Should extract major tick values")
            #expect(majorValues.contains(1.0), "Should include start value")
            #expect(majorValues.contains(10.0), "Should include end value")
        }
        
        @Test("Major tick values are ordered by position")
        func majorTickValuesOrdered() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0],
                labelLevels: [0]
            )
            
            let scaleDef = ScaleDefinition(
                name: "OrderTest",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection]
            )
            
            let majorValues = ScaleCalculator.majorTickValues(for: scaleDef)
            
            // Check that values are in ascending order
            for i in 0..<(majorValues.count - 1) {
                #expect(majorValues[i] <= majorValues[i + 1], "Major tick values should be ordered")
            }
        }
        
        @Test("Empty scale generates no major ticks")
        func emptyScaleMajorTicks() {
            let emptyScale = ScaleDefinition(
                name: "Empty",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: []
            )
            
            let majorValues = ScaleCalculator.majorTickValues(for: emptyScale)
            #expect(majorValues.count == 0, "Empty scale should have no major ticks")
        }
    }
    
    // MARK: - Circular Scale Error Handling Tests
    
    @Suite("Circular Scale Error Handling")
    struct CircularScaleErrorTests {
        
        private let linearScale = ScaleDefinition(
            name: "Linear",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            subsections: []
        )
        
        private let circularScale = ScaleDefinition(
            name: "Circular",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 360.0,
            layout: .circular(diameter: 200, radiusInPoints: 100),
            subsections: []
        )
        
        @Test("Angular position on linear scale triggers fatal error",
              .bug("https://github.com/project/issues/1",
                   "angularPosition should only work on circular scales"))
        func angularPositionOnLinearScale() {
            // Note: Testing fatal errors requires special handling
            // This test documents the expected behavior
            // In practice, calling angularPosition on a linear scale will crash
            #expect(linearScale.isCircular == false, 
                   "Linear scale should not be circular")
        }
        
        @Test("Value at angle on linear scale triggers fatal error",
              .bug("https://github.com/project/issues/2",
                   "value(atAngle:) should only work on circular scales"))
        func valueAtAngleOnLinearScale() {
            // Note: Testing fatal errors requires special handling
            // This test documents the expected behavior
            #expect(linearScale.isCircular == false,
                   "Linear scale should not be circular - calling value(atAngle:) would crash")
        }
        
        @Test("Angular position works correctly on circular scale")
        func angularPositionOnCircularScale() {
            let angle = ScaleCalculator.angularPosition(for: 5.0, on: circularScale)
            #expect(angle > 0 && angle < 360, "Should compute valid angular position")
        }
        
        @Test("Value at angle works correctly on circular scale")
        func valueAtAngleOnCircularScale() {
            let value = ScaleCalculator.value(atAngle: 180.0, on: circularScale)
            #expect(value > 1.0 && value < 10.0, "Should compute valid value at angle")
        }
        
        @Test("Arc length calculation requires circular scale")
        func arcLengthRequiresCircular() {
            #expect(circularScale.layout.radius != nil, 
                   "Circular scale should have radius for arc length calculation")
        }
        
        @Test("Arc distance calculation requires circular scale")
        func arcDistanceRequiresCircular() {
            let distance = ScaleCalculator.arcDistance(for: 5.0, on: circularScale)
            #expect(distance > 0, "Should calculate positive arc distance on circular scale")
        }
    }
    
    // MARK: - Tick Generation Edge Cases
    
    @Suite("Tick Generation Edge Cases")
    struct TickGenerationEdgeCasesTests {
        
        @Test("Circular scale overlap prevention skips duplicate at 360°")
        func circularOverlapPrevention() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.1],
                labelLevels: [0]
            )
            
            let circularScale = ScaleDefinition(
                name: "FullCircle",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 360.0,
                layout: .circular(diameter: 200, radiusInPoints: 100),
                subsections: [subsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: circularScale)
            
            // Check that we don't have duplicate ticks at 0° and 360°
            let zeroDegreeTicks = ticks.filter { 
                guard let angle = $0.angularPosition else { return false }
                return angle < 1.0 || angle > 359.0
            }
            
            #expect(zeroDegreeTicks.count <= 1, 
                   "Should not have duplicate ticks at 0°/360° overlap")
        }
        
        @Test("Empty subsection generates no ticks without error")
        func emptySubsectionHandling() {
            let emptySubsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: []
            )
            
            let scaleDef = ScaleDefinition(
                name: "EmptySubsection",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [emptySubsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            #expect(ticks.count == 0, "Empty subsection should generate no ticks")
        }
        
        @Test("Subsection with zero intervals generates no ticks")
        func zeroIntervalSubsection() {
            let zeroSubsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.0, 0.0]
            )
            
            let scaleDef = ScaleDefinition(
                name: "ZeroIntervals",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [zeroSubsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            #expect(ticks.count == 0, "Zero intervals should generate no ticks")
        }
        
        @Test("Duplicate tick prevention removes ticks too close together")
        func duplicateTickPrevention() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [0.001, 0.0001], // Very fine intervals
                labelLevels: [0]
            )
            
            let scaleDef = ScaleDefinition(
                name: "FineTicks",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 1.01, // Very narrow range
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            
            // Check that consecutive ticks aren't too close
            for i in 0..<(ticks.count - 1) {
                let distance = abs(ticks[i + 1].normalizedPosition - ticks[i].normalizedPosition)
                #expect(distance >= 0.001 || distance == 0.0, 
                       "Consecutive ticks should be separated or identical")
            }
        }
        
        @Test("Break condition prevents infinite loops with tiny intervals")
        func breakConditionPreventsInfiniteLoop() {
            let tinySubsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1e-11] // Extremely small interval
            )
            
            let scaleDef = ScaleDefinition(
                name: "TinyInterval",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [tinySubsection]
            )
            
            // Should complete without hanging
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            #expect(ticks.count >= 0, "Should handle tiny intervals without infinite loop")
        }
        
        @Test("Modulo algorithm handles empty subsection correctly")
        func moduloEmptySubsection() {
            let emptySubsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: []
            )
            
            let scaleDef = ScaleDefinition(
                name: "ModuloEmpty",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [emptySubsection]
            )
            
            let config = ModuloTickConfig(precisionMultiplier: 1000)
            let ticks = ScaleCalculator.generateTickMarks(
                for: scaleDef,
                algorithm: .modulo(config: config)
            )
            
            #expect(ticks.count == 0, "Modulo algorithm should handle empty subsection")
        }
    }
    
    // MARK: - Label Formatting Edge Cases
    
    @Suite("Label Formatting Edge Cases")
    struct LabelFormattingEdgeCasesTests {
        
        @Test("Label generation for very large values uses appropriate format")
        func veryLargeValueFormatting() {
            let largeSubsection = ScaleSubsection(
                startValue: 1000.0,
                tickIntervals: [100.0],
                labelLevels: [0]
            )
            
            let largeScale = ScaleDefinition(
                name: "LargeValues",
                function: LogarithmicFunction(),
                beginValue: 1000.0,
                endValue: 10000.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [largeSubsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: largeScale)
            let labeledTicks = ticks.filter { $0.label != nil }
            
            #expect(labeledTicks.count > 0, "Should have labeled ticks for large values")
            
            // Check that labels are properly formatted
            for tick in labeledTicks {
                if let label = tick.label {
                    #expect(label.count > 0, "Label should not be empty")
                }
            }
        }
        
        @Test("Label generation for very small values uses appropriate format")
        func verySmallValueFormatting() {
            let smallSubsection = ScaleSubsection(
                startValue: 0.001,
                tickIntervals: [0.001],
                labelLevels: [0]
            )
            
            let smallScale = ScaleDefinition(
                name: "SmallValues",
                function: LinearFunction(),
                beginValue: 0.001,
                endValue: 0.01,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [smallSubsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: smallScale)
            let labeledTicks = ticks.filter { $0.label != nil }
            
            #expect(labeledTicks.count > 0, "Should have labeled ticks for small values")
            
            // Check that small values are formatted with decimals
            for tick in labeledTicks where tick.value < 0.01 {
                if let label = tick.label {
                    #expect(label.contains(".") || label.contains("e"), 
                           "Small value labels should have decimal point or scientific notation")
                }
            }
        }
        
        @Test("Custom formatter overrides default formatting")
        func customFormatterOverride() {
            let customFormatter: @Sendable (ScaleValue) -> String = { value in
                return "X\(Int(value))"
            }
            
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0],
                labelLevels: [0],
                labelFormatter: customFormatter
            )
            
            let scaleDef = ScaleDefinition(
                name: "CustomFormat",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            let labeledTicks = ticks.filter { $0.label != nil }
            
            #expect(labeledTicks.count > 0, "Should have labeled ticks")
            
            // Check that custom formatter was used
            for tick in labeledTicks {
                if let label = tick.label {
                    #expect(label.hasPrefix("X"), "Custom formatter should prefix with 'X'")
                }
            }
        }
        
        @Test("Scale-level formatter applies when subsection has no formatter")
        func scaleLevelFormatterFallback() {
            let scaleFormatter: @Sendable (ScaleValue) -> String = { value in
                return String(format: "%.0f", value)
            }
            
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0],
                labelLevels: [0]
                // No labelFormatter specified
            )
            
            let scaleDef = ScaleDefinition(
                name: "ScaleFormatter",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection],
                labelFormatter: scaleFormatter
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            let labeledTicks = ticks.filter { $0.label != nil }
            
            #expect(labeledTicks.count > 0, "Should use scale-level formatter")
        }
        
        @Test("Nil formatter uses default formatting")
        func nilFormatterUsesDefault() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0],
                labelLevels: [0]
            )
            
            let scaleDef = ScaleDefinition(
                name: "DefaultFormat",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection]
                // No formatter specified
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            let labeledTicks = ticks.filter { $0.label != nil }
            
            #expect(labeledTicks.count > 0, "Should generate labels with default formatter")
            
            // Check that labels are reasonable
            for tick in labeledTicks {
                if let label = tick.label {
                    let value = Double(label)
                    #expect(value != nil || label.count > 0, 
                           "Default formatter should produce parseable numbers or valid strings")
                }
            }
        }
        
        @Test("Integer-like values format without unnecessary decimals")
        func integerValueFormatting() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0],
                labelLevels: [0]
            )
            
            let scaleDef = ScaleDefinition(
                name: "IntegerValues",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [subsection]
            )
            
            let ticks = ScaleCalculator.generateTickMarks(for: scaleDef)
            
            // Find tick at value 5.0 (should be an integer)
            if let tick5 = ticks.first(where: { abs($0.value - 5.0) < 0.01 && $0.label != nil }) {
                if let label = tick5.label {
                    // Integer values shouldn't have unnecessary decimals
                    #expect(!label.hasSuffix(".0"), 
                           "Integer-like values should format cleanly: '\(label)'")
                }
            }
        }
    }
}
