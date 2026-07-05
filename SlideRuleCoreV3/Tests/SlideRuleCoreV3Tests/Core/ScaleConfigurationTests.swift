//
//  ScaleConfigurationTests.swift
//  SlideRuleCoreV3Tests
//
//  Tests for the fluent configuration API types
//

import Foundation
import Testing
@testable import SlideRuleCoreV3

// MARK: - ScaleKey Tests

@Suite("ScaleKey Matching")
struct ScaleKeyMatchingTests {
    
    @Test("Type-safe keys match their canonical names")
    func typeSafeKeyMatching() {
        #expect(ScaleKey.c.matches("C"))
        #expect(ScaleKey.c.matches("c"))  // Case insensitive
        #expect(ScaleKey.ll1.matches("LL1"))
        #expect(ScaleKey.theta1.matches("Θ₁"))
    }
    
    @Test("Named keys match exactly")
    func namedKeyMatching() {
        let key = ScaleKey.named("PF")
        #expect(key.matches("PF"))
        #expect(key.matches("pf"))  // Case insensitive
        #expect(!key.matches("PF1"))
    }
    
    @Test("Pattern keys use regex matching")
    func patternKeyMatching() {
        // Note: Regex matches substrings, use ^...$ anchors for exact matching
        let llPattern = ScaleKey.matching(pattern: "^LL[0-3]$")
        #expect(llPattern.matches("LL0"))
        #expect(llPattern.matches("LL1"))
        #expect(llPattern.matches("LL2"))
        #expect(llPattern.matches("LL3"))
        #expect(!llPattern.matches("LL4"))
        #expect(!llPattern.matches("LL00"))
        
        let thetaPattern = ScaleKey.matching(pattern: "Θ[₁₂]")
        #expect(thetaPattern.matches("Θ₁"))
        #expect(thetaPattern.matches("Θ₂"))
    }
    
    @Test("Canonical names are correct")
    func canonicalNames() {
        #expect(ScaleKey.c.canonicalName == "C")
        #expect(ScaleKey.ll01.canonicalName == "LL01")
        #expect(ScaleKey.theta1.canonicalName == "Θ₁")
        #expect(ScaleKey.named("custom").canonicalName == "custom")
        #expect(ScaleKey.matching(pattern: ".*").canonicalName == nil)
    }
}

@Suite("ScaleKey Codable")
struct ScaleKeyCodableTests {
    
    @Test("Type-safe configuration keys preserve values when saved and restored")
    func typeSafeRoundTrip() throws {
        let keys: [ScaleKey] = [.c, .d, .ll1, .theta2, .st]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for key in keys {
            let data = try encoder.encode(key)
            let decoded = try decoder.decode(ScaleKey.self, from: data)
            #expect(decoded == key)
        }
    }
    
    @Test("Named configuration keys preserve values when saved and restored")
    func namedRoundTrip() throws {
        let key = ScaleKey.named("CustomScale")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(key)
        let decoded = try decoder.decode(ScaleKey.self, from: data)
        #expect(decoded == key)
    }
    
    @Test("Pattern configuration keys preserve values when saved and restored")
    func patternRoundTrip() throws {
        let key = ScaleKey.matching(pattern: "LL[0-3]")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(key)
        let decoded = try decoder.decode(ScaleKey.self, from: data)
        #expect(decoded == key)
    }
}

// MARK: - PositionNudge Tests

@Suite("PositionNudge")
struct PositionNudgeTests {
    
    @Test("Zero nudge has no offset")
    func zeroNudge() {
        let nudge = PositionNudge.zero
        #expect(nudge.horizontalOffset == 0)
        #expect(nudge.verticalOffset == 0)
    }
    
    @Test("Directional nudges compute correct offsets")
    func directionalNudges() {
        #expect(PositionNudge.up(10).verticalOffset == -10)
        #expect(PositionNudge.down(10).verticalOffset == 10)
        #expect(PositionNudge.left(10).horizontalOffset == -10)
        #expect(PositionNudge.right(10).horizontalOffset == 10)
    }
    
    @Test("Combined nudges add correctly")
    func combinedNudges() {
        let nudge1 = PositionNudge.up(5)
        let nudge2 = PositionNudge.right(10)
        let combined = nudge1.combined(with: nudge2)
        
        #expect(combined.verticalOffset == -5)
        #expect(combined.horizontalOffset == 10)
    }
    
