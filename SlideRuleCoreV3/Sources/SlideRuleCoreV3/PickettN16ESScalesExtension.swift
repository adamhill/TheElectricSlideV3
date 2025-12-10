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
            // FIX: Changed from 0.02 to 0.027 to match real Pickett N-16 ES slide rule
            // This offset prevents major tick marks from aligning between Lr and Cr scales
            // Real Pickett N-16 ES shows Lr starting at approximately 0.03
            .withRange(begin: 0.027, end: 200.0)  // Offset 4-decade range matching real Pickett N-16 ES
            .withLength(length)
            .withTickDirection(.down)
            // Use .absolutelyNone for major ticks so labelLevels is the sole determinant of labeling
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // PARTIAL DECADE: 0.027 to 0.1 (continues from 0.01-0.1 decade pattern)
                // Variable tick density: finest in first third, coarsest in last third
                // FIX: Scale now starts at 0.027 to match real Pickett N-16 ES
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.03→0.06: First section (finest = 0.001)
                // Major=0.01, Half=0.005, Minor=0.002, Tiny=0.001
                ScaleSubsection(startValue: 0.027, tickIntervals: [0.01, 0.005, 0.002, 0.001], labelLevels: [0]),
                
                // 0.06→0.1: Third third of decade (finest = 0.002)
                // Major=0.01, Half=0.005, Minor=0.002
                ScaleSubsection(startValue: 0.06, tickIntervals: [0.01, 0.005, 0.002], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // FULL DECADE: 0.1 to 1.0
                // Variable tick density: 20 divisions (first), 10 divisions (middle), 5 divisions (last)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.1→0.3: First third of decade (20 divisions per 0.1, finest = 0.005)
                // Major=0.1, Half=0.05, Minor=0.01, Tiny=0.005
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                
                // 0.3→0.6: Second third of decade (10 divisions per 0.1, finest = 0.01)
                // Major=0.1, Half=0.05, Minor=0.02, Tiny=0.01
                ScaleSubsection(startValue: 0.3, tickIntervals: [0.1, 0.05, 0.02, 0.01], labelLevels: [0]),
                
                // 0.6→1.0: Third third of decade (5 divisions per 0.1, finest = 0.02)
                // Major=0.1, Half=0.05, Minor=0.02
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // FULL DECADE: 1.0 to 10.0
                // Variable tick density: 20 divisions (first), 10 divisions (middle), 5 divisions (last)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 1→3: First third of decade (20 divisions per 1.0, finest = 0.05)
                // Major=1, Half=0.5, Minor=0.1, Tiny=0.05
                ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1, 0.05], labelLevels: [0]),
                
                // 3→6: Second third of decade (10 divisions per 1.0, finest = 0.1)
                // Major=1, Half=0.5, Minor=0.2, Tiny=0.1
                ScaleSubsection(startValue: 3.0, tickIntervals: [1, 0.5, 0.2, 0.1], labelLevels: [0]),
                
                // 6→10: Third third of decade (5 divisions per 1.0, finest = 0.2)
                // Major=1, Half=0.5, Minor=0.2
                ScaleSubsection(startValue: 6.0, tickIntervals: [1, 0.5, 0.2], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // FULL DECADE: 10.0 to 100.0
                // Variable tick density: 20 divisions (first), 10 divisions (middle), 5 divisions (last)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 10→30: First third of decade (20 divisions per 10, finest = 0.5)
                // Major=10, Half=5, Minor=1, Tiny=0.5
                ScaleSubsection(startValue: 10.0, tickIntervals: [10, 5, 1, 0.5], labelLevels: [0]),
                
                // 30→60: Second third of decade (10 divisions per 10, finest = 1.0)
                // Major=10, Half=5, Minor=2, Tiny=1
                ScaleSubsection(startValue: 30.0, tickIntervals: [10, 5, 2, 1], labelLevels: [0]),
                
                // 60→100: Third third of decade (5 divisions per 10, finest = 2.0)
                // Major=10, Half=5, Minor=2
                ScaleSubsection(startValue: 60.0, tickIntervals: [10, 5, 2], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // PARTIAL DECADE: 100.0 to 200.0 (continues 100-1000 decade pattern)
                // First third of decade (finest = 5)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 100→200: First third of decade (20 divisions per 100, finest = 5)
                // Major=100, Half=50, Minor=10, Tiny=5
                ScaleSubsection(startValue: 100.0, tickIntervals: [100, 50, 10, 5], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                guard value > 0 else { return "0" }
                
                if value < 1.0 {
                    // Values less than 1: leading decimal format like ".03", ".4"
                    if value >= 0.1 {
                        // 0.1 to 0.99 → ".1", ".2", ... ".9"
                        let digit = Int((value * 10).rounded())
                        return ".\(digit)"
                    } else {
                        // 0.01 to 0.099 → ".01", ".02", ... ".09"
                        let digit = Int((value * 100).rounded())
                        return ".0\(digit)"
                    }
                } else {
                    // Values >= 1: just the integer
                    return String(Int(value.rounded()))
                }
            }
            .withLabelColor(red: 0.0, green: 0.5, blue: 0.0)
            .addConstant(value: 25.12, label: "XL", style: .major)
            .addConstant(value: 26.30, label: "TL", style: .major)
            .build()
    }
    
    /// Cr - Capacitance with Reciprocal Function for resonance calculations
    /// Historical: Four-decade span (0.01 to 100)
    /// INVERTED SCALE: Values decrease from left (100) to right (0.01)
    /// Decimal keeper prevents magnitude errors across femtofarads to farads
    public static func capacitanceReciprocalScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Cr")
            .withFormula("1 - (log₁₀(x)+2)/4")
            .withFunction(CapacitanceReciprocalFunction(cycles: 4))
            .withRange(begin: 100.0, end: 0.01)  // INVERTED: 100 at position 0 (left), 0.01 at position 1 (right)
            .withLength(length)
            .withTickDirection(.up)
            // Use .absolutelyNone for major ticks so labelLevels is the sole determinant of labeling
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // INVERTED SCALE: Values decrease left-to-right (100 → 0.01)
                // Tick density pattern REVERSED from Lr: 5/10/20 (coarse→fine)
                // because left side (high values) is compressed, right side (low values) is expanded
                // ═══════════════════════════════════════════════════════════════════════
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 100 to 10 (leftmost, compressed end)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 100→60: First third of decade (5 divisions per 10 = coarse, compressed)
                // Major=10, Half=5, Minor=2
                ScaleSubsection(startValue: 100.0, tickIntervals: [10, 5, 2], labelLevels: [0]),
                
                // 60→30: Second third of decade (10 divisions per 10 = medium)
                // Major=10, Half=5, Minor=2, Tiny=1
                ScaleSubsection(startValue: 60.0, tickIntervals: [10, 5, 2, 1], labelLevels: [0]),
                
                // 30→10: Third third of decade (20 divisions per 10 = fine)
                // Major=10, Half=5, Minor=1, Tiny=0.5
                ScaleSubsection(startValue: 30.0, tickIntervals: [10, 5, 1, 0.5], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 10 to 1
                // ═══════════════════════════════════════════════════════════════════════
                
                // 10→6: First third of decade (5 divisions per 1 = coarse)
                // Major=1, Half=0.5, Minor=0.2
                ScaleSubsection(startValue: 10.0, tickIntervals: [1, 0.5, 0.2], labelLevels: [0]),
                
                // 6→3: Second third of decade (10 divisions per 1 = medium)
                // Major=1, Half=0.5, Minor=0.2, Tiny=0.1
                ScaleSubsection(startValue: 6.0, tickIntervals: [1, 0.5, 0.2, 0.1], labelLevels: [0]),
                
                // 3→1: Third third of decade (20 divisions per 1 = fine)
                // Major=1, Half=0.5, Minor=0.1, Tiny=0.05
                ScaleSubsection(startValue: 3.0, tickIntervals: [1, 0.5, 0.1, 0.05], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 1 to 0.1
                // ═══════════════════════════════════════════════════════════════════════
                
                // 1→0.6: First third of decade (5 divisions per 0.1 = coarse)
                // Major=0.1, Half=0.05, Minor=0.02
                ScaleSubsection(startValue: 1.0, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0]),
                
                // 0.6→0.3: Second third of decade (10 divisions per 0.1 = medium)
                // Major=0.1, Half=0.05, Minor=0.02, Tiny=0.01
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.1, 0.05, 0.02, 0.01], labelLevels: [0]),
                
                // 0.3→0.1: Third third of decade (20 divisions per 0.1 = fine)
                // Major=0.1, Half=0.05, Minor=0.01, Tiny=0.005
                ScaleSubsection(startValue: 0.3, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                
                // ═══════════════════════════════════════════════════════════════════════
                // DECADE: 0.1 to 0.01 (rightmost, expanded end)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 0.1→0.06: First third of decade (5 divisions per 0.01 = coarse)
                // Major=0.01, Half=0.005, Minor=0.002
                ScaleSubsection(startValue: 0.1, tickIntervals: [0.01, 0.005, 0.002], labelLevels: [0]),
                
                // 0.06→0.03: Second third of decade (10 divisions per 0.01 = medium)
                // Major=0.01, Half=0.005, Minor=0.002, Tiny=0.001
                ScaleSubsection(startValue: 0.06, tickIntervals: [0.01, 0.005, 0.002, 0.001], labelLevels: [0]),
                
                // 0.03→0.01: Third third of decade (20 divisions per 0.01 = fine, most expanded)
                // Major=0.01, Half=0.005, Minor=0.001, Tiny=0.0005
                ScaleSubsection(startValue: 0.03, tickIntervals: [0.01, 0.005, 0.001, 0.0005], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                guard value > 0 else { return "0" }
                
                if value < 1.0 {
                    // Values less than 1: leading decimal format like ".03", ".4"
                    if value >= 0.1 {
                        // 0.1 to 0.99 → ".1", ".2", ... ".9"
                        let digit = Int((value * 10).rounded())
                        return ".\(digit)"
                    } else {
                        // 0.01 to 0.099 → ".01", ".02", ... ".09"
                        let digit = Int((value * 100).rounded())
                        return ".0\(digit)"
                    }
                } else {
                    // Values >= 1: just the integer
                    return String(Int(value.rounded()))
                }
            }
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
    /// Sparse tick pattern matching physical Pickett N-16 ES slide rule
    ///
    /// Note: Uses `.absolutelyNone` as the major tick style so that `labelLevels`
    /// is the sole determinant of labeling. This ensures the 0.5-0.7 range
    /// has tick marks but no labels.
    public static func angularFrequencyOmegaScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("ω")
            .withFormula("log₁₀(2πf)/12")
            .withFunction(AngularFrequencyOmegaFunction(cycles: 12))
            .withRange(begin: 0.48, end: 62.0)
            .withLength(length)
            .withTickDirection(.up)
            // Use .absolutelyNone for major ticks so labelLevels: [] truly produces no labels
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
          // ═══════════════════════════════════════════════════════
            // DECADE: 0.5 to 1.0 — Tick pattern for 10ths of this decade
            // ═══════════════════════════════════════════════════════
            
            // 0.5 to 0.7: Ticks only, NO labels
            // Major=0.1, Half=0.05, Minor=0.02
            ScaleSubsection(
                startValue: 0.5,
                tickIntervals: [0.1, 0.05, 0.02],
                labelLevels: []  // NO labels
            ),
            
            // 0.7 to 1.0: Labels at .7, .8, .9
            ScaleSubsection(
                startValue: 0.7,
                tickIntervals: [0.1, 0.05, 0.02],
                labelLevels: [0]  // Label major ticks only
            ),
            
            // ═══════════════════════════════════════════════════════
            // DECADE: 1 to 10 — Intervals scale up 10×
            // Major=1.0, Half=0.5, Minor=0.1
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1, 0.02],  // Added 0.02 for finest ticks matching real Pickett N-16 ES
                labelLevels: [0]  // Label 1,2,3,4,5,6,7,8,9
            ),
            
            // ═══════════════════════════════════════════════════════
            // DECADE: 10 to 20 — Intervals scale up another 10×
            // Major=10.0, Half=5.0, Minor=1.0, Tiny=0.5, Micro=0.25
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0, 0.5,0.25],
                labelLevels: [0]  // Label 10,20,30,40,50,60
            ),

            // ═══════════════════════════════════════════════════════
            // DECADE: 10 to 20 — Intervals scale up another 10×
            // Major=10.0, Half=5.0, Minor=1.0, Tiny=0.5, Micro=0.25
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 20.0,
                tickIntervals: [10.0, 5.0, 1.0, 0.5],
                labelLevels: [0]  // Label 10,20,30,40,50,60
            ),

            // ═══════════════════════════════════════════════════════
            // DECADE: 10 to 60+ — Intervals scale up another 10×
            // Major=10.0, Half=5.0, Minor=1.0
            // ═══════════════════════════════════════════════════════
            ScaleSubsection(
                startValue: 50.0,
                tickIntervals: [10.0, 5.0, 1.0],
                labelLevels: [0]  // Label 10,20,30,40,50,60
            ),

            
        ])
        .withLabelFormatter { omega in
            guard omega > 0 else { return "" }
            
            if omega < 1.0 {
                // Format as ".7", ".8", ".9"
                let digit = Int((omega * 10).rounded())
                return ".\(digit)"
            } else if omega < 10.0 {
                // Format as "1", "2", ... "9"
                return String(Int(omega.rounded()))
            } else {
                // Format as "10", "20", ... "60"
                return String(Int(omega.rounded()))
            }
        }
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
