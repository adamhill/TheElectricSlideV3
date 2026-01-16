// ConfigurationAPIExamples.swift
// SlideRuleCoreV3
//
// Demonstrates the Scale Configuration API using the Pickett N-16 ES API Demo
// as a reference. These examples show all configuration patterns documented in
// swift-docs/scale-configuration-api-reference.md
//
// NOTE: All examples here use the ACTUAL implemented API and compile successfully.
// The "Pickett N-16 ES (API Demo)" rule in SlideRuleLibrary demonstrates ALL of these.

import Foundation

// MARK: - Example 1: Dense Stator with Alternating Names
// When a stator has many scales, suppress every other name for readability

/// Creates a configuration that hides names on even-indexed scales globally
func example1_denseStatorAlternatingNames() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        .suppressEvenScaleNames()  // Applies to ALL components
        .build()
}

// MARK: - Example 2: Colored Inverted and Log-Log Scales
// Make inverted scales red and Log-Log scales blue for visual distinction

/// Creates a configuration with colored scale labels
func example2_coloredScales() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        .colorInvertedScales(.red)    // CI, DI, CIF, DIF in red
        .colorLogLogScales(.blue)     // LL0, LL1, LL2, LL3, etc. in blue
        .build()
}

// MARK: - Example 3: Custom Component Configuration
// Fine-grained control over a specific component

/// Creates a configuration with custom settings for the slide
func example3_customComponentConfiguration() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        .configure(.frontSlide) {
            // Hide names on first 2 scales
            ScaleConfiguration.hideNames(for: .first(2))
            
            // Color the CI scale name red
            ScaleConfiguration.colorLabels(.red, for: .scale(.ci))
            
            // Nudge the C scale name slightly right
            ScaleConfiguration.nudgeName(.right(3), for: .scale(.c))
        }
        .build()
}

// MARK: - Example 4: Scale Name Overrides
// Display custom names instead of standard abbreviations

/// Creates a configuration with custom display names
func example4_scaleNameOverrides() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        .addNameOverrides([
            "CI": "1/x",      // CI → "1/x"
            "A": "x²",        // A → "x²"
            "K": "x³"         // K → "x³"
        ])
        .build()
}

// MARK: - Example 5: Complex Multi-Component Configuration
// Different settings for different parts of the rule

/// Creates a comprehensive configuration with multiple features
func example5_complexMultiComponent() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        // Global: hide all formulas
        .hideFormulas()
        
        // Front top stator: suppress alternate names (dense layout)
        .configure(.frontTopStator) {
            ScaleConfiguration.hideNames(for: .evenIndices)
        }
        
        // Front slide: color inverted scales
        .configure(.frontSlide) {
            ScaleConfiguration.colorLabels(.red, for: .scale(.ci))
            ScaleConfiguration.colorLabels(.red, for: .scale(.cif))
        }
        
        // Custom naming for electrical engineering scales
        .addNameOverride(canonical: "DQ", display: "D/Q")
        .addNameOverride(canonical: "L", display: "C/L")
        .addNameOverride(canonical: "Cos", display: "cos")
        .build()
}

// MARK: - Example 6: Pickett N-16 ES API Demo Configuration
// This is the full configuration that matches the API Demo rule in SlideRuleLibrary

