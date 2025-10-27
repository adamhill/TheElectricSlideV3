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
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
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
    
    /// Initialize library with standard rules if database is empty
    private func initializeLibraryIfNeeded() {
        if availableRules.isEmpty {
            let standardRules = SlideRuleLibrary.standardRules()
            for rule in standardRules {
                modelContext.insert(rule)
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to initialize slide rule library: \(error)")
            }
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
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SlideRulePicker(currentRule: .constant(nil))
        .modelContainer(for: [SlideRuleDefinitionModel.self, CurrentSlideRule.self])
        .frame(width: 400)
}
