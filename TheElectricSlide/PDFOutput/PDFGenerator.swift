// File: TheElectricSlide/PDF/PDFGenerator.swift

import CoreGraphics
import Foundation
import SlideRuleCoreV3

/// Main PDF generation coordinator
enum PDFGenerator {
    
    /// Error types for PDF generation
    enum PDFError: Error, LocalizedError {
        case cannotCreateFile(URL)
        case cannotCreateContext
        case renderingFailed(String)
        case noBackSide
        
        var errorDescription: String? {
            switch self {
            case .cannotCreateFile(let url):
                return "Cannot create PDF file at: \(url.path)"
            case .cannotCreateContext:
                return "Failed to create PDF graphics context"
            case .renderingFailed(let reason):
                return "PDF rendering failed: \(reason)"
            case .noBackSide:
                return "This slide rule has no back side to export"
            }
        }
    }
    
    // MARK: - Main Generation Method
    
    /// Generate a PDF file from the given configuration
    /// - Parameters:
    ///   - config: Export configuration
    ///   - fileURL: Destination file URL
    /// - Throws: PDFError if generation fails
    static func generate(
        config: PDFExportConfiguration,
        to fileURL: URL
    ) throws {
        // Create CGDataConsumer
        guard let dataConsumer = CGDataConsumer(url: fileURL as CFURL) else {
            throw PDFError.cannotCreateFile(fileURL)
        }
        
        // PDF document info
        var mediaBox = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(config.pageWidth),
            height: CGFloat(config.pageHeight)
        )
        
        let pdfInfo: [CFString: Any] = [
            kCGPDFContextTitle: config.title,
            kCGPDFContextAuthor: config.author,
            kCGPDFContextCreator: config.creator
        ]
        
        // Create PDF context
        guard let context = CGContext(consumer: dataConsumer, mediaBox: &mediaBox, pdfInfo as CFDictionary) else {
            throw PDFError.cannotCreateContext
        }
        
        // Wrap in helper
        let renderContext = PDFRenderContext(context: context, config: config)
        
        // Render pages based on configuration
        switch config.side {
        case .frontOnly:
            try renderSingleSidePage(renderContext: renderContext, config: config, isFront: true)
            
        case .backOnly:
            guard config.slideRule.backTopStator != nil else {
                throw PDFError.noBackSide
            }
            try renderSingleSidePage(renderContext: renderContext, config: config, isFront: false)
            
        case .both:
            guard config.slideRule.backTopStator != nil else {
                throw PDFError.noBackSide
            }
            try renderBothSidesPage(renderContext: renderContext, config: config)
        }
        
