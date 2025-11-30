import Foundation

// MARK: - Pickett N-16 ES Electronic Scale Functions
// Advanced slide rule scale functions for electronics engineering
// Historical Note: The N-16 ES (circa 1960) featured 32 scales designed by Chan Street
// "ES" = Eye-Saver yellow aluminum coating (5600 Angstrom wavelength)
// Used for RF engineering, filter design, impedance matching, and AC circuit analysis

/// Lr Scale - Inductance with Reciprocal Function (4-decade span)
/// PostScript: log10(10/value) / 12 + (1 - cycle/12)
/// Formula: 1 - log₁₀(value) / 12 cycles
/// Range: 0.001 µH to 100 H across 12 logarithmic decades
/// Special feature: Embedded reciprocal square root transformation for resonance calculations
/// Used with: Cr scale for direct resonant frequency reading (f = 1/(2π√LC))
/// Historical: Critical for tank circuits, RF oscillators, tuned amplifiers
public struct InductanceReciprocalFunction: ScaleFunction, Sendable {
    public let name = "inductance-reciprocal"
    public let cycles: Int
    
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript line 840: {10 exch div log 12 div 1 curcycle 1 12 div mul sub add}
        // The (1 - cycle/12) term cancels with decade offset in the implementation
        // Simplified: 1 - log10(value) / 12
        1.0 - log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = (1.0 - transformedValue) * Double(cycles)
        return pow(10, logValue)
    }
}

/// Cr Scale - Capacitance with Reciprocal Function (4-decade span)  
/// Formula: 1 - log₁₀(value) / 12 cycles
/// Range: 1 pF to 1000 µF across 12 logarithmic decades
/// Special feature: Embedded reciprocal square root transformation for resonance calculations
/// Used with: Lr scale for direct resonant frequency reading
/// Decimal keeper: Prevents order-of-magnitude errors spanning femtofarads to farads
/// Historical: Essential for determining resonant frequencies in RF circuits
public struct CapacitanceReciprocalFunction: ScaleFunction, Sendable {
    public let name = "capacitance-reciprocal"
    public let cycles: Int
    
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

/// C/L Scale - Combined Capacitance/Inductance Scale (4-decade span)
/// Formula: log₁₀(value) / 12 cycles
/// Range: Microhenries to henries OR picofarads to microfarads
/// Dual purpose: Can represent either L or C depending on calculation context
/// Used for: Time constant calculations (τ = RC or τ = L/R)
/// Historical: Unified scale design reduced slide rule complexity
public struct CapacitanceInductanceFunction: ScaleFunction, Sendable {
    public let name = "capacitance-inductance"
    public let cycles: Int
    
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

/// ω Scale - Angular Frequency (ω = 2πf)
/// Formula: log₁₀(2π × f) / 12 cycles  
/// Range: Radians per second from mrad/s to Grad/s
/// Used for: AC circuit analysis where phase relationships require radian notation
/// Relationship: ω = 2πf directly converts between hertz and radians/second
/// Historical: Critical for impedance calculations in complex notation (Z = R + jωL)
public struct AngularFrequencyFunction: ScaleFunction, Sendable {
    public let name = "angular-frequency"
    public let cycles: Int
    
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

/// τ Scale - Time Constant Scale  
/// Formula: log₁₀(RC or L/R) / 12 cycles
/// Range: Microseconds to seconds across 12 decades
/// Dual function: τ = RC for capacitive circuits, τ = L/R for inductive circuits
/// Used for: Charging/discharging rates, transient response, settling time
/// Applications: Timing circuits, amplifier response, control systems
/// Historical: Essential for audio equalizer design and power supply filtering
public struct TimeConstantFunction: ScaleFunction, Sendable {
    public let name = "time-constant"
    public let cycles: Int
    
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

/// λ Scale - Wavelength Scale (λ = c/f)
/// Formula: 1 - log₁₀(frequency) / 6 (inverted to show wavelength)
/// Range: 3000m to 3mm (corresponding to 100kHz to 100GHz)
/// Relationship: c = fλ (speed of light = frequency × wavelength)
/// Used for: Antenna design, transmission line length, RF/microwave work
/// Dual labeling: Shows both frequency and corresponding wavelength
/// Historical: Essential for radio and radar work, physical antenna dimensions
public struct WavelengthFunction: ScaleFunction, Sendable {
    public let name = "wavelength"
    public let cycles: Int
    private let speedOfLight: Double = 299792458.0 // m/s
    
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
    
    /// Convert frequency to wavelength in meters
    public func frequencyToWavelength(_ frequency: Double) -> Double {
        speedOfLight / frequency
    }
    
