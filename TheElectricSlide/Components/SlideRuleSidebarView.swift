//
//  SlideRuleSidebarView.swift
//  TheElectricSlide
//
//  Extracted from ContentView.swift
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3
import UniformTypeIdentifiers

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
    @Binding var useManufacturerColors: Bool
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
            // Cursor Display Mode Toggle at top with Liquid Glass styling
            VStack(spacing: 8) {
                Text("Cursor Display")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Toggle("Always Show Cursor Values", isOn: Binding(
                    get: { cursorDisplayMode.showReadings },
                    set: { isOn in
                        cursorDisplayMode = isOn ? .both : .gradients
                    }
                ))
                .toggleStyle(.switch)
                
                // Manufacturer colorway toggle - only shown when rule has a manufacturer
                if selectedRule?.manufacturer != nil {
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("Appearance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Toggle("Manufacturer Colors", isOn: $useManufacturerColors)
                        .toggleStyle(.switch)
                        .help("Apply authentic \(selectedRule?.manufacturerEnum?.displayName ?? "") color scheme")
                }
            }
            .padding()
            .background(.thinMaterial)

            Divider()
            
            // View Mode Picker (Front | Back | Both) with Liquid Glass container
            VStack(spacing: 8) {
                Picker("View Mode", selection: $viewMode) {
                    ForEach(availableModes) { mode in
                        Text(mode.rawValue).tag(mode)
                            .accessibilityLabel("\(mode.rawValue) side")
                            .accessibilityIdentifier("viewModeOption_\(mode.rawValue.lowercased())")
                    }
                }
                .pickerStyle(.segmented)
                .allowsHitTesting(true)
                .accessibilityLabel("View mode selector")
                .accessibilityIdentifier("viewModePicker")
                .accessibilityValue(viewMode.rawValue)
                .accessibilityHint("Select which side of the slide rule to display")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            
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
            // Hide the List's default opaque scroll background to allow
            // the Liquid Glass translucency effect to show through
            .scrollContentBackground(.hidden)
            .navigationTitle("Slide Rules")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            #endif
            .onAppear {
                initializeLibraryIfNeeded()
            }
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Menu("Export Front Side") {
                        Button("Full Size (9.84\")") {
                            exportToPDF(side: .frontOnly, size: .full)
                        }
                        Button("Pocket Size (4.92\")") {
                            exportToPDF(side: .frontOnly, size: .pocket)
                        }
                    }
                    
                    if hasBackSide {
                        Menu("Export Back Side") {
                            Button("Full Size (9.84\")") {
                                exportToPDF(side: .backOnly, size: .full)
                            }
                            Button("Pocket Size (4.92\")") {
                                exportToPDF(side: .backOnly, size: .pocket)
                            }
                        }
                        
                        Menu("Export Both Sides") {
                            Button("Full Size (9.84\")") {
                                exportToPDF(side: .both, size: .full)
                            }
                            Button("Pocket Size (4.92\")") {
                                exportToPDF(side: .both, size: .pocket)
                            }
                        }
                    }
                } label: {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedRule == nil)
            }
        }
        #endif
        // MARK: - Liquid Glass Translucency (iOS 26+)
        // Apply thin material background to make sidebar translucent on iOS
        // The detail content extended beneath via .ignoresSafeArea() and .backgroundExtensionEffect()
        // will show through the sidebar with the characteristic glass blur
        // Note: .containerBackground(_:for: .navigation) is only available on iOS/iPadOS 18+
        #if os(iOS)
        .containerBackground(.thinMaterial, for: .navigation)
        #endif
    }
    
    /// Initialize or update library with standard rules
    /// Detects version changes and updates modified rules
    private func initializeLibraryIfNeeded() {
        let standardRules = SlideRuleLibrary.standardRules()
        
        // Clean up rules with old names that have been renamed
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
                        existingRule.manufacturer = standardRule.manufacturer  // Sync manufacturer
                        // Sync configuration JSON (Phase 6 - full configuration system)
                        existingRule.configurationJSON = standardRule.configurationJSON
                        // Legacy annotation features (keeping for backward compatibility)
                        existingRule.backSlideAnnotationsJSON = standardRule.backSlideAnnotationsJSON
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

// MARK: - PDF Export Methods

#if os(macOS)
extension SlideRuleSidebarView {
    
    /// Trigger PDF export for the currently selected slide rule
    private func exportToPDF(side: PDFExportConfiguration.ExportSide, size: PDFExportConfiguration.Size) {
        guard let selectedRule = selectedRule else {
            presentError(message: "No slide rule selected")
            return
        }
        
        // Parse slide rule definition with correct scale length for the chosen size
        let scaleLength = size.lengthInPoints
        guard let slideRule = try? parseSlideRule(from: selectedRule, length: scaleLength) else {
            presentError(message: "Failed to parse slide rule definition")
            return
        }
        
        // Create configuration
        let config = PDFExportConfiguration(
            size: size,
            side: side,
            slideRule: slideRule,
            slideRuleName: selectedRule.name
        )
        
        // Present save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Export Slide Rule to PDF"
        savePanel.message = "Choose where to save the PDF"
        savePanel.nameFieldStringValue = "\(selectedRule.name).pdf"
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else {
                return
            }
            
            // Generate PDF in background
            Task {
                do {
                    try PDFGenerator.generate(config: config, to: url)
                    await MainActor.run {
                        presentSuccess(message: "PDF exported successfully to \(url.lastPathComponent)")
                    }
                } catch {
                    await MainActor.run {
                        presentError(message: "Export failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func parseSlideRule(from model: SlideRuleDefinitionModel, length: Distance) throws -> SlideRule {
        // Use model's parseSlideRule() to include all post-processing:
        // - Scale name overrides
        // - Even-indexed scale name suppression
        // - Back slide annotations
        return try model.parseSlideRule(scaleLength: length)
    }
    
    private func presentError(message: String) {
        let alert = NSAlert()
        alert.messageText = "PDF Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func presentSuccess(message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Complete"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
#endif
