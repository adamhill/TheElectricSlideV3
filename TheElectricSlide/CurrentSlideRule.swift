//  CurrentSlideRule.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/22/25.
//

import Foundation
import SwiftData
import SlideRuleCoreV3

/// Represents a slide rule definition stored in SwiftData
@Model
final class SlideRuleDefinitionModel {
    /// Unique identifier
    var id: UUID
    
    /// Human-readable name (e.g., "K&E 4081-3 Log-Log Duplex Decitrig")
    var name: String
    
    /// Description of the rule's features
    var ruleDescription: String
    
    /// PostScript-style definition string
    /// Format: "(scale1 scale2 [ slide_scale1 ] scale3 : back_scale1 [ back_slide ])"
    var definitionString: String
    
    /// Whether this rule is favorited
    var isFavorite: Bool
    
    /// Top stator height in mm
    var topStatorMM: Double
    
    /// Slide height in mm
    var slideMM: Double
    
    /// Bottom stator height in mm
    var bottomStatorMM: Double
    
    /// Optional circular specification (e.g., "circular:4inch")
    var circularSpec: String?
    
    /// Order for sorting
    var sortOrder: Int
    
    /// Scale name overrides for custom display labels
    /// Key: canonical scale name (e.g., "L"), Value: display name (e.g., "dB L")
    var scaleNameOverrides: [String: String] = [:]
    
    /// Library version this rule was created/updated with
    var libraryVersion: Int = 0
    
    /// Manufacturer associated with this rule (for color scheme application)
    /// Stored as String for SwiftData compatibility - nil for generic/educational rules
    var manufacturer: String?
    
    /// Computed property to get the SlideRuleManufacturer enum for color scheme lookup
    var manufacturerEnum: SlideRuleManufacturer? {
        guard let manufacturer else { return nil }
        return SlideRuleManufacturer(rawValue: manufacturer)
    }
    
    // MARK: - Configuration System (Phase 6)
    
    /// JSON-encoded SlideRuleConfiguration for full configuration support
    /// This replaces individual boolean properties while maintaining backward compatibility
    var configurationJSON: String?
    
