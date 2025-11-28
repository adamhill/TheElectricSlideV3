import Foundation

// MARK: - DF_M Scale Enhancement
//
// This file enhances the existing dfmScale implementation with:
// 1. Dedicated ScaleFunction implementations for DF_M variants
// 2. PostScript engine variant (lines 476-482)
// 3. Comprehensive mathematical documentation
// 4. Physical application examples
//
// NOTE: The primary dfmScale() is already defined in StandardScales.swift.
// This file adds the scale functions and the PostScript variant.

// MARK: - PostScript Concordance
//
// Source: postscript-engine-for-sliderules.ps, Lines 476-482
//
// PostScript Definition:
// /DFmscale Cscale ddup def DFmscale begin
//     /title (DFm) def
//     /tickdir -1 def
//     /beginscale 4.35 def
//     /endscale 43.5 def
//     /formula {log e log 10 mul log sub} def
// end
//
// IMPORTANT: Two variants exist:
// 1. PostScript variant (lines 476-482): Range 4.35 to 43.5 (≈10M to 100M)
//    Formula: log₁₀(x) - log₁₀(10M) where M = log₁₀(e)
//
// 2. Pickett 803 variant (per manual): Range M to 10M (≈0.434 to 4.34)
//    This allows direct reading of log₁₀(x) values when cursor is aligned with LL scales
//    ALREADY IMPLEMENTED in StandardScales.dfmScale()
//
// MATHEMATICAL FOUNDATION:
// ========================
// The DF_M scale is a D scale "folded" at M = log₁₀(e) ≈ 0.43429448190325176
// 
// M is also known as:
//   - The "modulus" of common logarithms
//   - The conversion factor: log₁₀(x) = M × ln(x)
//   - 1/ln(10) ≈ 0.43429
//
// PURPOSE:
// When the cursor is positioned over a value x on an LL scale:
//   - The D scale shows ln(x) (natural logarithm)
//   - The DF_M scale shows log₁₀(x) (common logarithm)
//
// This works because: log₁₀(x) = ln(x) × M
//
// On a standard D scale at position p:
//   - D shows: 10^p
//   - ln(10^p) = p × ln(10)
//
// On DF_M at the same position p:
//   - DF_M shows: M × 10^p
//   - This equals: log₁₀(e) × 10^p
//
// When aligned with LL scales:
//   - If LL3+ shows value x, the cursor position p = log₁₀(ln(x))
//   - D shows: 10^p = ln(x)
//   - DF_M shows: M × 10^p = M × ln(x) = log₁₀(x) ✓
//
// PHYSICAL APPLICATIONS:
// =====================
// 1. Direct logarithm conversion: Read log₁₀(x) directly when finding powers
// 2. Engineering calculations: Convert between natural and common logarithms
// 3. Decibel calculations: dB = 10 × log₁₀(P₂/P₁), directly readable
// 4. pH calculations: pH = -log₁₀[H⁺], directly readable
// 5. Richter scale: Magnitude = log₁₀(A/A₀), directly readable
//
// WORKED EXAMPLE (from Pickett 803 manual):
// =========================================
// Find log₁₀(15):
// 1. Set hairline over 15 on LL3+ scale
// 2. Read 1.176 directly on DF_M scale
// 3. Verify: log₁₀(15) = 1.17609... ≈ 1.176 ✓
//
// Find log₁₀(4):
// 1. Set hairline over 4.0 on LL3+ scale  
// 2. Read 0.602 on DF_M scale
// 3. Verify: log₁₀(4) = 0.60206... ≈ 0.602 ✓

// MARK: - DF_M Scale Function (Pickett 803 Variant)