        // Close PDF
        context.closePDF()
    }
    
    // MARK: - Page Rendering
    
    /// Render a single-side page (front only or back only) with unified title
    private static func renderSingleSidePage(
        renderContext: PDFRenderContext,
        config: PDFExportConfiguration,
        isFront: Bool
    ) throws {
        renderContext.beginPage()
        
        let totalHeight = CGFloat(config.totalRuleHeight(for: isFront ? .frontOnly : .backOnly))
        let contentOffsetY = (CGFloat(config.pageHeight) - totalHeight) / 2
        let contentOffsetX = CGFloat(config.contentOffsetX)
        let contentWidth = CGFloat(config.scaleDrawingWidth)
        
        // Render unified title (above content) - no "Front Side" or "Back Side" prefix
        renderContext.drawTitle(config.slideRuleName, at: CGPoint(x: contentOffsetX, y: contentOffsetY + totalHeight + 24))
        
        // Render content
        var currentY = contentOffsetY + totalHeight
        
        if isFront {
            // Front side components
            currentY = try renderComponent(
                component: config.slideRule.frontTopStator,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
            currentY -= CGFloat(config.spacingBetweenComponents())
            
            currentY = try renderComponent(
                component: config.slideRule.frontSlide,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
            currentY -= CGFloat(config.spacingBetweenComponents())
            
            _ = try renderComponent(
                component: config.slideRule.frontBottomStator,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
        } else {
            // Back side components
            if let topStator = config.slideRule.backTopStator {
                currentY = try renderComponent(
                    component: topStator,
                    at: currentY,
                    renderContext: renderContext,
                    config: config
                )
                currentY -= CGFloat(config.spacingBetweenComponents())
            }
            
            if let slide = config.slideRule.backSlide {
                currentY = try renderComponent(
                    component: slide,
                    at: currentY,
                    renderContext: renderContext,
                    config: config
                )
                currentY -= CGFloat(config.spacingBetweenComponents())
            }
            
            if let bottomStator = config.slideRule.backBottomStator {
                _ = try renderComponent(
                    component: bottomStator,
                    at: currentY,
                    renderContext: renderContext,
                    config: config
                )
            }
        }
        
        // Draw registration marks at corners
        let contentRect = CGRect(x: contentOffsetX, y: contentOffsetY, width: contentWidth, height: totalHeight)
        renderContext.drawRegistrationMarks(contentRect: contentRect)
        
        renderContext.endPage()
    }
    
    /// Render both sides on a single page with unified title
    private static func renderBothSidesPage(
        renderContext: PDFRenderContext,
        config: PDFExportConfiguration
    ) throws {
        renderContext.beginPage()
        
        let frontHeight = CGFloat(config.totalRuleHeight(for: .frontOnly))
        let backHeight = CGFloat(config.totalRuleHeight(for: .backOnly))
        let gapBetweenSides: CGFloat = 36.0  // 36pt gap between front and back
        let totalContentHeight = frontHeight + gapBetweenSides + backHeight
        
        let contentOffsetX = CGFloat(config.contentOffsetX)
        let contentWidth = CGFloat(config.scaleDrawingWidth)
        let contentOffsetY = (CGFloat(config.pageHeight) - totalContentHeight) / 2
        
        // Render unified title at top (above all content)
        let titleY = contentOffsetY + totalContentHeight + 24
        renderContext.drawTitle(config.slideRuleName, at: CGPoint(x: contentOffsetX, y: titleY))
        
        // Render front side at top
        var currentY = contentOffsetY + totalContentHeight
        let frontTopY = currentY
        
        currentY = try renderComponent(
            component: config.slideRule.frontTopStator,
            at: currentY,
            renderContext: renderContext,
            config: config
        )
        currentY -= CGFloat(config.spacingBetweenComponents())
        
        currentY = try renderComponent(
            component: config.slideRule.frontSlide,
            at: currentY,
            renderContext: renderContext,
            config: config
        )
        currentY -= CGFloat(config.spacingBetweenComponents())
        
        currentY = try renderComponent(
            component: config.slideRule.frontBottomStator,
            at: currentY,
            renderContext: renderContext,
            config: config
        )
        
        // Gap between front and back
        currentY -= gapBetweenSides
        
        // Render back side below front
        let backTopY = currentY
        
        if let topStator = config.slideRule.backTopStator {
            currentY = try renderComponent(
                component: topStator,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
            currentY -= CGFloat(config.spacingBetweenComponents())
        }
        
        if let slide = config.slideRule.backSlide {
            currentY = try renderComponent(
                component: slide,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
            currentY -= CGFloat(config.spacingBetweenComponents())
        }
        
        if let bottomStator = config.slideRule.backBottomStator {
            _ = try renderComponent(
                component: bottomStator,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
        }
        
        // Draw registration marks for front side
        let frontRect = CGRect(x: contentOffsetX, y: frontTopY - frontHeight, width: contentWidth, height: frontHeight)
        renderContext.drawRegistrationMarks(contentRect: frontRect)
        
        // Draw registration marks for back side
        let backRect = CGRect(x: contentOffsetX, y: backTopY - backHeight, width: contentWidth, height: backHeight)
        renderContext.drawRegistrationMarks(contentRect: backRect)
        
        renderContext.endPage()
    }
    
    // MARK: - Component Rendering
    
    /// Render a Stator or Slide component
    /// - Returns: New Y position after rendering this component
    private static func renderComponent<T: ScaleContainer>(
        component: T,
        at yPosition: CGFloat,
        renderContext: PDFRenderContext,
        config: PDFExportConfiguration
    ) throws -> CGFloat {
        var currentY = yPosition
        
        for (index, scale) in component.scales.enumerated() {
            var actualHeight = CGFloat(scale.definition.height)
            
            // Increase C and D scale heights by ~1.76mm (5.0 points)
            if scale.definition.name == "C" || scale.definition.name == "D" {
                actualHeight += 5.0
            }
            
            try ScalePDFRenderer.render(
                scale: scale,
                at: CGPoint(x: CGFloat(config.leftMargin), y: currentY - actualHeight),
                width: CGFloat(config.scaleDrawingWidth),
                height: actualHeight,
                renderContext: renderContext
            )
            currentY -= actualHeight
            
            // Add spacing based on PostScript rules (C/D get extra spacing)
            if index < component.scales.count - 1 {
                let spacing = config.spacingBetweenScales(scale, component.scales[index + 1])
                currentY -= CGFloat(spacing)
            }
        }
        
        return currentY
    }
}
