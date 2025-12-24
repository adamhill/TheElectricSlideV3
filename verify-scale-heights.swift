#!/usr/bin/env swift

import Foundation

// Add the SlideRuleCoreV3 package to the script's import path
#if canImport(SlideRuleCoreV3)
import SlideRuleCoreV3
#else
print("Error: Could not import SlideRuleCoreV3")
print("Run this script from the project root with:")
print("  swift run -Xswiftc -I -Xswiftc ./SlideRuleCoreV3/.build/debug verify-scale-heights.swift")
exit(1)
#endif

print("=" * 70)
print("SCALE HEIGHT VERIFICATION")
print("=" * 70)

// Test K&E 4081-3 (14mm/13mm/14mm components)
print("\n### K&E 4081-3 Log-Log Duplex Decitrig")
print("Component Heights: Top=14mm, Slide=13mm, Bottom=14mm")
print("Definition: (LL01 K A [ B | T ST S ] D L- LL1-)")

let ke4081Dimensions = RuleDefinition Parser.Dimensions(
    topStatorMM: 14,
    slideMM: 13,
    bottomStatorMM: 14
)

do {
    let keRule = try RuleDefinitionParser.parse(
        "(LL01 K A [ B | T ST S ] D L- LL1-)",
        dimensions: ke4081Dimensions,
        scaleLength: 250.0
    )
    
    print("\nFront Top Stator:")
    print("  Component Height: \(String(format: "%.2f", ke4081Dimensions.topStatorHeight))pt")
    print("  Scale Count: \(keRule.frontTopStator.scales.count)")
    if keRule.frontTopStator.scales.count > 0 {
        let firstScale = keRule.frontTopStator.scales[0]
        let heightMM = firstScale.definition.height / 2.834645669
        print("  Individual Scale Height: \(String(format: "%.2f", firstScale.definition.height))pt = \(String(format: "%.2fmm", heightMM))")
        print("  Total Height Used: \(String(format: "%.2f", Double(keRule.frontTopStator.scales.count) * firstScale.definition.height))pt")
    }
    
    print("\nFront Slide:")
    print("  Component Height: \(String(format: "%.2f", ke4081Dimensions.slideHeight))pt")
    print("  Scale Count: \(keRule.frontSlide.scales.count)")
    if keRule.frontSlide.scales.count > 0 {
        let firstScale = keRule.frontSlide.scales[0]
        let heightMM = firstScale.definition.height / 2.834645669
        print("  Individual Scale Height: \(String(format: "%.2f", firstScale.definition.height))pt = \(String(format: "%.2fmm", heightMM))")
        print("  Total Height Used: \(String(format: "%.2f", Double(keRule.frontSlide.scales.count) * firstScale.definition.height))pt")
    }
    
    print("\nFront Bottom Stator:")
    print("  Component Height: \(String(format: "%.2f", ke4081Dimensions.bottomStatorHeight))pt")
    print("  Scale Count: \(keRule.frontBottomStator.scales.count)")
    if keRule.frontBottomStator.scales.count > 0 {
        let firstScale = keRule.frontBottomStator.scales[0]
        let heightMM = firstScale.definition.height / 2.834645669
        print("  Individual Scale Height: \(String(format: "%.2f", firstScale.definition.height))pt = \(String(format: "%.2fmm", heightMM))")
        print("  Total Height Used: \(String(format: "%.2f", Double(keRule.frontBottomStator.scales.count) * firstScale.definition.height))pt")
    }
    
} catch {
    print("Error parsing K&E 4081-3: \(error)")
}

// Test Hemmi 266 (15mm/15mm/15mm components)
print("\n\n### Hemmi 266")
print("Component Heights: All=15mm")
print("Definition: (H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T-)")

let hemmi266Dimensions = RuleDefinitionParser.Dimensions(
    topStatorMM: 15,
    slideMM: 15,
    bottomStatorMM: 15
)

do {
    let hemmiRule = try RuleDefinitionParser.parse(
        "(H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T-)",
        dimensions: hemmi266Dimensions,
        scaleLength: 250.0
    )
    
    print("\nFront Top Stator:")
    print("  Component Height: \(String(format: "%.2f", hemmi266Dimensions.topStatorHeight))pt")
    print("  Scale Count: \(hemmiRule.frontTopStator.scales.count)")
    if hemmiRule.frontTopStator.scales.count > 0 {
        let firstScale = hemmiRule.frontTopStator.scales[0]
        let heightMM = firstScale.definition.height / 2.834645669
        print("  Individual Scale Height: \(String(format: "%.2f", firstScale.definition.height))pt = \(String(format: "%.2fmm", heightMM))")
        print("  Expected: ~3mm (8.5pt) for 5 scales")
    }
    
    print("\nFront Slide:")
    print("  Component Height: \(String(format: "%.2f", hemmi266Dimensions.slideHeight))pt")
    print("  Scale Count: \(hemmiRule.frontSlide.scales.count)")
    if hemmiRule.frontSlide.scales.count > 0 {
        let firstScale = hemmiRule.frontSlide.scales[0]
        let heightMM = firstScale.definition.height / 2.834645669
        print("  Individual Scale Height: \(String(format: "%.2f", firstScale.definition.height))pt = \(String(format: "%.2fmm", heightMM))")
        print("  Expected: ~3.75mm (10.6pt) for 4 scales")
    }
    
    print("\nFront Bottom Stator:")
    print("  Component Height: \(String(format: "%.2f", hemmi266Dimensions.bottomStatorHeight))pt")
    print("  Scale Count: \(hemmiRule.frontBottomStator.scales.count)")
    if hemmiRule.frontBottomStator.scales.count > 0 {
        let firstScale = hemmiRule.frontBottomStator.scales[0]
        let heightMM = firstScale.definition.height / 2.834645669
        print("  Individual Scale Height: \(String(format: "%.2f", firstScale.definition.height))pt = \(String(format: "%.2fmm", heightMM))")
        print("  Expected: ~3.75mm (10.6pt) for 4 scales")
    }
    
} catch {
    print("Error parsing Hemmi 266: \(error)")
}

print("\n" + "=" * 70)
print("VERIFICATION COMPLETE")
print("=" * 70)
print("\nBEFORE FIX: All scales would be 36pt (12.7mm) each")
print("AFTER FIX: Scales sized to fit within component totals")
print("\nCalculation: individual_scale_height = component_height / scale_count")
