//
//  ScaleView.swift
//  TheElectricSlide
//
//  Core scale rendering component that draws tick marks and labels
//  Extracted from ContentView.swift for better organization
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - ScaleView Component

struct ScaleView: View {
    let generatedScale: GeneratedScale  // ✅ Use pre-computed GeneratedScale
    let width: CGFloat
    let height: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Scale name label on the left (right-aligned with responsive width)
            // Extract label color from definition, applying it only if colorApplication allows
            let scaleLabelColor: Color = {
                if let tupleColor = generatedScale.definition.labelColor,
                   generatedScale.definition.colorApplication.scaleName {
                    return Color(red: tupleColor.red, green: tupleColor.green, blue: tupleColor.blue)
                } else {
                    return .black
                }
            }()
            
            Text(generatedScale.definition.name)
                .font(nameFont)
                .foregroundColor(scaleLabelColor)
                .frame(width: leftMarginWidth, alignment: .trailing)
            
            // Scale view
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Tick marks and labels
                    Canvas { context, size in
                        // ✅ Use pre-computed tick marks from GeneratedScale
                        drawScale(
                            context: &context,
                            size: size,
                            tickMarks: generatedScale.tickMarks,
                            definition: generatedScale.definition
                        )
                    }
                    .drawingGroup()  // ✅ Metal-accelerated rendering for complex Canvas
                }
            }
            .frame(width: width)
            .frame(minHeight: height * 0.8, idealHeight: height, maxHeight: height)
            
            // Formula label on the right (left-aligned with responsive width)
            Text(generatedScale.definition.formula)
                .font(formulaFont)
                .tracking((generatedScale.definition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black)
                .frame(width: rightMarginWidth, alignment: .leading)
        }
    }
    
    /// Draw the scale with pre-computed tick marks
    private func drawScale(
        context: inout GraphicsContext,
        size: CGSize,
        tickMarks: [TickMark],
        definition: ScaleDefinition
    ) {
        // Draw baseline if enabled
        if definition.showBaseline {
            let baselinePath = Path { path in
                switch definition.tickDirection {
                case .down:
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: size.width, y: 0))
                case .up:
                    path.move(to: CGPoint(x: 0, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                }
            }
            
            context.stroke(
                baselinePath,
                with: .color(.black),
                lineWidth: 2.0
            )
        }
        
        // Draw tick marks
        for tick in tickMarks {
            // Calculate horizontal position
            let xPos = tick.normalizedPosition * size.width
            
            // Calculate tick height based on relativeLength
            let tickHeight = tick.style.relativeLength * (size.height * 0.6)
            
            // Calculate tick start and end positions based on direction
            let (tickStartY, tickEndY): (CGFloat, CGFloat)
            switch definition.tickDirection {
            case .down:
                tickStartY = 0
                tickEndY = tickHeight
            case .up:
                tickStartY = size.height
                tickEndY = size.height - tickHeight
            }
            
            // Draw tick mark (vertical line) with anti-aliasing disabled
            // Apply custom color to tick marks if colorApplication allows
            let tickColor: Color = {
                if let tupleColor = definition.labelColor,
                   definition.colorApplication.scaleTicks {
                    return Color(red: tupleColor.red, green: tupleColor.green, blue: tupleColor.blue)
                } else {
                    return .black
                }
            }()
            
            let tickPath = Path { path in
                path.move(to: CGPoint(x: xPos, y: tickStartY))
                path.addLine(to: CGPoint(x: xPos, y: tickEndY))
            }
            
            context.withCGContext { cgContext in
                cgContext.setShouldAntialias(false)
                context.stroke(
                    tickPath,
                    with: .color(tickColor),
                    lineWidth: tick.style.lineWidth / 1.25
                )
            }
            
            // Draw labels (supports dual labeling from PostScript plabelR/plabelL)
            if !tick.labels.isEmpty {
                drawLabels(
                    context: &context,
                    labels: tick.labels,
                    xPos: xPos,
                    tickHeight: tickHeight,
                    tickDirection: definition.tickDirection,
                    size: size,
                    tickRelativeLength: tick.style.relativeLength
                )
            } else if let labelText = tick.label {
                // Backward compatibility: simple label rendering
                drawSimpleLabel(
                    context: &context,
                    text: labelText,
                    xPos: xPos,
                    tickHeight: tickHeight,
                    tickDirection: definition.tickDirection,
                    size: size,
                    tickRelativeLength: tick.style.relativeLength,
                    definition: definition
                )
            }
        }
    }
    
    /// Draw multiple labels with full PostScript-style configuration
    private func drawLabels(
        context: inout GraphicsContext,
        labels: [SlideRuleCoreV3.LabelConfig],
        xPos: CGFloat,
        tickHeight: CGFloat,
        tickDirection: SlideRuleCoreV3.TickDirection,
        size: CGSize,
        tickRelativeLength: Double
    ) {
        for labelConfig in labels {
            let baseFontSize = fontSizeForTick(tickRelativeLength)
            guard baseFontSize > 0 else { continue }
            
            let fontSize = baseFontSize * labelConfig.fontSizeMultiplier
            
            // Use regular font (not italic), we'll apply transform for slant
            let font = Font.system(size: fontSize)
            
            // Check if we should apply custom color based on colorApplication
            let labelColor: Color
            if let tupleColor = generatedScale.definition.labelColor,
               generatedScale.definition.colorApplication.scaleLabels {
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
            
            // Draw with transform
            var transformedContext = context
            transformedContext.transform = transform
            transformedContext.draw(
                resolvedText,
                at: CGPoint(x: labelX + textSize.width / 2, y: labelY + textSize.height / 2)
            )
        }
    }
    
    /// Draw simple label (backward compatibility)
    private func drawSimpleLabel(
        context: inout GraphicsContext,
        text: String,
        xPos: CGFloat,
        tickHeight: CGFloat,
        tickDirection: SlideRuleCoreV3.TickDirection,
        size: CGSize,
        tickRelativeLength: Double,
        definition: ScaleDefinition
    ) {
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
        
        context.draw(
            resolvedText,
            at: CGPoint(x: labelX + textSize.width / 2, y: labelY + textSize.height / 2)
        )
    }
    
    /// Calculate label position based on PostScript positioning rules
    private func calculateLabelPosition(
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
                labelY = tickHeight - textSize.height +  1  // Bottom corner near tick end
            case .up:
                labelY = size.height - tickHeight - 2 // Bottom corner near tick end
            }
            
        case .right:
            // PostScript /Nright: to the right of tick
            // Position so bottom corner barely doesn't touch tick, leaning away
            labelX = xPos + 7// Small gap from tick
            switch tickDirection {
            case .down:
                labelY = tickHeight - textSize.height + 1  // Bottom corner near tick end
            case .up:
                labelY = size.height - tickHeight - 2  // Bottom corner near tick end
            }
        }
        
        return (labelX, labelY)
    }
    
    /// Convert LabelColor to SwiftUI Color
    private func colorFromLabelColor(_ labelColor: SlideRuleCoreV3.LabelColor) -> Color {
        Color(
            red: labelColor.red,
            green: labelColor.green,
            blue: labelColor.blue,
            opacity: labelColor.alpha
        )
    }
    
    /// Convert an RGB tuple to SwiftUI Color (graceful helper for older definitions)
    private func colorFromTuple(_ tuple: (red: Double, green: Double, blue: Double)) -> Color {
        Color(red: tuple.red, green: tuple.green, blue: tuple.blue)
    }
    
    /// Get font with specified style (PostScript NumFontRi, NumFontLi support)
    private func fontForStyle(_ style: SlideRuleCoreV3.LabelFontStyle, size: CGFloat) -> Font {
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
    private func fontSizeForTick(_ relativeLength: Double) -> CGFloat {
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
