//
//  PDFExportSheet.swift
//  TheElectricSlide
//
//  SwiftUI modal for PDF export options with native file save dialog.
//  Supports both macOS (NSSavePanel) and iOS (share sheet).
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import SlideRuleCoreV3

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - PDF Export Sheet

/// Modal view for configuring and exporting slide rule PDFs
struct PDFExportSheet: View {
    
    // MARK: - Properties
    
    let rule: SlideRuleDefinitionModel
    
    @State private var selectedSize: RuleSize = .fullSize
    @State private var showCropMarks: Bool = true
    @State private var isExporting: Bool = false
    @State private var exportError: PDFExportError?
    @State private var showingError: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Rule info section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rule.name)
                            .font(.headline)
                        Text(rule.ruleDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Slide Rule")
                }
                
                // Size selection
                Section {
                    Picker("Scale Length", selection: $selectedSize) {
                        ForEach(RuleSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Display actual dimensions
                    HStack {
                        Text("Scale Length")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(selectedSize == .fullSize ? "10 inches (254mm)" : "6 inches (152mm)")
                            .font(.callout)
                    }
                    
                    HStack {
                        Text("Page Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Tabloid (11\" × 17\") Landscape")
                            .font(.callout)
                    }
                } header: {
                    Text("Dimensions")
                } footer: {
                    Text("Full-size matches standard 10\" slide rules. Pocket size matches 6\" pocket rules.")
                }
                
                // Options
                Section {
                    Toggle("Include Crop Marks", isOn: $showCropMarks)
                    Toggle("Include Registration Marks", isOn: $showCropMarks)
                        .disabled(true)  // Tied to crop marks
                        .foregroundStyle(showCropMarks ? .primary : .secondary)
                } header: {
                    Text("Print Guides")
                } footer: {
                    Text("Crop marks show where to cut. Registration marks help align front and back when printing duplex.")
                }
                
                // Layout preview
                Section {
                    VStack(spacing: 12) {
                        // Simple preview diagram
                        layoutPreview
                            .frame(height: 120)
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } header: {
                    Text("Layout Preview")
                } footer: {
                    Text("Both front and back sides will be printed on a single page.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Generate PDF")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await exportPDF()
                        }
                    } label: {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Export PDF")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }
    
    // MARK: - Layout Preview
    
    private var layoutPreview: some View {
        GeometryReader { geometry in
            let width = geometry.size.width - 24
            let height = geometry.size.height - 24
            let sideHeight = (height - 8) / 2
            
            VStack(spacing: 8) {
                // Front side preview
                HStack(spacing: 4) {
                    Text("FRONT")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                    
                    VStack(spacing: 1) {
                        previewBar(label: "Stator", height: sideHeight * 0.3)
                        previewBar(label: "Slide", height: sideHeight * 0.4, isSlide: true)
                        previewBar(label: "Stator", height: sideHeight * 0.3)
                    }
                    .frame(width: width - 40)
                }
                
                // Separator
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .overlay {
                        if showCropMarks {
                            Text("✂︎")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                
                // Back side preview
                HStack(spacing: 4) {
                    Text("BACK")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                    
                    VStack(spacing: 1) {
                        previewBar(label: "Stator", height: sideHeight * 0.3)
                        previewBar(label: "Slide", height: sideHeight * 0.4, isSlide: true)
                        previewBar(label: "Stator", height: sideHeight * 0.3)
                    }
                    .frame(width: width - 40)
                }
            }
            .padding(12)
        }
    }
    
    private func previewBar(label: String, height: CGFloat, isSlide: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isSlide ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
            .frame(height: height)
            .overlay {
                Text(label)
                    .font(.system(size: 6))
                    .foregroundStyle(.secondary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
    }
    
    // MARK: - Export Logic
    
    @MainActor
    private func exportPDF() async {
        isExporting = true
        
        do {
            // Create configuration
            let configuration = PDFExportConfiguration.forRuleSize(selectedSize, showCropMarks: showCropMarks)
            
            // Parse the slide rule on main thread (SwiftData models aren't Sendable)
            let slideRule = try rule.parseSlideRule(scaleLength: Double(selectedSize.scaleLength))
            let ruleName = rule.name
            
            // Create exporter and generate PDF
            let exporter = SlideRulePDFExporter(configuration: configuration)
            let pdfData = try exporter.generatePDF(for: slideRule, ruleName: ruleName)
            
            // Save file
            try await savePDF(data: pdfData)
            
            // Dismiss on success
            isExporting = false
            dismiss()
            
        } catch let error as PDFExportError {
            isExporting = false
            exportError = error
            showingError = true
        } catch {
            isExporting = false
            exportError = .renderingError(error.localizedDescription)
            showingError = true
        }
    }
    
    @MainActor
    private func savePDF(data: Data) async throws {
        let filename = "\(rule.name)-\(selectedSize.filenameSuffix).pdf"
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        
        #if os(macOS)
        try await savePDFMacOS(data: data, filename: filename)
        #else
        try await savePDFiOS(data: data, filename: filename)
        #endif
    }
    
    #if os(macOS)
    @MainActor
    private func savePDFMacOS(data: Data, filename: String) async throws {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = filename
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Save Slide Rule PDF"
        panel.message = "Choose a location to save the PDF"
        
        // Use standalone panel (works better with sheets)
        let response = await panel.begin()
        
        guard response == .OK, let url = panel.url else {
            return  // User cancelled
        }
        
        do {
            try data.write(to: url)
            
            // Optionally reveal in Finder
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            throw PDFExportError.fileSystemError(error.localizedDescription)
        }
    }
    #else
    @MainActor
    private func savePDFiOS(data: Data, filename: String) async throws {
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
        } catch {
            throw PDFExportError.fileSystemError(error.localizedDescription)
        }
        
        // Present share sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw PDFExportError.renderingError("Could not present share sheet")
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        
        // For iPad, configure popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true)
    }
    #endif
}

// MARK: - Preview

#Preview {
    PDFExportSheet(
        rule: SlideRuleLibrary.keuffelEsser4081_3()
    )
}
