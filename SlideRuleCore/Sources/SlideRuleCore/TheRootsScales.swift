import Foundation

// MARK: - Root Scales
//
// These scales implement square root and cube root functions:
//   - R1/Sq1: First square root scale (1 to √10 ≈ 3.16)
//   - R2/Sq2: Second square root scale (√10 to 10)
//   - Q1: First cube root scale (1 to ∛10 ≈ 2.15)
//   - Q2: Second cube root scale (∛10 to ∛100 ≈ 4.64)
//   - Q3: Third cube root scale (∛100 to 10)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Square Root Scales:
//   - R1 (Sq1):   Line 1016 - {log 2 mul} (range 1 to 3.2)
//   - R2 (Sq2):   Line 1021 - {log 2 mul} with offset {1 sub}
//
// Cube Root Scales:
//   - Q1:         Line 1027 - {log 3 mul} (range 1 to 2.16)
//   - Q2:         Line 1032 - {log 3 mul} with offset {1 sub}
//   - Q3:         Line 1040 - {log 3 mul} with offset {2 sub}

public enum TheRootsScales {
    
    // MARK: - Square Root Scales (R1, R2)
    
    /// R1 scale (Sq1): First square root scale from 1 to √10 ≈ 3.16
    /// Uses 2× log multiplier: log₁₀(x) × 2
    /// Covers range for √1 to √10, continues on R2
    public static func r1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sq1")
            .withFunction(CustomFunction(
                name: "square-root",
                transform: { log10($0) * 2.0 },
                inverseTransform: { pow(10, $0 / 2.0) }
            ))
            .withRange(begin: 1.0, end: 3.2)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 1.0-2.0: Dense subdivisions
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                ),
                // 2.0-3.2: Medium subdivisions
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                )
            ])
            .build()
    }
    
    /// R2 scale (Sq2): Second square root scale from √10 ≈ 3.16 to 10
    /// Uses 2× log multiplier with offset: (log₁₀(x) - 1) × 2
    /// Covers range for √10 to √100
    public static func r2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sq2")
            .withFunction(CustomFunction(
                name: "square-root-offset",
                transform: { (log10($0) - 1.0) * 2.0 },
                inverseTransform: { pow(10, $0 / 2.0 + 1.0) }
            ))
            .withRange(begin: 3.1, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 3.1-5.0: Dense subdivisions
                ScaleSubsection(
                    startValue: 3.1,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // 5.0-10.0: Medium subdivisions
                ScaleSubsection(
                    startValue: 5.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    // MARK: - Cube Root Scales (Q1, Q2, Q3)
    
    /// Q1 scale: First cube root scale from 1 to ∛10 ≈ 2.15
    /// Uses 3× log multiplier: log₁₀(x) × 3
    /// Covers range for ∛1 to ∛10
    public static func q1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Q1")
            .withFunction(CustomFunction(
                name: "cube-root",
                transform: { log10($0) * 3.0 },
                inverseTransform: { pow(10, $0 / 3.0) }
            ))
            .withRange(begin: 1.0, end: 2.16)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 1.0-2.0: Dense subdivisions
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                ),
                // 2.0-2.16: Very fine subdivisions
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [0.1, 0.05, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    /// Q2 scale: Second cube root scale from ∛10 ≈ 2.15 to ∛100 ≈ 4.64
    /// Uses 3× log multiplier with offset: (log₁₀(x) - 1) × 3
    /// Covers range for ∛10 to ∛100
    public static func q2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Q2")
            .withFunction(CustomFunction(
                name: "cube-root-offset1",
                transform: { (log10($0) - 1.0) * 3.0 },
                inverseTransform: { pow(10, $0 / 3.0 + 1.0) }
            ))
            .withRange(begin: 2.15, end: 4.7)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 2.15-2.0: Very fine subdivisions (overlap transition)
                ScaleSubsection(
                    startValue: 2.15,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: { value in
                        let rounded = value.rounded()
                        if abs(value - rounded) < 0.01 {
                            return String(Int(rounded))
                        }
                        return String(format: "%.1f", value)
                    }
                ),
                // 3.0-4.7: Medium subdivisions
                ScaleSubsection(
                    startValue: 3.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    
    /// Q3 scale: Third cube root scale from ∛100 ≈ 4.64 to 10
    /// Uses 3× log multiplier with offset: (log₁₀(x) - 2) × 3
    /// Covers range for ∛100 to ∛1000
    public static func q3Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Q3")
            .withFunction(CustomFunction(
                name: "cube-root-offset2",
                transform: { (log10($0) - 2.0) * 3.0 },
                inverseTransform: { pow(10, $0 / 3.0 + 2.0) }
            ))
            .withRange(begin: 4.6, end: 10.0)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 4.6-10.0: Medium subdivisions
                ScaleSubsection(
                    startValue: 4.6,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
}