    @Test("Opposing nudges cancel out")
    func opposingNudges() {
        let nudge = PositionNudge(up: 10, down: 10, left: 5, right: 5)
        #expect(nudge.verticalOffset == 0)
        #expect(nudge.horizontalOffset == 0)
    }
}

// MARK: - ScaleSelector Tests

@Suite("ScaleSelector Matching")
struct ScaleSelectorMatchingTests {
    
    @Test("Even indices selector matches correctly")
    func evenIndices() {
        let selector = ScaleSelector.evenIndices
        #expect(selector.matches(scaleName: "C", at: 0, totalCount: 5))
        #expect(!selector.matches(scaleName: "D", at: 1, totalCount: 5))
        #expect(selector.matches(scaleName: "A", at: 2, totalCount: 5))
        #expect(!selector.matches(scaleName: "B", at: 3, totalCount: 5))
        #expect(selector.matches(scaleName: "K", at: 4, totalCount: 5))
    }
    
    @Test("Odd indices selector matches correctly")
    func oddIndices() {
        let selector = ScaleSelector.oddIndices
        #expect(!selector.matches(scaleName: "C", at: 0, totalCount: 5))
        #expect(selector.matches(scaleName: "D", at: 1, totalCount: 5))
        #expect(!selector.matches(scaleName: "A", at: 2, totalCount: 5))
        #expect(selector.matches(scaleName: "B", at: 3, totalCount: 5))
    }
    
    @Test("First N selector matches correctly")
    func firstN() {
        let selector = ScaleSelector.first(2)
        #expect(selector.matches(scaleName: "C", at: 0, totalCount: 5))
        #expect(selector.matches(scaleName: "D", at: 1, totalCount: 5))
        #expect(!selector.matches(scaleName: "A", at: 2, totalCount: 5))
    }
    
    @Test("Last N selector matches correctly")
    func lastN() {
        let selector = ScaleSelector.last(2)
        #expect(!selector.matches(scaleName: "C", at: 0, totalCount: 5))
        #expect(!selector.matches(scaleName: "D", at: 1, totalCount: 5))
        #expect(!selector.matches(scaleName: "A", at: 2, totalCount: 5))
        #expect(selector.matches(scaleName: "B", at: 3, totalCount: 5))
        #expect(selector.matches(scaleName: "K", at: 4, totalCount: 5))
    }
    
    @Test("Specific indices selector matches correctly")
    func specificIndices() {
        let selector = ScaleSelector.indices([1, 3])
        #expect(!selector.matches(scaleName: "C", at: 0, totalCount: 5))
        #expect(selector.matches(scaleName: "D", at: 1, totalCount: 5))
        #expect(!selector.matches(scaleName: "A", at: 2, totalCount: 5))
        #expect(selector.matches(scaleName: "B", at: 3, totalCount: 5))
        #expect(!selector.matches(scaleName: "K", at: 4, totalCount: 5))
    }
    
    @Test("Pattern selector uses regex matching")
    func patternMatching() {
        // Note: Regex matches substrings, use ^...$ anchors for exact matching
        let selector = ScaleSelector.matching(pattern: "^LL[0-3]$")
        #expect(selector.matches(scaleName: "LL0", at: 0, totalCount: 4))
        #expect(selector.matches(scaleName: "LL1", at: 1, totalCount: 4))
        #expect(!selector.matches(scaleName: "LL00", at: 0, totalCount: 4))
    }
    
    @Test("Scale key selector matches by name")
    func scaleKeyMatching() {
        let selector = ScaleSelector.scale(.c)
        #expect(selector.matches(scaleName: "C", at: 5, totalCount: 10))
        #expect(!selector.matches(scaleName: "D", at: 0, totalCount: 10))
    }
    
    @Test("All selector matches everything")
    func allMatching() {
        let selector = ScaleSelector.all
        #expect(selector.matches(scaleName: "anything", at: 0, totalCount: 1))
        #expect(selector.matches(scaleName: "C", at: 99, totalCount: 100))
    }
    
