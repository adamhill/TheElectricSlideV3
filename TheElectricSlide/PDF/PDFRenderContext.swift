// File: TheElectricSlide/PDF/PDFRenderContext.swift

import CoreGraphics
import CoreText
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Convenient wrapper around CGContext for PDF rendering
struct PDFRenderContext {
    let context: CGContext
    let config: PDFExportConfiguration
    
    // MARK: - Page Management
    
    func beginPage() {
        context.beginPDFPage(nil)
    }
    
    func endPage() {
        context.endPDFPage()
    }
    
    // MARK: - Drawing Primitives
    
    /// Draw a line from start to end
    func drawLine(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat = 0.5, color: CGColor = CGColor(gray: 0, alpha: 1)) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(lineWidth)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
    }
    
    /// Draw a path
    func strokePath(_ path: CGPath, lineWidth: CGFloat = 0.5, color: CGColor = CGColor(gray: 0, alpha: 1)) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(lineWidth)
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }
    
    // MARK: - Text Rendering
    
    /// Draw text at specified position with optional transform (e.g., skew for italic)
    func drawText(
        _ text: String,
        at position: CGPoint,
        fontSize: CGFloat,
        fontName: String = "Helvetica",
        color: CGColor = CGColor(gray: 0, alpha: 1),
        transform: CGAffineTransform? = nil
    ) {
        context.saveGState()
        
        // Apply custom transform if provided (for italic text)
        if let transform = transform {
            context.concatenate(transform)
        }
        
        context.setFillColor(color)
        
        // Create font
        guard let font = CGFont(fontName as CFString) else {
            context.restoreGState()
            return
        }
        context.setFont(font)
        context.setFontSize(fontSize)
        
        // Position text - PDF coordinate system has origin at bottom-left
        context.textPosition = position
        
        // Draw text
        let glyphs = text.utf16.map { CGGlyph($0) }
        context.showGlyphs(glyphs, at: [])
        
        context.restoreGState()
    }
    
    /// Draw text using CoreText for better rendering quality
    func drawTextCoreText(
        _ text: String,
        at position: CGPoint,
        fontSize: CGFloat,
        fontName: String = "Helvetica",
        color: CGColor = CGColor(gray: 0, alpha: 1),
        skewAmount: CGFloat = 0  // Horizontal skew amount (c value in transform)
    ) {
        context.saveGState()
        
        // Create attributed string
        let attributes: [NSAttributedString.Key: Any] = [
            .font: CTFontCreateWithName(fontName as CFString, fontSize, nil),
            .foregroundColor: color
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)
        
        // Apply skew for italic if needed
        if skewAmount != 0 {
            var transform = CGAffineTransform.identity
            transform.c = skewAmount  // Horizontal skew (x' = x + c*y)
            context.concatenate(transform)
        }
        
        // Set position and draw
        context.textPosition = position
        CTLineDraw(line, context)
        
        context.restoreGState()
    }
    
    // MARK: - Helper Methods
    
    /// Draw registration marks at the corners of the specified rect
    func drawRegistrationMarks(contentRect: CGRect) {
        let markSize: CGFloat = 24
        let circleRadius: CGFloat = 8
        let lineWidth: CGFloat = 0.25
        let color = CGColor(gray: 0, alpha: 1)
        
        let corners = [
            CGPoint(x: contentRect.minX, y: contentRect.minY),
            CGPoint(x: contentRect.maxX, y: contentRect.minY),
            CGPoint(x: contentRect.minX, y: contentRect.maxY),
            CGPoint(x: contentRect.maxX, y: contentRect.maxY)
        ]
        
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(lineWidth)
        
        for corner in corners {
            // Draw crosshairs
            context.move(to: CGPoint(x: corner.x - markSize/2, y: corner.y))
            context.addLine(to: CGPoint(x: corner.x + markSize/2, y: corner.y))
            
            context.move(to: CGPoint(x: corner.x, y: corner.y - markSize/2))
            context.addLine(to: CGPoint(x: corner.x, y: corner.y + markSize/2))
            
            // Draw circle
            context.addEllipse(in: CGRect(
                x: corner.x - circleRadius,
                y: corner.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
            
            context.strokePath()
        }
        
        context.restoreGState()
    }

    /// Draw a title at the top of the page
    func drawTitle(_ title: String, at position: CGPoint) {
        drawTextCoreText(
            title,
            at: position,
            fontSize: 14,
            fontName: "Helvetica-Bold"
        )
    }
    
    /// Measure text width for positioning
    func measureText(
        _ text: String,
        fontSize: CGFloat,
        fontName: String = "Helvetica"
    ) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: CTFontCreateWithName(fontName as CFString, fontSize, nil)
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrString)
        
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        return bounds.size
    }
}
