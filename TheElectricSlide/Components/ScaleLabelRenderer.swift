//
//  ScaleLabelRenderer.swift
//  TheElectricSlide
//
//  Encapsulates all label rendering logic for scale views.
//  Handles PostScript-style multi-label configurations, positioning,
//  font selection, and color application.
//
//  Extracted from ScaleView.swift for better separation of concerns.
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Debug Logging

/// Debug flag - set to true to enable label rendering diagnostics
private let DEBUG_LABEL_RENDERING = false

/// Renders labels for scale tick marks with full PostScript-style configuration support
struct ScaleLabelRenderer {
    let definition: ScaleDefinition
    
    /// Track render calls for debugging
    private static var renderCallCount = 0
    
    // MARK: - Public Drawing Methods
    
    /// Draw multiple labels with full PostScript-style configuration
    func drawLabels(
        context: inout GraphicsContext,
        labels: [SlideRuleCoreV3.LabelConfig],
        xPos: CGFloat,
        tickHeight: CGFloat,
        tickDirection: SlideRuleCoreV3.TickDirection,
        size: CGSize,
        tickRelativeLength: Double
    ) {
        // Debug: Log render call with context
        if DEBUG_LABEL_RENDERING {
            Self.renderCallCount += 1
            let callId = Self.renderCallCount
            
            // Only log periodically to avoid console spam (every 100th call or first few)
            if callId <= 5 || callId % 100 == 0 {
                print("🏷️ [drawLabels #\(callId)] scale=\(self.definition.name) labelCount=\(labels.count) xPos=\(String(format: "%.2f", xPos)) size=(\(String(format: "%.1f", size.width))x\(String(format: "%.1f", size.height)))")
            }
            
            // Always log for specific problematic scales
            if definition.name.contains("LL") {
                print("🔴 [LL SCALE] \(self.definition.name) xPos=\(String(format: "%.4f", xPos)) size=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height))) labels=\(labels.map { $0.text }.joined(separator: ","))")
            }
        }
        
        for labelConfig in labels {
            let baseFontSize = fontSizeForTick(tickRelativeLength)
            guard baseFontSize > 0 else { continue }
            
            let fontSize = baseFontSize * labelConfig.fontSizeMultiplier
            
            // Use regular font (not italic), we'll apply transform for slant
            let font = Font.system(size: fontSize)
            
            // Check if we should apply custom color based on colorApplication
            let labelColor: Color
            if let tupleColor = definition.labelColor,
               definition.colorApplication.scaleLabels {
                // Use the definition's label color if colorApplication allows
                labelColor = Color(red: tupleColor.red, green: tupleColor.green, blue: tupleColor.blue)
            } else {
                // Otherwise use the label config's color (for dual labels) or default to black
                labelColor = colorFromLabelColor(labelConfig.color)
            }
            
            let text = Text(labelConfig.text)
                .font(font)
                .foregroundColor(labelColor)
            
            let resolvedText = context.resolve(text)
            let textSize = resolvedText.measure(in: CGSize(width: 100, height: 100))
            
            // Debug: Log text measurement for LL scales
            if DEBUG_LABEL_RENDERING && definition.name.contains("LL") && labelConfig.text == "3" {
                print("📏 [TEXT MEASURE] '\(labelConfig.text)' fontSize=\(fontSize) measured=(\(String(format: "%.4f", textSize.width))x\(String(format: "%.4f", textSize.height)))")
            }
            
            // Calculate position based on label position and tick direction
            let (labelX, labelY) = calculateLabelPosition(
                position: labelConfig.position,
                xPos: xPos,
                tickHeight: tickHeight,
                textSize: textSize,
                tickDirection: tickDirection,
                size: size
            )
            
            // Apply skew transform matching PostScript NumFontRi/NumFontLi
            // PostScript: [ 1 0 tan(20°) 1 0 0 ] for right italic
            //            [ 1 0 -tan(20°) 1 0 0 ] for left italic
            // tan(20°) ≈ 0.364
            let skewAmount: CGFloat
            switch labelConfig.position {
            case .right:
                skewAmount = -tan(20.0 * .pi / 180.0)  // Left-leaning (away from tick on right)
            case .left:
                skewAmount = tan(20.0 * .pi / 180.0) // Right-leaning (away from tick on left)
            default:
                skewAmount = 0     // No slant for centered labels
            }
            
            // Create skew transform matching PostScript font matrix
            // Matrix positions: [a b c d tx ty] where c creates horizontal skew
            var transform = CGAffineTransform.identity
            transform.c = skewAmount  // Horizontal skew (x' = x + c*y)
            
            // Calculate draw position and round to avoid sub-pixel rendering issues at zoom
            // Sub-pixel positions can cause text to shift when scaled due to different rounding
            let drawX = round(labelX + textSize.width / 2)
            let drawY = round(labelY + textSize.height / 2)
            
            // Debug: Log actual draw position for LL scales
            if DEBUG_LABEL_RENDERING && definition.name.contains("LL") {
                print("🎯 [DRAW POS] \(definition.name) '\(labelConfig.text)' drawAt=(\(String(format: "%.2f", drawX)),\(String(format: "%.2f", drawY))) textSize=(\(String(format: "%.2f", textSize.width))x\(String(format: "%.2f", textSize.height))) skew=\(String(format: "%.4f", skewAmount))")
            }
            
            // Draw with transform - use concatenation to preserve parent transforms
            var transformedContext = context
            transformedContext.concatenate(transform)
            transformedContext.draw(
                resolvedText,
                at: CGPoint(x: drawX, y: drawY)
            )
        }
    }
    