    @Test("Split segment selectors respect segment flags")
    func splitSegmentMatching() {
        let leftSelector = ScaleSelector.leftSegment(of: .theta1)
        let rightSelector = ScaleSelector.rightSegment(of: .theta1)
        
        // Left segment matches when isLeftSegment is true
        #expect(leftSelector.matches(scaleName: "Θ₁", at: 0, totalCount: 1, isLeftSegment: true))
        #expect(!leftSelector.matches(scaleName: "Θ₁", at: 0, totalCount: 1, isRightSegment: true))
        
        // Right segment matches when isRightSegment is true
        #expect(rightSelector.matches(scaleName: "Θ₁", at: 0, totalCount: 1, isRightSegment: true))
        #expect(!rightSelector.matches(scaleName: "Θ₁", at: 0, totalCount: 1, isLeftSegment: true))
        
        // Neither matches wrong scale name
        #expect(!leftSelector.matches(scaleName: "Θ₂", at: 0, totalCount: 1, isLeftSegment: true))
    }
}

// MARK: - ScaleConfiguration Tests

@Suite("ScaleConfiguration")
struct ScaleConfigurationTests {
    
    @Test("Factory methods create correct configurations")
    func factoryMethods() {
        let hideNames = ScaleConfiguration.hideNames(for: .evenIndices)
        #expect(hideNames.nameMargin == MarginSide.none)
        #expect(hideNames.formulaMargin == nil)
        
        let hideFormulas = ScaleConfiguration.hideFormulas(for: .all)
        #expect(hideFormulas.nameMargin == nil)
        #expect(hideFormulas.formulaMargin == MarginSide.none)
        
        let hideLabels = ScaleConfiguration.hideLabels(for: .oddIndices)
        #expect(hideLabels.nameMargin == MarginSide.none)
        #expect(hideLabels.formulaMargin == MarginSide.none)
        
        let colorRed = ScaleConfiguration.colorLabels(.red, for: .scale(.ll1))
        #expect(colorRed.labelColor == .red)
    }
    
    @Test("Priority is preserved")
    func priorityPreserved() {
        let lowPriority = ScaleConfiguration.hideNames(for: .all, priority: 1)
        let highPriority = ScaleConfiguration.hideNames(for: .all, priority: 10)
        
        #expect(lowPriority.priority == 1)
        #expect(highPriority.priority == 10)
    }
}

// MARK: - ScaleConfigurationResolver Tests

@Suite("ScaleConfigurationResolver")
struct ScaleConfigurationResolverTests {
    
    @Test("Empty configurations return defaults")
    func emptyConfigurations() {
        let resolver = ScaleConfigurationResolver(configurations: [])
        let result = resolver.resolve(scaleName: "C", at: 0, totalCount: 5)
        
        #expect(result.visible == true)
        #expect(result.nameMargin == .left)
        #expect(result.formulaMargin == .right)
    }
    
    @Test("Single matching configuration is applied")
    func singleConfiguration() {
        let config = ScaleConfiguration.hideNames(for: .all)
        let resolver = ScaleConfigurationResolver(configurations: [config])
        
        let result = resolver.resolve(scaleName: "C", at: 0, totalCount: 5)
        #expect(result.nameMargin == MarginSide.none)
        #expect(result.formulaMargin == .right)  // Unchanged
    }
    
    @Test("Non-matching configurations are ignored")
    func nonMatchingIgnored() {
        let config = ScaleConfiguration.hideNames(for: .scale(.ll1))
        let resolver = ScaleConfigurationResolver(configurations: [config])
        
        let result = resolver.resolve(scaleName: "C", at: 0, totalCount: 5)
        #expect(result.nameMargin == .left)  // Default, not hidden
    }
    
    @Test("Higher priority configurations win")
    func priorityResolution() {
        let lowPriority = ScaleConfiguration(
            selector: .all,
            labelColor: .red,
            priority: 1
        )
        let highPriority = ScaleConfiguration(
            selector: .all,
            labelColor: .blue,
            priority: 10
        )
        
        // Add in wrong order to ensure priority sorting works
        let resolver = ScaleConfigurationResolver(configurations: [highPriority, lowPriority])
        let result = resolver.resolve(scaleName: "C", at: 0, totalCount: 5)
        
        #expect(result.labelColor == .blue)
    }
    
