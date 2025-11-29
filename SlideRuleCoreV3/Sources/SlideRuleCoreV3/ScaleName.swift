//
//  ScaleName.swift
//  SlideRuleCoreV3
//
//  Type-safe scale name identifiers with human-readable descriptions and aliases
//

import Foundation

/// Type-safe identifier for slide rule scale names
/// Provides canonical names, human-readable descriptions, and common aliases
public enum ScaleName: String, CaseIterable, Sendable {
    // MARK: - Basic Logarithmic Scales
    
    case c = "C"
    case d = "D"
    case ci = "CI"
    case di = "DI"
    
    // MARK: - Folded Scales
    
    case cf = "CF"
    case df = "DF"
    case cif = "CIF"
    case dif = "DIF"
    case dfm = "DFm"
    
    // MARK: - Square Scales
    
    case a = "A"
    case b = "B"
    case ai = "AI"
    case bi = "BI"
    
    // MARK: - Cube Scale
    
    case k = "K"
    
    // MARK: - Log-Log Scales
    
    case ll00 = "LL00"
    case ll01 = "LL01"
    case ll02 = "LL02"
    case ll03 = "LL03"
    case ll0 = "LL0"
    case ll1 = "LL1"
    case ll2 = "LL2"
    case ll3 = "LL3"
    
    // MARK: - Trigonometric Scales
    
    case s = "S"
    case t = "T"
    case st = "ST"
    
    // MARK: - Logarithmic Scales
    
    case l = "L"
    case ln = "Ln"
    
    // MARK: - Hyperbolic Scales
    
    case sh = "Sh"
    case sh1 = "Sh1"
    case sh2 = "Sh2"
    case ch = "Ch"
    case th = "Th"
    case h1 = "H1"
    case h2 = "H2"
    
    // MARK: - Special Purpose Scales
    
    case p = "P"
    case pa = "PA"
    case l360 = "L360"
    case l180 = "L180"
    
    // MARK: - Extended Range Scales
    
    case c10_100 = "C10-100"
    case d10_100 = "D10-100"
    case c100_1000 = "C100-1000"
    
    // MARK: - Circular Scales
    
    case cr3s = "CR3S"
    case cas = "CAS"
    case time = "TIME"
    case time2 = "TIME2"
    case sc = "S/C"
    
    // MARK: - Square/Cube Root Scales
    
    case r1 = "R1"
    case r2 = "R2"
    case sq1 = "SQ1"
    case sq2 = "SQ2"
    case q1 = "Q1"
    case q2 = "Q2"
    case q3 = "Q3"
    
    // MARK: - Keuffel & Esser Variants
    
    case keS = "KE-S"
    case keT = "KE-T"
    case keST = "KE-ST"
    
    // MARK: - Electrical Engineering Scales (Hemmi 266)
    
    case xl = "XL"      // Inductive Reactance
    case xc = "Xc"      // Capacitive Reactance
    case f = "F"        // Frequency
    case r1EE = "r1"    // Resistance/Impedance 1
    case r2EE = "r2"    // Resistance/Impedance 2
    case q = "Q"        // Quality Factor
    case li = "Li"      // Inductance
    case cf_ee = "Cf"   // Capacitance (farads)
    case cz = "Cz"      // Capacitance (microfarads)
    case z = "Z"        // Impedance
    case fo = "Fo"      // Resonant Frequency
    case blank = "blank" // Spacer/blank scale
    
    // MARK: - Hemmi 266 Special Log-Log Scales
    
    case h266LL03 = "H266LL03"
    case h266LL01 = "H266LL01"
    case ll02B = "LL02B"
    case ll2B = "LL2B"
    
    // MARK: - Human-Readable Description
    
