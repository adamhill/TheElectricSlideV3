import Foundation

// MARK: - Special Scales
//
// **EXTENDED RANGE SCALE CONTEXT:**
//
// Extended C/D scales (10-100, 100-1000) solve two critical problems:
// 1. **Decimal Point Management**: Maintain proper decimal context without mental decade shifting
// 2. **Overflow Prevention**: Extended ranges "simplify manipulation when a result overflows" standard C/D scales
//
// **WHY MULTIPLE DECADES ARE NEEDED:**
// - Single-decade C/D (1-10): Maximum precision but requires careful decimal tracking
// - Extended scales: Trade some precision for automatic decimal placement
// - Fuller's designs: 500-inch cylindrical rules achieved 4-5 significant figures
// - Modern approach: Extended scales complement rather than replace standard C/D
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
    
    /// C10-100 scale: C scale extended to 10-100 range with ×10 labeling
    ///
    /// **Description:** C scale extended to 10-100 range with ×10 labeling
    /// **Formula:** log₁₀(x) where labels show 10×value
    /// **Range:** 10 to 100 (internally 1-10, labels ×10)
    /// **Used for:** extended-range-multiplication, decimal-management, overflow-prevention
    ///
    /// **Physical Applications:**
    /// - Engineering calculations: Operations in tens range without decade shifting
    /// - Scientific work: Maintaining significant figures across orders of magnitude
    /// - Educational: Teaching decimal point management
    /// - Complex calculations: Multi-step operations prone to overflow
    /// - Quality control: Measurements in specific decimal ranges
    ///
    /// **Example 1:** Direct multiplication: 25 × 3 = 75
    /// 1. Locate 25 on C10-100 scale
    /// 2. Set C10-100:1 index (showing as "10") over D:25
    /// 3. Move cursor to C10-100:3 (showing as "30")
    /// 4. Read D:75 directly
    /// 5. No decade mental adjustment needed
    ///
    /// **Example 2:** Prevent overflow: 8 × 15 using extended scale
    /// 1. Standard C×D: 8×15=120 would exceed scale
    /// 2. Use C10-100 to handle larger intermediate values
    /// 3. Align scales appropriately for extended range
    /// 4. Read result without going off-scale
    /// 5. Demonstrates overflow management
    ///
    /// **Example 3:** Multi-step with decimal context: (45 × 2.3) / 5.5
    /// 1. Calculate 45 × 2.3 using C10-100/D scales
    /// 2. Result ≈ 103.5 stays in extended range
    /// 3. Divide by 5.5 using standard C/D
    /// 4. Final answer ≈ 18.8
    /// 5. Extended scale preserves decimal context throughout
    ///
    /// **POSTSCRIPT REFERENCES:** Line 530 in postscript-engine-for-sliderules.ps
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
    
    /// C100-1000 scale: C scale extended to 100-1000 range with ×100 labeling
    ///
    /// **Description:** C scale extended to 100-1000 range with ×100 labeling
    /// **Formula:** log₁₀(x) where labels show 100×value
    /// **Range:** 100 to 1000 (internally 1-10, labels ×100)
    /// **Used for:** hundreds-range-calculations, high-value-operations, scientific-notation
    ///
    /// **Physical Applications:**
    /// - Large-scale engineering: Calculations in hundreds without notation
    /// - Manufacturing: Production quantities and rates
    /// - Financial: Business calculations in hundreds/thousands
    /// - Scientific research: Data in appropriate decimal context
    /// - Quality assurance: Statistical process control in production ranges
    ///
    /// **Example 1:** Calculate 250 × 3.5 in hundreds range
    /// 1. Locate 250 on C100-1000 scale
    /// 2. Multiply using standard technique
    /// 3. Result 875 stays in extended range
    /// 4. No scientific notation conversion needed
    ///
    /// **Example 2:** Manufacturing: Production rate calculation
    /// 1. Rate = 450 units/hour
    /// 2. Time = 2.2 hours
    /// 3. Total = 450 × 2.2 using C100-1000/D
    /// 4. Result: 990 units
    /// 5. Practical industrial application
    ///
    /// **POSTSCRIPT REFERENCES:** Line 538 in postscript-engine-for-sliderules.ps
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
    
    /// D10-100 scale: D scale extended to 10-100 range, companion to C10-100
    ///
    /// **Description:** D scale extended to 10-100 range, companion to C10-100
    /// **Formula:** log₁₀(x) where labels show 10×value
    /// **Range:** 10 to 100 (internally 1-10, labels ×10)
    /// **Used for:** extended-range-results, stationary-reference-tens
    ///
    /// **Physical Applications:**
    /// - Engineering calculations: Operations in tens range without decade shifting
    /// - Scientific work: Maintaining significant figures across orders of magnitude
    /// - Educational: Teaching decimal point management
    /// - Complex calculations: Multi-step operations prone to overflow
    /// - Quality control: Measurements in specific decimal ranges
    ///
    /// **Example:** Engineering calculation with extended D reference
    /// 1. Use C10-100 for slide operations
    /// 2. Read results on D10-100 stator
    /// 3. Both scales show tens range directly
    /// 4. Maintains decimal context for results
    /// 5. Companion scale operation
    ///
    /// **POSTSCRIPT REFERENCES:** Line 579 in postscript-engine-for-sliderules.ps
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