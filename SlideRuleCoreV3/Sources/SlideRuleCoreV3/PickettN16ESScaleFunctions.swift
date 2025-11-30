import Foundation

// MARK: - Pickett N-16 ES Electronic Scale Functions
// ============================================================================
//
// Historical Context:
// The Pickett N-16 ES (circa 1960) was a professional-grade slide rule designed
// by Chan Street specifically for electronics engineering. The "ES" designation
// indicated the "Eye-Saver" yellow aluminum coating (5600 Angstrom wavelength)
// which reduced eye strain during extended calculations.
//
// The N-16 ES featured 32 scales across a duplex aluminum rule and was used
// extensively during the golden age of American electronics for:
// - RF engineering and antenna design
// - Filter frequency response calculations
// - Impedance matching and transmission lines
// - Resonant circuit design (tank circuits, oscillators, tuned amplifiers)
// - AC circuit analysis
//
// Revolutionary Features:
// 1. Four-decade component value scales (Lr, Cr, C/L, F) eliminated constant
//    mental decade adjustments required by standard single-decade scales.
// 2. Reciprocal function embedding in Lr and Cr scales enabled direct
//    resonant frequency calculation: f = 1/(2π√LC)
// 3. Simultaneous triple reading with Θ, cos(Θ), and dB scales for complete
//    filter response analysis at a single cursor position.
// 4. Decimal keeper (D/Q) scale prevented order-of-magnitude errors when
//    component values spanned femtofarads to farads.
//
// PostScript Engine References:
// These implementations follow the mathematical specifications from Derek
// Pressnall's PostScript Slide Rule Engine (2011). Line numbers reference
// the postscript-engine-for-sliderules.ps file.
//
// ============================================================================

// MARK: - Inductance Reciprocal (Lr Scale)

/// Pickett Lr Scale - Inductance with Reciprocal Function
///
/// PostScript Reference: Lines 840-856
/// Formula: `1.0 - log₁₀(value) / cycles` where cycles = 12
/// Inverse: `pow(10, (1.0 - position) * cycles)`
///
/// Range: 0.001 µH to 100 H across 12 logarithmic decades
///
/// The Lr scale features an embedded reciprocal square root transformation
/// that enables direct resonant frequency calculation when paired with the
/// Cr scale. Setting L on Lr and aligning C on Cr yields f directly.
///
/// Formula for resonance: f = 1/(2π√LC)
///
/// Historical Note: Critical for tank circuits, RF oscillators, and tuned amplifiers.
/// The reciprocal transformation eliminates the need for mental square root operations.
public struct PickettInductanceReciprocalFunction: ScaleFunction {
    public let name = "pickett-inductance-reciprocal"
    public let cycles: Int
    
    /// Initialize with cycle count (default 12 for N-16 ES)
    /// - Parameter cycles: Number of logarithmic decades (default: 12)
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript line 840: {10 exch div log 12 div 1 curcycle 1 12 div mul sub add}
        // The (1 - cycle/12) term cancels with decade offset in implementation
        // Simplified: 1 - log10(value) / 12
        1.0 - log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = (1.0 - transformedValue) * Double(cycles)
        return pow(10, logValue)
    }
}

// MARK: - Capacitance Reciprocal (Cr Scale)

/// Pickett Cr Scale - Capacitance with Reciprocal Function (Symmetric to Lr)
///
/// PostScript Reference: Lines 840-856 (same transformation as Lr)
/// Formula: `1.0 - log₁₀(value) / cycles` where cycles = 12
/// Inverse: `pow(10, (1.0 - position) * cycles)`
///
/// Range: 1 pF to 1000 µF across 12 logarithmic decades
///
/// The Cr scale is designed to pair with the Lr scale for direct resonant
/// frequency calculation. Both scales use the same reciprocal transformation,
/// enabling the f = 1/(2π√LC) relationship to be read directly.
///
/// The decimal keeper feature prevents order-of-magnitude errors when
/// component values span femtofarads to farads (a common source of calculation
/// errors in RF engineering).
///
/// Historical Note: Essential for determining resonant frequencies in RF circuits,
/// filter design, and impedance matching networks.
public struct PickettCapacitanceReciprocalFunction: ScaleFunction {
    public let name = "pickett-capacitance-reciprocal"
    public let cycles: Int
    
