// ConfigurationAPIExamples.swift
// SlideRuleCoreV3
//
// Demonstrates the Scale Configuration API using the Pickett N-16 ES Annotation Test
// as a reference. These examples show all configuration patterns documented in
// swift-docs/scale-configuration-api-reference.md

import Foundation

// MARK: - Example 1: Dense Stator with Alternating Names
// When a stator has many scales, suppress every other name for readability

/// Creates a configuration that hides names on even-indexed scales for the front top stator
func example1_denseStatorAlternatingNames() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .suppressEvenScaleNames(
                for: .specific(side: .front, component: .topStator)
            )
    }
}

// MARK: - Example 2: Colored Inverted and Log-Log Scales
// Make inverted scales red and Log-Log scales blue for visual distinction

/// Creates a configuration with colored scale labels
func example2_coloredScales() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .colorInvertedScales(.red)    // CI, DI, CIF, DIF in red
            .colorLogLogScales(.blue)     // LL0, LL1, LL2, LL3, etc. in blue
    }
}

// MARK: - Example 3: Custom Component Configuration
// Fine-grained control over a specific component

/// Creates a configuration with custom settings for the slide
func example3_customComponentConfiguration() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .configure(.specific(side: .front, component: .slide)) {
                // Hide names on first 2 scales
                ScaleConfiguration.hideNames(for: .first(2))
                
                // Color the CI scale name red
                ScaleConfiguration.colorLabels(for: .scale(.ci), nameColor: .red)
                
                // Nudge the C scale name slightly right
                ScaleConfiguration.nudgeName(for: .scale(.c), nudge: .right(3))
            }
    }
}

// MARK: - Example 4: Scale Name Overrides
// Display custom names instead of standard abbreviations

/// Creates a configuration with custom display names
func example4_scaleNameOverrides() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .addNameOverrides([
                .ci: "1/x",      // CI → "1/x"
                .a: "x²",        // A → "x²"
                .k: "x³"         // K → "x³"
            ])
    }
}

// MARK: - Example 5: Complex Multi-Component Configuration
// Different settings for different parts of the rule

/// Creates a comprehensive configuration like the Pickett N-16 ES Annotation Test
func example5_complexMultiComponent() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            // Global: hide all formulas
            .hideFormulas()
            
            // Front top stator: suppress alternate names (dense 4-scale layout)
            .configure(.specific(side: .front, component: .topStator)) {
                ScaleConfiguration.hideNames(for: .evenIndices)
            }
            
            // All slides on both sides: color inverted scales
            .configure(.allSlides(side: .both)) {
                ScaleConfiguration.colorLabels(for: .scale(.ci), nameColor: .red)
                ScaleConfiguration.colorLabels(for: .scale(.cif), nameColor: .red)
            }
            
            // Back side: custom naming for electrical engineering scales
            .addNameOverride(key: .named("DQ"), name: "D/Q")
            .addNameOverride(key: .named("L"), name: "C/L")
            .addNameOverride(key: .named("Cos"), name: "cos")
    }
}

// MARK: - Example 6: Pickett N-16 ES Annotation Test Configuration
// This is the full configuration that matches the current Annotation Test rule

/// Complete configuration for the Pickett N-16 ES Annotation Test rule
/// Demonstrates:
/// - Rule-level display settings (formulas disabled)
/// - Even-indexed scale names suppressed on all components
/// - Custom scale name overrides for electrical engineering scales
/// - Component annotations (legend text block)
func example6_pickettN16ESAnnotationTest() -> SlideRuleConfiguration {
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
    
    return SlideRuleConfiguration.build { builder in
        builder
            // Rule-level: hide all formulas
            .hideFormulas()
            
            // Suppress even-indexed scale names globally (0, 2, 4, ...)
            .suppressEvenScaleNames(for: .global)
            
            // Custom scale name overrides for Pickett N-16 ES electrical scales
            .addNameOverrides([
                .named("DQ"): "D/Q",
                .named("L"): "C/L",
                .named("Cos"): "cos",
                .named("CosΘ"): "cos Θ",
                .named("Θ"): "θ",
                .named("λ"): "λ",
                .named("ω"): "ω",
                .named("τ"): "τ",
                .named("PF"): "F"
            ])
            
            // Add annotations to the rule
            .addAnnotation(legendAnnotation)
            .addAnnotation(nudgeDemoAnnotation)
    }
}