/// Complete configuration demonstrating ALL API features
/// This matches what's implemented in SlideRuleLibrary.pickettN16ESAnnotationTest()
func example6_pickettN16ESAPIDemo() -> SlideRuleConfiguration {
    // Custom colors not in LabelColor constants
    let orange = LabelColor(red: 1.0, green: 0.5, blue: 0)
    let purple = LabelColor(red: 0.5, green: 0, blue: 0.5)
    
    // Create the legend annotation for the back slide
    let legendAnnotation = ComponentAnnotation(
        content: .text("""
            F = cycles per. sec.
            λ = meters × 10⁶
            ω = radians per. sec.
            T = seconds
            
            C = farads
            L = Henrys
            Xc = ohms
            XL = ohms
            """),
        color: LabelColor.black,
        horizontalPosition: 0.99,  // Right edge
        verticalPosition: 0.5,     // Vertically centered
        anchor: .trailing,
        fontSize: 8,
        fontWeight: .medium,
        textAlignment: .leading
    )
    
    // Demonstration annotation showing PositionNudge
    let nudgeDemoAnnotation = ComponentAnnotation(
        content: .text("← Nudged 10pt left"),
        color: LabelColor(red: 0, green: 0.5, blue: 0, alpha: 1),  // Green
        horizontalPosition: 0.5,   // Center of slide
        verticalPosition: 0.0,     // Near top
        anchor: .top,
        fontSize: 13,
        fontWeight: .medium,
        textAlignment: .center,
        nudge: PositionNudge.left(10)  // Fine-grained position adjustment
    )
    
    // Front side annotation
    let frontAnnotation = ComponentAnnotation(
        content: .text("API Demo →"),
        color: LabelColor(red: 0.8, green: 0.4, blue: 0, alpha: 1),  // Orange
        horizontalPosition: 0.01,
        verticalPosition: 0.5,
        anchor: .leading,
        fontSize: 10,
        fontWeight: .bold,
        textAlignment: .leading,
        nudge: PositionNudge.right(5)
    )
    
    return SlideRuleConfigurationBuilder()
        // EXAMPLE 1 & 9: Rule-level display settings
        .hideFormulas()
        
        // EXAMPLE 1: Dense stator with alternating names
        .suppressEvenScaleNames()
        
        // EXAMPLE 2: Colored inverted and Log-Log scales
        .colorInvertedScales(.red)
        .colorLogLogScales(.blue)
        
        // EXAMPLE 4: Scale name overrides
        .addNameOverrides([
            "DQ": "D/Q",
            "L": "C/L",
            "Cos": "cos",
            "CosΘ": "cos Θ",
            "Θ": "θ",
            "λ": "λ",
            "ω": "ω",
            "τ": "τ",
            "PF": "F"
        ])
        
        // EXAMPLE 3: Custom component configuration - nudge C scale
        .configure(.frontSlide) {
            ScaleConfiguration.nudgeName(.right(5), for: .scale(.c))
        }
        
        // EXAMPLE 8: Pattern-based configuration - trig scales green
        .configure(.frontTopStator) {
            ScaleConfiguration.colorLabels(.green, for: .matching(pattern: "^(S|ST|T|T1|T2|Cos|SH1|SH2|TH)$"))
        }
        .configure(.frontSlide) {
            ScaleConfiguration.colorLabels(.green, for: .matching(pattern: "^(S|ST|T|T1|T2|Cos|SH1|SH2|TH)$"))
        }
        .configure(.frontBottomStator) {
            ScaleConfiguration.colorLabels(.green, for: .matching(pattern: "^(S|ST|T|T1|T2|Cos|SH1|SH2|TH)$"))
        }
        .configure(.backTopStator) {
            ScaleConfiguration.colorLabels(.green, for: .matching(pattern: "^(S|ST|T|T1|T2|Cos|SH1|SH2|TH|CosΘ)$"))
        }
        .configure(.backSlide) {
            ScaleConfiguration.colorLabels(.green, for: .matching(pattern: "^(S|ST|T|T1|T2|Cos|SH1|SH2|TH|CosΘ)$"))
        }
        .configure(.backBottomStator) {
            ScaleConfiguration.colorLabels(.green, for: .matching(pattern: "^(S|ST|T|T1|T2|Cos|SH1|SH2|TH|CosΘ)$"))
        }
        
        // EXAMPLE 12: Index-based selection
        .configure(.frontTopStator) {
            ScaleConfiguration.colorLabels(orange, for: .first(1))
        }
        .configure(.frontBottomStator) {
            ScaleConfiguration.colorLabels(purple, for: .last(1))
        }
        
        // EXAMPLE 6: Annotations
        .addAnnotation(legendAnnotation, on: .back)
        .addAnnotation(nudgeDemoAnnotation, on: .back)
        .addAnnotation(frontAnnotation, on: .front)
        .build()
}

// MARK: - Example 7: Using the Resolver Directly
// For rendering code that needs to query resolved settings

/// Demonstrates how to use ScaleConfigurationResolver in rendering code
func example7_usingResolverDirectly() {
    // Build a configuration
    let config = SlideRuleConfigurationBuilder()
        .colorLogLogScales(.blue)
        .suppressOddScaleNames()
        .build()
    
    // Get resolver for a specific component
    let resolver = config.resolverFor(side: .front, component: .topStator)
    
    // Example scale data (in real code, these come from GeneratedScale)
    let scales = [
        ("LL3", 0), ("LL2", 1), ("LL1", 2), ("D", 3), ("L", 4)
    ]
    let totalScales = scales.count
    
    // Resolve display settings for each scale
    for (scaleName, index) in scales {
        let display = resolver.resolve(
            scaleName: scaleName,
            scaleIndex: index,
            totalScales: totalScales
        )
        
        // Use resolved settings in rendering
        if display.nameMargin != .none {
            let color = display.labelColor ?? LabelColor.black
            // In real code: render scale name with color
            print("Scale \(scaleName): show name with color \(color)")
        } else {
            print("Scale \(scaleName): name hidden")
        }
    }
}

// MARK: - Example 8: Pattern-Based Configuration
// Using regex patterns to configure groups of scales

/// Configures all scales matching a pattern
func example8_patternBasedConfiguration() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        // Configure all Log-Log scales (LL0, LL1, LL2, LL3, LL00, LL01, etc.)
        .configure(.frontTopStator) {
            ScaleConfiguration.colorLabels(.blue, for: .matching(pattern: "^LL[0-9]+$"))
        }
        .configure(.frontBottomStator) {
            ScaleConfiguration.colorLabels(.blue, for: .matching(pattern: "^LL[0-9]+$"))
        }
        
        // Configure all trig scales
        .configure(.frontSlide) {
            ScaleConfiguration.colorLabels(.green, for: .matching(pattern: "^(S|ST|T|T1|T2|Cos)$"))
        }
        .build()
}

