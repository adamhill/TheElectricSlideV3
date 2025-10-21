import Foundation

// MARK: - PostScript Formula Concordance for Power Scales
//
// UNDERSTANDING POSTSCRIPT POWER FORMULAS:
// Power scales use logarithmic compression to fit multiple decades onto a single scale length.
// The key formulas divide the logarithm by 2 (squares) or 3 (cubes) to compress the range.
//
// Square Scale Examples:
//   {log 2 div}                     - Square scale: log₁₀(x) / 2 (fits x² from 1-100 on C/D length)
//   {100 exch div log 2 div}        - Inverse square: log₁₀(100/x) / 2 (descending scale for 1/x²)
//
// Cube Scale Example:
//   {log 3 div}                     - Cube scale: log₁₀(x) / 3 (fits x³ from 1-1000 on C/D length)
//
// How Division Compression Works:
//   A scale: log₁₀(x) / 2 maps [1,100] onto [0,1] normalized space
//     - x=1:   log₁₀(1)/2 = 0/2 = 0      (left edge)
//     - x=10:  log₁₀(10)/2 = 1/2 = 0.5   (midpoint, first decade)
//     - x=100: log₁₀(100)/2 = 2/2 = 1    (right edge, second decade)
//
//   K scale: log₁₀(x) / 3 maps [1,1000] onto [0,1] normalized space
//     - x=1:    log₁₀(1)/3 = 0/3 = 0     (left edge)
//     - x=10:   log₁₀(10)/3 = 1/3 ≈ 0.33 (first third)
//     - x=100:  log₁₀(100)/3 = 2/3 ≈ 0.67 (second third)
//     - x=1000: log₁₀(1000)/3 = 3/3 = 1  (right edge)
//
// Inverse Scale Pattern:
//   {100 exch div} creates reciprocal: 100/x
//   Then {log 2 div} applies square scale compression
//   Result: AI scale reads from 100 down to 1 (descending)
//
// POSTSCRIPT REFERENCES (postscript-engine-for-sliderules.ps):
// Power Scales:
//   - A scale:    Line 672  - {log 2 div}
//   - B scale:    Line 692  - {log 2 div} with tickdir=-1
//   - AI scale:   Line 698  - {100 exch div log 2 div}
//   - BI scale:   Line 704  - {100 exch div log 2 div} with tickdir=-1
//   - K scale:    Line 710  - {log 3 div}

// MARK: - Power Scales
//
// These scales implement power functions for squares and cubes:
//   - A/B scales: Square scales (read x² on D)
//   - AI/BI scales: Inverse square scales (100/x with square root)
//   - K scale: Cube scale (read x³ on D)

public enum ThePowerScales {
    
    // MARK: - Square Scales
    
    /// A scale: Square scale reading x² on D scale
    ///
    /// **Description:** Square scale reading x² on D scale
    /// **Formula:** log₁₀(x) / 2 (double-decade: 1 to 100)
    /// **Range:** 1 to 100 (two complete cycles of C/D scale)
    /// **Used for:** squaring-numbers, area-calculations, power-relationships
    ///
    /// **Physical Applications:**
    /// - Structural engineering: Stress calculations (force/area²)
    /// - Fluid dynamics: Velocity-based calculations (kinetic energy ∝ v²)
    /// - Electrical: Power calculations P = I²R, reactance X ∝ f
    /// - Geometric: Circle areas A = πr², square areas
    /// - Physics: Inverse square law preparations (1/r²)
    ///
    /// **Example 1:** Square a number: Find 7²
    /// 1. Locate 7 on D scale
    /// 2. Read directly above on A scale
    /// 3. Result: 49 on A scale
    /// 4. Demonstrates direct squaring without C/D manipulation
    ///
    /// **Example 2:** Calculate circle area: A = πr² for r = 5
    /// 1. Set cursor on D:5
    /// 2. Read A:25 (5²)
    /// 3. Move cursor to C:π (3.14)
    /// 4. With C:π over D:1, read D:78.5 (25π)
    /// 5. Combines A scale with π multiplication
    ///
    /// **Example 3:** Power calculation: P = I²R where I = 12A, R = 8Ω
    /// 1. Locate D:12, read A:144 (12²)
    /// 2. Set C:1 over D:144
    /// 3. Move cursor to C:8
    /// 4. Read D:1152 watts
    /// 5. Multi-scale electrical calculation
    ///
    /// **POSTSCRIPT REFERENCES:** Line 672 in postscript-engine-for-sliderules.ps
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
    
