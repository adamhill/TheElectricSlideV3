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
    /// Range: 0.91 → 0.35 (reversed from standard)
    /// Labels at 0.05 increments, 24 tick marks between labels
    /// Includes gauge mark at 1/e ≈ 0.368
    static func FC283N_LL02(length: Distance = 250.0) -> ScaleDefinition {
        let baseScale = ll02Scale(length: length)
        
        // 24 ticks between labels at 0.05 intervals
        // 0.05 / 24 ≈ 0.00208, use [0.05, 0.025, 0.01, 0.002]
        let subsections = [
            ScaleSubsection(
                startValue: 0.91,
                tickIntervals: [0.05, 0.025, 0.01, 0.002],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.twoDecimals
            )
        ]
        
        return ScaleBuilder(from: baseScale)
            .withName("LL02")
            .withDisplayName("LL02")  // Explicit: show "LL02" not "FC283NLL02"
            .withRange(begin: 0.91, end: 0.35)  // Reversed: large on left, small on right
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