    /// Human-readable description of this scale's purpose
    public var description: String {
        switch self {
        // Basic scales
        case .c: return "Basic logarithmic scale (multiply/divide)"
        case .d: return "Basic logarithmic scale (paired with C)"
        case .ci: return "Inverted C scale (reciprocals)"
        case .di: return "Inverted D scale (reciprocals)"
            
        // Folded scales
        case .cf: return "C scale folded at π (3.14...)"
        case .df: return "D scale folded at π"
        case .cif: return "Inverted CF scale"
        case .dif: return "Inverted DF scale"
        case .dfm: return "DF scale folded at M (0.4343...)"
            
        // Square scales
        case .a: return "Square scale (x²)"
        case .b: return "Square scale (x²)"
        case .ai: return "Inverted A scale (1/x²)"
        case .bi: return "Inverted B scale (1/x²)"
            
        // Cube scale
        case .k: return "Cube scale (x³)"
            
        // Log-Log scales
        case .ll00, .ll0: return "Log-log scale (e^0.001x to e^0.01x)"
        case .ll01, .ll1: return "Log-log scale (e^0.01x to e^0.1x)"
        case .ll02, .ll2: return "Log-log scale (e^0.1x to e^1x)"
        case .ll03, .ll3: return "Log-log scale (e^1x to e^10x)"
            
        // Trigonometric
        case .s: return "Sine scale (angles in degrees)"
        case .t: return "Tangent scale (angles in degrees)"
        case .st: return "Small tangent scale (for small angles)"
            
        // Logarithmic
        case .l: return "Common logarithm scale (log₁₀)"
        case .ln: return "Natural logarithm scale (ln)"
            
        // Hyperbolic
        case .sh, .sh1, .sh2: return "Hyperbolic sine scale"
        case .ch: return "Hyperbolic cosine scale"
        case .th: return "Hyperbolic tangent scale"
        case .h1, .h2: return "Hyperbolic function scale"
            
        // Special purpose
        case .p: return "Pythagorean scale (√(1+x²))"
        case .pa: return "Position angle scale"
        case .l360: return "360-degree conversion scale"
        case .l180: return "180-degree conversion scale"
            
        // Extended range
        case .c10_100: return "C scale from 10 to 100"
        case .d10_100: return "D scale from 10 to 100"
        case .c100_1000: return "C scale from 100 to 1000"
            
        // Circular
        case .cr3s: return "Circular rule speed scale"
        case .cas: return "Circular angle scale"
        case .time, .time2: return "Time conversion scale"
        case .sc: return "Speed/distance scale"
            
        // Roots
        case .r1, .r2: return "Square root scale"
        case .sq1, .sq2: return "Square scale variant"
        case .q1, .q2, .q3: return "Cube root scale"
            
        // K&E variants
        case .keS: return "Keuffel & Esser sine scale (5.5° to 90°)"
        case .keT: return "Keuffel & Esser tangent scale"
        case .keST: return "Keuffel & Esser small tangent scale"
            
        // Electrical Engineering
        case .xl: return "Inductive reactance (XL = 2πfL)"
        case .xc: return "Capacitive reactance (Xc = 1/2πfC)"
        case .f: return "Frequency (Hz)"
        case .r1EE, .r2EE: return "Resistance/Impedance (Ω)"
        case .q: return "Quality factor (Q = XL/R)"
        case .li: return "Inductance (henries)"
        case .cf_ee: return "Capacitance (farads)"
        case .cz: return "Capacitance (microfarads)"
        case .z: return "Impedance (Ω)"
        case .fo: return "Resonant frequency"
        case .blank: return "Spacer (no scale)"
            
        // Hemmi 266 special
        case .h266LL03: return "Hemmi 266 log-log scale variant"
        case .h266LL01: return "Hemmi 266 log-log scale variant"
        case .ll02B, .ll2B: return "Log-log scale variant"
        }
    }
    
    // MARK: - Aliases
    
    /// Common alternative names for this scale
    public var aliases: [String] {
        switch self {
        case .c10_100: return ["C10.100"]
        case .d10_100: return ["D10.100"]
        case .c100_1000: return ["C100.1000"]
        case .keS: return ["KES"]
        case .keT: return ["KET"]
        case .keST: return ["KEST", "SRT"]
        case .sc: return ["SC"]
        case .dfm: return ["DF/M", "DFM"]
        default: return []
        }
    }
    
    // MARK: - Lookup Methods
    
    /// Find a ScaleName by string, checking canonical name and aliases
    /// - Parameter name: The scale name to look up (case-insensitive)
    /// - Returns: The matching ScaleName, or nil if not found
    public static func lookup(_ name: String) -> ScaleName? {
        let normalized = name.uppercased()
        
        // Check canonical names (case-insensitive)
        for scale in ScaleName.allCases where scale.rawValue.uppercased() == normalized {
            return scale
        }
        
        // Check aliases
        for scale in ScaleName.allCases where scale.aliases.contains(where: { $0.uppercased() == normalized }) {
            return scale
        }
        
        return nil
    }
    
    /// Get the canonical display name for a given string
    /// If the string matches a known scale, returns the canonical name
    /// Otherwise returns the original string
    public static func canonicalName(for name: String) -> String {
        lookup(name)?.rawValue ?? name
    }
}
