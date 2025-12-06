import Foundation

// MARK: - PostScript to Swift Concordance
//
// PostScript uses Reverse Polish Notation (RPN) with a stack-based execution model.
//
// Reading PostScript formulas:
//   - Numbers are pushed onto the stack
//   - Operations pop values from stack, push result back
//   - 'exch' swaps top two stack items
//   - 'dup' duplicates top of stack
//
// Common operators:
//   x y add  → x+y          x y mul  → x×y
//   x y sub  → x-y          x y div  → x÷y
//   x exp    → eˣ           x log    → log₁₀(x)
//   x ln     → ln(x)        x sqrt   → √x
//   x y exp  → xʸ           x neg    → -x
//
// Examples:
//   {log}                    →  log₁₀(x)
//   {2 exp}                  →  x²  (x raised to power 2)
//   {10 mul log}             →  log₁₀(10×x)
//   {1 exch div}             →  1/x  (exch swaps 1 and x, then divide)
//   {dup 2 exp 1 sub}        →  x²-1  (dup duplicates x)
//   {log 2 div}              →  log₁₀(x)/2  (half-log for square scales)
//   {log 3 div}              →  log₁₀(x)/3  (third-log for cube scales)

// MARK: - Standard Scale Functions
//
// These functions implement the core mathematical transformations used in standard slide rule scales.
// Each function corresponds to a specific PostScript formula from the original engine.

// MARK: - Reciprocal Scale Functions

/// ReciprocalLogFunction: Used for CI/DI and CIF/DIF scales
/// PostScript: {1 exch div 10 mul log}
/// Formula: -log₁₀(x)
/// This function creates inverted logarithmic scales where values decrease from left to right,
/// enabling direct division operations and reciprocal calculations.
public struct ReciprocalLogFunction: ScaleFunction {
    public let name = "reciprocal-log"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        -log10(value)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, -transformedValue)
    }
}

// MARK: - Power Scale Functions

/// HalfLogFunction: Used for A/B scales (square scales)
/// PostScript: {log 2 div}
/// Formula: log₁₀(x) / 2
/// Maps x² values onto the standard C/D scale length, allowing squares to be read directly.
public struct HalfLogFunction: ScaleFunction {
    public let name = "half-log"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        0.5 * log10(value)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, 2 * transformedValue)
    }
}

/// ThirdLogFunction: Used for K scale (cube scale)
/// PostScript: {log 3 div}
/// Formula: log₁₀(x) / 3
/// Maps x³ values onto the standard C/D scale length, allowing cubes to be read directly.
public struct ThirdLogFunction: ScaleFunction {
    public let name = "third-log"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value) / 3.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, 3 * transformedValue)
    }
}

// MARK: - Logarithmic Scales

/// LogLnFunction: Used for LL1, LL2, LL3 scales (log-log scales)
/// PostScript: {ln X mul log} where X is the multiplier
/// Formula: log₁₀(ln(x)) × multiplier
/// Enables exponential and power calculations through logarithmic transformations.
/// Different multipliers (1, 10) provide different ranges for precision.
public struct LogLnFunction: ScaleFunction {
    public let name = "log-ln"
    public let multiplier: Double
    
    public init(multiplier: Double = 1.0) {
        self.multiplier = multiplier
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(log(value)) * multiplier
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        exp(pow(10, transformedValue / multiplier))
    }
}

/// LnNormalizedFunction: Used for Ln scale
/// PostScript: {10 ln div}
/// Formula: ln(x) / (10 × ln(10))
/// Provides direct reading of natural logarithms normalized to a decade range.
public struct LnNormalizedFunction: ScaleFunction {
    public let name = "ln-normalized"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log(value) / (10 * log(10))
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        exp(transformedValue * 10 * log(10))
    }
}

// MARK: - Trigonometric Scale Functions

/// SmallTanFunction: Used for ST and SRT/KE-ST scales
/// PostScript: {radians 100 mul log}
/// Formula: log₁₀(x × π/180 × 100)
/// For small angles where tan(x) ≈ x (in radians), provides precise tangent values.
public struct SmallTanFunction: ScaleFunction {
    public let name = "small-tan"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value * .pi / 180.0 * 100.0)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue) * 180.0 / .pi / 100.0
    }
}

