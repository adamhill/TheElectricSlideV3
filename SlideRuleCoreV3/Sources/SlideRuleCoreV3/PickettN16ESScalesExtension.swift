import Foundation

// MARK: - Pickett N-16 ES Electronic Scales Extension
// ============================================================================
//
// Historical Context:
// The Pickett N-16 ES (circa 1960) was designed by Chan Street as a professional-
// grade slide rule specifically for electronics engineering. The "ES" designation
// indicated the "Eye-Saver" yellow aluminum coating (5600 Angstrom wavelength)
// which reduced eye strain during extended calculations.
//
// Revolutionary Features:
// 1. Four-decade component value scales (Lr, Cr, C/L, F) - eliminated constant
//    mental decade adjustments
// 2. Reciprocal function embedding in Lr and Cr scales - enabled direct
//    resonant frequency calculation: f = 1/(2π√LC)
// 3. Simultaneous triple reading with Θ, cos(Θ), and dB scales for complete
//    filter response analysis
// 4. Decimal keeper (D/Q) scale - prevented order-of-magnitude errors
//
// This extension provides factory methods for creating all N-16 ES electronic
// scales following the ScaleBuilder pattern established in StandardScales.swift.
//
// ============================================================================

// MARK: - Pickett N-16 ES Scale Names

extension ScaleName {
    // N-16 ES specific scale names
    static let n16esLr = ScaleName(rawValue: "Lr")
    static let n16esCr = ScaleName(rawValue: "Cr")
    static let n16esCL = ScaleName(rawValue: "C/L")
    static let n16esOmega = ScaleName(rawValue: "ω")
    static let n16esLambda = ScaleName(rawValue: "λ")
    static let n16esTheta = ScaleName(rawValue: "Θ")
    static let n16esCosTheta = ScaleName(rawValue: "cos Θ")
    static let n16esDb = ScaleName(rawValue: "dB")
    static let n16esDQ = ScaleName(rawValue: "D/Q")
    static let n16esTau = ScaleName(rawValue: "τ")
}

// MARK: - Pickett N-16 ES Scale Definitions

extension StandardScales {
    
    // MARK: - Component Value Scales (Four-Decade Span)
    
    /// Lr - Inductance with reciprocal function for resonance calculations
    ///
    /// Historical: Revolutionary four-decade span (0.001 µH to 100 H)
    /// Used with Cr scale for direct f = 1/(2π√LC) reading.
    ///
    /// The reciprocal function embedding enables direct resonant frequency
    /// calculation without mental square root operations.
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Lr scale
    public static func n16esLrScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettInductanceReciprocalFunction(cycles: 12)
        
