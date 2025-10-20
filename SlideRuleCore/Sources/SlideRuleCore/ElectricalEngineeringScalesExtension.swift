import Foundation

// MARK: - Electrical Engineering Standard Scales

/// Factory methods for creating standard EE slide rule scales
/// These scales are used for AC circuit analysis, RF engineering, and electronic design
extension StandardScales {
    
    // MARK: - Reactance Scales
    
    /// XL Scale - Inductive Reactance with dual labeling
    /// Left labels: Resistance units (mΩ to MΩ)
    /// Right labels: Time constants (µs to S)
    /// 12 cycles covering complete range for AC calculations
    public static func xlScale(length: Distance = 250.0) -> ScaleDefinition {
        let xlFunction = InductiveReactanceFunction(cycles: 12)
        let units1 = ["**", "1mΩ", "*", "**", "1Ω", "*", "**", "1kΩ", "*", "**", "1MΩ", "*", "**"]
        let units2 = ["", "mµs", "", "", "µs", "", "", "ms", "", "", "S", "", "S"]
        
        return ScaleBuilder()
            .withName("XL")
            .withFunction(xlFunction)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelColor(red: 0.0, green: 0.5, blue: 0.0) // Green for XL
            .build()
    }
    
    /// Xc Scale - Capacitive Reactance (inverted) with dual labeling
    /// Left labels: Resistance units (mΩ to MΩ)
    /// Right labels: Time constants (µs to S)
    /// 12 cycles, inverted for reciprocal reactance relationship
    public static func xcScale(length: Distance = 250.0) -> ScaleDefinition {
        let xcFunction = CapacitiveReactanceFunction(cycles: 12)
        let units1 = ["**", "1mΩ", "*", "**", "1Ω", "*", "**", "1kΩ", "*", "**", "1MΩ", "*", "100MΩ"]
        let units2 = ["", "mµs", "", "", "µs", "", "", "ms", "", "", "S", "", "S"]
        
        return ScaleBuilder()
            .withName("Xc")
            .withFunction(xcFunction)
            .withRange(begin: 100.0, end: 1.0) // Inverted range
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0) // Red for Xc
            .build()
    }
    
    // MARK: - Frequency Scales
    
    /// F Scale - Frequency scale from 0.001 Hz to 1 GHz
    /// 12 logarithmic cycles with engineering unit prefixes
    public static func fScale(length: Distance = 250.0) -> ScaleDefinition {
        let fFunction = FrequencyFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("F")
            .withFunction(fFunction)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                let units = [".001Hz", "*", "**", "1Hz", "*", "**", "1KHz", "*", "**", "1MHz", "*", "**", "1GHz"]
                let cycle = Int(log10(value))
                let index = cycle >= 0 && cycle < units.count ? cycle : 0
                let unit = units[index]
                if unit == "*" || unit == "**" {
                    return "\(Int(value.rounded()))"
                }
                return unit
            }
            .build()
    }
    
    /// Fo Scale - Frequency/Wavelength scale
    /// Shows frequency and corresponding wavelength (c = fλ)
    /// 6 cycles inverted, essential for RF and antenna work
    public static func foScale(length: Distance = 250.0) -> ScaleDefinition {
        let foFunction = FrequencyWavelengthFunction(cycles: 6)
        
        return ScaleBuilder()
            .withName("Fo")
            .withFunction(foFunction)
            .withRange(begin: 100.0, end: 1.0) // Inverted
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 5.0, tickIntervals: [5.0, 1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [5.0, 1.0, 0.2], labelLevels: [0])
            ])
            .withLabelFormatter { value in
                let wavelengths = ["3000m", "300m", "30m", "3m", "30cm", "3cm", "3mm"]
                let cycle = Int(log10(value))
                let index = cycle >= 0 && cycle < wavelengths.count ? cycle : 0
                return wavelengths[index]
            }
            .build()
    }
    
    // MARK: - Component Scales
    
    /// L Scale - Inductance from 0.001 µH to 100 H
    /// 12 logarithmic cycles for inductor selection
    public static func eeInductanceScale(length: Distance = 250.0) -> ScaleDefinition {
        let lFunction = InductanceFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("L")
            .withFunction(lFunction)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .build()
    }
    
    /// Li Scale - Inverted Inductance scale
    /// Same range as L but inverted, with TL/XL constant markers
    public static func eeInductanceInvertedScale(length: Distance = 250.0) -> ScaleDefinition {
        let lFunction = InductanceFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("Li")
            .withFunction(lFunction)
            .withRange(begin: 100.0, end: 1.0) // Inverted
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .withConstants([
                ScaleConstant(value: 4.02 / 12.0, label: "TL", style: .major),
                ScaleConstant(value: 3.98 / 12.0, label: "XL", style: .major)
            ])
            .build()
    }
    
    /// Cz Scale - Capacitance for impedance calculations
    /// Range: 1 pF to 1000 µF over 12 cycles
    public static func czScale(length: Distance = 250.0) -> ScaleDefinition {
        let czFunction = CapacitanceImpedanceFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("Cz")
            .withFunction(czFunction)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .withConstants([
                ScaleConstant(value: 8.02 / 12.0, label: "TC/fm", style: .major)
            ])
            .build()
    }
    
    /// Cf Scale - Capacitance/Frequency product scale
    /// Used for RC time constant and frequency-dependent calculations
    /// 11 cycles with special scaling
    public static func eeCapacitanceFrequencyScale(length: Distance = 250.0) -> ScaleDefinition {
        let cfFunction = CapacitanceFrequencyFunction(cycles: 11)
        
        return ScaleBuilder()
            .withName("Cf")
            .withFunction(cfFunction)
            .withRange(begin: 100.0, end: 1.0) // Inverted
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.2], labelLevels: []),
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 6.0, tickIntervals: [1.0, 0.5], labelLevels: []),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0])
            ])
            .withConstants([
                ScaleConstant(value: (5.02 / 12.0) - (log10(EEConstants.cfScaleFactor) / 12.0),
                            label: "XC", style: .major)
            ])
            .build()
    }
    
    // MARK: - Impedance and Transmission Line Scales
    
    /// Z Scale - Impedance from 1 mΩ to 100 MΩ
    /// 6 logarithmic cycles for impedance matching
    public static func zScale(length: Distance = 250.0) -> ScaleDefinition {
        let zFunction = ImpedanceFunction(cycles: 6)
        
        return ScaleBuilder()
            .withName("Z")
            .withFunction(zFunction)
            .withRange(begin: 1.0, end: 100.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 5.0, tickIntervals: [5.0, 1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [5.0, 1.0, 0.2], labelLevels: [0])
            ])
            .build()
    }
    
    /// r1 Scale - Reflection Coefficient (VSWR) scale
    /// Range: 0.5 to 50 VSWR
    /// Used for transmission line analysis and impedance matching
    public static func eeReflectionCoefficientScale(length: Distance = 250.0) -> ScaleDefinition {
        let r1Function = ReflectionCoefficientFunction()
        
        return ScaleBuilder()
            .withName("r1")
            .withFunction(r1Function)
            .withRange(begin: 0.5, end: 50.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.5, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.7, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [0.5, 0.1, 0.02], labelLevels: [0]),
                ScaleSubsection(startValue: 1.5, tickIntervals: [0.5, 0.1, 0.05], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [3.0, 1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 5.0, tickIntervals: [5.0, 1.0], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [50.0, 10.0, 5.0], labelLevels: [0]),
                ScaleSubsection(startValue: 20.0, tickIntervals: [50.0, 10.0], labelLevels: [0]),
                ScaleSubsection(startValue: 50.0, tickIntervals: [50.0], labelLevels: [0])
            ])
            .withConstants([
                ScaleConstant(value: 0.0, label: "∞", style: .major)
            ])
            .withLabelColor(red: 1.0, green: 0.0, blue: 0.0) // Red
            .build()
    }
    
    /// r2 Scale - Inverted reflection coefficient scale
    /// Mirror of r1 scale with inverted tick direction
    public static func eeReflectionCoefficient2Scale(length: Distance = 250.0) -> ScaleDefinition {
        let r2Function = ReflectionCoefficientFunction()
        
        return ScaleBuilder()
            .withName("r2")
            .withFunction(r2Function)
            .withRange(begin: 0.5, end: 50.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 0.5, tickIntervals: [0.1, 0.05, 0.01, 0.005], labelLevels: [0]),
                ScaleSubsection(startValue: 0.7, tickIntervals: [0.1, 0.05, 0.01], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [0.5, 0.1, 0.02], labelLevels: [0]),
                ScaleSubsection(startValue: 1.5, tickIntervals: [0.5, 0.1, 0.05], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 3.0, tickIntervals: [3.0, 1.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 5.0, tickIntervals: [5.0, 1.0], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [50.0, 10.0, 5.0], labelLevels: [0]),
                ScaleSubsection(startValue: 20.0, tickIntervals: [50.0, 10.0], labelLevels: [0]),
                ScaleSubsection(startValue: 50.0, tickIntervals: [50.0], labelLevels: [0])
            ])
            .withConstants([
                ScaleConstant(value: 0.0, label: "∞", style: .major)
            ])
            .build()
    }
    
    // MARK: - Power Scales
    
    /// P Scale - Power ratio scale (dB calculations)
    /// Range: 0 to 14 (power ratios)
    /// Used for gain, loss, and dB conversions
    public static func eePowerRatioScale(length: Distance = 250.0) -> ScaleDefinition {
        let pFunction = PowerRatioFunction()
        
        return ScaleBuilder()
            .withName("P")
            .withFunction(pFunction)
            .withRange(begin: 0.0, end: 14.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(startValue: 0.0, tickIntervals: [1.0], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [2.0, 1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [2.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 4.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0])
            ])
            .withLabelColor(red: 0.0, green: 0.5, blue: 0.0) // Green
            .build()
    }
    
    /// Q Scale - Inverted power ratio scale
    /// Mirror of P scale with inverted tick direction
    public static func eePowerRatioInvertedScale(length: Distance = 250.0) -> ScaleDefinition {
        let qFunction = PowerRatioFunction()
        
        return ScaleBuilder()
            .withName("Q")
            .withFunction(qFunction)
            .withRange(begin: 0.0, end: 14.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(startValue: 0.0, tickIntervals: [1.0], labelLevels: [0]),
                ScaleSubsection(startValue: 1.0, tickIntervals: [2.0, 1.0, 0.5], labelLevels: [0]),
                ScaleSubsection(startValue: 2.0, tickIntervals: [2.0, 0.2], labelLevels: [0]),
                ScaleSubsection(startValue: 4.0, tickIntervals: [1.0, 0.5, 0.1], labelLevels: [0]),
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0])
            ])
            .build()
    }
}

