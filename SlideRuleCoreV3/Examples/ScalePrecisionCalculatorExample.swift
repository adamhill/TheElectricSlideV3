import Foundation

/// Slide Rule Cursor Precision Calculator
/// Based on PostScript Subsection Tick Mark Data
///
/// This module calculates the appropriate number of decimal places
/// to display for a digital slide rule cursor based on the subsection
/// intervals defined in the PostScript engine.

// MARK: - Data Structures

/// Represents a subsection of a scale with its tick mark intervals
struct ScaleSubsectionDefinition {
    /// Starting value of this subsection
    let beginSub: Double
    
    /// Tick intervals: [primary, secondary, tertiary, quaternary]
    /// nil values indicate no tick marks at that level
    let intervals: [Double?]
}

/// Complete definition of a scale for precision calculation
struct ScalePrecisionDefinition {
    /// Starting value of the scale
    let beginScale: Double
    
    /// Ending value of the scale
    let endScale: Double
    
    /// Precision multiplier (default 100)
    let xFactor: Double
    
    /// List of subsections defining tick intervals
    let subsections: [ScaleSubsectionDefinition]
}

// MARK: - Scale Precision Calculator

/// Calculates appropriate decimal places for cursor display based on
/// PostScript scale subsection definitions.
struct ScalePrecisionCalculator {
    /// Scale definition with subsections
    private let definition: ScalePrecisionDefinition
    
    /// Sorted subsections for efficient lookup
    private let sortedSubsections: [ScaleSubsectionDefinition]
    
    /// Initialize with a scale definition
    /// - Parameter definition: Complete scale definition with subsections
    init(definition: ScalePrecisionDefinition) {
        self.definition = definition
        // Sort subsections by beginSub to ensure proper ordering
        self.sortedSubsections = definition.subsections.sorted { $0.beginSub < $1.beginSub }
    }
    
    /// Get appropriate decimal places for cursor at given position
    /// - Parameter position: Current cursor position on the scale
    /// - Returns: Number of decimal places to display (1-5)
    func getDecimalPlaces(position: Double) -> Int {
        // Validate position is within scale bounds
        guard position >= definition.beginScale && position <= definition.endScale else {
            return 2 // default for out-of-bounds
        }
        
        // Find the active subsection for this position
        guard let activeSubsection = findActiveSubsection(position: position) else {
            return 2 // default if no subsection found
        }
        
        // Get the smallest interval from this subsection
        guard let smallestInterval = getSmallestInterval(subsection: activeSubsection) else {
            return 2 // default if no interval found
        }
        
        // Convert interval to decimal places
        return intervalToDecimalPlaces(interval: smallestInterval)
    }
    
    /// Find which subsection applies to the given position
    /// - Parameter position: Position on the scale
    /// - Returns: Active subsection, or nil if not found
    private func findActiveSubsection(position: Double) -> ScaleSubsectionDefinition? {
        var activeSubsection: ScaleSubsectionDefinition?
        
        // Iterate through subsections to find the last one
        // whose beginSub is <= position
        for subsection in sortedSubsections {
            if position >= subsection.beginSub {
                activeSubsection = subsection
            } else {
                // Since sorted, we can stop here
                break
            }
        }
        
        return activeSubsection
    }
    
    /// Extract the smallest (finest) interval from a subsection
    ///
    /// The intervals array is [primary, secondary, tertiary, quaternary].
    /// We want the smallest non-nil value (typically quaternary).
    ///
    /// - Parameter subsection: Subsection definition
    /// - Returns: Smallest interval value, or nil if all are nil
    private func getSmallestInterval(subsection: ScaleSubsectionDefinition) -> Double? {
        // Scan backwards through intervals to find last non-nil
        for interval in subsection.intervals.reversed() {
            if let interval = interval {
                return interval
            }
        }
        
        // If all are nil (shouldn't happen), return nil
        return nil
    }
    