    /// Convert wavelength in meters to frequency
    public func wavelengthToFrequency(_ wavelength: Double) -> Double {
        speedOfLight / wavelength
    }
}

/// Θ (Theta) Scale - Phase Angle for RC/RL Circuits
/// Formula: α = cot⁻¹(2πfRC) for capacitive circuits
///          α = tan⁻¹(2πfL/R) for inductive circuits  
/// Range: 0° to 90° (quadrant I phase relationships)
/// Used with: Filter frequency response, AC circuit analysis
/// Dual function: Can represent either RC or RL phase shift
/// Historical: Critical for audio equalizer design and communications filters
/// Special: Coordinated with cos(θ) and dB scales for simultaneous triple reading
public struct PhaseAngleFunction: ScaleFunction, Sendable {
    public let name = "phase-angle"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // Phase angle in degrees, linearized for slide rule scale
        // Transform to normalized position (0 to 1)
        // For RC: α = atan(1/(2πfRC))
        // For RL: α = atan(2πfL/R)
        let radians = value * .pi / 180.0
        // Cotangent-based transformation for better scale distribution
        return log10(tan(radians))
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let tanValue = pow(10, transformedValue)
        return atan(tanValue) * 180.0 / .pi
    }
}

/// cos(Θ) Scale - Power Factor and Relative Gain
/// Formula: cos(θ) = 1/√(1 + (1/(2πfRC))²) for filter response
/// Range: 0.0 to 1.0 (represents relative voltage or current)
/// Used for: Filter frequency response, power factor calculations
/// Applications: Audio equalizers, RF filters, power systems
/// Special: Simultaneous reading with dB and phase angle for complete filter analysis
/// Historical: Enabled point-by-point frequency response curve visualization
public struct CosinePhaseFunction: ScaleFunction, Sendable {
    public let name = "cosine-phase"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // cos(θ) represents relative gain (0 to 1)
        // Transform to log scale for slide rule positioning
        // Special nonlinear transformation for filter response
        if value <= 0 {
            return 0
        }
        if value >= 1 {
            return 1
        }
        // Transformation based on cos⁻¹ for better scale distribution
        let angle = acos(value)
        return 1.0 - angle / (.pi / 2.0) // Normalize to 0-1
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let angle = (1.0 - transformedValue) * (.pi / 2.0)
        return cos(angle)
    }
}

/// dB Scale - Decibels (Power and Voltage Ratios)
/// Two variants: Power ratios (10 log₁₀(P₂/P₁)) and Voltage ratios (20 log₁₀(V₂/V₁))
/// Range: Typically -40 dB to +40 dB
/// Used for: Amplifier gain, signal attenuation, filter response
/// Dual scales: Upper for power ratios, lower for voltage/current ratios
/// Special: Coordinated with cos(θ) for simultaneous gain/phase reading
/// Historical: Universal logarithmic scale for telecommunications and audio
public struct DecibelFunction: ScaleFunction, Sendable {
    public let name = "decibel"
    public let isVoltageRatio: Bool
    
    /// Initialize with ratio type
    /// - Parameter isVoltageRatio: true for 20log (voltage/current), false for 10log (power)
    public init(isVoltageRatio: Bool = false) {
        self.isVoltageRatio = isVoltageRatio
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // Value is the linear ratio (e.g., 2.0 for 2:1)
        // Convert to dB then normalize to scale position
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        let dB = multiplier * log10(value)
        // Normalize to 0-1 range (assuming ±40 dB range)
        return (dB + 40.0) / 80.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // Convert normalized position back to dB then to linear ratio
        let dB = transformedValue * 80.0 - 40.0
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        return pow(10, dB / multiplier)
    }
    
    /// Convert linear ratio to dB
    public func ratioToDb(_ ratio: Double) -> Double {
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        return multiplier * log10(ratio)
    }
    
    /// Convert dB to linear ratio
    public func dbToRatio(_ dB: Double) -> Double {
        let multiplier = isVoltageRatio ? 20.0 : 10.0
        return pow(10, dB / multiplier)
    }
}

/// D/Q Scale - Decimal Keeper and Q-Factor
/// Dual function scale:
/// - D mode: Tracks decimal magnitude (decade counter) to prevent order-of-magnitude errors
/// - Q mode: Quality factor for resonant circuits (Q = ωL/R = 1/(ωRC))
/// Range: 1 to 10 (repeating for each decade)
/// Special: Essential when component values span femtofarads to farads
/// Historical: The four-decade component value scales required careful decade tracking
public struct DecimalKeeperQFunction: ScaleFunction, Sendable {
    public let name = "decimal-keeper-q"
    public let isQMode: Bool
    
