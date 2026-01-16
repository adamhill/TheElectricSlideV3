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
                    b = b.addAnnotation(annotation, for: .backSlide)
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
        backSlideAnnotationsJSON: String? = nil
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
        self.showScaleNames = showScaleNames
        self.showFormulas = showFormulas
        self.suppressEvenScaleNames = suppressEvenScaleNames
        self.backSlideAnnotationsJSON = backSlideAnnotationsJSON
    }
    
    /// Parse this definition into a SlideRule
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
                displaySettings: displaySettings
            )
        }
        
        // Apply scale name overrides if any exist
        if !scaleNameOverrides.isEmpty {
            rule = applyScaleNameOverrides(to: rule)
        }
        
        // Apply even-indexed scale name suppression if enabled
        if suppressEvenScaleNames {
            print("🔧 Applying even-indexed scale name suppression")
            rule = applyEvenScaleNameSuppression(to: rule)
        } else {
            print("⚠️ suppressEvenScaleNames is FALSE, not suppressing")
        }
        
        // Apply back slide annotations if any exist
        if !backSlideAnnotations.isEmpty {
            rule = applyBackSlideAnnotations(to: rule)
        }
        
        return rule
    }
    
    /// Apply suppression of scale names at even indices (0, 2, 4, ...)
    private func applyEvenScaleNameSuppression(to rule: SlideRule) -> SlideRule {
        // Helper to suppress scale names at even indices
        func suppressEvenScales(_ scales: [GeneratedScale]) -> [GeneratedScale] {
            return scales.enumerated().map { (index, generatedScale) in
                // Even indices: 0, 2, 4, ...
                if index % 2 == 0 {
                    // IMPORTANT: Use MarginSide.none explicitly to avoid Swift inferring Optional.none (nil)
                    let newDefinition = ScaleBuilder(from: generatedScale.definition)
                        .withScaleNameMargin(MarginSide.none)
                        .build()
                    return GeneratedScale(definition: newDefinition, noLineBreak: generatedScale.noLineBreak)
                }
                return generatedScale
            }
        }
        
        func processStator(_ stator: Stator) -> Stator {
            Stator(
                name: stator.name,
                scales: suppressEvenScales(stator.scales),
                heightInPoints: stator.heightInPoints,
                showBorder: stator.showBorder,
                annotations: stator.annotations
            )
        }
        
        func processSlide(_ slide: Slide) -> Slide {
            Slide(
                name: slide.name,
                scales: suppressEvenScales(slide.scales),
                heightInPoints: slide.heightInPoints,
                showBorder: slide.showBorder,
                annotations: slide.annotations
            )
        }
        
        return SlideRule(
            frontTopStator: processStator(rule.frontTopStator),
            frontSlide: processSlide(rule.frontSlide),
            frontBottomStator: processStator(rule.frontBottomStator),
            backTopStator: rule.backTopStator.map { processStator($0) },
            backSlide: rule.backSlide.map { processSlide($0) },
            backBottomStator: rule.backBottomStator.map { processStator($0) },
            totalLengthInPoints: rule.totalLengthInPoints,
            diameter: rule.diameter,
            radialPositions: rule.radialPositions,
            displaySettings: rule.displaySettings
        )
    }
    
    /// Apply annotations to the back slide
    private func applyBackSlideAnnotations(to rule: SlideRule) -> SlideRule {
        guard let backSlide = rule.backSlide else { return rule }
        
        let newBackSlide = Slide(
            name: backSlide.name,
            scales: backSlide.scales,
            heightInPoints: backSlide.heightInPoints,
            showBorder: backSlide.showBorder,
            annotations: backSlide.annotations + backSlideAnnotations
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
    }
    
    /// Apply scale name overrides to a parsed slide rule
    private func applyScaleNameOverrides(to rule: SlideRule) -> SlideRule {
        guard !scaleNameOverrides.isEmpty else { return rule }
        
        // Shared helper to override a single GeneratedScale
        func overrideGeneratedScale(_ generatedScale: GeneratedScale) -> GeneratedScale {
            let scaleName = generatedScale.definition.name
            guard let overrideName = scaleNameOverrides[scaleName] else {
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
