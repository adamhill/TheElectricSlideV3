// File: TheElectricSlide/PDF/ScalePDFRenderer.swift

import CoreGraphics
import Foundation
import SlideRuleCoreV3

/// Renders individual scales to PDF using CGContext
enum ScalePDFRenderer {
    
    // MARK: - Scale Rendering
    
    /// Render a complete scale
    static func render(
        scale: GeneratedScale,
        at origin: CGPoint,
        width: CGFloat,
        height: CGFloat,
        renderContext: PDFRenderContext
    ) throws {
        let definition = scale.definition
        
        // Draw scale name on left
        let namePosition = CGPoint(
            x: origin.x - 56,  // 56pts left of scale
            y: origin.y + (height / 2) - 4
        )
        renderContext.drawTextCoreText(
            definition.displayName ?? definition.name,
            at: namePosition,
            fontSize: 10,
            fontName: "Helvetica-Bold"
        )
        
        // Draw formula on right
        if !definition.formula.isEmpty && definition.formula != ScaleDefinition.defaultFormula {
            let formulaPosition = CGPoint(
                x: origin.x + width + 8,  // 8pts right of scale
                y: origin.y + (height / 2) - 4
            )
            renderContext.drawTextCoreText(
                definition.formula,
                at: formulaPosition,
                fontSize: 9,
                fontName: "Helvetica"
            )
        }
        
        // Draw baseline if enabled
        if definition.showBaseline {
            renderBaseline(
                origin: origin,
                width: width,
                height: height,
                tickDirection: definition.tickDirection,
                renderContext: renderContext
            )
        }
        
        // Draw each tick mark and its label(s)
        for tick in scale.tickMarks {
            renderTick(
                tick: tick,
                origin: origin,
                scaleWidth: width,
                scaleHeight: height,
                definition: definition,
                renderContext: renderContext
            )
        }
    }
    
    // MARK: - Baseline Rendering
    
    private static func renderBaseline(
        origin: CGPoint,
        width: CGFloat,
        height: CGFloat,
        tickDirection: TickDirection,
        renderContext: PDFRenderContext
    ) {
        let y: CGFloat
        switch tickDirection {
        case .down:
            y = origin.y + height
        case .up:
            y = origin.y
        }
        
        let start = CGPoint(x: origin.x, y: y)
        let end = CGPoint(x: origin.x + width, y: y)
        
        // Use 2.0pt line width for baseline to match ScaleTickRenderer
        renderContext.drawLine(from: start, to: end, lineWidth: 2.0, color: CGColor(gray: 0, alpha: 1))
    }
    
    // MARK: - Tick Rendering
    
    private static func renderTick(
        tick: TickMark,
        origin: CGPoint,
        scaleWidth: CGFloat,
        scaleHeight: CGFloat,
        definition: ScaleDefinition,
        renderContext: PDFRenderContext
    ) {
        // Calculate horizontal position
        let xPos = origin.x + (CGFloat(tick.normalizedPosition) * scaleWidth)
        
        // Calculate tick height
        let tickHeight = CGFloat(tick.style.relativeLength) * (scaleHeight * 0.5)
        
        // Determine tick start and end Y positions
        let (startY, endY): (CGFloat, CGFloat)
        switch definition.tickDirection {
        case .down:
            startY = origin.y + scaleHeight
            endY = startY - tickHeight
        case .up:
            startY = origin.y
            endY = startY + tickHeight
        }
        
        // Draw tick line
        renderContext.drawLine(
            from: CGPoint(x: xPos, y: startY),
            to: CGPoint(x: xPos, y: endY),
            lineWidth: CGFloat(tick.style.lineWidth),
            color: colorForTick(definition: definition)
        )
        
        // Draw labels
        if !tick.labels.isEmpty {
            for labelConfig in tick.labels {
                renderLabel(
                    labelConfig: labelConfig,
                    xPos: xPos,
                    tickHeight: tickHeight,
                    tickRelativeLength: tick.style.relativeLength,
                    tickDirection: definition.tickDirection,
                    origin: origin,
                    scaleHeight: scaleHeight,
                    renderContext: renderContext
                )
            }
        }
    }
    
    // MARK: - Label Rendering
    