    @Test("Multiple configurations merge correctly")
    func configurationMerging() {
        let hideEvenNames = ScaleConfiguration.hideNames(for: .evenIndices, priority: 1)
        let colorLLScales = ScaleConfiguration.colorLabels(.red, for: .matching(pattern: "LL.*"), priority: 2)
        
        let resolver = ScaleConfigurationResolver(configurations: [hideEvenNames, colorLLScales])
        
        // LL1 at even index: name hidden + red color
        let ll1Result = resolver.resolve(scaleName: "LL1", at: 0, totalCount: 4)
        #expect(ll1Result.nameMargin == MarginSide.none)
        #expect(ll1Result.labelColor == .red)
        
        // LL2 at odd index: name shown + red color
        let ll2Result = resolver.resolve(scaleName: "LL2", at: 1, totalCount: 4)
        #expect(ll2Result.nameMargin == .left)
        #expect(ll2Result.labelColor == .red)
        
        // C at even index: name hidden, no color change
        let cResult = resolver.resolve(scaleName: "C", at: 0, totalCount: 4)
        #expect(cResult.nameMargin == MarginSide.none)
        #expect(cResult.labelColor == nil)
    }
    
    @Test("Nudges combine additively")
    func nudgeCombination() {
        let nudgeUp = ScaleConfiguration.nudgeName(.up(5), for: .all, priority: 1)
        let nudgeRight = ScaleConfiguration.nudgeName(.right(10), for: .all, priority: 2)
        
        let resolver = ScaleConfigurationResolver(configurations: [nudgeUp, nudgeRight])
        let result = resolver.resolve(scaleName: "C", at: 0, totalCount: 1)
        
        #expect(result.nameNudge.verticalOffset == -5)
        #expect(result.nameNudge.horizontalOffset == 10)
    }
}

// MARK: - LabelColor Tests

@Suite("LabelColor")
struct LabelColorTests {
    
    @Test("Named colors have correct RGB values")
    func namedColorRGB() {
        #expect(LabelColor.red.red == 1)
        #expect(LabelColor.red.green == 0)
        #expect(LabelColor.red.blue == 0)
        
        #expect(LabelColor.black.red == 0)
        #expect(LabelColor.black.green == 0)
        #expect(LabelColor.black.blue == 0)
    }
    
    @Test("Custom colors preserve RGB values")
    func customColorRGB() {
        let custom = LabelColor(red: 0.2, green: 0.4, blue: 0.8)
        
        #expect(custom.red == 0.2)
        #expect(custom.green == 0.4)
        #expect(custom.blue == 0.8)
    }
    
    @Test("Alpha values are correct")
    func alphaValues() {
        #expect(LabelColor.red.alpha == 1.0)
        #expect(LabelColor(red: 1, green: 0, blue: 0).alpha == 1.0)
        #expect(LabelColor(red: 1, green: 0, blue: 0, alpha: 0.5).alpha == 0.5)
    }
}

// MARK: - AnnotationPosition Tests

@Suite("AnnotationPosition")
struct AnnotationPositionTests {
    
    @Test("Scale positions resolve correctly")
    func normalizedResolution() {
        let pos = AnnotationPosition.normalized(h: 0.25, v: 0.75)
        let resolved = pos.normalized(in: (width: 100, height: 200))
        
        #expect(resolved.h == 0.25)
        #expect(resolved.v == 0.75)
    }
    
    @Test("Edge-relative positions resolve correctly")
    func edgeRelativeResolution() {
        let pos = AnnotationPosition(
            horizontal: .fromLeading(20),
            vertical: .fromTop(30)
        )
        let resolved = pos.normalized(in: (width: 100, height: 200))
        
        #expect(resolved.h == 0.2)
        #expect(resolved.v == 0.15)
    }
    
    @Test("Trailing edge positions resolve correctly")
    func trailingEdgeResolution() {
        let pos = AnnotationPosition(
            horizontal: .fromTrailing(10),
            vertical: .fromBottom(20)
        )
        let resolved = pos.normalized(in: (width: 100, height: 200))
        
        #expect(resolved.h == 0.9)
        #expect(resolved.v == 0.9)
    }
    
    @Test("Center positions resolve to 0.5")
    func centerResolution() {
        let pos = AnnotationPosition.centered
        let resolved = pos.normalized(in: (width: 100, height: 200))
        
        #expect(resolved.h == 0.5)
        #expect(resolved.v == 0.5)
    }
    