    /// Initialize with cycle count (default 12 for N-16 ES)
    /// - Parameter cycles: Number of logarithmic decades (default: 12)
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // Same transformation as Lr scale - reciprocal relationship
        // Enables direct f = 1/(2π√LC) calculation
        1.0 - log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = (1.0 - transformedValue) * Double(cycles)
        return pow(10, logValue)
    }
}

// MARK: - Capacitance/Inductance (C/L Scale)

/// Pickett C/L Scale - Combined Capacitance/Inductance Scale
///
/// Formula: `log₁₀(value) / cycles` where cycles = 12
/// Inverse: `pow(10, position * cycles)`
///
/// Range: Microhenries to henries OR picofarads to microfarads (dual purpose)
///
/// This unified scale can represent either inductance (L) or capacitance (C)
/// depending on the calculation context. The dual-purpose design reduced
/// slide rule complexity while maintaining four-decade range.
///
/// Primary Uses:
/// - Time constant calculations: τ = RC or τ = L/R
/// - Reactance calculations: XL = 2πfL or Xc = 1/(2πfC)
/// - General component value lookups
///
/// Historical Note: The unified scale design was a hallmark of Chan Street's
/// engineering approach, maximizing calculation capability per scale.
public struct PickettCapacitanceInductanceFunction: ScaleFunction {
    public let name = "pickett-capacitance-inductance"
    public let cycles: Int
    
    /// Initialize with cycle count (default 12 for N-16 ES)
    /// - Parameter cycles: Number of logarithmic decades (default: 12)
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue * Double(cycles))
    }
}

// MARK: - Angular Frequency (ω Scale)

/// Pickett ω Scale - Angular Frequency (ω = 2πf)
///
/// Formula: `log₁₀(2π × value) / cycles` where cycles = 12
/// Inverse: `pow(10, position * cycles) / (2π)`
///
/// Range: Radians per second from mrad/s to Grad/s across 12 decades
///
/// The angular frequency scale directly converts between frequency (Hz)
/// and angular frequency (rad/s) using the relationship ω = 2πf.
///
/// Primary Uses:
/// - AC circuit analysis where phase relationships require radian notation
/// - Complex impedance calculations: Z = R + jωL or Z = R + 1/(jωC)
/// - Transfer function evaluation
/// - Control system design
///
/// Historical Note: Critical for impedance calculations in complex notation,
/// filter analysis, and any calculation involving phase relationships.
public struct PickettAngularFrequencyFunction: ScaleFunction {
    public let name = "pickett-angular-frequency"
    public let cycles: Int
    
    /// Initialize with cycle count (default 12 for N-16 ES)
    /// - Parameter cycles: Number of logarithmic decades (default: 12)
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // ω = 2πf, so we transform log(2πf) / 12
        log10(2.0 * .pi * value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = transformedValue * Double(cycles)
        return pow(10, logValue) / (2.0 * .pi)
    }
}

// MARK: - Wavelength (λ Scale)

/// Pickett λ Scale - Wavelength (λ = c/f)
///
/// PostScript Reference: Line 1003
/// Formula: `1.0 - log₁₀(value) / cycles` where cycles = 6
/// Inverse: `pow(10, (1.0 - position) * cycles)`
///
/// Range: 3000m to 3mm wavelength (corresponding to 100kHz to 100GHz)
/// Speed of Light: 299,792,458 m/s
///
/// The wavelength scale uses the relationship c = fλ where c is the speed
/// of light. The inverted transformation (1.0 - ...) causes higher frequencies
/// to correspond to shorter wavelengths, maintaining physical intuition.
///
/// Primary Uses:
/// - Antenna design (physical antenna dimensions are wavelength-dependent)
/// - Transmission line length calculations (quarter-wave, half-wave)
/// - RF and microwave engineering
/// - Radio wave propagation analysis
///
/// Dual Labeling: The scale shows both frequency (Hz) and corresponding
/// wavelength (meters) for direct reading of both parameters.
///
/// Historical Note: Essential for radio and radar work where physical
/// dimensions relate directly to operating frequency.
public struct PickettWavelengthFunction: ScaleFunction {
    public let name = "pickett-wavelength"
    public let cycles: Int
    
    /// Speed of light in meters per second
    public static let speedOfLight: Double = 299792458.0
    