    /// B scale: Duplicate of A scale with ticks pointing down (stator-mounted)
    ///
    /// **Description:** Duplicate of A scale with ticks pointing down (stator-mounted)
    /// **Formula:** log₁₀(x) / 2
    /// **Range:** 1 to 100
    /// **Used for:** squaring-numbers, stationary-reference-for-A-scale
    ///
    /// **Physical Applications:** (same as A scale)
    ///
    /// **Example:** Calculate cylinder cross-section: A = (π/4)d² for d = 6
    /// 1. Locate D:6, read B:36 (6²)
    /// 2. Use CF/DF with π factor
    /// 3. Set CF index (π) over DF:36
    /// 4. Divide by 4: read result on DF
    /// 5. Shows B as stationary reference with folded scales
    ///
    /// **POSTSCRIPT REFERENCES:** Line 692 in postscript-engine-for-sliderules.ps
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
    
    /// AI scale: Inverse square scale for reciprocal calculations
    ///
    /// **Description:** Inverse square scale for reciprocal calculations
    /// **Formula:** log₁₀(100/x) / 2
    /// **Range:** 100 to 1 (descending, marked in red)
    /// **Used for:** inverse-square-law, reciprocal-squared-calculations, parallel-circuits
    ///
    /// **Physical Applications:**
    /// - Physics: Inverse square law - light intensity I ∝ 1/r²
    /// - Acoustics: Sound intensity falloff with distance
    /// - Gravity: Gravitational force F ∝ 1/r²
    /// - Radiation: Radiation exposure at varying distances
    /// - Electrical: Parallel capacitance calculations
    ///
    /// **Example 1:** Inverse square law: Light intensity at distance
    /// 1. Source intensity at 1m = 100 units
    /// 2. Find intensity at 5m using 1/r²
    /// 3. Locate 5 on AI scale
    /// 4. Read 4 on A/B scale (100/25)
    /// 5. Result: 4 units at 5m distance
    ///
    /// **Example 2:** Parallel capacitors: C_total = C1×C2/(C1+C2) approximation
    /// 1. For C1=C2, use C_total ≈ C1/2
    /// 2. Locate value on AI, read reciprocal squared relationship
    /// 3. Demonstrates electrical engineering application
    ///
    /// **POSTSCRIPT REFERENCES:** Line 698 in postscript-engine-for-sliderules.ps
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
    
    /// BI scale: Inverse of B scale with ticks pointing down
    ///
    /// **Description:** Inverse of B scale with ticks pointing down
    /// **Formula:** log₁₀(100/x) / 2
    /// **Range:** 100 to 1 (descending, red labels)
    /// **Used for:** inverse-square-calculations, stationary-reference
    ///
    /// **Physical Applications:** (same as AI scale)
    ///
    /// **Example:** Radiation safety: Calculate safe distance
    /// 1. Intensity at 2m = known safe level
    /// 2. Find distance for 1/4 intensity using BI scale
    /// 3. Demonstrates health physics application
    ///
    /// **POSTSCRIPT REFERENCES:** Line 704 in postscript-engine-for-sliderules.ps
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
    
    /// K scale: Cube scale reading x³ on D scale
    ///
    /// **Description:** Cube scale reading x³ on D scale
    /// **Formula:** log₁₀(x) / 3 (triple-decade: 1 to 1000)
    /// **Range:** 1 to 1000 (three complete cycles)
    /// **Used for:** cubing-numbers, volume-calculations, cubic-relationships
    ///
    /// **Physical Applications:**
    /// - Volume calculations: Spheres V = (4/3)πr³, cubes V = s³
    /// - Fluid dynamics: Pipe volumes, flow rates
    /// - Engineering: Cube root extractions for reverse calculations
    /// - Apollo Program: Fuel volume calculations using Pickett N600-ES
    /// - Mechanical: Torque and power relationships
    ///
    /// **Example 1:** Cube a number: Find 5³
    /// 1. Locate 5 on D scale (first third: 1-10)
    /// 2. Read directly above on K scale
    /// 3. Result: 125 on K scale
    /// 4. Note: Must select correct third based on digit count
    ///
    /// **Example 2:** Sphere volume: V = (4/3)πr³ for r = 3
    /// 1. Locate D:3, read K:27 (3³)
    /// 2. Set C:1 over D:27
    /// 3. Move cursor to C:4.19 (4π/3 ≈ 4.19)
    /// 4. Read D:113 cubic units
    /// 5. Combines K scale with π multiplication
    ///
    /// **Example 3:** Cube root: Find ∛4500
    /// 1. Identify 4500 has 4 digits → use first third of K scale
    /// 2. Locate 4500 on K scale (first third)
    /// 3. Read D:16.5 below cursor
    /// 4. Result: ∛4500 ≈ 16.5
    /// 5. Critical: Digit counting determines which third to use
    ///
    /// **Example 4:** Pipe volume calculation
    /// 1. Diameter d = 4, length l = 20
    /// 2. Use K for d³: D:4 → K:64
    /// 3. Multiply by π/4 using C/D scales
    /// 4. Multiply by length using C/D
    /// 5. Multi-step volume calculation for engineering
    ///
    /// **POSTSCRIPT REFERENCES:** Line 710 in postscript-engine-for-sliderules.ps
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