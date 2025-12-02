//
//  ScaleView.swift
//  TheElectricSlide
//
//  Core scale rendering component that draws tick marks and labels.
//  Label rendering is delegated to ScaleLabelRenderer for separation of concerns.
//
//  Extracted from ContentView.swift for better organization.
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Debug Logging

/// Debug flag - set to true to enable scale rendering diagnostics
private let DEBUG_SCALE_RENDERING = false

/// Track Canvas redraw count
private var canvasRedrawCount = 0

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
                    .drawingGroup()  // Metal-accelerated rendering for 200+ tick marks
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
        // Debug: Track Canvas redraws
        if DEBUG_SCALE_RENDERING {
            canvasRedrawCount += 1
            let redrawId = canvasRedrawCount
            
            // Log every redraw for LL scales, or periodically for others
            if definition.name.contains("LL") || redrawId <= 10 || redrawId % 50 == 0 {
                print("🎨 [Canvas REDRAW #\(redrawId)] scale=\(definition.name) size=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height))) width_prop=\(String(format: "%.2f", self.width)) height_prop=\(String(format: "%.2f", self.height)) tickCount=\(tickMarks.count)")
                
                // Log if there's a mismatch between passed size and view property
                if abs(size.width - width) > 0.5 || abs(size.height - height) > 0.5 {
                    print("⚠️ SIZE MISMATCH: Canvas size differs from view props! canvas=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height))) props=(\(String(format: "%.2f", self.width))x\(String(format: "%.2f", self.height)))")
                }
            }
        }
        
        // Create label renderer for this scale
        let labelRenderer = ScaleLabelRenderer(definition: definition)
        
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
            
            // Draw labels using the label renderer
            if !tick.labels.isEmpty {
                labelRenderer.drawLabels(
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
                labelRenderer.drawSimpleLabel(
                    context: &context,
                    text: labelText,
                    xPos: xPos,
                    tickHeight: tickHeight,
                    tickDirection: definition.tickDirection,
                    size: size,
                    tickRelativeLength: tick.style.relativeLength
                )
            }
        }
    }
}