    @Test("Convenience factories create correct positions")
    func convenienceFactories() {
        #expect(AnnotationPosition.topLeading.normalized(in: (100, 100)) == (h: 0, v: 0))
        #expect(AnnotationPosition.topTrailing.normalized(in: (100, 100)) == (h: 1, v: 0))
        #expect(AnnotationPosition.bottomLeading.normalized(in: (100, 100)) == (h: 0, v: 1))
        #expect(AnnotationPosition.bottomTrailing.normalized(in: (100, 100)) == (h: 1, v: 1))
    }
}

// MARK: - ComponentConfiguration Tests (Phase 3)

@Suite("ComponentConfiguration")
struct ComponentConfigurationTests {
    
    @Test("Factory methods create correct selectors")
    func factoryMethods() {
        let frontSlide = ComponentConfiguration.frontSlide()
        #expect(frontSlide.selector == .frontSlide)
        #expect(frontSlide.scaleConfigs.isEmpty)
        #expect(frontSlide.annotations.isEmpty)
        
        let backTopStator = ComponentConfiguration.backTopStator(
            scaleConfigs: [ScaleConfiguration.hideNames(for: .all)]
        )
        #expect(backTopStator.selector == .backTopStator)
        #expect(backTopStator.scaleConfigs.count == 1)
    }
    
    @Test("appliesTo correctly matches components")
    func appliesToMatching() {
        let frontSlideConfig = ComponentConfiguration.frontSlide()
        
        #expect(frontSlideConfig.appliesTo(side: .front, component: .slide))
        #expect(!frontSlideConfig.appliesTo(side: .back, component: .slide))
        #expect(!frontSlideConfig.appliesTo(side: .front, component: .topStator))
    }
    
    @Test("Both-side selector matches both sides")
    func bothSideMatching() {
        let bothSlidesConfig = ComponentConfiguration(
            selector: ComponentSelector(side: .both, component: .slide)
        )
        
        #expect(bothSlidesConfig.appliesTo(side: .front, component: .slide))
        #expect(bothSlidesConfig.appliesTo(side: .back, component: .slide))
        #expect(!bothSlidesConfig.appliesTo(side: .front, component: .topStator))
    }
    
    @Test("Resolver uses component's scale configs")
    func resolverFromComponent() {
        let config = ComponentConfiguration.frontSlide(
            scaleConfigs: [ScaleConfiguration.hideNames(for: .evenIndices)]
        )
        
        let resolver = config.resolver()
        
        // Even index - name hidden
        let evenResult = resolver.resolve(scaleName: "C", at: 0, totalCount: 4)
        #expect(evenResult.nameMargin == MarginSide.none)
        
        // Odd index - name shown
        let oddResult = resolver.resolve(scaleName: "D", at: 1, totalCount: 4)
        #expect(oddResult.nameMargin == .left)
    }
}

// MARK: - SlideRuleConfiguration Tests (Phase 4)

@Suite("SlideRuleConfiguration")
struct SlideRuleConfigurationTests {
    
    @Test("Standard configuration has default settings")
    func standardConfig() {
        let config = SlideRuleConfiguration.standard
        
        #expect(config.displaySettings.showScaleNames == true)
        #expect(config.displaySettings.showFormulas == true)
        #expect(config.componentConfigs.isEmpty)
    }
    
    @Test("namesOnly hides formulas")
    func namesOnlyConfig() {
        let config = SlideRuleConfiguration.namesOnly
        
        #expect(config.displaySettings.showScaleNames == true)
        #expect(config.displaySettings.showFormulas == false)
    }
    
    @Test("configuration(for:component:) finds matching config")
    func configurationQuery() {
        var config = SlideRuleConfiguration()
        config.addComponentConfig(ComponentConfiguration.frontSlide(
            scaleConfigs: [ScaleConfiguration.hideNames(for: .all)]
        ))
        config.addComponentConfig(ComponentConfiguration.backSlide(
            scaleConfigs: [ScaleConfiguration.hideFormulas(for: .all)]
        ))
        
        let frontSlideConfig = config.configuration(for: .front, component: .slide)
        #expect(frontSlideConfig != nil)
        #expect(frontSlideConfig?.selector == .frontSlide)
        
        let backSlideConfig = config.configuration(for: .back, component: .slide)
        #expect(backSlideConfig != nil)
        #expect(backSlideConfig?.selector == .backSlide)
        
        let frontTopConfig = config.configuration(for: .front, component: .topStator)
        #expect(frontTopConfig == nil)
    }
    
