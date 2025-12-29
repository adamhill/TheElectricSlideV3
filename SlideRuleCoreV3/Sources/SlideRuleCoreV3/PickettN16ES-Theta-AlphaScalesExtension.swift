import Foundation

// MARK: - Pickett N-16 ES Phase Angle Scales (Θ and α)
// ═══════════════════════════════════════════════════════════════════════════════
//
// PHYSICAL LAYOUT (from actual N-16 ES specimen):
//
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ Θ (THETA) - TICK MARKS POINTING UP                                          │
// │   LEFT HALF: Small angles 5.7° → 0.6° (BLACK decreasing toward center)     │
// │   RIGHT HALF: Large angles 89° → 84.3° (BLACK decreasing toward right)     │
// │   Dual labels: BLACK left of tick, RED right of tick, sum = 90°            │
// │                                                                             │
// │ ═══════════════════════ SHARED BASELINE ═══════════════════════════════════ │
// │                                                                             │
// │ α (ALPHA) - TICK MARKS POINTING DOWN                                        │
// │   Full range: 84.3° → 45° → 5.7° (standard descending)                     │
// │   Dual labels: BLACK left of tick, RED right of tick, sum = 90°            │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// Physical applications (from Chan Street M379 manual):
// - Θ (Theta): Phase shift of circuits whose phase INCREASES with DECREASING frequency
// - α (Alpha): Phase shift of circuits whose phase INCREASES with INCREASING frequency
//
// Reference: ISRM M379 - Chan Street's N16-ES Instructions
// https://sliderulemuseum.org/Manuals/ISRM_M379_Pickett_N16-ES_ElectronicDuplex_Instructions_GiftOfPollyHattemer.pdf
// ═══════════════════════════════════════════════════════════════════════════════

extension StandardScales {
    
    // MARK: - THETA Scale (Split Dual-Range for Extreme Angles)
    
