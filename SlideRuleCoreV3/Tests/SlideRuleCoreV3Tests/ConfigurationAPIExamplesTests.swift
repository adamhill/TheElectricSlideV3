// ConfigurationAPIExamplesTests.swift
// SlideRuleCoreV3Tests
//
// Tests that verify all Configuration API examples from the documentation
// work correctly. These tests serve as living documentation.

import Testing
@testable import SlideRuleCoreV3

// MARK: - Configuration API Examples Test Suite

@Suite("Configuration API Examples", .tags(.examples))
struct ConfigurationAPIExamplesTests {
    
    // MARK: - Example 1: Dense Stator with Alternating Names
    
    @Test("Example 1: Dense stator with alternating names suppresses even indices")
    func example1_denseStatorAlternatingNames() throws {
        // GIVEN: A configuration that hides names on even-indexed scales
        let config = SlideRuleConfiguration.build { builder in
            builder
                .configure(.frontTopStator) {
                    ScaleConfiguration.hideNames(for: .evenIndices)
                }
        }
        
        // WHEN: We get the resolver for the front top stator
        let resolver = config.resolver(for: .front, component: .topStator)
        
        // THEN: Even indices should have names hidden
        let display0 = resolver.resolve(scaleName: "LL3", at: 0, totalCount: 5)
        let display1 = resolver.resolve(scaleName: "LL2", at: 1, totalCount: 5)
        let display2 = resolver.resolve(scaleName: "LL1", at: 2, totalCount: 5)
        
        #expect(display0.nameMargin == MarginSide.none, "Index 0 (even) should be hidden")
        #expect(display1.nameMargin != MarginSide.none, "Index 1 (odd) should be shown")
        #expect(display2.nameMargin == MarginSide.none, "Index 2 (even) should be hidden")
    }
    
    // MARK: - Example 2: Colored Inverted and Log-Log Scales
    
    @Test("Example 2: Colored scales applies red to inverted, blue to log-log")
    func example2_coloredScales() throws {
        // GIVEN: A configuration with colored scale labels for a specific component
        // Note: When combining colors, configure them together in one component block
        let config = SlideRuleConfiguration.build { builder in
            builder
                .configure(.frontSlide) {
                    // CI, DI in red (inverted scales)
                    ScaleConfiguration.colorLabels(.red, for: .matching(pattern: "^[CD]I[F]?$"))
                    // LL scales in blue
                    ScaleConfiguration.colorLabels(.blue, for: .matching(pattern: "^LL[0-3]$"))
                }
        }
        
        // WHEN: We resolve display for various scales
        let resolver = config.resolver(for: .front, component: .slide)
        
        let ciDisplay = resolver.resolve(scaleName: "CI", at: 0, totalCount: 5)
        let ll2Display = resolver.resolve(scaleName: "LL2", at: 1, totalCount: 5)
        let cDisplay = resolver.resolve(scaleName: "C", at: 2, totalCount: 5)
        
        // THEN: Colors should be applied correctly
        #expect(ciDisplay.labelColor == LabelColor.red, "CI should be red")
        #expect(ll2Display.labelColor == LabelColor.blue, "LL2 should be blue")
        #expect(cDisplay.labelColor == nil, "C should have no color override")
    }
    
    // MARK: - Example 3: Custom Component Configuration
    
    @Test("Example 3: Custom component configuration applies multiple rules")
    func example3_customComponentConfiguration() throws {
        // GIVEN: A configuration with custom settings for the slide
        let config = SlideRuleConfiguration.build { builder in
            builder
                .configure(.frontSlide) {
                    // Hide names on first 2 scales
                    ScaleConfiguration.hideNames(for: .first(2))
                    
                    // Color the CI scale name red
                    ScaleConfiguration.colorLabels(.red, for: .scale(.ci))
                    
                    // Nudge the C scale name slightly right
                    ScaleConfiguration.nudgeName(.right(3), for: .scale(.c))
                }
        }
        
        // WHEN: We resolve display for the slide
        let resolver = config.resolver(for: .front, component: .slide)
        
        let scale0 = resolver.resolve(scaleName: "CF", at: 0, totalCount: 5)
        let scale1 = resolver.resolve(scaleName: "L", at: 1, totalCount: 5)
        let scale2_CI = resolver.resolve(scaleName: "CI", at: 2, totalCount: 5)
        let scale3_C = resolver.resolve(scaleName: "C", at: 3, totalCount: 5)
        
        // THEN: Rules should be applied
        #expect(scale0.nameMargin == MarginSide.none, "First scale should be hidden")
        #expect(scale1.nameMargin == MarginSide.none, "Second scale should be hidden")
        #expect(scale2_CI.labelColor == LabelColor.red, "CI should be red")
        #expect(scale3_C.nameNudge == PositionNudge.right(3), "C should be nudged right 3")
    }
    