    // NOTE: Scale name customization now handled via displayName at scale definition time
    // See StandardScales.swift factory functions for examples
    
    @Test("resolver(for:component:) uses display settings")
    func resolverFromConfig() {
        // Config with formulas hidden
        let config = SlideRuleConfiguration.namesOnly
        let resolver = config.resolver(for: .front, component: .slide)
        
        let result = resolver.resolve(scaleName: "C", at: 0, totalCount: 1)
        
        #expect(result.nameMargin == .left)  // Names shown
        #expect(result.formulaMargin == MarginSide.none)  // Formulas hidden
    }
    
    @Test("resolver(for:component:) merges component configs")
    func resolverWithComponentConfig() {
        var config = SlideRuleConfiguration()
        config.addComponentConfig(ComponentConfiguration.frontSlide(
            scaleConfigs: [ScaleConfiguration.hideNames(for: .evenIndices)]
        ))
        
        let resolver = config.resolver(for: .front, component: .slide)
        
        // Even index - name hidden
        let evenResult = resolver.resolve(scaleName: "C", at: 0, totalCount: 4)
        #expect(evenResult.nameMargin == MarginSide.none)
        
        // Odd index - name shown (default)
        let oddResult = resolver.resolve(scaleName: "D", at: 1, totalCount: 4)
        #expect(oddResult.nameMargin == .left)
    }
    
    @Test("fromLegacy creates matching configuration")
    func legacyMigration() {
        let config = SlideRuleConfiguration.fromLegacy(
            showScaleNames: true,
            showFormulas: false,
            suppressEvenScaleNames: true
        )
        
        #expect(config.displaySettings.showScaleNames == true)
        #expect(config.displaySettings.showFormulas == false)
        
        // Should have component configs for even name suppression
        #expect(!config.componentConfigs.isEmpty)
        
        // Check resolver behavior matches legacy
        let resolver = config.resolver(for: .front, component: .slide)
        let evenResult = resolver.resolve(scaleName: "C", at: 0, totalCount: 4)
        #expect(evenResult.nameMargin == MarginSide.none)  // Even names hidden
        #expect(evenResult.formulaMargin == MarginSide.none)  // Formulas hidden globally
    }
    
    @Test("annotations(for:) retrieves correct annotations")
    func annotationQuery() {
        let annotation = ComponentAnnotation(
            content: .text("Test"),
            color: LabelColor.black,
            horizontalPosition: 0.5,
            verticalPosition: 0.5,
            anchor: .center,
            fontSize: 12,
            fontWeight: .medium,
            textAlignment: .center
        )
        
        var config = SlideRuleConfiguration()
        config.addAnnotation(annotation, on: .front)
        
        #expect(config.annotations(for: .front).count == 1)
        #expect(config.annotations(for: .back).isEmpty)
    }
}

// MARK: - SlideRuleConfiguration Codable Tests

@Suite("SlideRuleConfiguration Codable")
struct SlideRuleConfigurationCodableTests {
    
    @Test("Complete configuration preserves all settings when saved and restored")
    func fullRoundTrip() throws {
        var config = SlideRuleConfiguration(
            displaySettings: RuleDisplaySettings(showFormulas: false)
        )
        config.addComponentConfig(ComponentConfiguration.frontSlide(
            scaleConfigs: [ScaleConfiguration.hideNames(for: .evenIndices)]
        ))
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(config)
        let decoded = try decoder.decode(SlideRuleConfiguration.self, from: data)
        
        #expect(decoded.displaySettings.showFormulas == false)
        #expect(decoded.componentConfigs.count == 1)
    }
    
    @Test("Default configuration preserves correctly when saved and restored")
    func emptyRoundTrip() throws {
        let config = SlideRuleConfiguration.standard
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(config)
        let decoded = try decoder.decode(SlideRuleConfiguration.self, from: data)
        
        #expect(decoded.displaySettings.showScaleNames == true)
        #expect(decoded.displaySettings.showFormulas == true)
        #expect(decoded.componentConfigs.isEmpty)
    }
}

// MARK: - Phase 5: Fluent Builder Tests

@Suite("SlideRuleConfigurationBuilder")
struct SlideRuleConfigurationBuilderTests {
    