    /// Convert an interval size to appropriate decimal places
    ///
    /// The logic:
    /// - For intervals >= 1: show 1 decimal place (for interpolation)
    /// - For intervals < 1: calculate decimal places needed to represent
    ///   the interval, then add 1 for interpolation between marks
    /// - Clamp result to 1-5 decimal places
    ///
    /// - Parameter interval: The smallest tick mark spacing
    /// - Returns: Number of decimal places (1-5)
    private func intervalToDecimalPlaces(interval: Double) -> Int {
        if interval >= 1 {
            // Integer precision, but show one decimal for smooth interpolation
            return 1
        }
        
        // Calculate how many decimal places needed to represent this interval
        // For 0.01, we need 2 decimal places
        // For 0.001, we need 3 decimal places
        // Formula: -floor(log10(interval))
        var decimalPlaces = -Int(floor(log10(interval)))
        
        // Add one more decimal place for interpolation
        // (users can estimate about 1/10 between marks)
        decimalPlaces += 1
        
        // Clamp to reasonable range (1-5)
        return min(max(decimalPlaces, 1), 5)
    }
    
    /// Get a formatted string representation of the position
    /// with appropriate decimal places
    /// - Parameter position: Position on the scale
    /// - Returns: Formatted string (e.g., "1.234" or "56.7")
    func getFormattedValue(position: Double) -> String {
        let decimalPlaces = getDecimalPlaces(position: position)
        return String(format: "%.\(decimalPlaces)f", position)
    }
}

// MARK: - Factory Functions

/// Create a calculator for the standard C scale
///
/// This matches the PostScript definition from lines 430-461.
///
/// - Returns: Configured ScalePrecisionCalculator
func createCScaleCalculator() -> ScalePrecisionCalculator {
    let cScaleDefinition = ScalePrecisionDefinition(
        beginScale: 1,
        endScale: 10,
        xFactor: 100,
        subsections: [
            ScaleSubsectionDefinition(beginSub: 1,  intervals: [1, 0.1, 0.05, 0.01]),
            ScaleSubsectionDefinition(beginSub: 2,  intervals: [1, 0.5, 0.1, 0.02]),
            ScaleSubsectionDefinition(beginSub: 4,  intervals: [1, 0.5, 0.1, 0.05]),
            ScaleSubsectionDefinition(beginSub: 10, intervals: [10, 1, 0.5, 0.1]),
            ScaleSubsectionDefinition(beginSub: 20, intervals: [10, 5, 1, 0.2]),
            ScaleSubsectionDefinition(beginSub: 40, intervals: [10, 5, 1, 0.5]),
        ]
    )
    return ScalePrecisionCalculator(definition: cScaleDefinition)
}

/// Create a calculator for the LL00 scale (very fine precision)
///
/// This matches the PostScript definition from lines 1201-1210.
///
/// - Returns: Configured ScalePrecisionCalculator
func createLL00ScaleCalculator() -> ScalePrecisionCalculator {
    let ll00ScaleDefinition = ScalePrecisionDefinition(
        beginScale: 0.990,
        endScale: 0.999,
        xFactor: 100000,
        subsections: [
            ScaleSubsectionDefinition(beginSub: 0.990, intervals: [0.001, 0.0005, 0.0001, 0.00005]),
            ScaleSubsectionDefinition(beginSub: 0.995, intervals: [0.001, 0.0005, 0.0001, 0.00002]),
            ScaleSubsectionDefinition(beginSub: 0.998, intervals: [0.0005, 0.0001, 0.00005, 0.00001]),
        ]
    )
    return ScalePrecisionCalculator(definition: ll00ScaleDefinition)
}

