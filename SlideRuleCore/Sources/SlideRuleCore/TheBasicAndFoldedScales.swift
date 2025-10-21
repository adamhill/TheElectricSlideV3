import Foundation

// MARK: - PostScript Formula Concordance
//
// UNDERSTANDING POSTSCRIPT NOTATION:
// PostScript uses Reverse Polish Notation (RPN) where operators follow operands.
// The stack-based execution processes values from left to right.
//
// Basic Examples:
//   {log}                           - Take logarithm of input value: log₁₀(x)
//   {1 exch div}                    - Reciprocal: 1 ÷ x (exch swaps stack order)
//   {1 exch div 10 mul log}         - Reciprocal×10, then log: log₁₀(10/x)
//   {log PI log sub}                - Subtract log(π) from log(x): log₁₀(x/π)
//   {2 exp 1 sub .5 exp}            - Square x, subtract 1, take square root: √(x²-1)
//
// Stack Operations:
//   exch  - Exchange top two stack items (e.g., "x y exch" → "y x")
//   div   - Divide (top by second): "a b div" → a/b
//   mul   - Multiply: "a b mul" → a×b
//   sub   - Subtract: "a b sub" → a-b
//   exp   - Exponentiate: "a b exp" → a^b
//   log   - Base-10 logarithm: "x log" → log₁₀(x)
//
// The formula {1 exch div 10 mul log} executes as:
//   1. Start with input value x on stack: [x]
//   2. Push 1: [x, 1]
//   3. exch swaps: [1, x]
//   4. div divides: [1/x]
//   5. Push 10: [1/x, 10]
//   6. mul multiplies: [10/x]
//   7. log takes logarithm: [log₁₀(10/x)]
//
// This concordance helps interpret the PostScript formulas referenced in each scale.

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
    
    /// C scale: Standard logarithmic scale, foundation of slide rule calculations
    ///
    /// **PostScript Reference:** C scale (line 395)
    /// Formula: log₁₀(x)
    /// Range: 1 to 10 (single decade)
    /// Used for: multiplication, division, logarithmic-calculations
    ///
    /// **Physical Applications:**
    /// - Mechanical engineering: Force, torque, and power calculations
    /// - General calculations: Any multiplication or division operation
    /// - Component sizing: Dimensional analysis and scaling
    /// - Sequential operations: Chained calculations with other scales
    ///
    /// **Example 1:** Multiply 2 × 3
    /// 1. Set left index (1) of C scale over 2 on D scale
    /// 2. Move cursor to 3 on C scale
    /// 3. Read answer 6 below cursor on D scale
    ///
    /// **Example 2:** Divide 8 ÷ 4
    /// 1. Set 4 on C scale over 8 on D scale
    /// 2. Move cursor to left index (1) on C scale
    /// 3. Read answer 2 below cursor on D scale
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
    
    /// D scale: Identical to C scale but with opposite tick direction (stator-mounted)
    ///
    /// **PostScript Reference:** D scale (line 470)
    /// Formula: log₁₀(x)
    /// Range: 1 to 10 (single decade)
    /// Used for: multiplication, division, reading-results
    ///
    /// **Physical Applications:**
    /// - Mechanical engineering: Force, torque, and power calculations
    /// - General calculations: Any multiplication or division operation
    /// - Component sizing: Dimensional analysis and scaling
    /// - Sequential operations: Chained calculations with other scales
    ///
    /// **Example:** Basic multiplication using D as the stationary reference scale
    /// 1. D scale serves as the fixed reference (stator)
    /// 2. C scale moves above it (slider)
    /// 3. Set 1 on C over first number on D
    /// 4. Read result on D below second number on C
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
    
    /// CI scale: Inverted C scale for reciprocals and division
    ///
    /// **PostScript Reference:** CI scale (line 503)
    /// Formula: log₁₀(1/x) = -log₁₀(x), displayed as log₁₀(10/x) for scale positioning
    /// Range: 10 to 1 (reversed, marked in red)
    /// Used for: reciprocals, division-by-multiplication, preventing-off-scale-errors
    ///
    /// **Physical Applications:**
    /// - Electrical engineering: Parallel resistance calculations (1/R_total = 1/R1 + 1/R2)
    /// - Optics: Lens power calculations (reciprocal of focal length)
    /// - Sequential operations: Chained division operations
    /// - Scale management: Alternative when C/D calculations exceed limits
    ///
    /// **Example 1:** Find reciprocal of 4 (calculate 1/4)
    /// 1. Locate 4 on CI scale
    /// 2. Read value 2.5 directly below on C/D scale (since 1/4 = 0.25, scale shows as 2.5)
    /// 3. Adjust decimal: 0.25
    ///
    /// **Example 2:** Divide using multiplication (8 ÷ 2 = 8 × 1/2)
    /// 1. Set left index of C over 8 on D
    /// 2. Move cursor to 2 on CI scale
    /// 3. Read answer 4 on D scale
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
    
    /// DI scale: Inverted D scale, reciprocal companion to CI
    ///
    /// **PostScript Reference:** DI scale (line 509)
    /// Formula: log₁₀(1/x) = -log₁₀(x)
    /// Range: 10 to 1 (reversed)
    /// Used for: reciprocals, complementary-division-operations
    ///
    /// **Physical Applications:**
    /// - Electrical engineering: Parallel resistance calculations (1/R_total = 1/R1 + 1/R2)
    /// - Optics: Lens power calculations (reciprocal of focal length)
    /// - Sequential operations: Chained division operations
    /// - Scale management: Alternative when C/D calculations exceed limits
    ///
    /// **Example 1:** Calculate tan(63°) using T and DI scales together
    /// 1. Locate 63° on T scale (tangent scale)
    /// 2. Read corresponding value on DI scale ≈ 1.96
    /// 3. Result can be flipped to CI scale for continued operations
    /// 4. This demonstrates DI's role in trig-to-reciprocal conversions
    ///
    /// **Example 2:** Chained division: Calculate (100 ÷ 4) ÷ 5
    /// 1. Set 4 on C over 100 on D
    /// 2. Read intermediate result 25 under 1 on C (using D scale)
    /// 3. Without moving slide, locate 5 on CI scale
    /// 4. Read final result 5 on DI scale below
    /// 5. Demonstrates chained operations without slide reset
    ///
    /// **Example 3:** Reciprocal with continuation
    /// 1. Find 1/8 by locating 8 on DI, reading 1.25 on D (decimal adjustment to 0.125)
    /// 2. Use this result immediately with CI scale for further multiplication
    /// 3. Shows DI as intermediate result holder
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
    
    /// CF scale: C scale folded at π instead of 1, extends calculation range
    ///
    /// **PostScript Reference:** CF scale (line 484)
    /// Formula: log₁₀(x) where x ranges from π to 10π
    /// Range: π to 10π (3.14159 to 31.4159), prevents off-scale errors
    /// Used for: extended-range-multiplication, pi-calculations, preventing-scale-overrun
    ///
    /// **Physical Applications:**
    /// - Circle calculations: Circumference = πd, Area = πr²
    /// - Sphere calculations: Volume = (4/3)πr³, Surface = 4πr²
    /// - Cylinder calculations: Volume = πr²h
    /// - Engineering formulas: Any calculation involving π
    /// - Sequential operations: Intermediate results between C and CF scales
    ///
    /// **Example 1:** Calculate circumference from diameter (C = πd, d=5)
    /// 1. Locate 5 on D scale
    /// 2. Set left index (π) of CF over 5 on D
    /// 3. Move to right index (10π) on CF
    /// 4. Read 15.7 on D scale (5π ≈ 15.71)
    ///
    /// **Example 2:** Multiply 7 × 4 using CF to prevent overrun
    /// 1. If 7×4 might exceed 10 on C/D, use CF/DF
    /// 2. Set π on CF over 7 on DF
    /// 3. Read 4 on CF against 28 on DF (accounting for π factor)
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
    
    /// DF scale: D scale folded at π, companion to CF
    ///
    /// **PostScript Reference:** DF scale (line 498)
    /// Formula: log₁₀(x) where x ranges from π to 10π
    /// Range: π to 10π (3.14159 to 31.4159)
    /// Used for: extended-range-operations, pi-calculations
    ///
    /// **Physical Applications:**
    /// - Circle calculations: Circumference = πd, Area = πr²
    /// - Sphere calculations: Volume = (4/3)πr³, Surface = 4πr²
    /// - Cylinder calculations: Volume = πr²h
    /// - Engineering formulas: Any calculation involving π
    /// - Sequential operations: Intermediate results between C and CF scales
    ///
    /// **Example 1:** Multi-step calculation: 2.07 × 8.4 × 16.1 using CF/DF
    /// 1. Set CF index (π) on DF:8.4
    /// 2. Move cursor to CF:16.1
    /// 3. Align CIF:2.07 with cursor
    /// 4. Read result DF:280 without slide repositioning
    /// 5. Demonstrates continuous calculation flow
    ///
    /// **Example 2:** Integration with L (log) scale: Calculate 10^(0.5 × log(15))
    /// 1. Find log(15) on L scale ≈ 1.176
    /// 2. Set C:1 over D:1.176
    /// 3. Move cursor to C:0.5
    /// 4. Read intermediate on DF scale
    /// 5. Use LL scale to find antilog for final answer
    /// 6. Shows DF bridging logarithmic and folded operations
    ///
    /// **Example 3:** Trig calculation with π: Calculate 7 × sin(30°) × π
    /// 1. Find sin(30°) = 0.5 on S scale (read on C/D)
    /// 2. Set C:7 over D:0.5, giving 3.5
    /// 3. Without reset, align DF index (π) with cursor
    /// 4. Read 11.0 on DF scale (3.5π ≈ 11.0)
    /// 5. Demonstrates π multiplication integration with trig
    ///
    /// **Example 4:** Preventing off-scale with multi-step: 3.8 × 45 continuing
    /// 1. Standard C/D would give 171, exceeding scale
    /// 2. Use DF:45 aligned with CF:3.8
    /// 3. Read intermediate on DF without going off-scale
    /// 4. Continue calculation with result on DF
    /// 5. Shows DF's advantage for extended range
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
    
    /// CIF scale: Inverted CF scale, folded reciprocal for complex operations
    ///
    /// **PostScript Reference:** CIF scale (line 514)
    /// Formula: log₁₀(1/x) for x in range π to 10π, displayed inverted
    /// Range: 10π to π (31.4159 to 3.14159, reversed)
    /// Used for: reciprocal-pi-calculations, division-in-folded-range, chained-operations
    ///
    /// **Physical Applications:**
    /// - Inverse circle calculations: d = C/π (diameter from circumference)
    /// - Inverse sphere calculations: r = ∛(3V/4π)
    /// - Complex sequential operations without slide repositioning
    /// - Extended range division operations
    ///
    /// **Example:** Calculate diameter from circumference (d = C/π, C=20)
    /// 1. Locate 20 on D scale
    /// 2. Set left index (10π) of CIF over 20 on D
    /// 3. Move to right index (π) on CIF
    /// 4. Read 6.37 on D scale (20/π ≈ 6.366)
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
    
    /// DIF scale: Inverted DF scale, folded reciprocal companion
    ///
    /// **PostScript Reference:** DIF scale (line 523)
    /// Formula: log₁₀(1/x) for x in range π to 10π
    /// Range: 10π to π (reversed)
    /// Used for: reciprocal-folded-operations
    ///
    /// **Physical Applications:**
    /// - Inverse circle calculations: d = C/π (diameter from circumference)
    /// - Inverse sphere calculations: r = ∛(3V/4π)
    /// - Complex sequential operations without slide repositioning
    /// - Extended range division operations
    ///
    /// **Example 1:** Complex chain: Calculate 6.3 × 2.5 × 0.17 × 9.3 × 2.8
    /// 1. Set D:6.3 with CI:2.5 → intermediate at CI index
    /// 2. Align CIF:9.3 with cursor
    /// 3. Move cursor to CF:2.8
    /// 4. Read final result on DIF scale
    /// 5. Five operations completed without slide repositioning
    /// 6. Demonstrates maximum efficiency with inverted-folded scales
    ///
    /// **Example 2:** Mixed operations: (12.5 ÷ 37) × 0.18 using CF/CIF/DIF
    /// 1. Set CI:37 over D:12.5 (division by reciprocal multiplication)
    /// 2. Move cursor to CF:0.18
    /// 3. Read intermediate on DIF scale
    /// 4. Result: ≈ 0.061
    /// 5. Shows seamless division-multiplication combining
    ///
    /// **Example 3:** Engineering calculation: Power factor correction
    /// Calculate: (240 × 0.85) ÷ (377 × π) using multiple scales
    /// 1. Set CF:240 over D:0.85 → result ≈ 204
    /// 2. Align DIF:377 with cursor position
    /// 3. π factor automatically included via DIF folding
    /// 4. Read corrected value on DF scale
    /// 5. Demonstrates electrical engineering application with π and reciprocals
    ///
    /// **Example 4:** Sequential reciprocal operations: 1/(1/4 + 1/6)
    /// 1. Locate 4 on CIF, read on DF → 0.25
    /// 2. Locate 6 on CIF, read on DF → 0.167
    /// 3. Sum mentally: 0.417
    /// 4. Find 0.417 on DIF scale
    /// 5. Read reciprocal result ≈ 2.4 on DF
    /// 6. Parallel calculation pattern common in electrical circuits
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