    @Test("Empty builder creates standard configuration")
    func emptyBuilder() {
        let config = SlideRuleConfigurationBuilder()
            .build()
        
        #expect(config.displaySettings.showScaleNames == true)
        #expect(config.displaySettings.showFormulas == true)
        #expect(config.componentConfigs.isEmpty)
    }
    
    @Test("hideFormulas sets showFormulas to false")
    func hideFormulas() {
        let config = SlideRuleConfigurationBuilder()
            .hideFormulas()
            .build()
        
        #expect(config.displaySettings.showScaleNames == true)
        #expect(config.displaySettings.showFormulas == false)
    }
    
    @Test("hideScaleNames sets showScaleNames to false")
    func hideScaleNames() {
        let config = SlideRuleConfigurationBuilder()
            .hideScaleNames()
            .build()
        
        #expect(config.displaySettings.showScaleNames == false)
        #expect(config.displaySettings.showFormulas == true)
    }
    
    @Test("hideAllLabels hides both names and formulas")
    func hideAllLabels() {
        let config = SlideRuleConfigurationBuilder()
            .hideAllLabels()
            .build()
        
        #expect(config.displaySettings.showScaleNames == false)
        #expect(config.displaySettings.showFormulas == false)
    }
    
    @Test("configure adds component configuration with result builder")
    func configureWithResultBuilder() {
        let config = SlideRuleConfigurationBuilder()
            .configure(.frontSlide) {
                ScaleConfiguration.hideNames(for: .evenIndices)
                ScaleConfiguration.colorLabels(.red, for: .scale(.ll1))
            }
            .build()
        
        #expect(config.componentConfigs.count == 1)
        #expect(config.componentConfigs[0].selector == .frontSlide)
        #expect(config.componentConfigs[0].scaleConfigs.count == 2)
    }
    
    @Test("configure with arrays adds component configuration")
    func configureWithArrays() {
        let config = SlideRuleConfigurationBuilder()
            .configure(
                .backTopStator,
                scaleConfigs: [ScaleConfiguration.hideFormulas(for: .all)],
                annotations: []
            )
            .build()
        
        #expect(config.componentConfigs.count == 1)
        #expect(config.componentConfigs[0].selector == .backTopStator)
    }
    
    @Test("suppressEvenScaleNames adds configs to all components")
    func suppressEvenScaleNames() {
        let config = SlideRuleConfigurationBuilder()
            .suppressEvenScaleNames()
            .build()
        
        // Should have 6 component configs (all front + all back)
        #expect(config.componentConfigs.count == 6)
        
        // Each should have evenIndices selector
        for componentConfig in config.componentConfigs {
            #expect(componentConfig.scaleConfigs.count == 1)
            #expect(componentConfig.scaleConfigs[0].selector == .evenIndices)
        }
    }
    
    @Test("colorLogLogScales adds color configs to all components")
    func colorLogLogScales() {
        let config = SlideRuleConfigurationBuilder()
            .colorLogLogScales(.red)
            .build()
        
        // Should have 6 component configs
        #expect(config.componentConfigs.count == 6)
        
        // Each should have 2 scale configs (LL[0-3] and LL0[0-3])
        for componentConfig in config.componentConfigs {
            #expect(componentConfig.scaleConfigs.count == 2)
            #expect(componentConfig.scaleConfigs[0].labelColor == .red)
            #expect(componentConfig.scaleConfigs[1].labelColor == .red)
        }
    }
    
    @Test("addAnnotation on side adds rule-level annotation")
    func addAnnotationOnSide() {
        let annotation = ComponentAnnotation(
            content: .text("Test"),
            color: LabelColor.black,
            horizontalPosition: 0.5,
            verticalPosition: 0.5,
            anchor: .center,
            fontSize: 12,
            fontWeight: .medium,
            textAlignment: .center
        )
        
        let config = SlideRuleConfigurationBuilder()
            .addAnnotation(annotation, on: .front)
            .build()
        
        #expect(config.ruleAnnotations[.front]?.count == 1)
        #expect(config.ruleAnnotations[.back] == nil)
    }
    
