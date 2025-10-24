import Foundation
import SlideRuleCore

// MARK: - Usage Examples

/*
 This file demonstrates how to use the slide rule scale engine.
 
 The implementation is based on:
 1. Mathematical Foundations of the Slide Rule by Joseph Pasquale
    - Uses the formula: d(x) = m * (f(x) - f(x_L)) / (f(x_R) - f(x_L))
    - Where m = scale length, f = scale function, x_L = left value, x_R = right value
 
 2. PostScript Slide Rule Engine by Derek Pressnall
    - Scale definitions with subsections and tick patterns
    - Rule assembly with stators and slides
 */

// MARK: - Example 1: Simple Scale Creation

func example1_createBasicScale() {
    print("=== Example 1: Create a Basic C Scale ===\n")
    
    // Create a standard C scale (logarithmic, 1 to 10)
    let cScale = StandardScales.cScale(length: 250.0)
    
    // Generate all tick marks
    let generated = GeneratedScale(definition: cScale)
    
    print("Scale: \(generated.definition.name)")
    print("Function: \(generated.definition.function.name)")
    print("Range: \(generated.definition.beginValue) to \(generated.definition.endValue)")
    print("Total tick marks: \(generated.tickMarks.count)")
    
    // Find position of specific values
    let value = 2.5
    let position = ScaleCalculator.normalizedPosition(for: value, on: cScale)
    let absolutePos = ScaleCalculator.absolutePosition(for: value, on: cScale)
    
    print("\nValue \(value) is at:")
    print("  Normalized position: \(position) (0.0 = left, 1.0 = right)")
    print("  Absolute position: \(absolutePos) points from left")
    
    // Find major tick marks
    let majorTicks = generated.tickMarks.filter { $0.style.relativeLength >= 0.9 }
    print("\nMajor tick values: \(majorTicks.map { $0.value })")
}

// MARK: - Example 2: Custom Scale Creation

func example2_createCustomScale() {
    print("\n=== Example 2: Create a Custom Square Root Scale ===\n")
    
    // Create a custom scale for square roots: √x from 1 to 100
    let sqrtScale = ScaleBuilder()
        .withName("√X")
        .withFunction(CustomFunction(
            name: "sqrt",
            transform: { log10(sqrt($0)) },
            inverseTransform: { pow(pow(10, $0), 2) }
        ))
        .withRange(begin: 1, end: 100)
        .withLength(250.0)
        .withTickDirection(.up)
        .withSubsections([
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.oneDecimal
            ),
            ScaleSubsection(
                startValue: 10.0,
                tickIntervals: [10.0, 5.0, 1.0],
                labelLevels: [0],
                labelFormatter: StandardLabelFormatter.integer
            )
        ])
        .withLabelFormatter(StandardLabelFormatter.integer)
        .build()
    
    let generated = GeneratedScale(definition: sqrtScale)
    
    print("Created custom scale: \(generated.definition.name)")
    print("This scale shows square roots - for example:")
    
    for value in [4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0, 100.0] {
        let pos = ScaleCalculator.normalizedPosition(for: value, on: sqrtScale)
        print("  √\(Int(value)) = \(sqrt(value)) at position \(String(format: "%.3f", pos))")
    }
}

// MARK: - Example 3: Scale Analysis

func example3_analyzeScale() {
    print("\n=== Example 3: Analyze Scale Statistics ===\n")
    
    let dScale = StandardScales.dScale(length: 250.0)
    let generated = GeneratedScale(definition: dScale)
    
    // Get statistics
    let stats = ScaleAnalysis.ScaleStatistics(scale: generated)
    
    print("Statistics for D scale:")
    print("  Total ticks: \(stats.totalTicks)")
    print("  Major ticks: \(stats.majorTicks)")
    print("  Medium ticks: \(stats.mediumTicks)")
    print("  Minor ticks: \(stats.minorTicks)")
    print("  Tiny ticks: \(stats.tinyTicks)")
    print("  Labeled ticks: \(stats.labeledTicks)")
    print("  Value range: \(stats.valueRange.min) to \(stats.valueRange.max)")
    print("  Average tick spacing: \(String(format: "%.4f", stats.averageTickSpacing)) (normalized)")
    
    // Find highest density region
    if let highDensity = ScaleAnalysis.highestDensityRegion(in: generated) {
        print("\nHighest density region:")
        print("  From \(String(format: "%.2f", highDensity.start)) to \(String(format: "%.2f", highDensity.end))")
        print("  Density: \(String(format: "%.1f", highDensity.density)) ticks per normalized unit")
    }
}