        // 12-cycle subsections with 2 active levels (3rd and 4th commented out)
        let subsections = [
            // Level 0 & 1: Primary marks at 1.0, secondary at 0.5, tertiary at 0.1
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 3.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 6.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("Lr")
            .withFormula("1/√L")
            .withFunction(function)
            .withRange(begin: 0.001, end: 100.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])  // Only 2 active levels
            .withLabelColor(red: 0.0, green: 0.5, blue: 0.0)  // Green for XL side
            .build()
    }
    
    /// Cr - Capacitance with reciprocal function for resonance calculations
    ///
    /// Historical: Four-decade span (1 pF to 1000 µF)
    /// Decimal keeper prevents magnitude errors across femtofarads to farads.
    ///
    /// Paired with Lr scale for direct resonant frequency calculation:
    /// f = 1/(2π√LC)
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Cr scale
    public static func n16esCrScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettCapacitanceReciprocalFunction(cycles: 12)
        
        // 12-cycle subsections with 2 active levels
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 3.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 6.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        // Note: Range [0.001, 100.0] is the same as Lr scale.
        // This represents normalized decade values (1-10 pattern repeated).
        // Actual capacitance is read with decade offset interpretation:
        // e.g., reading "1" could mean 1pF, 1nF, 1µF, etc. based on context.
        return ScaleBuilder()
            .withName("Cr")
            .withFormula("1/√C")
            .withFunction(function)
            .withRange(begin: 0.001, end: 100.0)  // Fixed: same as Lr for proper tick generation
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])  // Only 2 active levels
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red for Xc side
            .build()
    }
    
    /// C/L - Combined Capacitance/Inductance scale (four-decade)
    ///
    /// Dual purpose: Can represent either inductance (L) or capacitance (C)
    /// depending on the calculation context.
    ///
    /// Primary Uses:
    /// - Time constant calculations: τ = RC or τ = L/R
    /// - Reactance calculations: XL = 2πfL or Xc = 1/(2πfC)
    /// - General component value lookups
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the C/L scale
    public static func n16esClScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettCapacitanceInductanceFunction(cycles: 12)
        
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        // Note: Range [0.001, 100.0] represents normalized decade values.
        // Actual C or L values are interpreted with decade offsets based on context.
        return ScaleBuilder()
            .withName("C/L")
            .withFormula("C or L")
            .withFunction(function)
            .withRange(begin: 0.001, end: 100.0)  // Fixed: proper range for tick generation
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .build()
    }
    
    // MARK: - Frequency and Wavelength Scales
    
    /// F - Frequency scale (12-cycle logarithmic)
    ///
    /// This may reuse the existing EE frequency scale if compatible,
    /// otherwise creates a new 12-cycle version specific to N-16 ES.
    ///
    /// Range: 0.001 Hz to 1 GHz across 12 decades
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Frequency scale
    public static func n16esFrequencyScale(length: Distance = 250.0) -> ScaleDefinition {
        // Reuse existing EE frequency function which is already 12-cycle
        let function = FrequencyFunction(cycles: 12)
        
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 3.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 6.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("F")
            .withFormula("f Hz")
            .withFunction(function)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelFormatter(N16ESLabelFormatters.frequencyFormatter)
            .build()
    }
    
    /// λ - Wavelength scale (c/f relationship)
    ///
    /// Shows wavelength corresponding to frequency using c = fλ
    /// where c is the speed of light (299,792,458 m/s).
    ///
    /// Range: 3000m to 3mm wavelength (100 kHz to 100 GHz)
    ///
    /// Critical for: Antenna design, transmission lines, RF work
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Wavelength scale
    public static func n16esWavelengthScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettWavelengthFunction(cycles: 6)
        
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [5.0, 1.0, 0.2],
                // Level 2 COMMENTED: [5.0, 1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [5.0, 1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [5.0, 1.0, 0.2],
                // Level 2 COMMENTED: [5.0, 1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [5.0, 1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            )
        ]
        
        // Note: Range [0.1, 1000.0] represents normalized wavelength values.
        // For 6-cycle wavelength scale, this maps positions properly to [0,1].
        // Actual wavelength (meters) is interpreted with SI prefixes based on context.
        return ScaleBuilder()
            .withName("λ")
            .withFormula("c/f")
            .withFunction(function)
            .withRange(begin: 0.1, end: 1000.0)  // Fixed: proper range for 6-cycle scale
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red labels
            .withLabelFormatter(N16ESLabelFormatters.wavelengthFormatter)
            .build()
    }
    
    /// ω - Angular frequency scale (ω = 2πf)
    ///
    /// Used for: Complex impedance calculations, AC analysis in radian notation,
    /// transfer function evaluation, control system design.
    ///
    /// Range: mrad/s to Grad/s across 12 decades
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Angular Frequency scale
    public static func n16esOmegaScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettAngularFrequencyFunction(cycles: 12)
        
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        // Note: Range [1.0, 100.0] represents normalized decade values (2 decades).
        // The function with cycles: 12 handles the full mathematical domain (0.001 to 1e9).
        // Tick generation iterates over this 2-decade range; the scale function handles
        // the cyclic repetition across all 12 decades.
        return ScaleBuilder()
            .withName("ω")
            .withFormula("2πf")
            .withFunction(function)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .build()
    }
    
    // MARK: - Filter Response Scales (Coordinated Triple Reading)
    
    /// Θ - Phase angle scale for RC/RL circuits (0° to 90°)
    ///
    /// For RC circuits: α = cot⁻¹(2πfRC) = phase lag
    /// For RL circuits: α = tan⁻¹(2πfL/R) = phase lead
    ///
    /// Used with: cos(Θ) and dB scales for simultaneous filter analysis.
    ///
    /// Applications: Filter frequency response, audio equalizers, communications filters
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Phase Angle scale
    public static func n16esThetaScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettPhaseAngleFunction()
        
        let subsections = [
            // Low angles: fine resolution where phase changes rapidly
            ScaleSubsection(
                startValue: 0.0,
                tickIntervals: [5.0, 1.0],
                // Level 2 COMMENTED: [5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [5.0, 1.0],
                // Level 2 COMMENTED: [5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 20.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 45.0,
                tickIntervals: [15.0, 5.0, 1.0],
                // Level 2 COMMENTED: [15.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [15.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            ),
            // High angles: coarser resolution as phase flattens
            ScaleSubsection(
                startValue: 75.0,
                tickIntervals: [15.0, 5.0],
                // Level 2 COMMENTED: [15.0, 5.0, 1.0]
                // Level 3 COMMENTED: [15.0, 5.0, 1.0, 0.5]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("Θ")
            .withFormula("phase°")
            .withFunction(function)
            .withRange(begin: 0.0, end: 90.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelFormatter(N16ESLabelFormatters.angleFormatter)
            .build()
    }
    
    /// cos(Θ) - Relative gain and power factor (0 to 1)
    ///
    /// Formula: cos(θ) = 1/√(1 + (1/(2πfRC))²) for filters
    /// Also represents power factor (PF = cos(θ)) in AC power systems.
    ///
    /// Special marker: 0.707 = -3dB point (half-power frequency/cutoff)
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Cosine Phase scale
    public static func n16esCosThetaScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettCosinePhaseFunction()
        
        let subsections = [
            // Near 0: fine resolution
            ScaleSubsection(
                startValue: 0.0,
                tickIntervals: [0.1, 0.05, 0.01],
                // Level 2 COMMENTED: [0.1, 0.05, 0.01, 0.005]
                // Level 3 COMMENTED: [0.1, 0.05, 0.01, 0.005, 0.002]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 0.2,
                tickIntervals: [0.1, 0.05, 0.01],
                // Level 2 COMMENTED: [0.1, 0.05, 0.01, 0.005]
                // Level 3 COMMENTED: [0.1, 0.05, 0.01, 0.005, 0.002]
                labelLevels: [0]
            ),
            // Mid-range: moderate resolution
            ScaleSubsection(
                startValue: 0.5,
                tickIntervals: [0.1, 0.05, 0.01],
                // Level 2 COMMENTED: [0.1, 0.05, 0.01, 0.005]
                // Level 3 COMMENTED: [0.1, 0.05, 0.01, 0.005, 0.002]
                labelLevels: [0]
            ),
            // Near 1: coarser resolution
            ScaleSubsection(
                startValue: 0.8,
                tickIntervals: [0.1, 0.02],
                // Level 2 COMMENTED: [0.1, 0.05, 0.02]
                // Level 3 COMMENTED: [0.1, 0.05, 0.02, 0.01]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("cos Θ")
            .withFormula("gain")
            .withFunction(function)
            .withRange(begin: 0.0, end: 1.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .addConstant(value: 0.707, label: "-3dB", style: .medium)  // Half-power point
            .build()
    }
    
    /// dB (Power) - Decibel scale for power ratios
    ///
    /// Formula: 10 × log₁₀(P₂/P₁)
    /// Coordinated with Θ and cos(Θ) for complete filter characterization.
    ///
    /// Range: 0.01 to 100 (representing approximately -40 to +40 dB)
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Power dB scale
    public static func n16esDecibelPowerScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettDecibelFunction(isVoltageRatio: false)
        
        let subsections = [
            // Low ratios: fine dB resolution
            ScaleSubsection(
                startValue: 0.01,
                tickIntervals: [0.01, 0.005, 0.001],
                // Level 2 COMMENTED: [0.01, 0.005, 0.001, 0.0005]
                // Level 3 COMMENTED: [0.01, 0.005, 0.001, 0.0005, 0.0002]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 0.1,
                tickIntervals: [0.1, 0.05, 0.01],
                // Level 2 COMMENTED: [0.1, 0.05, 0.01, 0.005]
                // Level 3 COMMENTED: [0.1, 0.05, 0.01, 0.005, 0.002]
                labelLevels: [0]
            ),
            // Unity (0 dB) region
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            // High ratios
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("dB")
            .withFormula("10log₁₀P")
            .withFunction(function)
            .withRange(begin: 0.01, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelFormatter(N16ESLabelFormatters.decibelPowerFormatter)
            .build()
    }
    
    /// dB (Voltage) - Decibel scale for voltage/current ratios
    ///
    /// Formula: 20 × log₁₀(V₂/V₁)
    /// Lower scale on N-16 ES back face.
    ///
    /// Range: 0.01 to 100 (representing approximately -40 to +40 dB)
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Voltage dB scale
    public static func n16esDecibelVoltageScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettDecibelFunction(isVoltageRatio: true)
        
        let subsections = [
            ScaleSubsection(
                startValue: 0.01,
                tickIntervals: [0.01, 0.005, 0.001],
                // Level 2 COMMENTED: [0.01, 0.005, 0.001, 0.0005]
                // Level 3 COMMENTED: [0.01, 0.005, 0.001, 0.0005, 0.0002]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 0.1,
                tickIntervals: [0.1, 0.05, 0.01],
                // Level 2 COMMENTED: [0.1, 0.05, 0.01, 0.005]
                // Level 3 COMMENTED: [0.1, 0.05, 0.01, 0.005, 0.002]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("dBv")
            .withFormula("20log₁₀V")
            .withFunction(function)
            .withRange(begin: 0.01, end: 100.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelFormatter(N16ESLabelFormatters.decibelVoltageFormatter)
            .build()
    }
    
    // MARK: - Utility Scales
    
    /// D - Decimal keeper scale
    ///
    /// Tracks decimal magnitude (decade counter) to prevent order-of-magnitude
    /// errors when component values span multiple decades.
    ///
    /// The D mode extracts the mantissa (1-10 range) from any value.
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Decimal Keeper scale
    public static func n16esDecimalKeeperScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettDecimalKeeperQFunction(isQMode: false)
        
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0, 1]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0, 1]
            ),
            ScaleSubsection(
                startValue: 4.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("D")
            .withFormula("mantissa")
            .withFunction(function)
            .withRange(begin: 1.0, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .build()
    }
    
    /// Q - Quality factor scale
    ///
    /// Quality factor for resonant circuits:
    /// Q = ωL/R = 1/(ωRC) = (1/R)√(L/C)
    ///
    /// Higher Q means narrower bandwidth and sharper frequency response.
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Q Factor scale
    public static func n16esQFactorScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettDecimalKeeperQFunction(isQMode: true)
        
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0, 1]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0, 1]
            ),
            ScaleSubsection(
                startValue: 4.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            )
        ]
        
        return ScaleBuilder()
            .withName("Q")
            .withFormula("Q factor")
            .withFunction(function)
            .withRange(begin: 1.0, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .build()
    }
    
    // MARK: - Time Constant Scales
    
    /// τ - Time constant scale
    ///
    /// Time constant for RC and RL circuits:
    /// - RC circuits: τ = R × C
    /// - RL circuits: τ = L / R
    ///
    /// Physical Interpretation:
    /// - After time τ, circuit reaches 63.2% (1 - 1/e) of final value
    /// - After time 5τ, circuit reaches 99.3% of final value
    ///
    /// Range: nanoseconds to kiloseconds across 12 decades
    ///
    /// - Parameter length: Scale length in points (default: 250)
    /// - Returns: ScaleDefinition for the Time Constant scale
    public static func n16esTimeConstantScale(length: Distance = 250.0) -> ScaleDefinition {
        let function = PickettTimeConstantFunction(cycles: 12)
        
        let subsections = [
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                // Level 2 COMMENTED: [1.0, 0.5, 0.1, 0.05]
                // Level 3 COMMENTED: [1.0, 0.5, 0.1, 0.05, 0.02]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 2.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 3.0,
                tickIntervals: [1.0, 0.2],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 5.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: [0]
            ),
            ScaleSubsection(
                startValue: 6.0,
                tickIntervals: [1.0, 0.5],
                // Level 2 COMMENTED: [1.0, 0.5, 0.2]
                // Level 3 COMMENTED: [1.0, 0.5, 0.2, 0.1]
                labelLevels: []
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                // Level 2 COMMENTED: [10.0, 5.0, 1.0, 0.5]
                // Level 3 COMMENTED: [10.0, 5.0, 1.0, 0.5, 0.2]
                labelLevels: [0]
            )
        ]
        
        // Note: Range [1.0, 100.0] represents normalized decade values (2 decades).
        // The function with cycles: 12 handles the full mathematical domain (1e-9 to 1e3).
        // Tick generation iterates over this 2-decade range; the scale function handles
        // the cyclic repetition across all 12 decades.
        return ScaleBuilder()
            .withName("τ")
            .withFormula("RC or L/R")
            .withFunction(function)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections(subsections)
            .withDefaultTickStyles([.major, .medium])
            .withLabelFormatter(N16ESLabelFormatters.timeConstantFormatter)
            .build()
    }
}

