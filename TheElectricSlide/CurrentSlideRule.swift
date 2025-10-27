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
    
    init(
        name: String,
        description: String,
        definitionString: String,
        topStatorMM: Double = 14,
        slideMM: Double = 13,
        bottomStatorMM: Double = 14,
        circularSpec: String? = nil,
        isFavorite: Bool = false,
        sortOrder: Int = 0
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
        
        if circularSpec != nil {
            return try RuleDefinitionParser.parseWithCircular(
                fullDefinition,
                dimensions: dimensions,
                scaleLength: scaleLength
            )
        } else {
            return try RuleDefinitionParser.parse(
                fullDefinition,
                dimensions: dimensions,
                scaleLength: scaleLength
            )
        }
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
