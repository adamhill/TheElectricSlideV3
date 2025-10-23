import Foundation

// MARK: - Electrical Engineering Scale Functions
// These scales are used for AC circuit analysis, RF engineering, transmission line theory,
// and electronic component calculations

/// XL Scale - Inductive Reactance: XL = 2πfL (in ohms)
/// Used for: AC circuit analysis, filter design, impedance matching
/// Formula: log₁₀(2πfL) over 12 cycles spanning mΩ to MΩ
/// The scale shows reactance values with dual labeling for resistance and time constant
public struct InductiveReactanceFunction: ScaleFunction {
    public let name = "inductive-reactance"
    public let cycles: Int
    
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // Formula: log(0.5 * π * value) / 12 cycles normalized
        // Where value represents the frequency × inductance product
        log10(0.5 * .pi * value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = transformedValue * Double(cycles)
        return pow(10, logValue) / (0.5 * .pi)
    }
}

/// Xc Scale - Capacitive Reactance: Xc = 1/(2πfC) (in ohms)
/// Used for: AC circuit analysis, filter design, coupling/decoupling calculations
/// Formula: log₁₀(1/(2πfC)) over 12 cycles (inverted reactance)
/// Shows reciprocal relationship with dual labeling for resistance and time constant
public struct CapacitiveReactanceFunction: ScaleFunction {
    public let name = "capacitive-reactance"
    public let cycles: Int
    
    public init(cycles: Int = 12) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript formula: log10(5π/value)/12 + (1 - cycle/12)
        // Simplified: (log10(5π/value) + 11) / 12 for 12 cycles
        // The cycle offset (1 - N/12) is implicit in the algebra
        (log10(5.0 * .pi / value) + Double(cycles - 1)) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = transformedValue * Double(cycles) - Double(cycles - 1)
        return 5.0 * .pi / pow(10, logValue)
    }
}

/// F Scale - Frequency Scale (Hz, kHz, MHz, GHz)
/// Used for: RF calculations, signal processing, filter design
/// Range: 0.001 Hz to 1 GHz over 12 logarithmic cycles
/// Standard logarithmic scale with engineering unit prefixes
public struct FrequencyFunction: ScaleFunction {
    public let name = "frequency"
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

/// L Scale - Inductance Scale (µH, mH, H)
/// Used for: Inductor selection, filter design, energy storage calculations
/// Range: 0.001 µH to 100 H over 12 logarithmic cycles
/// Standard logarithmic scale with engineering unit prefixes
public struct InductanceFunction: ScaleFunction {
    public let name = "inductance"
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

/// Reflection Coefficient Scale (r1, r2) - VSWR and Return Loss
/// Used for: Transmission line analysis, antenna matching, RF measurements
/// Formula: (1 - √(1 - (ρ/2)²)) × 0.472
/// Range: 0.5 to 50 (VSWR), mapped nonlinearly
/// Historical note: Critical for Smith chart calculations and impedance matching
public struct ReflectionCoefficientFunction: ScaleFunction {
    public let name = "reflection-coefficient"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript formula: { 1 1 1 4 -1 roll div .5 mul sub sub .472 mul }
        // Simplified: (0.5 / value) × 0.472
        (0.5 / value) * 0.472
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // Inverse: value = 0.5 / (transformedValue / 0.472)
        0.5 / (transformedValue / 0.472)
    }
}

/// Power Ratio Scale (P, Q) - Decibels and Power Ratios
/// Used for: dB calculations, amplifier gain, signal attenuation
/// Formula: (x² / 14²) × 0.477 + 0.523
/// Range: 0 to 14 (representing power ratios in dB)
/// Maps power ratios to logarithmic scale for dB conversion
public struct PowerRatioFunction: ScaleFunction {
    public let name = "power-ratio"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        // Formula: (value² / 196) × 0.477 + 0.523
        // Maps power ratios to dB scale
        let normalized = (value * value) / (14.0 * 14.0)
        return normalized * 0.477 + 0.523
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let normalized = (transformedValue - 0.523) / 0.477
        return sqrt(normalized * 14.0 * 14.0)
    }
}

/// Z Scale - Impedance Scale (Ω, kΩ, MΩ)
/// Used for: Impedance matching, circuit analysis, transmission line design
/// Range: 1 mΩ to 100 MΩ over 6 logarithmic cycles
/// Standard logarithmic impedance scale with engineering prefixes
public struct ImpedanceFunction: ScaleFunction {
    public let name = "impedance"
    public let cycles: Int
    
    public init(cycles: Int = 6) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue * Double(cycles))
    }
}

/// Cz Scale - Capacitance Scale for Impedance Calculations (pF, nF, µF)
/// Used for: Capacitor selection, impedance calculations, filter design
/// Range: 1 pF to 1000 µF over 12 logarithmic cycles
/// Similar to standard C scale but optimized for impedance work
public struct CapacitanceImpedanceFunction: ScaleFunction {
    public let name = "capacitance-impedance"
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

/// Cf Scale - Capacitive Reactance/Frequency Product
/// Used for: RC time constant calculations, frequency-dependent capacitance effects
/// Formula: log₁₀(100/(3.948 × fC)) over 11 cycles, inverted
/// Complex scale combining frequency and capacitance for reactance calculations
public struct CapacitanceFrequencyFunction: ScaleFunction {
    public let name = "capacitance-frequency"
    public let cycles: Int
    private let scaleFactor: Double = 3.94784212 // Special scaling constant
    