// MARK: - Example 9: Formulas-Only Configuration
// Show formulas but hide scale names

/// Creates a configuration showing only formulas
func example9_formulasOnly() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        .hideScaleNames()  // Hide names
        // Formulas shown by default
        .build()
}

// MARK: - Example 10: Minimal Clean Display
// Hide all labels for a clean appearance

/// Creates a minimal configuration with no labels
func example10_minimalClean() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        .hideAllLabels()  // Hide both names and formulas
        .build()
}

// MARK: - Example 11: Split Scale Configuration
// Configure left and right segments of split scales separately

/// Configures split scales with different settings per segment
func example11_splitScaleConfiguration() -> SlideRuleConfiguration {
    SlideRuleConfigurationBuilder()
        .configure(.frontTopStator) {
            // Left segment of SQ1 - hide name (it's labeled on right)
            ScaleConfiguration.hideNames(for: .leftSegment(of: .sq1))
            
            // Right segment of SQ1 - color it orange
            let orange = LabelColor(red: 1.0, green: 0.5, blue: 0)
            ScaleConfiguration.colorLabels(orange, for: .rightSegment(of: .sq1))
        }
        .build()
}

// MARK: - Example 12: Index-Based Selection
// Configure specific scales by their position index

/// Configures scales at specific indices
func example12_indexBasedSelection() -> SlideRuleConfiguration {
    let orange = LabelColor(red: 1.0, green: 0.5, blue: 0)
    let purple = LabelColor(red: 0.5, green: 0, blue: 0.5)
    
    return SlideRuleConfigurationBuilder()
        .configure(.frontTopStator) {
            // Hide names for scales at indices 0, 2, and 4
            ScaleConfiguration.hideNames(for: .indices([0, 2, 4]))
            
            // Color the first scale orange
            ScaleConfiguration.colorLabels(orange, for: .first(1))
            
            // Color the last 2 scales purple
            ScaleConfiguration.colorLabels(purple, for: .last(2))
        }
        .build()
}

// MARK: - Preview/Test Helpers

/// Prints a summary of a configuration for debugging
func printConfigurationSummary(_ config: SlideRuleConfiguration, label: String) {
    print("\n=== \(label) ===")
    print("Display Settings:")
    print("  - Show Names: \(config.displaySettings.showScaleNames)")
    print("  - Show Formulas: \(config.displaySettings.showFormulas)")
    print("  - Default Name Margin: \(config.displaySettings.defaultScaleNameMargin)")
    print("  - Default Formula Margin: \(config.displaySettings.defaultFormulaMargin)")
    print("Component Configs: \(config.componentConfigs.count)")
    print("Rule Annotations: \(config.ruleAnnotations.count)")
    print("Scale Name Overrides: \(config.scaleNameOverrides.count)")
    for (key, name) in config.scaleNameOverrides {
        print("  - \(key) → \"\(name)\"")
    }
}

// MARK: - Running All Examples

/// Demonstrates all configuration examples
func runAllConfigurationExamples() {
    print("Scale Configuration API Examples")
    print("================================\n")
    
    // Example 1
    let config1 = example1_denseStatorAlternatingNames()
    printConfigurationSummary(config1, label: "Example 1: Dense Stator")
    
    // Example 2
    let config2 = example2_coloredScales()
    printConfigurationSummary(config2, label: "Example 2: Colored Scales")
    
    // Example 3
    let config3 = example3_customComponentConfiguration()
    printConfigurationSummary(config3, label: "Example 3: Custom Component")
    
    // Example 4
    let config4 = example4_scaleNameOverrides()
    printConfigurationSummary(config4, label: "Example 4: Name Overrides")
    
    // Example 5
    let config5 = example5_complexMultiComponent()
    printConfigurationSummary(config5, label: "Example 5: Complex Multi-Component")
    
    // Example 6
    let config6 = example6_pickettN16ESAPIDemo()
    printConfigurationSummary(config6, label: "Example 6: Pickett N-16 ES API Demo")
    
    // Example 7 - prints its own output
    print("\n=== Example 7: Using Resolver ===")
    example7_usingResolverDirectly()
    
    // Example 8
    let config8 = example8_patternBasedConfiguration()
    printConfigurationSummary(config8, label: "Example 8: Pattern-Based")
    
    // Example 9
    let config9 = example9_formulasOnly()
    printConfigurationSummary(config9, label: "Example 9: Formulas Only")
    
    // Example 10
    let config10 = example10_minimalClean()
    printConfigurationSummary(config10, label: "Example 10: Minimal Clean")
    
    // Example 11
    let config11 = example11_splitScaleConfiguration()
    printConfigurationSummary(config11, label: "Example 11: Split Scale")
    
    // Example 12
    let config12 = example12_indexBasedSelection()
    printConfigurationSummary(config12, label: "Example 12: Index-Based Selection")
    
    print("\n✅ All examples completed!")
}
