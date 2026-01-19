//
//  SlideRulePicker.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/26/25.
//

import SwiftUI
import SwiftData

/// UI for selecting and switching between slide rule definitions
struct SlideRulePicker: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SlideRuleDefinitionModel.sortOrder) private var availableRules: [SlideRuleDefinitionModel]
    
    @Binding var currentRule: SlideRuleDefinitionModel?
    
    /// Whether the picker is expanded
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with current selection
            HStack {
                Label {
                    Text(currentRule?.name ?? "No Rule Selected")
                        .font(.headline)
                } icon: {
                    Image(systemName: "ruler")
                }
                .accessibilityLabel("Current slide rule: \(currentRule?.name ?? "None selected")")
                .accessibilityIdentifier("currentSlideRuleLabel")
                
                Spacer()
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse slide rule list" : "Expand slide rule list")
                .accessibilityIdentifier("slideRuleListToggle")
                .accessibilityHint(isExpanded ? "Hides the list of available slide rules" : "Shows the list of available slide rules")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                {
                    #if os(macOS)
                    Color(nsColor: NSColor.controlBackgroundColor)
                    #else
                    Color(uiColor: .secondarySystemBackground)
                    #endif
                }()
            )
            .cornerRadius(8)
            
            // Expandable rule list
            if isExpanded {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(availableRules) { rule in
                            SlideRuleButton(
                                rule: rule,
                                isSelected: currentRule?.id == rule.id,
                                action: {
                                    selectRule(rule)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 300)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .onAppear {
            initializeLibraryIfNeeded()
            selectDefaultRuleIfNeeded()
        }
    }
    
    // MARK: - Actions
    
    private func selectRule(_ rule: SlideRuleDefinitionModel) {
        print("🎯 SlideRulePicker: Selecting rule '\(rule.name)'")
        print("   Current rule before: \(currentRule?.name ?? "nil")")
        currentRule = rule
        print("   Current rule after: \(currentRule?.name ?? "nil")")
        withAnimation {
            isExpanded = false
        }
    }
    
    /// Initialize or update library with standard rules
    /// Detects version changes and updates modified rules
    private func initializeLibraryIfNeeded() {
        let standardRules = SlideRuleLibrary.standardRules()
        
        if availableRules.isEmpty {
            // First time: insert all rules
            print("📚 Initializing slide rule library (version \(SlideRuleLibrary.libraryVersion))")
            for rule in standardRules {
                modelContext.insert(rule)
            }
        } else {
            // Check if library version has changed or force refresh is enabled
            let maxExistingVersion = availableRules.map { $0.libraryVersion }.max() ?? 0
            let shouldUpdate = SlideRuleLibrary.forceRefresh || maxExistingVersion < SlideRuleLibrary.libraryVersion
            
            if shouldUpdate {
                if SlideRuleLibrary.forceRefresh {
                    print("📚 Force refreshing slide rule library (forceRefresh=true)")
                }
                print("📚 Updating slide rule library: v\(maxExistingVersion) → v\(SlideRuleLibrary.libraryVersion)")
                
                // Clean up rules with old names (renamed rules)
                let renamedRules: Set<String> = [
                    "Pickett N-16 ES (Annotation Test)",  // Renamed to "Configuration Playground"
                    "Pickett N-16 ES (API Demo)"          // Also renamed to "Configuration Playground"
                ]
                var deletedRuleNames = Set<String>()
                for oldName in renamedRules {
                    if let oldRule = availableRules.first(where: { $0.name == oldName }) {
                        print("  🗑 Deleting renamed rule: \(oldName)")
                        modelContext.delete(oldRule)
                        deletedRuleNames.insert(oldName)
                    }
                }
                
                // Create a lookup of existing rules by name (excluding deleted ones)
                var existingRulesByName: [String: SlideRuleDefinitionModel] = [:]
                for rule in availableRules where !deletedRuleNames.contains(rule.name) {
                    existingRulesByName[rule.name] = rule
                }
                
                // Update or insert each standard rule
                for standardRule in standardRules {
                    if let existingRule = existingRulesByName[standardRule.name] {
                        // Update existing rule with new definition
                        print("  ↻ Updating: \(standardRule.name)")
                        existingRule.ruleDescription = standardRule.ruleDescription
                        existingRule.definitionString = standardRule.definitionString
                        existingRule.topStatorMM = standardRule.topStatorMM
                        existingRule.slideMM = standardRule.slideMM
                        existingRule.bottomStatorMM = standardRule.bottomStatorMM
                        existingRule.circularSpec = standardRule.circularSpec
                        existingRule.sortOrder = standardRule.sortOrder
                        existingRule.libraryVersion = standardRule.libraryVersion
                        // Sync configuration JSON (Phase 6 - full configuration system)
                        print("    📝 configurationJSON sync: standard=\(standardRule.configurationJSON?.prefix(100) ?? "nil") → existing=\(existingRule.configurationJSON?.prefix(100) ?? "nil")")
                        existingRule.configurationJSON = standardRule.configurationJSON
                        print("    ✅ After sync: \(existingRule.configurationJSON?.prefix(100) ?? "nil")")
                        // Legacy annotation features (keeping for backward compatibility)
                        existingRule.backSlideAnnotationsJSON = standardRule.backSlideAnnotationsJSON
                        // Preserve user's favorite status
                    } else {
                        // New rule: insert it
                        print("  + Adding: \(standardRule.name)")
                        modelContext.insert(standardRule)
                    }
                }
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Slide rule library synchronized")
        } catch {
            print("❌ Failed to save slide rule library: \(error)")
        }
    }
    
    /// Select first rule if none selected
    private func selectDefaultRuleIfNeeded() {
        if currentRule == nil, let firstRule = availableRules.first {
            currentRule = firstRule
        }
    }
}

// MARK: - Slide Rule Button Component

struct SlideRuleButton: View {
    let rule: SlideRuleDefinitionModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: rule.circularSpec != nil ? "circle.hexagongrid.circle" : "ruler.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 30)
                    .accessibilityHidden(true)  // Hide icon from VoiceOver (redundant with button label)
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(rule.ruleDescription)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .accessibilityElement(children: .combine)  // Combine name and description for VoiceOver
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .accessibilityHidden(true)  // Selection state is conveyed via button traits
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : {
                        #if os(macOS)
                        Color(nsColor: NSColor.controlBackgroundColor)
                        #else
                        Color(uiColor: .secondarySystemBackground)
                        #endif
                    }())
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(rule.name). \(rule.ruleDescription)")
        .accessibilityIdentifier("slideRuleButton_\(rule.name.replacingOccurrences(of: " ", with: "_"))")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select this slide rule")
    }
}

// MARK: - Preview

#Preview {
    SlideRulePicker(currentRule: .constant(nil))
        .modelContainer(for: [SlideRuleDefinitionModel.self, CurrentSlideRule.self])
        .frame(width: 400)
}