// MARK: - Inverse Power Scale Functions

/// AIScaleFunction: Used for AI/BI scales (inverse square scales)
/// PostScript: {100 exch div log 2 div}
/// Formula: log₁₀(100/x) / 2
/// Reciprocal of the A/B scales, reading 100/x² values directly.
public struct AIScaleFunction: ScaleFunction {
    public let name = "AI-scale"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(100.0 / value) / 2.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        100.0 / pow(10, transformedValue * 2.0)
    }
}

// MARK: - Aviation Scale Functions

/// CalibratedAirspeedFunction: Used for CAS scale
/// Formula: log₁₀((x × 22.74 + 698.7) / 1000)
/// Specialized aviation calculation for converting between indicated and calibrated airspeed.
/// The constants 22.74 and 698.7 derive from aerodynamic formulas.
public struct CalibratedAirspeedFunction: ScaleFunction {
    public let name = "calibrated-airspeed"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10((value * 22.74 + 698.7) / 1000.0)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        (pow(10, transformedValue) * 1000.0 - 698.7) / 22.74
    }
}

// MARK: - Time Conversion Scale Functions

/// TimeConversionFunction: Used for TIME and TIME2 scales
/// Formula: log₁₀(x/60) + log₁₀(6) = log₁₀(6x/60) = log₁₀(x/10)
/// Converts between minutes and hours with logarithmic spacing.
/// The formula simplifies the ratio for convenient time arithmetic.
public struct TimeConversionFunction: ScaleFunction {
    public let name = "time-conversion"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value / 60.0) + log10(6.0)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue - log10(6.0)) * 60.0
    }
}

// MARK: - Square Root Scale Functions

/// SquareRootFunction: Used for R1 (Sq1) scale
/// PostScript: {log 2 mul}
/// Formula: log₁₀(x) × 2
/// First square root scale covering √1 to √10 (1 to √10 ≈ 3.16).
/// The 2× multiplier expands the scale for precision.
public struct SquareRootFunction: ScaleFunction {
    public let name = "square-root"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value) * 2.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue / 2.0)
    }
}

/// SquareRootOffsetFunction: Used for R2 (Sq2) scale
/// PostScript: {log 2 mul} with offset {1 sub}
/// Formula: (log₁₀(x) - 1) × 2
/// Second square root scale covering √10 to √100 (√10 ≈ 3.16 to 10).
/// The offset shifts the range to continue from R1.
public struct SquareRootOffsetFunction: ScaleFunction {
    public let name = "square-root-offset"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        (log10(value) - 1.0) * 2.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue / 2.0 + 1.0)
    }
}

// MARK: - Cube Root Scale Functions

/// CubeRootFunction: Used for Q1 scale
/// PostScript: {log 3 mul}
/// Formula: log₁₀(x) × 3
/// First cube root scale covering ∛1 to ∛10 (1 to ∛10 ≈ 2.15).
/// The 3× multiplier expands the scale for precision.
public struct CubeRootFunction: ScaleFunction {
    public let name = "cube-root"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value) * 3.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue / 3.0)
    }
}

/// CubeRootOffset1Function: Used for Q2 scale
/// PostScript: {log 3 mul} with offset {1 sub}
/// Formula: (log₁₀(x) - 1) × 3
/// Second cube root scale covering ∛10 to ∛100 (∛10 ≈ 2.15 to ∛100 ≈ 4.64).
/// The offset shifts the range to continue from Q1.
public struct CubeRootOffset1Function: ScaleFunction {
    public let name = "cube-root-offset1"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        (log10(value) - 1.0) * 3.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue / 3.0 + 1.0)
    }
}

/// CubeRootOffset2Function: Used for Q3 scale
/// PostScript: {log 3 mul} with offset {2 sub}
/// Formula: (log₁₀(x) - 2) × 3
/// Third cube root scale covering ∛100 to ∛1000 (∛100 ≈ 4.64 to 10).
/// The offset shifts the range to continue from Q2.
public struct CubeRootOffset2Function: ScaleFunction {
    public let name = "cube-root-offset2"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        (log10(value) - 2.0) * 3.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue / 3.0 + 2.0)
    }
}