    /// Draw simple label (backward compatibility for single-label ticks)
    func drawSimpleLabel(
        context: inout GraphicsContext,
        text: String,
        xPos: CGFloat,
        tickHeight: CGFloat,
        tickDirection: SlideRuleCoreV3.TickDirection,
        size: CGSize,
        tickRelativeLength: Double
    ) {
        // Debug: Log simple label render
        if DEBUG_LABEL_RENDERING {
            Self.renderCallCount += 1
            let callId = Self.renderCallCount
            
            // Only log periodically to avoid console spam
            if callId <= 5 || callId % 100 == 0 {
                print("🏷️ [drawSimpleLabel #\(callId)] scale=\(self.definition.name) text='\(text)' xPos=\(String(format: "%.2f", xPos)) size=(\(String(format: "%.1f", size.width))x\(String(format: "%.1f", size.height)))")
            }
            
            // Always log for LL scales (the problematic ones)
            if definition.name.contains("LL") {
                print("🔴 [LL SIMPLE] \(self.definition.name) text='\(text)' xPos=\(String(format: "%.4f", xPos)) size=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height)))")
            }
        }
        
        let fontSize = fontSizeForTick(tickRelativeLength)
        guard fontSize > 0 else { return }
        
        // Use label color from definition if available and colorApplication allows, otherwise default to black
        let labelColor: Color
        if let tupleColor = definition.labelColor,
           definition.colorApplication.scaleLabels {
            labelColor = Color(red: tupleColor.red, green: tupleColor.green, blue: tupleColor.blue)
        } else {
            labelColor = .black
        }
        
        let label = Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(labelColor)
        
        let resolvedText = context.resolve(label)
        let textSize = resolvedText.measure(in: CGSize(width: 100, height: 100))
        
        // Position label based on tick direction
        let labelY: CGFloat
        switch tickDirection {
        case .down:
            // Labels below tick mark
            labelY = tickHeight + 2
        case .up:
            // Labels above tick mark
            labelY = size.height - tickHeight - textSize.height - 2
        }
        let labelX = xPos - textSize.width / 2
        
        // Round to avoid sub-pixel rendering issues at zoom
        let drawX = round(labelX + textSize.width / 2)
        let drawY = round(labelY + textSize.height / 2)
        
        context.draw(
            resolvedText,
            at: CGPoint(x: drawX, y: drawY)
        )
    }
    