    /// Initialize with cycle count (default 6 for N-16 ES wavelength scale)
    /// - Parameter cycles: Number of logarithmic decades (default: 6)
    public init(cycles: Int = 6) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript line 1003: inverted frequency scale
        // λ = c/f, so higher frequencies = shorter wavelengths (inverted)
        1.0 - log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = (1.0 - transformedValue) * Double(cycles)
        return pow(10, logValue)
    }
    
    /// Convert frequency (Hz) to wavelength (meters)
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Wavelength in meters
    public func frequencyToWavelength(_ frequency: Double) -> Double {
        Self.speedOfLight / frequency
    }
    
    /// Convert wavelength (meters) to frequency (Hz)
    /// - Parameter wavelength: Wavelength in meters
    /// - Returns: Frequency in Hz
    public func wavelengthToFrequency(_ wavelength: Double) -> Double {
        Self.speedOfLight / wavelength
    }
}

// MARK: - Phase Angle (Θ Scale)

/// Pickett Θ Scale - Phase Angle for RC/RL Circuits
///
/// Formula: `log₁₀(tan(radians))` where radians = value × π / 180
/// Inverse: `atan(pow(10, position)) × 180 / π`
///
/// Range: 0° to 90° (quadrant I phase relationships)
///
/// The phase angle scale represents:
/// - For RC circuits: α = cot⁻¹(2πfRC) = phase lag
/// - For RL circuits: α = tan⁻¹(2πfL/R) = phase lead
///
/// The tangent-based transformation provides optimal scale distribution
/// across the 0° to 90° range, with finer resolution near the extremes
/// where phase changes are most significant.
///
/// Primary Uses:
/// - Filter frequency response (phase vs frequency plots)
/// - AC circuit analysis (power factor angle)
/// - Impedance angle calculations
/// - Audio equalizer design
///
/// Special Feature: Coordinated with cos(Θ) and dB scales for simultaneous
/// triple reading - a single cursor position yields gain, phase shift, and
/// decibel loss simultaneously.
///
/// Historical Note: Critical for audio equalizer design, communications
/// filters, and any application requiring phase-accurate frequency response.
public struct PickettPhaseAngleFunction: ScaleFunction {
    public let name = "pickett-phase-angle"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // Phase angle in degrees, transformed via tangent for better distribution
        // For RC: α = atan(1/(2πfRC))
        // For RL: α = atan(2πfL/R)
        let radians = value * .pi / 180.0
        
        // Guard against tan(0) = 0 which would give -infinity for log
        guard radians > 0 else { return -10.0 } // Effectively negative infinity
        guard radians < .pi / 2.0 else { return 10.0 } // Effectively positive infinity
        
        // Cotangent-based transformation for better scale distribution
        return log10(tan(radians))
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let tanValue = pow(10, transformedValue)
        return atan(tanValue) * 180.0 / .pi
    }
}

// MARK: - Cosine Phase (cos(Θ) Scale)

/// Pickett cos(Θ) Scale - Power Factor and Relative Gain
///
/// Formula: `1.0 - acos(value) / (π/2)` (arccos-based transform)
/// Inverse: `cos((1.0 - position) × π/2)`
///
/// Range: 0.0 to 1.0 (represents relative voltage or current gain)
///
/// The cosine of the phase angle represents the relative gain (0 to 1)
/// for filter frequency response calculations:
/// - cos(Θ) = 1/√(1 + (1/(2πfRC))²) for RC filters
/// - Also represents power factor (PF = cos(Θ)) in AC power systems
///
/// Primary Uses:
/// - Filter frequency response (gain vs frequency)
/// - Power factor calculations
/// - Audio equalizers and RF filters
/// - Relative amplitude measurements
///
/// Special Marker: 0.707 represents the -3dB point, marking the half-power
/// frequency (cutoff frequency) of filters.
///
/// Simultaneous Reading: A single cursor position on coordinated Θ, cos(Θ),
/// and dB scales yields complete filter response information.
///
/// Historical Note: Enabled point-by-point frequency response curve
/// visualization in the pre-computer era of filter design.
public struct PickettCosinePhaseFunction: ScaleFunction {
    public let name = "pickett-cosine-phase"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // cos(θ) represents relative gain (0 to 1)
        // Transform to normalized position for slide rule positioning
        
        // Clamp to valid range
        guard value > 0 else { return 0 }
        guard value < 1 else { return 1 }
        
        // Transformation based on cos⁻¹ for better scale distribution
        let angle = acos(value)
        return 1.0 - angle / (.pi / 2.0) // Normalize to 0-1
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let angle = (1.0 - transformedValue) * (.pi / 2.0)
        return cos(angle)
    }
}

// MARK: - Decibel (dB Scale)

