import Foundation

// MARK: - Standard Scales Reading Guide
//
// POSTSCRIPT SCALE IMPLEMENTATION NOTES:
// These scales implement the core PostScript formulas from postscript-engine-for-sliderules.ps.
// Standard scales form the foundation of all slide rule calculations:
//   - C/D scales: Base 10 logarithmic scales for multiplication/division
//   - A/B scales: Square scales (read x² on D)
//   - K scale: Cube scale (read x³ on D)
//   - CI/DI scales: Reciprocal scales (inverted C/D)
//   - CF/DF scales: Folded at π to prevent running off scale edge
//   - LL scales: Log-log scales for exponential calculations (e^x)
//   - Trig scales: S, T, ST for sine, tangent, small angles
//
// SCALE ALIGNMENT:
// Basic operations using C and D scales:
//   - Multiply: Set 1 on C to first number on D, read second number on C against result on D
//   - Divide: Set divisor on C to dividend on D, read result on D under 1 on C
//   - Square: Read from A scale, value appears on D scale
//   - Cube: Read from K scale, value appears on D scale
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
//
// Power Scales:
//   - A scale:    Line 672  - {log 2 div}
//   - B scale:    Line 692  - {log 2 div} with tickdir=-1
//   - AI scale:   Line 698  - {100 exch div log 2 div}
//   - BI scale:   Line 704  - {100 exch div log 2 div} with tickdir=-1
//   - K scale:    Line 710  - {log 3 div}
//
// Square Root Scales:
//   - R1 (Sq1):   Line 1016 - {log 2 mul} (range 1 to 3.2)
//   - R2 (Sq2):   Line 1021 - {log 2 mul} with offset {1 sub}
//
// Cube Root Scales:
//   - Q1:         Line 1027 - {log 3 mul} (range 1 to 2.16)
//   - Q2:         Line 1032 - {log 3 mul} with offset {1 sub}
//   - Q3:         Line 1040 - {log 3 mul} with offset {2 sub}
//
// Logarithmic Scales:
//   - LL0-LL3:    Lines 1348-1446 - Various {ln X mul log} formulas
//   - L scale:    Line 1136 - {} (linear/identity)
//   - Ln scale:   Line 1173 - {10 ln div}
//
// Trigonometric Scales:
//   - S scale:    Line 586  - {sin 10 mul log}
//   - T scale:    Line 623  - {tan 10 mul log}
//   - ST scale:   Line 638  - {radians 100 mul log}
//   - KE-S:       Line 661  - S scale starting at 5.5°
//   - KE-T:       Line 657  - T scale starting at 5.5°
//   - KE-ST/SRT:  Line 665  - ST scale range 0.55° to 6°
//
// Special Scales:
//   - C10-100:    Line 530  - C scale with ×10 labels
//   - C100-1000:  Line 538  - C scale with ×100 labels  
//   - D10-100:    Line 579  - D scale with ×10 labels

// MARK: - Standard Scale Definitions

/// Factory for creating standard slide rule scales based on the PostScript definitions
public enum StandardScales {
    
    // MARK: - Basic Logarithmic Scales
    
