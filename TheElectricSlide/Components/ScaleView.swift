//
//  ScaleView.swift
//  TheElectricSlide
//
//  Core scale rendering component that draws tick marks and labels.
//  Tick rendering is delegated to ScaleTickRenderer.
//  Label rendering is delegated to ScaleLabelRenderer.
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

struct ScaleView: View, Equatable {
    let generatedScale: GeneratedScale  // ✅ Use pre-computed GeneratedScale
    let width: CGFloat
    let height: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    // This prevents unnecessary Canvas redraws when parent views re-evaluate
    static func == (lhs: ScaleView, rhs: ScaleView) -> Bool {
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.generatedScale.definition.name == rhs.generatedScale.definition.name &&
        lhs.generatedScale.tickMarks.count == rhs.generatedScale.tickMarks.count
    }
    
    // Compute renderers once per view instance, not per Canvas redraw
    private var tickRenderer: ScaleTickRenderer {
        ScaleTickRenderer(definition: generatedScale.definition)
    }
    
    private var labelRenderer: ScaleLabelRenderer {
        ScaleLabelRenderer(definition: generatedScale.definition)
    }
    
    // Compute scale label color once per view instance, not in body
    private var scaleLabelColor: Color {
        if let tupleColor = generatedScale.definition.labelColor,
           generatedScale.definition.colorApplication.scaleName {
            return Color(red: tupleColor.red, green: tupleColor.green, blue: tupleColor.blue)
        } else {
            return .black
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Scale name label on the left (right-aligned with responsive width)
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
        
        // Use pre-computed renderers from view properties (avoids recreation on each Canvas redraw)
        
        // Draw baseline if enabled
        tickRenderer.drawBaseline(context: &context, size: size)
        
        // Draw tick marks and labels
        for tick in tickMarks {
            // Draw tick mark and get geometry for label positioning
            let (xPos, tickHeight) = tickRenderer.drawTick(
                context: &context,
                tick: tick,
                size: size
            )
            
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