// MARK: - Example 7: Using the Resolver Directly
// For rendering code that needs to query resolved settings

/// Demonstrates how to use ScaleConfigurationResolver in rendering code
func example7_usingResolverDirectly() {
    // Build a configuration
    let config = SlideRuleConfiguration.build { builder in
        builder
            .colorLogLogScales(.blue)
            .suppressOddScaleNames(for: .specific(side: .front, component: .topStator))
    }
    
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
        if display.showName {
            let nameToShow = display.customName ?? scaleName
            let color = display.nameColor ?? .defaultLabel
            // In real code: render nameToShow with color
            print("Scale \(scaleName): show name '\(nameToShow)' with color \(color)")
        } else {
            print("Scale \(scaleName): name hidden")
        }
    }
}

// MARK: - Example 8: Pattern-Based Configuration
// Using regex patterns to configure groups of scales

/// Configures all scales matching a pattern
func example8_patternBasedConfiguration() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            // Configure all Log-Log scales (LL0, LL1, LL2, LL3, LL00, LL01, etc.)
            .configure(.global) {
                ScaleConfiguration.colorLabels(
                    for: .matching(pattern: "LL[0-9]+"),
                    nameColor: .blue
                )
            }
            
            // Configure all trig scales
            .configure(.global) {
                ScaleConfiguration.colorLabels(
                    for: .matching(pattern: "(S|ST|T|T1|T2|Cos)"),
                    nameColor: .green
                )
            }
    }
}

// MARK: - Example 9: Formulas-Only Configuration
// Show formulas but hide scale names

/// Creates a configuration showing only formulas
func example9_formulasOnly() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .hideScaleNames()  // Hide names
            // Formulas shown by default
    }
}

// MARK: - Example 10: Minimal Clean Display
// Hide all labels for a clean appearance

/// Creates a minimal configuration with no labels
func example10_minimalClean() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .hideAllLabels()  // Hide both names and formulas
    }
}

// MARK: - Example 11: Split Scale Configuration
// Configure left and right segments of split scales separately

/// Configures split scales with different settings per segment
func example11_splitScaleConfiguration() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .configure(.global) {
                // Left segment of SQ1 - hide name (it's labeled on right)
                ScaleConfiguration.hideNames(for: .leftSegment(.sq1))
                
                // Right segment of SQ1 - show name, color it
                ScaleConfiguration.colorLabels(
                    for: .rightSegment(.sq1),
                    nameColor: .orange
                )
            }
    }
}

// MARK: - Example 12: Index-Based Selection
// Configure specific scales by their position index

/// Configures scales at specific indices
func example12_indexBasedSelection() -> SlideRuleConfiguration {
    SlideRuleConfiguration.build { builder in
        builder
            .configure(.specific(side: .front, component: .topStator)) {
                // Hide names for scales at indices 0, 2, and 4
                ScaleConfiguration.hideNames(for: .indices([0, 2, 4]))
                
                // Color the first scale
                ScaleConfiguration.colorLabels(for: .first(1), nameColor: .red)
                
                // Color the last 2 scales
                ScaleConfiguration.colorLabels(for: .last(2), nameColor: .blue)
            }
    }
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
        print("  - \(key.canonicalName) → \"\(name)\"")
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
    let config6 = example6_pickettN16ESAnnotationTest()
    printConfigurationSummary(config6, label: "Example 6: Pickett N-16 ES Annotation Test")
    
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