    // MARK: - Position Calculation
    
    /// Calculate label position based on PostScript positioning rules
    func calculateLabelPosition(
        position: SlideRuleCoreV3.LabelPosition,
        xPos: CGFloat,
        tickHeight: CGFloat,
        textSize: CGSize,
        tickDirection: SlideRuleCoreV3.TickDirection,
        size: CGSize
    ) -> (x: CGFloat, y: CGFloat) {
        let labelX: CGFloat
        let labelY: CGFloat
        
        switch position {
        case .centered:
            // Default: center on tick
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = tickHeight + 2
            case .up:
                labelY = size.height - tickHeight - textSize.height - 2
            }
            
        case .top:
            // PostScript /Ntop: above tick (inverted for .down direction)
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = -textSize.height - 2  // Above the baseline
            case .up:
                labelY = size.height - tickHeight - textSize.height - 2
            }
            
        case .bottom:
            // Below tick
            labelX = xPos - textSize.width / 2
            switch tickDirection {
            case .down:
                labelY = tickHeight + 2
            case .up:
                labelY = size.height + 2  // Below baseline
            }
            
        case .left:
            // PostScript /Nleft: to the left of tick
            // Position so bottom corner barely doesn't touch tick, leaning away
            labelX = xPos - textSize.width - 7 // Small gap from tick
            switch tickDirection {
            case .down:
                labelY = tickHeight - textSize.height + 1  // Bottom corner near tick end
            case .up:
                labelY = size.height - tickHeight - 2 // Bottom corner near tick end
            }
            
        case .right:
            // PostScript /Nright: to the right of tick
            // Position so bottom corner barely doesn't touch tick, leaning away
            labelX = xPos + 7 // Small gap from tick
            switch tickDirection {
            case .down:
                labelY = tickHeight - textSize.height + 1  // Bottom corner near tick end
            case .up:
                labelY = size.height - tickHeight - 2  // Bottom corner near tick end
            }
        }
        
        return (labelX, labelY)
    }
    
    // MARK: - Color Helpers
    
    /// Convert LabelColor to SwiftUI Color
    func colorFromLabelColor(_ labelColor: SlideRuleCoreV3.LabelColor) -> Color {
        Color(
            red: labelColor.red,
            green: labelColor.green,
            blue: labelColor.blue,
            opacity: labelColor.alpha
        )
    }
    
    /// Convert an RGB tuple to SwiftUI Color (graceful helper for older definitions)
    func colorFromTuple(_ tuple: (red: Double, green: Double, blue: Double)) -> Color {
        Color(red: tuple.red, green: tuple.green, blue: tuple.blue)
    }
    
    // MARK: - Font Helpers
    
    /// Get font with specified style (PostScript NumFontRi, NumFontLi support)
    func fontForStyle(_ style: SlideRuleCoreV3.LabelFontStyle, size: CGFloat) -> Font {
        switch style {
        case .regular:
            return .system(size: size)
        case .italic:
            return .system(size: size).italic()
        case .leftItalic:
            // SwiftUI doesn't support left italic, use regular italic
            // For true left italic, would need custom font rendering
            return .system(size: size).italic()
        case .bold:
            return .system(size: size).bold()
        case .boldItalic:
            return .system(size: size).bold().italic()
        }
    }
    
    /// Determine font size based on tick relativeLength
    func fontSizeForTick(_ relativeLength: Double) -> CGFloat {
        if relativeLength >= 0.9 {
            return 6.0  // Major ticks
        } else if relativeLength >= 0.7 {
            return 4.5  // Medium ticks
        } else if relativeLength >= 0.4 {
            return 3.0  // Minor ticks
        } else {
            return 0.0  // Tiny ticks - no label
        }
    }
}