    /// Full configuration object - encodes/decodes from JSON automatically
    var configuration: SlideRuleConfiguration {
        get {
            guard let json = configurationJSON,
                  let data = json.data(using: .utf8) else {
                // Return migrated configuration from legacy properties
                return migratedConfiguration
            }
            do {
                return try JSONDecoder().decode(SlideRuleConfiguration.self, from: data)
            } catch {
                print("⚠️ Failed to decode configuration: \(error)")
                return migratedConfiguration
            }
        }
        set {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                let data = try encoder.encode(newValue)
                configurationJSON = String(data: data, encoding: .utf8)
            } catch {
                print("⚠️ Failed to encode configuration: \(error)")
            }
        }
    }
    
    /// Creates a configuration from legacy properties (backward compatibility)
    private var migratedConfiguration: SlideRuleConfiguration {
        SlideRuleConfiguration.build { builder in
            var b = builder
            
            // Apply display settings
            if !_showScaleNames {
                b = b.hideScaleNames()
            }
            if !_showFormulas {
                b = b.hideFormulas()
            }
            
            // Apply even scale name suppression
            if _suppressEvenScaleNames {
                b = b.suppressEvenScaleNames()
            }
            
            // Apply scale name overrides
            if !scaleNameOverrides.isEmpty {
                b = b.addNameOverrides(scaleNameOverrides)
            }
            
            // Apply back slide annotations
            if let json = backSlideAnnotationsJSON,
               let data = json.data(using: .utf8),
               let annotations = try? JSONDecoder().decode([ComponentAnnotation].self, from: data) {
                for annotation in annotations {
                    b = b.addAnnotation(annotation, on: .back)
                }
            }
            
            return b
        }
    }
    
    // MARK: - Legacy Properties (Backward Compatibility)
    // These are stored for migration but accessed through computed properties
    
    /// Internal storage for showScaleNames (legacy)
    private var _showScaleNames: Bool = true
    
    /// Internal storage for showFormulas (legacy)
    private var _showFormulas: Bool = true
    
    /// Internal storage for suppressEvenScaleNames (legacy)
    private var _suppressEvenScaleNames: Bool = false
    
    /// JSON-encoded annotation data for back slide (legacy - now in configuration)
    var backSlideAnnotationsJSON: String?
    
    /// Whether to show scale names (computed from configuration)
    var showScaleNames: Bool {
        get { 
            if configurationJSON != nil {
                return configuration.displaySettings.showScaleNames
            }
            return _showScaleNames
        }
        set {
            if configurationJSON != nil {
                var config = configuration
                config.displaySettings.showScaleNames = newValue
                configuration = config
            } else {
                _showScaleNames = newValue
            }
        }
    }
    
    /// Whether to show formulas (computed from configuration)
    var showFormulas: Bool {
        get {
            if configurationJSON != nil {
                return configuration.displaySettings.showFormulas
            }
            return _showFormulas
        }
        set {
            if configurationJSON != nil {
                var config = configuration
                config.displaySettings.showFormulas = newValue
                configuration = config
            } else {
                _showFormulas = newValue
            }
        }
    }
    
    /// Whether to suppress scale names for even-indexed scales
    var suppressEvenScaleNames: Bool {
        get {
            if configurationJSON != nil {
                // Check if any component config has even-index hiding
                return configuration.componentConfigs.contains { componentConfig in
                    componentConfig.scaleConfigs.contains { scaleConfig in
                        scaleConfig.selector == .evenIndices && scaleConfig.nameMargin == MarginSide.none
                    }
                }
            }
            return _suppressEvenScaleNames
        }
        set {
            if configurationJSON != nil {
                var config = configuration
                if newValue {
                    // Add even name suppression to all components
                    let evenHide = ScaleConfiguration.hideNames(for: .evenIndices)
                    for selector in ComponentSelector.all {
                        config.addComponentConfig(ComponentConfiguration(
                            selector: selector,
                            scaleConfigs: [evenHide]
                        ))
                    }
                }
                // Note: Removing suppression is complex - would need to filter existing configs
                configuration = config
            } else {
                _suppressEvenScaleNames = newValue
            }
        }
    }
    
    /// Computed property to get RuleDisplaySettings
    var displaySettings: RuleDisplaySettings {
        configuration.displaySettings
    }
    
    /// Computed property to decode back slide annotations
    var backSlideAnnotations: [ComponentAnnotation] {
        // First check configuration
        let configAnnotations = configuration.ruleAnnotations[.back] ?? []
        if !configAnnotations.isEmpty {
            return configAnnotations
        }
        
        // Fall back to legacy JSON
        guard let json = backSlideAnnotationsJSON,
              let data = json.data(using: .utf8) else {
            return []
        }
        do {
            return try JSONDecoder().decode([ComponentAnnotation].self, from: data)
        } catch {
            print("Failed to decode backSlideAnnotations: \(error)")
            return []
        }
    }
    
    init(
        name: String,
        description: String,
        definitionString: String,
        topStatorMM: Double = 14,
        slideMM: Double = 13,
        bottomStatorMM: Double = 14,
        circularSpec: String? = nil,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        scaleNameOverrides: [String: String] = [:],
        libraryVersion: Int = 0,
        manufacturer: String? = nil,
        showScaleNames: Bool = true,
        showFormulas: Bool = true,
        suppressEvenScaleNames: Bool = false,
        backSlideAnnotationsJSON: String? = nil,
        configuration: SlideRuleConfiguration? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.ruleDescription = description
        self.definitionString = definitionString
        self.topStatorMM = topStatorMM
        self.slideMM = slideMM
        self.bottomStatorMM = bottomStatorMM
        self.circularSpec = circularSpec
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.scaleNameOverrides = scaleNameOverrides
        self.libraryVersion = libraryVersion
        self.manufacturer = manufacturer
        
        // Store legacy values for backward compatibility
        self._showScaleNames = showScaleNames
        self._showFormulas = showFormulas
        self._suppressEvenScaleNames = suppressEvenScaleNames
        self.backSlideAnnotationsJSON = backSlideAnnotationsJSON
        
        // If configuration provided, encode and store it
        if let config = configuration {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                let data = try encoder.encode(config)
                self.configurationJSON = String(data: data, encoding: .utf8)
            } catch {
                print("⚠️ Failed to encode initial configuration: \(error)")
            }
        }
    }
    
    /// Convenience initializer that takes a SlideRuleConfiguration directly
    convenience init(
        name: String,
        description: String,
        definitionString: String,
        topStatorMM: Double = 14,
        slideMM: Double = 13,
        bottomStatorMM: Double = 14,
        circularSpec: String? = nil,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        libraryVersion: Int = 0,
        manufacturer: String? = nil,
        configuration: SlideRuleConfiguration
    ) {
        self.init(
            name: name,
            description: description,
            definitionString: definitionString,
            topStatorMM: topStatorMM,
            slideMM: slideMM,
            bottomStatorMM: bottomStatorMM,
            circularSpec: circularSpec,
            isFavorite: isFavorite,
            sortOrder: sortOrder,
            scaleNameOverrides: configuration.scaleNameOverrides,
            libraryVersion: libraryVersion,
            manufacturer: manufacturer,
            showScaleNames: configuration.displaySettings.showScaleNames,
            showFormulas: configuration.displaySettings.showFormulas,
            suppressEvenScaleNames: false, // Handled by configuration
            backSlideAnnotationsJSON: nil, // Handled by configuration
            configuration: configuration
        )
    }
    
    /// Parse this definition into a SlideRule using the configuration system
    func parseSlideRule(scaleLength: Distance = 1000.0) throws -> SlideRule {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: topStatorMM,
            slideMM: slideMM,
            bottomStatorMM: bottomStatorMM
        )
        
        let fullDefinition: String
        if let circularSpec = circularSpec {
            fullDefinition = "\(definitionString) \(circularSpec)"
        } else {
            fullDefinition = definitionString
        }
        
        // Get the configuration (either from JSON or migrated from legacy)
        let config = configuration
        
        var rule: SlideRule
        if circularSpec != nil {
            rule = try RuleDefinitionParser.parseWithCircular(
                fullDefinition,
                dimensions: dimensions,
                scaleLength: scaleLength
            )
        } else {
            rule = try RuleDefinitionParser.parse(
                fullDefinition,
                dimensions: dimensions,
                scaleLength: scaleLength,
                displaySettings: config.displaySettings
            )
        }
        
        // Apply configuration using the new unified system
        rule = applyConfiguration(config, to: rule)
        
        return rule
    }
    
    /// Apply full SlideRuleConfiguration to a parsed rule
    private func applyConfiguration(_ config: SlideRuleConfiguration, to rule: SlideRule) -> SlideRule {
        var result = rule
        
        // Apply scale name overrides
        if !config.scaleNameOverrides.isEmpty {
            result = applyScaleNameOverrides(config.scaleNameOverrides, to: result)
        }
        
        // Apply component configurations (scale display settings)
        if !config.componentConfigs.isEmpty {
            result = applyComponentConfigs(config.componentConfigs, to: result)
        }
        
        // Apply rule-level annotations
        for (side, annotations) in config.ruleAnnotations {
            result = applyAnnotations(annotations, side: side, to: result)
        }
        
        return result
    }
    
    /// Apply component configurations to control scale display
    private func applyComponentConfigs(_ configs: [ComponentConfiguration], to rule: SlideRule) -> SlideRule {
        // DEBUG: Log all configs
        print("🔧 applyComponentConfigs: received \(configs.count) component configs")
        for (idx, config) in configs.enumerated() {
            print("  [\(idx)] selector: \(config.selector), scaleConfigs: \(config.scaleConfigs.count)")
            for scaleConfig in config.scaleConfigs {
                print("    - nameMargin: \(String(describing: scaleConfig.nameMargin)), formulaMargin: \(String(describing: scaleConfig.formulaMargin))")
            }
        }
        
        // Process each component
        func processScales(
            _ scales: [GeneratedScale],
            side: RuleSideSelector,
            component: ComponentType
        ) -> [GeneratedScale] {
            // Find all configs that apply to this component
            let applicableConfigs = configs.filter { $0.appliesTo(side: side, component: component) }
            print("🔧 processScales: \(side) \(component) - found \(applicableConfigs.count) applicable configs")
            guard !applicableConfigs.isEmpty else { return scales }
            
            let totalCount = scales.count
            return scales.enumerated().map { (index, generatedScale) in
                // Apply each applicable config's scale configs
                var modifiedDefinition = generatedScale.definition
                var wasModified = false
                
                for componentConfig in applicableConfigs {
                    for scaleConfig in componentConfig.scaleConfigs {
                        if scaleConfig.selector.matches(
                            scaleName: generatedScale.definition.name,
                            at: index,
                            totalCount: totalCount
                        ) {
                            // Apply the scale configuration
                            modifiedDefinition = applyScaleConfig(scaleConfig, to: modifiedDefinition)
                            wasModified = true
                        }
                    }
                }
                
                if wasModified {
                    return GeneratedScale(definition: modifiedDefinition, noLineBreak: generatedScale.noLineBreak)
                }
                return generatedScale
            }
        }
        
        func processStator(_ stator: Stator, side: RuleSideSelector, component: ComponentType) -> Stator {
            Stator(
                name: stator.name,
                scales: processScales(stator.scales, side: side, component: component),
                heightInPoints: stator.heightInPoints,
                showBorder: stator.showBorder,
                annotations: stator.annotations
            )
        }
        
        func processSlide(_ slide: Slide, side: RuleSideSelector, component: ComponentType) -> Slide {
            Slide(
                name: slide.name,
                scales: processScales(slide.scales, side: side, component: component),
                heightInPoints: slide.heightInPoints,
                showBorder: slide.showBorder,
                annotations: slide.annotations
            )
        }
        
        return SlideRule(
            frontTopStator: processStator(rule.frontTopStator, side: .front, component: .topStator),
            frontSlide: processSlide(rule.frontSlide, side: .front, component: .slide),
            frontBottomStator: processStator(rule.frontBottomStator, side: .front, component: .bottomStator),
            backTopStator: rule.backTopStator.map { processStator($0, side: .back, component: .topStator) },
            backSlide: rule.backSlide.map { processSlide($0, side: .back, component: .slide) },
            backBottomStator: rule.backBottomStator.map { processStator($0, side: .back, component: .bottomStator) },
            totalLengthInPoints: rule.totalLengthInPoints,
            diameter: rule.diameter,
            radialPositions: rule.radialPositions,
            displaySettings: rule.displaySettings
        )
    }
    
    /// Apply a single ScaleConfiguration to a ScaleDefinition
    private func applyScaleConfig(_ config: ScaleConfiguration, to definition: ScaleDefinition) -> ScaleDefinition {
        var builder = ScaleBuilder(from: definition)
        
        // Apply name margin (visibility)
        if let nameMargin = config.nameMargin {
            builder = builder.withScaleNameMargin(nameMargin)
        }
        
        // Apply formula margin (visibility)
        if let formulaMargin = config.formulaMargin {
            builder = builder.withFormulaMargin(formulaMargin)
        }
        
        // Apply label color
        if let labelColor = config.labelColor {
            builder = builder.withLabelColor(labelColor)
        }
        
        // Apply name nudge (position offset for scale name)
        if let nameNudge = config.nameNudge {
            builder = builder.withNameNudge(nameNudge)
        }
        
        // Apply formula nudge (position offset for formula)
        if let formulaNudge = config.formulaNudge {
            builder = builder.withFormulaNudge(formulaNudge)
        }
        
        return builder.build()
    }
    
    /// Apply annotations to a specific side
    private func applyAnnotations(_ annotations: [ComponentAnnotation], side: RuleSideSelector, to rule: SlideRule) -> SlideRule {
        guard !annotations.isEmpty else { return rule }
        
        // For now, annotations go on the slide component
        // Future: could use component specifier in annotation
        switch side {
        case .front:
            let newSlide = Slide(
                name: rule.frontSlide.name,
                scales: rule.frontSlide.scales,
                heightInPoints: rule.frontSlide.heightInPoints,
                showBorder: rule.frontSlide.showBorder,
                annotations: rule.frontSlide.annotations + annotations
            )
            return SlideRule(
                frontTopStator: rule.frontTopStator,
                frontSlide: newSlide,
                frontBottomStator: rule.frontBottomStator,
                backTopStator: rule.backTopStator,
                backSlide: rule.backSlide,
                backBottomStator: rule.backBottomStator,
                totalLengthInPoints: rule.totalLengthInPoints,
                diameter: rule.diameter,
                radialPositions: rule.radialPositions,
                displaySettings: rule.displaySettings
            )
        case .back:
            guard let backSlide = rule.backSlide else { return rule }
            let newBackSlide = Slide(
                name: backSlide.name,
                scales: backSlide.scales,
                heightInPoints: backSlide.heightInPoints,
                showBorder: backSlide.showBorder,
                annotations: backSlide.annotations + annotations
            )
            return SlideRule(
                frontTopStator: rule.frontTopStator,
                frontSlide: rule.frontSlide,
                frontBottomStator: rule.frontBottomStator,
                backTopStator: rule.backTopStator,
                backSlide: newBackSlide,
                backBottomStator: rule.backBottomStator,
                totalLengthInPoints: rule.totalLengthInPoints,
                diameter: rule.diameter,
                radialPositions: rule.radialPositions,
                displaySettings: rule.displaySettings
            )
        case .both:
            var result = rule
            result = applyAnnotations(annotations, side: .front, to: result)
            result = applyAnnotations(annotations, side: .back, to: result)
            return result
        }
    }
    
    /// Apply scale name overrides to a parsed slide rule
    private func applyScaleNameOverrides(_ overrides: [String: String], to rule: SlideRule) -> SlideRule {
        guard !overrides.isEmpty else { return rule }
        
        // Shared helper to override a single GeneratedScale
        func overrideGeneratedScale(_ generatedScale: GeneratedScale) -> GeneratedScale {
            let scaleName = generatedScale.definition.name
            guard let overrideName = overrides[scaleName] else {
                return generatedScale
            }
            
            let newDefinition = ScaleDefinition(
                name: overrideName,
                formula: generatedScale.definition.formula,
                function: generatedScale.definition.function,
                beginValue: generatedScale.definition.beginValue,
                endValue: generatedScale.definition.endValue,
                scaleLengthInPoints: generatedScale.definition.scaleLengthInPoints,
                layout: generatedScale.definition.layout,
                tickDirection: generatedScale.definition.tickDirection,
                subsections: generatedScale.definition.subsections,
                defaultTickStyles: generatedScale.definition.defaultTickStyles,
                labelFormatter: generatedScale.definition.labelFormatter,
                labelColor: generatedScale.definition.labelColor,
                colorApplication: generatedScale.definition.colorApplication,
                constants: generatedScale.definition.constants,
                showBaseline: generatedScale.definition.showBaseline,
                formulaTracking: generatedScale.definition.formulaTracking
            )
            return GeneratedScale(definition: newDefinition, noLineBreak: generatedScale.noLineBreak)
        }
        
        // Helper function to override scale names in a Stator
        func overrideStatorScales(_ stator: Stator) -> Stator {
            return Stator(
                name: stator.name,
                scales: stator.scales.map(overrideGeneratedScale),
                heightInPoints: stator.heightInPoints,
                showBorder: stator.showBorder,
                annotations: stator.annotations
            )
        }
        
        // Helper function to override scale names in a Slide
        func overrideSlideScales(_ slide: Slide) -> Slide {
            return Slide(
                name: slide.name,
                scales: slide.scales.map(overrideGeneratedScale),
                heightInPoints: slide.heightInPoints,
                showBorder: slide.showBorder,
                annotations: slide.annotations
            )
        }
        
        // Apply overrides to front side
        let newFrontTopStator = overrideStatorScales(rule.frontTopStator)
        let newFrontSlide = overrideSlideScales(rule.frontSlide)
        let newFrontBottomStator = overrideStatorScales(rule.frontBottomStator)
        
        // Apply overrides to back side (if it exists)
        let newBackTopStator = rule.backTopStator.map { overrideStatorScales($0) }
        let newBackSlide = rule.backSlide.map { overrideSlideScales($0) }
        let newBackBottomStator = rule.backBottomStator.map { overrideStatorScales($0) }
        
        return SlideRule(
            frontTopStator: newFrontTopStator,
            frontSlide: newFrontSlide,
            frontBottomStator: newFrontBottomStator,
            backTopStator: newBackTopStator,
            backSlide: newBackSlide,
            backBottomStator: newBackBottomStator,
            totalLengthInPoints: rule.totalLengthInPoints,
            diameter: rule.diameter,
            radialPositions: rule.radialPositions,
            displaySettings: rule.displaySettings
        )
    }
    
    // MARK: - Migration Helpers
    
    /// Migrate from legacy properties to configuration JSON
    /// Call this to persist legacy settings into the new configuration system
    func migrateToConfiguration() {
        guard configurationJSON == nil else { return } // Already migrated
        configuration = migratedConfiguration
    }
}

/// Stores the currently selected slide rule
@Model
final class CurrentSlideRule {
    /// Reference to the currently selected rule definition
    var selectedRule: SlideRuleDefinitionModel?
    
    /// Last updated timestamp
    var lastUpdated: Date
    
    init(selectedRule: SlideRuleDefinitionModel? = nil) {
        self.selectedRule = selectedRule
        self.lastUpdated = Date()
    }
    
    func updateSelection(_ rule: SlideRuleDefinitionModel) {
        self.selectedRule = rule
        self.lastUpdated = Date()
    }
}
