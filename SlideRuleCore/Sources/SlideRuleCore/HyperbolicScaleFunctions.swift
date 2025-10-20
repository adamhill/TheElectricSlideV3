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
//   {2 exp 1 sub .5 exp}     →  √(x²-1)  (.5 exp means raise to power 0.5)
//   {1 exch 2 exp sub}       →  1-x²  (exch swaps 1 and x before operations)

// MARK: - Hyperbolic Scale Functions

// MARK: - Hyperbolic Cosine Function
// PostScript: {cosh log}
// Formula: log₁₀(cosh(x))
// Used for: catenary-curves, transmission-lines, hyperbolic-geometry
public struct HyperbolicCosineFunction: ScaleFunction {
    public let name = "cosh"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(cosh(value))
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        acosh(pow(10, transformedValue))
    }
}

// MARK: - Hyperbolic Tangent Function
// PostScript: {tanh 10 mul log}
// Formula: log₁₀(10×tanh(x))
// Used for: relativity-velocity-addition, signal-processing, neural-networks
public struct HyperbolicTangentFunction: ScaleFunction {
    public let name = "tanh"
    public let multiplier: Double
    
    public init(multiplier: Double = 10.0) {
        self.multiplier = multiplier
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(tanh(value) * multiplier)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        atanh(pow(10, transformedValue) / multiplier)
    }
}

// MARK: - Hyperbolic Sine Function
// PostScript: {sinh 10 mul log}
// Formula: log₁₀(10×sinh(x-offset))
// Used for: catenary-curves, hanging-cables, special-relativity
public struct HyperbolicSineFunction: ScaleFunction {
    public let name = "sinh"
    public let multiplier: Double
    public let offset: Double
    
    public init(multiplier: Double = 10.0, offset: Double = 0.0) {
        self.multiplier = multiplier
        self.offset = offset
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(sinh(value - offset) * multiplier)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        asinh(pow(10, transformedValue) / multiplier) + offset
    }
}

// MARK: - Pythagorean/Hyperbolic Scale Functions

// MARK: - Pythagorean H Function
// PostScript (H1): {2 exp 1 sub .5 exp 10 mul log}
// PostScript (H2): {2 exp 1 sub .5 exp log}
// Formula: log₁₀(m×√(x²-1)) where m is multiplier
// Used for: pythagorean-theorem, vector-calculations, right-triangles
public struct PythagoreanHFunction: ScaleFunction {
    public let name = "pythagorean-h"
    public let multiplier: Double
    
    public init(multiplier: Double = 1.0) {
        self.multiplier = multiplier
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        let sqrtTerm = sqrt(value * value - 1.0)
        return log10(sqrtTerm * multiplier)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let sqrtValue = pow(10, transformedValue) / multiplier
        return sqrt(sqrtValue * sqrtValue + 1.0)
    }
}

// MARK: - Pythagorean P Function
// PostScript: {1 exch 2 exp sub .5 exp 10 mul log}
// Formula: log₁₀(10×√(1-x²))
// Used for: pythagorean-complement, unit-circle, trigonometric-identities
public struct PythagoreanPFunction: ScaleFunction {
    public let name = "pythagorean-p"
    public let multiplier: Double
    
    public init(multiplier: Double = 10.0) {
        self.multiplier = multiplier
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        let sqrtTerm = sqrt(1.0 - value * value)
        return log10(sqrtTerm * multiplier)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let sqrtValue = pow(10, transformedValue) / multiplier
        return sqrt(1.0 - sqrtValue * sqrtValue)
    }
}

// MARK: - Percentage/Angular Scale Functions

// MARK: - Percentage Angular Function
// PostScript: {10 sub 7.6 log 1.72 log sub 81 div mul 7.6 log exch sub}
// Formula: log₁₀(7.6) - ((x-10)×(log₁₀(7.6)-log₁₀(1.72))/81)
// Range: 9% to 91%
// Used for: percentage-calculations, angular-measurements, specialized-scales
public struct PercentageAngularFunction: ScaleFunction {
    public let name = "percentage-angular"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript formula: {10 sub 7.6 log 1.72 log sub 81 div mul 7.6 log exch sub}
        // Reading the RPN: (x-10) * (log(7.6) - log(1.72)) / 81, then log(7.6) - result
        let percentage = (value - 10.0) / 81.0  // Normalize to 0-1 range from 9-90
        let scaleFactor = log10(7.6) - log10(1.72)
        return log10(7.6) - (percentage * scaleFactor)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let scaleFactor = log10(7.6) - log10(1.72)
        let percentage = (log10(7.6) - transformedValue) / scaleFactor
        return percentage * 81.0 + 10.0
    }
}

// MARK: - Linear Degree Scales

// MARK: - Linear Degree Function
// PostScript (L360): {360 div}
// PostScript (L180): {360 div} with inverted direction
// Formula: x/maxDegrees (simple linear mapping)
// Used for: degree-measurements, circular-scales, angular-conversions
public struct LinearDegreeFunction: ScaleFunction {
    public let name = "linear-degrees"
    public let maxDegrees: Double
    
    public init(maxDegrees: Double = 360.0) {
        self.maxDegrees = maxDegrees
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        value / maxDegrees
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        transformedValue * maxDegrees
    }
}

// MARK: - Helper Functions

/// Hyperbolic cosine
private func cosh(_ x: Double) -> Double {
    (exp(x) + exp(-x)) / 2.0
}

/// Hyperbolic sine
private func sinh(_ x: Double) -> Double {
    (exp(x) - exp(-x)) / 2.0
}

/// Hyperbolic tangent
private func tanh(_ x: Double) -> Double {
    sinh(x) / cosh(x)
}

/// Inverse hyperbolic cosine
private func acosh(_ x: Double) -> Double {
    log(x + sqrt(x * x - 1.0))
}

/// Inverse hyperbolic sine
private func asinh(_ x: Double) -> Double {
    log(x + sqrt(x * x + 1.0))
}

/// Inverse hyperbolic tangent
private func atanh(_ x: Double) -> Double {
    0.5 * log((1.0 + x) / (1.0 - x))
}
