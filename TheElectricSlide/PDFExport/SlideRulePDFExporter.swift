//
//  SlideRulePDFExporter.swift
//  TheElectricSlide
//
//  Orchestrates PDF document creation for slide rule scales.
//  Generates print-ready PDFs with accurate physical dimensions.
//
//  Layout: Both front and back sides on a single 8.5" × 11" page (landscape)
//  Scale lengths: 10" (full-size) or 6" (pocket) - configurable
//

import Foundation
import CoreGraphics
import CoreText
import SlideRuleCoreV3

// MARK: - Slide Rule PDF Exporter

/// Main PDF export service for slide rules
public final class SlideRulePDFExporter: Sendable {
    
    // MARK: - Properties
    
    public let configuration: PDFExportConfiguration
    private let scaleRenderer: PDFScaleRenderer
    private let cropMarkRenderer: PDFCropMarkRenderer
    
    // MARK: - Initializer
    
    public init(configuration: PDFExportConfiguration) {
        self.configuration = configuration
        self.scaleRenderer = PDFScaleRenderer(configuration: configuration)
        self.cropMarkRenderer = PDFCropMarkRenderer(configuration: configuration)
    }
    
    // MARK: - Public Export Methods
    
    /// Generate PDF data for a slide rule
    /// - Parameters:
    ///   - slideRule: The parsed SlideRule with generated scales
    ///   - ruleName: Name for labeling (e.g., "K&E 4081-3")
    /// - Returns: PDF data ready to save to file
    public func generatePDF(
        for slideRule: SlideRule,
        ruleName: String
    ) throws -> Data {
        // Calculate page layout
        let pageRect = CGRect(
            x: 0,
            y: 0,
            width: configuration.pageWidth,
            height: configuration.pageHeight
        )
        
        // Create PDF data
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            throw PDFExportError.contextCreationFailed
        }
        
        var mediaBox = pageRect
        
