import Foundation

// MARK: - Basic and Folded Scales
//
// These scales implement the core PostScript formulas from postscript-engine-for-sliderules.ps.
// Standard scales form the foundation of all slide rule calculations:
//   - C/D scales: Base 10 logarithmic scales for multiplication/division
//   - CI/DI scales: Reciprocal scales (inverted C/D)
//   - CF/DF scales: Folded at π to prevent running off scale edge
//   - CIF/DIF scales: Folded reciprocal scales for division operations
//
// SCALE ALIGNMENT:
// Basic operations using C and D scales:
//   - Multiply: Set 1 on C to first number on D, read second number on C against result on D
//   - Divide: Set divisor on C to dividend on D, read result on D under 1 on C
//   - Reciprocal: Use CI/DI scales (inverted C/D)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Basic Scales:
//   - C scale:    Line 395  - {log}
//   - D scale:    Line 470  - {log} with tickdir=-1
//   - CI scale:   Line 503  - {1 exch div 10 mul log}
//   - DI scale:   Line 509  - {1 exch div 10 mul log} with tickdir=-1
//
// Folded Scales:
//   - CF scale:   Line 484  - {log PI log sub}
//   - DF scale:   Line 498  - {log PI log sub} with tickdir=1
//   - CIF scale:  Line 514  - {1 exch div 100 mul PI div log}
//   - DIF scale:  Line 523  - {1 exch div 100 mul PI div log} with tickdir=1

public enum TheBasicAndFoldedScales {
    
    // MARK: - Basic Logarithmic Scales
    
    /// C scale: Standard logarithmic scale from 1 to 10
    public static func cScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("C")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1, end: 10)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 1.0 to 2.0: dense subdivisions
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
                    labelLevels: [0, 1]
                ),
                // 2.0 to 4.0: medium subdivisions
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1]
                ),
                // 4.0 to 10.0: coarser subdivisions
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .addConstant(value: .pi, label: "π", style: .medium)
            .build()
    }
    
    /// D scale: Identical to C but with opposite tick direction
    public static func dScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("D")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1, end: 10)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
                    labelLevels: [0, 1]
                ),
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1]
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .addConstant(value: .pi, label: "π", style: .medium)
            .build()
    }
    
    /// CI scale: Inverted C scale (reciprocal) from 10 to 1
    public static func ciScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("CI")
            .withFunction(CustomFunction(
                name: "reciprocal-log",
                transform: { -log10($0) },
                inverseTransform: { pow(10, -$0) }
            ))
            .withRange(begin: 10, end: 1) // Reversed
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .build()
    }
    
    /// DI scale: Duplicate of CI scale with ticks pointing down
    /// Same as CI scale but with tickdir = -1
    /// Range: 10 to 1 (reciprocal, descending)
    /// Formula: -log₁₀(x)
    public static func diScale(length: Distance = 250.0) -> ScaleDefinition {
        // Start with CI scale and change tick direction
        let ciScale = self.ciScale(length: length)
        
        return ScaleDefinition(
            name: "DI",
            function: ciScale.function,
            beginValue: ciScale.beginValue,
            endValue: ciScale.endValue,
            scaleLengthInPoints: length,
            layout: ciScale.layout,
            tickDirection: .down,  // Only difference from CI scale
            subsections: ciScale.subsections,
            defaultTickStyles: ciScale.defaultTickStyles,
            labelFormatter: ciScale.labelFormatter,
            labelColor: ciScale.labelColor,
            constants: ciScale.constants
        )
    }
    
    // MARK: - Folded Scales
    
    /// CF scale: C scale folded at π (π to 10π)
    /// Prevents "running off the scale" by providing alternate starting point
    public static func cfScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("CF")
            .withFunction(LogarithmicFunction())
            .withRange(begin: .pi, end: 10 * .pi)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // π to 5: dense subdivisions
                ScaleSubsection(
                    startValue: .pi,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                // 5 to 10: medium subdivisions
                ScaleSubsection(
                    startValue: 5.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                // 10 to 31.4: coarser subdivisions
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .addConstant(value: .pi, label: "π", style: .major)
            .addConstant(value: 10.0, label: "10", style: .major)
            .build()
    }
    
    /// DF scale: D scale folded at π (π to 10π)
    /// Companion to CF with opposite tick direction
    public static func dfScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("DF")
            .withFunction(LogarithmicFunction())
            .withRange(begin: .pi, end: 10 * .pi)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: .pi,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
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
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .addConstant(value: .pi, label: "π", style: .major)
            .addConstant(value: 10.0, label: "10", style: .major)
            .build()
    }
    
    /// CIF scale: Inverted C scale folded at π (10π to π)
    /// Folded reciprocal scale for division operations
    public static func cifScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("CIF")
            .withFunction(CustomFunction(
                name: "reciprocal-log",
                transform: { -log10($0) },
                inverseTransform: { pow(10, -$0) }
            ))
            .withRange(begin: 10 * .pi, end: .pi) // Reversed for reciprocal
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Mirror of CF but reversed
                ScaleSubsection(
                    startValue: .pi,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
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
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .addConstant(value: .pi, label: "π", style: .major)
            .addConstant(value: 10.0, label: "10", style: .major)
            .build()
    }
    
    /// DIF scale: Duplicate of CIF scale with ticks pointing up
    /// Same as CIF scale but with tickdir =1
    /// Range: 10π to π (folded reciprocal, descending)
    /// Formula: -log₁₀(x)
    public static func difScale(length: Distance = 250.0) -> ScaleDefinition {
        // Start with CIF scale and change tick direction
        let cifScale = self.cifScale(length: length)
        
        return ScaleDefinition(
            name: "DIF",
            function: cifScale.function,
            beginValue: cifScale.beginValue,
            endValue: cifScale.endValue,
            scaleLengthInPoints: length,
            layout: cifScale.layout,
            tickDirection: .up,  // Ticks pointing up (tickdir=1)
            subsections: cifScale.subsections,
            defaultTickStyles: cifScale.defaultTickStyles,
            labelFormatter: cifScale.labelFormatter,
            labelColor: cifScale.labelColor,
            constants: cifScale.constants
        )
    }
}