/// DFmFoldedFunction: D scale folded at M = log₁₀(e)
/// 
/// PostScript Reference: Lines 476-482 (adapted for Pickett 803 range)
/// Formula: log₁₀(x) with range M to 10M
///
/// This function implements the Pickett 803 style DF_M scale that allows
/// direct reading of common logarithms when used with LL scales.
///
/// Mathematical Properties:
/// - At position 0: value = M ≈ 0.43429
/// - At position 0.5: value = √10 × M ≈ 1.373
/// - At position 1: value = 10M ≈ 4.3429
///
/// The scale shows log₁₀(x) values directly when aligned with LL scales
/// because log₁₀(x) = M × ln(x), and the D scale shows ln(x) at any
/// LL scale alignment.
public struct DFmFoldedFunction: ScaleFunction {
    public let name = "dfm-folded"
    
    public init() {}
    
    /// Transform using standard logarithm
    /// The folding is handled by the scale's range (M to 10M), not the function
    public func transform(_ value: ScaleValue) -> Double {
        log10(value)
    }
    
    /// Inverse: convert normalized log back to value
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue)
    }
}

// MARK: - DF_M Scale Function (PostScript Variant)

/// DFmPostScriptFunction: D scale with PostScript formula
///
/// PostScript Reference: Lines 476-482
/// Formula: {log e log 10 mul log sub}
///
/// RPN Translation:
/// - x log         → log₁₀(x)
/// - e log         → log₁₀(e) = M
/// - 10 mul        → 10 × M = 10M
/// - log           → log₁₀(10M)
/// - sub           → log₁₀(x) - log₁₀(10M)
///
/// Final formula: log₁₀(x) - log₁₀(10M) = log₁₀(x / 10M)
///
/// This is equivalent to a standard log scale with range 10M to 100M
public struct DFmPostScriptFunction: ScaleFunction {
    public let name = "dfm-postscript"
    
    /// The modulus M = log₁₀(e)
    private let M = Double.log10e
    
    public init() {}
    
    /// PostScript formula: log₁₀(x) - log₁₀(10M)
    public func transform(_ value: ScaleValue) -> Double {
        log10(value) - log10(10 * M)
    }
    
    /// Inverse: x = 10^(result + log₁₀(10M))
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        pow(10, transformedValue + log10(10 * M))
    }
}

// MARK: - Standard Scales Extension (PostScript Variant Only)
//
// NOTE: The primary dfmScale() already exists in StandardScales.swift
// This extension adds only the PostScript variant for completeness.

extension StandardScales {
    
    // MARK: - DF_M Scale (PostScript Variant)
    
    /// DF_M scale: PostScript engine variant with range 10M to 100M
    ///
    /// PostScript Reference: Lines 476-482
    /// Range: 4.35 to 43.5 (≈ 10M to 100M)
    /// Formula: {log e log 10 mul log sub}
    ///
    /// Note: This variant has a different range than the Pickett 803.
    /// Use the existing dfmScale() for the Pickett 803 compatible version.
    ///
    /// This scale is included for PostScript engine compatibility and for
    /// slide rules that use the larger range variant.
    public static func dfmPostScriptScale(length: Distance = 250.0) -> ScaleDefinition {
        let M = Double.log10e
        let begin = 10 * M  // ≈ 4.3429
        let end = 100 * M   // ≈ 43.429
        
        return ScaleBuilder()
            .withName("DFm-PS")
            .withFormula("log₁₀x")
            .withFunction(DFmPostScriptFunction())
            .withRange(begin: begin, end: end)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                // PostScript style subsections matching C scale pattern
                ScaleSubsection(
                    startValue: begin,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1]
                ),
                ScaleSubsection(
                    startValue: 5.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 40.0,
                    tickIntervals: [5.0, 1.0, 0.5],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .addConstant(value: 10.0, label: "10", style: .major)
            .build()
    }
}

// MARK: - Mathematical Constants Extension
//
// NOTE: Double.log10e is already defined in StandardScales.swift (line 1738)
// This extension adds the modulusM alias for documentation clarity.

extension Double {
    /// Alias for log10e, commonly used in slide rule documentation
    /// as "M" (the modulus of common logarithms)
    ///
    /// Usage: Double.modulusM or just M in contexts where Double is inferred
    ///
    /// Value: 0.43429448190325176
    /// Identity: M = log₁₀(e) = 1/ln(10)
    public static let modulusM: Double = log10e
}