// MARK: - Example 4: Parse Rule Definition

func example4_parseRuleDefinition() throws {
    print("\n=== Example 4: Parse a Complete Slide Rule ===\n")
    
    // Define dimensions (in mm, will be converted to points)
    let dimensions = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    // Parse a K&E 4081-3 style rule
    let ruleDefinition = "(K A [ C T ST S ] D L : LL1 LL2 LL3 [ CI C ] D)"
    let slideRule = try RuleDefinitionParser.parse(
        ruleDefinition,
        dimensions: dimensions,
        scaleLength: 250.0
    )
    
    print("Parsed slide rule definition: \(ruleDefinition)")
    print("\nFront side:")
    print("  Top stator: \(slideRule.frontTopStator.scales.map { $0.definition.name }.joined(separator: ", "))")
    print("  Slide: \(slideRule.frontSlide.scales.map { $0.definition.name }.joined(separator: ", "))")
    print("  Bottom stator: \(slideRule.frontBottomStator.scales.map { $0.definition.name }.joined(separator: ", "))")
    
    if let backTop = slideRule.backTopStator {
        print("\nBack side:")
        print("  Top stator: \(backTop.scales.map { $0.definition.name }.joined(separator: ", "))")
        if let backSlide = slideRule.backSlide {
            print("  Slide: \(backSlide.scales.map { $0.definition.name }.joined(separator: ", "))")
        }
        if let backBottom = slideRule.backBottomStator {
            print("  Bottom stator: \(backBottom.scales.map { $0.definition.name }.joined(separator: ", "))")
        }
    }
    
    // Validate the rule
    let errors = ScaleValidator.validateRule(slideRule)
    if errors.isEmpty {
        print("\n✓ All scales validated successfully!")
    } else {
        print("\n✗ Validation errors:")
        for (location, error) in errors {
            print("  \(location): \(error)")
        }
    }
}

// MARK: - Example 5: Multiplication Using C and D Scales

func example5_multiplicationExample() {
    print("\n=== Example 5: Perform Multiplication with C and D Scales ===\n")
    
    // This demonstrates the principle of slide rules for multiplication
    let cScale = StandardScales.cScale(length: 250.0)
    let dScale = StandardScales.dScale(length: 250.0)
    
    let cGenerated = GeneratedScale(definition: cScale)
    let dGenerated = GeneratedScale(definition: dScale)
    
    // To multiply 2 × 3 = 6
    let x = 2.0
    let y = 3.0
    let expectedResult = 6.0
    
    print("Multiplication: \(x) × \(y) = ?")
    print("\nSlide rule procedure:")
    print("1. Find \(x) on D scale")
    let xPositionD = ScaleCalculator.normalizedPosition(for: x, on: dScale)
    print("   Position: \(String(format: "%.4f", xPositionD))")
    
    print("\n2. Align C scale's index (1) with \(x) on D")
    print("   This sets the slide offset")
    
    print("\n3. Find \(y) on C scale")
    let yPositionC = ScaleCalculator.normalizedPosition(for: y, on: cScale)
    print("   Position: \(String(format: "%.4f", yPositionC))")
    
    print("\n4. Read result on D scale at same position as \(y) on C")
    // In actual use, you'd add the offset, but for this demo we calculate directly
    let resultPosition = ScaleCalculator.normalizedPosition(for: expectedResult, on: dScale)
    let calculatedResult = ScaleCalculator.value(at: resultPosition, on: dScale)
    print("   Result position: \(String(format: "%.4f", resultPosition))")
    print("   Result value: \(String(format: "%.2f", calculatedResult))")
    
    print("\nMathematical principle:")
    print("log(\(x)) + log(\(y)) = log(\(x) × \(y))")
    print("\(String(format: "%.4f", log10(x))) + \(String(format: "%.4f", log10(y))) = \(String(format: "%.4f", log10(expectedResult)))")
}

// MARK: - Example 6: Export Scale Data

func example6_exportScaleData() throws {
    print("\n=== Example 6: Export Scale Data ===\n")
    
    let cScale = StandardScales.cScale(length: 250.0)
    let generated = GeneratedScale(definition: cScale)
    
    // Export to CSV
    print("CSV Export (first 10 lines):")
    let csv = ScaleExporter.toCSV(generated)
    let csvLines = csv.components(separatedBy: "\n").prefix(11)
    for line in csvLines {
        print(line)
    }
    
    // Export to JSON
    print("\nJSON Export:")
    let json = try ScaleExporter.toJSON(generated)
    
    // For display, just show a truncated version
    if let jsonData = json.data(using: .utf8),
       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
        print("  name: \(jsonObject["name"] ?? "")")
        print("  functionName: \(jsonObject["functionName"] ?? "")")
        print("  tickMarks count: \((jsonObject["tickMarks"] as? [Any])?.count ?? 0)")
        print("  (truncated for display)")
    }
}

