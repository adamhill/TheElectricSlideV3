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
    
    /// Draw registration marks at corners with cross marks
    /// Cross marks: 5mm offset from corners, 10mm line length, 0.5pt stroke width
    func drawRegistrationMarks(contentRect: CGRect) {
        let offset: CGFloat = 5.0 * 2.83465      // 5mm offset from corner in points
        let lineLength: CGFloat = 10.0 * 2.83465 // 10mm line length in points
        let lineWidth: CGFloat = 0.5              // 0.5pt stroke width
        let color = CGColor(gray: 0, alpha: 1)
        
        // Corner positions with offset
        let corners = [
            // Top left
            CGPoint(x: contentRect.minX, y: contentRect.maxY),
            // Top right
            CGPoint(x: contentRect.maxX, y: contentRect.maxY),
            // Bottom left
            CGPoint(x: contentRect.minX, y: contentRect.minY),
            // Bottom right
            CGPoint(x: contentRect.maxX, y: contentRect.minY)
        ]
        
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(lineWidth)
        
        for (index, corner) in corners.enumerated() {
            // Determine offset directions based on corner position
            let xDir: CGFloat = (index == 0 || index == 2) ? -1 : 1  // Left corners: -1, Right corners: 1
            let yDir: CGFloat = (index == 0 || index == 1) ? 1 : -1  // Top corners: 1, Bottom corners: -1
            
            let markCenter = CGPoint(
                x: corner.x + (offset * xDir),
                y: corner.y + (offset * yDir)
            )
            
            // Draw horizontal line of cross
            let hStart = CGPoint(x: markCenter.x - lineLength / 2, y: markCenter.y)
            let hEnd = CGPoint(x: markCenter.x + lineLength / 2, y: markCenter.y)
            context.move(to: hStart)
            context.addLine(to: hEnd)
            
            // Draw vertical line of cross
            let vStart = CGPoint(x: markCenter.x, y: markCenter.y - lineLength / 2)
            let vEnd = CGPoint(x: markCenter.x, y: markCenter.y + lineLength / 2)
            context.move(to: vStart)
            context.addLine(to: vEnd)
        }
        
        context.strokePath()
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
