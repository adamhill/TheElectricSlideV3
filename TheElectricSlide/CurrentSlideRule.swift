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
        libraryVersion: Int = 0
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
                scaleLength: scaleLength
            )
        }
        
        // Apply scale name overrides if any exist
        if !scaleNameOverrides.isEmpty {
            rule = applyScaleNameOverrides(to: rule)
        }
        
        return rule
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
            Stator(
                name: stator.name,
                scales: stator.scales.map(overrideGeneratedScale),
                heightInPoints: stator.heightInPoints,
                showBorder: stator.showBorder
            )
        }
        
        // Helper function to override scale names in a Slide
        func overrideSlideScales(_ slide: Slide) -> Slide {
            Slide(
                name: slide.name,
                scales: slide.scales.map(overrideGeneratedScale),
                heightInPoints: slide.heightInPoints,
                showBorder: slide.showBorder
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
            radialPositions: rule.radialPositions
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
