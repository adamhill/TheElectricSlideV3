import Foundation

// MARK: - Scale Reading Guide
//
// POSTSCRIPT SCALE IMPLEMENTATION NOTES:
// These scales implement the PostScript formulas documented in postscript-engine-for-sliderules.ps.
// Each scale definition specifies:
//   - Formula: The mathematical transformation applied
//   - Range: The input value range for the scale
//   - Physical Applications: Real-world uses
//   - Usage Examples: Step-by-step calculation procedures
//
// SCALE ALIGNMENT:
// Slide rule scales work by aligning values to perform multiplication, division,
// and function evaluation. Common operations:
//   - Multiplication: C×D scales (align hairline)
//   - Function evaluation: Read from function scale, interpret on C/D
//   - Inverse operations: Use inverted scales (CI, DI)
//
// POSTSCRIPT REFERENCES:
// - Ch scale:  Line 1048 - {cosh log}
// - Th scale:  Line 1063 - {tanh 10 mul log}
// - Sh scale:  Line 1077 - {sinh 10 mul log}
// - Sh1/Sh2:   Lines 1085-1095 - Split sinh scales
// - H1 scale:  Line 1099 - {2 exp 1 sub .5 exp 10 mul log}
// - H2 scale:  Line 1111 - {2 exp 1 sub .5 exp log}
// - P scale:   Line 1120 - {1 exch 2 exp sub .5 exp 10 mul log}
// - L360:      Line 1145 - {360 div}
// - L180:      Line 1155 - {360 div} with dual labeling
// - PA scale:  Line 1163 - Complex percentage formula

// MARK: - Hyperbolic Scales Extension

extension StandardScales {
    
    // MARK: - Ch Scale (Hyperbolic Cosine)
    