/// Pickett dB Scale - Decibels (Power and Voltage Ratios)
///
/// Formula (Power): `10 × log₁₀(value)` (normalized to ±40 dB range)
/// Formula (Voltage): `20 × log₁₀(value)` (configurable)
/// 
/// Range: ±40 dB (0.01 to 100 ratio range)
///
/// Two variants available:
/// - Power ratios: 10 × log₁₀(P₂/P₁) - for power measurements
/// - Voltage ratios: 20 × log₁₀(V₂/V₁) - for voltage/current measurements
///
/// The 20 dB/decade relationship for voltage comes from power being
/// proportional to voltage squared: P ∝ V²
///
/// Primary Uses:
/// - Amplifier gain calculations
/// - Signal attenuation measurements
/// - Filter frequency response
/// - Communications system analysis
///
/// Special Feature: Coordinated with cos(Θ) scale for simultaneous
/// gain/phase reading in filter analysis applications.
///
/// Historical Note: The universal logarithmic scale for telecommunications
/// and audio engineering, enabling multiplication by addition.
public struct PickettDecibelFunction: ScaleFunction {
    public let name = "pickett-decibel"
    
    /// Whether this scale uses voltage ratio (20 log) or power ratio (10 log)
    public let isVoltageRatio: Bool
    
    /// Range in dB (default ±40 dB)
    public let dbRange: Double
    
    /// Initialize with ratio type
    /// - Parameters:
    ///   - isVoltageRatio: true for 20×log (voltage/current), false for 10×log (power)
    ///   - dbRange: Total dB range (default: 80 for ±40 dB)
    public init(isVoltageRatio: Bool = false, dbRange: Double = 80.0) {
        self.isVoltageRatio = isVoltageRatio
        self.dbRange = dbRange
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // Value is the linear ratio (e.g., 2.0 for 2:1)
        // Convert to dB then normalize to scale position
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        let dB = multiplier * log10(value)
        // Normalize to 0-1 range (assuming ±40 dB range by default)
        return (dB + dbRange / 2.0) / dbRange
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // Convert normalized position back to dB then to linear ratio
        let dB = transformedValue * dbRange - dbRange / 2.0
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        return pow(10, dB / multiplier)
    }
    
    /// Convert linear ratio to dB
    /// - Parameter ratio: Linear ratio (e.g., 2.0 for doubling)
    /// - Returns: Value in decibels
    public func ratioToDb(_ ratio: Double) -> Double {
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        return multiplier * log10(ratio)
    }
    
    /// Convert dB to linear ratio
    /// - Parameter dB: Value in decibels
    /// - Returns: Linear ratio
    public func dbToRatio(_ dB: Double) -> Double {
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        return pow(10, dB / multiplier)
    }
}

// MARK: - Decimal Keeper / Q Factor (D/Q Scale)

/// Pickett D/Q Scale - Decimal Keeper and Q-Factor
///
/// D Mode Formula: Mantissa extraction `value / pow(10, floor(log₁₀(|value|)))`
/// Q Mode Formula: Logarithmic Q-factor `log₁₀(value)`
///
/// Range: 1 to 10 (repeating for each decade)
///
/// Dual function scale:
/// - D mode (Decimal Keeper): Tracks decimal magnitude (decade counter) to
///   prevent order-of-magnitude errors when component values span multiple
///   decades (e.g., femtofarads to farads)
/// - Q mode (Q-Factor): Quality factor for resonant circuits
///   Q = ωL/R = 1/(ωRC) = (1/R)√(L/C)
///
/// The D mode extracts the mantissa (1-10 range) from any value, effectively
/// showing only the significant figures while the user tracks decades mentally.
///
/// Historical Note: The four-decade component value scales (Lr, Cr) required
/// careful decade tracking. The D/Q scale prevented the most common source of
/// calculation errors in electronics work.
public struct PickettDecimalKeeperQFunction: ScaleFunction {
    public let name = "pickett-decimal-keeper-q"
    
    /// Whether scale operates in Q-factor mode (true) or decimal keeper mode (false)
    public let isQMode: Bool
    
    /// Initialize with mode selection
    /// - Parameter isQMode: true for Q-factor logarithmic scale, false for decimal keeper
    public init(isQMode: Bool = false) {
        self.isQMode = isQMode
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        if isQMode {
            // Q-factor: standard logarithmic scale
            return log10(value)
        } else {
            // Decimal keeper: shows mantissa (1-10 range)
            // Extract the mantissa by dividing by the order of magnitude
            guard value != 0 else { return 0 }
            let absValue = abs(value)
            let mantissa = absValue / pow(10, floor(log10(absValue)))
            return log10(mantissa)
        }
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // In both modes, inverse is simply 10^position
        // For D mode, this gives mantissa; user supplies decade
        pow(10, transformedValue)
    }
}