    @Test("addAnnotation on component adds component annotation")
    func addAnnotationOnComponent() {
        let annotation = ComponentAnnotation(
            content: .text("Legend"),
            color: LabelColor.green,
            horizontalPosition: 0.1,
            verticalPosition: 0.9,
            anchor: .bottomLeading,
            fontSize: 10,
            fontWeight: .regular,
            textAlignment: .leading
        )
        
        let config = SlideRuleConfigurationBuilder()
            .addAnnotation(on: .backSlide, annotation)
            .build()
        
        #expect(config.componentConfigs.count == 1)
        #expect(config.componentConfigs[0].selector == .backSlide)
        #expect(config.componentConfigs[0].annotations.count == 1)
    }
    
    @Test("Chained methods accumulate correctly")
    func chainedMethods() {
        let config = SlideRuleConfigurationBuilder()
            .hideFormulas()
            .suppressEvenScaleNames()
            .configure(.backSlide) {
                ScaleConfiguration.colorLabels(.blue, for: .scale(.c))
            }
            .build()
        
        #expect(config.displaySettings.showFormulas == false)
        // 6 from suppressEvenScaleNames + 1 from configure
        #expect(config.componentConfigs.count == 7)
    }
    
    @Test("Builder from existing configuration preserves settings")
    func builderFromExisting() {
        let existing = SlideRuleConfiguration(
            displaySettings: RuleDisplaySettings(showFormulas: false)
        )
        
        let config = SlideRuleConfigurationBuilder(from: existing)
            .hideScaleNames()
            .build()
        
        #expect(config.displaySettings.showFormulas == false)
        #expect(config.displaySettings.showScaleNames == false)
    }
    
    @Test("Static build method works with closure")
    func staticBuildMethod() {
        let config = SlideRuleConfiguration.build { builder in
            builder
                .hideFormulas()
                .suppressEvenScaleNames()
        }
        
        #expect(config.displaySettings.showFormulas == false)
        #expect(config.componentConfigs.count == 6)
    }
    
    @Test("Default margin methods work correctly")
    func defaultMarginMethods() {
        let config = SlideRuleConfigurationBuilder()
            .defaultScaleNameMargin(.right)
            .defaultFormulaMargin(.left)
            .build()
        
        #expect(config.displaySettings.defaultScaleNameMargin == .right)
        #expect(config.displaySettings.defaultFormulaMargin == .left)
    }
}

// MARK: - Result Builder Tests

@Suite("ScaleConfigurationResultBuilder")
struct ScaleConfigurationResultBuilderTests {
    
    @Test("Result builder combines multiple configurations")
    func combinesConfigurations() {
        @ScaleConfigurationResultBuilder
        func buildConfigs() -> [ScaleConfiguration] {
            ScaleConfiguration.hideNames(for: .evenIndices)
            ScaleConfiguration.hideFormulas(for: .oddIndices)
            ScaleConfiguration.colorLabels(.red, for: .scale(.ll1))
        }
        
        let configs = buildConfigs()
        #expect(configs.count == 3)
    }
    
    @Test("Result builder handles conditionals")
    func handlesConditionals() {
        let showRed = true
        
        @ScaleConfigurationResultBuilder
        func buildConfigs() -> [ScaleConfiguration] {
            ScaleConfiguration.hideNames(for: .evenIndices)
            if showRed {
                ScaleConfiguration.colorLabels(.red, for: .all)
            }
        }
        
        let configs = buildConfigs()
        #expect(configs.count == 2)
    }
    
    @Test("Result builder handles else branch")
    func handlesElseBranch() {
        let useRed = false
        
        @ScaleConfigurationResultBuilder
        func buildConfigs() -> [ScaleConfiguration] {
            if useRed {
                ScaleConfiguration.colorLabels(.red, for: .all)
            } else {
                ScaleConfiguration.colorLabels(.blue, for: .all)
            }
        }
        
        let configs = buildConfigs()
        #expect(configs.count == 1)
        #expect(configs[0].labelColor == .blue)
    }
    
    @Test("Result builder handles arrays in loops")
    func handlesArrays() {
        let keys: [ScaleKey] = [.ll1, .ll2, .ll3]
        
        @ScaleConfigurationResultBuilder
        func buildConfigs() -> [ScaleConfiguration] {
            for key in keys {
                ScaleConfiguration.colorLabels(.red, for: .scale(key))
            }
        }
        
        let configs = buildConfigs()
        #expect(configs.count == 3)
    }
}

