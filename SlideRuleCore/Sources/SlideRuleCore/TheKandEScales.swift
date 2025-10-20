import Foundation

// MARK: - Keuffel & Esser Trigonometric Scales
//
// These scales are Keuffel & Esser variants of the standard trigonometric scales:
//   - KE-S scale: Sine scale from 5.5° to 90° (earlier starting point than standard S)
//   - KE-T scale: Tangent scale from 5.5° to 45° (earlier starting point than standard T)
//   - KE-ST scale (SRT): Small angle tangent from 0.55° to 6° (extended range)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
//   - KE-S:       Line 661  - S scale starting at 5.5°
//   - KE-T:       Line 657  - T scale starting at 5.5°
//   - KE-ST/SRT:  Line 665  - ST scale range 0.55° to 6°

public enum TheKandEScales {
    
    // MARK: - KE Trigonometric Scales
    
    /// KE-S scale: Sine scale from 5.5° to 90° (Keuffel & Esser variant)
    /// Modified from standard S scale with earlier starting point
    public static func keSScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("KE-S")
            .withFunction(SineFunction(multiplier: 10.0))
            .withRange(begin: 5.5, end: 90)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 5.5,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.angle
                ),
                ScaleSubsection(
                    startValue: 50.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                )
            ])
            .build()
    }
    
    /// KE-T scale: Tangent scale from 5.5° to 45° (Keuffel & Esser variant)
    /// Modified from standard T scale with earlier starting point
    public static func keTScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("KE-T")
            .withFunction(TangentFunction(multiplier: 10.0))
            .withRange(begin: 5.5, end: 45)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 5.5,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.angle
                )
            ])
            .build()
    }
    
    /// KE-ST scale (SRT): Small angle tangent from 0.55° to 6° (Keuffel & Esser variant)
    /// Extended range compared to standard ST scale (0.57° to 5.7°)
    /// Titled "SRT" on actual K&E slide rules
    public static func keSTScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("SRT")
            .withFunction(CustomFunction(
                name: "small-tan",
                transform: { log10($0 * .pi / 180.0 * 100.0) },
                inverseTransform: { pow(10, $0) * 180.0 / .pi / 100.0 }
            ))
            .withRange(begin: 0.55, end: 6.0)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.55,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
}