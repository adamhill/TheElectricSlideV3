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
            .withFormula("cosh x")
            .withFunction(HyperbolicCosineFunction())
            .withRange(begin: 0, end: 3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 2 decimals (from 0.1 secondary interval)
                // Mathematical: Ch scale start, cosh(0) = 1, only primary and secondary marks
                // Historical: Hyperbolic cosine scales rare on slide rules, used for catenary calculations in bridge/transmission line design
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [1.0, 0.1, 0, 0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Low Ch range where cosh changes slowly, 0.05 marks adequate
                // Historical: 0.1-0.3 region provides precision for shallow catenary curves
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0, 0.1, 0, 0.05],
                    labelLevels: [1],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Transitioning to steeper cosh curve, 0.02 marks for better precision
                // Historical: Ch scale mid-range used for moderate catenary span calculations
                ScaleSubsection(
                    startValue: 0.3,
                    tickIntervals: [0.1, 0.05, 0, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Maintains 0.02 precision through 0.4-0.5 transition
                // Historical: Tick marks without labels for visual continuity
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0.05, 0, 0.02],
                    labelLevels: [],
                    labelFormatter: nil
                ),
                // Cursor Precision: 3 decimals (from 0.01 quaternary interval)
                // Mathematical: Ch scale steepens, 0.01 marks for cosh(0.5-1) precision
                // Historical: Used for calculating cable sag in power line design
                ScaleSubsection(
                    startValue: 0.5,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.01 quaternary interval)
                // Mathematical: Upper Ch range (cosh > 1.54), maintains 0.01 precision
                // Historical: Ch scales uncommon, appeared on specialized engineering slide rules
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
            .withFormula("tanh x")
            .withFunction(HyperbolicTangentFunction(multiplier: 10.0))
            .withRange(begin: 0.1, end: 3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Th scale start, tanh changes rapidly near 0, finest marks for 0.1-0.2
                // Historical: Hyperbolic tangent for velocity addition in relativity, rare on standard rules
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Low Th range (0.2-0.4), 0.002 marks for relativistic β calculations
                // Historical: Used in special relativity for combining velocities near 0.2c
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.05, 0, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Mid Th range, tanh(0.4-0.7) for moderate velocity additions
                // Historical: Th scales on specialized physics/engineering slide rules
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.01 quaternary interval)
                // Mathematical: Upper-mid Th (0.7-1.0), tanh flattening, 0.01 marks adequate
                // Historical: 0.7-1.0 region used for high-velocity relativistic calculations
                ScaleSubsection(
                    startValue: 0.7,
                    tickIntervals: [0.1, 0, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Th approaching 1 (tanh → 1 as x → ∞), coarser 0.02 marks
                // Historical: Upper Th range for velocities approaching light speed
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: High Th range (1.5-2.0), tanh very close to 1, 0.05 marks sufficient
                // Historical: Extreme relativistic regime where tanh(x) ≈ 1 - 2e^(-2x)
                ScaleSubsection(
                    startValue: 1.5,
                    tickIntervals: [0.5, 0, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 1 decimal (from 0.5 quaternary interval)
                // Mathematical: Upper Th endpoint (2-3), tanh effectively 1, coarsest marks
                // Historical: Th scales rare above 2, used only on specialized physics slide rules
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
            .withFormula("sinh x")
            .withFunction(HyperbolicSineFunction(multiplier: 10.0))
            .withRange(begin: 0.1, end: 3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Sh scale start, sinh changes rapidly near 0, finest 0.001 marks
                // Historical: Hyperbolic sine for catenary calculations, appears on specialized engineering rules
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Low Sh range (0.2-0.4), 0.002 marks for shallow catenary precision
                // Historical: Used for cable sag calculations in transmission line design
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.05, 0, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Mid Sh range, sinh(0.4) ≈ 0.41, 0.005 marks for moderate spans
                // Historical: Sh scales rare, found on K&E physics rules and some Japanese models
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
            .withFormula("sinh x")
            .withFunction(HyperbolicSineFunction(multiplier: 10.0))
            .withRange(begin: 0.1, end: 0.90)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Sh1 split scale for extended precision, identical marks to Sh at start
                // Historical: Sh1/Sh2 split provides higher resolution for catenary work, uncommon feature
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: Sh1 mid-range (0.2-0.4), maintains finest precision for small-angle work
                // Historical: Split Sh scales found on advanced engineering rules for precision catenary calculations
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.05, 0, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Sh1 upper range approaching transition to Sh2 at 0.9
                // Historical: Sh1 ends at 0.9 with overlap region (0.88-0.9) for smooth transition to Sh2
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
            .withFormula("sinh(x-1)")
            .withFunction(HyperbolicSineFunction(multiplier: 10.0, offset: 1.0))
            .withRange(begin: 0.88, end: 3.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Sh2 start with -1 offset, overlaps Sh1 end (0.88-0.9) for continuity
                // Historical: Offset scale allows extended range while maintaining precision, advanced engineering feature
                ScaleSubsection(
                    startValue: 0.88,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Sh2 mid-range (1.0-1.5), sinh(x-1) for large catenary spans
                // Historical: Extended sinh range for long-span suspension bridges and power lines
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Upper Sh2 range, sinh increases rapidly, coarser 0.05 marks
                // Historical: Sh2 upper end (1.5-2.0) for extreme catenary calculations rare in practice
                ScaleSubsection(
                    startValue: 1.5,
                    tickIntervals: [0.5, 0, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 1 decimal (from 0.5 quaternary interval)
                // Mathematical: Sh2 endpoint (2-3), very coarse marks as sinh grows exponentially
                // Historical: Sh2 scales uncommon above 2, specialized engineering applications only
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
            .withFormula("√(x²-1)")
            .withFunction(PythagoreanHFunction(multiplier: 10.0))
            .withRange(begin: 1.005, end: 1.415)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 5 decimals (from 0.0001 quaternary interval)
                // Mathematical: H1 start near unity (√(1.005²-1) ≈ 0.1), finest marks for small Pythagorean calculations
                // Historical: H scales for precision surveying and navigation, K&E showed extreme precision near 1
                ScaleSubsection(
                    startValue: 1.005,
                    tickIntervals: [0.005, 0.001, 0.0005, 0.0001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.0002 quaternary interval)
                // Mathematical: Low H1 (1.01-1.02), √(x²-1) for small elevation changes in surveying
                // Historical: H1 precision critical for calculating height differences over long distances
                ScaleSubsection(
                    startValue: 1.01,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Mid H1 (1.02-1.05), 0.0005 marks for precision geometry
                // Historical: Used for optical calculations and small-angle navigation corrections
                ScaleSubsection(
                    startValue: 1.02,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                ),
                // Cursor Precision: 4 decimals (from 0.001 quaternary interval)
                // Mathematical: Upper-mid H1 (1.05-1.1), Pythagorean calculations for moderate angles
                // Historical: H1 range used for calculating truss member lengths in structural engineering
                ScaleSubsection(
                    startValue: 1.05,
                    tickIntervals: [0.05, 0.01, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.twoDecimals
                ),
                // Cursor Precision: 3 decimals (from 0.002 quaternary interval)
                // Mathematical: H1 approaching transition to H2 (1.1-1.2), coarser 0.002 marks
                // Historical: H1/H2 boundary around 1.4, scales complement each other for Pythagorean work
                ScaleSubsection(
                    startValue: 1.1,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.005 tertiary interval)
                // Mathematical: H1 endpoint (1.2-1.415), 0.005 marks as scale transitions to H2
                // Historical: H scales rare on slide rules, found mainly on specialized surveying models
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
            .withFormula("√(x²-1)")
            .withFunction(PythagoreanHFunction(multiplier: 1.0))
            .withRange(begin: 1.42, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 3 decimals (from 0.01 tertiary interval)
                // Mathematical: H2 start (1.4-2.0), √(x²-1) for general Pythagorean calculations
                // Historical: H2 extends H1 range, used for construction and mechanical design work
                ScaleSubsection(
                    startValue: 1.4,
                    tickIntervals: [0.1, 0.05, 0, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Mid H2 (2.0-4.0), 0.02 marks for standard geometry problems
                // Historical: H2 mid-range used for diagonal calculations in rectangular structures
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [0.5, 0.1, 0, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Upper H2 (4-10), larger hypotenuses, 0.05 marks adequate
                // Historical: H2 endpoint covers practical engineering range for Pythagorean calculations
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
        let customFormatter: @Sendable (ScaleValue) -> String = { value in
            let rounded = value.rounded()
            if abs(value - rounded) < 0.001 {
                return String(Int(rounded + 0.5))
            } else {
                return String(format: "%.3f", value)
            }
        }
        
        return ScaleBuilder()
            .withName("P")
            .withFormula("√(1-x²)")
            .withFunction(PythagoreanPFunction(multiplier: 10.0))
            .withRange(begin: 0, end: 0.995)
            .withLength(length)
            .withTickDirection(.up)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withSubsections([
                // Cursor Precision: 2 decimals (from 0.1 tertiary interval)
                // Mathematical: P scale start (0-0.2), √(1-x²) for unit circle, 0.1 marks for low values
                // Historical: P scale (Pythagorean complement) complements H scales, red labels indicate inverse relationship
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [0.2, 0, 0.1, 0],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 2 decimals (from 0.1 tertiary interval)
                // Mathematical: P transition (0.1-0.2), tick marks only for visual continuity
                // Historical: Sparse labeling strategy maintains readability while providing guidance
                ScaleSubsection(
                    startValue: 0.1,
                    tickIntervals: [0, 0, 0.1, 0],
                    labelLevels: [],
                    labelFormatter: nil
                ),
                // Cursor Precision: 2 decimals (from 0.05 quaternary interval)
                // Mathematical: Low P (0.2-0.3), √(1-x²) for small unit circle values, 0.05 marks
                // Historical: P scale used for probability calculations and quality control work
                ScaleSubsection(
                    startValue: 0.2,
                    tickIntervals: [0.1, 0, 0, 0.05],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 3 decimals (from 0.02 quaternary interval)
                // Mathematical: Mid-low P (0.3-0.4), 0.02 marks for moderate precision
                // Historical: P scale mid-range provides 3 sig figs for complementary calculations
                ScaleSubsection(
                    startValue: 0.3,
                    tickIntervals: [0.1, 0, 0, 0.02],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 3 decimals (from 0.01 quaternary interval)
                // Mathematical: Mid P (0.4-0.6), 0.01 marks for standard unit circle work
                // Historical: 0.4-0.6 range most commonly used for trigonometric complement calculations
                ScaleSubsection(
                    startValue: 0.4,
                    tickIntervals: [0.1, 0, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 4 decimals (from 0.005 quaternary interval)
                // Mathematical: Upper-mid P (0.6-0.8), increasing precision as √(1-x²) changes rapidly
                // Historical: Higher precision needed as P scale approaches critical region near 0.8
                ScaleSubsection(
                    startValue: 0.6,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 4 decimals (from 0.002 quaternary interval)
                // Mathematical: High P (0.8-0.9), √(1-x²) flattens, 0.002 marks for precision
                // Historical: 0.8-0.9 region critical for quality factors and acceptance rates
                ScaleSubsection(
                    startValue: 0.8,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 4 decimals (from 0.001 tertiary interval)
                // Mathematical: Very high P (0.9-0.95), finest marks for near-unity calculations
                // Historical: P approaching 1 requires highest precision for probability work
                ScaleSubsection(
                    startValue: 0.9,
                    tickIntervals: [0.01, 0, 0.005, 0.001],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 4 decimals (from 0.0005 quaternary interval)
                // Mathematical: Ultra-high P (0.95-0.98), extreme precision near unity
                // Historical: P scale finest region for quality control acceptance calculations
                ScaleSubsection(
                    startValue: 0.95,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 4 decimals (from 0.0002 quaternary interval)
                // Mathematical: Near-unity P (0.98-0.99), finest interval for critical calculations
                // Historical: Ultra-high precision for 99%+ confidence levels in statistics
                ScaleSubsection(
                    startValue: 0.98,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0002],
                    labelLevels: [0],
                    labelFormatter: customFormatter
                ),
                // Cursor Precision: 5 decimals (from 0.0001 quaternary interval)
                // Mathematical: P endpoint (0.99-0.995), finest marks on P scale for extreme precision
                // Historical: P scale limit near unity, used for six-sigma quality calculations
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
            .withFormula("θ° (0-360)")
            .withFunction(LinearDegreeFunction(maxDegrees: 360.0))
            .withRange(begin: 0, end: 360)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Cursor Precision: 1 decimal (from 1.0 quaternary interval)
                // Mathematical: L360 linear scale (0-360°), 1° marks for compass bearing precision
                // Historical: Linear degree scales for navigation and surveying, simpler than logarithmic scales
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
        let primaryFormatter: @Sendable (ScaleValue) -> String = { value in
            String(Int(value + 0.5))
        }
        
        // Secondary label formatter (360 - value, skip 270)
        let secondaryFormatter: @Sendable (ScaleValue) -> String = { value in
            if Int(value + 0.5) == 270 {
                return ""
            }
            return String(Int(360 - value + 0.5))
        }
        
        return ScaleBuilder()
            .withName("L180")
            .withFormula("θ° (0-180°)")
            .withFunction(LinearDegreeFunction(maxDegrees: 360.0))
            .withRange(begin: 0, end: 360)
            .withLength(length)
            .withTickDirection(.down)  // Note: inverted in PostScript
            .withSubsections([
                // Cursor Precision: 1 decimal (from 1.0 quaternary interval)
                // Mathematical: L180 first half (0-190°), linear scale with 1° marks for protractor readings
                // Historical: Dual-labeled scales for bidirectional angle measurements, protractor applications
                ScaleSubsection(
                    startValue: 0,
                    tickIntervals: [10, 0, 5, 1],
                    labelLevels: [0],
                    labelFormatter: primaryFormatter
                ),
                // Cursor Precision: 1 decimal (from 1.0 quaternary interval)
                // Mathematical: L180 second half (190-360°), complementary labels show supplementary angles
                // Historical: Reading from either direction enables quick supplementary angle verification
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
            .withFormula("10-x-7.6log₁₀(x)/log₁₀(1.72)+log₁₀(7.6)")
            .withFunction(PercentageAngularFunction())
            .withRange(begin: 9, end: 91)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                // Cursor Precision: 1 decimal (from 0.5 quaternary interval)
                // Mathematical: PA scale complex logarithmic formula, 0.5% marks for statistical precision
                // Historical: Percentage/angular scale for quality control and statistics, specialized K&E feature
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
