import Foundation
import Testing
@testable import SlideRuleCoreV3

/// Tests for cursor precision API
///
/// These tests verify the cursor precision display logic, including:
/// - Automatic precision calculation from tick intervals
/// - Fixed precision overrides
/// - Value formatting for cursor display
///
/// For mathematical precision of value calculations, see:
/// - `CursorValueRoundTripTests` - Position → Value → Position accuracy
/// - `CursorValueKnownValueTests` - Known mathematical values
/// - `CursorValueBoundaryTests` - Scale boundary accuracy
struct CursorPrecisionTests {
    
    // MARK: - Automatic Precision Calculation Tests
    
    @Test("Automatic precision from intervals [1, 0.1, 0.05, 0.01] gives 3 decimals")
    func automaticPrecisionFineIntervals() {
        let intervals = [1.0, 0.1, 0.05, 0.01]
        let precision = CursorPrecision.calculateFromIntervals(intervals)
        #expect(precision == 3)
    }
    
    @Test("Automatic precision from intervals [1, 0.5, 0.1, 0.05] gives 2 decimals")
    func automaticPrecisionMediumIntervals() {
        let intervals = [1.0, 0.5, 0.1, 0.05]
        let precision = CursorPrecision.calculateFromIntervals(intervals)
        #expect(precision == 2)
    }
    
    @Test("Automatic precision from intervals [100, 50, 10, 5] gives 1 decimal")
    func automaticPrecisionCoarseIntervals() {
        let intervals = [100.0, 50.0, 10.0, 5.0]
        let precision = CursorPrecision.calculateFromIntervals(intervals)
        #expect(precision == 1)
    }
    
    @Test("Automatic precision from very fine intervals clamped to 5 decimals")
    func automaticPrecisionVeryFineIntervals() {
        let intervals = [0.001, 0.0005, 0.0001, 0.00002]
        let precision = CursorPrecision.calculateFromIntervals(intervals)
        #expect(precision == 5) // Clamped to max of 5
    }
    
    // MARK: - Fixed Precision Tests
    
    @Test("Fixed precision override works correctly")
    func fixedPrecisionOverride() {
        let subsection = ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [1, 0.1, 0.05, 0.01], // Would normally be 3 decimals
            labelLevels: [0],
            cursorPrecision: .fixed(places: 4) // Override to 4 decimals
        )
        