// MARK: - Historical Context

/*
 ELECTRICAL ENGINEERING SLIDE RULE SCALES - HISTORICAL CONTEXT
 
 These specialized scales were developed primarily in the 1940s-1960s for electronics
 engineers working on radio, radar, and communication systems. Before calculators,
 these scales enabled rapid calculations for:
 
 1. **Reactance Scales (XL, Xc)**: Calculate inductive and capacitive reactance
    - XL = 2πfL (inductive reactance in ohms)
    - Xc = 1/(2πfC) (capacitive reactance in ohms)
    - Essential for filter design and impedance matching
 
 2. **Transmission Line Scales (r1, r2)**: VSWR and reflection coefficient
    - Used with Smith charts for impedance matching
    - Critical for antenna and RF circuit design
    - VSWR (Voltage Standing Wave Ratio) indicates mismatch quality
 
 3. **Component Scales (L, C)**: Inductance and capacitance value selection
    - Helped engineers select standard component values
    - Calculate resonant frequencies: f = 1/(2π√LC)
 
 4. **Frequency/Wavelength (Fo)**: Relate frequency to wavelength
    - λ = c/f (where c ≈ 3×10⁸ m/s)
    - Essential for antenna design and RF propagation
 
 5. **Power Ratio Scales (P, Q)**: Decibel calculations
    - Convert between power ratios and dB
    - dB = 10 log₁₀(P₂/P₁)
    - Used for gain, loss, and signal strength calculations
 
 MANUFACTURERS:
 - Pickett (USA): Models N515-T, 160-ES "Electronics" rule
 - K&E (Keuffel & Esser): Model 68-1100 "Electronic" rule
 - Faber-Castell (Germany): Elektro 67/87 series
 - Aristo (Germany): Studio 87 with electronics scales
 
 These rules were standard equipment for electronics engineers until the
 mid-1970s when electronic calculators became affordable and ubiquitous.
 */
