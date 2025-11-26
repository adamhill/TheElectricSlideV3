import Foundation

// MARK: - Cursor Value Precision Constants

/// Defines explicit tolerance constants for cursor value precision testing.
///
/// These tolerances are based on the analysis of floating-point error accumulation
/// in the scale calculation chain:
///
/// - **Standard scales** (C, D, A, B): Direct logarithmic transformations with minimal
///   error accumulation. The primary error source is in the linear interpolation
///   formula in `ScaleCalculator.value(at:on:)`.
///
/// - **Transcendental scales** (K, S, T, ST): Additional error from trigonometric
///   or cube functions. Error approximately 1e-12 from nested operations.
///
/// - **Nested transcendental scales** (LL scales): Log-log transformations with
///   multiple layers of transcendental function composition. Error approximately 1e-10.
///
/// # Usage
/// ```swift
/// let value = ScaleCalculator.value(at: position, on: cScale)
/// #expect(abs(value - expectedValue) < CursorValuePrecision.standardTolerance)
/// ```
///
/// # Implementation Reference
/// The precision calculations relate to `ScaleCalculator.swift:186`:
/// ```swift
/// let fx = fL + position * (fR - fL)
/// ```
/// This linear interpolation can accumulate floating-point errors, especially
/// when combined with transcendental function inverse transforms.
public enum CursorValuePrecision {
    
    // MARK: - Mathematical Precision Tolerances
    
    /// Standard tolerance for simple logarithmic scales (C, D, A, B, L, Ln).
    ///
    /// These scales use direct log/pow operations with minimal error accumulation.
    /// The 1e-14 tolerance accommodates:
    /// - IEEE 754 double precision (~15-17 significant digits)
    /// - One level of transcendental function (log10/pow)
    /// - Linear interpolation error
    public static let standardTolerance: Double = 1e-14
    
    /// Tolerance for scales with single transcendental functions (K, S, T, ST).
    ///
    /// These scales involve additional transcendental operations:
    /// - K scale: cube root (log/3, pow(10, 3*x))
    /// - S scale: sin/asin operations
    /// - T scale: tan/atan operations
    /// - ST scale: combined small-angle approximations
    ///
    /// Error approximately 1e-12 from:
    /// - Two levels of transcendental functions
    /// - Angular conversion (degrees ↔ radians)
    public static let transcendentalTolerance: Double = 1e-12
    
    /// Tolerance for nested transcendental functions (LL scales).
    ///
    /// LL (log-log) scales involve double logarithmic operations:
    /// - transform: log10(ln(x)) or similar
    /// - inverse: exp(pow(10, x))
    ///
    /// Error approximately 1e-10 from:
    /// - Three or more levels of transcendental functions
    /// - Exponential amplification of intermediate errors
    public static let nestedTranscendentalTolerance: Double = 1e-10
    
    // MARK: - Display Precision Tolerances
    
    /// Tolerance for display formatting verification.
    ///
    /// When verifying that formatted strings are correct, this tolerance
    /// accounts for rounding at the display precision level.
    /// For 4 decimal places (common for cursor readings), this is 5e-5
    /// to accommodate half-way rounding cases.
    public static let displayTolerance: Double = 5e-5
    
    /// Tolerance for verifying integer display values.
    ///
    /// Used when checking that a value rounds correctly to an integer
    /// for display purposes (e.g., major tick labels).
    public static let integerDisplayTolerance: Double = 0.5
    
    // MARK: - Round-Trip Precision Tolerances
    
    /// Tolerance for position → value → position round-trip tests.
    ///
    /// This verifies that the forward and inverse transformations
    /// are mathematically consistent. The tolerance is tighter than
    /// value precision because we're measuring position consistency,
    /// not value accuracy.
    public static let roundTripPositionTolerance: Double = 1e-13
    
    /// Tolerance for value → position → value round-trip tests.
    ///
    /// This is used when starting from a known value, computing its
    /// position, then computing the value at that position.
    public static let roundTripValueTolerance: Double = 1e-13
    
    // MARK: - Test Position Values
    
    /// Standard test positions across the normalized scale (0.0 to 1.0).
    ///
    /// These positions cover:
    /// - Boundaries (0.0, 1.0)
    /// - Common fractions (0.25, 0.5, 0.75)
    /// - Mathematically significant positions
    public static let standardTestPositions: [Double] = [
        0.0,            // Start boundary
        0.1,            // Early range
        0.25,           // Quarter point
        0.30103,        // log10(2) - mathematically significant
        0.4,            // Mid-low range
        0.4971498727,   // log10(π) ≈ 0.4971
        0.5,            // Midpoint
        0.6,            // Mid-high range
        0.75,           // Three-quarter point
        0.9,            // Late range
        1.0             // End boundary
    ]
    
    /// Test positions specifically for logarithmic scales that mathematically
    /// correspond to known values.
    public static let logarithmicTestPositions: [Double] = [
        0.0,                          // log10(1) = 0
        0.15051499783199059,          // log10(√2)
        0.30102999566398119,          // log10(2)
        0.4342944819032518,           // log10(e)
        0.4771212547196624,           // log10(3)
        0.4971498726941339,           // log10(π)
        0.6989700043360189,           // log10(5)
        0.8450980400142568,           // log10(7)
        1.0                           // log10(10) = 1
    ]
    
    // MARK: - Known Mathematical Values
    
    /// Known mathematical constants and their logarithms for precision testing.
    public struct KnownValues {
        /// log₁₀(2) to maximum double precision
        public static let log10_2: Double = 0.30102999566398119
        
        /// log₁₀(π) to maximum double precision  
        public static let log10_pi: Double = 0.4971498726941339
        
        /// log₁₀(e) to maximum double precision
        public static let log10_e: Double = 0.4342944819032518
        
        /// log₁₀(√2) to maximum double precision
        public static let log10_sqrt2: Double = 0.15051499783199059
        
        /// log₁₀(3) to maximum double precision
        public static let log10_3: Double = 0.4771212547196624
        
        /// log₁₀(5) to maximum double precision
        public static let log10_5: Double = 0.6989700043360189
        
        /// log₁₀(7) to maximum double precision
        public static let log10_7: Double = 0.8450980400142568
        
        /// e (Euler's number) to maximum double precision
        public static let e: Double = 2.718281828459045
        
        /// π to maximum double precision
        public static let pi: Double = 3.141592653589793
        
        /// √2 to maximum double precision
        public static let sqrt2: Double = 1.4142135623730951
    }
    
    // MARK: - Scale Category Classification
    
    /// Determines the appropriate tolerance for a given scale based on its function type.
    ///
    /// - Parameter scaleName: The name of the scale (e.g., "C", "LL3", "S")
    /// - Returns: The appropriate tolerance for precision testing
    public static func tolerance(forScale scaleName: String) -> Double {
        let upperName = scaleName.uppercased()
        
        // Nested transcendental (LL scales)
        if upperName.hasPrefix("LL") {
            return nestedTranscendentalTolerance
        }
        
        // Single transcendental (K, trig scales)
        let transcendentalScales = ["K", "S", "T", "ST", "SRT", "KE-S", "KE-T", "KE-ST"]
        if transcendentalScales.contains(upperName) || transcendentalScales.contains(where: { upperName.hasPrefix($0) }) {
            return transcendentalTolerance
        }
        
        // Standard scales
        return standardTolerance
    }
}