        let places = subsection.decimalPlaces(for: 5.0, zoomLevel: 1.0)
        #expect(places == 4)
    }
    
    @Test("Fixed precision clamping to valid range")
    func fixedPrecisionClamping() {
        // Test upper bound clamping
        let subsection1 = ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [1, 0.1],
            cursorPrecision: .fixed(places: 10) // Should clamp to 5
        )
        #expect(subsection1.decimalPlaces(for: 5.0) == 5)
        
        // Test lower bound clamping
        let subsection2 = ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [1, 0.1],
            cursorPrecision: .fixed(places: 0) // Should clamp to 1
        )
        #expect(subsection2.decimalPlaces(for: 5.0) == 1)
    }
    
    // MARK: - ScaleDefinition Integration Tests
    
    @Test("ScaleDefinition cursor precision at different positions")
    func scalePrecisionAtPositions() {
        // Create a simple C scale with varying precision
        let scale = ScaleDefinition(
            name: "C",
            formula: "x",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            subsections: [
                // Position 1-2: fine intervals → 3 decimals
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1, 0.1, 0.05, 0.01]
                ),
                // Position 2-4: medium intervals → 3 decimals
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1, 0.5, 0.1, 0.02]
                ),
                // Position 4-10: coarse intervals → 2 decimals
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1, 0.5, 0.1, 0.05]
                )
            ]
        )
        
        // Test position in first subsection (value ~1.5)
        let pos1 = 0.176  // Normalized position ≈ 1.5
        let decimals1 = scale.cursorDecimalPlaces(at: pos1, zoomLevel: 1.0)
        #expect(decimals1 == 3)
        
        // Test position in third subsection (value ~5.0)
        let pos2 = 0.699  // Normalized position ≈ 5.0
        let decimals2 = scale.cursorDecimalPlaces(at: pos2, zoomLevel: 1.0)
        #expect(decimals2 == 2)
    }
    
    @Test("Format value for cursor display with explicit precision verification")
    func formatForCursorDisplay() {
        let scale = ScaleDefinition(
            name: "C",
            formula: "x",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1, 0.1, 0.05, 0.01] // 3 decimals
                )
            ]
        )
        
        // Test formatting with explicit expected value
        // IEEE 754 rounding of 1.23456 to 3 decimal places should give 1.235
        let testValue = 1.23456
        let formatted = scale.formatForCursor(value: testValue, at: 0.1, zoomLevel: 1.0)
        
        // Verify the formatting is deterministic - standard IEEE rounding gives 1.235
        #expect(formatted == "1.235", "Expected 1.23456 rounded to 3 places to be 1.235")
        
        // Verify the round-trip error is within expected formatting precision
        // For 3 decimal places, max rounding error is 0.5 * 10^(-3) = 0.0005
        // We use 0.001 as the tolerance to account for possible edge cases
        if let parsedValue = Double(formatted) {
            let roundTripError = abs(parsedValue - testValue)
            let decimalPlaces = 3
            let formattingTolerance = 0.5 * pow(10.0, Double(-decimalPlaces)) * 2.0  // 0.001 for 3 decimals
            #expect(roundTripError < formattingTolerance,
                    "Round-trip error (\(roundTripError)) should be < \(formattingTolerance) for \(decimalPlaces) decimal places")
        }
    }
    
    @Test("Format computed value at known position")
    func formatComputedValueAtKnownPosition() {
        let scale = ScaleDefinition(
            name: "C",
            formula: "x",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1, 0.1, 0.05, 0.01] // 3 decimals
                )
            ]
        )
        
        // Use a known mathematical position: log10(2) ≈ 0.30103
        let position = CursorValuePrecision.KnownValues.log10_2
        
        // First verify the computed value accuracy
        let computedValue = ScaleCalculator.value(at: position, on: scale)
        #expect(abs(computedValue - 2.0) < CursorValuePrecision.standardTolerance,
                "Value at log10(2) should be 2.0 within standard tolerance")
        
        // Then verify the formatting is correct
        let formatted = scale.formatForCursor(value: computedValue, at: position, zoomLevel: 1.0)
        #expect(formatted == "2.000", "Value 2.0 formatted to 3 decimals should be 2.000")
    }
    
    @Test("Handle non-finite values gracefully")
    func formatNonFiniteValues() {
        let scale = ScaleDefinition(
            name: "C",
            formula: "x",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1, 0.1]
                )
            ]
        )
        
        // Test infinity
        let formatted1 = scale.formatForCursor(value: Double.infinity, at: 0.5)
        #expect(formatted1 == "—")
        
        // Test NaN
        let formatted2 = scale.formatForCursor(value: Double.nan, at: 0.5)
        #expect(formatted2 == "—")
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test("Subsection without cursorPrecision defaults to automatic")
    func backwardCompatibilityAutomatic() {
        // Old-style initialization without cursorPrecision parameter
        let subsection = ScaleSubsection(
            startValue: 1.0,
            tickIntervals: [1, 0.1, 0.05, 0.01],
            labelLevels: [0]
        )
        
        // Should automatically compute precision from intervals
        let places = subsection.decimalPlaces(for: 5.0)
        #expect(places == 3) // Expected from intervals
    }
    
    @Test("CursorPrecision enum equality")
    func cursorPrecisionEquality() {
        #expect(CursorPrecision.automatic == CursorPrecision.automatic)
        #expect(CursorPrecision.fixed(places: 3) == CursorPrecision.fixed(places: 3))
        #expect(CursorPrecision.fixed(places: 3) != CursorPrecision.fixed(places: 4))
        #expect(CursorPrecision.automatic != CursorPrecision.fixed(places: 3))
    }
    
    @Test("CursorPrecision enum hashability")
    func cursorPrecisionHashability() {
        var set = Set<CursorPrecision>()
        set.insert(.automatic)
        set.insert(.fixed(places: 3))
        set.insert(.fixed(places: 3)) // Duplicate
        
        #expect(set.count == 2) // Should only have 2 unique values
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty intervals array returns default precision")
    func emptyIntervals() {
        let precision = CursorPrecision.calculateFromIntervals([])
        #expect(precision == 2) // Fallback default
    }
    
    @Test("Intervals with zero values are handled")
    func intervalsWithZeros() {
        let intervals = [1.0, 0.1, 0.0, 0.01]
        let precision = CursorPrecision.calculateFromIntervals(intervals)
        #expect(precision == 3) // Should use 0.01, not 0.0
    }
    
    @Test("Find active subsection for value")
    func findActiveSubsection() {
        let scale = ScaleDefinition(
            name: "C",
            formula: "x",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            subsections: [
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.1]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.5]),
                ScaleSubsection(startValue: 4.0, tickIntervals: [1, 0.5])
            ]
        )
        
        // Test value in first subsection
        let subsection1 = scale.activeSubsection(for: 1.5)
        #expect(subsection1?.startValue == 1.0)
        
        // Test value in second subsection
        let subsection2 = scale.activeSubsection(for: 3.0)
        #expect(subsection2?.startValue == 2.0)
        
        // Test value in third subsection
        let subsection3 = scale.activeSubsection(for: 7.0)
        #expect(subsection3?.startValue == 4.0)
    }
}