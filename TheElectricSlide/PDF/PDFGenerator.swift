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
            try renderFrontPage(renderContext: renderContext, config: config)
            
        case .backOnly:
            guard config.slideRule.backTopStator != nil else {
                throw PDFError.noBackSide
            }
            try renderBackPage(renderContext: renderContext, config: config)
            
        case .both:
            try renderFrontPage(renderContext: renderContext, config: config)
            if config.slideRule.backTopStator != nil {
                try renderBackPage(renderContext: renderContext, config: config)
            }
        }
        
        // Close PDF
        context.closePDF()
    }
    
    // MARK: - Page Rendering
    
    private static func renderFrontPage(
        renderContext: PDFRenderContext,
        config: PDFExportConfiguration
    ) throws {
        renderContext.beginPage()
        
        let totalHeight = CGFloat(config.totalRuleHeight(for: .frontOnly))
        let contentOffsetY = (CGFloat(config.pageHeight) - totalHeight) / 2
        let contentOffsetX = CGFloat(config.contentOffsetX)
        let contentWidth = CGFloat(config.scaleDrawingWidth)
        
        // Render title (above content)
        renderContext.drawTitle("Front Side - \(config.slideRuleName)", at: CGPoint(x: contentOffsetX, y: contentOffsetY + totalHeight + 24))
        
        // Calculate vertical positions (starting from top of content area)
        var currentY = contentOffsetY + totalHeight
        
        // Top Stator
        currentY = try renderComponent(
            component: config.slideRule.frontTopStator,
            at: currentY,
            renderContext: renderContext,
            config: config
        )
        currentY -= 4 // Spacing between components
        
        // Slide
        currentY = try renderComponent(
            component: config.slideRule.frontSlide,
            at: currentY,
            renderContext: renderContext,
            config: config
        )
        currentY -= 4 // Spacing between components
        
        // Bottom Stator
        _ = try renderComponent(
            component: config.slideRule.frontBottomStator,
            at: currentY,
            renderContext: renderContext,
            config: config
        )
        
        // Draw registration marks at corners of scale area
        let contentRect = CGRect(x: contentOffsetX, y: contentOffsetY, width: contentWidth, height: totalHeight)
        renderContext.drawRegistrationMarks(contentRect: contentRect)
        
        renderContext.endPage()
    }
    
    private static func renderBackPage(
        renderContext: PDFRenderContext,
        config: PDFExportConfiguration
    ) throws {
        renderContext.beginPage()
        
        let totalHeight = CGFloat(config.totalRuleHeight(for: .backOnly))
        let contentOffsetY = (CGFloat(config.pageHeight) - totalHeight) / 2
        let contentOffsetX = CGFloat(config.contentOffsetX)
        let contentWidth = CGFloat(config.scaleDrawingWidth)
        
        // Render title
        renderContext.drawTitle("Back Side - \(config.slideRuleName)", at: CGPoint(x: contentOffsetX, y: contentOffsetY + totalHeight + 24))
        
        var currentY = contentOffsetY + totalHeight
        
        // Back side components (if present)
        if let topStator = config.slideRule.backTopStator {
            currentY = try renderComponent(
                component: topStator,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
            currentY -= 4
        }
        
        if let slide = config.slideRule.backSlide {
            currentY = try renderComponent(
                component: slide,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
            currentY -= 4
        }
        
        if let bottomStator = config.slideRule.backBottomStator {
            _ = try renderComponent(
                component: bottomStator,
                at: currentY,
                renderContext: renderContext,
                config: config
            )
        }
        
        // Draw registration marks
        let contentRect = CGRect(x: contentOffsetX, y: contentOffsetY, width: contentWidth, height: totalHeight)
        renderContext.drawRegistrationMarks(contentRect: contentRect)
        
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
        
        for scale in component.scales {
            let actualHeight = CGFloat(scale.definition.height)
            try ScalePDFRenderer.render(
                scale: scale,
                at: CGPoint(x: CGFloat(config.leftMargin), y: currentY - actualHeight),
                width: CGFloat(config.scaleDrawingWidth),
                height: actualHeight,
                renderContext: renderContext
            )
            currentY -= (actualHeight + 4)  // 4pt spacing between scales
        }
        
        return currentY
    }
}