    /// C scale: Standard logarithmic scale from 1 to 10
    public static func cScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("C")
            .withFormula("x")
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
            .withFormula("x")
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
            .withFormula("1/x")
            .withFunction(ReciprocalLogFunction())
            .withRange(begin: 10, end: 1) // Reversed
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 10.0 to 4.0: mirrors C scale's 1.0 to 2.0 subsection
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0]
                ),
                // 4.0 to 2.0: mirrors C scale's 2.0 to 4.0 subsection
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1]
                ),
                // 2.0 to 1.0: mirrors C scale's 4.0 to 10.0 but denser
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
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
            formula: "1/x",
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
            .withFormula("πx")
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
            .withFormula("πx")
            .withFunction(LogarithmicFunction())
            .withRange(begin: .pi, end: 10 * .pi)
            .withLength(length)
            .withTickDirection(.up)
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
            .withFormula("1/πx")
            .withFunction(ReciprocalLogFunction())
            .withRange(begin: 10 * .pi, end: .pi) // Reversed for reciprocal
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // Start from 10π and work backwards to π
                ScaleSubsection(
                    startValue: 10 * .pi,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 5.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]
                ),
                ScaleSubsection(
                    startValue: .pi,
                    tickIntervals: [0.5, 0.1, 0.05, 0.01],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.oneDecimal
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .addConstant(value: .pi, label: "π", style: .major)
            .addConstant(value: 10.0, label: "10", style: .major)
            .build()
    }
    /// DIF scale: Duplicate of CIF scale with ticks pointing down
    /// Same as CIF scale but with tickdir = -1
    /// Range: 10π to π (folded reciprocal, descending)
    /// Formula: -log₁₀(x)
    public static func difScale(length: Distance = 250.0) -> ScaleDefinition {
        // Start with CIF scale and change tick direction
        let cifScale = self.cifScale(length: length)
        
        return ScaleDefinition(
            name: "DIF",
            formula: "1/πx",
            function: cifScale.function,
            beginValue: cifScale.beginValue,
            endValue: cifScale.endValue,
            scaleLengthInPoints: length,
            layout: cifScale.layout,
            tickDirection: .down,  // Ticks pointing down (tickdir=-1) - opposite of CIF
            subsections: cifScale.subsections,
            defaultTickStyles: cifScale.defaultTickStyles,
            labelFormatter: cifScale.labelFormatter,
            labelColor: cifScale.labelColor,
            constants: cifScale.constants
        )
    }
    // MARK: - Folding scales: CF (C folded scale), DF (D folded scale), CIF (inverted folded scale), DIF (inverted folded reciprocal scale)

    /// A scale: Square scale (reads x² on D) from 1 to 100
    public static func aScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("A")
            .withFormula("x²")
            .withFunction(HalfLogFunction())
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
    
    /// K scale: Cube scale (reads x³ on D) from 1 to 1000
    /// PostScript Reference: lines 710-727 (/Kscale definition)
    /// 
    /// IMPLEMENTATION NOTES:
    /// - PostScript has 10 subsections for fine-grained density control
    /// - Current implementation uses 4 active subsections for practical mobile usability
    /// - Commented subsections can be enabled for high-resolution displays
    /// - Label density optimized for 5-inch phone (360pt) and 10-inch tablet (720pt)
    public static func kScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("K")
            .withFormula("x³")
            .withFunction(ThirdLogFunction())
            .withRange(begin: 1, end: 1000)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // PostScript subsection 1: 1-3 (line 718)
                // Dense subdivisions for precision in the 1-10 range
                // Intervals: [1, .5, .1, .05] - primary, secondary, tertiary, quaternary
                // LABEL STRATEGY: Show integers 1, 2, 3
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0]  // Primary ticks at 1, 2, 3 get labels
                ),
                
                // PostScript subsection 2: 3-6 (line 719)
                // Medium density, null tertiary interval
                // Intervals: [1, null, .5, .1]
                // LABEL STRATEGY: Continue showing integers (3, 4, 5, 6)
                // NOTE: 3 appears in both subsections, but duplicate removal handles this
                ScaleSubsection(
                    startValue: 3.0,
                    tickIntervals: [1.0, 0.5, 0.1],  // Skip null interval
                    labelLevels: [0]  // Primary ticks at 3, 4, 5, 6 get labels
                ),
                
                // PostScript subsection 3: 6-10 (line 720)
                // Coarser intervals as we approach the decade boundary
                // Intervals: [1, null, null, .2]
                // PURPOSE: Prevents subsection 2 from labeling 7, 8, 9, 10
                ScaleSubsection(
                    startValue: 6.0,
                    tickIntervals: [1.0, 0.2],  // Only primary and quaternary
                    labelLevels: [0]  // Labels at 6, 7, 8, 9, 10
                ),
                
                // PostScript subsection 4: 10-30 (line 721)
                // Decade scaling begins - intervals × 10
                // Intervals: [10, 5, 1, .5]
                // LABEL STRATEGY: Show compact labels (10→"1", 20→"2", 30→"3")
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],  // Only primary (10-interval) ticks
                    labelFormatter: StandardLabelFormatter.kScale
                ),
                
                // PostScript subsection 5: 30-60 (line 722)
                // Mid-range decades with null secondary interval
                // Intervals: [10, null, 5, 1]
                // LABEL STRATEGY: Show compact labels (30→"3", 40→"4", 50→"5", 60→"6")
                ScaleSubsection(
                    startValue: 30.0,
                    tickIntervals: [10.0, 5.0, 1.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.kScale
                ),
                
                // PostScript subsection 6: 60-100 (line 723)
                // Approaching the hundreds boundary
                // Intervals: [10, null, null, 2]
                // LABEL STRATEGY: Show compact labels (60→"6", 70→"7", 80→"8", 90→"9", 100→"10")
                ScaleSubsection(
                    startValue: 60.0,
                    tickIntervals: [10.0, 2.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.kScale
                ),
                
                // PostScript subsection 7: 100-300 (line 724)
                // Hundreds range with × 100 intervals
                // Intervals: [100, 50, 10, 5]
                // LABEL STRATEGY: Show compact labels (100→"1", 200→"2", 300→"3")
                ScaleSubsection(
                    startValue: 100.0,
                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.kScale
                ),
                
                // PostScript subsection 8: 300-600 (line 725)
                // Mid-hundreds range
                // Intervals: [100, null, 50, 10]
                // LABEL STRATEGY: Show compact labels (300→"3", 400→"4", 500→"5", 600→"6")
                ScaleSubsection(
                    startValue: 300.0,
                    tickIntervals: [100.0, 50.0, 10.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.kScale
                ),
                
                // PostScript subsection 9: 600-1000 (line 726)
                // Upper hundreds approaching maximum
                // Intervals: [100, null, null, 20]
                // LABEL STRATEGY: Show compact labels (600→"6", 700→"7", 800→"8", 900→"9", 1000→"10")
                ScaleSubsection(
                    startValue: 600.0,
                    tickIntervals: [100.0, 20.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.kScale
                ),
                
                // PostScript subsection 10: 1000 (line 727)
                // Final endpoint marker
                // Intervals: [1000, 500, 100, 50]
                // LABEL STRATEGY: Would show "1" but absorbed into subsection 9's "10" at 1000
                // This subsection primarily provides tick marks, label handled by previous subsection
                ScaleSubsection(
                    startValue: 1000.0,
                    tickIntervals: [1000.0, 500.0, 100.0, 50.0],
                    labelLevels: []  // No labels - endpoint already labeled by subsection 9
                )
            ])
            .withLabelFormatter(StandardLabelFormatter.integer)
            .build()
    }
    
    // MARK: - Log-Log Scales
    
    /// LL1 scale: e^(0.01 to 0.1)
//    public static func ll1Scale(length: Distance = 250.0) -> ScaleDefinition {
//        ScaleBuilder()
//            .withName("LL1")
//            .withFormula("e⁰·⁰¹ˣ")
//            .withFunction(LogLnFunction(multiplier: 10.0))
//            .withRange(begin: 1.01, end: 1.105)
//            .withLength(length)
//            .withTickDirection(.up)
//            .withSubsections([
//                ScaleSubsection(
//                    startValue: 1.01,
//                    tickIntervals: [0.01, 0.005, 0.001, 0.0005],
//                    labelLevels: [0],
//                    labelFormatter: StandardLabelFormatter.threeDecimals
//                )
//            ])
//            .build()
//    }
    
    /// LL2 scale: e^(0.1 to 1.0)
//    public static func ll2Scale(length: Distance = 250.0) -> ScaleDefinition {
//        ScaleBuilder()
//            .withName("LL2")
//            .withFormula("e⁰·¹ˣ")
//            .withFunction(LogLnFunction(multiplier: 10.0))
//            .withRange(begin: 1.105, end: 2.72)
//            .withLength(length)
//            .withTickDirection(.up)
//            .withSubsections([
//                ScaleSubsection(
//                    startValue: 1.1,
//                    tickIntervals: [0.1, 0.05, 0.01, 0.005],
//                    labelLevels: [0],
//                    labelFormatter: StandardLabelFormatter.oneDecimal
//                )
//            ])
//            .addConstant(value: .e, label: "e", style: .major)
//            .build()
//    }
    
    /// LL3 scale: e^(1.0 to 10.0) - approximately 2.72 to 22026
//    public static func ll3Scale(length: Distance = 250.0) -> ScaleDefinition {
//        ScaleBuilder()
//            .withName("LL3")
//            .withFormula("eˣ")
//            .withFunction(LogLnFunction(multiplier: 1.0))
//            .withRange(begin: 2.74, end: 21000)
//            .withLength(length)
//            .withTickDirection(.up)
//            .withSubsections([
//                ScaleSubsection(
//                    startValue: 2.6,
//                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
//                    labelLevels: [0]
//                ),
//                ScaleSubsection(
//                    startValue: 4.0,
//                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
//                    labelLevels: [0]
//                ),
//                ScaleSubsection(
//                    startValue: 10.0,
//                    tickIntervals: [5.0, 1.0, 0.5, 0.2],
//                    labelLevels: [0]
//                ),
//                ScaleSubsection(
//                    startValue: 100.0,
//                    tickIntervals: [100.0, 50.0, 10.0, 5.0],
//                    labelLevels: [0]
//                ),
//                ScaleSubsection(
//                    startValue: 1000.0,
//                    tickIntervals: [1000.0, 500.0, 100.0, 50.0],
//                    labelLevels: [0]
//                )
//            ])
//            .withLabelFormatter(StandardLabelFormatter.integer)
//            .build()
//    }
    
    // MARK: - Trigonometric Scales
    
    /// S scale: Sine scale from 5.7° to 90°
    /// S scale: Sine scale from 5.7° to 90°
    /// Implements all 7 PostScript subsections for accurate sine angle readings
    /// PostScript Reference: lines 592-598
    /// 
    /// DESIGN NOTE: S scales traditionally show both sine (ascending left→right)
    /// and cosine (descending, complementary angles). This implementation uses
    /// dual labeling to show sine angles on the right (italic) and complementary
    /// cosine angles on the left (left-italic), matching PostScript /plabelR and /plabelL.
    public static func sScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("S")
            .withFormula("∡sin")
            .withFunction(SineFunction(multiplier: 10.0))
            .withRange(begin: 5.7, end: 90)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // PostScript subsection 1: 5.5-10° (line 592)
                // Very dense for small angles where sine changes rapidly
                // Intervals: [1, .5, .1, .05]
                // LABEL STRATEGY: Show dual labels (sine right, cosine left) for all degree marks
                ScaleSubsection(
                    startValue: 5.5,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0],  // Primary ticks labeled
                    dualLabelFormatter: StandardLabelFormatter.sScaleDual
                ),
                
                // PostScript subsection 2: 10-20° (line 593)
                // Medium density with 5° primary intervals
                // Intervals: [5, 1, .5, .1]
                // LABEL STRATEGY: Show dual labels at 10°, 15°, 20° and intermediate degrees
                ScaleSubsection(
                    startValue: 10.0,
                    tickIntervals: [5.0, 1.0, 0.5, 0.1],
                    labelLevels: [],  // Primary and secondary labeled
                    dualLabelFormatter: StandardLabelFormatter.sScaleDual
                ),
                
                // PostScript subsection 3: 20-30° (line 594)
                // Transition zone, null secondary interval
                // Intervals: [5, null, 1, .5]
                // LABEL STRATEGY: Show dual labels at 20°, 25°, 30° and single degrees
                ScaleSubsection(
                    startValue: 20.0,
                    tickIntervals: [5.0, 1.0, 0.5],  // Skip null interval
                    labelLevels: [0],  // Only primary (5° intervals)
                    dualLabelFormatter: StandardLabelFormatter.sScaleDual
                ),
                
                // PostScript subsection 4: 30-60° (line 595)
                // Mid-range angles with 10° primary intervals
                // Intervals: [10, 5, 1, .5]
                // LABEL STRATEGY: Show dual labels at 30°, 40°, 50°, 60° (every 10°)
                ScaleSubsection(
                    startValue: 30.0,
                    tickIntervals: [10.0, 5.0, 1.0, 0.5],
                    labelLevels: [0],  // Only major 10° marks
                    dualLabelFormatter: StandardLabelFormatter.sScaleDual
                ),
                
                // PostScript subsection 5: 60-80° (line 596)
                // Approaching vertical, coarser intervals
                // Intervals: [10, null, 5, 1]
                // LABEL STRATEGY: Show dual labels at 60°, 70°, 80° (every 10°)
                ScaleSubsection(
                    startValue: 60.0,
                    tickIntervals: [10.0, 5.0, 1.0],  // Skip null interval
                    labelLevels: [0],  // Only 10° marks
                    dualLabelFormatter: StandardLabelFormatter.sScaleDual
                ),
                
                // PostScript subsection 6: 80-90° (line 597)
                // Very coarse near 90° where sine plateaus
                // Intervals: [10, null, null, 5]
                // LABEL STRATEGY: No labels (handled by next subsection)
                ScaleSubsection(
                    startValue: 80.0,
                    tickIntervals: [10.0, 5.0],  // Only primary and quaternary
                    labelLevels: []  // No labels - tick marks only
                ),
                
                // PostScript subsection 7: 90° endpoint (line 598)
                // Final endpoint marker
                // Intervals: [10, null, null, null]
                // LABEL STRATEGY: Show dual labels "90°" (right) and "0°" (left) at endpoint
                ScaleSubsection(
                    startValue: 90.0,
                    tickIntervals: [10.0],  // Single interval
                    labelLevels: [0],  // Label the 90° mark
                    dualLabelFormatter: StandardLabelFormatter.sScaleDual
                )
            ])
            .build()
    }
    
    /// T scale: Tangent scale from 5.7° to 45°
    public static func tScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("T")
            .withFormula("∡tan")
            .withFunction(TangentFunction(multiplier: 10.0))
            .withRange(begin: 5.7, end: 45)
            .withLength(length)
            .withTickDirection(.up)
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
            .withFormula("∡tan ≈ ∡")
            .withFunction(SmallTanFunction())
            .withRange(begin: 0.57, end: 5.7)
            .withLength(length)
            .withTickDirection(.up)
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
    
    // MARK: - Special Scales
    
    /// L scale: Linear logarithm scale from 0 to 1 (mantissa)
    /// PostScript Reference: line 1136 - tickdir=1 (up)
    public static func lScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("L")
            .withFormula("log₁₀ x")
            .withFunction(LinearFunction())
            .withRange(begin: 0, end: 1)
            .withLength(length)
            .withTickDirection(.up)  // Fixed: PostScript has tickdir=1 (up), not -1 (down)
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
            .withFormula("ln x")
            .withFunction(LnNormalizedFunction())
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
    
    // MARK: - Folding scales: CF (C folded scale), DF (D folded scale), CIF (inverted folded scale), DIF (inverted folded reciprocal scale)

    /// B scale - Duplicate of A scale with ticks pointing down
    /// Same as A scale but with tickdir = -1
    /// Range: 1 to 100 (squares)
    /// Formula: log₁₀(x) / 2
    public static func bScale(length: Distance = 250.0) -> ScaleDefinition {
        // Start with A scale and modify
        let aScale = self.aScale(length: length)
        
        return ScaleDefinition(
            name: "B",
            formula: "x²",
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
        let aiFunction = AIScaleFunction()
        
        return ScaleDefinition(
            name: "AI",
            formula: "100/x²",
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
            formula: "100/x²",
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

    // MARK: - KE Trigonometric Scales
    
    /// KE-S scale: Sine scale from 5.5° to 90° (Keuffel & Esser variant)
    /// Modified from standard S scale with earlier starting point
    public static func keSScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("KE-S")
            .withFormula("sin x")
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
            .withFormula("tan x")
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
            .withFormula("tan x ≈ x")
            .withFunction(SmallTanFunction())
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
    
    // MARK: - Extended Range C Scales
    
    /// C scale representing 10 to 100
    /// Uses standard logarithmic function but displays values × 10
    /// Internally operates on 1-10, labels show 10-100
    public static func c10to100Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("C10-100")
            .withFormula("10x")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1, end: 10)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 1.0 to 2.0 (displays as 10-20): dense subdivisions
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.scaled(by: 10, decimals: 0)
                ),
                // 2.0 to 4.0 (displays as 20-40): medium subdivisions
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.scaled(by: 10, decimals: 0)
                ),
                // 4.0 to 10.0 (displays as 40-100): coarser subdivisions
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.scaled(by: 10, decimals: 0)
                )
            ])
            .build()
    }
    
    /// C scale representing 100 to 1000
    /// Uses standard logarithmic function but displays values × 100
    /// Internally operates on 1-10, labels show 100-1000
    public static func c100to1000Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("C100-1000")
            .withFormula("100x")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1, end: 10)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 1.0 to 2.0 (displays as 100-200): dense subdivisions
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.scaled(by: 100, decimals: 0)
                ),
                // 2.0 to 4.0 (displays as 200-400): medium subdivisions
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.scaled(by: 100, decimals: 0)
                ),
                // 4.0 to 10.0 (displays as 400-1000): coarser subdivisions
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.scaled(by: 100, decimals: 0)
                )
            ])
            .build()
    }
    
    // MARK: - Aviation Scales
    
    /// CAS scale: Calibrated Airspeed scale from 80 to 1000
    /// Used in aviation for converting between indicated and calibrated airspeed
    /// Formula: log₁₀((x × 22.74 + 698.7) / 1000)
    /// This is a specialized aviation calculation scale
    public static func casScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("CAS")
            .withFormula("(22.74x+698.7)/1000")
            .withFunction(CalibratedAirspeedFunction())
            .withRange(begin: 80, end: 1000)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 80 to 300: finer divisions for lower speeds
                ScaleSubsection(
                    startValue: 80,
                    tickIntervals: [20.0, 10.0, 2.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                ),
                // 300 to 1000: coarser divisions for higher speeds
                ScaleSubsection(
                    startValue: 300,
                    tickIntervals: [100.0, 50.0, 10.0],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.integer
                )
            ])
            .build()
    }
    // MARK: - Time Conversion Scales
    
    /// TIME scale: Time conversion from 1 minute to 10 hours (60-600 minutes)
    /// Formula: log₁₀(x/60) + log₁₀(6) = log₁₀(6x/60) = log₁₀(x/10)
    /// Labels show hours:minutes format (e.g., "1:30" for 90 minutes)
    public static func timeScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("TIME")
            .withFormula("x min")
            .withFunction(TimeConversionFunction())
            .withRange(begin: 60, end: 600)
            .withLength(length)
            .withTickDirection(.up)
            .withSubsections([
                // 60-240 minutes (1:00 - 4:00 hours)
                ScaleSubsection(
                    startValue: 60,
                    tickIntervals: [30.0, 10.0],
                    labelLevels: [0],
                    labelFormatter: Self.timeFormatter
                ),
                // 240-600 minutes (4:00 - 10:00 hours)
                ScaleSubsection(
                    startValue: 240,
                    tickIntervals: [60.0, 30.0, 10.0],
                    labelLevels: [0],
                    labelFormatter: Self.timeFormatter
                )
            ])
            .build()
    }
    
    /// TIME2 scale: Extended time conversion from 10 to 100 hours (600-6000 minutes)
    /// Same formula as TIME but extended range, with downward ticks
    public static func time2Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("TIME2")
            .withFormula("x hr")
            .withFunction(TimeConversionFunction())
            .withRange(begin: 600, end: 6000)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                // 600-1200 minutes (10-20 hours)
                ScaleSubsection(
                    startValue: 600,
                    tickIntervals: [60.0, 30.0],
                    labelLevels: [0],
                    labelFormatter: Self.timeFormatter
                ),
                // 1200-2940 minutes (20-49 hours)
                ScaleSubsection(
                    startValue: 1200,
                    tickIntervals: [240.0, 60.0],
                    labelLevels: [0],
                    labelFormatter: Self.timeFormatter
                ),
                // 2940-6000 minutes (49-100 hours) - shown in days
                ScaleSubsection(
                    startValue: 2940,
                    tickIntervals: [1440.0, 720.0, 360.0, 60.0],
                    labelLevels: [0],
                    labelFormatter: Self.timeDaysFormatter
                )
            ])
            .build()
    }
    
    // MARK: - Combined Sine/Cosine Scale
    
    /// CR3S scale: Combined Sine/Cosine scale from 6° to 90°
    /// Shows both sine values (ascending) and cosine values (descending)
    /// Cosine of x = sine of (90° - x), so both can share the same physical scale
    public static func cr3sScale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("S/C")
            .withFormula("sin x / cos x")
            .withFunction(SineFunction(multiplier: 10.0))
            .withRange(begin: 6, end: 90)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                // 6-25°: Dense divisions, sine labels
                ScaleSubsection(
                    startValue: 6,
                    tickIntervals: [1.0],
                    labelLevels: [0],
                    labelFormatter: { value in "\(Int(value.rounded()))°" }
                ),
                // 25-45°: Medium divisions, sine labels
                ScaleSubsection(
                    startValue: 25,
                    tickIntervals: [5.0, 1.0],
                    labelLevels: [0],
                    labelFormatter: { value in "\(Int(value.rounded()))°" }
                ),
                // 45-70°: Medium divisions, cosine labels (90-x)
                ScaleSubsection(
                    startValue: 45,
                    tickIntervals: [5.0, 1.0],
                    labelLevels: [0],
                    labelFormatter: { value in "\(Int((90 - value).rounded()))°" }
                ),
                // 70-80°: Coarser divisions, cosine labels
                ScaleSubsection(
                    startValue: 70,
                    tickIntervals: [10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: { value in "\(Int((90 - value).rounded()))°" }
                ),
                // 80-90°: Coarsest divisions, cosine labels
                ScaleSubsection(
                    startValue: 80,
                    tickIntervals: [10.0, 5.0],
                    labelLevels: [0],
                    labelFormatter: { value in "\(Int((90 - value).rounded()))°" }
                )
            ])
            .withConstants([
                // Small angle markers for precision work (in degrees)
                ScaleConstant(value: 1.0, label: "1°", style: .medium),
                ScaleConstant(value: 1.5, label: "1.5°", style: .medium),
                ScaleConstant(value: 2.0, label: "2°", style: .medium),
                ScaleConstant(value: 2.5, label: "2.5°", style: .medium),
                ScaleConstant(value: 3.0, label: "3°", style: .medium),
                ScaleConstant(value: 3.5, label: "3.5°", style: .medium),
                ScaleConstant(value: 4.0, label: "4°", style: .medium),
                ScaleConstant(value: 4.5, label: "4.5°", style: .medium),
                ScaleConstant(value: 5.0, label: "5°", style: .medium)
            ])
            .build()
    }
    
    // MARK: - Extended Range D Scale
    
    /// D scale representing 10 to 100 (companion to C10-100)
    /// Same as C10-100 but with downward-pointing ticks
    public static func d10to100Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("D10-100")
            .withFormula("10x")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1, end: 10)
            .withLength(length)
            .withTickDirection(.down)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1, 0.05, 0.01],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.scaled(by: 10, decimals: 0)
                ),
                ScaleSubsection(
                    startValue: 2.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: [0, 1],
                    labelFormatter: StandardLabelFormatter.scaled(by: 10, decimals: 0)
                ),
                ScaleSubsection(
                    startValue: 4.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.02],
                    labelLevels: [0],
                    labelFormatter: StandardLabelFormatter.scaled(by: 10, decimals: 0)
                )
            ])
            .build()
    }
    
    // MARK: - Square Root Scales (R1, R2)
    
    /// R1 scale (Sq1): First square root scale from 1 to √10 ≈ 3.16
    /// Uses 2× log multiplier: log₁₀(x) × 2
    /// Covers range for √1 to √10, continues on R2
    public static func r1Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("Sq1")
            .withFormula("√x")
            .withFunction(SquareRootFunction())
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
            .withFormula("√(10x)")
            .withFunction(SquareRootOffsetFunction())
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
            .withFormula("∛x")
            .withFunction(CubeRootFunction())
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
            .withFormula("∛(10x)")
            .withFunction(CubeRootOffset1Function())
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
            .withFormula("∛(100x)")
            .withFunction(CubeRootOffset2Function())
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
    
   
    
    
    
    // MARK: - Helper Label Formatters
    
    /// Formats time in minutes as hours:minutes (e.g., 90 → "1:30")
    private static let timeFormatter: @Sendable (ScaleValue) -> String = { minutes in
        let totalMinutes = Int(minutes.rounded())
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if mins == 0 {
            return "\(hours):00"
        }
        return String(format: "%d:%02d", hours, mins)
    }
    
    /// Formats time in minutes as days (e.g., 1440 → "1d", 2880 → "2d")
    private static let timeDaysFormatter: @Sendable (ScaleValue) -> String = { minutes in
        let days = Int((minutes / 1440.0).rounded())
        return "\(days)d"
    }
    // MARK: - Factory Method
    
    /// Create a standard scale by name
    public static func scale(named name: String, length: Distance = 250.0) -> ScaleDefinition? {
        switch name.uppercased() {
        case "C": return cScale(length: length)
        case "D": return dScale(length: length)
        case "CI": return ciScale(length: length)
        case "DI": return diScale(length: length)
        case "CF": return cfScale(length: length)
            
        case "DF": return dfScale(length: length)
        case "CIF": return cifScale(length: length)
        case "DIF": return difScale(length: length)
        case "A": return aScale(length: length)
        case "K": return kScale(length: length)
        
        case "S": return sScale(length: length)
        case "T": return tScale(length: length)
        case "ST": return stScale(length: length)
        case "L": return lScale(length: length)
        case "LN": return lnScale(length: length)
        
        // NEW: Log-Log scales
        case "LL0": return ll0Scale(length: length)
        case "LL1": return ll1Scale(length: length)
        case "LL2": return ll2Scale(length: length)
        case "LL3": return ll3Scale(length: length)
            
        // NEW: inverse Log-Log scales
        case "LL00": return ll00Scale(length: length)
        case "LL01": return ll01Scale(length: length)
        case "LL02": return ll02Scale(length: length)
        case "LL03": return ll03Scale(length: length)
            
        // NEW: B, BI, AI scales
        case "B": return bScale(length: length)
        case "BI": return biScale(length: length)
        case "AI": return aiScale(length: length)
            
        // KE Trigonometric variants
        case "KE-S", "KES": return keSScale(length: length)
        case "KE-T", "KET": return keTScale(length: length)
        case "KE-ST", "KEST", "SRT": return keSTScale(length: length)
        
        // Extended range C scales
        case "C10-100", "C10.100": return c10to100Scale(length: length)
        case "C100-1000", "C100.1000": return c100to1000Scale(length: length)
        
        // Aviation scales
        case "CAS": return casScale(length: length)
            
        // Time conversion scales
        case "TIME": return timeScale(length: length)
        case "TIME2": return time2Scale(length: length)
        
        // Combined sine/cosine
        case "CR3S", "S/C", "SC": return cr3sScale(length: length)
        
        // Extended D scale
        case "D10-100", "D10.100": return d10to100Scale(length: length)
        
        // Square root scales
        case "R1", "SQ1": return r1Scale(length: length)
        case "R2", "SQ2": return r2Scale(length: length)
        
        // Cube root scales
        case "Q1": return q1Scale(length: length)
        case "Q2": return q2Scale(length: length)
        case "Q3": return q3Scale(length: length)
        
        // Hyperbolic scales
        case "SH": return shScale(length: length)
        case "CH": return chScale(length: length)
        case "TH": return thScale(length: length)
        
        // Power scales
        case "PA": return paScale(length: length)
        case "P": return pScale(length: length)
            
        default: return nil
        }
    }
}

// MARK: - Mathematical Constants

extension Double {
    static let e = 2.718281828459045
}