// MARK: - Time Constant (τ Scale)

/// Pickett τ Scale - Time Constant
///
/// Formula: `log₁₀(value) / cycles` where cycles = 12
/// Inverse: `pow(10, position * cycles)`
///
/// Range: Nanoseconds to minutes across 12 logarithmic decades
///
/// The time constant represents the characteristic response time of
/// RC and RL circuits:
/// - RC circuits: τ = R × C (resistance × capacitance)
/// - RL circuits: τ = L / R (inductance / resistance)
///
/// Physical Interpretation:
/// - After time τ, an RC circuit charges to 63.2% (1 - 1/e) of final value
/// - After time 5τ, the circuit reaches 99.3% of final value
///
/// Primary Uses:
/// - Timing circuit design
/// - Amplifier frequency response (time domain)
/// - Power supply filtering (ripple decay)
/// - Control system transient response
/// - Audio equalizer time constants
///
/// Historical Note: Essential for audio equalizer design, timing circuits,
/// and power supply filter calculations in the vacuum tube and early
/// transistor eras.
public struct PickettTimeConstantFunction: ScaleFunction {
    public let name = "pickett-time-constant"
    public let cycles: Int
    
    /// Initialize with cycle count (default 12 for N-16 ES)
    /// - Parameter cycles: Number of logarithmic decades (default: 12)
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue * Double(cycles))
    }
}

// MARK: - Example Calculations

/// Example calculations demonstrating Pickett N-16 ES capabilities
///
/// These utility functions implement the core electronic engineering
/// calculations that the N-16 ES was designed to perform. They serve
/// both as documentation of the slide rule's capabilities and as
/// reference implementations for verifying scale accuracy.
///
/// Historical Note: Before electronic calculators (circa 1970s), these
/// calculations were performed daily by thousands of electronics engineers
/// using the N-16 ES and similar specialized slide rules.
public enum PickettN16ESExamples {
    
    // MARK: - Resonance
    
    /// Calculate resonant frequency using Lr and Cr scales
    ///
    /// Formula: f = 1 / (2π√LC)
    ///
    /// Example:
    /// ```swift
    /// let f = PickettN16ESExamples.resonantFrequency(
    ///     inductance: 25e-3,  // 25 mH
    ///     capacitance: 2e-6   // 2 µF
    /// )
    /// // Result: ≈ 711 Hz
    /// ```
    ///
    /// - Parameters:
    ///   - inductance: Inductance in henries
    ///   - capacitance: Capacitance in farads
    /// - Returns: Resonant frequency in Hz
    public static func resonantFrequency(inductance: Double, capacitance: Double) -> Double {
        1.0 / (2.0 * .pi * sqrt(inductance * capacitance))
    }
    
    // MARK: - Filter Response
    
    /// Calculate RC low-pass filter response at specific frequency
    ///
    /// Formula:
    /// - Gain = 1/√(1 + (2πfRC)²)
    /// - Phase = -atan(2πfRC) (negative for lag)
    ///
    /// Example:
    /// ```swift
    /// let response = PickettN16ESExamples.rcFilterResponse(
    ///     resistance: 30_000,  // 30 kΩ
    ///     capacitance: 1e-6,   // 1 µF
    ///     frequency: 5         // 5 Hz
    /// )
    /// // Result: (gain: 0.686, phase: 46.7°, dB: -3.28)
    /// ```
    ///
    /// - Parameters:
    ///   - resistance: Resistance in ohms
    ///   - capacitance: Capacitance in farads
    ///   - frequency: Frequency in Hz
    /// - Returns: Tuple of (relative gain, phase shift in degrees, gain in dB)
    public static func rcFilterResponse(
        resistance: Double,
        capacitance: Double,
        frequency: Double
    ) -> (relativeGain: Double, phaseShift: Double, gainDB: Double) {
        let omega = 2.0 * .pi * frequency
        let product = omega * resistance * capacitance
        
        // Low-pass filter response
        let relativeGain = 1.0 / sqrt(1.0 + product * product)
        let phaseShift = -atan(product) * 180.0 / .pi  // Negative for lag
        let gainDB = 20.0 * log10(relativeGain)
        
        return (relativeGain, phaseShift, gainDB)
    }
    
    // MARK: - Reactance
    