    /// Ch scale: Hyperbolic cosine scale
    /// 
    /// **PostScript Reference:** Chscale (line 1048)
    /// Formula: log₁₀(cosh(x))
    /// Range: 0 to 3
    /// Used for: catenary-curves, transmission-lines, hyperbolic-geometry
    ///
    /// **Physical Applications:**
    /// - Catenary curve: Shape of hanging cables and chains under uniform gravity
    /// - Transmission lines: Voltage/current distribution in electrical systems
    /// - Hyperbolic geometry: Non-Euclidean geometry calculations
    /// - Cable engineering: Sag calculations for suspended power lines
    ///
    /// **Example 1:** Find cosh(1.5) for catenary curve calculation
    /// 1. Locate 1.5 on Ch scale
    /// 2. Read corresponding value on C/D scale
    /// 3. Result: ≈ 2.35 (catenary shape factor)
    ///
    /// **Example 2:** Calculate cable sag for power line design
    /// 1. Determine span-to-sag ratio on C/D scale
    /// 2. Align with Ch scale reading
    /// 3. Result provides catenary coefficient for engineering calculations
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
    /// 
    /// **PostScript Reference:** Thscale (line 1063)
    /// Formula: log₁₀(10×tanh(x))
    /// Range: 0.1 to 3
    /// Used for: relativity-velocity-addition, signal-processing, neural-networks
    ///
    /// **Physical Applications:**
    /// - Special Relativity: Velocity addition β = tanh(rapidity), where β = v/c
    /// - Signal Processing: Soft limiting and saturation functions in audio
    /// - Neural Networks: Activation function for hidden layers (tanh activation)
    /// - Transmission Lines: Wave propagation in lossy media
    ///
    /// **Example 1:** Find tanh(1.5) for relativistic velocity calculation
    /// 1. Locate 1.5 on Th scale
    /// 2. Read corresponding value on C/D scale
    /// 3. Result: ≈ 0.905 (velocity as fraction of c)
    ///
    /// **Example 2:** Combine two relativistic velocities 0.6c and 0.8c
    /// 1. Convert velocities to rapidities: atanh(0.6) ≈ 0.69, atanh(0.8) ≈ 1.10
    /// 2. Add rapidities: 0.69 + 1.10 = 1.79 (using L scale or calculation)
    /// 3. Read tanh(1.79) from Th scale ≈ 0.946c (combined velocity)
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
    /// 
    /// **PostScript Reference:** Shscale (line 1077)
    /// Formula: log₁₀(10×sinh(x))
    /// Range: 0.1 to 3
    /// Used for: catenary-calculations, hanging-cables, special-relativity
    ///
    /// **Physical Applications:**
    /// - Catenary: Shape of hanging chains/cables under gravity
    /// - Transmission Lines: Current/voltage distribution in lossy systems
    /// - Special Relativity: Spacetime intervals and rapidity calculations
    /// - Suspension bridges: Cable tension and geometry analysis
    ///
    /// **Example 1:** Calculate catenary sag for a suspended cable
    /// 1. Find cable parameter a = tension/weight (e.g., 1.2)
    /// 2. Locate 1.2 on Sh scale
    /// 3. Read sinh(1.2) ≈ 1.51 on C/D scale
    /// 4. Use result to calculate vertical sag: sag = a × sinh(span/a)
    ///
    /// **Example 2:** Find sinh(0.5) for small-angle approximation
    /// 1. Locate 0.5 on Sh scale
    /// 2. Read value on C/D scale ≈ 0.521
    /// 3. Compare with linear approximation (sinh(x) ≈ x for small x)
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
    /// 
    /// **PostScript Reference:** Sh1scale (line 1085)
    /// Formula: log₁₀(10×sinh(x))
    /// Range: 0.1 to 0.90
    /// Used for: small-argument-sinh, high-precision-calculations
    ///
    /// **Split Scale Design:**
    /// Sh1/Sh2 provide extended precision by splitting the sinh function range.
    /// Sh1 covers small arguments (0.1-0.9) with high resolution for accuracy.
    /// Sh2 continues from 0.88 to 3.0, covering medium to large arguments.
    /// The overlap region (0.88-0.90) allows smooth transition between scales.
    ///
    /// **Physical Applications:**
    /// - Small-angle catenary calculations requiring high precision
    /// - Initial conditions in suspension cable design
    /// - Near-linear regime analysis (sinh(x) ≈ x for small x)
    ///
    /// **Example:** Calculate sinh(0.45) with high precision
    /// 1. Locate 0.45 on Sh1 scale
    /// 2. Read value on C/D scale ≈ 0.466
    /// 3. Use for precise catenary calculations in the near-linear region
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
    /// 
    /// **PostScript Reference:** Sh2scale (line 1090)
    /// Formula: log₁₀(10×sinh(x-1))
    /// Range: 0.88 to 3 (displayed as -0.12 to 2 after offset)
    /// Used for: extended-range-sinh, continuation-from-sh1
    ///
    /// **Offset Functionality:**
    /// The -1 offset in sinh(x-1) shifts the scale by one unit, allowing:
    /// - Continuous coverage from Sh1's endpoint
    /// - Extended range to larger arguments
    /// - Maintains logarithmic spacing for uniform precision
    ///
    /// **Physical Applications:**
    /// - Large-span catenary calculations
    /// - Extended transmission line analysis
    /// - High-velocity relativistic calculations
    ///
    /// **Example:** Calculate sinh(2.5) for large catenary span
    /// 1. Add 1 to argument: 2.5 + 1 = 3.5 (physical input)
    /// 2. Locate 3.5 on Sh2 scale (which internally computes sinh(3.5-1) = sinh(2.5))
    /// 3. Read value on C/D scale ≈ 6.05
    /// 4. Use for catenary sag calculations in long-span applications
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
    ///
    /// **PostScript Reference:** H1scale (line 1099)
    /// Formula: log₁₀(10×√(x²-1))
    /// Range: 1.005 to 1.415
    /// Used for: pythagorean-theorem, near-unity-calculations, precision-geometry
    ///
    /// **Mathematical Basis:**
    /// For a right triangle with hypotenuse x and one side = 1, the other side = √(x²-1).
    /// H1 provides high precision for near-unity hypotenuse values where the difference
    /// between sides is small, critical in precision engineering and surveying.
    ///
    /// **Physical Applications:**
    /// - Precision surveying: Small elevation changes over long distances
    /// - Optical calculations: Small-angle approximations in lens systems
    /// - Navigation: Course corrections with minimal deviation
    /// - Structural analysis: Member length calculations in trusses
    ///
    /// **Example 1:** Find the other side when hypotenuse = 1.2 and one side = 1
    /// 1. Locate 1.2 on H1 scale
    /// 2. Read √(1.2²-1) on C/D scale
    /// 3. Result: ≈ 0.663 (other side length)
    ///
    /// **Example 2:** Survey elevation change over 1000m horizontal distance
    /// 1. Slope distance measured: 1005m (hypotenuse = 1.005 ratio)
    /// 2. Locate 1.005 on H1 scale
    /// 3. Read √(1.005²-1) ≈ 0.100 on C/D scale
    /// 4. Elevation change: 0.100 × 1000m = 100m
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
    /// 
    /// **PostScript Reference:** H2scale (line 1111)
    /// Formula: log₁₀(√(x²-1))
    /// Range: 1.42 to 10
    /// Used for: pythagorean-theorem, general-geometry, distance-calculations
    ///
    /// **Mathematical Basis:**
    /// Extends H1 to larger hypotenuse values. For right triangle with hypotenuse x
    /// and one side = 1, computes √(x²-1) without the 10× multiplier of H1.
    /// Used for general-purpose Pythagorean calculations in everyday engineering.
    ///
    /// **Physical Applications:**
    /// - Construction: Diagonal bracing and rafter calculations
    /// - Navigation: Great circle distance approximations
    /// - Surveying: General slope and elevation calculations
    /// - Mechanical design: Link lengths in mechanisms
    ///
    /// **Example 1:** Find diagonal of rectangle with sides 3 and 1
    /// 1. Hypotenuse formula: √(3²+1²) = √10 ≈ 3.162
    /// 2. Using normalized form: if one side = 1, hypotenuse/side ratio = 3.162
    /// 3. Locate 3.162 on H2 scale
    /// 4. Read √(3.162²-1) = 3.0 on C/D scale (confirms the 3:1 ratio)
    ///
    /// **Example 2:** Calculate roof rafter length
    /// 1. Rise = 4m, run = 3m, so hypotenuse = 5m
    /// 2. Normalized: hypotenuse/run = 5/3 ≈ 1.667
    /// 3. Locate 1.667 on H2 scale
    /// 4. Read √(1.667²-1) ≈ 1.333 on C/D scale (rise/run ratio = 4/3)
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
    /// 
    /// **PostScript Reference:** Pscale (line 1120)
    /// Formula: log₁₀(10×√(1-x²))
    /// Range: 0 to 0.995
    /// Used for: unit-circle-calculations, trigonometric-complements, probability
    ///
    /// **Mathematical Basis:**
    /// For unit circle: if one coordinate is x, the other is √(1-x²).
    /// Also represents complementary relationships: sin²θ + cos²θ = 1.
    /// The red labeling indicates this scale's complementary nature to H scales.
    ///
    /// **Physical Applications:**
    /// - Unit circle: Converting between x and y coordinates
    /// - Trigonometry: Finding sin from cos or vice versa (sin = √(1-cos²))
    /// - Probability: Computing complementary probabilities
    /// - Quality control: Calculating acceptance/rejection rates
    ///
    /// **Example 1:** Unit circle - if x-coordinate = 0.6, find y-coordinate
    /// 1. Locate 0.6 on P scale
    /// 2. Read √(1-0.6²) on C/D scale
    /// 3. Result: 0.8 (y-coordinate on unit circle)
    /// 4. Verification: 0.6² + 0.8² = 0.36 + 0.64 = 1.0 ✓
    ///
    /// **Example 2:** Find sin(θ) given cos(θ) = 0.8
    /// 1. Locate 0.8 on P scale
    /// 2. Read √(1-0.8²) ≈ 0.6 on C/D scale
    /// 3. Result: sin(θ) = 0.6 (since sin²θ + cos²θ = 1)
    ///
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
    /// 
    /// **PostScript Reference:** L360scale (line 1145)
    /// Formula: x/360 (linear)
    /// Range: 0° to 360°
    /// Used for: angular-measurements, navigation, circular-calculations
    ///
    /// **Physical Applications:**
    /// - Navigation: Compass bearings and heading calculations
    /// - Trigonometry: Angle conversions and circular measurements
    /// - Circular motion: Angular displacement in rotational systems
    /// - Surveying: Azimuth and bearing measurements
    ///
    /// **Example 1:** Convert compass bearing to decimal position
    /// 1. Bearing: 135° (Southeast)
    /// 2. Locate 135 on L360 scale
    /// 3. Read decimal position 0.375 on C/D scale (135/360)
    /// 4. Use for circular interpolation or phase calculations
    ///
    /// **Example 2:** Calculate angular distance between two bearings
    /// 1. First bearing: 45° (Northeast)
    /// 2. Second bearing: 315° (Northwest)
    /// 3. Difference: 315° - 45° = 270° or equivalently -90° (clockwise)
    /// 4. Use L360 to convert to proportional values for calculations
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
    /// 
    /// **PostScript Reference:** L180scale (line 1155)
    /// Formula: x/360 (linear)
    /// Range: 0° to 360° (labeled as 0-180 and 360-180)
    /// Used for: protractor-readings, supplementary-angles, bidirectional-measurements
    ///
    /// **Dual Labeling System:**
    /// - Front labels: 0° to 180° (ascending) - read left to right
    /// - Back labels: 360° to 180° (descending) - read right to left
    /// - Useful for reading angles from either direction on a protractor
    /// - Automatically handles supplementary angle relationships
    ///
    /// **Physical Applications:**
    /// - Protractor readings: Direct reading from either side
    /// - Supplementary angles: θ + (180° - θ) = 180°
    /// - Bearing conversions: Converting between forward and back bearings
    /// - Angular differences: Computing angle complements
    ///
    /// **Example 1:** Read angle from both directions of a protractor
    /// 1. Measure angle from left: reads 45° on ascending scale
    /// 2. Measure same angle from right: reads 135° on descending scale
    /// 3. Verify: 45° + 135° = 180° (supplementary angles)
    ///
    /// **Example 2:** Calculate back bearing in navigation
    /// 1. Forward bearing: 75°
    /// 2. Back bearing = forward + 180° = 255° (if < 360°)
    /// 3. Or back bearing = forward - 180° (if > 180°)
    /// 4. Use L180 dual labels to quickly verify relationships
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
    /// 
    /// **PostScript Reference:** PAscale (line 1163)
    /// Formula: 10 - x - 7.6·log₁₀(x)/log₁₀(1.72) + log₁₀(7.6)
    /// Range: 9 to 91 (representing percentages and angular relationships)
    /// Used for: percentage-calculations, probability, statistical-work
    ///
    /// **Specialized Formula:**
    /// This scale has a complex logarithmic transformation that maps percentages
    /// to provide easier reading near critical values (e.g., 50%, 90%, 95%).
    /// The non-linear spacing gives better precision where it's most needed in
    /// statistical and quality control applications.
    ///
    /// **Physical Applications:**
    /// - Statistics: Confidence intervals and significance levels
    /// - Quality control: Acceptance/rejection percentages
    /// - Probability: Converting between probability values
    /// - Survey analysis: Percentage distributions and margins
    ///
    /// **Example 1:** Calculate percentage acceptance in quality control
    /// 1. Acceptance rate: 95% (high-quality threshold)
    /// 2. Locate 95 on PA scale
    /// 3. Read corresponding quality factor on C/D scale
    /// 4. Use for statistical process control calculations
    ///
    /// **Example 2:** Find complementary percentage for rejection rate
    /// 1. Acceptance: 85% (locate on PA scale)
    /// 2. Rejection: 100% - 85% = 15%
    /// 3. Locate 15 on PA scale for rejection analysis
    /// 4. Compare values for quality metrics
    ///
    /// **Example 3:** Statistical confidence intervals
    /// 1. 90% confidence level (locate on PA scale)
    /// 2. Corresponds to 5% in each tail (two-tailed test)
    /// 3. Use for hypothesis testing and interval estimation
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
