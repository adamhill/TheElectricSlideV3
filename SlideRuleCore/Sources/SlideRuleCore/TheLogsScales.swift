import Foundation

// MARK: - Logarithmic Scales
//
// These scales implement logarithmic and log-log functions:
//   - LL1, LL2, LL3: Log-log scales for exponential calculations (e^x)
//   - L scale: Linear logarithm scale (mantissa from 0 to 1)
//   - Ln scale: Natural logarithm scale
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Logarithmic Scales:
//   - LL0-LL3:    Lines 1348-1446 - Various {ln X mul log} formulas
//   - L scale:    Line 1136 - {} (linear/identity)
//   - Ln scale:   Line 1173 - {10 ln div}

public enum TheLogsScales {
    
    // MARK: - Log-Log Scales
    
    /// LL1 scale: e^(0.01 to 0.1)
    public static func ll1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("LL1")
            .withFunction(CustomFunction(
                name: "log-ln",
                transform: { log10(log($0)) * 10.0 },
                inverseTransform: { exp(pow(10, $0 / 10.0)) }
            ))
            .withRange(begin: 1.01, end: 1.105)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.01,
                    tickIntervals: [0.01, 0.005, 0.001, 0.0005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.threeDecimals
                )
            ])
            .build()
    }
    
    /// LL2 scale: e^(0.1 to 1.0)
    public static func ll2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("LL2")
            .withFunction(CustomFunction(
                name: "log-ln",
                transform: { log10(log($0)) * 10.0 },
                inverseTransform: { exp(pow(10, $0 / 10.0)) }
            ))
            .withRange(begin: 1.105, end: 2.72)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.1,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .addConstant(value: .e, label: "e", style: .major)
            .build()
    }
    
    /// LL3 scale: e^(1.0 to 10.0) - approximately 2.72 to 22026
    public static func ll3Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("LL3")
            .withFunction(CustomFunction(
                name: "log-ln",
                transform: { log10(log($0)) },
                inverseTransform: { exp(pow(10, $0)) }
            ))
            .withRange(begin: 2.74, end: 21000)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 2.6,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.2],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 500.0, 100.0, 50.0],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .build()
    }
    
    // MARK: - Linear Logarithm Scales
    
    /// L scale: Linear logarithm scale from 0 to 1 (mantissa)
    public static func lScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("L")
            .withFunction(LinearFunction())
            .withRange(begin: 0, end: 1)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [0.1, 0.05, 0.01, 0.002],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
    
    /// Ln scale: Natural logarithm scale
    public static func lnScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Ln")
            .withFunction(CustomFunction(
                name: "ln-normalized",
                transform: { log($0) / (10 * log(10)) },
                inverseTransform: { exp($0 * 10 * log(10)) }
            ))
            .withRange(begin: 0, end: 10 * log(10))
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 0.0,
                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .build()
    }
}