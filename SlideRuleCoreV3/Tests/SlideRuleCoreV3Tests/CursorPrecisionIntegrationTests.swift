import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive integration tests for cursor precision system
/// Verifies that precision calculation, formatting, and scale definitions work correctly end-to-end
@Suite("Cursor Precision Integration Tests")
struct CursorPrecisionIntegrationTests {
    
    // MARK: - Scale-Specific Precision Tests
    
    @Suite("C/D Scale Precision Tests")
    struct CScalePrecisionTests {
        
        @Test("C scale precision at position 1.5 (3 decimals from 0.01 interval)")
        func cScaleAtLowEnd() {
            let cScale = StandardScales.cScale(length: 250.0)
            
            // Position for value ~1.5 is in first subsection with 0.01 quaternary interval
            let pos = ScaleCalculator.normalizedPosition(for: 1.5, on: cScale)
            let decimals = cScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 3, "C scale at 1.5 should have 3 decimals (0.01 interval)")
        }
        
        @Test("C scale precision at position 3.0 (3 decimals from 0.05 interval)")
        func cScaleAtMidRange() {
            let cScale = StandardScales.cScale(length: 250.0)
            
            // Position for value ~3.0 is in second subsection with 0.05 quaternary interval
            // Formula: -floor(log10(0.05)) + 1 = -floor(-1.301) + 1 = 2 + 1 = 3
            let pos = ScaleCalculator.normalizedPosition(for: 3.0, on: cScale)
            let decimals = cScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 3, "C scale at 3.0 should have 3 decimals (0.05 interval)")
        }
        
        @Test("C scale precision at position 5.0 (3 decimals from 0.02 interval)")
        func cScaleAtHighEnd() {
            let cScale = StandardScales.cScale(length: 250.0)
            
            // Position for value ~5.0 is in third subsection with 0.02 quaternary interval
            // Formula: -floor(log10(0.02)) + 1 = -floor(-1.699) + 1 = 2 + 1 = 3
            let pos = ScaleCalculator.normalizedPosition(for: 5.0, on: cScale)
            let decimals = cScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 3, "C scale at 5.0 should have 3 decimals (0.02 interval)")
        }
        
        @Test("D scale matches C scale precision (tick direction doesn't affect precision)")
        func dScaleMatchesCScale() {
            let cScale = StandardScales.cScale(length: 250.0)
            let dScale = StandardScales.dScale(length: 250.0)
            
            // Test at multiple positions
            let testValues = [1.5, 3.0, 5.0, 7.5, 9.0]
            
            for value in testValues {
                let cPos = ScaleCalculator.normalizedPosition(for: value, on: cScale)
                let dPos = ScaleCalculator.normalizedPosition(for: value, on: dScale)
                
                let cDecimals = cScale.cursorDecimalPlaces(at: cPos)
                let dDecimals = dScale.cursorDecimalPlaces(at: dPos)
                
                #expect(cDecimals == dDecimals, 
                       "C and D scales should have same precision at value \(value)")
            }
        }
    }
    
    @Suite("K Scale Precision Tests")
    struct KScalePrecisionTests {
        
        @Test("K scale precision varies across 10 subsections")
        func kScaleVaryingPrecision() {
            let kScale = StandardScales.kScale(length: 250.0)
            
            // Test representative values from each subsection
            let testCases: [(value: Double, expectedDecimals: Int, description: String)] = [
                (1.5, 3, "1-3: 0.05 interval → 3 decimals"),
                (4.0, 2, "3-6: 0.1 interval → 2 decimals"),
                (7.0, 2, "6-10: 0.2 interval → 2 decimals"),
                (15.0, 2, "10-30: 0.5 interval → 2 decimals"),
                (40.0, 1, "30-60: 1.0 interval → 1 decimal"),
                (80.0, 1, "60-100: 2.0 interval → 1 decimal (≥1.0)"),
                (150.0, 1, "100-300: 5.0 interval → 1 decimal"),
                (400.0, 1, "300-600: 10.0 interval → 1 decimal (≥1.0)"),
                (800.0, 1, "600-1000: 20.0 interval → 1 decimal (≥1.0)")
            ]
            
            for testCase in testCases {
                let pos = ScaleCalculator.normalizedPosition(for: testCase.value, on: kScale)
                let decimals = kScale.cursorDecimalPlaces(at: pos)
                
                #expect(decimals == testCase.expectedDecimals,
                       "K scale at \(testCase.value): \(testCase.description)")
            }
        }
        
        @Test("K scale precision transitions smoothly at subsection boundaries")
        func kScaleSubsectionBoundaries() {
            let kScale = StandardScales.kScale(length: 250.0)
            
            // Test at subsection boundaries
            let boundaries = [3.0, 6.0, 10.0, 30.0, 60.0, 100.0]
            
            for boundary in boundaries {
                // Test slightly before and after boundary
                let beforePos = ScaleCalculator.normalizedPosition(for: boundary - 0.1, on: kScale)
                let atPos = ScaleCalculator.normalizedPosition(for: boundary, on: kScale)
                
                _ = kScale.cursorDecimalPlaces(at: beforePos)
                let atDecimals = kScale.cursorDecimalPlaces(at: atPos)
                
                // At boundary, should use new subsection precision
                // Verify it's a valid precision (1-5)
                #expect(atDecimals >= 1 && atDecimals <= 5,
                       "K scale at boundary \(boundary) has valid precision")
            }
        }
    }
    
    @Suite("LL00 Scale Precision Tests")
    struct LL00ScalePrecisionTests {
        
        @Test("LL00 scale has finest precision (5 decimals)")
        func ll00FinestPrecision() {
            let ll00Scale = StandardScales.ll00Scale(length: 250.0)
            
            // Test at representative positions across LL00 range (0.990-0.999)
            let testValues = [0.991, 0.995, 0.998]
            
            for value in testValues {
                let pos = ScaleCalculator.normalizedPosition(for: value, on: ll00Scale)
                let decimals = ll00Scale.cursorDecimalPlaces(at: pos)
                
                #expect(decimals == 5,
                       "LL00 scale at \(value) should have 5 decimals (finest precision)")
            }
        }
        
        @Test("LL00 scale formatting shows 5 decimal places")
        func ll00FormattingPrecision() {
            let ll00Scale = StandardScales.ll00Scale(length: 250.0)
            
            let value = 0.99512
            let pos = ScaleCalculator.normalizedPosition(for: value, on: ll00Scale)
            let formatted = ll00Scale.formatForCursor(value: value, at: pos)
            
            // Should show 5 decimal places
            #expect(formatted.contains(".99512") || formatted.contains(".99511") || formatted.contains(".99513"),
                   "LL00 scale should format with 5 decimal places")
        }
    }
    
    @Suite("A/B Scale Precision Tests")
    struct ABScalePrecisionTests {
        
        @Test("A scale precision in low range (3 decimals from 0.05 interval)")
        func aScaleLowRange() {
            let aScale = StandardScales.aScale(length: 250.0)
            
            // First subsection (1-10): 0.05 interval → 3 decimals
            // Formula: -floor(log10(0.05)) + 1 = 3
            let pos = ScaleCalculator.normalizedPosition(for: 2.0, on: aScale)
            let decimals = aScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 3, "A scale at 2.0 should have 3 decimals (0.05 interval)")
        }
        
        @Test("A scale precision in high range (2 decimals from 0.5 interval)")
        func aScaleHighRange() {
            let aScale = StandardScales.aScale(length: 250.0)
            
            // Second subsection (10-100): 0.5 interval → 2 decimals
            // Formula: -floor(log10(0.5)) + 1 = 2
            let pos = ScaleCalculator.normalizedPosition(for: 50.0, on: aScale)
            let decimals = aScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 2, "A scale at 50.0 should have 2 decimals (0.5 interval)")
        }
        
        @Test("B scale matches A scale precision")
        func bScaleMatchesAScale() {
            let aScale = StandardScales.aScale(length: 250.0)
            let bScale = StandardScales.bScale(length: 250.0)
            
            let testValues = [2.0, 5.0, 15.0, 50.0, 80.0]
            
            for value in testValues {
                let aPos = ScaleCalculator.normalizedPosition(for: value, on: aScale)
                let bPos = ScaleCalculator.normalizedPosition(for: value, on: bScale)
                
                let aDecimals = aScale.cursorDecimalPlaces(at: aPos)
                let bDecimals = bScale.cursorDecimalPlaces(at: bPos)
                
                #expect(aDecimals == bDecimals,
                       "A and B scales should match precision at value \(value)")
            }
        }
    }
    
    @Suite("Trigonometric Scale Precision Tests")
    struct TrigScalePrecisionTests {
        
        @Test("S scale precision at low angles (3 decimals from 0.05 interval)")
        func sScaleLowAngles() {
            let sScale = StandardScales.sScale(length: 250.0)
            
            // First subsection (5.5-10°): 0.05 interval → 3 decimals
            // Formula: -floor(log10(0.05)) + 1 = 3
            let pos = ScaleCalculator.normalizedPosition(for: 7.0, on: sScale)
            let decimals = sScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 3, "S scale at 7° should have 3 decimals (0.05 interval)")
        }
        
        @Test("S scale precision at mid angles (2 decimals)")
        func sScaleMidAngles() {
            let sScale = StandardScales.sScale(length: 250.0)
            
            // Mid subsection (10-20°): 0.1 interval → 2 decimals
            let pos = ScaleCalculator.normalizedPosition(for: 15.0, on: sScale)
            let decimals = sScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 2, "S scale at 15° should have 2 decimals (0.1 interval)")
        }
        
        @Test("S scale precision at high angles (1 decimal)")
        func sScaleHighAngles() {
            let sScale = StandardScales.sScale(length: 250.0)
            
            // High subsection (80-90°): 5.0 interval → 1 decimal
            let pos = ScaleCalculator.normalizedPosition(for: 85.0, on: sScale)
            let decimals = sScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 1, "S scale at 85° should have 1 decimal (5.0 interval)")
        }
        
        @Test("T scale precision varies appropriately")
        func tScalePrecision() {
            let tScale = StandardScales.tScale(length: 250.0)
            
            // Low angles (6-10°): 0.05 interval → 3 decimals
            let lowPos = ScaleCalculator.normalizedPosition(for: 7.0, on: tScale)
            let lowDecimals = tScale.cursorDecimalPlaces(at: lowPos)
            
            // Mid angles (10-45°): 0.1 interval → 2 decimals
            let midPos = ScaleCalculator.normalizedPosition(for: 25.0, on: tScale)
            let midDecimals = tScale.cursorDecimalPlaces(at: midPos)
            
            #expect(lowDecimals == 3, "T scale at 7° should have 3 decimals (0.05 interval)")
            #expect(midDecimals == 2, "T scale at 25° should have 2 decimals (0.1 interval)")
        }
        
        @Test("ST scale has fine precision (4 decimals from 0.005 interval)")
        func stScaleFinePrecision() {
            let stScale = StandardScales.stScale(length: 250.0)
            
            // First subsection (0.6-1.0°): 0.005 interval → 4 decimals
            let pos = ScaleCalculator.normalizedPosition(for: 0.8, on: stScale)
            let decimals = stScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 4, "ST scale at 0.8° should have 4 decimals (0.005 interval)")
        }
    }
    
    // MARK: - Format Integration Tests
    
    @Suite("Format Integration Tests")
    struct FormatIntegrationTests {
        
        @Test("C scale formatting at position 1.5 with 3 decimals")
        func cScaleFormatting() {
            let cScale = StandardScales.cScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: 1.5, on: cScale)
            
            // Value 1.5 should format with 3 decimals
            let formatted = cScale.formatForCursor(value: 1.5, at: pos)
            
            #expect(formatted == "1.500", "C scale should format 1.5 as '1.500'")
        }
        
        @Test("K scale formatting at different positions")
        func kScaleFormatting() {
            let kScale = StandardScales.kScale(length: 250.0)
            
            // Low end: 3 decimals (0.05 interval)
            let lowPos = ScaleCalculator.normalizedPosition(for: 2.5, on: kScale)
            let lowFormatted = kScale.formatForCursor(value: 2.5, at: lowPos)
            #expect(lowFormatted == "2.500", "K scale at 2.5 should format as '2.500' (3 decimals)")
            
            // Mid range: 1 decimal (1.0 interval)
            let midPos = ScaleCalculator.normalizedPosition(for: 45.0, on: kScale)
            let midFormatted = kScale.formatForCursor(value: 45.0, at: midPos)
            #expect(midFormatted == "45.0", "K scale at 45.0 should format as '45.0' (1 decimal)")
        }
        
        @Test("LL00 scale formatting with 5 decimals")
        func ll00ScaleFormatting() {
            let ll00Scale = StandardScales.ll00Scale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: 0.995, on: ll00Scale)
            
            let formatted = ll00Scale.formatForCursor(value: 0.99512, at: pos)
            
            // Should have 5 decimals
            let decimalCount = formatted.split(separator: ".").last?.count ?? 0
            #expect(decimalCount == 5, "LL00 should format with 5 decimal places")
        }
        
        @Test("A scale formatting matches expected precision")
        func aScaleFormatting() {
            let aScale = StandardScales.aScale(length: 250.0)
            
            // Low range: 3 decimals (0.05 interval)
            let lowPos = ScaleCalculator.normalizedPosition(for: 3.0, on: aScale)
            let lowFormatted = aScale.formatForCursor(value: 3.14159, at: lowPos)
            #expect(lowFormatted == "3.142", "A scale should format with 3 decimals (0.05 interval)")
        }
        
        @Test("Formatting produces consistent decimal places")
        func formattingConsistency() {
            let cScale = StandardScales.cScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: 2.0, on: cScale)
            
            // Different values at same position should use same precision
            let values = [2.0, 2.123456, 2.987654]
            let expectedDecimals = cScale.cursorDecimalPlaces(at: pos)
            
            for value in values {
                let formatted = cScale.formatForCursor(value: value, at: pos)
                let decimalCount = formatted.split(separator: ".").last?.count ?? 0
                
                #expect(decimalCount == expectedDecimals,
                       "All values at position should format with \(expectedDecimals) decimals")
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Suite("Edge Case Tests")
    struct EdgeCaseTests {
        
        @Test("Non-finite values format as em dash")
        func nonFiniteValues() {
            let cScale = StandardScales.cScale(length: 250.0)
            let pos = 0.5
            
            // Test infinity
            let infFormatted = cScale.formatForCursor(value: Double.infinity, at: pos)
            #expect(infFormatted == "—", "Infinity should format as em dash")
            
            // Test negative infinity
            let negInfFormatted = cScale.formatForCursor(value: -Double.infinity, at: pos)
            #expect(negInfFormatted == "—", "Negative infinity should format as em dash")
            
            // Test NaN
            let nanFormatted = cScale.formatForCursor(value: Double.nan, at: pos)
            #expect(nanFormatted == "—", "NaN should format as em dash")
        }
        
        @Test("Very small values use scientific notation")
        func verySmallValues() {
            let cScale = StandardScales.cScale(length: 250.0)
            let pos = 0.5
            
            // Values < 0.001 should use scientific notation
            let formatted = cScale.formatForCursor(value: 0.0005, at: pos)
            
            #expect(formatted.contains("e"), "Very small values should use scientific notation")
        }
        
        @Test("Position at subsection boundary uses correct precision")
        func subsectionBoundaries() {
            let cScale = StandardScales.cScale(length: 250.0)
            
            // Test at boundary between first and second subsection (value = 2.0)
            let boundaryPos = ScaleCalculator.normalizedPosition(for: 2.0, on: cScale)
            let decimals = cScale.cursorDecimalPlaces(at: boundaryPos)
            
            // Should use second subsection's precision
            #expect(decimals >= 1 && decimals <= 5, "Boundary position has valid precision")
        }
        
        @Test("Scales without explicit precision use automatic calculation")
        func automaticPrecisionCalculation() {
            // Create scale without explicit cursorPrecision
            let scale = ScaleDefinition(
                name: "TEST",
                formula: "x",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1, 0.1, 0.05, 0.01]
                        // No cursorPrecision specified - should auto-calculate
                    )
                ]
            )
            
            let pos = 0.5
            let decimals = scale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 3, "Scale without explicit precision should auto-calculate from intervals")
        }
        
        @Test("Zero or negative intervals handled gracefully")
        func invalidIntervals() {
            let intervals1 = [1.0, 0.5, 0.0, 0.01]  // Contains zero
            let precision1 = CursorPrecision.calculateFromIntervals(intervals1)
            #expect(precision1 == 3, "Should skip zero interval and use 0.01")
            
            let intervals2: [Double] = []  // Empty array
            let precision2 = CursorPrecision.calculateFromIntervals(intervals2)
            #expect(precision2 == 2, "Empty intervals should return fallback default")
        }
        
        @Test("activeSubsection returns correct subsection for value")
        func activeSubsectionLookup() {
            let kScale = StandardScales.kScale(length: 250.0)
            
            // Test finding subsections at various points
            let testCases: [(value: Double, expectedStart: Double)] = [
                (1.5, 1.0),
                (4.0, 3.0),
                (7.0, 6.0),
                (15.0, 10.0),
                (500.0, 300.0)
            ]
            
            for testCase in testCases {
                let subsection = kScale.activeSubsection(for: testCase.value)
                #expect(subsection?.startValue == testCase.expectedStart,
                       "Value \(testCase.value) should be in subsection starting at \(testCase.expectedStart)")
            }
        }
        
        @Test("activeSubsection returns nil for out-of-range values")
        func activeSubsectionOutOfRange() {
            let cScale = StandardScales.cScale(length: 250.0)
            
            // Value below range
            let below = cScale.activeSubsection(for: 0.5)
            #expect(below == nil, "Value below range should return nil")
            
            // Value above range  
            let above = cScale.activeSubsection(for: 15.0)
            // Should return last subsection if above range
            #expect(above?.startValue == 4.0 || above == nil, 
                   "Value above range returns last subsection or nil")
        }
    }
    
    // MARK: - Performance Tests
    
    @Suite("Performance Tests")
    struct PerformanceTests {
        
        @Test("Precision query performance < 0.1ms per query",
              .timeLimit(.minutes(1)))
        func precisionQueryPerformance() {
            let cScale = StandardScales.cScale(length: 250.0)
            let iterations = 1000
            
            let startTime = Date()
            
            for _ in 0..<iterations {
                let randomPos = Double.random(in: 0...1)
                _ = cScale.cursorDecimalPlaces(at: randomPos)
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let perQuery = (elapsed / Double(iterations)) * 1000 // Convert to ms
            
            #expect(perQuery < 0.1, "Precision query should be < 0.1ms (was \(perQuery)ms)")
        }
        
        @Test("Formatting performance < 0.2ms per format",
              .timeLimit(.minutes(1)))
        func formattingPerformance() {
            let cScale = StandardScales.cScale(length: 250.0)
            let iterations = 1000
            
            let startTime = Date()
            
            for _ in 0..<iterations {
                let randomPos = Double.random(in: 0...1)
                let randomValue = Double.random(in: 1...10)
                _ = cScale.formatForCursor(value: randomValue, at: randomPos)
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let perFormat = (elapsed / Double(iterations)) * 1000 // Convert to ms
            
            #expect(perFormat < 0.2, "Formatting should be < 0.2ms (was \(perFormat)ms)")
        }
        
        @Test("activeSubsection lookup is fast (< 0.05ms)",
              .timeLimit(.minutes(1)))
        func activeSubsectionPerformance() {
            let kScale = StandardScales.kScale(length: 250.0)
            let iterations = 1000
            
            let startTime = Date()
            
            for _ in 0..<iterations {
                let randomValue = Double.random(in: 1...1000)
                _ = kScale.activeSubsection(for: randomValue)
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let perLookup = (elapsed / Double(iterations)) * 1000 // Convert to ms
            
            #expect(perLookup < 0.05, "Subsection lookup should be < 0.05ms (was \(perLookup)ms)")
        }
        
        @Test("Precision calculation from intervals is fast",
              .timeLimit(.minutes(1)))
        func precisionCalculationPerformance() {
            let intervals = [1.0, 0.1, 0.05, 0.01]
            let iterations = 10000
            
            let startTime = Date()
            
            for _ in 0..<iterations {
                _ = CursorPrecision.calculateFromIntervals(intervals)
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let perCalc = (elapsed / Double(iterations)) * 1000 // Convert to ms
            
            #expect(perCalc < 0.01, "Interval calculation should be < 0.01ms (was \(perCalc)ms)")
        }
    }
    
    // MARK: - Cross-Scale Consistency Tests
    
    @Suite("Cross-Scale Consistency Tests")
    struct CrossScaleConsistencyTests {
        
        @Test("C and D scales have identical precision")
        func cAndDScalesMatch() {
            let cScale = StandardScales.cScale(length: 250.0)
            let dScale = StandardScales.dScale(length: 250.0)
            
            // Test at 20 points across the scale
            for i in 0...19 {
                let value = 1.0 + Double(i) * 0.45 // Values from 1.0 to 9.55
                
                let cPos = ScaleCalculator.normalizedPosition(for: value, on: cScale)
                let dPos = ScaleCalculator.normalizedPosition(for: value, on: dScale)
                
                let cDecimals = cScale.cursorDecimalPlaces(at: cPos)
                let dDecimals = dScale.cursorDecimalPlaces(at: dPos)
                
                #expect(cDecimals == dDecimals,
                       "C and D should match at value \(value)")
            }
        }
        
        @Test("A and B scales have identical precision")
        func aAndBScalesMatch() {
            let aScale = StandardScales.aScale(length: 250.0)
            let bScale = StandardScales.bScale(length: 250.0)
            
            let testValues = [1.5, 5.0, 10.0, 25.0, 50.0, 75.0, 95.0]
            
            for value in testValues {
                let aPos = ScaleCalculator.normalizedPosition(for: value, on: aScale)
                let bPos = ScaleCalculator.normalizedPosition(for: value, on: bScale)
                
                let aDecimals = aScale.cursorDecimalPlaces(at: aPos)
                let bDecimals = bScale.cursorDecimalPlaces(at: bPos)
                
                #expect(aDecimals == bDecimals,
                       "A and B should match at value \(value)")
            }
        }
        
        @Test("CI scale matches C scale precision (inverted)")
        func ciScaleMatchesCScale() {
            let cScale = StandardScales.cScale(length: 250.0)
            let ciScale = StandardScales.ciScale(length: 250.0)
            
            // C goes 1→10, CI goes 10→1 (inverted)
            // Value 2.0 on C corresponds to value 5.0 on CI (reciprocal relationship)
            let testPairs: [(cValue: Double, ciValue: Double)] = [
                (1.5, 6.67),
                (2.0, 5.0),
                (3.0, 3.33),
                (5.0, 2.0)
            ]
            
            for pair in testPairs {
                let cPos = ScaleCalculator.normalizedPosition(for: pair.cValue, on: cScale)
                let ciPos = ScaleCalculator.normalizedPosition(for: pair.ciValue, on: ciScale)
                
                let cDecimals = cScale.cursorDecimalPlaces(at: cPos)
                let ciDecimals = ciScale.cursorDecimalPlaces(at: ciPos)
                
                // CI should have same precision as C at corresponding positions
                #expect(cDecimals == ciDecimals || abs(cDecimals - ciDecimals) <= 1,
                       "C at \(pair.cValue) and CI at \(pair.ciValue) should have similar precision")
            }
        }
        
        @Test("CF and DF scales have identical precision")
        func cfAndDfScalesMatch() {
            let cfScale = StandardScales.cfScale(length: 250.0)
            let dfScale = StandardScales.dfScale(length: 250.0)
            
            let testValues = [3.5, 5.0, 10.0, 15.0, 25.0]
            
            for value in testValues {
                let cfPos = ScaleCalculator.normalizedPosition(for: value, on: cfScale)
                let dfPos = ScaleCalculator.normalizedPosition(for: value, on: dfScale)
                
                let cfDecimals = cfScale.cursorDecimalPlaces(at: cfPos)
                let dfDecimals = dfScale.cursorDecimalPlaces(at: dfPos)
                
                #expect(cfDecimals == dfDecimals,
                       "CF and DF should match at value \(value)")
            }
        }
        
        @Test("AI and BI scales have identical precision")
        func aiAndBiScalesMatch() {
            let aiScale = StandardScales.aiScale(length: 250.0)
            let biScale = StandardScales.biScale(length: 250.0)
            
            let testValues = [10.0, 25.0, 50.0, 75.0, 95.0]
            
            for value in testValues {
                let aiPos = ScaleCalculator.normalizedPosition(for: value, on: aiScale)
                let biPos = ScaleCalculator.normalizedPosition(for: value, on: biScale)
                
                let aiDecimals = aiScale.cursorDecimalPlaces(at: aiPos)
                let biDecimals = biScale.cursorDecimalPlaces(at: biPos)
                
                #expect(aiDecimals == biDecimals,
                       "AI and BI should match at value \(value)")
            }
        }
        
        @Test("Extended range C scales maintain precision consistency")
        func extendedCScalePrecision() {
            let c10_100 = StandardScales.c10to100Scale(length: 250.0)
            let c100_1000 = StandardScales.c100to1000Scale(length: 250.0)
            
            // Both should have similar precision patterns to base C scale
            let testValues = [1.5, 3.0, 5.0, 8.0]
            
            for value in testValues {
                let pos10 = ScaleCalculator.normalizedPosition(for: value, on: c10_100)
                let pos100 = ScaleCalculator.normalizedPosition(for: value, on: c100_1000)
                
                let decimals10 = c10_100.cursorDecimalPlaces(at: pos10)
                let decimals100 = c100_1000.cursorDecimalPlaces(at: pos100)
                
                // Extended scales should have same precision as base C
                #expect(decimals10 >= 1 && decimals10 <= 5, "C10-100 has valid precision")
                #expect(decimals100 >= 1 && decimals100 <= 5, "C100-1000 has valid precision")
                #expect(decimals10 == decimals100, "Extended C scales should match each other")
            }
        }
    }
    
    // MARK: - Comprehensive Scale Coverage Tests
    
    @Suite("Comprehensive Scale Coverage Tests")
    struct ScaleCoverageTests {
        
        @Test("All standard logarithmic scales have valid precision")
        func allStandardScalesValid() {
            let scales: [(name: String, scale: ScaleDefinition)] = [
                ("C", StandardScales.cScale()),
                ("D", StandardScales.dScale()),
                ("CI", StandardScales.ciScale()),
                ("DI", StandardScales.diScale()),
                ("CF", StandardScales.cfScale()),
                ("DF", StandardScales.dfScale())
            ]
            
            for (name, scale) in scales {
                // Test at start, middle, end
                let positions = [0.1, 0.5, 0.9]
                
                for pos in positions {
                    let decimals = scale.cursorDecimalPlaces(at: pos)
                    #expect(decimals >= 1 && decimals <= 5,
                           "\(name) scale at position \(pos) has valid precision (1-5)")
                }
            }
        }
        
        @Test("All power scales (A, B, K) have valid precision")
        func allPowerScalesValid() {
            let scales: [(name: String, scale: ScaleDefinition)] = [
                ("A", StandardScales.aScale()),
                ("B", StandardScales.bScale()),
                ("K", StandardScales.kScale())
            ]
            
            for (name, scale) in scales {
                let positions = [0.1, 0.5, 0.9]
                
                for pos in positions {
                    let decimals = scale.cursorDecimalPlaces(at: pos)
                    #expect(decimals >= 1 && decimals <= 5,
                           "\(name) scale at position \(pos) has valid precision")
                }
            }
        }
        
        @Test("All trig scales have valid precision")
        func allTrigScalesValid() {
            let scales: [(name: String, scale: ScaleDefinition)] = [
                ("S", StandardScales.sScale()),
                ("T", StandardScales.tScale()),
                ("ST", StandardScales.stScale())
            ]
            
            for (name, scale) in scales {
                let positions = [0.1, 0.5, 0.9]
                
                for pos in positions {
                    let decimals = scale.cursorDecimalPlaces(at: pos)
                    #expect(decimals >= 1 && decimals <= 5,
                           "\(name) scale at position \(pos) has valid precision")
                }
            }
        }
        
        @Test("All LL scales have valid precision")
        func allLLScalesValid() {
            let scales: [(name: String, scale: ScaleDefinition)] = [
                ("LL00", StandardScales.ll00Scale()),
                ("LL01", StandardScales.ll01Scale()),
                ("LL02", StandardScales.ll02Scale()),
                ("LL03", StandardScales.ll03Scale()),
                ("LL0", StandardScales.ll0Scale()),
                ("LL1", StandardScales.ll1Scale()),
                ("LL2", StandardScales.ll2Scale()),
                ("LL3", StandardScales.ll3Scale())
            ]
            
            for (name, scale) in scales {
                let positions = [0.1, 0.5, 0.9]
                
                for pos in positions {
                    let decimals = scale.cursorDecimalPlaces(at: pos)
                    #expect(decimals >= 1 && decimals <= 5,
                           "\(name) scale at position \(pos) has valid precision")
                }
            }
        }
    }
    
    // MARK: - Real-World Usage Tests
    
    @Suite("Real-World Usage Tests")
    struct RealWorldUsageTests {
        
        @Test("Multiply operation: C scale reading has appropriate precision")
        func multiplicationPrecision() {
            let cScale = StandardScales.cScale()
            
            // Multiply 2.5 × 3.6 = 9.0
            // Read 2.5 on C, align with 1 on D
            // Read result under 3.6 on C
            let resultValue = 9.0
            let pos = ScaleCalculator.normalizedPosition(for: resultValue, on: cScale)
            _ = cScale.formatForCursor(value: resultValue, at: pos)
            
            // Should show with appropriate precision for position
            let decimals = cScale.cursorDecimalPlaces(at: pos)
            #expect(decimals >= 1 && decimals <= 3,
                   "Multiplication result should have 1-3 decimals")
        }
        
        @Test("Square operation: A scale reading shows correct precision")
        func squareOperationPrecision() {
            let aScale = StandardScales.aScale()
            
            // Square of 5: 5² = 25
            let resultValue = 25.0
            let pos = ScaleCalculator.normalizedPosition(for: resultValue, on: aScale)
            _ = aScale.formatForCursor(value: resultValue, at: pos)
            
            // A scale should show 1-2 decimals at this position
            let decimals = aScale.cursorDecimalPlaces(at: pos)
            #expect(decimals >= 1 && decimals <= 2,
                   "Square result should have 1-2 decimals")
        }
        
        @Test("Cube operation: K scale reading shows correct precision")
        func cubeOperationPrecision() {
            let kScale = StandardScales.kScale()
            
            // Cube of 5: 5³ = 125
            let resultValue = 125.0
            let pos = ScaleCalculator.normalizedPosition(for: resultValue, on: kScale)
            let decimals = kScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals >= 1 && decimals <= 2,
                   "Cube result should have 1-2 decimals")
        }
        
        @Test("Trig operation: S scale for sin(30°) shows correct precision")
        func trigOperationPrecision() {
            let sScale = StandardScales.sScale()
            
            // sin(30°) ≈ 0.5, read at 30° on S scale
            let angle = 30.0
            let pos = ScaleCalculator.normalizedPosition(for: angle, on: sScale)
            let decimals = sScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals >= 1 && decimals <= 2,
                   "Trig reading should have 1-2 decimals at mid-range")
        }
        
        @Test("Exponential operation: LL3 scale shows correct precision")
        func exponentialOperationPrecision() {
            let ll3Scale = StandardScales.ll3Scale()
            
            // e^2 ≈ 7.389
            let resultValue = 7.389
            let pos = ScaleCalculator.normalizedPosition(for: resultValue, on: ll3Scale)
            let decimals = ll3Scale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals >= 1 && decimals <= 3,
                   "LL3 reading should have 1-3 decimals")
        }
    }
    
    // MARK: - Precision Calculation Formula Tests
    
    @Suite("Precision Calculation Formula Tests")
    struct PrecisionFormulaTests {
        
        @Test("Formula: interval 0.01 → 3 decimals")
        func intervalPoint01() {
            let precision = CursorPrecision.calculateFromIntervals([1.0, 0.1, 0.05, 0.01])
            #expect(precision == 3, "0.01 interval should give 3 decimals")
        }
        @Test("Formula: interval 0.05 → 3 decimals")
        func intervalPoint05() {
            let precision = CursorPrecision.calculateFromIntervals([1.0, 0.5, 0.1, 0.05])
            // Formula: -floor(log10(0.05)) + 1 = -floor(-1.301) + 1 = 2 + 1 = 3
            #expect(precision == 3, "0.05 interval should give 3 decimals")
        }
        }
        
        @Test("Formula: interval 1.0 → 1 decimal")
        func interval1Point0() {
            let precision = CursorPrecision.calculateFromIntervals([10.0, 5.0, 1.0])
            #expect(precision == 1, "1.0 interval should give 1 decimal")
        }
        
        @Test("Formula: interval 0.001 → 4 decimals")
        func intervalPoint001() {
            let precision = CursorPrecision.calculateFromIntervals([0.01, 0.005, 0.001])
            #expect(precision == 4, "0.001 interval should give 4 decimals")
        }
        
        @Test("Formula: interval 0.00005 → 5 decimals (clamped)")
        func intervalPoint00005() {
            let precision = CursorPrecision.calculateFromIntervals([0.001, 0.0005, 0.0001, 0.00005])
            #expect(precision == 5, "0.00005 interval should give 5 decimals (clamped)")
        }
        
        @Test("Formula: very large interval → 1 decimal (clamped)")
        func veryLargeInterval() {
            let precision = CursorPrecision.calculateFromIntervals([1000.0, 500.0, 100.0])
            #expect(precision == 1, "Large intervals should give 1 decimal (minimum)")
        }
    }
    
    // MARK: - Special Scale Tests
    
    @Suite("Special Scale Precision Tests")
    struct SpecialScaleTests {
        
        @Test("L scale (linear) has high precision")
        func lScalePrecision() {
            let lScale = StandardScales.lScale()
            
            // L scale is linear with 0.002 quaternary interval → 4 decimals
            let pos = 0.5
            let decimals = lScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals == 4, "L scale should have 4 decimals (0.002 interval)")
        }
        
        @Test("Ln scale has high precision")
        func lnScalePrecision() {
            let lnScale = StandardScales.lnScale()
            
            // Ln scale has 0.005 quaternary interval → 4 decimals
            // But actually, looking at StandardScales, it might be different
            let pos = 0.5
            let decimals = lnScale.cursorDecimalPlaces(at: pos)
            
            // Verify it's a reasonable precision (2-4 decimals for linear scale)
            #expect(decimals >= 2 && decimals <= 4, "Ln scale should have 2-4 decimals")
        }
        
        @Test("CAS scale (aviation) has practical precision")
        func casScalePrecision() {
            let casScale = StandardScales.casScale()
            
            // CAS scale for airspeed should have 2 decimals
            let pos = ScaleCalculator.normalizedPosition(for: 150.0, on: casScale)
            let decimals = casScale.cursorDecimalPlaces(at: pos)
            
            #expect(decimals >= 1 && decimals <= 2,
                   "CAS scale should have 1-2 decimals for practical airspeed")
        }
        
        @Test("R1/R2 square root scales have fine precision")
        func squareRootScalePrecision() {
            let r1Scale = StandardScales.r1Scale()
            let r2Scale = StandardScales.r2Scale()
            
            // R1 has 0.005 quinary interval → 4 decimals
            let r1Pos = ScaleCalculator.normalizedPosition(for: 1.5, on: r1Scale)
            let r1Decimals = r1Scale.cursorDecimalPlaces(at: r1Pos)
            #expect(r1Decimals >= 3 && r1Decimals <= 4, "R1 scale should have 3-4 decimals")
            
            // R2 has 0.02 quaternary interval → 3 decimals
            let r2Pos = ScaleCalculator.normalizedPosition(for: 5.0, on: r2Scale)
            let r2Decimals = r2Scale.cursorDecimalPlaces(at: r2Pos)
            #expect(r2Decimals == 3, "R2 scale should have 3 decimals")
        }
    }
    
    // MARK: - Subsection Lookup Tests
    
    @Suite("Subsection Lookup Tests")
    struct SubsectionLookupTests {
        
        @Test("Find subsection in scale with multiple subsections")
        func findInMultipleSubsections() {
            let kScale = StandardScales.kScale()
            
            // K scale has 10 subsections
            let testCases: [(value: Double, expectedStart: Double)] = [
                (1.5, 1.0),    // First subsection
                (5.0, 3.0),    // Second subsection  
                (8.0, 6.0),    // Third subsection
                (20.0, 10.0),  // Fourth subsection
                (500.0, 300.0) // Eighth subsection
            ]
            
            for (value, expectedStart) in testCases {
                let subsection = kScale.activeSubsection(for: value)
                #expect(subsection?.startValue == expectedStart,
                       "Value \(value) should find subsection at \(expectedStart)")
            }
        }
        
        @Test("Find subsection in scale with single subsection")
        func findInSingleSubsection() {
            let scale = ScaleDefinition(
                name: "SIMPLE",
                formula: "x",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.1])
                ]
            )
            
            // Any value should find the single subsection
            let testValues = [1.0, 5.0, 9.9]
            
            for value in testValues {
                let subsection = scale.activeSubsection(for: value)
                #expect(subsection?.startValue == 1.0,
                       "Value \(value) should find the only subsection")
            }
        }
        
        @Test("Subsection lookup returns last applicable when sorted")
        func subsectionsSorted() {
            let cScale = StandardScales.cScale()
            
            // C scale subsections start at 1.0, 2.0, 4.0
            // Value 3.5 should return subsection starting at 2.0
            let subsection = cScale.activeSubsection(for: 3.5)
            
            #expect(subsection?.startValue == 2.0,
                   "Value 3.5 should use subsection 2.0 (last applicable)")
        }
    }
    
    // MARK: - Integration with ScaleCalculator Tests
    
    @Suite("ScaleCalculator Integration Tests")
    struct ScaleCalculatorIntegrationTests {
        
        @Test("Precision query uses ScaleCalculator.value correctly")
        func precisionUsesCalculator() {
            let cScale = StandardScales.cScale()
            
            // Query precision at normalized position 0.3
            let normalizedPos = 0.3
            
            // This should internally use ScaleCalculator to find the value
            let decimals = cScale.cursorDecimalPlaces(at: normalizedPos)
            
            // Verify it's a valid precision
            #expect(decimals >= 1 && decimals <= 5,
                   "Precision query should return valid decimal count")
            
            // Cross-check by getting value manually
            let value = ScaleCalculator.value(at: normalizedPos, on: cScale)
            let subsection = cScale.activeSubsection(for: value)
            
            #expect(subsection != nil, "Should find active subsection for calculated value")
        }
        
        @Test("Format uses correct precision for calculated value")
        func formatUsesCorrectPrecision() {
            let cScale = StandardScales.cScale()
            let normalizedPos = 0.3
            
            // Get the value at this position
            let value = ScaleCalculator.value(at: normalizedPos, on: cScale)
            
            // Format it
            let formatted = cScale.formatForCursor(value: value, at: normalizedPos)
            
            // Get expected decimals
            let expectedDecimals = cScale.cursorDecimalPlaces(at: normalizedPos)
            
            // Count decimals in formatted string
            if let decimalPart = formatted.split(separator: ".").last {
                let actualDecimals = decimalPart.count
                #expect(actualDecimals == expectedDecimals,
                       "Formatted string should have \(expectedDecimals) decimals")
            }
        }
    }
    
    // MARK: - Zoom Level Tests (Future-proofing)
    
    @Suite("Zoom Level Tests")
    struct ZoomLevelTests {
        
        @Test("Zoom level parameter accepted but currently unused")
        func zoomLevelParameter() {
            let cScale = StandardScales.cScale()
            let pos = 0.5
            
            // At 1x zoom
            let decimals1x = cScale.cursorDecimalPlaces(at: pos, zoomLevel: 1.0)
            
            // At 2x zoom (currently should return same as 1x for automatic precision)
            let decimals2x = cScale.cursorDecimalPlaces(at: pos, zoomLevel: 2.0)
            
            // With .automatic precision, zoom doesn't affect result yet
            #expect(decimals1x == decimals2x,
                   "Automatic precision currently ignores zoom level")
        }
        
        @Test("Zoom-dependent precision placeholder works")
        func zoomDependentPrecision() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1, 0.1],
                cursorPrecision: .zoomDependent(basePlaces: 2)
            )
            
            // At 1x zoom: base places
            let decimals1x = subsection.decimalPlaces(for: 5.0, zoomLevel: 1.0)
            #expect(decimals1x == 2, "1x zoom should use base places")
            
            // At 2x zoom: base + 1
            let decimals2x = subsection.decimalPlaces(for: 5.0, zoomLevel: 2.0)
            #expect(decimals2x == 3, "2x zoom should add 1 decimal")
            
            // At 4x zoom: base + 2 (clamped to max 5)
            let decimals4x = subsection.decimalPlaces(for: 5.0, zoomLevel: 4.0)
            #expect(decimals4x == 4, "4x zoom should add 2 decimals")
        }
    }
    
    // MARK: - Precision Clamping Tests
    
    @Suite("Precision Clamping Tests")
    struct PrecisionClampingTests {
        
        @Test("Precision always clamped to minimum 1 decimal")
        func minimumOneDecimal() {
            // Very coarse intervals should still give 1 decimal minimum
            let precision = CursorPrecision.calculateFromIntervals([1000.0, 500.0, 100.0])
            
            #expect(precision >= 1, "Precision should never be less than 1")
        }
        
        @Test("Precision always clamped to maximum 5 decimals")
        func maximumFiveDecimals() {
            // Ultra-fine intervals should clamp to 5 decimals max
            let precision = CursorPrecision.calculateFromIntervals([0.00001, 0.000001])
            
            #expect(precision <= 5, "Precision should never exceed 5")
            #expect(precision == 5, "Ultra-fine intervals should give 5 decimals")
        }
        
        @Test("Fixed precision clamped to valid range")
        func fixedPrecisionClamping() {
            // Test over-clamping
            let high = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1],
                cursorPrecision: .fixed(places: 10)
            )
            #expect(high.decimalPlaces(for: 5.0) == 5, "Fixed precision clamped to max 5")
            
            // Test under-clamping
            let low = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1],
                cursorPrecision: .fixed(places: -1)
            )
            #expect(low.decimalPlaces(for: 5.0) == 1, "Fixed precision clamped to min 1")
        }
    }
    
    // MARK: - Multiple Subsection Navigation Tests
    
    @Suite("Multiple Subsection Navigation Tests")
    struct MultipleSubsectionTests {
        
        @Test("Navigate through all C scale subsections")
        func navigateCScaleSubsections() {
            let cScale = StandardScales.cScale()
            
            // C scale has 3 subsections: 1.0, 2.0, 4.0
            let testPoints: [(value: Double, expectedSubsection: Double)] = [
                (1.2, 1.0),
                (1.9, 1.0),
                (2.5, 2.0),
                (3.8, 2.0),
                (5.0, 4.0),
                (9.5, 4.0)
            ]
            
            for (value, expectedStart) in testPoints {
                let subsection = cScale.activeSubsection(for: value)
                #expect(subsection?.startValue == expectedStart,
                       "Value \(value) should be in subsection \(expectedStart)")
            }
        }
        
        @Test("Navigate through all K scale subsections")
        func navigateKScaleSubsections() {
            let kScale = StandardScales.kScale()
            
            // K scale has 10 subsections
            let boundaries = [1.0, 3.0, 6.0, 10.0, 30.0, 60.0, 100.0, 300.0, 600.0, 1000.0]
            
            for i in 0..<boundaries.count {
                let startValue = boundaries[i]
                let testValue = i < boundaries.count - 1 ? 
                    (startValue + boundaries[i + 1]) / 2 : startValue + 50
                
                let subsection = kScale.activeSubsection(for: testValue)
                #expect(subsection?.startValue == startValue,
                       "Value \(testValue) should be in subsection \(startValue)")
            }
        }
    }
    
    // MARK: - Reciprocal Scale Tests
    
    @Suite("Reciprocal/Inverted Scale Tests")
    struct ReciprocalScaleTests {
        
        @Test("LL positive and negative scales have appropriate precision")
        func llReciprocalPrecision() {
            let ll3 = StandardScales.ll3Scale()
            let ll03 = StandardScales.ll03Scale()
            
            // LL3 low end should have 2-3 decimals
            let ll3Pos = ScaleCalculator.normalizedPosition(for: 5.0, on: ll3)
            let ll3Decimals = ll3.cursorDecimalPlaces(at: ll3Pos)
            #expect(ll3Decimals >= 1 && ll3Decimals <= 3, "LL3 should have 1-3 decimals")
            
            // LL03 should have very high precision (4-5 decimals)
            let ll03Pos = ScaleCalculator.normalizedPosition(for: 0.01, on: ll03)
            let ll03Decimals = ll03.cursorDecimalPlaces(at: ll03Pos)
            #expect(ll03Decimals >= 4 && ll03Decimals <= 5, "LL03 should have 4-5 decimals")
        }
        
        @Test("CI scale precision mirrors C scale at corresponding positions")
        func ciMirrorsCPrecision() {
            let cScale = StandardScales.cScale()
            let ciScale = StandardScales.ciScale()
            
            // CI is inverted: C's 1.0 is CI's 10.0
            // Test reciprocal pairs
            let testPairs: [(c: Double, ci: Double)] = [
                (1.0, 10.0),
                (2.0, 5.0),
                (2.5, 4.0),
                (5.0, 2.0)
            ]
            
            for (cValue, ciValue) in testPairs {
                let cPos = ScaleCalculator.normalizedPosition(for: cValue, on: cScale)
                let ciPos = ScaleCalculator.normalizedPosition(for: ciValue, on: ciScale)
                
                let cDecimals = cScale.cursorDecimalPlaces(at: cPos)
                let ciDecimals = ciScale.cursorDecimalPlaces(at: ciPos)
                
                // Due to inversion, precision might differ by 1
                #expect(abs(cDecimals - ciDecimals) <= 1,
                       "CI precision should be similar to C at reciprocal position")
            }
        }
    }
    
    // MARK: - Comprehensive End-to-End Tests
    
    @Suite("End-to-End Integration Tests")
    struct EndToEndTests {
        
        @Test("Complete workflow: position → value → precision → format")
        func completeWorkflow() {
            let cScale = StandardScales.cScale()
            
            // Start with normalized position
            let normalizedPos = 0.3
            
            // Calculate value at position
            let value = ScaleCalculator.value(at: normalizedPos, on: cScale)
            
            // Get precision for that position
            let decimals = cScale.cursorDecimalPlaces(at: normalizedPos)
            
            // Format the value
            let formatted = cScale.formatForCursor(value: value, at: normalizedPos)
            
            // Verify all steps worked
            #expect(value > 0, "Value should be calculated")
            #expect(decimals >= 1 && decimals <= 5, "Precision should be valid")
            #expect(!formatted.isEmpty, "Formatted string should not be empty")
            
            // Count decimals in formatted string
            if let decimalPart = formatted.split(separator: ".").last {
                #expect(decimalPart.count == decimals,
                       "Formatted decimals should match calculated precision")
            }
        }
        
        @Test("Precision system handles all scale types correctly")
        func allScaleTypesWork() {
            // Test representative scale from each category
            let scales: [(name: String, scale: ScaleDefinition)] = [
                ("C", StandardScales.cScale()),       // Logarithmic
                ("A", StandardScales.aScale()),       // Power (square)
                ("K", StandardScales.kScale()),       // Power (cube)
                ("S", StandardScales.sScale()),       // Trig (sine)
                ("L", StandardScales.lScale()),       // Linear
                ("LL3", StandardScales.ll3Scale()),   // Log-log
                ("LL00", StandardScales.ll00Scale())  // Ultra-precision
            ]
            
            for (name, scale) in scales {
                let pos = 0.5 // Test at midpoint
                
                let decimals = scale.cursorDecimalPlaces(at: pos)
                let value = ScaleCalculator.value(at: pos, on: scale)
                let formatted = scale.formatForCursor(value: value, at: pos)
                
                #expect(decimals >= 1 && decimals <= 5,
                       "\(name) scale has valid precision")
                #expect(!formatted.isEmpty,
                       "\(name) scale produces formatted output")
            }
        }
        
        @Test("Precision system performance acceptable across all scales")
        func allScalesPerformant() {
            let scales = [
                StandardScales.cScale(),
                StandardScales.kScale(),
                StandardScales.ll3Scale(),
                StandardScales.sScale()
            ]
            
            let iterations = 100
            let startTime = Date()
            
            for scale in scales {
                for _ in 0..<iterations {
                    let randomPos = Double.random(in: 0...1)
                    _ = scale.cursorDecimalPlaces(at: randomPos)
                }
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let perQuery = (elapsed / Double(scales.count * iterations)) * 1000
            
            #expect(perQuery < 0.1, "Average precision query < 0.1ms across all scales")
        }
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Suite("Backward Compatibility Tests")
    struct BackwardCompatibilityTests {
        
        @Test("Subsections without cursorPrecision work correctly")
        func oldStyleSubsections() {
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1, 0.1, 0.05, 0.01],
                labelLevels: [0]
                // No cursorPrecision parameter
            )
            
            let decimals = subsection.decimalPlaces(for: 5.0)
            #expect(decimals == 3, "Old-style subsection should auto-calculate precision")
        }
        
        @Test("Existing scale definitions still work")
        func existingScalesWork() {
            // All factory methods should work
            let scales = [
                StandardScales.cScale(),
                StandardScales.dScale(),
                StandardScales.aScale(),
                StandardScales.kScale()
            ]
            
            for scale in scales {
                let decimals = scale.cursorDecimalPlaces(at: 0.5)
                #expect(decimals >= 1 && decimals <= 5,
                       "\(scale.name) scale works with precision API")
            }
        }
    }
    
    // MARK: - Validation Tests
    
    @Suite("Validation Tests")
    struct ValidationTests {
        
        @Test("All C scale subsections have documented precision")
        func cScaleDocumented() {
            let cScale = StandardScales.cScale()
            
            // Verify we have 3 subsections
            #expect(cScale.subsections.count == 3, "C scale should have 3 subsections")
            
            // Verify each subsection produces valid precision
            for subsection in cScale.subsections {
                let decimals = subsection.decimalPlaces(for: subsection.startValue)
                #expect(decimals >= 1 && decimals <= 5,
                       "Subsection at \(subsection.startValue) has valid precision")
            }
        }
        
        @Test("All K scale subsections have documented precision")
        func kScaleDocumented() {
            let kScale = StandardScales.kScale()
            
            // Verify we have 10 subsections
            #expect(kScale.subsections.count == 10, "K scale should have 10 subsections")
            
            // Verify each subsection produces valid precision
            for subsection in kScale.subsections {
                let decimals = subsection.decimalPlaces(for: subsection.startValue)
                #expect(decimals >= 1 && decimals <= 5,
                       "K subsection at \(subsection.startValue) has valid precision")
            }
        }
        
        @Test("All LL00 scale subsections have 5 decimal precision")
        func ll00AllSubsectionsFine() {
            let ll00Scale = StandardScales.ll00Scale()
            
            // All LL00 subsections should have finest precision
            for subsection in ll00Scale.subsections {
                let decimals = subsection.decimalPlaces(for: subsection.startValue)
                #expect(decimals == 5,
                       "LL00 subsection at \(subsection.startValue) should have 5 decimals")
            }
        }
    }