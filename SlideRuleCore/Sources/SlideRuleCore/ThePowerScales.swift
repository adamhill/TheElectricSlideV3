import Foundation

// MARK: - Power Scales
//
// These scales implement power functions for squares and cubes:
//   - A/B scales: Square scales (read x² on D)
//   - AI/BI scales: Inverse square scales (100/x with square root)
//   - K scale: Cube scale (read x³ on D)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Power Scales:
//   - A scale:    Line 672  - {log 2 div}
//   - B scale:    Line 692  - {log 2 div} with tickdir=-1
//   - AI scale:   Line 698  - {100 exch div log 2 div}
//   - BI scale:   Line 704  - {100 exch div log 2 div} with tickdir=-1
//   - K scale:    Line 710  - {log 3 div}

public enum ThePowerScales {
    
    // MARK: - Square Scales
    
    /// A scale: Square scale (reads x² on D) from 1 to 100
    public static func aScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("A")
            .withFunction(CustomFunction(
                name: "half-log",
                transform: { 0.5 * log10($0) },
                inverseTransform: { pow(10, 2 * $0) }
            ))
            .withRange(begin: 1, end: 100)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .build()
    }
    
    /// B scale - Duplicate of A scale with ticks pointing down
    /// Same as A scale but with tickdir = -1
    /// Range: 1 to 100 (squares)
    /// Formula: log₁₀(x) / 2
    public static func bScale(length: Distance = 250.0) -> ScaleDefinition {
        // Start with A scale and modify
        let aScale = self.aScale(length: length)
        
        return ScaleDefinition(
            name: "B",
            function: aScale.function,
            beginValue: aScale.beginValue,
            endValue: aScale.endValue,
            scaleLengthInPoints: length,
            layout: aScale.layout,
            tickDirection: .down,  // Only difference from A scale
            subsections: aScale.subsections,
            defaultTickStyles: aScale.defaultTickStyles,
            labelFormatter: aScale.labelFormatter,
            labelColor: aScale.labelColor,
            constants: aScale.constants
        )
    }
    
    /// AI scale - Inverse of A scale (100/x with square root)
    /// Range: 100 to 1 (descending)
    /// Formula: log₁₀(100/x) / 2 = (log₁₀(100) - log₁₀(x)) / 2
    /// Labels in red
    public static func aiScale(length: Distance = 250.0) -> ScaleDefinition {
        // Start with A scale structure
        let aScale = self.aScale(length: length)
        
        // Inverse formula: log(100/x) / 2
        let aiFunction = CustomFunction(
            name: "AI-scale",
            transform: { value in
                log10(100.0 / value) / 2.0
            },
            inverseTransform: { transformed in
                100.0 / pow(10, transformed * 2.0)
            }
        )
        
        return ScaleDefinition(
            name: "AI",
            function: aiFunction,
            beginValue: 100.0,  // Start at 100
            endValue: 1.0,      // End at 1 (descending)
            scaleLengthInPoints: length,
            layout: aScale.layout,
            tickDirection: .up,  // Same as A scale
            subsections: aScale.subsections,
            defaultTickStyles: aScale.defaultTickStyles,
            labelFormatter: aScale.labelFormatter,
            labelColor: (red: 1.0, green: 0.0, blue: 0.0),  // Red labels
            constants: []  // No constants for inverse scales typically
        )
    }
    
    /// BI scale - Inverse of B scale (100/x with square root, ticks down)
    /// Range: 100 to 1 (descending)
    /// Formula: log₁₀(100/x) / 2
    /// Labels in red, ticks pointing down
    public static func biScale(length: Distance = 250.0) -> ScaleDefinition {
        // Start with AI scale and change tick direction
        let aiScale = self.aiScale(length: length)
        
        return ScaleDefinition(
            name: "BI",
            function: aiScale.function,
            beginValue: aiScale.beginValue,
            endValue: aiScale.endValue,
            scaleLengthInPoints: length,
            layout: aiScale.layout,
            tickDirection: .down,  // Ticks point down like B scale
            subsections: aiScale.subsections,
            defaultTickStyles: aiScale.defaultTickStyles,
            labelFormatter: aiScale.labelFormatter,
            labelColor: (red: 1.0, green: 0.0, blue: 0.0),  // Red labels
            constants: aiScale.constants
        )
    }
    
    // MARK: - Cube Scale
    
    /// K scale: Cube scale (reads x³ on D) from 1 to 1000
    public static func kScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("K")
            .withFunction(CustomFunction(
                name: "third-log",
                transform: { log10($0) / 3.0 },
                inverseTransform: { pow(10, 3 * $0) }
            ))
            .withRange(begin: 1, end: 1000)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
                    labelLevels: [0]
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .build()
    }
}