// MARK: - N-16 ES Label Formatters

/// Label formatters specific to Pickett N-16 ES electronic scales
public enum N16ESLabelFormatters {
    
    /// Frequency scale formatter with engineering prefixes
    public static let frequencyFormatter: @Sendable (ScaleValue) -> String = { value in
        // Engineering prefixes for frequency: mHz, Hz, kHz, MHz, GHz
        let log = log10(value)
        
        // This formatter handles normalized values in 1-100 range per cycle
        // Actual frequency labels depend on the decade position
        if value >= 10 {
            return String(format: "%.0f", value)
        } else if value >= 1 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    /// Wavelength scale formatter
    public static let wavelengthFormatter: @Sendable (ScaleValue) -> String = { value in
        // Value represents frequency; wavelength = c/f
        // Show wavelength in appropriate units
        let c = 299792458.0  // Speed of light
        let wavelength = c / value
        
        if wavelength >= 1000 {
            return String(format: "%.0fkm", wavelength / 1000)
        } else if wavelength >= 1 {
            return String(format: "%.0fm", wavelength)
        } else if wavelength >= 0.01 {
            return String(format: "%.0fcm", wavelength * 100)
        } else {
            return String(format: "%.0fmm", wavelength * 1000)
        }
    }
    
    /// Time constant formatter with engineering prefixes
    public static let timeConstantFormatter: @Sendable (ScaleValue) -> String = { value in
        if value >= 1.0 {
            return String(format: "%.0fs", value)
        } else if value >= 1e-3 {
            return String(format: "%.0fms", value * 1e3)
        } else if value >= 1e-6 {
            return String(format: "%.0fµs", value * 1e6)
        } else if value >= 1e-9 {
            return String(format: "%.0fns", value * 1e9)
        } else {
            return String(format: "%.1eps", value * 1e12)
        }
    }
    
    /// Angle formatter (degrees)
    public static let angleFormatter: @Sendable (ScaleValue) -> String = { value in
        let rounded = value.rounded()
        if abs(value - rounded) < 0.1 {
            return "\(Int(rounded))°"
        } else {
            return String(format: "%.1f°", value)
        }
    }
    
    /// Decibel formatter for power ratios
    public static let decibelPowerFormatter: @Sendable (ScaleValue) -> String = { value in
        // Convert ratio to dB: 10 log₁₀(ratio)
        let dB = 10.0 * log10(value)
        if abs(dB) < 0.1 {
            return "0"
        } else if dB >= 0 {
            return String(format: "+%.0f", dB)
        } else {
            return String(format: "%.0f", dB)
        }
    }
    
    /// Decibel formatter for voltage ratios
    public static let decibelVoltageFormatter: @Sendable (ScaleValue) -> String = { value in
        // Convert ratio to dB: 20 log₁₀(ratio)
        let dB = 20.0 * log10(value)
        if abs(dB) < 0.1 {
            return "0"
        } else if dB >= 0 {
            return String(format: "+%.0f", dB)
        } else {
            return String(format: "%.0f", dB)
        }
    }
    
    /// Q factor formatter
    public static let qFactorFormatter: @Sendable (ScaleValue) -> String = { value in
        if value >= 10 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Historical Documentation

/*
 PICKETT N-16 ES ELECTRONIC SLIDE RULE - HISTORICAL CONTEXT
 
 The Pickett N-16 ES was manufactured by Pickett & Eckel, Inc. of Alhambra,
 California, and represented one of the most sophisticated specialized slide
 rules ever mass-produced.
 
 KEY INNOVATIONS:
 
 1. FOUR-DECADE COMPONENT SCALES
    Previous electronics slide rules used single-decade scales, requiring
    mental decade tracking. The N-16 ES's Lr and Cr scales spanned four
    decades (0.001 to 100 for inductance, 1pF to 1000µF for capacitance),
    dramatically reducing calculation errors.
 
 2. RECIPROCAL FUNCTION EMBEDDING
    The Lr and Cr scales incorporated the 1/√x transformation required for
    resonance calculations. This meant that f = 1/(2π√LC) could be read
    directly by aligning the L and C values - no further calculation needed.
 
 3. SIMULTANEOUS TRIPLE READING
    The Θ (phase), cos(Θ) (gain), and dB scales were designed to be read
    together at a single cursor position, giving complete filter response
    information in one operation.
 
 4. EYE-SAVER YELLOW
    The "ES" designation referred to the yellow aluminum coating at
    5600 Angstrom wavelength, which was found to reduce eye strain
    during extended calculations.
 
 TYPICAL APPLICATIONS:
 
 - Resonant Circuit Design: Tank circuits, oscillators, IF transformers
 - Filter Design: Audio crossovers, RF bandpass, high/low pass filters
 - Impedance Matching: Transmission lines, antenna matching networks
 - AC Circuit Analysis: Phase relationships, power factor, reactance
 - RF Engineering: Wavelength calculations, antenna sizing
 - Audio Engineering: Equalizer design, amplifier frequency response
 
 SCALE ARRANGEMENT (Original N-16 ES):
 
 Front Face (Top to Bottom):
 - Sh1, Sh2 (Hyperbolic sine)
 - Th (Hyperbolic tangent)
 - DF (D Folded at π)
 - CF, L, S, ST, T (Trig and log)
 - CI, C
 - D, LL3, LL2, LL1, Ln
 
 Back Face (Top to Bottom):
 - Θ, dB, D/Q (Filter response)
 - XL, Xc (Reactance)
 - C/L, F (Component/Frequency)
 - λ, ω, τ (Wavelength, Angular freq, Time constant)
 - Cr, Lr (Reciprocal component scales)
 - dBv, cos(Θ), Z (Voltage dB, gain, impedance)
 
 The N-16 ES remained in production until the mid-1970s when electronic
 calculators made slide rules obsolete for most engineering calculations.
 */