//
//  PDFCropMarkRenderer.swift
//  TheElectricSlide
//
//  Renders crop marks and registration guides for precise cutting
//  and alignment when printing slide rule labels.
//
//  Crop marks indicate where to cut the paper.
//  Registration marks help align front and back when printing duplex.
//

import Foundation
import CoreGraphics
import CoreText

// MARK: - PDF Crop Mark Renderer

/// Renders crop marks and registration guides to a Core Graphics context
public struct PDFCropMarkRenderer: Sendable {
    
    // MARK: - Properties
    
    public let configuration: PDFExportConfiguration
    
    // MARK: - Initializer
    
    public init(configuration: PDFExportConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Drawing Methods
    
    /// Draw all crop marks and registration guides
    public func drawAll(
        context: CGContext,
        contentRect: CGRect,
        pageRect: CGRect
    ) {
        guard configuration.showCropMarks else { return }
        
        drawCropMarks(context: context, contentRect: contentRect)
        drawRegistrationMarks(context: context, pageRect: pageRect)
        drawCenterLines(context: context, contentRect: contentRect, pageRect: pageRect)
    }
    
    /// Draw corner crop marks indicating cut lines
    public func drawCropMarks(
        context: CGContext,
        contentRect: CGRect
    ) {
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(0.5)
        
        let offset = configuration.cropMarkOffset
        let length = configuration.cropMarkLength
        
        // Top-left corner
        drawCornerCropMark(
            context: context,
            corner: CGPoint(x: contentRect.minX, y: contentRect.minY),
            offset: offset,
            length: length,
            horizontalDirection: -1,  // Left
            verticalDirection: -1     // Up
        )
        
        // Top-right corner
        drawCornerCropMark(
            context: context,
            corner: CGPoint(x: contentRect.maxX, y: contentRect.minY),
            offset: offset,
            length: length,
            horizontalDirection: 1,   // Right
            verticalDirection: -1     // Up
        )
        
        // Bottom-left corner
        drawCornerCropMark(
            context: context,
            corner: CGPoint(x: contentRect.minX, y: contentRect.maxY),
            offset: offset,
            length: length,
            horizontalDirection: -1,  // Left
            verticalDirection: 1      // Down
        )
        
        // Bottom-right corner
        drawCornerCropMark(
            context: context,
            corner: CGPoint(x: contentRect.maxX, y: contentRect.maxY),
            offset: offset,
            length: length,
            horizontalDirection: 1,   // Right
            verticalDirection: 1      // Down
        )
        
        context.strokePath()
        context.restoreGState()
    }
    
    /// Draw registration marks for alignment (centered on each edge)
    public func drawRegistrationMarks(
        context: CGContext,
        pageRect: CGRect
    ) {
        let size = configuration.registrationMarkSize
        let halfSize = size / 2
        
        // Positions for registration marks (centered on each edge)
        let centers = [
            CGPoint(x: pageRect.midX, y: pageRect.minY + size + 4),   // Top center
            CGPoint(x: pageRect.midX, y: pageRect.maxY - size - 4),   // Bottom center
            CGPoint(x: pageRect.minX + size + 4, y: pageRect.midY),   // Left center
            CGPoint(x: pageRect.maxX - size - 4, y: pageRect.midY)    // Right center
        ]
        
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(0.5)
        
        for center in centers {
            // Draw circle
            let circleRect = CGRect(
                x: center.x - halfSize,
                y: center.y - halfSize,
                width: size,
                height: size
            )
            context.addEllipse(in: circleRect)
            context.strokePath()
            
            // Draw crosshairs
            // Horizontal line
            context.move(to: CGPoint(x: center.x - size, y: center.y))
            context.addLine(to: CGPoint(x: center.x + size, y: center.y))
            
            // Vertical line
            context.move(to: CGPoint(x: center.x, y: center.y - size))
            context.addLine(to: CGPoint(x: center.x, y: center.y + size))
            
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    /// Draw light center lines for alignment reference
    public func drawCenterLines(
        context: CGContext,
        contentRect: CGRect,
        pageRect: CGRect
    ) {
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0.7, alpha: 0.5))  // Light gray, semi-transparent
        context.setLineWidth(0.25)
        
        // Set dashed line pattern
        let dashPattern: [CGFloat] = [4, 4]
        context.setLineDash(phase: 0, lengths: dashPattern)
        
        // Horizontal center line (through content center)
        let contentCenterY = contentRect.midY
        context.move(to: CGPoint(x: pageRect.minX, y: contentCenterY))
        context.addLine(to: CGPoint(x: pageRect.maxX, y: contentCenterY))
        
        // Vertical center line
        let contentCenterX = pageRect.midX
        context.move(to: CGPoint(x: contentCenterX, y: pageRect.minY))
        context.addLine(to: CGPoint(x: contentCenterX, y: pageRect.maxY))
        
        context.strokePath()
        context.restoreGState()
    }
    
    /// Draw separation line between front and back sides
    public func drawSideSeparator(
        context: CGContext,
        y: CGFloat,
        pageRect: CGRect
    ) {
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0.5, alpha: 0.5))
        context.setLineWidth(0.5)
        
