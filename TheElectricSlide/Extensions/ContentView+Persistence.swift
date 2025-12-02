//
//  ContentView+Persistence.swift
//  TheElectricSlide
//
//  Persistence helpers extracted from ContentView.swift
//  Handles SwiftData operations for slide rule selection and parsing
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

// MARK: - Persistence Helpers

extension ContentView {
    
    /// Load the currently selected slide rule from SwiftData
    /// Called on app launch to restore previous selection
    func loadCurrentRule() {
        if let currentRule = currentRuleQuery.first {
            selectedRuleDefinition = currentRule.selectedRule
            selectedRuleId = currentRule.selectedRule?.id
        }
        // Parse initial slide rule
        parseAndUpdateSlideRule()
    }
    
    /// Save the current slide rule selection to SwiftData
    /// Called when user selects a different rule
    func saveCurrentRule() {
        guard let selectedRuleDefinition = selectedRuleDefinition else {
            print("⚠️ Cannot save: selectedRuleDefinition is nil")
            return
        }
        if let current = currentRuleQuery.first {
            current.updateSelection(selectedRuleDefinition)
        } else {
            let newCurrent = CurrentSlideRule(selectedRule: selectedRuleDefinition)
            modelContext.insert(newCurrent)
        }
        
        try? modelContext.save()
    }
    
    /// Parse the selected rule definition and update the current slide rule
    /// Handles errors gracefully with fallback to default rule
    func parseAndUpdateSlideRule() {
        guard let definition = selectedRuleDefinition else {
            // Use default rule
            print("⚠️ No definition selected, using default")
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
            cursorState.updateReadings()
            return
        }
        
        print("🔧 Parsing slide rule: \(definition.name)")
        print("   Definition: \(definition.definitionString)")
        
        do {
            let parsed = try definition.parseSlideRule(scaleLength: 1000)
            currentSlideRule = parsed
            print("✅ Successfully loaded slide rule: \(definition.name)")
            print("   Front scales: \(parsed.frontTopStator.scales.count) + \(parsed.frontSlide.scales.count) + \(parsed.frontBottomStator.scales.count)")
            
            // Update cursor readings immediately after parsing new slide rule
            cursorState.updateReadings()
        } catch {
            print("❌ Failed to parse slide rule '\(definition.name)': \(error)")
            // Fallback to basic rule
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
            cursorState.updateReadings()
        }
    }
}
