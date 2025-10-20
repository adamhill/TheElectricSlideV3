import Foundation

// MARK: - Hyperbolic Scale Functions

/// Hyperbolic cosine function for Ch scale: log₁₀(cosh(x))
/// Used for: Catenary curves, hyperbolic geometry, transmission line theory
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

/// Hyperbolic tangent function for Th scale: log₁₀(10×tanh(x))
/// Used for: Velocity addition in relativity, signal processing, neural networks
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

/// Hyperbolic sine function for Sh scale: log₁₀(10×sinh(x))
/// Used for: Catenary curves, hanging cable problems, special relativity
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

/// H scale function: log₁₀(√(x²-1))
/// Used for: Pythagorean theorem calculations, computing √(x²-1)
/// Mathematical basis: For unit circle, if radius = x, then adjacent side = √(x²-1)
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

/// P scale function: log₁₀(√(1-x²))
/// Used for: Pythagorean complement, computing √(1-x²)
/// Mathematical basis: For unit circle, if one side = x, then other side = √(1-x²)
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

/// PA scale function: Complex percentage/angular scale
/// Range: 9% to 91%, used for percentage and angular calculations
/// Formula: log₁₀(√(1-(x/100)²)) scaled to match standard C/D scales
public struct PercentageAngularFunction: ScaleFunction {
    public let name = "percentage-angular"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript formula: {10 sub 7.6 log 1.72 log sub 81 div mul 7.6 log exch sub}
        // Converted: (value - 10) * (log₁₀(7.6) - log₁₀(1.72)) / 81 + log₁₀(7.6) - ???
        // Simplified interpretation: percentage to angular scale mapping
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

/// Linear degree scale for L360 and L180 scales
/// Simple linear mapping of degrees to normalized positions
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
