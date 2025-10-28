import Foundation

// MARK: - EE Scale Reading Guide
//
// POSTSCRIPT SCALE IMPLEMENTATION NOTES:
// These scales implement the PostScript formulas documented in ElectricalEngineeringScaleFunctions.swift.
// EE scales use multi-cycle logarithmic formats for wide range coverage:
//   - 12-cycle scales: Cover 12 decades (e.g., 1 mΩ to 1 TΩ)
//   - 6-cycle scales: Cover 6 decades for impedance work
//   - Dual labeling: Shows both resistance/reactance AND time constants
//
// COMMON EE CALCULATIONS:
// - Reactance: XL = 2πfL, Xc = 1/(2πfC)
// - Resonance: f = 1/(2π√LC)
// - Impedance: Z = √(R² + X²)
// - VSWR/Reflection: ρ = (VSWR-1)/(VSWR+1)
// - Power ratios: dB = 10 log₁₀(P₂/P₁)
//
// SCALE PAIRING:
// - XL + F → inductance L
// - Xc + F → capacitance C
// - r1 + r2 → impedance matching calculations
// - P + Q → dB conversions
//
// POSTSCRIPT REFERENCES:
// - XL scale:  Line 755 - Inductive reactance with dual labeling
// - Xc scale:  Line 787 - Capacitive reactance (inverted)
// - F scale:   Line 805 - Frequency scale (12 cycles)
// - Fo scale:  Line 1003 - Frequency/wavelength scale
// - L scale:   Line 823 - Inductance scale
// - Li scale:  Line 840 - Inverted inductance with constants
// - Cz scale:  Line 934 - Capacitance for impedance
// - Cf scale:  Line 959 - Capacitance/frequency product
// - Z scale:   Line 913 - Impedance scale (6 cycles)
// - r1 scale:  Line 862 - Reflection coefficient (VSWR)
// - r2 scale:  Line 883 - Inverted reflection coefficient
// - P scale:   Line 891 - Power ratio (dB)
// - Q scale:   Line 903 - Inverted power ratio

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
        // TODO: Implement dual unit labeling for Resistance (mΩ to MΩ) and Time constants (µs to S)
        // let units1 = ["**", "1mΩ", "*", "**", "1Ω", "*", "**", "1kΩ", "*", "**", "1MΩ", "*", "**"]
        // let units2 = ["", "mµs", "", "", "µs", "", "", "ms", "", "", "S", "", "S"]
        
        return ScaleBuilder()
            .withName("XL")
            .withFormula("ωL")
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
    /// Range: 100.0 to 1.0 (inverted for reciprocal relationship)
    /// Used for: AC-circuit-analysis, filter-design, impedance-matching, capacitor-selection
    ///
    /// **Physical Applications:**
    /// - Filter Design: Calculate capacitor reactance for high-pass and band-pass filters
    /// - Impedance Matching: Design matching networks for RF amplifiers
    /// - AC Circuit Analysis: Find capacitive component of impedance
    /// - Coupling Networks: Calculate coupling capacitor values
    /// - Tuning Circuits: Design variable capacitor tuning ranges
    /// - Bypass Capacitors: Select values for power supply decoupling
    ///
    /// **Example 1:** Find reactance of 1µF capacitor at 1kHz
    /// 1. Locate 1kHz on F scale
    /// 2. Align with 1µF on Cf scale
    /// 3. Read Xc scale: ≈ 159Ω (1/(2π × 1kHz × 1µF))
    ///
    /// **Example 2:** Design high-pass filter with fc = 100Hz, Z = 10kΩ
    /// 1. Calculate required C = 1/(2πfcZ) = 159nF
    /// 2. Verify: 100Hz on F + 159nF on Cf → 10kΩ on Xc
    /// 3. Use standard 150nF capacitor (closest E12 value)
    public static func xcScale(length: Distance = 250.0) -> ScaleDefinition {
        let xcFunction = CapacitiveReactanceFunction(cycles: 12)
        // TODO: Implement dual unit labeling for Resistance (mΩ to MΩ) and Time constants (µs to S)
        // let units1 = ["**", "1mΩ", "*", "**", "1Ω", "*", "**", "1kΩ", "*", "**", "1MΩ", "*", "100MΩ"]
        // let units2 = ["", "mµs", "", "", "µs", "", "", "ms", "", "", "S", "", "S"]
        
        return ScaleBuilder()
            .withName("Xc")
            .withFormula("1/(ωC)")
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
    
    /// F Scale: Frequency scale from 0.001 Hz to 1 GHz
    /// 12 logarithmic cycles with engineering unit prefixes
    /// **PostScript Reference:** eeFscale (line 805)
    /// Formula: log₁₀(f) over 12 logarithmic cycles
    /// Range: 1.0 to 100.0 per cycle (covers 0.001 Hz to 1 GHz)
    /// Used for: frequency-selection, filter-design, resonance-calculations, RF-design
    ///
    /// **Physical Applications:**
    /// - Audio Engineering: 20 Hz to 20 kHz range for audio circuits
    /// - RF Design: MHz to GHz range for radio and wireless systems
    /// - Filter Design: Determine cutoff and resonant frequencies
    /// - Signal Processing: Analyze frequency response of circuits
    /// - Power Systems: 50/60 Hz industrial frequency calculations
    /// - Medical Electronics: Sub-Hz to kHz for biometric signals
    ///
    /// **Example 1:** Calculate resonant frequency for LC tank circuit
    /// 1. Given: L = 10µH, C = 100pF
    /// 2. f = 1/(2π√LC) = 5.03 MHz
    /// 3. Locate on F scale for impedance calculations
    ///
    /// **Example 2:** Design audio crossover at 2.5kHz
    /// 1. Locate 2.5kHz on F scale
    /// 2. Use with L or C scales to calculate component values
    /// 3. Verify frequency response across audio spectrum
    public static func fScale(length: Distance = 250.0) -> ScaleDefinition {
        let fFunction = FrequencyFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("F")
            .withFormula("log₁₀ f")
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
    
    /// Fo Scale: Frequency/Wavelength scale
    /// Shows frequency and corresponding wavelength (c = fλ)
    /// 6 cycles inverted, essential for RF and antenna work
    /// Formula: log₁₀(f) with wavelength labeling (λ = c/f)
    /// Range: 100.0 to 1.0 (inverted, 6 cycles)
    /// Used for: antenna-design, RF-propagation, wavelength-calculations, electromagnetic-theory
    ///
    /// **Physical Applications:**
    /// - Antenna Design: Calculate antenna dimensions from frequency (λ/4, λ/2 antennas)
    /// - RF Propagation: Relate frequency to wavelength for path loss calculations
    /// - Microwave Engineering: Design waveguides and resonant cavities
    /// - Radar Systems: Determine optimal frequency for target detection
    /// - Radio Broadcasting: Match antenna size to broadcast frequency
    /// - Satellite Communications: Calculate free-space path loss
    ///
    /// **Example 1:** Design quarter-wave antenna for 100 MHz FM station
    /// 1. Locate 100 MHz on Fo scale
    /// 2. Read wavelength: λ = 3m
    /// 3. Quarter-wave length = 3m/4 = 75cm
    ///
    /// **Example 2:** Calculate wavelength for 2.4 GHz WiFi
    /// 1. Locate 2.4 GHz on Fo scale
    /// 2. Read wavelength: λ ≈ 12.5cm
    /// 3. Use for antenna design and Fresnel zone calculations
    public static func foScale(length: Distance = 250.0) -> ScaleDefinition {
        let foFunction = FrequencyWavelengthFunction(cycles: 6)
        
        return ScaleBuilder()
            .withName("Fo")
            .withFormula("c/f")
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
    /// **PostScript Reference:** eeLscale (line 823)
    /// Formula: log₁₀(L) over 12 logarithmic cycles
    /// Range: 1.0 to 100.0 per cycle (covers 0.001 µH to 100 H)
    /// Used for: inductor-selection, filter-design, resonance-calculations, transformer-design
    ///
    /// **Physical Applications:**
    /// - RF Coils: nH to µH range for high-frequency circuits
    /// - Audio Inductors: mH range for speaker crossovers and filters
    /// - Power Supplies: mH to H range for energy storage chokes
    /// - Resonant Circuits: Calculate LC combinations for oscillators
    /// - Impedance Matching: Design L-network matching circuits
    /// - EMI Filters: Select common-mode and differential-mode chokes
    ///
    /// **Example 1:** Select inductor for 455 kHz IF transformer
    /// 1. Target reactance: XL = 1kΩ at 455 kHz
    /// 2. Calculate: L = XL/(2πf) = 350 µH
    /// 3. Locate 350 µH on L scale, verify on XL scale
    ///
    /// **Example 2:** Design LC filter with fc = 1 MHz, using C = 100pF
    /// 1. Calculate: L = 1/(4π²f²C) = 253 µH
    /// 2. Locate 253 µH on L scale
    /// 3. Verify resonance: F scale reading should be 1 MHz
    public static func eeInductanceScale(length: Distance = 250.0) -> ScaleDefinition {
        let lFunction = InductanceFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("L")
            .withFormula("log₁₀ L")
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
    /// **PostScript Reference:** eeLiscale (line 840)
    /// Formula: log₁₀(L) over 12 cycles (inverted range)
    /// Range: 100.0 to 1.0 (inverted for reciprocal calculations)
    /// Used for: reciprocal-inductance, Q-factor-calculations, time-constant-analysis
    ///
    /// **Constant Markers:**
    /// - TL marker: Transmission line characteristic
    /// - XL marker: Reactance reference point
    /// These constants facilitate rapid calculations involving inductance ratios.
    ///
    /// **Physical Applications:**
    /// - Q Factor Analysis: Calculate inductor quality factor Q = XL/R
    /// - Time Constants: Compute L/R time constants for RL circuits
    /// - Transformer Ratios: Calculate turns ratios from inductance ratios
    /// - Energy Storage: Relate energy (½LI²) to inductance
    /// - Impedance Transformation: Design matching networks
    /// - Filter Alignment: Adjust component values for desired response
    ///
    /// **Example 1:** Calculate Q factor of inductor
    /// 1. Given: L = 100 µH, R = 10Ω at f = 1 MHz
    /// 2. XL = 2πfL = 628Ω
    /// 3. Q = XL/R = 62.8 (use Li scale with resistance ratio)
    ///
    /// **Example 2:** Find L/R time constant
    /// 1. Given: L = 10 mH, R = 100Ω
    /// 2. τ = L/R = 100 µs
    /// 3. Use Li scale to verify ratio calculations
    public static func eeInductanceInvertedScale(length: Distance = 250.0) -> ScaleDefinition {
        let lFunction = InductanceFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("Li")
            .withFormula("log₁₀(1/L)")
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
    /// **PostScript Reference:** eeCzscale (line 934)
    /// Formula: log₁₀(C) over 12 logarithmic cycles
    /// Range: 1.0 to 100.0 per cycle (covers 1 pF to 1000 µF)
    /// Used for: capacitor-selection, filter-design, impedance-matching, energy-storage
    ///
    /// **Constant Markers:**
    /// - TC/fm marker: Time constant per frequency multiplier reference
    /// Used for rapid RC time constant calculations in frequency domain.
    ///
    /// **Physical Applications:**
    /// - Coupling Capacitors: Select values for AC coupling in amplifiers
    /// - Bypass Capacitors: Calculate values for power supply decoupling
    /// - Timing Circuits: Design RC oscillators and timers
    /// - Filter Design: Calculate capacitor values for active filters
    /// - Impedance Matching: Design capacitive matching networks
    /// - Energy Storage: Size capacitors for power delivery
    ///
    /// **Example 1:** Select coupling capacitor for 100 Hz cutoff
    /// 1. Given: Source impedance Z = 10kΩ
    /// 2. Calculate: C = 1/(2πfZ) = 159 nF
    /// 3. Locate 159 nF on Cz scale, verify on Xc scale
    ///
    /// **Example 2:** Design bypass capacitor for 1 MHz noise suppression
    /// 1. Target impedance: 1Ω at 1 MHz
    /// 2. Calculate: C = 1/(2πfZ) = 159 nF
    /// 3. Use standard 150 nF or 180 nF capacitor
    public static func czScale(length: Distance = 250.0) -> ScaleDefinition {
        let czFunction = CapacitanceImpedanceFunction(cycles: 12)
        
        return ScaleBuilder()
            .withName("Cz")
            .withFormula("log₁₀ C")
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
    /// Formula: log₁₀(C·f) over 11 cycles (inverted)
    /// Range: 100.0 to 1.0 (inverted for reciprocal calculations)
    /// Used for: RC-time-constants, filter-design, phase-shift-calculations, timing-circuits
    ///
    /// **Constant Markers:**
    /// - XC marker: Capacitive reactance reference point
    /// Facilitates rapid calculation of capacitive reactance from C·f product.
    ///
    /// **Physical Applications:**
    /// - RC Time Constants: Calculate τ = RC for timing circuits
    /// - Phase Shift Networks: Design audio phase shift oscillators
    /// - Filter Alignment: Adjust cutoff frequency with component changes
    /// - Impedance Calculations: Rapid Xc calculations
    /// - Oscillator Design: Calculate frequency-determining components
    /// - Signal Delay: Design RC delay networks
    ///
    /// **Example 1:** Calculate RC time constant for 555 timer
    /// 1. Given: R = 10kΩ, C = 10µF
    /// 2. τ = RC = 100 ms
    /// 3. Period T = 1.1RC = 110 ms (astable mode)
    ///
    /// **Example 2:** Design phase shift oscillator at 1 kHz
    /// 1. Three RC stages: f = 1/(2π√6·RC)
    /// 2. For C = 100nF: R = 650Ω
    /// 3. Use Cf scale to verify frequency response
    public static func eeCapacitanceFrequencyScale(length: Distance = 250.0) -> ScaleDefinition {
        let cfFunction = CapacitanceFrequencyFunction(cycles: 11)
        
        return ScaleBuilder()
            .withName("Cf")
            .withFormula("log₁₀(C·f)")
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
    /// **PostScript Reference:** eeZscale (line 913)
    /// Formula: log₁₀(Z) over 6 logarithmic cycles
    /// Range: 1.0 to 100.0 per cycle (covers 1 mΩ to 100 MΩ)
    /// Used for: impedance-matching, transmission-lines, antenna-impedance, circuit-analysis
    ///
    /// **Physical Applications:**
    /// - Transmission Lines: Match source and load impedances (typically 50Ω or 75Ω)
    /// - Antenna Systems: Calculate antenna feed point impedance
    /// - Audio Systems: Match amplifier output to speaker impedance (4Ω, 8Ω, 16Ω)
    /// - RF Circuits: Design impedance matching networks
    /// - Power Distribution: Calculate line impedances for voltage drop
    /// - EMI/EMC: Determine shielding effectiveness and grounding impedances
    ///
    /// **Example 1:** Design L-network to match 50Ω to 200Ω
    /// 1. Impedance ratio: 200Ω/50Ω = 4
    /// 2. Q = √(ratio - 1) = √3 ≈ 1.73
    /// 3. Use Z scale to calculate series/parallel components
    ///
    /// **Example 2:** Calculate transmission line characteristic impedance
    /// 1. Given: Zo = √(L/C) for lossless line
    /// 2. For 50Ω coax: locate on Z scale
    /// 3. Verify impedance matching for minimum VSWR
    public static func zScale(length: Distance = 250.0) -> ScaleDefinition {
        let zFunction = ImpedanceFunction(cycles: 6)
        
        return ScaleBuilder()
            .withName("Z")
            .withFormula("log₁₀ Z")
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
    /// Formula: (0.5/ρ) × 0.472 where ρ is reflection coefficient
    /// Range: 0.5 to 50 (VSWR)
    /// Used for: transmission-line-analysis, antenna-matching, RF-measurements, VSWR-calculations
    ///
    /// **Constant Markers:**
    /// - ∞ marker: Indicates infinite VSWR (total reflection)
    /// Critical reference point for impedance matching quality assessment.
    ///
    /// **Physical Applications:**
    /// - Antenna Matching: Measure and minimize VSWR for maximum power transfer
    /// - Transmission Lines: Calculate reflected power and transmission efficiency
    /// - Smith Chart Work: Convert between VSWR and reflection coefficient
    /// - Cable Testing: Verify impedance match quality and locate faults
    /// - RF Amplifier Design: Ensure stability and prevent oscillation
    /// - Network Analyzer Calibration: Interpret S-parameter measurements
    ///
    /// **Example 1:** Convert VSWR 2.0 to reflection coefficient
    /// 1. Locate 2.0 on r1 scale
    /// 2. Calculate ρ = (VSWR-1)/(VSWR+1) = (2-1)/(2+1) = 0.333
    /// 3. Reflected power = ρ² = 11.1% of incident power
    ///
    /// **Example 2:** Find return loss for VSWR 1.5
    /// 1. Locate 1.5 on r1 scale
    /// 2. ρ = (1.5-1)/(1.5+1) = 0.2
    /// 3. Return Loss = -20 log₁₀(ρ) ≈ 14 dB
    /// 4. 96% of power transmitted (excellent match)
    public static func eeReflectionCoefficientScale(length: Distance = 250.0) -> ScaleDefinition {
        let r1Function = ReflectionCoefficientFunction()
        
        return ScaleBuilder()
            .withName("r1")
            .withFormula("VSWR")
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
    /// **PostScript Reference:** eer2scale (line 883)
    /// Formula: (0.5/ρ) × 0.472 where ρ is reflection coefficient (inverted)
    /// Range: 0.5 to 50 (VSWR, inverted tick direction)
    /// Used for: transmission-line-analysis, impedance-matching, reciprocal-VSWR-calculations
    ///
    /// **Constant Markers:**
    /// - ∞ marker: Indicates infinite VSWR reference point
    /// Mirror of r1 scale for complementary calculations.
    ///
    /// **Physical Applications:**
    /// - Bidirectional Measurements: Measure forward and reverse VSWR
    /// - Network Analysis: Calculate input and output match simultaneously
    /// - Smith Chart Operations: Perform impedance transformations
    /// - Cable Analysis: Identify mismatches from both directions
    /// - Filter Design: Analyze input and output impedances
    /// - Antenna Systems: Compare feed line and antenna VSWR
    ///
    /// **Example 1:** Calculate total VSWR with cascaded mismatches
    /// 1. Source VSWR = 1.2 (from r1 scale)
    /// 2. Load VSWR = 1.5 (from r2 scale)
    /// 3. Combined effect analyzed using both scales
    ///
    /// **Example 2:** Verify reciprocal matching network
    /// 1. Forward VSWR on r1: 1.3
    /// 2. Reverse VSWR on r2: should also be 1.3 for symmetric network
    /// 3. Compare readings to verify network symmetry
    public static func eeReflectionCoefficient2Scale(length: Distance = 250.0) -> ScaleDefinition {
        let r2Function = ReflectionCoefficientFunction()
        
        return ScaleBuilder()
            .withName("r2")
            .withFormula("1/VSWR")
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
    /// Formula: 10 log₁₀(P₂/P₁)
    /// Range: 0 to 14 (power ratios from 1 to ~25)
    /// Used for: gain-calculations, loss-measurements, dB-conversions, signal-strength
    ///
    /// **Physical Applications:**
    /// - Amplifier Gain: Calculate power gain in dB (e.g., +20 dB = 100× power)
    /// - Attenuation: Measure signal loss in cables and filters
    /// - Link Budget Analysis: Calculate total system gain/loss in communication links
    /// - Audio Engineering: Measure sound pressure levels and acoustic power
    /// - Antenna Gain: Express directivity and efficiency in dBi or dBd
    /// - Optical Power: Calculate fiber optic link budgets in dB
    ///
    /// **Example 1:** Calculate amplifier gain in dB
    /// 1. Input power: 1 mW, Output power: 10 W
    /// 2. Power ratio: 10,000 (10 W / 1 mW)
    /// 3. Gain = 10 log₁₀(10,000) = 40 dB
    ///
    /// **Example 2:** Find cable loss over 100m
    /// 1. Attenuation spec: 0.5 dB per 10m
    /// 2. Total loss: 5 dB for 100m
    /// 3. Power ratio: 10^(-5/10) ≈ 0.316 (68.4% loss)
    ///
    /// **Example 3:** Calculate link budget for wireless system
    /// 1. Transmitter power: +30 dBm (1 W)
    /// 2. Cable loss: -2 dB
    /// 3. Antenna gain: +10 dBi
    /// 4. Total EIRP: 30 - 2 + 10 = +38 dBm
    public static func eePowerRatioScale(length: Distance = 250.0) -> ScaleDefinition {
        let pFunction = PowerRatioFunction()
        
        return ScaleBuilder()
            .withName("P")
            .withFormula("10log₁₀(P₂/P₁)")
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
    /// **PostScript Reference:** eeQscale (line 903)
    /// Formula: 10 log₁₀(P₂/P₁) (inverted tick direction)
    /// Range: 0 to 14 (power ratios, inverted)
    /// Used for: reciprocal-gain, loss-calculations, dB-arithmetic, signal-attenuation
    ///
    /// **Physical Applications:**
    /// - Loss Measurements: Calculate signal attenuation in reverse direction
    /// - Noise Figure: Analyze degradation in signal-to-noise ratio
    /// - Filter Insertion Loss: Measure power loss through filter networks
    /// - Bidirectional Systems: Analyze forward and reverse gain/loss
    /// - Attenuator Design: Calculate resistive attenuator values
    /// - Power Splitter Analysis: Determine port-to-port isolation
    ///
    /// **Example 1:** Calculate filter insertion loss
    /// 1. Power before filter: 10 W
    /// 2. Power after filter: 8 W
    /// 3. Loss = -10 log₁₀(8/10) = 0.97 dB ≈ 1 dB
    ///
    /// **Example 2:** Design 10 dB attenuator pad
    /// 1. Required attenuation: 10 dB
    /// 2. Power ratio: 10^(-10/10) = 0.1 (10:1 reduction)
    /// 3. Use Q scale to calculate resistor values for π or T network
    ///
    /// **Example 3:** Analyze cascaded losses
    /// 1. Cable loss: -3 dB
    /// 2. Connector loss: -0.5 dB  
    /// 3. Total loss: -3.5 dB (use Q scale for summation)
    public static func eePowerRatioInvertedScale(length: Distance = 250.0) -> ScaleDefinition {
        let qFunction = PowerRatioFunction()
        
        return ScaleBuilder()
            .withName("Q")
            .withFormula("10log₁₀(P₁/P₂)")
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
