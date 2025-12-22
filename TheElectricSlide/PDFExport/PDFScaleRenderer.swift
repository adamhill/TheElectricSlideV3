//
//  PDFScaleRenderer.swift
//  TheElectricSlide
//
//  Core Graphics-based renderer for drawing slide rule scales to PDF.
//  Adapts the logic from ScaleTickRenderer and ScaleLabelRenderer
//  to work with CGContext instead of SwiftUI GraphicsContext.
//
//  Reference: PostScript engine position calculation:
//  tickx = (curtick / xfactor).formula() × scalelen + scalestart
//
//  Swift equivalent:
//  xPos = tick.normalizedPosition * scaleLength + originX
//

import Foundation
import CoreGraphics
import CoreText
import SlideRuleCoreV3

// MARK: - PDF Scale Renderer

/// Renders slide rule scales to a Core Graphics context (PDF-compatible)
public struct PDFScaleRenderer: Sendable {
    
    // MARK: - Properties
    
    public let configuration: PDFExportConfiguration
    
    // MARK: - Pre-computed Constants
    
    /// Height multiplier for tick calculations (matches ScaleTickRenderer)
    private static let kHeightMultiplier: CGFloat = 0.5
    
    /// Pre-computed skew values for italic labels (matches ScaleLabelRenderer)
    private static let kSkewRight: CGFloat = -tan(20.0 * .pi / 180.0)  // ≈ -0.364
    private static let kSkewLeft: CGFloat = tan(20.0 * .pi / 180.0)    // ≈ 0.364
    
    // MARK: - Initializer
    
