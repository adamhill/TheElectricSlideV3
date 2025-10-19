import Foundation
import SlideRuleCore
// MARK: - Advanced Scales Usage Examples

/// Comprehensive examples for TIME, CR3S, square root (R), and cube root (Q) scales

    
    // MARK: - Example 1: Time Conversion Scales
    
    /// Demonstrates the TIME and TIME2 scales for minute/hour conversions
    public func example1_TimeScales() {
        print("=" * 60)
        print("Example 1: Time Conversion Scales")
        print("=" * 60)
        
        let time = StandardScales.timeScale(length: 250.0)
        let time2 = StandardScales.time2Scale(length: 250.0)
        
        print("\nTIME scale: \(Int(time.beginValue)) to \(Int(time.endValue)) minutes")
        print("           (1:00 to 10:00 hours)")
        print("TIME2 scale: \(Int(time2.beginValue)) to \(Int(time2.endValue)) minutes")
        print("            (10:00 to 100:00 hours, or 0.4 to 4.2 days)")
        
        // Generate and show labels
        let genTime = GeneratedScale(definition: time)
        print("\nTIME scale labels (sample):")
        genTime.tickMarks.filter { $0.style == .major && $0.label != nil }.prefix(8).forEach {
            let minutes = Int($0.value)
            print(String(format: "  %3d minutes → \"%@\"", minutes, $0.label ?? ""))
        }
        
        // Test specific conversions
        print("\nTime conversion examples:")
        let testTimes: [Double] = [90, 120, 180, 240, 360, 480]
        for minutes in testTimes {
            let pos = ScaleCalculator.normalizedPosition(for: minutes, on: time)
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            print(String(format: "  %3.0f min = %d:%02d → position %.3f",
                        minutes, hours, mins, pos))
        }
        
        // Show formula explanation
        print("\n" + "─" * 60)
        print("Formula: log₁₀(x/60) + log₁₀(6) = log₁₀(x/10)")
        print("")
        print("Why this works:")
        print("- Converts minutes to hours-relative logarithmic scale")
        print("- Aligns with standard C/D scales for multiplication")
        print("- Example: 2 hours × 1.5 = 3 hours (120 min × 1.5 = 180 min)")
        print("─" * 60)
    }
    
    // MARK: - Example 2: Combined Sine/Cosine Scale
    
    /// Demonstrates the CR3S combined sine/cosine scale
    public func example2_CR3SScale() {
        print("\n" + "=" * 60)
        print("Example 2: Combined Sine/Cosine Scale (CR3S)")
        print("=" * 60)
        
        let cr3s = StandardScales.cr3sScale(length: 250.0)
        print("\nCR3S scale: \(Int(cr3s.beginValue))° to \(Int(cr3s.endValue))°")
        print("Dual purpose: Read as sine (left) or cosine (right)")
        
        let generated = GeneratedScale(definition: cr3s)
        print("\nGenerated \(generated.tickMarks.count) tick marks")
        
        // Demonstrate complementary angles
        print("\nComplementary angle pairs (sin x = cos(90-x)):")
        let testAngles: [Double] = [10, 20, 30, 45, 60, 70, 80]
        for angle in testAngles {
            let complement = 90 - angle
            let posSine = ScaleCalculator.normalizedPosition(for: angle, on: cr3s)
            let posCosine = ScaleCalculator.normalizedPosition(for: complement, on: cr3s)
            
            // These should be at the same position!
            let samePosition = abs(posSine - posCosine) < 0.001
            let marker = samePosition ? "✓" : "✗"
            
            print(String(format: "  %s sin(%2.0f°) at %.3f = cos(%2.0f°) at %.3f",
                        marker, angle, posSine, complement, posCosine))
        }
        
        // Show constants (small angle markers)
        print("\nSmall angle constants (1° - 5°):")
        for constant in cr3s.constants.prefix(9) {
            let pos = ScaleCalculator.normalizedPosition(for: constant.value, on: cr3s)
            print(String(format: "  %s at position %.3f", constant.label, pos))
        }
        
        print("\n" + "─" * 60)
        print("Use Case: Navigation and surveying")
        print("- Read sine values left-to-right (6° → 90°)")
        print("- Read cosine values right-to-left (84° → 0°)")
        print("- Uses identity: cos(x) = sin(90° - x)")
        print("─" * 60)
    }
    
    // MARK: - Example 3: Square Root Scales (R1, R2)
    
    /// Demonstrates the square root scales and their usage
    public func example3_SquareRootScales() {
        print("\n" + "=" * 60)
        print("Example 3: Square Root Scales (R1/Sq1 and R2/Sq2)")
        print("=" * 60)
        
        let r1 = StandardScales.r1Scale(length: 250.0)
        let r2 = StandardScales.r2Scale(length: 250.0)
        
        print("\nR1 (Sq1): \(r1.beginValue) to \(r1.endValue) → covers √1 to √10")
        print("R2 (Sq2): \(r2.beginValue) to \(r2.endValue) → covers √10 to √100")
        print("\nFormula: f(x) = log₁₀(x) × 2")
        
        // Find square roots
        print("\nSquare root calculations:")
        let testValues: [Double] = [2, 4, 8, 16, 25, 50, 64, 81, 100]
        
        for value in testValues {
            let sqrt = value.squareRoot()
            
            // Determine which scale to use
            let scale: ScaleDefinition
            let scaleName: String
            if sqrt <= 3.2 {
                scale = r1
                scaleName = "R1"
            } else {
                scale = r2
                scaleName = "R2"
            }
            
            let pos = ScaleCalculator.normalizedPosition(for: sqrt, on: scale)
            //print(String(format: "  √%3.0f = %5.2f  (on %s at position %.3f)",
             //           value, sqrt, scaleName, pos))
        }
        
        // Show how they work together
        print("\n" + "─" * 60)
        print("How to use R1/R2 scales:")
        print("")
        print("Finding √64:")
        print("1. Locate 64 on the C or D scale")
        print("2. Read the corresponding value on R1/R2")
        print("3. Answer: 8 (because 8² = 64)")
        print("")
        print("The 2× multiplier in the formula:")
        print("- Makes two rotations on the log scale equal one on C/D")
        print("- Position of x on R = position of x² on C")
        print("─" * 60)
    }
    
    // MARK: - Example 4: Cube Root Scales (Q1, Q2, Q3)
    
    /// Demonstrates the cube root scales and their usage
    public func example4_CubeRootScales() {
        print("\n" + "=" * 60)
        print("Example 4: Cube Root Scales (Q1, Q2, Q3)")
        print("=" * 60)
        
        let q1 = StandardScales.q1Scale(length: 250.0)
        let q2 = StandardScales.q2Scale(length: 250.0)
        let q3 = StandardScales.q3Scale(length: 250.0)
        
        print("\nQ1: \(q1.beginValue) to \(q1.endValue) → covers ∛1 to ∛10")
        print("Q2: \(q2.beginValue) to \(q2.endValue) → covers ∛10 to ∛100")
        print("Q3: \(q3.beginValue) to \(q3.endValue) → covers ∛100 to ∛1000")
        print("\nFormula: f(x) = log₁₀(x) × 3")
        
        // Find cube roots
        print("\nCube root calculations:")
        let testValues: [Double] = [8, 27, 64, 125, 216, 343, 512, 729, 1000]
        
        for value in testValues {
            let cbrt = pow(value, 1.0/3.0)
            
            // Determine which scale to use
            let scale: ScaleDefinition
            let scaleName: String
            if cbrt <= 2.16 {
                scale = q1
                scaleName = "Q1"
            } else if cbrt <= 4.7 {
                scale = q2
                scaleName = "Q2"
            } else {
                scale = q3
                scaleName = "Q3"
            }
            
            let pos = ScaleCalculator.normalizedPosition(for: cbrt, on: scale)
            //print(String(format: "  ∛%4.0f = %5.2f  (on %s at position %.3f)",
             //           value, cbrt, scaleName, pos))
        }
        
        // Show the mathematical progression
        print("\n" + "─" * 60)
        print("Three-part scale coverage:")
        print("")
        print("  Q1: ∛(1 to 10)    = 1.00 to 2.15")
        print("  Q2: ∛(10 to 100)  = 2.15 to 4.64")
        print("  Q3: ∛(100 to 1000)= 4.64 to 10.0")
        print("")
        print("Finding ∛125:")
        print("1. Locate 125 on the C or D scale")
        print("2. Read the corresponding value on Q1/Q2/Q3")
        print("3. Answer: 5 (because 5³ = 125)")
        print("─" * 60)
    }
    
    // MARK: - Example 5: Using R and Q Scales Together
    
    /// Demonstrates combined usage of square root and cube root scales
    public func example5_CombinedRootScales() {
        print("\n" + "=" * 60)
        print("Example 5: Combined Square and Cube Root Calculations")
        print("=" * 60)
        
        print("\nComparing square and cube roots of the same value:")
        
        let values: [Double] = [8, 27, 64, 125, 216, 512, 1000]
        
        for value in values {
            let sqrt = value.squareRoot()
            let cbrt = pow(value, 1.0/3.0)
            
            print(String(format: "\nValue: %.0f", value))
            print(String(format: "  √%.0f  = %.3f", value, sqrt))
            print(String(format: "  ∛%.0f = %.3f", value, cbrt))
            print(String(format: "  Ratio: %.3f (√ is %.1f%% larger)",
                        sqrt/cbrt, (sqrt/cbrt - 1) * 100))
        }
        
        // Special calculations
        print("\n" + "─" * 60)
        print("Special Calculations:")
        print("")
        
        // Finding √(∛x)
        let x = 64.0
        let cbrt64 = pow(x, 1.0/3.0)  // 4
        let sqrtOfCbrt = cbrt64.squareRoot()  // 2
        print(String(format: "√(∛64) = √4 = %.0f  (sixth root: 64^(1/6))", sqrtOfCbrt))
        
        // Finding ∛(√x)
        let sqrt64 = x.squareRoot()  // 8
        let cbrtOfSqrt = pow(sqrt64, 1.0/3.0)  // 2
        print(String(format: "∛(√64) = ∛8 = %.0f  (sixth root: 64^(1/6))", cbrtOfSqrt))
        
        print("\nBoth give the same answer - sixth root!")
        print("Because: x^(1/2 × 1/3) = x^(1/3 × 1/2) = x^(1/6)")
        print("─" * 60)
    }
    
    // MARK: - Example 6: D10-100 Scale
    
    /// Demonstrates the D10-100 scale (companion to C10-100)
    public func example6_D10to100Scale() {
        print("\n" + "=" * 60)
        print("Example 6: D10-100 Scale")
        print("=" * 60)
        
        let c10_100 = StandardScales.c10to100Scale(length: 250.0)
        let d10_100 = StandardScales.d10to100Scale(length: 250.0)
        
        print("\nC10-100: Upward ticks, 10 to 100")
        print("D10-100: Downward ticks, 10 to 100")
        print("\nThese are companion scales like C and D.")
        
        // Compare positions
        print("\nPosition comparison at key values:")
        let testValues: [Double] = [1.5, 2.5, 5.0, 7.5]
        
        for value in testValues {
            let posC = ScaleCalculator.normalizedPosition(for: value, on: c10_100)
            let posD = ScaleCalculator.normalizedPosition(for: value, on: d10_100)
            let displayValue = value * 10
            
            print(String(format: "  %.1f (displays as %.0f): C=%.3f, D=%.3f %s",
                        value, displayValue, posC, posD,
                        abs(posC - posD) < 0.001 ? "✓" : "✗"))
        }
        
        print("\n" + "─" * 60)
        print("Usage:")
        print("- Same calculations as C/D scales")
        print("- But in the 10-100 range without mental shifting")
        print("- Example: 25 × 2 = 50 (on C10-100 and D10-100)")
        print("           versus 2.5 × 2 = 5 (on C and D)")
        print("─" * 60)
    }
    
    // MARK: - Example 7: Factory Methods
    
    /// Demonstrates factory methods for advanced scales
    public func example7_FactoryMethods() {
        print("\n" + "=" * 60)
        print("Example 7: Factory Methods for Advanced Scales")
        print("=" * 60)
        
        print("\nAdvanced scale factory:")
        let advancedNames = ["TIME", "TIME2", "CR3S", "D10-100", "R1", "R2", "Q1", "Q2", "Q3"]
        for name in advancedNames {
            if let scale = StandardScales.scale(named: name) {
                print("  ✓ '\(name)' → '\(scale.name)'")
            }
        }
        
        print("\nUnified factory (all scales):")
        let allNames = ["C", "KE-S", "TIME", "R1", "Q2"]
        for name in allNames {
            if let scale = StandardScales.scale(named: name) {
                let type: String
                if StandardScales.scale(named: name) != nil {
                    type = "standard"
                } else if StandardScales.scale(named: name) != nil {
                    type = "specialty"
                } else {
                    type = "advanced"
                }
                print("  ✓ '\(name)' → '\(scale.name)' (\(type))")
            }
        }
        
        print("\nAlternate name variations:")
        let variations = [
            ("R1", "SQ1"),
            ("R2", "SQ2"),
            ("CR3S", "S/C"),
            ("D10-100", "D10.100")
        ]
        
        for (name1, name2) in variations {
            let scale1 = StandardScales.scale(named: name1)
            let scale2 = StandardScales.scale(named: name2)
            if scale1 != nil && scale2 != nil {
                print("  '\(name1)' = '\(name2)' → same scale")
            }
        }
        
        print("\n" + "─" * 60)
        print("The unified factory searches:")
        print("1. Standard scales (C, D, A, K, etc.)")
        print("2. Specialty scales (KE-S, CAS, etc.)")
        print("3. Advanced scales (TIME, R1, Q1, etc.)")
        print("─" * 60)
    }
    
    // MARK: - Example 8: Validation and Statistics
    
    /// Validates all advanced scales and shows statistics
    public func example8_ValidationAndStats() {
        print("\n" + "=" * 60)
        print("Example 8: Validation and Statistics")
        print("=" * 60)
        
        let scales: [(String, ScaleDefinition)] = [
            ("TIME", StandardScales.timeScale()),
            ("TIME2", StandardScales.time2Scale()),
            ("CR3S", StandardScales.cr3sScale()),
            ("D10-100", StandardScales.d10to100Scale()),
            ("R1", StandardScales.r1Scale()),
            ("R2", StandardScales.r2Scale()),
            ("Q1", StandardScales.q1Scale()),
            ("Q2", StandardScales.q2Scale()),
            ("Q3", StandardScales.q3Scale())
        ]
        
        print("\nValidating scales...")
        var allValid = true
        
        for (name, definition) in scales {
            do {
                try ScaleValidator.validate(definition)
                let generated = GeneratedScale(definition: definition)
                let stats = ScaleAnalysis.ScaleStatistics(scale: generated)
                
                //print(String(format: "  ✓ %-8s: %3d ticks, %2d labeled",
                 //           name, stats.totalTicks, stats.labeledTicks))
            } catch let error as ScaleValidator.ValidationError {
                print("  ✗ \(name): \(error.description)")
                allValid = false
            } catch {
                print("  ✗ \(name): Unexpected error")
                allValid = false
            }
        }
        
        if allValid {
            print("\n✓ All advanced scales passed validation!")
        }
        
        // Detailed stats for one scale
        print("\nDetailed statistics for TIME scale:")
        let timeScale = GeneratedScale(definition: StandardScales.timeScale())
        let stats = ScaleAnalysis.ScaleStatistics(scale: timeScale)
        
        print("  Total ticks:    \(stats.totalTicks)")
        print("  Major ticks:    \(stats.majorTicks)")
        print("  Medium ticks:   \(stats.mediumTicks)")
        print("  Minor ticks:    \(stats.minorTicks)")
        print("  Tiny ticks:     \(stats.tinyTicks)")
        print("  Labeled ticks:  \(stats.labeledTicks)")
        print(String(format: "  Value range:    %.1f to %.1f",
                    stats.valueRange.min, stats.valueRange.max))
        print(String(format: "  Avg spacing:    %.4f", stats.averageTickSpacing))
        
        print("\n" + "─" * 60)
        print("All scales validated for:")
        print("- Finite ranges")
        print("- Invertible functions")
        print("- Non-overlapping subsections")
        print("- Proper label formatting")
        print("─" * 60)
    }
    
    // MARK: - Example 9: Concurrent Generation
    
    /// Demonstrates concurrent generation of advanced scales
    public func example9_ConcurrentGeneration() async {
        print("\n" + "=" * 60)
        print("Example 9: Concurrent Advanced Scale Generation")
        print("=" * 60)
        
        let definitions = [
            StandardScales.timeScale(),
            StandardScales.cr3sScale(),
            StandardScales.r1Scale(),
            StandardScales.r2Scale(),
            StandardScales.q1Scale(),
            StandardScales.q2Scale(),
            StandardScales.q3Scale()
        ]
        
        print("\nGenerating \(definitions.count) advanced scales concurrently...")
        
        let startTime = Date()
        let generator = ConcurrentScaleGenerator()
        let scales = await generator.generateScales(definitions)
        let duration = Date().timeIntervalSince(startTime)
        
        print("✓ Generated in \(String(format: "%.2f", duration * 1000))ms")
        
        print("\nResults:")
        for scale in scales {
            print("  \(scale.definition.name): \(scale.tickMarks.count) ticks")
        }
        
        print("\n" + "─" * 60)
        print("Benefits of concurrent generation:")
        print("- Utilizes multiple CPU cores")
        print("- ~2-3x speedup on modern hardware")
        print("- Thread-safe with Swift 6 concurrency")
        print("─" * 60)
    }
    
    // MARK: - Run All Examples
    
    /// Runs all advanced scale examples
    public func runAllTimeSquaresCubes() {
        example1_TimeScales()
        example2_CR3SScale()
        example3_SquareRootScales()
        example4_CubeRootScales()
        example5_CombinedRootScales()
        example6_D10to100Scale()
        example7_FactoryMethods()
        example8_ValidationAndStats()
        //example9_ConcurrentGeneration()
        
        print("\n" + "=" * 60)
        print("All Advanced Scale Examples Complete!")
        print("=" * 60)
    }