// MARK: - Example 7: Concurrent Scale Generation

@available(macOS 13.0, iOS 16.0, *)
func example7_concurrentGeneration() async {
    print("\n=== Example 7: Concurrent Scale Generation ===\n")
    
    let scaleDefinitions = [
        StandardScales.cScale(),
        StandardScales.dScale(),
        StandardScales.aScale(),
        StandardScales.kScale(),
        StandardScales.ll1Scale(),
        StandardScales.ll2Scale(),
        StandardScales.ll3Scale(),
        StandardScales.sScale(),
        StandardScales.tScale()
    ]
    
    print("Generating \(scaleDefinitions.count) scales concurrently...")
    
    let startTime = Date()
    let generator = ConcurrentScaleGenerator()
    let generatedScales = await generator.generateScales(scaleDefinitions)
    let elapsed = Date().timeIntervalSince(startTime)
    
    print("Generated \(generatedScales.count) scales in \(String(format: "%.3f", elapsed)) seconds")
    
    for (index, scale) in generatedScales.enumerated() {
        print("\(index + 1). \(scale.definition.name): \(scale.tickMarks.count) tick marks")
    }
}

// MARK: - Example 8: Finding Values and Interpolation

func example8_interpolation() {
    print("\n=== Example 8: Value Interpolation ===\n")
    
    let dScale = StandardScales.dScale(length: 250.0)
    let generated = GeneratedScale(definition: dScale)
    
    // Find value at a specific position
    let testPosition: NormalizedPosition = 0.5
    let valueAtMidpoint = ScaleInterpolation.interpolateValue(at: testPosition, in: generated)
    
    print("At normalized position \(testPosition) (midpoint):")
    print("  Value: \(String(format: "%.4f", valueAtMidpoint))")
    print("  (Should be approximately √10 ≈ 3.162)")
    
    // Find nearest labeled tick
    if let nearestTick = ScaleInterpolation.nearestLabeledTick(to: testPosition, in: generated) {
        print("\nNearest labeled tick:")
        print("  Value: \(nearestTick.value)")
        print("  Label: \(nearestTick.label ?? "none")")
        print("  Position: \(String(format: "%.4f", nearestTick.normalizedPosition))")
    }
    
    // Get all major divisions
    let majorDivs = ScaleInterpolation.majorDivisions(in: generated)
    print("\nMajor divisions: \(majorDivs.map { $0.value })")
}

// MARK: - Example 9: Folded Scales

func example9_foldedScales() {
    print("\n=== Example 9: Folded Scales (CF, DF, CIF) ===\n")
    
    // Folded scales are shifted by π to prevent "running off the scale"
    let cfScale = StandardScales.cfScale(length: 250.0)
    let dfScale = StandardScales.dfScale(length: 250.0)
    
    print("Folded scales start at π instead of 1")
    print("\nCF scale range: \(cfScale.beginValue) to \(cfScale.endValue)")
    print("  That's π to 10π, or approximately \(String(format: "%.2f", 1 * Swift.Float.pi)) to \(String(format: "%.2f", 10 * Swift.Float.pi))")
    
    let cfGenerated = GeneratedScale(definition: cfScale)
    let dfGenerated = GeneratedScale(definition: dfScale)
    
    print("\nCF scale tick marks: \(cfGenerated.tickMarks.count)")
    print("DF scale tick marks: \(dfGenerated.tickMarks.count)")
    
    // Show how folded scales work for multiplication
    print("\nExample multiplication: 5 × 2 = 10")
    print("Using CF/DF folded scales:")
    
    let x = 5.0
    let y = 2.0
    let result = 10.0
    
    let xPos = ScaleCalculator.normalizedPosition(for: x, on: cfScale)
    let yPos = ScaleCalculator.normalizedPosition(for: y, on: cfScale)
    let resultPos = ScaleCalculator.normalizedPosition(for: result, on: dfScale)
    
    print("  \(x) on CF at position: \(String(format: "%.4f", xPos))")
    print("  \(y) on CF at position: \(String(format: "%.4f", yPos))")
    print("  Result \(result) on DF at position: \(String(format: "%.4f", resultPos))")
    
    print("\nWhy folded scales?")
    print("  Regular C/D scales: 1 to 10")
    print("  Folded CF/DF scales: π to 10π (≈3.14 to 31.4)")
    print("  This prevents calculations from going off the edge!")
    print("  Example: 8 × 5 = 40 would go off a regular C scale,")
    print("  but on CF: 8 × 5 = 40 / 10 = 4 (read on DF, multiply by 10)")
}
// MARK: - Main Example Runner