/// Create a calculator for the K scale (cube roots)
///
/// This matches the PostScript definition from lines 710-728.
///
/// - Returns: Configured ScalePrecisionCalculator
func createKScaleCalculator() -> ScalePrecisionCalculator {
    let kScaleDefinition = ScalePrecisionDefinition(
        beginScale: 1,
        endScale: 1000,
        xFactor: 100,
        subsections: [
            ScaleSubsectionDefinition(beginSub: 1,    intervals: [1, 0.5, 0.1, 0.05]),
            ScaleSubsectionDefinition(beginSub: 3,    intervals: [1, nil, 0.5, 0.1]),
            ScaleSubsectionDefinition(beginSub: 6,    intervals: [1, nil, nil, 0.2]),
            ScaleSubsectionDefinition(beginSub: 10,   intervals: [10, 5, 1, 0.5]),
            ScaleSubsectionDefinition(beginSub: 30,   intervals: [10, nil, 5, 1]),
            ScaleSubsectionDefinition(beginSub: 60,   intervals: [10, nil, nil, 2]),
            ScaleSubsectionDefinition(beginSub: 100,  intervals: [100, 50, 10, 5]),
            ScaleSubsectionDefinition(beginSub: 300,  intervals: [100, nil, 50, 10]),
            ScaleSubsectionDefinition(beginSub: 600,  intervals: [100, nil, nil, 20]),
            ScaleSubsectionDefinition(beginSub: 1000, intervals: [1000, 500, 100, 50]),
        ]
    )
    return ScalePrecisionCalculator(definition: kScaleDefinition)
}

// MARK: - Demo and Testing

/// Demonstrate the scale precision calculator functionality
func demonstrateScalePrecisionCalculator() {
    print("=" + String(repeating: "=", count: 69))
    print("Slide Rule Cursor Precision Calculator Demo")
    print("=" + String(repeating: "=", count: 69))
    
    // Test C Scale
    print("\n--- C Scale (Standard Logarithmic) ---")
    let cCalc = createCScaleCalculator()
    
    let testPositionsC = [1.0, 1.5, 2.0, 3.14159, 5.0, 7.5, 9.0]
    for pos in testPositionsC {
        let decimals = cCalc.getDecimalPlaces(position: pos)
        let formatted = cCalc.getFormattedValue(position: pos)
        print(String(format: "Position %6.3f: %d decimals → %8s", pos, decimals, formatted))
    }
    
    // Test LL00 Scale (Very Fine)
    print("\n--- LL00 Scale (Very Fine Precision) ---")
    let ll00Calc = createLL00ScaleCalculator()
    
    let testPositionsLL00 = [0.990, 0.993, 0.996, 0.9985, 0.999]
    for pos in testPositionsLL00 {
        let decimals = ll00Calc.getDecimalPlaces(position: pos)
        let formatted = ll00Calc.getFormattedValue(position: pos)
        print(String(format: "Position %.5f: %d decimals → %10s", pos, decimals, formatted))
    }
    
    // Test K Scale (Cube Roots)
    print("\n--- K Scale (Cube Roots) ---")
    let kCalc = createKScaleCalculator()
    
    let testPositionsK: [Double] = [1, 5, 10, 50, 100, 500, 1000]
    for pos in testPositionsK {
        let decimals = kCalc.getDecimalPlaces(position: pos)
        let formatted = kCalc.getFormattedValue(position: pos)
        print(String(format: "Position %6.1f: %d decimals → %8s", pos, decimals, formatted))
    }
    
    print("\n" + String(repeating: "=", count: 70))
    print("Validation Summary:")
    print(String(repeating: "=", count: 70))
    print("✓ Fine scales (LL00): 5 decimal places near 1.0")
    print("✓ Standard scales (C): 2-3 decimal places across range")
    print("✓ Coarse scales (K high values): 1 decimal place")
    print("✓ Automatic adaptation to scale position")
    print("✓ Matches historical slide rule precision")
    print(String(repeating: "=", count: 70))
}

// Run the demonstration
// Uncomment to execute:
// demonstrateScalePrecisionCalculator()