import Foundation
import SlideRuleCoreV3

/// Example demonstrating the cursor precision API
func demonstrateCursorPrecisionAPI() {
    print("=== Cursor Precision API Examples ===\n")
    
    // Example 1: Automatic precision from intervals
    print("1. Automatic Precision Calculation:")
    let intervals1 = [1.0, 0.1, 0.05, 0.01]
    let precision1 = CursorPrecision.calculateFromIntervals(intervals1)
    print("   Intervals: \(intervals1)")
    print("   Calculated precision: \(precision1) decimal places\n")
    
    // Example 2: Different interval sets
    let intervals2 = [100.0, 50.0, 10.0, 5.0]
    let precision2 = CursorPrecision.calculateFromIntervals(intervals2)
    print("   Intervals: \(intervals2)")
    print("   Calculated precision: \(precision2) decimal places\n")
    
    // Example 3: Create a scale with automatic precision
    print("2. Scale with Automatic Precision:")
    let cScale = ScaleDefinition(
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
                tickIntervals: [1, 0.1, 0.05, 0.01]
            )
        ]
    )
    
    // Query precision at a position
    let position = 0.3
    let decimals = cScale.cursorDecimalPlaces(at: position, zoomLevel: 1.0)
    print("   At position \(position): \(decimals) decimal places")
    
    // Format a value
    let value = 2.3456789
    let formatted = cScale.formatForCursor(value: value, at: position)
    print("   Formatted value \(value): \(formatted)\n")
    
    // Example 4: Fixed precision override
    print("3. Scale with Fixed Precision Override:")
    let overrideScale = ScaleDefinition(
        name: "LL00",
        formula: "e^e^x",
        function: LogLogFunction(),
        beginValue: 0.990,
        endValue: 0.999,
        scaleLengthInPoints: 250.0,
        layout: .linear,
        subsections: [
            ScaleSubsection(
                startValue: 0.990,
                tickIntervals: [0.001, 0.0005, 0.0001],
                cursorPrecision: .fixed(places: 5) // Override to 5 decimals
            )
        ]
    )
    
    let overrideDecimals = overrideScale.cursorDecimalPlaces(at: 0.5)
    print("   Fixed precision: \(overrideDecimals) decimal places")
    
    let overrideFormatted = overrideScale.formatForCursor(value: 0.99512, at: 0.5)
    print("   Formatted: \(overrideFormatted)\n")
    
    // Example 5: Backward compatibility - no cursorPrecision specified
    print("4. Backward Compatibility (defaults to automatic):")
    let oldStyleSubsection = ScaleSubsection(
        startValue: 1.0,
        tickIntervals: [1, 0.5, 0.1, 0.05]
    )
    let autoDecimals = oldStyleSubsection.decimalPlaces(for: 5.0)
    print("   Subsection without cursorPrecision parameter")
    print("   Automatically computed: \(autoDecimals) decimal places\n")
    
    print("=== All examples completed successfully! ===")
}

// Run the demonstration
// Uncomment to execute:
// demonstrateCursorPrecisionAPI()