        // PDF metadata
        let pdfInfo: [CFString: Any] = [
            kCGPDFContextTitle: "\(ruleName) - Slide Rule Scales",
            kCGPDFContextCreator: "The Electric Slide",
            kCGPDFContextAuthor: "The Electric Slide App"
        ]
        
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, pdfInfo as CFDictionary) else {
            throw PDFExportError.contextCreationFailed
        }
        
        // Begin the PDF page
        context.beginPDFPage(nil)
        
        // Draw the slide rule
        try drawSlideRule(
            slideRule,
            ruleName: ruleName,
            in: context,
            pageRect: pageRect
        )
        
        // End page and close PDF
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
    
    // MARK: - Private Drawing Methods
    
    /// Draw complete slide rule (front and back sides)
    private func drawSlideRule(
        _ slideRule: SlideRule,
        ruleName: String,
        in context: CGContext,
        pageRect: CGRect
    ) throws {
        // Calculate content area (inside page margins)
        // PDF coordinates: origin at bottom-left, y increases upward
        let contentRect = CGRect(
            x: configuration.leftMargin,
            y: configuration.bottomMargin,
            width: pageRect.width - configuration.leftMargin - configuration.rightMargin,
            height: pageRect.height - configuration.topMargin - configuration.bottomMargin
        )
        
        // Draw crop marks and registration guides
        cropMarkRenderer.drawAll(
            context: context,
            contentRect: contentRect,
            pageRect: pageRect
        )
        
        // Calculate layout for front and back sides
        let layout = calculateLayout(for: slideRule, in: contentRect)
        
        // Draw title/rule name at top
        drawTitle(
            context: context,
            title: ruleName,
            at: CGPoint(x: pageRect.midX, y: configuration.topMargin - 12)
        )
        
        // Draw front side
        try drawSide(
            topStator: slideRule.frontTopStator,
            slide: slideRule.frontSlide,
            bottomStator: slideRule.frontBottomStator,
            sideLabel: "FRONT",
            in: context,
            layout: layout.frontLayout
        )
        
        // Draw separator line if back side exists
        if slideRule.backTopStator != nil {
            let separatorY = layout.frontLayout.totalRect.maxY + configuration.gapBetweenSides / 2
            cropMarkRenderer.drawSideSeparator(
                context: context,
                y: separatorY,
                pageRect: pageRect
            )
        }
        
        // Draw back side if exists
        if let backTop = slideRule.backTopStator,
           let backSlide = slideRule.backSlide,
           let backBottom = slideRule.backBottomStator {
            try drawSide(
                topStator: backTop,
                slide: backSlide,
                bottomStator: backBottom,
                sideLabel: "BACK",
                in: context,
                layout: layout.backLayout!
            )
        }
    }
    
    /// Draw one side of the slide rule (top stator + slide + bottom stator)
    private func drawSide(
        topStator: Stator,
        slide: Slide,
        bottomStator: Stator,
        sideLabel: String,
        in context: CGContext,
        layout: SideLayout
    ) throws {
        // Draw side label
        cropMarkRenderer.drawSideLabel(
            context: context,
            text: sideLabel,
            at: CGPoint(x: layout.scaleOriginX - 20, y: layout.totalRect.midY),
            alignment: .right
        )
        
        // Draw top stator
        drawStator(
            topStator,
            in: context,
            origin: layout.topStatorOrigin,
            width: configuration.scaleLength,
            height: layout.topStatorHeight
        )
        
        // Draw slide with visual indicator (slightly offset or bordered)
        drawSlide(
            slide,
            in: context,
            origin: layout.slideOrigin,
            width: configuration.scaleLength,
            height: layout.slideHeight
        )
        
        // Draw bottom stator
        drawStator(
            bottomStator,
            in: context,
            origin: layout.bottomStatorOrigin,
            width: configuration.scaleLength,
            height: layout.bottomStatorHeight
        )
        
        // Draw border around the entire side
        drawSideBorder(
            context: context,
            rect: layout.totalRect
        )
    }
    
    /// Draw a stator (fixed portion with multiple scales)
    private func drawStator(
        _ stator: Stator,
        in context: CGContext,
        origin: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {
        let scaleCount = stator.scales.count
        guard scaleCount > 0 else { return }
        
        let scaleHeight = height / CGFloat(scaleCount)
        
        // Render scales top-to-bottom: first scale at highest y, last scale at lowest y
        // In PDF coordinates, y increases upward, so we start from the top
        for (index, generatedScale) in stator.scales.enumerated() {
            let scaleOriginY = origin.y + height - CGFloat(index + 1) * scaleHeight
            let scaleOrigin = CGPoint(x: origin.x, y: scaleOriginY)
            
            // Draw scale name in left margin
            scaleRenderer.drawScaleName(
                context: context,
                name: generatedScale.definition.displayName ?? generatedScale.definition.name,
                at: CGPoint(x: scaleOrigin.x, y: scaleOriginY),
                height: scaleHeight,
                definition: generatedScale.definition
            )
            
            // Draw scale ticks and labels
            scaleRenderer.drawScale(
                generatedScale,
                in: context,
                at: scaleOrigin,
                width: width,
                height: scaleHeight
            )
            
            // Draw formula in right margin
            scaleRenderer.drawFormula(
                context: context,
                formula: generatedScale.definition.formula,
                at: scaleOrigin,
                width: width,
                height: scaleHeight,
                definition: generatedScale.definition
            )
        }
    }
    
    /// Draw a slide (movable portion with multiple scales)
    private func drawSlide(
        _ slide: Slide,
        in context: CGContext,
        origin: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {
        // Draw slide background (slight gray to differentiate from stators)
        context.saveGState()
        context.setFillColor(CGColor(gray: 0.97, alpha: 1))
        context.fill(CGRect(x: origin.x - 2, y: origin.y, width: width + 4, height: height))
        context.restoreGState()
        
        // Draw slide border
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0.3, alpha: 1))
        context.setLineWidth(0.5)
        context.stroke(CGRect(x: origin.x - 2, y: origin.y, width: width + 4, height: height))
        context.restoreGState()
        
        let scaleCount = slide.scales.count
        guard scaleCount > 0 else { return }
        
        let scaleHeight = height / CGFloat(scaleCount)
        
        // Render scales top-to-bottom: first scale at highest y, last scale at lowest y
        // In PDF coordinates, y increases upward, so we start from the top
        for (index, generatedScale) in slide.scales.enumerated() {
            let scaleOriginY = origin.y + height - CGFloat(index + 1) * scaleHeight
            let scaleOrigin = CGPoint(x: origin.x, y: scaleOriginY)
            
            // Draw scale name in left margin
            scaleRenderer.drawScaleName(
                context: context,
                name: generatedScale.definition.displayName ?? generatedScale.definition.name,
                at: CGPoint(x: scaleOrigin.x, y: scaleOriginY),
                height: scaleHeight,
                definition: generatedScale.definition
            )
            
            // Draw scale ticks and labels
            scaleRenderer.drawScale(
                generatedScale,
                in: context,
                at: scaleOrigin,
                width: width,
                height: scaleHeight
            )
            
            // Draw formula in right margin
            scaleRenderer.drawFormula(
                context: context,
                formula: generatedScale.definition.formula,
                at: scaleOrigin,
                width: width,
                height: scaleHeight,
                definition: generatedScale.definition
            )
        }
    }
    
    /// Draw border around an entire side
    private func drawSideBorder(context: CGContext, rect: CGRect) {
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(1.0)
        context.stroke(rect)
        context.restoreGState()
    }
    
    /// Draw title at top of page
    private func drawTitle(context: CGContext, title: String, at position: CGPoint) {
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 12, nil)
        
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: CGColor(gray: 0, alpha: 1)
        ]
        
        let attributedString = CFAttributedStringCreate(nil, title as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        let x = position.x - bounds.width / 2
        
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: position.y)
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
    // MARK: - Layout Calculation
    
    /// Calculate layout for front and back sides
    private func calculateLayout(
        for slideRule: SlideRule,
        in contentRect: CGRect
    ) -> (frontLayout: SideLayout, backLayout: SideLayout?) {
        // Calculate heights based on stator/slide MM values
        // PostScript reference: [14 mm 13 mm 14 mm] for K&E 4081-3
        
        let hasBackSide = slideRule.backTopStator != nil
        
        // Available height per side
        let availableHeight: CGFloat
        if hasBackSide {
            availableHeight = (contentRect.height - configuration.gapBetweenSides) / 2
        } else {
            availableHeight = contentRect.height
        }
        
        // Front side layout
        let frontLayout = calculateSideLayout(
            topStator: slideRule.frontTopStator,
            slide: slideRule.frontSlide,
            bottomStator: slideRule.frontBottomStator,
            originY: contentRect.minY,
            availableHeight: availableHeight,
            scaleOriginX: contentRect.minX + configuration.leftMargin
        )
        
        // Back side layout (if exists)
        var backLayout: SideLayout?
        if let backTop = slideRule.backTopStator,
           let backSlide = slideRule.backSlide,
           let backBottom = slideRule.backBottomStator {
            backLayout = calculateSideLayout(
                topStator: backTop,
                slide: backSlide,
                bottomStator: backBottom,
                originY: frontLayout.totalRect.maxY + configuration.gapBetweenSides,
                availableHeight: availableHeight,
                scaleOriginX: contentRect.minX + configuration.leftMargin
            )
        }
        
        return (frontLayout, backLayout)
    }
    
    /// Calculate layout for a single side
    private func calculateSideLayout(
        topStator: Stator,
        slide: Slide,
        bottomStator: Stator,
        originY: CGFloat,
        availableHeight: CGFloat,
        scaleOriginX: CGFloat
    ) -> SideLayout {
        // Calculate proportional heights based on MM values
        let topMM = topStator.heightInPoints / kPointsPerMM
        let slideMM = slide.heightInPoints / kPointsPerMM
        let bottomMM = bottomStator.heightInPoints / kPointsPerMM
        let totalMM = topMM + slideMM + bottomMM
        
        let topHeight = availableHeight * (topMM / totalMM)
        let slideHeight = availableHeight * (slideMM / totalMM)
        let bottomHeight = availableHeight * (bottomMM / totalMM)
        
        // In PDF coordinates, y increases upward, so:
        // - Top stator should be at highest y (visual top)
        // - Bottom stator should be at lowest y (visual bottom)
        let bottomOrigin = CGPoint(x: scaleOriginX, y: originY)
        let slideOrigin = CGPoint(x: scaleOriginX, y: originY + bottomHeight)
        let topOrigin = CGPoint(x: scaleOriginX, y: originY + bottomHeight + slideHeight)
        
        let totalRect = CGRect(
            x: scaleOriginX - configuration.leftMargin,
            y: originY,
            width: configuration.contentWidth,
            height: availableHeight
        )
        
        return SideLayout(
            topStatorOrigin: topOrigin,
            topStatorHeight: topHeight,
            slideOrigin: slideOrigin,
            slideHeight: slideHeight,
            bottomStatorOrigin: bottomOrigin,
            bottomStatorHeight: bottomHeight,
            scaleOriginX: scaleOriginX,
            totalRect: totalRect
        )
    }
}

// MARK: - Layout Structures

/// Layout information for one side of the slide rule
private struct SideLayout {
    let topStatorOrigin: CGPoint
    let topStatorHeight: CGFloat
    let slideOrigin: CGPoint
    let slideHeight: CGFloat
    let bottomStatorOrigin: CGPoint
    let bottomStatorHeight: CGFloat
    let scaleOriginX: CGFloat
    let totalRect: CGRect
}

// MARK: - Convenience Extension

extension SlideRulePDFExporter {
    
    /// Generate PDF from a SlideRuleDefinitionModel
    func generatePDF(
        from model: SlideRuleDefinitionModel,
        scaleLength: CGFloat? = nil
    ) throws -> Data {
        let length = scaleLength ?? configuration.scaleLength
        
        do {
            let slideRule = try model.parseSlideRule(scaleLength: Double(length))
            return try generatePDF(for: slideRule, ruleName: model.name)
        } catch {
            throw PDFExportError.parseError(error.localizedDescription)
        }
    }
}