    // MARK: - Example 4: Scale Display Names (now via ScaleBuilder)
    // Note: Scale name customization is now done via displayName in scale factories
    // See PickettN16ESScalesExtension.swift for examples
    
    // MARK: - Example 5: Complex Multi-Component Configuration
    
    @Test("Example 5: Complex multi-component applies different rules per component")
    func example5_complexMultiComponent() throws {
        // GIVEN: A comprehensive configuration
        let config = SlideRuleConfiguration.build { builder in
            builder
                // Global: hide all formulas
                .hideFormulas()
                
                // Front top stator: suppress alternate names
                .configure(.frontTopStator) {
                    ScaleConfiguration.hideNames(for: .evenIndices)
                }
                
                // Front slide: color inverted scales
                .configure(.frontSlide) {
                    ScaleConfiguration.colorLabels(.red, for: .scale(.ci))
                }
        }
        
        // THEN: Global settings should apply
        #expect(!config.displaySettings.showFormulas, "Formulas should be hidden globally")
        #expect(config.displaySettings.showScaleNames, "Names should still be shown")
        
        // AND: Front top stator should have even names suppressed
        let topStatorResolver = config.resolver(for: .front, component: .topStator)
        let topScale0 = topStatorResolver.resolve(scaleName: "SH1", at: 0, totalCount: 4)
        let topScale1 = topStatorResolver.resolve(scaleName: "SH2", at: 1, totalCount: 4)
        #expect(topScale0.nameMargin == MarginSide.none, "Even index on top stator should be hidden")
        #expect(topScale1.nameMargin != MarginSide.none, "Odd index on top stator should be shown")
        
        // AND: Slide should have CI colored
        let slideResolver = config.resolver(for: .front, component: .slide)
        let ciOnSlide = slideResolver.resolve(scaleName: "CI", at: 0, totalCount: 5)
        #expect(ciOnSlide.labelColor == LabelColor.red, "CI on slide should be red")
    }
    
    // MARK: - Example 6: Pickett N-16 ES Annotation Test Configuration
    
    @Test("Example 6: Pickett N-16 ES Annotation Test has complete configuration")
    func example6_pickettN16ESAnnotationTest() throws {
        // GIVEN: The legend annotation for the back slide
        let legendAnnotation = ComponentAnnotation(
            content: .text("F = cycles per. sec.\nλ = meters × 10⁶"),
            color: LabelColor.black,
            horizontalPosition: 0.99,
            verticalPosition: 0.5,
            anchor: .trailing,
            fontSize: 8,
            fontWeight: .medium,
            textAlignment: .leading
        )
        
        // AND: A nudge demo annotation
        let nudgeDemoAnnotation = ComponentAnnotation(
            content: .text("← Nudged 10pt left"),
            color: LabelColor(red: 0, green: 0.5, blue: 0, alpha: 1),
            horizontalPosition: 0.5,
            verticalPosition: 0.0,
            anchor: .top,
            fontSize: 13,
            fontWeight: .medium,
            textAlignment: .center,
            nudge: PositionNudge.left(10)
        )
        
        // WHEN: We build the configuration
        let config = SlideRuleConfiguration.build { builder in
            builder
                .hideFormulas()
                .suppressEvenScaleNames()
                .addAnnotation(legendAnnotation, on: .back)
                .addAnnotation(nudgeDemoAnnotation, on: .back)
        }
        
        // THEN: Display settings should be correct
        #expect(!config.displaySettings.showFormulas, "Formulas should be hidden")
        
        // AND: Annotations should be stored
        let backAnnotations = config.ruleAnnotations[.back] ?? []
        #expect(backAnnotations.count == 2, "Should have 2 annotations on back")
        
        // AND: Even indices should be suppressed
        let resolver = config.resolver(for: .front, component: .topStator)
        let scale0 = resolver.resolve(scaleName: "Test", at: 0, totalCount: 4)
        let scale1 = resolver.resolve(scaleName: "Test", at: 1, totalCount: 4)
        #expect(scale0.nameMargin == MarginSide.none, "Even index should be hidden")
        #expect(scale1.nameMargin != MarginSide.none, "Odd index should be shown")
    }
    
