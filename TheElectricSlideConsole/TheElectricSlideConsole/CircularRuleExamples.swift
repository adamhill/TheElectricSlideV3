import Foundation
import SlideRuleCore

// MARK: - Circular Rule Examples

/// Comprehensive examples demonstrating circular slide rule support
public func circularRuleExamples() {
    print("\n" + "═".repeating(count: 70))
    print("CIRCULAR RULE SUPPORT EXAMPLES")
    print("═".repeating(count: 70))
    
    example1_LinearVsCircular()
    example2_CircularConversion()
    example3_PostScriptSyntax()
    example4_ConcentricRings()
    example5_FactoryMethods2()
}

// MARK: - Example 1: Linear vs Circular Comparison

func example1_LinearVsCircular() {
    print("\n## Example 1: Linear vs Circular - Same Definition")
    print("─".repeating(count: 70))
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    do {
        // Linear rule
        let linear = try RuleDefinitionParser.parse(
            "(C D [ CI ])",
            dimensions: dims,
            scaleLength: 250.0
        )
        
        // Circular rule with same scales
        let circular = try RuleDefinitionParser.parseWithCircular(
            "(C D [ CI ]) circular:4inch",
            dimensions: dims
        )
        
        print("\nLinear Rule:")
        print("  Layout: Linear")
        print("  Total scales: \(linear.frontTopStator.scales.count + linear.frontSlide.scales.count + linear.frontBottomStator.scales.count)")
        print("  C scale ticks: \(linear.frontTopStator.scales.first?.tickMarks.count ?? 0)")
        
        print("\nCircular Rule:")
        print("  Layout: Circular")
        print("  Diameter: \(circular.diameter!) points (4 inches)")
        print("  Total scales: \(circular.frontTopStator.scales.count + circular.frontSlide.scales.count + circular.frontBottomStator.scales.count)")
        print("  C scale ticks: \(circular.frontTopStator.scales.first?.tickMarks.count ?? 0)")
        
        // Compare position calculations
        let linearC = linear.frontTopStator.scales.first!.definition
        let circularC = circular.frontTopStator.scales.first!.definition
        
        print("\nPosition of value 2.5:")
        let linearPos = ScaleCalculator.normalizedPosition(for: 2.5, on: linearC)
        let linearDist = ScaleCalculator.absolutePosition(for: 2.5, on: linearC)
        let circularAngle = ScaleCalculator.angularPosition(for: 2.5, on: circularC)
        
        print("  Linear:   \(String(format: "%.4f", linearPos)) normalized → \(String(format: "%.1f", linearDist)) points")
        print("  Circular: \(String(format: "%.4f", linearPos)) normalized → \(String(format: "%.1f°", circularAngle))")
        print("  ✓ Same normalized position, different physical representation")
        
    } catch {
        print("Error: \(error)")
    }
}

// MARK: - Example 2: Converting Existing Rules

