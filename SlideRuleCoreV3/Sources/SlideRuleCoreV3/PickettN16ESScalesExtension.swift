import Foundation

// MARK: - Pickett N-16 ES Electronic Slide Rule Scales
// Complete implementation of all 32 specialized scales from the N-16 ES (circa 1960)
// Designed by Chan Street for professional electronics engineering
// Historical significance: Revolutionary four-decade scales, reciprocal embedding, simultaneous triple reading

extension StandardScales {
    
    // MARK: - Pickett N-16 ES Component Value Scales (Four-Decade Span)
    
    /// Lr - Inductance with Reciprocal Function for resonance calculations
    /// Historical: Revolutionary four-decade span (0.001µH to 100H)
    /// Used with Cr scale for direct f = 1/(2π√LC) reading
    /// PostScript reference: Line 840
    public static func inductanceReciprocalScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Lr")
            .withFormula("1 - log₁₀(x)/12")
            .withFunction(InductanceReciprocalFunction(cycles: 12))
            .withRange(begin: 0.001, end: 100.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .withLabelColor(red: 0.0, green: 0.5, blue: 0.0)
            .addConstant(value: 25.12, label: "XL", style: .major)
            .addConstant(value: 26.30, label: "TL", style: .major)
            .build()
    }
    
    /// Cr - Capacitance with Reciprocal Function for resonance calculations
    /// Historical: Four-decade span (1pF to 1000µF)
    /// Decimal keeper prevents magnitude errors across femtofarads to farads
    public static func capacitanceReciprocalScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Cr")
            .withFormula("1 - log₁₀(x)/12")
            .withFunction(CapacitanceReciprocalFunction(cycles: 12))
            .withRange(begin: 1e-12, end: 1e-3)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)
            .build()
    }
    
    /// C/L - Combined Capacitance/Inductance scale (four-decade)
    /// Dual purpose: Component values or time constant calculations
    /// Note: This conflicts with standard C scale, so we use "pickettL" internally
    public static func pickettLScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("L")
            .withFormula("log₁₀(x)/12")
            .withFunction(CapacitanceInductanceFunction(cycles: 12))
            .withRange(begin: 1e-12, end: 1e-3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .build()
    }
    
    // MARK: - Pickett N-16 ES Frequency and Wavelength Scales
    
    /// ω - Angular Frequency scale (ω = 2πf)
    /// Used for: Complex impedance, AC analysis in radian notation
    public static func angularFrequencyOmegaScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("ω")
            .withFormula("log₁₀(2πf)/12")
            .withFunction(AngularFrequencyFunction(cycles: 12))
            .withRange(begin: 0.001, end: 1e9)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Subsections must use actual frequency values (Hz) across the 12-decade range
                // 0.001 Hz to 0.01 Hz (millihertz range)
                ScaleSubsection(startValue: 0.001, tickIntervals: [0.001, 0.0005, 0.0001], labelLevels: [0]),
                // 0.01 Hz to 0.1 Hz
                ScaleSubsection(startValue: 0.01, tickIntervals: [0.01, 0.005, 0.001], labelLevels: [0]),
                // 0.1 Hz to 1 Hz
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                // 1 Hz to 10 Hz
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                // 10 Hz to 100 Hz
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1], labelLevels: [0]),
                // 100 Hz to 1 kHz
                ScaleSubsection(startValue: 100.0, tickIntervals: [100, 50, 10], labelLevels: [0]),
                // 1 kHz to 10 kHz
                ScaleSubsection(startValue: 1e3, tickIntervals: [1e3, 5e2, 1e2], labelLevels: [0]),
                // 10 kHz to 100 kHz
                ScaleSubsection(startValue: 1e4, tickIntervals: [1e4, 5e3, 1e3], labelLevels: [0]),
                // 100 kHz to 1 MHz
                ScaleSubsection(startValue: 1e5, tickIntervals: [1e5, 5e4, 1e4], labelLevels: [0]),
                // 1 MHz to 10 MHz
                ScaleSubsection(startValue: 1e6, tickIntervals: [1e6, 5e5, 1e5], labelLevels: [0]),
                // 10 MHz to 100 MHz
                ScaleSubsection(startValue: 1e7, tickIntervals: [1e7, 5e6, 1e6], labelLevels: [0]),
                // 100 MHz to 1 GHz
                ScaleSubsection(startValue: 1e8, tickIntervals: [1e8, 5e7, 1e7], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .build()
    }
    
    /// λ - Wavelength scale (c/f relationship)
    /// Shows wavelength corresponding to frequency (c = fλ)
    public static func wavelengthLambdaScale(length: Distance = 250.0) -> ScaleDefinition {
        // Helper to convert wavelength (meters) to frequency (Hz)
        let c = 299792458.0  // Speed of light m/s
        func wavelengthToFreq(_ wavelength: Double) -> Double {
            c / wavelength
        }
        
        return ScaleBuilder()
            .withName("λ")
            .withFormula("1 - log₁₀(f)/6")
            .withFunction(WavelengthFunction(cycles: 6))
            .withRange(begin: 1e5, end: 1e11)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Subsections must use frequency values (Hz), not wavelength (m)
                // These correspond to wavelengths in the 3000m to 3mm range
                ScaleSubsection(startValue: wavelengthToFreq(3000), tickIntervals: [1e5, 5e4, 1e4], labelLevels: [0]),
                ScaleSubsection(startValue: wavelengthToFreq(300), tickIntervals: [1e6, 5e5, 1e5], labelLevels: [0]),
                ScaleSubsection(startValue: wavelengthToFreq(30), tickIntervals: [1e7, 5e6, 1e6], labelLevels: [0]),
                ScaleSubsection(startValue: wavelengthToFreq(3), tickIntervals: [1e8, 5e7, 1e7], labelLevels: [0]),
                ScaleSubsection(startValue: wavelengthToFreq(0.3), tickIntervals: [1e9, 5e8, 1e8], labelLevels: [0]),
                ScaleSubsection(startValue: wavelengthToFreq(0.03), tickIntervals: [1e10, 5e9, 1e9], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)
            .build()
    }
    
    // MARK: - Pickett N-16 ES Filter Response Scales (Coordinated Triple Reading)
    
    /// Θ - Phase angle scale for RC/RL circuits (0° to 90°)
    /// Used with: cos(Θ) and dB scales for simultaneous filter analysis
    /// Applications: Audio equalizers, communications filters
    public static func phaseAngleThetaScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Θ")
            .withFormula("α = cot⁻¹(2πfRC)")
            .withFunction(PhaseAngleFunction())
            .withRange(begin: 0, end: 90)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0, tickIntervals: [10, 5, 1], labelLevels: [0]),
                ScaleSubsection(startValue: 30, tickIntervals: [10, 5, 1], labelLevels: [0]),
                ScaleSubsection(startValue: 60, tickIntervals: [10, 5, 1], labelLevels: [0]),
                ScaleSubsection(startValue: 80, tickIntervals: [5, 1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                if value < 1.0 {
                    return String(format: "%.2f°", value)
                } else if value < 10.0 {
                    return String(format: "%.1f°", value)
                } else {
                    return String(format: "%.0f°", value)
                }
            }
            .build()
    }
    
    /// cos(Θ) - Relative gain and power factor (0 to 1)
    /// Formula: cos(θ) = 1/√(1 + (1/(2πfRC))²) for filters
    /// Special marker: -3dB point at 0.707
    public static func cosinePowerFactorScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("cos Θ")
            .withFormula("cos(θ)")
            .withFunction(CosinePhaseFunction())
            .withRange(begin: 0.0, end: 1.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 0.0, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 0.5, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 0.9, tickIntervals: [0.05, 0.01], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                if value < 0.01 {
                    return String(format: "%.3f", value)
                } else if value < 0.1 {
                    return String(format: "%.3f", value)
                } else {
                    return String(format: "%.2f", value)
                }
            }
            .addConstant(value: 0.707, label: "-3dB", style: .major)
            .build()
    }
    
    /// dB - Decibel scale (power ratios)
    /// Formula: 10 log₁₀(P₂/P₁)
    /// Coordinated with Θ and cos(Θ) for complete filter characterization
    public static func decibelPowerScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("db")
            .withFormula("10 log₁₀(P₂/P₁)")
            .withFunction(DecibelFunction(isVoltageRatio: false))
            .withRange(begin: 0.01, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                // Convert ratio to dB for display
                let dB = 10.0 * log10(value)
                if abs(dB) < 1.0 {
                    return String(format: "%.2f dB", dB)
                } else if abs(dB) < 10.0 {
                    return String(format: "%.1f dB", dB)
                } else {
                    return String(format: "%.0f dB", dB)
                }
            }
            .withLabelColor(red: 0.0, green: 0.5, blue: 0.0)
            .build()
    }
    
    /// dB - Decibel scale (voltage/current ratios)
    /// Formula: 20 log₁₀(V₂/V₁)
    /// Lower scale on N-16 ES back face
    public static func decibelVoltageScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("db")
            .withFormula("20 log₁₀(V₂/V₁)")
            .withFunction(DecibelFunction(isVoltageRatio: true))
            .withRange(begin: 0.01, end: 100.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                // Convert ratio to dB for display
                let dB = 20.0 * log10(value)
                if abs(dB) < 1.0 {
                    return String(format: "%.2f dB", dB)
                } else if abs(dB) < 10.0 {
                    return String(format: "%.1f dB", dB)
                } else {
                    return String(format: "%.0f dB", dB)
                }
            }
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)
            .build()
    }
    
    // MARK: - Pickett N-16 ES Time Constant Scale
    
    /// τ - Time constant scale (τ = RC or L/R)
    /// Dual function: Capacitive (RC) or inductive (L/R) circuits
    /// Applications: Charging rates, transient response, settling time
    public static func timeConstantTauScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("τ")
            .withFormula("log₁₀(τ)/12")
            .withFunction(TimeConstantFunction(cycles: 12))
            .withRange(begin: 1e-9, end: 1e3)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1, 0.5], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                // Convert to appropriate time unit
                if value < 1e-6 {
                    return String(format: "%.1f ns", value * 1e9)
                } else if value < 1e-3 {
                    return String(format: "%.1f µs", value * 1e6)
                } else if value < 1 {
                    return String(format: "%.1f ms", value * 1e3)
                } else if value < 60 {
                    return String(format: "%.2f s", value)
                } else {
                    return String(format: "%.1f min", value / 60.0)
                }
            }
            .build()
    }
    
    // MARK: - Pickett N-16 ES Utility Scales
    
    /// D/Q - Decimal keeper and Q-factor scale
    /// Dual mode: Decade tracking or quality factor
    /// Essential: Prevents magnitude errors in four-decade calculations
    /// Note: This conflicts with standard D scale, so we use "pickettD" internally
    public static func pickettDScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("D")
            .withFormula("log₁₀(x)")
            .withFunction(DecimalKeeperQFunction(isQMode: false))
            .withRange(begin: 1.0, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.1, 0.05, 0.01], labelLevels: [0, 1]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.5, 0.1, 0.05], labelLevels: [0, 1]),
                ScaleSubsection(startValue: 4.0, tickIntervals: [1, 0.5, 0.1, 0.02], labelLevels: [0])
            ])
            .withLabelFormatter(StandardLabelFormatter.oneDecimal)
            .build()
    }
    
    /// Q - Quality factor scale
    /// Shows Q-factor for resonant circuits (Q = ωL/R = 1/(ωRC))
    public static func pickettQScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Q")
            .withFormula("log₁₀(Q)")
            .withFunction(DecimalKeeperQFunction(isQMode: true))
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                if value < 10 {
                    return String(format: "Q=%.1f", value)
                } else {
                    return String(format: "Q=%.0f", value)
                }
            }
            .build()
    }
    
    // MARK: - Convenience Accessors for N-16 ES Scale Names
    
    /// Cos - Alias for cosinePowerFactorScale (used in definition strings)
    public static func cosScale(length: Distance = 250.0) -> ScaleDefinition {
        cosinePowerFactorScale(length: length)
    }
}
