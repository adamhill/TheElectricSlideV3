#!/usr/bin/env swift

import Foundation

// Add the package directory to the import search path
#if canImport(SlideRuleCoreV3)
import SlideRuleCoreV3
#else
print("Error: Cannot import SlideRuleCoreV3")
print("Run this script from the project root with:")
print("  swift -I SlideRuleCoreV3/.build/debug verify-w-scale-labels.swift")
exit(1)
#endif

// Faber-Castell 62/83N definition
let definition = "LL03 LL02 LL01 LL00 W2 [ W2' CI L C W1' ] W1 D^ LL0 LL1 LL2 LL3"

print("Testing Faber-Castell 62/83N W scale label display fix")
print("Definition: \(definition)")
print()

let dimensions = RuleDefinitionParser.Dimensions(
    topStatorMM: 15,
    slideMM: 15,
    bottomStatorMM: 15
)

do {
    let slideRule = try RuleDefinitionParser.parse(
        "(\(definition))",
        dimensions: dimensions,
        scaleLength: 250.0
    )
    
    print("✅ Parsing successful!")
    print()
    
    // Check top stator scales (should include W2)
    print("Top Stator Scales:")
    for scale in slideRule.frontTopStator.scales {
        let displayName = scale.definition.displayName ?? scale.definition.name
        let canonicalName = scale.definition.name
        let status = displayName == canonicalName ? "  " : "✓"
        print("  \(status) Display: '\(displayName)' (canonical: '\(canonicalName)')")
    }
    print()
    
    // Check slide scales (should include W2' and W1')
    print("Slide Scales:")
    for scale in slideRule.frontSlide.scales {
        let displayName = scale.definition.displayName ?? scale.definition.name
        let canonicalName = scale.definition.name
        let status = displayName == canonicalName ? "  " : "✓"
        print("  \(status) Display: '\(displayName)' (canonical: '\(canonicalName)')")
    }
    print()
    
    // Check bottom stator scales (should include W1)
    print("Bottom Stator Scales:")
    for scale in slideRule.frontBottomStator.scales {
        let displayName = scale.definition.displayName ?? scale.definition.name
        let canonicalName = scale.definition.name
        let status = displayName == canonicalName ? "  " : "✓"
        print("  \(status) Display: '\(displayName)' (canonical: '\(canonicalName)')")
    }
    print()
    
    // Verify expected W scale labels
    let wScales = [
        ("W2", slideRule.frontTopStator.scales),
        ("W2'", slideRule.frontSlide.scales),
        ("W1'", slideRule.frontSlide.scales),
        ("W1", slideRule.frontBottomStator.scales)
    ]
    
    print("Verification Results:")
    var allCorrect = true
    for (expectedDisplay, scales) in wScales {
        if let scale = scales.first(where: { ($0.definition.displayName ?? $0.definition.name) == expectedDisplay }) {
            let canonicalName = scale.definition.name
            print("  ✅ '\(expectedDisplay)' displays correctly (uses \(canonicalName) implementation)")
        } else {
            print("  ❌ '\(expectedDisplay)' NOT FOUND")
            allCorrect = false
        }
    }
    print()
    
    if allCorrect {
        print("🎉 SUCCESS: All W scale labels display with their original names!")
    } else {
        print("⚠️  FAILURE: Some W scale labels are missing or incorrect")
    }
    
} catch {
    print("❌ Parsing failed: \(error)")
    exit(1)
}