func example2_CircularConversion() {
    print("\n## Example 2: Converting Linear Rules to Circular")
    print("─".repeating(count: 70))
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 12,
        slideMM: 16,
        bottomStatorMM: 8
    )
    
    do {
        // Define once, convert to circular
        let circular = try RuleDefinitionParser.parseWithCircular(
            "(K A [ C T ST S ] D L) circular:5inch",
            dimensions: dims
        )
        
        print("\nCircular Duplex Rule:")
        print("  Diameter: 5 inches (\(circular.diameter!) points)")
        print("  Outer ring (top stator): \(circular.frontTopStator.scales.map { $0.definition.name }.joined(separator: ", "))")
        print("  Middle ring (slide): \(circular.frontSlide.scales.map { $0.definition.name }.joined(separator: ", "))")
        print("  Inner ring (bottom): \(circular.frontBottomStator.scales.map { $0.definition.name }.joined(separator: ", "))")
        
        print("\nRadial positions:")
        for (i, radius) in circular.radialPositions!.enumerated() {
            let names = ["Outer", "Middle", "Inner"]
            print("  \(names[i]): \(String(format: "%.1f", radius)) points")
        }
        
        // Show circumferences
        print("\nCircumferences (scale length on ring):")
        for (i, radius) in circular.radialPositions!.enumerated() {
            let circumference = 2.0 * .pi * radius
            print("  Ring \(i + 1): \(String(format: "%.1f", circumference)) points")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// MARK: - Example 3: PostScript-Style Syntax

func example3_PostScriptSyntax() {
    print("\n## Example 3: PostScript-Compatible Syntax")
    print("─".repeating(count: 70))
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 3.5,
        slideMM: 17.5,
        bottomStatorMM: 0
    )
    
    // PostScript-style examples from the original engine
    let examples = [
        ("(C D [ CI ]) circular:4inch", "Simple 4-inch circular"),
        ("(K | A C [ D CI B L ]) circular:5inch", "Single-sided with separator"),
        ("(A [ C ] CI : LL1 LL2 [ D ] S) circular:4.5inch", "Duplex circular"),
    ]
    
    for (definition, description) in examples {
        do {
            let rule = try RuleDefinitionParser.parseWithCircular(
                definition,
                dimensions: dims
            )
            
            print("\n\(description):")
            print("  Definition: \(definition)")
            print("  Diameter: \(String(format: "%.1f", rule.diameter!)) points")
            print("  Front scales: \(rule.frontTopStator.scales.count + rule.frontSlide.scales.count + rule.frontBottomStator.scales.count)")
            if rule.backTopStator != nil {
                let backCount = (rule.backTopStator?.scales.count ?? 0) +
                               (rule.backSlide?.scales.count ?? 0) +
                               (rule.backBottomStator?.scales.count ?? 0)
                print("  Back scales: \(backCount)")
            }
            print("  ✓ Successfully parsed")
            
        } catch {
            print("  ✗ Error: \(error)")
        }
    }
}

// MARK: - Example 4: Multiple Concentric Rings

func example4_ConcentricRings() {
    print("\n## Example 4: Designing Concentric Rings")
    print("─".repeating(count: 70))
    
    // Design a 4-inch circular rule with carefully chosen radii
    let diameter: Distance = 288.0  // 4 inches
    
    // Radii from center (in mm, converted to points)
    let outerMM = 45.0  // ~1.77 inches from center
    let middleMM = 35.0 // ~1.38 inches from center
    let innerMM = 25.0  // ~0.98 inches from center
    
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: outerMM,
        slideMM: middleMM,
        bottomStatorMM: innerMM
    )
    
    do {
        let rule = try RuleDefinitionParser.parseWithCircular(
            "(A [ C ] CI) circular:4inch",
            dimensions: dims
        )
        
        print("\n4-inch Circular Rule Design:")
        print("  Total diameter: 4 inches (\(diameter) points)")
        
        let radii = rule.radialPositions!
        print("\nRing layout (from center):")
        for (i, radius) in radii.enumerated() {
            let inches = radius / 72.0
            let circumference = 2.0 * .pi * radius
            let scaleNames = [
                rule.frontTopStator.scales.map { $0.definition.name },
                rule.frontSlide.scales.map { $0.definition.name },
                rule.frontBottomStator.scales.map { $0.definition.name }
            ][i]
            
            print("\n  Ring \(i + 1): \(scaleNames.joined(separator: ", "))")
            print("    Radius: \(String(format: "%.1f", radius)) points (\(String(format: "%.2f", inches)) inches)")
            print("    Circumference: \(String(format: "%.1f", circumference)) points")
        }
        
        print("\nSpace between rings:")
        for i in 0..<(radii.count - 1) {
            let gap = radii[i] - radii[i + 1]
            print("  Rings \(i + 1)-\(i + 2): \(String(format: "%.1f", gap)) points")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// MARK: - Example 5: Factory Methods

func example5_FactoryMethods2() {
    print("\n## Example 5: Convenient Factory Methods")
    print("─".repeating(count: 70))
    
    // Linear rule
    let linear = SlideRule.logLogDuplexDecitrig()
    print("\nLinear Rule (Factory):")
    print("  Type: Log-Log Duplex Decitrig")
    print("  Layout: Linear")
    print("  Front scales: \(linear.frontTopStator.scales.count + linear.frontSlide.scales.count + linear.frontBottomStator.scales.count)")
    
    // Circular rule
    let circular = SlideRule.circularBasic(diameter: 288.0)
    print("\nCircular Rule (Factory):")
    print("  Type: Basic Circular")
    print("  Layout: Circular")
    print("  Diameter: \(circular.diameter!) points (4 inches)")
    print("  Scales: \(circular.frontTopStator.scales.count + circular.frontSlide.scales.count + circular.frontBottomStator.scales.count)")
    
    // Manual creation
    let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    do {
        let custom = try RuleDefinitionParser.parseWithCircular(
            "(D [ C ] CI) circular:6inch",
            dimensions: dims
        )
        
        print("\nCustom Circular Rule:")
        print("  Definition: (D [ C ] CI)")
        print("  Diameter: 6 inches")
        print("  Scales: \(custom.frontTopStator.scales.map { $0.definition.name }.joined(separator: ", "))")
        
        // Demonstrate usage
        let cScale = custom.frontSlide.scales.first!
        let testValue = 3.14159
        let angle = ScaleCalculator.angularPosition(for: testValue, on: cScale.definition)
        
        print("\nUsage Example:")
        print("  Find π (\(testValue)) on C scale")
        print("  Angular position: \(String(format: "%.1f°", angle))")
        
        // Find nearest tick
        if let nearestTick = cScale.nearestTick(to: testValue) {
            print("  Nearest tick: \(String(format: "%.2f", nearestTick.value)) at \(String(format: "%.1f°", nearestTick.angularPosition ?? 0))")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// MARK: - Run All Examples

extension String {
    func repeating(count: Int) -> String {
        String(repeating: self, count: count)
    }
}
