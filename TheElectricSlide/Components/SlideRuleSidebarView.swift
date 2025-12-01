//
//  SlideRuleSidebarView.swift
//  TheElectricSlide
//
//  Extracted from ContentView.swift
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

// MARK: - Platform Color Helpers

#if os(iOS)
private func systemBackgroundColor() -> Color {
    Color(uiColor: .systemBackground)
}
#else
private func systemBackgroundColor() -> Color {
    Color(nsColor: .windowBackgroundColor)
}
#endif

// MARK: - Sidebar View (List of Slide Rules)

struct SlideRuleSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedRule: SlideRuleDefinitionModel?
    @Binding var viewMode: ViewMode
    @Binding var cursorDisplayMode: CursorDisplayMode
    let availableRules: [SlideRuleDefinitionModel]
    let hasBackSide: Bool
    let deviceCategory: DeviceCategory
    let onRuleSelected: (SlideRuleDefinitionModel) -> Void
    
    /// Available view modes based on device category and slide rule capabilities
    private var availableModes: [ViewMode] {
        ViewMode.availableModes(for: deviceCategory).filter { mode in
            mode == .front || hasBackSide
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Cursor Display Mode Picker at top
            VStack(spacing: 8) {
                Text("Cursor Display")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Cursor Display", selection: $cursorDisplayMode) {
                    ForEach(CursorDisplayMode.allCases) { mode in
                        Text(mode.displayText).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding()
            .background(systemBackgroundColor())

            Divider()
            
            // View Mode Picker (Front | Back | Both)
            Picker("View Mode", selection: $viewMode) {
                ForEach(availableModes) { mode in
                    Text(mode.rawValue).tag(mode)
                        .accessibilityLabel("\(mode.rawValue) side")
                        .accessibilityIdentifier("viewModeOption_\(mode.rawValue.lowercased())")
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
            .allowsHitTesting(true)
            .accessibilityLabel("View mode selector")
            .accessibilityIdentifier("viewModePicker")
            .accessibilityValue(viewMode.rawValue)
            .accessibilityHint("Select which side of the slide rule to display")
            
            Divider()
            
            // List of slide rules
            List(availableRules, selection: $selectedRule) { rule in
                Button {
                    onRuleSelected(rule)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                    // Icon
                    Image(systemName: rule.circularSpec != nil ? "circle.hexagongrid.circle" : "ruler.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.name)
                            .font(.headline)
                        
                        Text(rule.ruleDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            }
            .navigationTitle("Slide Rules")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            #endif
            .onAppear {
                initializeLibraryIfNeeded()
            }
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
            // Check if library version has changed
            let maxExistingVersion = availableRules.map { $0.libraryVersion }.max() ?? 0
            
            if maxExistingVersion < SlideRuleLibrary.libraryVersion {
                print("📚 Updating slide rule library: v\(maxExistingVersion) → v\(SlideRuleLibrary.libraryVersion)")
                
                // Create a lookup of existing rules by name
                var existingRulesByName: [String: SlideRuleDefinitionModel] = [:]
                for rule in availableRules {
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
                        existingRule.scaleNameOverrides = standardRule.scaleNameOverrides
                        existingRule.libraryVersion = standardRule.libraryVersion
                        // Preserve user's favorite status
                    } else {
                        // New rule: insert it
                        print("  + Adding: \(standardRule.name)")
                        modelContext.insert(standardRule)
                    }
                }
                
                // Optionally: Remove rules that no longer exist in standard library
                // (commented out to preserve user-created custom rules)
                /*
                let standardRuleNames = Set(standardRules.map { $0.name })
                for existingRule in availableRules {
                    if !standardRuleNames.contains(existingRule.name) && existingRule.libraryVersion > 0 {
                        print("  - Removing: \(existingRule.name)")
                        modelContext.delete(existingRule)
                    }
                }
                */
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Slide rule library synchronized")
        } catch {
            print("❌ Failed to save slide rule library: \(error)")
        }
    }
}