    /// Θ - Phase Angle Scale for Extreme Phase Shifts
    ///
    /// **Physical Structure:**
    /// - Tick marks point UP (toward top edge of stator)
    /// - Shares baseline with ALPHA scale below
    /// - LEFT HALF: Small angles 5.71° → ~0.57° (BLACK decreasing toward center)
    /// - RIGHT HALF: Large angles ~89.43° → 84.29° (BLACK decreasing toward right)
    ///
    /// **Dual Labeling (same pattern as S scale):**
    /// - BLACK label: LEFT side of tick mark (primary angle)
    /// - RED label: RIGHT side of tick mark with ">" (complementary, 90° - primary)
    ///
    /// **Physical Meaning (from Chan Street manual):**
    /// "Phase shift angle (voltage with respect to current) of circuits whose
    /// phase increases with DECREASING frequency (reads against frequency F scale)"
    ///
    /// **Range on Physical Rule:**
    /// - Left edge: 5.71° BLACK / 84.29°> RED (inset ~2mm from absolute edge)
    /// - Center: ~0.57° BLACK / ~89.43°> RED meeting ~89.43° BLACK / ~0.57°> RED
    /// - Right edge: 84.29° BLACK / 5.71°> RED
    ///
    public static func phaseAngleThetaScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Θ")
            //.withAliases(["THETA", "θ", "PHASE-THETA"])
            .withFormula("Split: small angles left, large angles right")
            .withFunction(ThetaSplitScaleFunction())
            .withRange(begin: 5.71, end: 84.29)
            .withLength(length)
            .withTickDirection(.up)  // CORRECT: Ticks point UP
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // LEFT HALF: Small angles 5.71° → ~0.57° (DECREASING toward center)
                // Physical spacing EXPANDS as angles decrease (more room for fine ticks)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 5.71° → 5°: Left edge (inset ~2mm from absolute edge)
                ScaleSubsection(startValue: 5.71, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 5° → 4°: Dense region
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 4° → 3°
                ScaleSubsection(startValue: 4.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 3° → 2°
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 2° → 1°: More expanded, finer ticks possible
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 1° → 0.8°: Sub-degree region
                ScaleSubsection(startValue: 1.0, tickIntervals: [0.2, 0.1, 0.05, 0.02], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 0.8° → 0.6°: Approaching center
                ScaleSubsection(startValue: 0.8, tickIntervals: [0.2, 0.1, 0.05, 0.02], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 0.6° → ~0.57°: Center-left (smallest angles on this half)
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // ═══════════════════════════════════════════════════════════════════════
                // RIGHT HALF: Large angles 89.43° → 84.29° (DECREASING toward right)
                // Mirror structure of left half (complements)
                // ═══════════════════════════════════════════════════════════════════════
                
                // ~89.43° → 89.4°: Center-right (largest angles)
                ScaleSubsection(startValue: 89.43, tickIntervals: [0.1, 0.05, 0.02], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 89.4° → 89.2°
                ScaleSubsection(startValue: 89.4, tickIntervals: [0.2, 0.1, 0.05, 0.02], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 89.2° → 89°
                ScaleSubsection(startValue: 89.2, tickIntervals: [0.2, 0.1, 0.05, 0.02], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 89° → 88°: Contracting space
                ScaleSubsection(startValue: 89.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 88° → 87°
                ScaleSubsection(startValue: 88.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 87° → 86°
                ScaleSubsection(startValue: 87.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 86° → 85°
                ScaleSubsection(startValue: 86.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 85° → 84.29°: Right edge
                ScaleSubsection(startValue: 85.0, tickIntervals: [1.0, 0.5, 0.2, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual)
            ])
            .build()
    }
    
    // MARK: - ALPHA Scale (Standard Descending, Middle Range)
    
    /// α - Phase Angle Scale for Middle Range (84.3° → 45° → 5.7°)
    ///
    /// **Physical Structure:**
    /// - Tick marks point DOWN (toward bottom edge, away from THETA)
    /// - Shares baseline with THETA scale above
    /// - Standard descending scale covering the middle range
    ///
    /// **Dual Labeling (same pattern as S scale):**
    /// - BLACK label: LEFT side of tick mark (primary angle)
    /// - RED label: RIGHT side of tick mark with ">" (complementary, 90° - primary)
    ///
    /// **Physical Meaning (from Chan Street manual):**
    /// "Phase shift angle (voltage with respect to current) of circuits whose
    /// phase increases with INCREASING frequency (reads against frequency F scale)"
    ///
    /// **Key Points:**
    /// - 45° at center (tan(45°) = 1, resonance point where R = X)
    /// - ALPHA covers the range that THETA skips
    /// - Together, THETA and ALPHA provide full 0° to 90° coverage
    ///
    public static func phaseAngleAlphaScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("α")
            //.withAliases(["ALPHA", "PHASE-ALPHA"])
            .withFormula("0.5 - 0.5 × log₁₀(tan(α))")
            .withFunction(AlphaScaleFunction())
            // DESCENDING: 84.29° at left (position 0) to 5.71° at right (position 1)
            .withRange(begin: 84.29, end: 5.71)
            .withLength(length)
            .withTickDirection(.down)  // CORRECT: Ticks point DOWN
            .withDefaultTickStyles([.absolutelyNone, .medium, .minor, .tiny])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // LEFT PORTION: 84.29° → 55° (large angles, compressed physical space)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 84.29° → 80°: Left edge (starts exactly at edge)
                ScaleSubsection(startValue: 84.29, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 80° → 70°
                ScaleSubsection(startValue: 80.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 70° → 60°
                ScaleSubsection(startValue: 70.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 60° → 55°
                ScaleSubsection(startValue: 60.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // ═══════════════════════════════════════════════════════════════════════
                // CENTER REGION: 55° → 35° (includes 45° = resonance point)
                // Most expanded - highest precision available
                // ═══════════════════════════════════════════════════════════════════════
                
                // 55° → 50°
                ScaleSubsection(startValue: 55.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 50° → 45°: Approaching center
                ScaleSubsection(startValue: 50.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 45° → 40°: CENTER (45° = tan⁻¹(1), resonance)
                ScaleSubsection(startValue: 45.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 40° → 35°
                ScaleSubsection(startValue: 40.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // ═══════════════════════════════════════════════════════════════════════
                // RIGHT PORTION: 35° → 5.71° (small angles, compressing)
                // ═══════════════════════════════════════════════════════════════════════
                
                // 35° → 30°
                ScaleSubsection(startValue: 35.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 30° → 20°
                ScaleSubsection(startValue: 30.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 20° → 10°
                ScaleSubsection(startValue: 20.0, tickIntervals: [10.0, 5.0, 1.0], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual),
                
                // 10° → 5.71°: Right edge
                ScaleSubsection(startValue: 10.0, tickIntervals: [5.0, 1.0, 0.5], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.alphaScaleDual)
            ])
            .build()
    }
}

// MARK: - Dual Label Formatters for Theta/Alpha Scales

extension StandardLabelFormatter {
    
    /// THETA scale dual labeling: BLACK angle (left) and RED complement (right)
    ///
    /// Following the S scale pattern from PostScript /plabelR and /plabelL
    /// - Left label (BLACK): Primary angle reading
    /// - Right label (RED with ">"): Complementary angle (90° - primary)
    ///
    public static func thetaScaleDual(value: ScaleValue) -> [LabelConfig] {
        let primary = value
        let complementary = 90.0 - value
        
        // Format based on value magnitude
        let primaryText = formatThetaLabel(primary)
        let complementaryText = formatThetaLabel(complementary) + ">"
        
        return [
            // Left label: primary angle in BLACK
            LabelConfig(
                text: primaryText,
                position: .left,
                fontStyle: .regular,
                color: .black,
                fontSizeMultiplier: 1.0,
                offset: Offset(horizontal: -1, vertical: 0)
            ),
            // Right label: complementary angle in RED with ">"
            LabelConfig(
                text: complementaryText,
                position: .right,
                fontStyle: .regular,
                color: .red,
                fontSizeMultiplier: 1.0,
                offset: Offset(horizontal: 1, vertical: 0)
            )
        ]
    }
    
    /// ALPHA scale dual labeling: BLACK angle (left) and RED complement (right)
    ///
    /// Same pattern as THETA but for the standard descending range
    ///
    public static func alphaScaleDual(value: ScaleValue) -> [LabelConfig] {
        let primary = value
        let complementary = 90.0 - value
        
        let primaryText = formatAlphaLabel(primary)
        let complementaryText = formatAlphaLabel(complementary) + ">"
        
        return [
            // Left label: primary angle in BLACK
            LabelConfig(
                text: primaryText,
                position: .left,
                fontStyle: .regular,
                color: .black,
                fontSizeMultiplier: 1.0,
                offset: Offset(horizontal: -1, vertical: 0)
            ),
            // Right label: complementary angle in RED with ">"
            LabelConfig(
                text: complementaryText,
                position: .right,
                fontStyle: .regular,
                color: .red,
                fontSizeMultiplier: 1.0,
                offset: Offset(horizontal: 1, vertical: 0)
            )
        ]
    }
    
    // MARK: - Private Formatters for Theta/Alpha
    
    /// Format THETA scale labels (handles sub-degree values)
    private static func formatThetaLabel(_ angle: Double) -> String {
        if angle < 1.0 {
            // Sub-degree: ".6" for 0.6°, ".8" for 0.8°
            let tenths = Int((angle * 10).rounded())
            return ".\(tenths)°"
        } else if angle < 10.0 {
            // Single digit: "1°", "2°", etc.
            return String(format: "%.0f°", angle.rounded())
        } else {
            // Two digit: "84°", "85°", "89°", etc.
            return String(format: "%.0f°", angle.rounded())
        }
    }
    
    /// Format ALPHA scale labels (standard integer degrees)
    private static func formatAlphaLabel(_ angle: Double) -> String {
        return String(format: "%.0f", angle.rounded())
    }
}

// MARK: - Transform Functions

/// Transform function for THETA split dual-range scale
///
/// Maps small angles (0.57° to 5.71°) to LEFT half (position 0 to 0.5)
/// Maps large angles (84.29° to 89.43°) to RIGHT half (position 0.5 to 1)
///
/// The CENTER of the scale is where smallest small angles meet largest large angles.
///
/// Position formulas:
/// - Left half (small angles θ): position = 0.5 × (1 + log₁₀(tan(θ)))
///   - At θ = 5.71°: tan = 0.1, log = -1, position = 0.5 × (1 + (-1)) = 0
///   - At θ = 0.57°: tan = 0.01, log = -2, position = 0.5 × (1 + (-2)) = -0.5? No...
///
/// Let me recalculate based on observed behavior:
/// - Position 0 (left edge): θ = 5.71° (tan = 0.1)
/// - Position 0.5 (center): θ = 0.57° (tan = 0.01) OR θ = 89.43° (tan = 100)
/// - Position 1 (right edge): θ = 84.29° (tan = 10)
///
/// For LEFT half (small angles, position increases as angle DECREASES):
/// position = 0.5 × (1 + log₁₀(0.1/tan(θ))) = 0.5 × (1 - 1 - log₁₀(tan(θ))) = 0.5 × (-log₁₀(tan(θ)))
/// Wait, that doesn't work either...
///
/// Actually, for the left half where angles DECREASE from 5.71° to 0.57°:
/// - At θ = 5.71°: we want position = 0
/// - At θ = 0.57°: we want position = 0.5
///
/// tan(5.71°) = 0.1, tan(0.57°) = 0.01
/// log₁₀(0.1) = -1, log₁₀(0.01) = -2
///
/// position = 0.5 × (-1 - log₁₀(tan(θ)))
/// At 5.71°: position = 0.5 × (-1 - (-1)) = 0 ✓
/// At 0.57°: position = 0.5 × (-1 - (-2)) = 0.5 ✓
///
/// For RIGHT half (large angles, position increases as angle DECREASES from 89.43° to 84.29°):
/// - At θ = 89.43°: we want position = 0.5
/// - At θ = 84.29°: we want position = 1.0
///
/// tan(89.43°) = 100, tan(84.29°) = 10
/// log₁₀(100) = 2, log₁₀(10) = 1
///
/// position = 0.5 + 0.5 × (2 - log₁₀(tan(θ)))
/// At 89.43°: position = 0.5 + 0.5 × (2 - 2) = 0.5 ✓
/// At 84.29°: position = 0.5 + 0.5 × (2 - 1) = 1.0 ✓
///
public struct ThetaSplitScaleFunction: ScaleFunction, Sendable {
    public let name = "theta-split-scale"
    
    /// Boundary angles
    private let smallAngleMax: Double = 5.71   // tan ≈ 0.1
    private let largeAngleMin: Double = 84.29  // tan ≈ 10
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        let theta = value
        let radians = theta * .pi / 180.0
        
        guard radians > 0 && radians < .pi / 2 else { return 0.5 }
        
        let tanTheta = tan(radians)
        let logTan = log10(tanTheta)
        
        if theta <= smallAngleMax {
            // LEFT HALF: Small angles (5.71° → 0.57°)
            // position = 0.5 × (-1 - log₁₀(tan(θ)))
            return 0.5 * (-1.0 - logTan)
        } else if theta >= largeAngleMin {
            // RIGHT HALF: Large angles (89.43° → 84.29°)
            // position = 0.5 + 0.5 × (2 - log₁₀(tan(θ)))
            return 0.5 + 0.5 * (2.0 - logTan)
        } else {
            // MIDDLE RANGE: Not covered by THETA (use ALPHA instead)
            return 0.5
        }
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        let position = transformedValue
        
        if position <= 0.5 {
            // LEFT HALF: Small angles
            // log₁₀(tan(θ)) = -1 - 2×position
            let logTan = -1.0 - 2.0 * position
            let tanTheta = pow(10, logTan)
            return atan(tanTheta) * 180.0 / .pi
        } else {
            // RIGHT HALF: Large angles
            // log₁₀(tan(θ)) = 2 - 2×(position - 0.5) = 3 - 2×position
            let logTan = 3.0 - 2.0 * position
            let tanTheta = pow(10, logTan)
            return atan(tanTheta) * 180.0 / .pi
        }
    }
}

/// Transform function for ALPHA scale (standard descending)
///
/// Maps angles 84.29° (left) → 45° (center) → 5.71° (right)
///
/// This is the INVERSE of a standard ascending T scale.
///
/// Position formula: position = 0.5 - 0.5 × log₁₀(tan(α))
/// - At α = 84.29°: tan = 10, log = 1, position = 0.5 - 0.5 = 0 (left)
/// - At α = 45°: tan = 1, log = 0, position = 0.5 - 0 = 0.5 (center)
/// - At α = 5.71°: tan = 0.1, log = -1, position = 0.5 + 0.5 = 1 (right)
///
public struct AlphaScaleFunction: ScaleFunction, Sendable {
    public let name = "alpha-scale"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        let alpha = value
        let radians = alpha * .pi / 180.0
        
        guard radians > 0 && radians < .pi / 2 else {
            if radians <= 0 { return 1.0 }
            return 0.0
        }
        
        let tanAlpha = tan(radians)
        let logTan = log10(tanAlpha)
        
        return 0.5 - 0.5 * logTan
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // log₁₀(tan(α)) = (0.5 - position) × 2 = 1 - 2×position
        let logTan = 1.0 - 2.0 * transformedValue
        let tanAlpha = pow(10, logTan)
        return atan(tanAlpha) * 180.0 / .pi
    }
}

// MARK: - Position Reference Tables
// ═══════════════════════════════════════════════════════════════════════════════
//
// THETA SCALE (Split Dual-Range, TICK MARKS UP):
//
// LEFT HALF (Small Angles, BLACK decreasing → center):
// | BLACK (L) | tan(θ)  | log₁₀   | Position | RED (R)  |
// |-----------|---------|---------|----------|----------|
// | 5.71°     | 0.100   | -1.000  | 0.000    | 84.29°>  |
// | 5°        | 0.0875  | -1.058  | 0.029    | 85°>     |
// | 4°        | 0.0699  | -1.156  | 0.078    | 86°>     |
// | 3°        | 0.0524  | -1.281  | 0.140    | 87°>     |
// | 2°        | 0.0349  | -1.457  | 0.228    | 88°>     |
// | 1°        | 0.0175  | -1.757  | 0.379    | 89°>     |
// | .8°       | 0.0140  | -1.855  | 0.427    | 89.2°>   |
// | .6°       | 0.0105  | -1.980  | 0.490    | 89.4°>   |
//
// RIGHT HALF (Large Angles, BLACK decreasing → right):
// | BLACK (L) | tan(θ)  | log₁₀   | Position | RED (R)  |
// |-----------|---------|---------|----------|----------|
// | 89.4°     | 95.49   | 1.980   | 0.510    | .6°>     |
// | 89.2°     | 71.62   | 1.855   | 0.573    | .8°>     |
// | 89°       | 57.29   | 1.758   | 0.621    | 1°>      |
// | 88°       | 28.64   | 1.457   | 0.772    | 2°>      |
// | 87°       | 19.08   | 1.281   | 0.860    | 3°>      |
// | 86°       | 14.30   | 1.156   | 0.922    | 4°>      |
// | 85°       | 11.43   | 1.058   | 0.971    | 5°>      |
// | 84.29°    | 10.00   | 1.000   | 1.000    | 5.71°>   |
//
// ALPHA SCALE (Standard Descending, TICK MARKS DOWN):
//
// | BLACK (L) | tan(α)  | log₁₀   | Position | RED (R)  |
// |-----------|---------|---------|----------|----------|
// | 84        | 9.51    | 0.978   | 0.011    | 6>       |
// | 80        | 5.67    | 0.754   | 0.123    | 10>      |
// | 70        | 2.75    | 0.439   | 0.281    | 20>      |
// | 60        | 1.73    | 0.239   | 0.381    | 30>      |
// | 50        | 1.19    | 0.076   | 0.462    | 40>      |
// | 45        | 1.00    | 0.000   | 0.500    | 45>      |
// | 40        | 0.84    | -0.076  | 0.538    | 50>      |
// | 30        | 0.58    | -0.239  | 0.619    | 60>      |
// | 20        | 0.36    | -0.439  | 0.719    | 70>      |
// | 10        | 0.18    | -0.754  | 0.877    | 80>      |
// | 6         | 0.105   | -0.978  | 0.989    | 84>      |
//
// ═══════════════════════════════════════════════════════════════════════════════

// MARK: - Scale Rendering Notes
//
// To render the complete THETA/ALPHA pair on the N-16 ES back face:
//
// 1. Render ALPHA first (lower scale):
//    - Tick marks point DOWN
//    - Dual labels: BLACK left, RED right
//    - Baseline at Y = baseline_y
//
// 2. Render THETA second (upper scale):
//    - Tick marks point UP
//    - Dual labels: BLACK left, RED right
//    - Baseline SHARED with ALPHA at Y = baseline_y
//
// 3. Labels will never overlap because:
//    - THETA labels are ABOVE the shared baseline
//    - ALPHA labels are BELOW the shared baseline
//    - Each scale's dual labels (BLACK/RED) are on opposite sides of their ticks
//
// The visual result matches the physical N-16 ES where these two scales
// appear as a "sandwich" with tick marks pointing away from each other.