    // MARK: - Example 7: Using the Resolver Directly
    
    @Test("Example 7: Resolver correctly resolves complex configurations")
    func example7_usingResolverDirectly() throws {
        // GIVEN: A configuration with multiple rules combined in a single component block
        // Note: When combining multiple rules for resolution, put them in one configure() block
        let config = SlideRuleConfiguration.build { builder in
            builder
                .configure(.frontTopStator) {
                    // LL scales in blue
                    ScaleConfiguration.colorLabels(.blue, for: .matching(pattern: "^LL[0-3]$"))
                    // Hide odd-indexed names
                    ScaleConfiguration.hideNames(for: .oddIndices)
                }
        }
        
        // WHEN: We get the resolver and resolve each scale
        let resolver = config.resolver(for: .front, component: .topStator)
        
        let scales = [
            ("LL3", 0), ("LL2", 1), ("LL1", 2), ("D", 3), ("L", 4)
        ]
        let totalScales = scales.count
        
        // THEN: Odd indices should be hidden, LL scales should be blue
        for (scaleName, index) in scales {
            let display = resolver.resolve(
                scaleName: scaleName,
                at: index,
                totalCount: totalScales
            )
            
            let isOdd = index % 2 == 1
            let isLogLog = scaleName.hasPrefix("LL")
            
            if isOdd {
                #expect(display.nameMargin == MarginSide.none, "\(scaleName) at odd index \(index) should be hidden")
            } else {
                #expect(display.nameMargin != MarginSide.none, "\(scaleName) at even index \(index) should be shown")
            }
            
            if isLogLog {
                #expect(display.labelColor == LabelColor.blue, "\(scaleName) should be blue")
            }
        }
    }
    
    // MARK: - Example 8: Pattern-Based Configuration
    
    @Test("Example 8: Pattern-based configuration matches scale names by regex")
    func example8_patternBasedConfiguration() throws {
        // GIVEN: A configuration with pattern matching
        let config = SlideRuleConfiguration.build { builder in
            builder
                .configure(.frontTopStator) {
                    ScaleConfiguration.colorLabels(.blue, for: .matching(pattern: "^LL[0-9]+$"))
                }
        }
        
        // WHEN: We resolve display for various scales
        let resolver = config.resolver(for: .front, component: .topStator)
        
        let ll0 = resolver.resolve(scaleName: "LL0", at: 0, totalCount: 5)
        let ll1 = resolver.resolve(scaleName: "LL1", at: 1, totalCount: 5)
        let ll02 = resolver.resolve(scaleName: "LL02", at: 2, totalCount: 5)
        let d = resolver.resolve(scaleName: "D", at: 3, totalCount: 5)
        
        // THEN: LL scales should be blue, others should not
        #expect(ll0.labelColor == LabelColor.blue, "LL0 should match pattern")
        #expect(ll1.labelColor == LabelColor.blue, "LL1 should match pattern")
        #expect(ll02.labelColor == LabelColor.blue, "LL02 should match pattern")
        #expect(d.labelColor == nil, "D should not match pattern")
    }
    
    // MARK: - Example 9: Formulas-Only Configuration
    