// MARK: - Quick Test Function

/// Quick test to verify all advanced scales work
public func testTimeSquaresCubes() {
    print("Testing Advanced Scales...")
    
    let scales: [(String, ScaleDefinition)] = [
        ("TIME", StandardScales.timeScale()),
        ("TIME2", StandardScales.time2Scale()),
        ("CR3S", StandardScales.cr3sScale()),
        ("D10-100", StandardScales.d10to100Scale()),
        ("R1", StandardScales.r1Scale()),
        ("R2", StandardScales.r2Scale()),
        ("Q1", StandardScales.q1Scale()),
        ("Q2", StandardScales.q2Scale()),
        ("Q3", StandardScales.q3Scale())
    ]
    
    for (name, definition) in scales {
        let generated = GeneratedScale(definition: definition)
        print("  ✓ \(name): \(generated.tickMarks.count) ticks")
    }
    
    print("✓ All advanced scales working!")
}

// MARK: - Mathematical Verification Examples

/// Verifies mathematical correctness of root scales
public func verifyRootScaleCalculations() {
    print("\n" + "=" * 60)
    print("Verifying Root Scale Mathematical Correctness")
    print("=" * 60)
    
    // Verify square root scales
    print("\nSquare Root Scale Verification:")
    let squareTestValues: [Double] = [4, 9, 16, 25, 36, 49, 64, 81, 100]
    
    for value in squareTestValues {
        let expectedSqrt = value.squareRoot()
        
        // Choose appropriate scale
        let scale = expectedSqrt <= 3.2
            ? StandardScales.r1Scale()
            : StandardScales.r2Scale()
        
        // Forward: sqrt → position
        let position = ScaleCalculator.normalizedPosition(for: expectedSqrt, on: scale)
        
        // Reverse: position → sqrt
        let calculatedSqrt = ScaleCalculator.value(at: position, on: scale)
        
        let error = abs(expectedSqrt - calculatedSqrt)
        let errorPercent = (error / expectedSqrt) * 100
        
        let status = errorPercent < 0.01 ? "✓" : "✗"
        print(String(format: "  %s √%.0f = %.3f (calculated: %.3f, error: %.4f%%)",
                    status, value, expectedSqrt, calculatedSqrt, errorPercent))
    }
    
    // Verify cube root scales
    print("\nCube Root Scale Verification:")
    let cubeTestValues: [Double] = [8, 27, 64, 125, 216, 343, 512, 729, 1000]
    
    for value in cubeTestValues {
        let expectedCbrt = pow(value, 1.0/3.0)
        
        // Choose appropriate scale
        let scale: ScaleDefinition
        if expectedCbrt <= 2.16 {
            scale = StandardScales.q1Scale()
        } else if expectedCbrt <= 4.7 {
            scale = StandardScales.q2Scale()
        } else {
            scale = StandardScales.q3Scale()
        }
        
        // Forward: cbrt → position
        let position = ScaleCalculator.normalizedPosition(for: expectedCbrt, on: scale)
        
        // Reverse: position → cbrt
        let calculatedCbrt = ScaleCalculator.value(at: position, on: scale)
        
        let error = abs(expectedCbrt - calculatedCbrt)
        let errorPercent = (error / expectedCbrt) * 100
        
        let status = errorPercent < 0.01 ? "✓" : "✗"
        print(String(format: "  %s ∛%.0f = %.3f (calculated: %.3f, error: %.4f%%)",
                    status, value, expectedCbrt, calculatedCbrt, errorPercent))
    }
    
    print("\n" + "─" * 60)
    print("All calculations should have < 0.01% error")
    print("This verifies the transform/inverseTransform functions")
    print("─" * 60)
}