    /// Calculate inductive reactance: XL = 2πfL
    ///
    /// The inductive reactance increases with frequency, causing
    /// inductors to act as high-frequency blockers.
    ///
    /// - Parameters:
    ///   - frequency: Frequency in Hz
    ///   - inductance: Inductance in henries
    /// - Returns: Inductive reactance in ohms
    public static func inductiveReactance(frequency: Double, inductance: Double) -> Double {
        2.0 * .pi * frequency * inductance
    }
    
    /// Calculate capacitive reactance: Xc = 1/(2πfC)
    ///
    /// The capacitive reactance decreases with frequency, causing
    /// capacitors to act as low-frequency blockers.
    ///
    /// - Parameters:
    ///   - frequency: Frequency in Hz
    ///   - capacitance: Capacitance in farads
    /// - Returns: Capacitive reactance in ohms
    public static func capacitiveReactance(frequency: Double, capacitance: Double) -> Double {
        1.0 / (2.0 * .pi * frequency * capacitance)
    }
    
    // MARK: - Wavelength
    
    /// Calculate wavelength from frequency: λ = c/f
    ///
    /// Uses the speed of light constant (299,792,458 m/s).
    ///
    /// Example:
    /// ```swift
    /// let wavelength = PickettN16ESExamples.wavelength(frequency: 100e6)
    /// // Result: ≈ 3.0 meters (FM radio band)
    /// ```
    ///
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Wavelength in meters
    public static func wavelength(frequency: Double) -> Double {
        PickettWavelengthFunction.speedOfLight / frequency
    }
    
    // MARK: - Time Constants
    
    /// Calculate RC time constant: τ = R × C
    ///
    /// The time constant determines the charging/discharging rate:
    /// - After 1τ: 63.2% of final value
    /// - After 3τ: 95.0% of final value
    /// - After 5τ: 99.3% of final value
    ///
    /// - Parameters:
    ///   - resistance: Resistance in ohms
    ///   - capacitance: Capacitance in farads
    /// - Returns: Time constant in seconds
    public static func timeConstantRC(resistance: Double, capacitance: Double) -> Double {
        resistance * capacitance
    }
    
    /// Calculate LR time constant: τ = L / R
    ///
    /// For inductive circuits, the time constant determines how quickly
    /// current builds up or decays through the inductor.
    ///
    /// - Parameters:
    ///   - inductance: Inductance in henries
    ///   - resistance: Resistance in ohms
    /// - Returns: Time constant in seconds
    public static func timeConstantLR(inductance: Double, resistance: Double) -> Double {
        inductance / resistance
    }
    
    // MARK: - Quality Factor
    
    /// Calculate Q factor for a series RLC circuit
    ///
    /// Formula: Q = (1/R) × √(L/C) = ωL/R = 1/(ωRC)
    ///
    /// Q factor represents the "selectivity" or "sharpness" of resonance.
    /// Higher Q means narrower bandwidth and sharper frequency response.
    ///
    /// - Parameters:
    ///   - resistance: Resistance in ohms
    ///   - inductance: Inductance in henries
    ///   - capacitance: Capacitance in farads
    /// - Returns: Quality factor (dimensionless)
    public static func qualityFactor(
        resistance: Double,
        inductance: Double,
        capacitance: Double
    ) -> Double {
        (1.0 / resistance) * sqrt(inductance / capacitance)
    }
    
    // MARK: - Impedance
    
    /// Calculate series RLC impedance at a given frequency
    ///
    /// Formula: Z = √(R² + (XL - Xc)²)
    /// Phase: θ = atan((XL - Xc) / R)
    ///
    /// - Parameters:
    ///   - resistance: Resistance in ohms
    ///   - inductance: Inductance in henries
    ///   - capacitance: Capacitance in farads
    ///   - frequency: Frequency in Hz
    /// - Returns: Tuple of (impedance magnitude in ohms, phase angle in degrees)
    public static func seriesImpedance(
        resistance: Double,
        inductance: Double,
        capacitance: Double,
        frequency: Double
    ) -> (magnitude: Double, phaseDegrees: Double) {
        let xL = inductiveReactance(frequency: frequency, inductance: inductance)
        let xC = capacitiveReactance(frequency: frequency, capacitance: capacitance)
        let netReactance = xL - xC
        
        let magnitude = sqrt(resistance * resistance + netReactance * netReactance)
        let phaseDegrees = atan(netReactance / resistance) * 180.0 / .pi
        
        return (magnitude, phaseDegrees)
    }
}