    public init(configuration: PDFExportConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Drawing Methods
    
    /// Draw a complete scale (baseline, ticks, labels, name, formula)
    public func drawScale(
        _ generatedScale: GeneratedScale,
        in context: CGContext,
        at origin: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {
        let definition = generatedScale.definition
        
        // Draw baseline if enabled
        if definition.showBaseline {
            drawBaseline(context: context, origin: origin, width: width, height: height, definition: definition)
        }
        
        // Draw each tick mark and its label(s)
        for tick in generatedScale.tickMarks {
            let (xPos, tickHeight) = drawTick(
                context: context,
                tick: tick,
                origin: origin,
                width: width,
                height: height,
                definition: definition
            )
            
            // Draw labels for this tick
            if !tick.labels.isEmpty {
                drawLabels(
                    context: context,
                    labels: tick.labels,
                    xPos: xPos,
                    tickHeight: tickHeight,
                    tickDirection: definition.tickDirection,
                    origin: origin,
                    height: height,
                    tickRelativeLength: tick.style.relativeLength,
                    definition: definition
                )
            } else if let labelText = tick.label, tick.style.shouldLabel {
                drawSimpleLabel(
                    context: context,
                    text: labelText,
                    xPos: xPos,
                    tickHeight: tickHeight,
                    tickDirection: definition.tickDirection,
                    origin: origin,
                    height: height,
                    tickRelativeLength: tick.style.relativeLength,
                    definition: definition
                )
            }
        }
    }
    
    /// Draw the scale name in the left margin
    public func drawScaleName(
        context: CGContext,
        name: String,
        at origin: CGPoint,
        height: CGFloat,
        definition: ScaleDefinition
    ) {
        let fontSize = configuration.scaleNameFontSize * configuration.fontScaleFactor
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
        
        // Use scale's label color if defined
        let color = labelColor(for: definition)
        
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color
        ]
        
        let attributedString = CFAttributedStringCreate(nil, name as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        // Center vertically in the scale height (PDF coords: y increases upward)
        let x = origin.x - bounds.width - 4  // 4pt gap from scale
        let y = origin.y + (height - bounds.height) / 2
        
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
    /// Draw the formula in the right margin
    public func drawFormula(
        context: CGContext,
        formula: String,
        at origin: CGPoint,
        width: CGFloat,
        height: CGFloat,
        definition: ScaleDefinition
    ) {
        guard !formula.isEmpty else { return }
        
        let fontSize = configuration.formulaFontSize * configuration.fontScaleFactor
        let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
        
        // Use scale's label color if defined, lighter for formulas
        let color = labelColor(for: definition, alpha: 0.7)
        
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color
        ]
        
        let attributedString = CFAttributedStringCreate(nil, formula as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        // Position to the right of the scale
        let x = origin.x + width + 4  // 4pt gap from scale
        let y = origin.y + (height - bounds.height) / 2
        
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
    // MARK: - Private Drawing Methods
    
    /// Draw the scale baseline
    private func drawBaseline(
        context: CGContext,
        origin: CGPoint,
        width: CGFloat,
        height: CGFloat,
        definition: ScaleDefinition
    ) {
        let baselineY: CGFloat
        switch definition.tickDirection {
        case .down:
            baselineY = origin.y
        case .up:
            baselineY = origin.y + height
        }
        
        context.saveGState()
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(configuration.baselineWidth)
        context.move(to: CGPoint(x: origin.x, y: baselineY))
        context.addLine(to: CGPoint(x: origin.x + width, y: baselineY))
        context.strokePath()
        context.restoreGState()
    }
    
    /// Draw a single tick mark and return its geometry for label positioning
    @discardableResult
    private func drawTick(
        context: CGContext,
        tick: TickMark,
        origin: CGPoint,
        width: CGFloat,
        height: CGFloat,
        definition: ScaleDefinition
    ) -> (xPos: CGFloat, tickHeight: CGFloat) {
        // Calculate horizontal position
        let xPos = origin.x + tick.normalizedPosition * width
        
        // Calculate tick height based on relativeLength
        let tickHeight = tick.style.relativeLength * (height * Self.kHeightMultiplier)
        
        // Calculate tick start and end positions based on direction
        let (tickStartY, tickEndY): (CGFloat, CGFloat)
        switch definition.tickDirection {
        case .down:
            tickStartY = origin.y
            tickEndY = origin.y + tickHeight
        case .up:
            tickStartY = origin.y + height
            tickEndY = origin.y + height - tickHeight
        }
        
        // Get tick color
        let tickColor = self.tickColor(for: definition)
        
        // Draw tick mark
        context.saveGState()
        context.setStrokeColor(tickColor)
        context.setLineWidth(tick.style.lineWidth * configuration.tickLineWidthMultiplier)
        context.move(to: CGPoint(x: xPos, y: tickStartY))
        context.addLine(to: CGPoint(x: xPos, y: tickEndY))
        context.strokePath()
        context.restoreGState()
        
        return (xPos, tickHeight)
    }
    
    /// Draw multiple labels with full PostScript-style configuration
    private func drawLabels(
        context: CGContext,
        labels: [LabelConfig],
        xPos: CGFloat,
        tickHeight: CGFloat,
        tickDirection: TickDirection,
        origin: CGPoint,
        height: CGFloat,
        tickRelativeLength: Double,
        definition: ScaleDefinition
    ) {
        for labelConfig in labels {
            let baseFontSize = configuration.fontSizeForTick(tickRelativeLength)
            guard baseFontSize > 0 else { continue }
            
            let fontSize = baseFontSize * labelConfig.fontSizeMultiplier
            let font = fontForStyle(labelConfig.fontStyle, size: fontSize)
            
            // Use scale's label color or fall back to label config's color
            let color: CGColor
            if let tupleColor = definition.labelColor, definition.colorApplication.scaleLabels {
                color = CGColor(
                    srgbRed: CGFloat(tupleColor.red),
                    green: CGFloat(tupleColor.green),
                    blue: CGFloat(tupleColor.blue),
                    alpha: 1.0
                )
            } else {
                color = colorFromLabelColor(labelConfig.color)
            }
            
            let attributes: [CFString: Any] = [
                kCTFontAttributeName: font,
                kCTForegroundColorAttributeName: color
            ]
            
            let attributedString = CFAttributedStringCreate(nil, labelConfig.text as CFString, attributes as CFDictionary)!
            let line = CTLineCreateWithAttributedString(attributedString)
            let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
            let textSize = bounds.size
            
            // Calculate position based on label position and tick direction
            let (labelX, labelY) = calculateLabelPosition(
                position: labelConfig.position,
                xPos: xPos,
                tickHeight: tickHeight,
                textSize: textSize,
                tickDirection: tickDirection,
                origin: origin,
                height: height
            )
            
            // Apply skew transform for italic positions
            let skewAmount: CGFloat
            switch labelConfig.position {
            case .right:
                skewAmount = Self.kSkewRight
            case .left:
                skewAmount = Self.kSkewLeft
            default:
                skewAmount = 0
            }
            
            // Draw the label
            context.saveGState()
            
            // Apply skew if needed
            if skewAmount != 0 {
                var transform = CGAffineTransform.identity
                transform.c = skewAmount
                context.concatenate(transform)
            }
            
            // Set up text matrix for proper rendering (PDF native coords)
            context.textMatrix = .identity
            
            let drawX = labelX + labelConfig.offset.horizontal
            let drawY = labelY + labelConfig.offset.vertical
            
            context.textPosition = CGPoint(x: drawX, y: drawY)
            CTLineDraw(line, context)
            
            context.restoreGState()
        }
    }
    
    /// Draw simple label (for single-label ticks)
    private func drawSimpleLabel(
        context: CGContext,
        text: String,
        xPos: CGFloat,
        tickHeight: CGFloat,
        tickDirection: TickDirection,
        origin: CGPoint,
        height: CGFloat,
        tickRelativeLength: Double,
        definition: ScaleDefinition
    ) {
        let fontSize = configuration.fontSizeForTick(tickRelativeLength)
        guard fontSize > 0 else { return }
        
        let font = CTFontCreateWithName("Helvetica-Medium" as CFString, fontSize, nil)
        let color = labelColor(for: definition)
        
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color
        ]
        
        let attributedString = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        let textSize = bounds.size
        
        // Position label based on tick direction (PDF coords: y increases upward)
        let labelY: CGFloat
        switch tickDirection {
        case .down:
            // Ticks go down from baseline, labels below ticks
            labelY = origin.y - tickHeight - textSize.height - 2
        case .up:
            // Ticks go up from baseline, labels above ticks
            labelY = origin.y + height + tickHeight + 2
        }
        let labelX = xPos - textSize.width / 2
        
        // Draw the label
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: labelX, y: labelY)
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
    // MARK: - Position Calculation
    
    /// Calculate label position based on PostScript positioning rules
    private func calculateLabelPosition(
        position: LabelPosition,
        xPos: CGFloat,
        tickHeight: CGFloat,
        textSize: CGSize,
        tickDirection: TickDirection,
        origin: CGPoint,
        height: CGFloat
    ) -> (x: CGFloat, y: CGFloat) {
        let labelX: CGFloat
        let labelY: CGFloat
        
        switch position {
        case .centered:
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = origin.y + tickHeight + 2
            case .up:
                labelY = origin.y + height - tickHeight - textSize.height - 2
            }
            
        case .top:
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = origin.y - textSize.height - 2
            case .up:
                labelY = origin.y + height - tickHeight - textSize.height - 2
            }
            
        case .bottom:
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = origin.y + tickHeight + 2
            case .up:
                labelY = origin.y + height + 2
            }
            
        case .left:
            labelX = xPos - textSize.width - 7
            switch tickDirection {
            case .down:
                labelY = origin.y + tickHeight - textSize.height + 1
            case .up:
                labelY = origin.y + height - tickHeight - 2
            }
            
        case .right:
            labelX = xPos + 7
            switch tickDirection {
            case .down:
                labelY = origin.y + tickHeight - textSize.height + 1
            case .up:
                labelY = origin.y + height - tickHeight - 2
            }
        }
        
        return (labelX, labelY)
    }
    
