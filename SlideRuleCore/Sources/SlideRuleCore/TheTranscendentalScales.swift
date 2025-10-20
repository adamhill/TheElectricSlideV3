import Foundation

// MARK: - Transcendental Scales
//
// These scales implement trigonometric functions:
//   - S scale: Sine scale from 5.7° to 90°
//   - T scale: Tangent scale from 5.7° to 45°
//   - ST scale: Small angle tangent (for small angles where tan x ≈ x)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Trigonometric Scales:
//   - S scale:    Line 586  - {sin 10 mul log}
//   - T scale:    Line 623  - {tan 10 mul log}
//   - ST scale:   Line 638  - {radians 100 mul log}

public enum TheTranscendentalScales {
    
    // MARK: - Trigonometric Scales
    
    /// S scale: Sine scale from 5.7° to 90°
    public static func sScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("S")
            .withFunction(SineFunction(multiplier: 10.0))
            .withRange(begin: 5.7, end: 90)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 6.0,
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
    
    /// T scale: Tangent scale from 5.7° to 45°
    public static func tScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("T")
            .withFunction(TangentFunction(multiplier: 10.0))
            .withRange(begin: 5.7, end: 45)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 6.0,
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
    
    /// ST scale: Small angle tangent (for small angles where tan x ≈ x)
    public static func stScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("ST")
            .withFunction(CustomFunction(
                name: "small-tan",
                transform: { log10($0 * .pi / 180.0 * 100.0) },
                inverseTransform: { pow(10, $0) * 180.0 / .pi / 100.0 }
            ))
            .withRange(begin: 0.57, end: 5.7)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.6,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
}