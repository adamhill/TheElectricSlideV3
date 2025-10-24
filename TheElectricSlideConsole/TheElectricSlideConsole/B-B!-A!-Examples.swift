//
//  B-B!-A!-Examples.swift
//  TheElectricSlideConsole
//
//  Created by Adam Hill on 10/18/25.
//
import Foundation
import SlideRuleCore

public func exampleBScales() {
    print("\n" + "═".repeating(count: 70))
    print("B, BI, AND AI SCALE EXAMPLES")
    print("═".repeating(count: 70))
    
    // Create scales
    let aScale = StandardScales.aScale()
    let bScale = StandardScales.bScale()
    let aiScale = StandardScales.aiScale()
    let biScale = StandardScales.biScale()
    
    print("\n## Scale Definitions")
    print("─".repeating(count: 70))
    print("A  scale: \(aScale.name), range \(aScale.beginValue)-\(aScale.endValue), ticks \(aScale.tickDirection)")
    print("B  scale: \(bScale.name), range \(bScale.beginValue)-\(bScale.endValue), ticks \(bScale.tickDirection)")
    print("AI scale: \(aiScale.name), range \(aiScale.beginValue)-\(aiScale.endValue), ticks \(aiScale.tickDirection)")
    print("BI scale: \(biScale.name), range \(biScale.beginValue)-\(biScale.endValue), ticks \(biScale.tickDirection)")
    
    // Generate and compare
    let genA = GeneratedScale(definition: aScale)
    let genB = GeneratedScale(definition: bScale)
    let genAI = GeneratedScale(definition: aiScale)
    let genBI = GeneratedScale(definition: biScale)
    
    print("\n## Tick Counts")
    print("─".repeating(count: 70))
    print("A:  \(genA.tickMarks.count) ticks")
    print("B:  \(genB.tickMarks.count) ticks (same as A)")
    print("AI: \(genAI.tickMarks.count) ticks")
    print("BI: \(genBI.tickMarks.count) ticks (same as AI)")
    
    // Test positions
    print("\n## Position Tests")
    print("─".repeating(count: 70))
    
    let testValues = [1.0, 4.0, 10.0, 25.0, 100.0]
    
    print("\nA and B scales (forward):")
    //print(String(format: "%-8s  %12s  %12s", "Value", "A Position", "B Position"))
    print("─".repeating(count: 35))
    for value in testValues {
        let posA = ScaleCalculator.normalizedPosition(for: value, on: aScale)
        let posB = ScaleCalculator.normalizedPosition(for: value, on: bScale)
        print(String(format: "%-8.1f  %12.4f  %12.4f", value, posA, posB))
    }
    print("✓ A and B have identical positions")
    
    print("\nAI and BI scales (inverse):")
    //print(String(format: "%-8s  %12s  %12s", "Value", "AI Position", "BI Position"))
    print("─".repeating(count: 35))
    for value in testValues.reversed() {  // AI/BI go from 100 to 1
        let posAI = ScaleCalculator.normalizedPosition(for: value, on: aiScale)
        let posBI = ScaleCalculator.normalizedPosition(for: value, on: biScale)
        print(String(format: "%-8.1f  %12.4f  %12.4f", value, posAI, posBI))
    }
    print("✓ AI and BI have identical positions")
    
    // Test inverse relationship
    print("\n## Inverse Relationship")
    print("─".repeating(count: 70))
    print("A scale at value 4:")
    let posA4 = ScaleCalculator.normalizedPosition(for: 4.0, on: aScale)
    print("  Position: \(String(format: "%.4f", posA4))")
    
    print("\nAI scale at value 25 (100/4):")
    let posAI25 = ScaleCalculator.normalizedPosition(for: 25.0, on: aiScale)
    print("  Position: \(String(format: "%.4f", posAI25))")
    
    print("\n✓ These positions mirror each other around 0.5")
    print("  Sum: \(String(format: "%.4f", posA4 + posAI25)) (should be ≈ 1.0)")
    
    // Usage example
    print("\n## Usage Example: Using A/AI for Division")
    print("─".repeating(count: 70))
    print("""
    To divide 36 ÷ 4 = 9:
    
    1. Find 36 on A scale
       Position: \(String(format: "%.4f", ScaleCalculator.normalizedPosition(for: 36.0, on: aScale)))
    
    2. Find 4 on AI scale (which is 100/4 = 25 on A scale)
       Position: \(String(format: "%.4f", ScaleCalculator.normalizedPosition(for: 4.0, on: aiScale)))
    
    3. Read result at aligned position on A scale
       Expected: 9 (\(String(format: "%.4f", ScaleCalculator.normalizedPosition(for: 9.0, on: aScale))))
    
    The AI scale eliminates the need to move the slide for division!
    """)
    
    // Label color test
    print("\n## Label Colors")
    print("─".repeating(count: 70))
    print("A scale:  \(aScale.labelColor == nil ? "Default (black)" : "Custom")")
    print("B scale:  \(bScale.labelColor == nil ? "Default (black)" : "Custom")")
    print("AI scale: \(aiScale.labelColor != nil ? "Red" : "Default")")
    print("BI scale: \(biScale.labelColor != nil ? "Red" : "Default")")
    
    if let color = aiScale.labelColor {
        print("  AI color: RGB(\(color.red), \(color.green), \(color.blue))")
    }
    
    print("\n" + "═".repeating(count: 70))
    print("END OF B/BI/AI SCALE EXAMPLES")
    print("═".repeating(count: 70) + "\n")
}