    public init(isQMode: Bool = false) {
        self.isQMode = isQMode
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        if isQMode {
            // Q-factor: logarithmic scale
            return log10(value)
        } else {
            // Decimal keeper: shows mantissa (1-10 range)
            let mantissa = value / pow(10, floor(log10(abs(value))))
            return log10(mantissa)
        }
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue)
    }
}

// MARK: - N-16 ES Example Calculations

/// Example calculations demonstrating N-16 ES capabilities
public enum N16ESExamples {
    
    /// Calculate resonant frequency using Lr and Cr scales
    /// Formula: f = 1 / (2π√LC)
    /// Example: L = 25 mH, C = 2 µF → f ≈ 711 Hz
    public static func resonantFrequency(inductance: Double, capacitance: Double) -> Double {
        1.0 / (2.0 * .pi * sqrt(inductance * capacitance))
    }
    
    /// Calculate RC filter response at specific frequency
    /// Returns: (relative gain, phase shift in degrees, gain in dB)
    /// Formula: Gain = 1/√(1 + (1/(2πfRC))²), Phase = atan(1/(2πfRC))
    /// Example: R = 30kΩ, C = 1.0µF, f = 5Hz → (0.686, -3.28dB, 46.7°)
    public static func rcFilterResponse(
        resistance: Double,
        capacitance: Double,
        frequency: Double
    ) -> (relativeGain: Double, phaseShift: Double, gainDB: Double) {
        let product = 2.0 * .pi * frequency * resistance * capacitance
        let relativeGain = 1.0 / sqrt(1.0 + 1.0 / (product * product))
        let phaseShift = atan(1.0 / product) * 180.0 / .pi
        let gainDB = 20.0 * log10(relativeGain)
        
        return (relativeGain, phaseShift, gainDB)
    }
    
    /// Calculate inductive reactance: XL = 2πfL
    public static func inductiveReactance(frequency: Double, inductance: Double) -> Double {
        2.0 * .pi * frequency * inductance
    }
    
    /// Calculate capacitive reactance: XC = 1/(2πfC)
    public static func capacitiveReactance(frequency: Double, capacitance: Double) -> Double {
        1.0 / (2.0 * .pi * frequency * capacitance)
    }
    
    /// Calculate wavelength from frequency: λ = c/f
    public static func wavelength(frequency: Double) -> Double {
        299792458.0 / frequency // speed of light in m/s
    }
    
    /// Calculate time constant: τ = RC or τ = L/R
    public static func timeConstantRC(resistance: Double, capacitance: Double) -> Double {
        resistance * capacitance
    }
    
    public static func timeConstantLR(inductance: Double, resistance: Double) -> Double {
        inductance / resistance
    }
}

// MARK: - N-16 ES Scale Builder

/// Utilities for creating Pickett N-16 ES scale definitions
public enum N16ESScaleBuilder {
    
    /// Create the Lr (inductance reciprocal) scale with proper subsections
    public static func createLrScale(
        scaleLengthInPoints: Double = 250.0,
        layout: ScaleLayout = .linear,
        tickDirection: TickDirection = .up
    ) -> ScaleDefinition {
        StandardScales.inductanceReciprocalScale(length: scaleLengthInPoints)
    }
    
    /// Create the Cr (capacitance reciprocal) scale
    public static func createCrScale(
        scaleLengthInPoints: Double = 250.0,
        layout: ScaleLayout = .linear,
        tickDirection: TickDirection = .down
    ) -> ScaleDefinition {
        StandardScales.capacitanceReciprocalScale(length: scaleLengthInPoints)
    }
    
    /// Create the Fo (frequency/wavelength) scale
    public static func createFoScale(
        scaleLengthInPoints: Double = 250.0,
        layout: ScaleLayout = .linear,
        tickDirection: TickDirection = .up
    ) -> ScaleDefinition {
        StandardScales.foScale(length: scaleLengthInPoints)
    }
    
    /// Create phase angle (Θ) scale for filter response
    public static func createPhaseAngleScale(
        scaleLengthInPoints: Double = 250.0,
        layout: ScaleLayout = .linear,
        tickDirection: TickDirection = .up
    ) -> ScaleDefinition {
        StandardScales.phaseAngleThetaScale(length: scaleLengthInPoints)
    }
    
    /// Create cos(Θ) scale for relative gain
    public static func createCosinePhaseScale(
        scaleLengthInPoints: Double = 250.0,
        layout: ScaleLayout = .linear,
        tickDirection: TickDirection = .down
    ) -> ScaleDefinition {
        StandardScales.cosinePowerFactorScale(length: scaleLengthInPoints)
    }
    
