import Foundation

// MARK: - Pickett N16-ES THETA and ALPHA Scales
//
// ## Implementation Status: ✅ COMPLETE
//
// This file implements the THETA (Θ₁, Θ₂) and ALPHA (α) scales for the
// Pickett N16-ES Electronic slide rule.
//
// ## Split Scale Architecture
//
// The THETA scales use the split scale system to share one physical scale line:
// - Θ₁ (phaseAngleThetaSmallScale): Left half (0-50%)
//   - Domain: 6.0° → 0.0° (unlabeled boundary at 6.0°)
//   - First labeled tick: 5.7° (~2-3mm inset from left edge)
//   - Split segment: .left(formulaOffset: 0.0)
//
// - Θ₂ (phaseAngleThetaLargeScale): Right half (50-100%)
//   - Domain: 0.0° → 5.71°
//   - Split segment: .right(formulaOffset: 0.0)
//
// - α (alphaScale): Full width, ticks point DOWN
//   - Domain: 84.29° → 5.71°
//   - Complementary scale to THETA
//
// ## Dual Label Formatting
//
// Both THETA and ALPHA use dual label formatters that show:
// - Primary angle (black, left-aligned)
// - Complementary angle (red, right-aligned with ">")
//
// ## Label Suppression
//
// The 6.0° tick on Θ₁ is unlabeled to match the physical Pickett N-16 ES,
// which has the 5.7° label (~2-3mm) inset from the left edge.
// This is handled in thetaScaleDual() formatter.
//
// ## References
// - split-scales-implementation-plan.md
// - postscript-caret-symbol-no-linebreak.md (PostScript heritage)
//
// PHYSICAL LAYOUT (from actual N-16 ES specimen):
//
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ Θ (THETA) - TICK MARKS POINTING UP                                          │
// │   LEFT HALF: Small angles 6.0° → 0.57° (BLACK decreasing toward center)    │
// │              Labels ONLY at: 5.7°, 5°, 4°, 3°, 2°, 1°, .8°, .6°            │
// │              Center tick at 0.57° is UNLABELED                              │
// │   RIGHT HALF: Large angles 89.43° → 84.29° (BLACK decreasing)              │
// │   Dual labels: BLACK left of tick, RED right of tick, sum = 90°            │
// │                                                                             │
// │ ═══════════════════════ SHARED BASELINE ═══════════════════════════════════ │
// │                                                                             │
// │ α (ALPHA) - TICK MARKS POINTING DOWN                                        │
// │   Full range: 84.29° → 45° → 5.71° (standard descending)                   │
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
    
    // MARK: - THETA Scale (Two Independent Scales for Extreme Angles)
    
    /// Θ₁ (THETA SMALL) - Phase Angle Scale for SMALL Angles
    ///
    /// **Physical Structure:**
    /// - Tick marks point UP (toward top edge of stator)
    /// - Shares baseline with ALPHA scale below
    /// - LEFT HALF of the physical THETA scale: 6.0° → 0.57° (BLACK decreasing toward center)
    ///
    /// **CRITICAL DOMAIN SPECIFICATION:**
    /// - Domain STARTS at 6.0° (left edge of scale) but 6.0° has NO tick mark or label
    /// - FIRST VISIBLE tick mark and label is "5.7°" 
    /// - This matches the physical Pickett N-16 ES where 5.7° is the leftmost labeled tick
    /// - The 6.0° domain boundary is required for proper logarithmic positioning
    ///
    /// **Dual Labeling (same pattern as S scale):**
    /// - BLACK label: LEFT side of tick mark (primary angle)
    /// - RED label: RIGHT side of tick mark with ">" (complementary, 90° - primary)
    ///
    /// **Physical Meaning (from Chan Street manual):**
    /// "Phase shift angle (voltage with respect to current) of circuits whose
    /// phase increases with DECREASING frequency (reads against frequency F scale)"
    ///
    /// **Range:** 6.0° → 0.57° (6.0° is domain start with NO tick/label, 0.57° is CENTER boundary, also unlabeled)
    ///
    /// **Labels:** ONLY at major angles: 5.7°, 5°, 4°, 3°, 2°, 1°, .8°, .6° (NOT at 6.0° or 0.57°)
    ///
    /// **Transform:** position = -1 - log₁₀(tan(θ))
    /// - At θ = 6.0°: tan ≈ 0.1051, log ≈ -0.978, position ≈ -0.022 (domain start, NO tick)
    /// - At θ = 5.71°: tan = 0.1, log = -1, position = 0 (near left edge)
    /// - At θ = 0.6°: tan ≈ 0.0105, log ≈ -1.98, position ≈ 0.98
    /// - At θ = 0.57°: tan = 0.01, log = -2, position = 1.0 (CENTER - unlabeled tick)
    ///
    public static func phaseAngleThetaSmallScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Θ₁")
            //.withAliases(["THETA-SMALL", "θ₁"])
            .withFormula("-1 - log₁₀(tan(θ))")
            .withFunction(ThetaSmallScaleFunction())
            // ═══════════════════════════════════════════════════════════════════════════
            // DOMAIN: 6.0° to 0.57°
            // - 6.0° is the LEFT EDGE of the scale domain (NO tick mark or label here!)
            // - First VISIBLE tick mark is at 5.7° (labeled "5.7°")
            // - 0.57° is the CENTER boundary (unlabeled)
            // This domain is REQUIRED for proper logarithmic positioning of all tick marks
            // ═══════════════════════════════════════════════════════════════════════════
            .withRange(begin: 6.0, end: 0.57)
            .withSuppressBeginBoundaryTick() // No tick at 6.0° (position 0.0)
            .withSuppressBeginBoundaryLabel() // No label at 6.0°
            .withSuppressEndBoundaryLabel() // No label at 0.57° (center boundary)
            .withLength(length)
            .withTickDirection(.up)
            .withSplitSegment(.left(formulaOffset: 0.0))  // LEFT half of split scale
            .withDefaultTickStyles([
                // TICK PATTERN from physical Pickett N-16 ES (HUMAN COUNTED):
                // 5.7→5: 6 ticks, 5→4/4→3/3→2/2→1: 19 ticks each, 1→.8/.8→.6: 3 ticks each
                .major,               // Level 0: Labeled marks ONLY (5.7°, 5°, 4°, 3°, 2°, 1°, .8, .6)
                .medium,              // Level 1: Half-degree marks (0.5°)
                .minor,               // Level 2: Tenth-degree marks (0.1°)
                TickStyle(relativeLength: 0.40, shouldLabel: false, lineWidth: 0.45)  // Level 3: 0.05° marks
            ])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // TICK PATTERN from physical Pickett N-16 ES (HUMAN COUNTED on actual slide rule)
                // 
                // DOMAIN NOTE: Scale domain starts at 6.0° but NO tick mark at 6.0°!
                // The subsections below define ONLY the visible tick marks starting at 5.7°
                //
                // LABELS: 5.7°, 5°, 4°, 3°, 2°, 1°, .8, .6 - NO intermediate labels!
                // ═══════════════════════════════════════════════════════════════════════
                
                // 5.7° → 5°: EXACTLY 6 intermediate ticks at 0.1° intervals
                // ─────────────────────────────────────────────────────────────────────────
                // FIRST VISIBLE TICK: "5.7°" label (NO complement - just black label)
                // Intermediate ticks at: 5.6, 5.5, 5.4, 5.3, 5.2, 5.1 = EXACTLY 6 ticks
                // NOTE: Domain starts at 6.0° but this subsection starts at 5.7° because
                //       6.0° has NO tick mark - it's just the mathematical domain boundary
                // Use 0.7 as level 0 so only 5.7 gets labeled (next 0.7 tick would be 5.0)
                // ─────────────────────────────────────────────────────────────────────────
                ScaleSubsection(startValue: 5.7, tickIntervals: [5.7, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleNoComplement),
                
                // 5° → 4°: 19 intermediate ticks
                // Label: "5° 85°>" ONLY at 5° (dual label with complement)
                // Use 1.0 as level 0 so only 5° gets labeled (not 4.5°)
                // Pattern: 1 tick at 0.5° + 8 ticks at 0.1° + 10 ticks at 0.05° = 19 ticks
                ScaleSubsection(startValue: 5.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 4° → 3°: 19 intermediate ticks  
                // Label: "4° 86°>" ONLY at 4°
                ScaleSubsection(startValue: 4.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 3° → 2°: 19 intermediate ticks
                // Label: "3° 87°>" ONLY at 3°
                ScaleSubsection(startValue: 3.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 2° → 1°: 19 intermediate ticks
                // Label: "2° 88°>" ONLY at 2°
                ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 1° → 0.8°: 3 intermediate ticks at 0.05° intervals
                // Label: "1° 89°>" ONLY at 1° (dual label with complement)
                // Label: ".8" at 0.8° (NO complement - just black label, matches physical scale)
                // Use 0.2 as level 0 for labeled ticks at 1.0 and 0.8
                // Ticks at: 0.95, 0.90, 0.85 = 3 intermediate ticks
                ScaleSubsection(startValue: 1.0, tickIntervals: [0.2, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDualExceptSubDegree),
                
                // 0.8° → 0.6°: 3 intermediate ticks at 0.05° intervals
                // Label: ".8" ONLY at 0.8° (NO complement - just black label)
                // Use 0.2 as level 0 so only 0.8 gets labeled
                // Ticks at: 0.75, 0.70, 0.65 = 3 ticks
                ScaleSubsection(startValue: 0.8, tickIntervals: [0.2, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleNoComplement),
                
                // 0.6° → boundary (0.57°): NO intermediate ticks
                // Label: NONE (0.6° is too close to center boundary)
                ScaleSubsection(startValue: 0.6, tickIntervals: [0.6], labelLevels: [],
                                 dualLabelFormatter: StandardLabelFormatter.thetaScaleNoComplement)
            ])
            .withBaseline(true)  // Shared baseline with ALPHA scale below
            .build()
    }
    
    /// Θ₂ (THETA LARGE) - Phase Angle Scale for LARGE Angles
    ///
    /// **Physical Structure:**
    /// - Tick marks point UP (toward top edge of stator)
    /// - Shares baseline with ALPHA scale below
    /// - RIGHT HALF of the physical THETA scale: 0.57° → 6.0° (MIRRORING Θ₁)
    ///
    /// **CRITICAL DOMAIN SPECIFICATION:**
    /// - Domain ENDS at 6.0° (right edge of scale) but 6.0° has NO tick mark or label
    /// - LAST VISIBLE tick mark and label is "5.7°" (rendered via ScaleConstant)
    /// - This matches the physical Pickett N-16 ES where 5.7° is the rightmost labeled tick
    /// - The 6.0° domain boundary is required for proper logarithmic positioning
    ///
    /// **MIRROR PATTERN:**
    /// - This scale EXACTLY MIRRORS ThetaSmall (Θ₁) but in REVERSE order
    /// - Θ₁: 6.0° → 0.57° (left half, 6.0° unlabeled, first visible label at 5.7°)
    /// - Θ₂: 0.57° → 6.0° (right half, 6.0° unlabeled, last visible label at 5.7°)
    /// - Creates a symmetric fold at the center point (0.57°)
    ///
    /// **Dual Labeling (same pattern as S scale):**
    /// - BLACK label: LEFT side of tick mark (primary angle)
    /// - RED label: RIGHT side of tick mark with ">" (complementary, 90° - primary)
    ///
    /// **Physical Meaning (from Chan Street manual):**
    /// "Phase shift angle (voltage with respect to current) of circuits whose
    /// phase increases with DECREASING frequency (reads against frequency F scale)"
    ///
    /// **Range:** 0.57° → 6.0° (0.57° is CENTER boundary unlabeled, 6.0° is RIGHT EDGE also unlabeled)
    ///
    /// **Transform:** position = 2 - log₁₀(tan(θ))
    /// - At θ = 0.57°: tan = 0.01, log = -2, position = 0 (center boundary)
    /// - At θ = 5.71°: tan = 0.1, log = -1, position ≈ 1.0 (near right edge)
    /// - At θ = 6.0°: tan ≈ 0.1051, log ≈ -0.978, position ≈ 1.022 (domain end, NO tick)
    ///
    public static func phaseAngleThetaLargeScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Θ₂")
            //.withAliases(["THETA-LARGE", "θ₂"])
            .withFormula("2 - log₁₀(tan(θ))")
            .withFunction(ThetaLargeScaleFunction())
            // ═══════════════════════════════════════════════════════════════════════════
            // DOMAIN: 0.57° to 6.0°
            // - 0.57° is the CENTER boundary (unlabeled, shared with Θ₁)
            // - 6.0° is the RIGHT EDGE of the scale domain (NO tick mark or label here!)
            // - Last VISIBLE tick mark is at 5.7° (rendered via ScaleConstant below)
            // This domain is REQUIRED for proper logarithmic positioning of all tick marks
            // ═══════════════════════════════════════════════════════════════════════════
            .withRange(begin: 89.43, end: 84.29)  // Large angles 89.43° (center) → 84.29° (right edge)
            .withSuppressBeginBoundaryLabel()     // No label at center (89.43°)
            .withSuppressEndBoundaryTick()        // No tick at 84.29° (handled by constant 84.3°)
            .withSuppressEndBoundaryLabel()       // No label at 84.29°
            .withLength(length)
            .withTickDirection(.up)
            .rightSegment() // physical 0.5...1.0, formulaOffset: 0.0
            .withDefaultTickStyles([
                .major,               // Level 0: Labeled marks (89, 88, 87, 86, 85)
                .medium,              // Level 1: Half-degree marks
                .minor,               // Level 2: Tenth-degree marks
                TickStyle(relativeLength: 0.40, shouldLabel: false, lineWidth: 0.45)  // Level 3 (0.05°)
            ])
            .withSubsections([
                // ═══════════════════════════════════════════════════════════════════════
                // MIRROR PATTERN: Θ₂ subsections EXACTLY REVERSE Θ₁ intervals
                // ═══════════════════════════════════════════════════════════════════════
                
                // 89.43° → 89.4°: MIRROR of Θ₁ #8 (0.6° → 0.57°)
                // No intermediate ticks
                ScaleSubsection(startValue: 89.43, tickIntervals: [0.6], labelLevels: [],
                               dualLabelFormatter: nil),
                
                                // 89.4° → 89.2°: MIRROR of Θ₁ #7 (0.8° → 0.6°)
                                // [0.1, 0.05] → 3 ticks (89.35, 89.30, 89.25)
                                // Labels: ".6°>" in RED (complement of 89.4)
                                ScaleSubsection(startValue: 89.4, tickIntervals: [0.2, 0.1, 0.05], labelLevels: [0],
                                                dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                                
                                // 89.2° → 89.0°: MIRROR of Θ₁ #6 (1° → 0.8°)
                                // [0.1, 0.05] → 3 ticks (89.15, 89.10, 89.05)
                                // Labels: ".8°>" in RED (complement of 89.2)
                                ScaleSubsection(startValue: 89.2, tickIntervals: [0.2, 0.1, 0.05], labelLevels: [0],
                                                dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                // 89° → 88°: MIRROR of Θ₁ #5 (2° → 1°)
                // [1.0, 0.5, 0.1, 0.05] → 19 ticks
                ScaleSubsection(startValue: 89.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 88° → 87°: MIRROR of Θ₁ #4 (3° → 2°)
                ScaleSubsection(startValue: 88.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 87° → 86°: MIRROR of Θ₁ #3 (4° → 3°)
                ScaleSubsection(startValue: 87.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 86° → 85°: MIRROR of Θ₁ #2 (5° → 4°)
                ScaleSubsection(startValue: 86.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual),
                
                // 85° → 84.3°: MIRROR of Θ₁ #1 (5.7° → 5°)
                // EXACTLY 6 intermediate ticks at 0.1° intervals: 84.9, 84.8, 84.7, 84.6, 84.5, 84.4
                // The "84.3°" label at the right edge is rendered via ScaleConstant below
                // Use 1.0 as major interval to label 85.0 and avoid mislabeling 84.7 (which is a multiple of 0.7)
                ScaleSubsection(startValue: 85.0, tickIntervals: [1.0, 0.1], labelLevels: [0],
                               dualLabelFormatter: StandardLabelFormatter.thetaScaleDual)
            ])
            // ═══════════════════════════════════════════════════════════════════════════
            // FORCED "84.3°" LABEL at right edge of scale
            // This is necessary because:
            // - Domain extends to 84.29° for proper logarithmic positioning
            // - But 84.29° has NO tick mark (matches physical Pickett N-16 ES)
            // - 84.3° is the LAST VISIBLE labeled tick mark on the right
            // - Using ScaleConstant ensures the label appears without a subsection boundary issue
            // ═══════════════════════════════════════════════════════════════════════════
            .withConstants([
                ScaleConstant(value: 84.3, label: "84.3", style: .medium)
            ])
            .withBaseline(true)  // Shared baseline with ALPHA scale below
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
    /// Used for: 5°, 4°, 3°, 2°, 1° (whole degree marks that show complements)
    public static func thetaScaleDual(value: ScaleValue) -> [LabelConfig] {
        let primary = value
        let complementary = 90.0 - value
        
        var configs: [LabelConfig] = []
        
        // BLACK label (primary)
        // PHYSICAL RULE: Angles > 89° on Theta Large don't show black primary labels
        // because they would be redundant and crowd the starting edge.
        if primary <= 89.001 {
            let primaryText = formatThetaLabel(primary)
            configs.append(LabelConfig(
                text: primaryText,
                position: .left,
                fontStyle: .regular,
                color: .black,
                fontSizeMultiplier: 1.0,
                offset: Offset(horizontal: -1, vertical: 0),
                source: .subsection
            ))
        }
        
        // RED label (complement)
        // Always show for whole degrees, and for sub-degree complements (e.g., .6°>, .8°>)
        let complementaryText = formatThetaComplement(complementary) + ">"
        configs.append(LabelConfig(
            text: complementaryText,
            position: .right,
            fontStyle: .regular,
            color: .red,
            fontSizeMultiplier: 1.0,
            offset: Offset(horizontal: 1, vertical: 0),
            source: .subsection
        ))
        
        return configs
    }
    
    /// THETA scale labeling WITHOUT complement (black label only)
    ///
    /// Used for: 5.7°, .8°, .6° (marks that don't show red complement on physical scale)
    ///
    public static func thetaScaleNoComplement(value: ScaleValue) -> [LabelConfig] {
        let primaryText = formatThetaLabel(value)
        
        return [
            // Single label: primary angle in BLACK (no complement)
            LabelConfig(
                text: primaryText,
                position: .left,
                fontStyle: .regular,
                color: .black,
                fontSizeMultiplier: 1.0,
                offset: Offset(horizontal: -1, vertical: 0),
                source: .subsection
            )
        ]
    }
    
    /// THETA scale dual labeling for whole degrees, but NO complement for sub-degree values
    ///
    /// Used for subsections that span both whole degrees (1°) and sub-degree values (0.8°)
    /// - Whole degrees (≥1°): Dual label with complement (e.g., "1° 89°>")
    /// - Sub-degree (<1°): Single black label only (e.g., ".8")
    ///
    public static func thetaScaleDualExceptSubDegree(value: ScaleValue) -> [LabelConfig] {
        if value < 1.0 {
            // Sub-degree: no complement, just black label
            return thetaScaleNoComplement(value: value)
        } else {
            // Whole degree: dual label with complement
            return thetaScaleDual(value: value)
        }
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
                offset: Offset(horizontal: -1, vertical: 0),
                source: .subsection
            ),
            // Right label: complementary angle in RED with ">"
            LabelConfig(
                text: complementaryText,
                position: .right,
                fontStyle: .regular,
                color: .red,
                fontSizeMultiplier: 1.0,
                offset: Offset(horizontal: 1, vertical: 0),
                source: .subsection
            )
        ]
    }
    
    // MARK: - Private Formatters for Theta/Alpha
    
    /// Format THETA scale labels (handles sub-degree values)
    ///
    /// Physical scale pattern from Pickett N-16 ES:
    /// - "5.7°" at 5.7°
    /// - "5° 85°>" through "1° 89°>" for whole degrees (with complement)
    /// - ".8" and ".6" for sub-degree values (NO degree symbol, NO complement)
    private static func formatThetaLabel(_ angle: Double) -> String {
        if angle < 1.0 {
            // Sub-degree: ".6" for 0.6°, ".8" for 0.8° (NO degree symbol on physical scale)
            let tenths = Int((angle * 10).rounded())
            return ".\(tenths)"
        } else if abs(angle - angle.rounded()) < 0.01 {
            // Whole degrees: "1°", "89°", etc.
            return String(format: "%.0f°", angle.rounded())
        } else {
            // Decimal angles: "5.7°", "84.3°", etc.
            return String(format: "%.1f°", angle)
        }
    }
    
    /// Format THETA complement labels (for red labels on right side)
    private static func formatThetaComplement(_ angle: Double) -> String {
        if angle < 1.0 {
            // Sub-degree complement: ".6°", ".8°"
            let tenths = Int((angle * 10).rounded())
            return ".\(tenths)°"
        } else {
            // Whole degree complement: "1°", "85°", etc.
            return String(format: "%.0f°", angle.rounded())
        }
    }
    
    /// Format ALPHA scale labels (standard integer degrees)
    private static func formatAlphaLabel(_ angle: Double) -> String {
        return String(format: "%.0f", angle.rounded())
    }
}

// MARK: - Transform Functions

/// Transform function for THETA SMALL angles scale (Θ₁)
///
/// Maps small angles 5.71° → 0.57° to position 0 → 1
///
/// **Formula:** position = -1 - log₁₀(tan(θ))
///
/// **Verification:**
/// - At θ = 5.71°: tan = 0.1, log₁₀ = -1, position = -1 - (-1) = 0 ✓
/// - At θ = 0.57°: tan = 0.01, log₁₀ = -2, position = -1 - (-2) = 1 ✓
///
public struct ThetaSmallScaleFunction: ScaleFunction, Sendable {
    public let name = "theta-small-scale"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        let theta = value
        let radians = theta * .pi / 180.0
        
        guard radians > 0 && radians < .pi / 2 else {
            if radians <= 0 { return 1.0 }
            return 0.0
        }
        
        let tanTheta = tan(radians)
        let logTan = log10(tanTheta)
        
        return -1.0 - logTan
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // Solve: position = -1 - log₁₀(tan(θ))
        // log₁₀(tan(θ)) = -1 - position
        let logTan = -1.0 - transformedValue
        let tanTheta = pow(10, logTan)
        return atan(tanTheta) * 180.0 / .pi
    }
}

/// Transform function for THETA LARGE angles scale (Θ₂)
///
/// Maps large angles 89.43° → 84.29° to position 0 → 1
///
/// **Formula:** position = 2 - log₁₀(tan(θ))
///
/// **Verification:**
/// - At θ = 89.43°: tan = 100, log₁₀ = 2, position = 2 - 2 = 0 ✓
/// - At θ = 84.29°: tan = 10, log₁₀ = 1, position = 2 - 1 = 1 ✓
///
public struct ThetaLargeScaleFunction: ScaleFunction, Sendable {
    public let name = "theta-large-scale"
    
    public init() {}
    
    public func transform(_ value: ScaleValue) -> Double {
        let theta = value
        let radians = theta * .pi / 180.0
        
        guard radians > 0 && radians < .pi / 2 else {
            if radians <= 0 { return 1.0 }
            return 0.0
        }
        
        let tanTheta = tan(radians)
        let logTan = log10(tanTheta)
        
        return 2.0 - logTan
    }
    
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // Solve: position = 2 - log₁₀(tan(θ))
        // log₁₀(tan(θ)) = 2 - position
        let logTan = 2.0 - transformedValue
        let tanTheta = pow(10, logTan)
        return atan(tanTheta) * 180.0 / .pi
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
// THETA SMALL SCALE (Θ₁) - Independent Left Half, TICK MARKS UP
// Formula: position = -1 - log₁₀(tan(θ))
// Range: 5.71° → 0.57° maps to position 0 → 1
//
// | BLACK (L) | tan(θ)  | log₁₀   | Position | RED (R)  |
// |-----------|---------|---------|----------|----------|
// | 5.71°     | 0.100   | -1.000  | 0.000    | 84.29°>  |
// | 5°        | 0.0875  | -1.058  | 0.058    | 85°>     |
// | 4°        | 0.0699  | -1.156  | 0.156    | 86°>     |
// | 3°        | 0.0524  | -1.281  | 0.281    | 87°>     |
// | 2°        | 0.0349  | -1.457  | 0.457    | 88°>     |
// | 1°        | 0.0175  | -1.757  | 0.757    | 89°>     |
// | .8°       | 0.0140  | -1.855  | 0.855    | 89.2°>   |
// | .6°       | 0.0105  | -1.980  | 0.980    | 89.4°>   |
// | .57°      | 0.010   | -2.000  | 1.000    | 89.43°>  |
//
// THETA LARGE SCALE (Θ₂) - Independent Right Half, TICK MARKS UP
// Formula: position = 2 - log₁₀(tan(θ))
// Range: 0.01° → 5.71° maps to position 0 → 1 (MIRRORS Θ₁)
//
// **MIRROR PATTERN:** Θ₂ intervals EXACTLY REVERSE Θ₁
// Θ₁: [0.1], [1.0, 0.5, 0.1, 0.05], ..., [0.1, 0.05], [0.1, 0.05], [0.6]
// Θ₂: [0.59], [0.1, 0.05], [0.1, 0.05], [1.0, 0.5, 0.1, 0.05], ..., [0.1]
//
// | BLACK (L) | tan(θ)  | log₁₀   | Position | RED (R)  |
// |-----------|---------|---------|----------|----------|
// | 0.59°     | 0.0103  | -1.987  | ~3.987   | 89.41°>  |
// | 0.6°      | 0.0105  | -1.980  | ~3.980   | 89.4°>   |
// | 0.8°      | 0.0140  | -1.855  | ~3.855   | 89.2°>   |
// | 1°        | 0.0175  | -1.757  | ~3.757   | 89°>     |
// | 2°        | 0.0349  | -1.457  | ~3.457   | 88°>     |
// | 3°        | 0.0524  | -1.281  | ~3.281   | 87°>     |
// | 4°        | 0.0699  | -1.156  | ~3.156   | 86°>     |
// | 5°        | 0.0875  | -1.058  | ~3.058   | 85°>     |
// | 5.71°     | 0.100   | -1.000  | 3.000    | 84.29°>  |
//
// ALPHA SCALE (α) - Standard Descending, TICK MARKS DOWN
// Formula: position = 0.5 - 0.5 × log₁₀(tan(α))
// Range: 84.29° → 5.71° maps to position 0 → 1
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
// NOTE: Θ₁ and Θ₂ are two INDEPENDENT scales that together represent the
// physical THETA scale. Each spans the full 0-1 position range independently.
// They share the same baseline and tick direction (UP), and both use dual
// BLACK/RED complementary angle labeling.
//
// **MIRROR SYMMETRY:** Θ₂ subsections EXACTLY MIRROR Θ₁ subsections in REVERSE:
//   Θ₁: [0.1], [1.0, 0.5, 0.1, 0.05](×4), [0.1, 0.05](×2), [0.6]
//   Θ₂: [0.59], [0.1, 0.05](×2), [1.0, 0.5, 0.1, 0.05](×4), [0.1]
// This creates a symmetric fold at the center point (0.57°/0.59°).
//
// ═══════════════════════════════════════════════════════════════════════════════

// MARK: - Scale Rendering Notes
//
// To render the complete THETA/ALPHA scales on the N-16 ES back face:
//
// 1. Render ALPHA first (lower scale):
//    - Tick marks point DOWN
//    - Dual labels: BLACK left, RED right
//    - Baseline at Y = baseline_y
//    - Single continuous scale: 84.29° → 5.71°
//
// 2. Render Θ₁ (THETA SMALL) second (upper left):
//    - Tick marks point UP
//    - Dual labels: BLACK left, RED right
//    - Baseline SHARED with ALPHA at Y = baseline_y
//    - Independent scale: 5.71° → 0.57° (mirrored left half)
//    - Tick intervals: [0.1], [1.0, 0.5, 0.1, 0.05](×4), [0.1, 0.05](×2), [0.6]
//
// 3. Render Θ₂ (THETA LARGE) third (upper right):
//    - Tick marks point UP
//    - Dual labels: BLACK left, RED right
//    - Baseline SHARED with ALPHA at Y = baseline_y
//    - Independent scale: 0.01° → 5.71° (mirrored right half)
//    - Tick intervals: [0.59], [0.1, 0.05](×2), [1.0, 0.5, 0.1, 0.05](×4), [0.1]
//    - **MIRRORS Θ₁ exactly but in REVERSE order**
//
// 4. Labels will never overlap because:
//    - THETA labels are ABOVE the shared baseline
//    - ALPHA labels are BELOW the shared baseline
//    - Each scale's dual labels (BLACK/RED) are on opposite sides of their ticks
//
// The visual result matches the physical N-16 ES where these scales appear as
// a "sandwich" with tick marks pointing away from each other. The THETA scale
// visually appears as one continuous scale but is implemented as two independent
// scales (Θ₁ and Θ₂) with symmetric tick patterns that create a fold at center.
