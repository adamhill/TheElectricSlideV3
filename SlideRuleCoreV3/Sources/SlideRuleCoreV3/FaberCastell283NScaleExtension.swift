import Foundation

// MARK: - Faber-Castell 62/83 N Custom Scales

/// Custom scales for the Faber-Castell 62/83 N slide rule
/// These scales are based on standard scales but with manufacturer-specific customizations
public extension StandardScales {
    
    // MARK: - Log-Log Scales (LL0x - Reciprocal/Negative Powers)
    
    /// FC283N LL00 scale - Faber-Castell 62/83 N variant
    /// Canonical name for definition string: "FC283NLL00"
    /// Range: 0.9991 → 0.990 (reversed from standard)
    /// Labels at 0.0005 increments, 24 tick marks between labels
    static func FC283N_LL00(length: Distance = 250.0) -> ScaleDefinition {
        let baseScale = ll00Scale(length: length)
        
        // 24 ticks between labels at 0.0005 intervals
        // 0.0005 / 24 ≈ 0.0000208, use [0.0005, 0.00025, 0.0001, 0.00002]
        let subsections = [
            ScaleSubsection(
                startValue: 0.9991,
                tickIntervals: [0.0005, 0.00025, 0.0001, 0.00002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.fourDecimals
            )
        ]
        
        return ScaleBuilder(from: baseScale)
            .withName("LL00")
            .withDisplayName("LL00")  // Explicit: show "LL00" not "FC283NLL00"
            .withRange(begin: 0.9991, end: 0.990)  // Reversed: large on left, small on right
            .withSubsections(subsections)
            .build()
    }
    
    /// FC283N LL01 scale - Faber-Castell 62/83 N variant
    /// Canonical name for definition string: "FC283NLL01"
    /// Range: 0.99 → 0.90 (reversed from standard)
    /// Labels at 0.01 increments, 24 tick marks between labels
    static func FC283N_LL01(length: Distance = 250.0) -> ScaleDefinition {
        let baseScale = ll01Scale(length: length)
        
        // 24 ticks between labels at 0.01 intervals
        // 0.01 / 24 ≈ 0.000417, use [0.01, 0.005, 0.001, 0.0004]
        let subsections = [
            ScaleSubsection(
                startValue: 0.99,
                tickIntervals: [0.01, 0.005, 0.001, 0.0004],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            )
        ]
        
        return ScaleBuilder(from: baseScale)
            .withName("LL01")
            .withDisplayName("LL01")  // Explicit: show "LL01" not "FC283NLL01"
            .withRange(begin: 0.99, end: 0.90)  // Reversed: large on left, small on right
            .withSubsections(subsections)
            .build()
    }
    
    /// FC283N LL02 scale - Faber-Castell 62/83 N variant
    /// Canonical name for definition string: "FC283NLL02"
    /// Range: 0.9141... → 0.35 (reversed from standard)
    /// 
    /// Tick mark counts from actual Faber-Castell 62/83N measurement:
    /// - 0.91 → 0.90: 19 ticks (0.01 range / 20 = 0.0005 finest interval)
    /// - 0.90 → 0.85: 49 ticks (0.05 range / 50 = 0.001 finest interval)
    /// - 0.85 → 0.80: 49 ticks (0.05 range / 50 = 0.001 finest interval)
    /// - Continues with similar pattern to 0.35
    /// 
    /// **Ghost Start Implementation:**
    /// The 0.91 label starts at the FIFTH tick mark on the LL03 scale above it,
    /// creating a ~2% visual gap at the left edge. This is achieved by setting
    /// the scale's beginValue to a virtual value (0.9141...) that is larger than
    /// the first visible tick (0.91). The first subsection starts at 0.91,
    /// so no ticks appear in the gap region between begin and 0.91.
    /// 
    /// Virtual begin calculated: f⁻¹((f(0.91) - 0.011 × f(0.35)) / (1 - 0.011)) = 0.912272537119513
    /// where f(x) = log₁₀(-ln(x) × 10) is the LL02 transform.
    /// 
    /// Includes gauge mark at 1/e ≈ 0.368
    static func FC283N_LL02(length: Distance = 250.0) -> ScaleDefinition {
        let baseScale = ll02Scale(length: length)
        
        // Virtual begin value for ~1.1% ghost start gap
        // Calculated so 0.91 appears at normalized position 0.011
        let virtualBegin = 0.912272537119513
        
        // Subsections based on actual Faber-Castell 62/83N tick patterns
        let subsections = [
            // 0.91 → 0.90: 19 ticks between labels
            // 0.01 range / 20 positions = 0.0005 finest interval
            // Tick hierarchy: 0.01 (label), 0.005 (medium), 0.001 (minor), 0.0005 (finest)
            // NOTE: First subsection starts at 0.91, NOT virtualBegin, creating the ghost start gap
            ScaleSubsection(
                startValue: 0.91,
                tickIntervals: [0.01, 0.005, 0.001, 0.0005],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.90 → 0.85: 49 ticks between labels
            // 0.05 range / 50 positions = 0.001 finest interval
            // Tick hierarchy: 0.05 (label), 0.01 (medium), 0.005 (minor), 0.001 (finest)
            ScaleSubsection(
                startValue: 0.90,
                tickIntervals: [0.05, 0.01, 0.005, 0.001],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.85 → 0.80: 49 ticks between labels (same pattern)
            ScaleSubsection(
                startValue: 0.85,
                tickIntervals: [0.05, 0.01, 0.005, 0.001],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.80 → 0.75: 24 ticks between labels
            // 0.05 range / 25 positions = 0.002 finest interval
            // Tick hierarchy: 0.05 (label), 0.01 (medium), 0.002 (finest)
            ScaleSubsection(
                startValue: 0.80,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.75 → 0.70: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.75,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.70 → 0.65: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.70,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.65 → 0.60: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.65,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.60 → 0.55: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.60,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.55 → 0.50: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.55,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.50 → 0.45: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.50,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.45 → 0.40: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.45,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.40 → 0.35: 24 ticks between labels
            ScaleSubsection(
                startValue: 0.40,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            ),
            // 0.35 → end: 15 more ticks at 0.002 interval (no label at end)
            // Ghost end: ticks stop at 0.32 (0.35 - 15×0.002), scale positioning extends to ~0.29
            ScaleSubsection(
                startValue: 0.35,
                tickIntervals: [0.05, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            )
        ]
        
        // Virtual end value for ~3% ghost end gap
        // Calculated so the last tick (0.32) appears at normalized position 0.97
        // Using inverse LL02 transform: f⁻¹((f(0.32) - 0.03 × f(virtualBegin)) / (1 - 0.03))
        let virtualEnd = 0.29178597781571775
        
        // Visible end value: where ticks actually stop (0.35 - 15×0.002 = 0.32)
        let visibleEnd = 0.32
        
        return ScaleBuilder(from: baseScale)
            .withName("LL02")
            .withDisplayName("LL02")  // Explicit: show "LL02" not "FC283NLL02"
            .withRange(begin: virtualBegin, end: virtualEnd)  // Ghost start (1.1%) + ghost end (3%)
            .withVisibleEndValue(visibleEnd)  // Ticks stop at 0.32
            .withSubsections(subsections)
            .addConstant(value: 1.0 / Double.e, label: "1/e", style: .medium)  // Gauge mark at 1/e ≈ 0.368
            .build()
    }
    
    /// FC283N LL03 scale - Based on standard LL03 with Faber-Castell 62/83 N customizations
    /// Canonical name for definition string: "FC283NLL03"
    /// Range: 0.4 to 0.00001 (e⁻ˣ for small values)
    static func FC283N_LL03(length: Distance = 250.0) -> ScaleDefinition {
        let baseScale = ll03Scale(length: length)
        
        return ScaleBuilder(from: baseScale)
            .withName("LL03")
            .withDisplayName("LL03")  // Explicit: show "LL03" not "FC283NLL03"
            .build()
    }
}