    public init(cycles: Int = 11) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript formula uses explicit /12 div, not cycles
        // curcycle 1 add creates cycle+1 offset that cancels in the algebra
        // Simplified: 1 - log10(scaleFactor × value) / 12
        1.0 - log10(scaleFactor * value) / 12.0
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = (1.0 - transformedValue) * 12.0
        return pow(10, logValue) / scaleFactor
    }
}

/// Fo Scale - Frequency/Wavelength Scale
/// Used for: RF and microwave work, wavelength calculations, antenna design
/// Formula: Inverted log scale over 6 cycles showing frequency and corresponding wavelength
/// Dual labeling shows frequency in Hz and wavelength in meters
/// Historical note: Essential for radio and radar work, c = fλ relationship
public struct FrequencyWavelengthFunction: ScaleFunction {
    public let name = "frequency-wavelength"
    public let cycles: Int
    
    public init(cycles: Int = 6) {
        self.cycles = cycles
    }
    
    public func transform(_ value: ScaleValue) -> Double {
        // PostScript formula: 1 - [log10(value)/6 + (cycle-1)/6]
        // The (cycle-1)/6 offset cancels with the implicit decade offset
        // Simplified: 1 - log10(value) / 6
        1.0 - log10(value) / Double(cycles)
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let logValue = (1.0 - transformedValue) * Double(cycles)
        return pow(10, logValue)
    }
}

// MARK: - Label Formatters for EE Scales

public enum EELabelFormatters {
    /// Format with engineering units and cycle-based prefixes
    public static func reactanceFormatter(units: [String], cycle: Int) -> @Sendable (ScaleValue) -> String {
        return { value in
            let cycleIndex = cycle - 1
            guard cycleIndex >= 0 && cycleIndex < units.count else { return "\(Int(value.rounded()))" }
            let unit = units[cycleIndex]
            if unit == "*" || unit == "**" || unit.isEmpty {
                return "\(Int(value.rounded()))"
            }
            return unit
        }
    }
    
    /// Format frequencies with appropriate SI prefixes
    public static let frequencyFormatter: @Sendable (ScaleValue, Int) -> String = { value, cycle in
        let units = [".001Hz", "*", "**", "1Hz", "*", "**", "1KHz", "*", "**", "1MHz", "*", "**", "1GHz"]
        let cycleIndex = cycle - 1
        guard cycleIndex >= 0 && cycleIndex < units.count else { return "\(Int(value.rounded()))" }
        let unit = units[cycleIndex]
        if unit == "*" || unit == "**" {
            return "\(Int(value.rounded()))"
        }
        return unit
    }
    
    /// Format inductance values with appropriate SI prefixes
    public static let inductanceFormatter: @Sendable (ScaleValue, Int) -> String = { value, cycle in
        let units = ["**", ".001µH", "*", "**", "1µH", "*", "**", "1mH", "*", "**", "1H", "*", "100H"]
        let cycleIndex = cycle - 1
        guard cycleIndex >= 0 && cycleIndex < units.count else { return "\(Int(value.rounded()))" }
        let unit = units[cycleIndex]
        if unit == "*" || unit == "**" {
            return "\(Int(value.rounded()))"
        }
        return unit
    }
    
    /// Format impedance values with SI prefixes
    public static let impedanceFormatter: @Sendable (ScaleValue, Int) -> String = { value, cycle in
        let units = ["Ω", "kΩ", "MΩ"]
        let cycleIndex = (cycle - 1) / 2
        guard cycleIndex >= 0 && cycleIndex < units.count else { return "\(Int(value.rounded()))" }
        return "\(Int((value * pow(10, Double(cycle - 1).truncatingRemainder(dividingBy: 3))).rounded()))\(units[cycleIndex])"
    }
    
    /// Format VSWR/reflection coefficient values
    public static let reflectionFormatter: @Sendable (ScaleValue) -> String = { value in
        if value < 1.0 {
            return String(format: "%.2f", value)
        } else if value < 10.0 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    /// Format power ratio (dB) values
    public static let powerRatioFormatter: @Sendable (ScaleValue) -> String = { value in
        String(format: "%.0f", value)
    }
}

// MARK: - Constants Helper

/// Special constants used in EE slide rules
public enum EEConstants {
    /// Special scaling factor for capacitance-frequency calculations
    public static let cfScaleFactor: Double = 3.94784212
    
    /// Reflection coefficient scaling (related to Smith chart normalization)
    public static let reflectionScaling: Double = 0.472
    
    /// Power ratio normalization
    public static let powerRatioScale: Double = 0.477
    public static let powerRatioOffset: Double = 0.523
}
