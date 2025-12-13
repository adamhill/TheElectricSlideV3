import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Debug test to identify why L scale doesn't render in the application
@Suite("L Scale Rendering Debug")
struct LScaleRenderingDebugTest {
    
    @Test("Parse application's slide rule definition and check L scale")
    func testApplicationDefinitionParsing() throws {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        // This is the EXACT definition from ContentView.swift line 255
        let definition = "( L DF [ CF- CIF DI CI C ] D A)"
        
        print("\n=== APPLICATION PARSING DEBUG ===")
        print("Definition: \(definition)")
        
        let slideRule = try RuleDefinitionParser.parse(
            definition,
            dimensions: dimensions,
            scaleLength: 800.0
        )
        
        print("\nFront Top Stator scales: \(slideRule.frontTopStator.scales.count)")
        for (i, scale) in slideRule.frontTopStator.scales.enumerated() {
            print("  \(i): \(scale.definition.name) - \(scale.tickMarks.count) ticks")
        }
        
        print("\nFront Slide scales: \(slideRule.frontSlide.scales.count)")
        for (i, scale) in slideRule.frontSlide.scales.enumerated() {
            print("  \(i): \(scale.definition.name) - \(scale.tickMarks.count) ticks")
        }
        
        print("\nFront Bottom Stator scales: \(slideRule.frontBottomStator.scales.count)")
        for (i, scale) in slideRule.frontBottomStator.scales.enumerated() {
            print("  \(i): \(scale.definition.name) - \(scale.tickMarks.count) ticks")
        }
        
        // Find L scale
        let allScales = slideRule.frontTopStator.scales + 
                       slideRule.frontSlide.scales + 
                       slideRule.frontBottomStator.scales
        
        if let lScale = allScales.first(where: { $0.definition.name == "L" }) {
            print("\nL Scale FOUND!")
            print("  Location: ", terminator: "")
            if slideRule.frontTopStator.scales.contains(where: { $0.definition.name == "L" }) {
                print("Top Stator")
            } else if slideRule.frontSlide.scales.contains(where: { $0.definition.name == "L" }) {
                print("Slide")
            } else {
                print("Bottom Stator")
            }
            print("  Tick count: \(lScale.tickMarks.count)")
            print("  First 5 ticks:")
            for tick in lScale.tickMarks.prefix(5) {
                print("    value=\(tick.value), pos=\(tick.normalizedPosition)")
            }
        } else {
            print("\nERROR: L Scale NOT FOUND in parsed slide rule!")
        }
        
        print("=== END DEBUG ===\n")
    }
    
    @Test("Check if StandardScales can create L scale")
    func testStandardScalesLookup() {
        print("\n=== STANDARD SCALES LOOKUP DEBUG ===")
        
        // Try to get L scale by name
        if let lScale = StandardScales.scale(named: "L", length: 800.0) {
            print("✓ StandardScales.scale(named: \"L\") SUCCESS")
            print("  Range: \(lScale.beginValue) to \(lScale.endValue)")
            print("  Subsections: \(lScale.subsections.count)")
            
            let generated = GeneratedScale(definition: lScale)
            print("  Generated ticks: \(generated.tickMarks.count)")
        } else {
            print("✗ StandardScales.scale(named: \"L\") returned nil!")
            print("  This means the factory method can't find the L scale!")
        }
        
        print("=== END DEBUG ===\n")
    }
}