    private static func renderLabel(
        labelConfig: LabelConfig,
        xPos: CGFloat,
        tickHeight: CGFloat,
        tickRelativeLength: Double,
        tickDirection: TickDirection,
        origin: CGPoint,
        scaleHeight: CGFloat,
        renderContext: PDFRenderContext
    ) {
        // Determine base font size from tick relative length (EXACT match for ScaleLabelRenderer)
        let baseFontSize = fontSizeForTick(tickRelativeLength)
        guard baseFontSize > 0 else { return }
        let fontSize = baseFontSize * CGFloat(labelConfig.fontSizeMultiplier)
        
        // Measure text for positioning
        let fontName = fontNameForStyle(labelConfig.fontStyle)
        let textSize = renderContext.measureText(labelConfig.text, fontSize: fontSize, fontName: fontName)
        
        // Calculate label position based on PostScript positioning rules
        let labelPos = calculateLabelPosition(
            labelConfig: labelConfig,
            xPos: xPos,
            tickHeight: tickHeight,
            textSize: textSize,
            tickDirection: tickDirection,
            origin: origin,
            scaleHeight: scaleHeight
        )
        
        // Determine skew amount for italic styles
        let skewAmount = skewAmountForFontStyle(labelConfig.fontStyle)
        
        // Render text
        renderContext.drawTextCoreText(
            labelConfig.text,
            at: labelPos,
            fontSize: fontSize,
            fontName: fontName,
            color: cgColorForLabelColor(labelConfig.color),
            skewAmount: skewAmount
        )
    }
    
    // MARK: - Helper Methods
    
    private static func calculateLabelPosition(
        labelConfig: LabelConfig,
        xPos: CGFloat,
        tickHeight: CGFloat,
        textSize: CGSize,
        tickDirection: TickDirection,
        origin: CGPoint,
        scaleHeight: CGFloat
    ) -> CGPoint {
        var labelX: CGFloat
        var labelY: CGFloat
        
        switch labelConfig.position {
        case .centered:
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = origin.y + scaleHeight - tickHeight - textSize.height - 2
            case .up:
                labelY = origin.y + tickHeight + 2
            }
            
        case .top:
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = origin.y + scaleHeight + 2
            case .up:
                labelY = origin.y + tickHeight + 2
            }
            
        case .bottom:
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = origin.y + scaleHeight - tickHeight - textSize.height - 2
            case .up:
                labelY = origin.y - textSize.height - 2
            }
            
        case .left:
            labelX = xPos - textSize.width - 7
            switch tickDirection {
            case .down:
                // Bottom of label 1pt below tick end
                labelY = origin.y + scaleHeight - tickHeight - 1
            case .up:
                // Bottom of label 2pt above tick end
                labelY = origin.y + tickHeight + 2 - textSize.height
            }
            
        case .right:
            labelX = xPos + 7
            switch tickDirection {
            case .down:
                // Bottom of label 1pt below tick end
                labelY = origin.y + scaleHeight - tickHeight - 1
            case .up:
                // Bottom of label 2pt above tick end
                labelY = origin.y + tickHeight + 2 - textSize.height
            }
        }
        
        // Apply offset and round for parity with SwiftUI rendering
        labelX = round(labelX + CGFloat(labelConfig.offset.horizontal))
        labelY = round(labelY + CGFloat(labelConfig.offset.vertical))
        
        return CGPoint(x: labelX, y: labelY)
    }
    
    private static func fontSizeForTick(_ relativeLength: Double) -> CGFloat {
        // EXACT match for ScaleLabelRenderer.fontSizeForTick
        if relativeLength >= 0.9 {
            return 8.0  // Major ticks
        } else if relativeLength >= 0.7 {
            return 6.5  // Medium ticks
        } else if relativeLength >= 0.4 {
            return 5.0  // Minor ticks
        } else {
            return 0.0  // Tiny ticks - no label
        }
    }
    
    private static func fontNameForStyle(_ style: LabelFontStyle) -> String {
        switch style {
        case .regular:
            return "Helvetica"
        case .medium:
            return "Helvetica"
        case .italic, .leftItalic:
            return "Helvetica-Oblique"
        case .bold:
            return "Helvetica-Bold"
        case .boldItalic:
            return "Helvetica-BoldOblique"
        }
    }
    
    private static func skewAmountForFontStyle(_ style: LabelFontStyle) -> CGFloat {
        switch style {
        case .italic:
            return -tan(20.0 * .pi / 180.0)  // Right-leaning
        case .leftItalic:
            return tan(20.0 * .pi / 180.0)   // Left-leaning
        default:
            return 0
        }
    }
    
    private static func colorForTick(definition: ScaleDefinition) -> CGColor {
        if let color = definition.labelColor, definition.colorApplication.scaleTicks {
            return CGColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: CGFloat(color.alpha))
        }
        return CGColor(gray: 0, alpha: 1)
    }
    
    private static func cgColorForLabelColor(_ labelColor: LabelColor) -> CGColor {
        return CGColor(red: CGFloat(labelColor.red), green: CGFloat(labelColor.green), blue: CGFloat(labelColor.blue), alpha: CGFloat(labelColor.alpha))
    }
}