    /// Create dB (decibel) scale
    public static func createDecibelScale(
        isVoltageRatio: Bool = false,
        scaleLengthInPoints: Double = 250.0,
        layout: ScaleLayout = .linear,
        tickDirection: TickDirection = .up
    ) -> ScaleDefinition {
        if isVoltageRatio {
            return StandardScales.decibelVoltageScale(length: scaleLengthInPoints)
        } else {
            return StandardScales.decibelPowerScale(length: scaleLengthInPoints)
        }
    }
}

// MARK: - N-16 ES Label Formatters

public enum N16ESLabelFormatters {
    
    /// Format inductance values with appropriate SI prefixes across 4 decades
    /// Units: µH, mH, H across 12 cycles
    public static let inductanceReciprocalFormatter: @Sendable (ScaleValue, Int) -> String = { value, cycle in
        let units = ["**", ".001µH", "*", "**", "1µH", "*", "**", "1mH", "*", "**", "1H", "*", "100H"]
        let cycleIndex = cycle - 1
        guard cycleIndex >= 0 && cycleIndex < units.count else { return "\(Int(value.rounded()))" }
        let unit = units[cycleIndex]
        if unit == "*" {
            return "\(Int(value.rounded()))"
        } else if unit == "**" {
            return "**"
        }
        return unit
    }
    
    /// Format capacitance values with appropriate SI prefixes across 4 decades
    /// Units: pF, nF, µF across 12 cycles
    public static let capacitanceReciprocalFormatter: @Sendable (ScaleValue, Int) -> String = { value, cycle in
        let units = ["**", "1PF", "*", "**", ".001µF", "*", "**", "1µF", "*", "**", "1000µF", "*", "Z"]
        let cycleIndex = cycle - 1
        guard cycleIndex >= 0 && cycleIndex < units.count else { return "\(Int(value.rounded()))" }
        let unit = units[cycleIndex]
        if unit == "*" {
            return "\(Int(value.rounded()))"
        } else if unit == "**" {
            return "**"
        }
        return unit
    }
    
    /// Format angular frequency (ω) with rad/s units
    public static let angularFrequencyFormatter: @Sendable (ScaleValue, Int) -> String = { value, cycle in
        let units = ["mrad/s", "rad/s", "krad/s", "Mrad/s", "Grad/s"]
        let magnitude = log10(value)
        let exponent = Int(floor(magnitude / 3.0))
        let index = min(max(exponent + 1, 0), units.count - 1)
        
        let divisor = pow(10.0, Double(index - 1) * 3.0)
        let displayValue = value / divisor
        
        if displayValue >= 100 {
            return "\(Int(displayValue.rounded()))\(units[index])"
        } else if displayValue >= 10 {
            return String(format: "%.1f", displayValue) + units[index]
        } else {
            return String(format: "%.2f", displayValue) + units[index]
        }
    }
    
    /// Format time constant values (τ = RC or L/R)
    public static let timeConstantFormatter: @Sendable (ScaleValue) -> String = { value in
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
    
    /// Format wavelength values (meters with SI prefixes)
    public static let wavelengthFormatter: @Sendable (ScaleValue) -> String = { value in
        // Value is wavelength in meters
        if value >= 1000 {
            return String(format: "%.0f km", value / 1000)
        } else if value >= 1 {
            return String(format: "%.0f m", value)
        } else if value >= 0.01 {
            return String(format: "%.0f cm", value * 100)
        } else if value >= 0.001 {
            return String(format: "%.1f mm", value * 1000)
        } else {
            return String(format: "%.0f µm", value * 1e6)
        }
    }
    
    /// Format phase angle in degrees
    public static let phaseAngleFormatter: @Sendable (ScaleValue) -> String = { value in
        if value < 1.0 {
            return String(format: "%.2f°", value)
        } else if value < 10.0 {
            return String(format: "%.1f°", value)
        } else {
            return String(format: "%.0f°", value)
        }
    }
    
    /// Format cosine of phase (relative gain, 0 to 1)
    public static let cosinePhaseFormatter: @Sendable (ScaleValue) -> String = { value in
        if value < 0.01 {
            return String(format: "%.3f", value)
        } else if value < 0.1 {
            return String(format: "%.3f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    /// Format decibel values
    public static let decibelFormatter: @Sendable (ScaleValue) -> String = { value in
        if abs(value) < 1.0 {
            return String(format: "%.2f dB", value)
        } else if abs(value) < 10.0 {
            return String(format: "%.1f dB", value)
        } else {
            return String(format: "%.0f dB", value)
        }
    }
    
    /// Format Q-factor values
    public static let qFactorFormatter: @Sendable (ScaleValue) -> String = { value in
        if value < 10 {
            return String(format: "Q=%.1f", value)
        } else if value < 100 {
            return String(format: "Q=%.0f", value)
        } else {
            return String(format: "Q=%.0f", value)
        }
    }
}
