import Foundation

// MARK: - Hyperbolic Scales Extension

extension StandardScales {
    
    // MARK: - Ch Scale (Hyperbolic Cosine)
    
    /// Ch scale: Hyperbolic cosine scale
    /// Formula: log₁₀(cosh(x))
    /// Range: 0 to 3
    /// Used for: Catenary curves, hyperbolic geometry, transmission line calculations
    ///
    /// **Physical Applications:**
    /// - Catenary curve: Shape of hanging cables and chains
    /// - Transmission lines: Voltage/current distribution
    /// - Hyperbolic geometry: Non-Euclidean geometry calculations
    ///
    /// **Example:** To find cosh(1.5):
    /// 1. Locate 1.5 on Ch scale
    /// 2. Read value on C/D scale (≈ 2.35)
    public static func chScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Ch")
            .withFunction(HyperbolicCosineFunction())
            .withRange(begin: 0, end: 3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [1.0, 0.1, 0, 0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0, 0.1, 0, 0.05],
                    labelLevels: [1],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 0.3,
                    tickIntervals: [0.1, 0.05, 0, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0.05, 0, 0.02],
                    labelLevels: [],
                    labelFormatter: nil
                ),
                ScaleSubsection(
                    startValue: 0.5,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.1, 0, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    // MARK: - Th Scale (Hyperbolic Tangent)
    
    /// Th scale: Hyperbolic tangent scale
    /// Formula: log₁₀(10×tanh(x))
    /// Range: 0.1 to 3
    /// Used for: Special relativity velocity addition, signal processing, neural network activation
    ///
    /// **Physical Applications:**
    /// - Special Relativity: Velocity addition formula β = tanh(rapidities)
    /// - Signal Processing: Soft limiting and saturation
    /// - Neural Networks: Activation functions
    ///
    /// **Example:** Velocity addition in special relativity:
    /// If two velocities are v₁ and v₂ (as fractions of c), find combined velocity
    public static func thScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Th")
            .withFunction(HyperbolicTangentFunction(multiplier: 10.0))
            .withRange(begin: 0.1, end: 3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.05, 0, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 0.7,
                    tickIntervals: [0.1, 0, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.5,
                    tickIntervals: [0.5, 0, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0, 0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    // MARK: - Sh Scale (Hyperbolic Sine)
    
    /// Sh scale: Hyperbolic sine scale
    /// Formula: log₁₀(10×sinh(x))
    /// Range: 0.1 to 3
    /// Used for: Catenary curves, hanging cable problems, special relativity
    ///
    /// **Physical Applications:**
    /// - Catenary: Shape of hanging chains/cables under gravity
    /// - Transmission Lines: Current/voltage distribution
    /// - Special Relativity: Spacetime intervals
    ///
    /// **Example:** Calculate the sag of a suspended cable
    public static func shScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sh")
            .withFunction(HyperbolicSineFunction(multiplier: 10.0))
            .withRange(begin: 0.1, end: 3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.05, 0, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    // MARK: - Sh1 and Sh2 Scales (Split Hyperbolic Sine)
    
    /// Sh1 scale: First part of hyperbolic sine scale
    /// Formula: log₁₀(10×sinh(x))
    /// Range: 0.1 to 0.90
    /// Used for: Small argument hyperbolic sine calculations
    public static func sh1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sh1")
            .withFunction(HyperbolicSineFunction(multiplier: 10.0))
            .withRange(begin: 0.1, end: 0.90)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.05, 0, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    /// Sh2 scale: Second part of hyperbolic sine scale with offset
    /// Formula: log₁₀(10×sinh(x-1))
    /// Range: 0.88 to 3 (displayed as -0.12 to 2 after offset)
    /// Used for: Extended range hyperbolic sine calculations
    public static func sh2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sh2")
            .withFunction(HyperbolicSineFunction(multiplier: 10.0, offset: 1.0))
            .withRange(begin: 0.88, end: 3.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.88,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.5,
                    tickIntervals: [0.5, 0, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0, 0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    // MARK: - H Scales (Pythagorean)
    
    /// H1 scale: Pythagorean hyperbolic scale for small values
    /// Formula: log₁₀(10×√(x²-1))
    /// Range: 1.005 to 1.415
    /// Used for: Pythagorean theorem, computing √(x²-1) for x near 1
    ///
    /// **Mathematical Basis:**
    /// For a right triangle with hypotenuse x and one side = 1, the other side = √(x²-1)
    ///
    /// **Example:** Find the other side of a right triangle with hypotenuse 1.2 and one side 1
    public static func h1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("H1")
            .withFunction(PythagoreanHFunction(multiplier: 10.0))
            .withRange(begin: 1.005, end: 1.415)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.005,
                    tickIntervals: [0.005, 0.001, 0.0005, 0.0001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                ScaleSubsection(
                    startValue: 1.01,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                ScaleSubsection(
                    startValue: 1.02,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                ScaleSubsection(
                    startValue: 1.05,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                ScaleSubsection(
                    startValue: 1.1,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.2,
                    tickIntervals: [0.1, 0.05, 0, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    /// H2 scale: Pythagorean hyperbolic scale for larger values
    /// Formula: log₁₀(√(x²-1))
    /// Range: 1.42 to 10
    /// Used for: Pythagorean theorem, computing √(x²-1) for general x
    ///
    /// **Example:** For a right triangle with hypotenuse 5 and one side 1, find other side ≈ 4.9
    public static func h2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("H2")
            .withFunction(PythagoreanHFunction(multiplier: 1.0))
            .withRange(begin: 1.42, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.4,
                    tickIntervals: [0.1, 0.05, 0, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [0.5, 0.1, 0, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    // MARK: - P Scale (Pythagorean Complement)
    
    /// P scale: Pythagorean complement scale
    /// Formula: log₁₀(10×√(1-x²))
    /// Range: 0 to 0.995
    /// Used for: Computing √(1-x²), complementary to H scales
    ///
    /// **Mathematical Basis:**
    /// For a unit circle, if one coordinate is x, the other is √(1-x²)
    /// Also used for: sin/cos relationships, percentage probability complements
    ///
    /// **Example:** If one side of a right triangle with hypotenuse 1 is 0.6, find other side
    public static func pScale(length: Distance = 250.0) -> ScaleDefinition {
        let customFormatter: (ScaleValue) -> String = { value in
            let rounded = value.rounded()
            if abs(value - rounded) < 0.001 {
                return String(Int(rounded + 0.5))
            } else {
                return String(format: "%.3f", value)
            }
        }
        
        return ScaleBuilder()
            .withName("P")
            .withFunction(PythagoreanPFunction(multiplier: 10.0))
            .withRange(begin: 0, end: 0.995)
            .withLength(length)
            .withTickDirection(.up)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [0.2, 0, 0.1, 0],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0, 0, 0.1, 0],
                    labelLevels: [],
                    labelFormatter: nil
                ),
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.1, 0, 0, 0.05],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.3,
                    tickIntervals: [0.1, 0, 0, 0.02],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.6,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.8,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.9,
                    tickIntervals: [0.01, 0, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.95,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.98,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0002],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                ScaleSubsection(
                    startValue: 0.99,
                    tickIntervals: [0.005, 0, 0.0005, 0.0001],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                )
            ])
            .build()
    }
    
    // MARK: - L360 and L180 Scales (Linear Degree Scales)
    
    /// L360 scale: Linear 360-degree scale
    /// Formula: x/360 (linear)
    /// Range: 0° to 360°
    /// Used for: Angular measurements, circular calculations, compass bearings
    ///
    /// **Applications:**
    /// - Navigation: Compass bearings
    /// - Trigonometry: Angle conversions
    /// - Circular motion: Angular displacement
    public static func l360Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("L360")
            .withFunction(LinearDegreeFunction(maxDegrees: 360.0))
            .withRange(begin: 0, end: 360)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0,
                    tickIntervals: [10, 0, 5, 1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    /// L180 scale: Linear 180-degree scale with complementary labeling
    /// Formula: x/360 (linear)
    /// Range: 0° to 360° (labeled as 0-180 and 360-180)
    /// Used for: Protractor readings, supplementary angles
    ///
    /// **Features:**
    /// - Front labels: 0° to 180° (ascending)
    /// - Back labels: 360° to 180° (descending)
    /// - Useful for reading angles from either direction
    public static func l180Scale(length: Distance = 250.0) -> ScaleDefinition {
        // Primary label formatter (0 to 180)
        let primaryFormatter: (ScaleValue) -> String = { value in
            String(Int(value + 0.5))
        }
        
        // Secondary label formatter (360 - value, skip 270)
        let secondaryFormatter: (ScaleValue) -> String = { value in
            if Int(value + 0.5) == 270 {
                return ""
            }
            return String(Int(360 - value + 0.5))
        }
        
        return ScaleBuilder()
            .withName("L180")
            .withFunction(LinearDegreeFunction(maxDegrees: 360.0))
            .withRange(begin: 0, end: 360)
            .withLength(length)
            .withTickDirection(.down)  // Note: inverted in PostScript
            .withSubsections([
                // First subsection: 0 to 190 degrees
                ScaleSubsection(
                    startValue: 0,
                    tickIntervals: [10, 0, 5, 1],
                    labelLevels: [0],
                    labelFormatter: primaryFormatter
                ),
                // Second subsection: 190 to 360 degrees with complementary labels
                ScaleSubsection(
                    startValue: 190,
                    tickIntervals: [10, 0, 5, 1],
                    labelLevels: [0, 1],  // Both primary and secondary labels
                    labelFormatter: secondaryFormatter
                )
            ])
            .build()
    }
    
    // MARK: - PA Scale (Percentage Angular)
    
    /// PA scale: Percentage/Angular scale
    /// Complex formula for percentage and angular calculations
    /// Range: 9 to 91
    /// Used for: Percentage calculations, probability, statistical work
    ///
    /// **Note:** This scale has a specialized formula that maps percentages
    /// to a logarithmic distribution for easier reading near critical values
    public static func paScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("PA")
            .withFunction(PercentageAngularFunction())
            .withRange(begin: 9, end: 91)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0,
                    tickIntervals: [5, 0, 1, 0.5],
                    labelLevels: [0],
                    labelFormatter: { value in
                        String(Int(value - 10 + 0.5))
                    }
                )
            ])
            .build()
    }
}