    @Test("Example 9: Formulas-only configuration hides names but shows formulas")
    func example9_formulasOnly() throws {
        // GIVEN: A configuration showing only formulas
        let config = SlideRuleConfiguration.build { builder in
            builder
                .hideScaleNames()
        }
        
        // THEN: Names hidden, formulas shown
        #expect(!config.displaySettings.showScaleNames, "Names should be hidden")
        #expect(config.displaySettings.showFormulas, "Formulas should be shown")
    }
    
    // MARK: - Example 10: Minimal Clean Display
    
    @Test("Example 10: Minimal clean display hides all labels")
    func example10_minimalClean() throws {
        // GIVEN: A minimal configuration
        let config = SlideRuleConfiguration.build { builder in
            builder
                .hideAllLabels()
        }
        
        // THEN: Both names and formulas hidden
        #expect(!config.displaySettings.showScaleNames, "Names should be hidden")
        #expect(!config.displaySettings.showFormulas, "Formulas should be hidden")
    }
    
    // MARK: - Example 11: Split Scale Configuration
    
    @Test("Example 11: Split scale configuration targets left/right segments")
    func example11_splitScaleConfiguration() throws {
        // GIVEN: A configuration for split scales
        let config = SlideRuleConfiguration.build { builder in
            builder
                .configure(.frontTopStator) {
                    // Left segment - hide name
                    ScaleConfiguration.hideNames(for: .leftSegment(of: .sq1))
                    
                    // Right segment - color it (custom orange)
                    ScaleConfiguration.colorLabels(
                        LabelColor(red: 1.0, green: 0.5, blue: 0.0),
                        for: .rightSegment(of: .sq1)
                    )
                }
        }
        
        // THEN: Component configs should exist
        #expect(config.componentConfigs.count >= 1)
        
        // AND: Should have scale configs for both segments
        guard let componentConfig = config.configuration(for: RuleSideSelector.front, component: ComponentType.topStator) else {
            Issue.record("Expected component config for front top stator")
            return
        }
        #expect(componentConfig.scaleConfigs.count >= 2, "Should have configs for both segments")
    }
    
    // MARK: - Example 12: Index-Based Selection
    
    @Test("Example 12: Index-based selection targets specific positions")
    func example12_indexBasedSelection() throws {
        // GIVEN: A configuration using indices
        let config = SlideRuleConfiguration.build { builder in
            builder
                .configure(
                    .frontTopStator,
                    scaleConfigs: [
                        // Hide names for scales at indices 0, 2, and 4
                        ScaleConfiguration.hideNames(for: .indices([0, 2, 4])),
                        
                        // Color the first scale
                        ScaleConfiguration.colorLabels(.red, for: .first(1)),
                        
                        // Color the last 2 scales
                        ScaleConfiguration.colorLabels(.blue, for: .last(2))
                    ],
                    annotations: []
                )
        }
        
        // WHEN: We resolve display
        let resolver = config.resolver(for: .front, component: .topStator)
        let totalScales = 6
        
        // THEN: Specific indices should be hidden
        let scale0 = resolver.resolve(scaleName: "A", at: 0, totalCount: totalScales)
        let scale1 = resolver.resolve(scaleName: "B", at: 1, totalCount: totalScales)
        let scale2 = resolver.resolve(scaleName: "C", at: 2, totalCount: totalScales)
        let scale4 = resolver.resolve(scaleName: "E", at: 4, totalCount: totalScales)
        let scale5 = resolver.resolve(scaleName: "F", at: 5, totalCount: totalScales)
        
        #expect(scale0.nameMargin == MarginSide.none, "Index 0 should be hidden")
        #expect(scale1.nameMargin != MarginSide.none, "Index 1 should be shown")
        #expect(scale2.nameMargin == MarginSide.none, "Index 2 should be hidden")
        #expect(scale4.nameMargin == MarginSide.none, "Index 4 should be hidden")
        
        // AND: First scale should be red
        #expect(scale0.labelColor == LabelColor.red, "First scale should be red")
        
        // AND: Last 2 scales should be blue
        #expect(scale4.labelColor == LabelColor.blue, "Second-to-last should be blue")
        #expect(scale5.labelColor == LabelColor.blue, "Last should be blue")
    }
}

// MARK: - Tags

extension Tag {
    @Tag static var examples: Self
}