    // MARK: - Color Helpers
    
    /// Get tick color for a scale definition
    private func tickColor(for definition: ScaleDefinition) -> CGColor {
        if let tupleColor = definition.labelColor, definition.colorApplication.scaleTicks {
            return CGColor(
                srgbRed: CGFloat(tupleColor.red),
                green: CGFloat(tupleColor.green),
                blue: CGFloat(tupleColor.blue),
                alpha: 1.0
            )
        }
        return CGColor(gray: 0, alpha: 1)  // black
    }
    
    /// Get label color for a scale definition
    private func labelColor(for definition: ScaleDefinition) -> CGColor {
        if let tupleColor = definition.labelColor, definition.colorApplication.scaleLabels {
            return CGColor(
                srgbRed: CGFloat(tupleColor.red),
                green: CGFloat(tupleColor.green),
                blue: CGFloat(tupleColor.blue),
                alpha: 1.0
            )
        }
        return CGColor(gray: 0, alpha: 1)  // black
    }
    
    /// Get label color with adjusted alpha
    private func labelColor(for definition: ScaleDefinition, alpha: CGFloat) -> CGColor {
        if let tupleColor = definition.labelColor, definition.colorApplication.scaleLabels {
            return CGColor(
                srgbRed: CGFloat(tupleColor.red),
                green: CGFloat(tupleColor.green),
                blue: CGFloat(tupleColor.blue),
                alpha: alpha
            )
        }
        return CGColor(gray: 0, alpha: alpha)  // black with alpha
    }
    
    /// Convert LabelColor to CGColor
    private func colorFromLabelColor(_ labelColor: LabelColor) -> CGColor {
        CGColor(
            srgbRed: CGFloat(labelColor.red),
            green: CGFloat(labelColor.green),
            blue: CGFloat(labelColor.blue),
            alpha: CGFloat(labelColor.alpha)
        )
    }
    
    // MARK: - Font Helpers
    
    /// Get CTFont for a label style
    private func fontForStyle(_ style: LabelFontStyle, size: CGFloat) -> CTFont {
        let fontName: CFString
        switch style {
        case .regular:
            fontName = "Helvetica" as CFString
        case .medium:
            fontName = "Helvetica-Medium" as CFString
        case .italic, .leftItalic:
            fontName = "Helvetica-Oblique" as CFString
        case .bold:
            fontName = "Helvetica-Bold" as CFString
        case .boldItalic:
            fontName = "Helvetica-BoldOblique" as CFString
        }
        return CTFontCreateWithName(fontName, size, nil)
    }
}
