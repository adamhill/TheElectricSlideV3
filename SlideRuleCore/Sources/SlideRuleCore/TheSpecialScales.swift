import Foundation

// MARK: - Special Scales
//
// These scales provide extended range variations of the C and D scales:
//   - C10-100 scale: C scale representing 10 to 100 (labels × 10)
//   - C100-1000 scale: C scale representing 100 to 1000 (labels × 100)
//   - D10-100 scale: D scale representing 10 to 100 (companion to C10-100)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Special Scales:
//   - C10-100:    Line 530  - C scale with ×10 labels
//   - C100-1000:  Line 538  - C scale with ×100 labels  
//   - D10-100:    Line 579  - D scale with ×10 labels

public enum TheSpecialScales {
    
    // MARK: - Extended Range C Scales
    
    /// C scale representing 10 to 100
    /// Uses standard logarithmic function but displays values × 10
    /// Internally operates on 1-10, labels show 10-100
    public static func c10to100Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("C10-100")
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
    
    // MARK: - Extended Range D Scale
    
    /// D scale representing 10 to 100 (companion to C10-100)
    /// Same as C10-100 but with downward-pointing ticks
    public static func d10to100Scale(length: Distance = 250.0) -> ScaleDefinition {
        ScaleBuilder()
            .withName("D10-100")
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
}