        // Dashed line
        let dashPattern: [CGFloat] = [6, 3]
        context.setLineDash(phase: 0, lengths: dashPattern)
        
        context.move(to: CGPoint(x: pageRect.minX + 20, y: y))
        context.addLine(to: CGPoint(x: pageRect.maxX - 20, y: y))
        context.strokePath()
        
        context.restoreGState()
    }
    
    // MARK: - Private Helpers
    
    /// Draw a single corner crop mark (L-shaped)
    private func drawCornerCropMark(
        context: CGContext,
        corner: CGPoint,
        offset: CGFloat,
        length: CGFloat,
        horizontalDirection: CGFloat,
        verticalDirection: CGFloat
    ) {
        // Horizontal mark
        let hStart = CGPoint(
            x: corner.x + (offset * horizontalDirection),
            y: corner.y
        )
        let hEnd = CGPoint(
            x: corner.x + ((offset + length) * horizontalDirection),
            y: corner.y
        )
        context.move(to: hStart)
        context.addLine(to: hEnd)
        
        // Vertical mark
        let vStart = CGPoint(
            x: corner.x,
            y: corner.y + (offset * verticalDirection)
        )
        let vEnd = CGPoint(
            x: corner.x,
            y: corner.y + ((offset + length) * verticalDirection)
        )
        context.move(to: vStart)
        context.addLine(to: vEnd)
    }
}

// MARK: - Side Label Renderer

/// Renders "FRONT" and "BACK" labels on the PDF
extension PDFCropMarkRenderer {
    
    /// Draw a side label (e.g., "FRONT" or "BACK")
    public func drawSideLabel(
        context: CGContext,
        text: String,
        at position: CGPoint,
        alignment: TextAlignment = .center
    ) {
        #if os(macOS)
        let font = CTFontCreateWithName("Helvetica" as CFString, 8, nil)
        #else
        let font = CTFontCreateWithName("Helvetica" as CFString, 8, nil)
        #endif
        
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: CGColor(gray: 0.5, alpha: 1)
        ]
        
        let attributedString = CFAttributedStringCreate(
            nil,
            text as CFString,
            attributes as CFDictionary
        )!
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        let x: CGFloat
        switch alignment {
        case .left:
            x = position.x
        case .center:
            x = position.x - bounds.width / 2
        case .right:
            x = position.x - bounds.width
        }
        
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: position.y)
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
    public enum TextAlignment {
        case left
        case center
        case right
    }
}

// MARK: - Fold Line Renderer

extension PDFCropMarkRenderer {
    
    /// Draw a fold line with label (for folding front/back together)
    public func drawFoldLine(
        context: CGContext,
        y: CGFloat,
        startX: CGFloat,
        endX: CGFloat,
        label: String = "FOLD"
    ) {
        context.saveGState()
        
        // Draw dashed fold line
        context.setStrokeColor(CGColor(gray: 0.6, alpha: 0.8))
        context.setLineWidth(0.75)
        
        let dashPattern: [CGFloat] = [8, 4, 2, 4]  // Long-short pattern
        context.setLineDash(phase: 0, lengths: dashPattern)
        
        context.move(to: CGPoint(x: startX, y: y))
        context.addLine(to: CGPoint(x: endX, y: y))
        context.strokePath()
        
        // Draw fold label at center
        let centerX = (startX + endX) / 2
        drawSideLabel(
            context: context,
            text: "✂︎ \(label) ✂︎",
            at: CGPoint(x: centerX, y: y - 10),
            alignment: .center
        )
        
        context.restoreGState()
    }
}