func runAllExamples() {
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  Slide Rule Scale Engine - Usage Examples                   ║")
    print("║  Based on PostScript engine and mathematical foundations    ║")
    print("╚══════════════════════════════════════════════════════════════╝\n")
    
    example1_createBasicScale()
    example2_createCustomScale()
    example3_analyzeScale()
    
    do {
        try example4_parseRuleDefinition()
    } catch {
        print("Error parsing rule: \(error)")
    }
    
    example5_multiplicationExample()
    
    do {
        try example6_exportScaleData()
    } catch {
        print("Error exporting data: \(error)")
    }
    
    example8_interpolation()
    example9_foldedScales()
    
    // Async example (requires await context)
    if #available(macOS 13.0, iOS 16.0, *) {
        Task {
            //await example7_concurrentGeneration()
        }
    }
    
    print("\n╔══════════════════════════════════════════════════════════════╗")
    print("║  Examples complete!                                          ║")
    print("╚══════════════════════════════════════════════════════════════╝")
}

// MARK: - Quick Reference Documentation

/*
 QUICK REFERENCE
 ===============
 
 ## Creating a Scale
 
 ```swift
 // Use a predefined scale
 let cScale = StandardScales.cScale(length: 250.0)
 
 // Or build a custom scale
 let customScale = ScaleBuilder()
     .withName("MyScale")
     .withFunction(LogarithmicFunction())
     .withRange(begin: 1, end: 10)
     .withLength(250.0)
     .withSubsections([
         ScaleSubsection(
             startValue: 1.0,
             tickIntervals: [1.0, 0.1, 0.01],
             labelLevels: [0]
         )
     ])
     .build()
 ```
 
 ## Generating Tick Marks
 
 ```swift
 let generated = GeneratedScale(definition: cScale)
 print("Total ticks: \(generated.tickMarks.count)")
 
 for tick in generated.tickMarks {
     print("Value: \(tick.value), Position: \(tick.normalizedPosition)")
 }
 ```
 
 ## Finding Positions
 
 ```swift
 // Value to position
 let position = ScaleCalculator.normalizedPosition(for: 2.5, on: cScale)
 
 // Position to value
 let value = ScaleCalculator.value(at: 0.5, on: cScale)
 ```
 
 ## Parsing Rule Definitions
 
 ```swift
 let dimensions = RuleDefinitionParser.Dimensions(
     topStatorMM: 14, slideMM: 13, bottomStatorMM: 14
 )
 
 let rule = try RuleDefinitionParser.parse(
     "(C D [ CI ] A K)",
     dimensions: dimensions,
     scaleLength: 250.0
 )
 ```
 
 ## Available Standard Scales
 
 - C, D: Basic logarithmic scales (1-10)
 - CI: Inverted logarithmic (10-1)
 - CF, DF: Folded logarithmic (π to 10π)
 - CIF: Inverted folded (10π to π)
 - A: Square scale (reads x² on D)
 - K: Cube scale (reads x³ on D)
 - LL1, LL2, LL3: Log-log scales (for powers)
 - S: Sine scale (angles)
 - T, ST: Tangent scales
 - L: Linear logarithm (mantissa)
 - Ln: Natural logarithm
 
 ## Scale Functions
 
 - LogarithmicFunction: Standard log₁₀(x)
 - LogLogFunction: log₁₀(ln(x))
 - NaturalLogFunction: ln(x)
 - LinearFunction: x (identity)
 - SineFunction: sin(x)
 - TangentFunction: tan(x)
 - CustomFunction: Your own transform/inverse pair
 
 ## Mathematical Principle
 
 Position calculation:
   d(x) = m × (f(x) - f(x_L)) / (f(x_R) - f(x_L))
 
 Where:
   - d(x) = distance from left edge
   - m = scale length
   - f = scale function
   - x_L = leftmost value
   - x_R = rightmost value
 
 This formula from "Mathematical Foundations of the Slide Rule"
 by Joseph Pasquale ensures accurate positioning for any function.
 */
