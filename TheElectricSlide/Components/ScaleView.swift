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

/// Debug flag for split scale Canvas size diagnostics
private let DEBUG_SPLIT_CANVAS = true

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
    
    /// Optional background gradient to draw in Canvas instead of using .background() modifier
    /// Drawing in Canvas eliminates VStack preference propagation during parent view updates
    let backgroundGradient: ScaleBackgroundGradient?
    
    // ✅ Stored properties initialized once per view instance, not per access
    // These avoid repeated computation when properties are accessed multiple times
    private let tickRenderer: ScaleTickRenderer
    private let labelRenderer: ScaleLabelRenderer
    private let scaleLabelColor: Color
    
    init(
        generatedScale: GeneratedScale,
        width: CGFloat,
        height: CGFloat,
        leftMarginWidth: CGFloat,
        rightMarginWidth: CGFloat,
        nameFont: Font,
        formulaFont: Font,
        backgroundGradient: ScaleBackgroundGradient? = nil
    ) {
        self.generatedScale = generatedScale
        self.width = width
        self.height = height
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
        self.nameFont = nameFont
        self.formulaFont = formulaFont
        self.backgroundGradient = backgroundGradient
        
        // Initialize renderers once during init instead of on each access
        self.tickRenderer = ScaleTickRenderer(definition: generatedScale.definition)
        self.labelRenderer = ScaleLabelRenderer(definition: generatedScale.definition)
        
        // Initialize scale label color once during init instead of on each access
        if let tupleColor = generatedScale.definition.labelColor,
           generatedScale.definition.colorApplication.scaleName {
            self.scaleLabelColor = Color(red: tupleColor.red, green: tupleColor.green, blue: tupleColor.blue)
        } else {
            self.scaleLabelColor = .black
        }
    }
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    // This prevents unnecessary Canvas redraws when parent views re-evaluate
    static func == (lhs: ScaleView, rhs: ScaleView) -> Bool {
        lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.nameFont == rhs.nameFont &&
        lhs.formulaFont == rhs.formulaFont &&
        lhs.generatedScale.definition.name == rhs.generatedScale.definition.name &&
        lhs.generatedScale.tickMarks.count == rhs.generatedScale.tickMarks.count &&
        lhs.backgroundGradient == rhs.backgroundGradient
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Scale name label on the left (right-aligned with responsive width)
            // Use displayName if available (for aliases like W2→Sq2), otherwise use canonical name
            let scaleLabel = generatedScale.definition.displayName ?? generatedScale.definition.name
            
            Text(scaleLabel)
                .font(nameFont)
                .foregroundColor(self.scaleLabelColor)
                .frame(width: leftMarginWidth, alignment: .trailing)
                .accessibilityIdentifier("scale-name-\(scaleLabel)")
            
            // Scale view
            ZStack(alignment: .topLeading) {
                // Tick marks and labels
                Canvas { context, size in
                    // DEBUG: Log Canvas size for split scales
                    if DEBUG_SPLIT_CANVAS && (generatedScale.definition.name.contains("Θ") || generatedScale.definition.name.contains("θ")) {
                        print("🎨 [CANVAS] \(generatedScale.definition.name): size=(\(size.width), \(size.height)), passed height=\(height), tickDir=\(generatedScale.definition.tickDirection)")
                        if let segment = generatedScale.definition.splitSegment {
                            print("   splitSegment: \(segment)")
                        }
                    }
                    
                    // ✅ OPTIMIZATION: Draw background gradient in Canvas instead of .background()
                    // This eliminates VStack preference propagation during drag updates
                    if let gradient = backgroundGradient {
                        drawBackgroundGradient(context: &context, size: size, gradient: gradient)
                    }
                    
                    // ✅ Use pre-computed tick marks from GeneratedScale
                    drawScale(
                        context: &context,
                        size: size,
                        tickMarks: generatedScale.tickMarks,
                        definition: generatedScale.definition
                    )
                }
                .drawingGroup()  // Metal-accelerated rendering for 200+ tick marks
                .accessibilityIdentifier("scale-canvas-\(generatedScale.definition.name)")
            }
            // ✅ FIXED HEIGHT: Use fixed frame to ensure Canvas gets consistent size
            // This is critical for split scale ZStack rendering where both scales
            // must have identical Canvas dimensions for proper tick alignment
            .frame(width: width, height: height)
            .accessibilityIdentifier("scale-tickarea-\(generatedScale.definition.name)")
            
            // Formula label on the right (left-aligned with responsive width)
            Text(generatedScale.definition.formula)
                .font(formulaFont)
                .tracking((generatedScale.definition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black)
                .frame(width: rightMarginWidth, alignment: .leading)
                .accessibilityIdentifier("scale-formula-\(generatedScale.definition.name)")
        }
        .frame(height: height)  // Ensure consistent height for split scale ZStack alignment
        .accessibilityIdentifier("scaleview-\(generatedScale.definition.name)")
    }
    
    /// Draw the scale with pre-computed tick marks
    ///
    /// **Optimization (Step 2 - December 2025):**
    /// Uses batched tick drawing to minimize CGContext state changes.
    /// All ticks are drawn in a single `withCGContext` block, grouped by line width.
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
            
            // Log every redraw for L/Ln scales, LL scales, or periodically for others
            if definition.name == "L" || definition.name == "Ln" || definition.name.contains("LL") || redrawId <= 10 || redrawId % 50 == 0 {
                print("🎨 [Canvas REDRAW #\(redrawId)] scale=\(definition.name) size=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height))) width_prop=\(String(format: "%.2f", self.width)) height_prop=\(String(format: "%.2f", self.height)) tickCount=\(tickMarks.count)")
                
                // Log if there's a mismatch between passed size and view property
                if abs(size.width - width) > 0.5 || abs(size.height - height) > 0.5 {
                    print("⚠️ SIZE MISMATCH: Canvas size differs from view props! canvas=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height))) props=(\(String(format: "%.2f", self.width))x\(String(format: "%.2f", self.height)))")
                }
                
                // DEBUG: For Ln scale, log first few tick details
                if definition.name == "Ln" {
                    print("🔍 [Ln DEBUG] First 5 ticks:")
                    for (idx, tick) in tickMarks.prefix(5).enumerated() {
                        print("  Tick \(idx): value=\(tick.value), normPos=\(tick.normalizedPosition), relLen=\(tick.style.relativeLength), isNaN=\(tick.normalizedPosition.isNaN)")
                    }
                }
            }
        }
        
        // Draw baseline if enabled
        tickRenderer.drawBaseline(context: &context, size: size)
        
        // Draw separator line if enabled
        tickRenderer.drawSeparator(context: &context, size: size)
        
        // ✅ OPTIMIZED: Draw all ticks in a single batched operation
        // Returns pre-computed geometry for label positioning
        let tickGeometries = tickRenderer.drawTicksBatched(
            context: &context,
            tickMarks: tickMarks,
            size: size
        )
        
        // Draw labels using pre-computed geometry
        for geometry in tickGeometries {
            // Skip invalid geometries (from NaN ticks)
            guard geometry.tickHeight > 0 else { continue }
            
            let tick = tickMarks[geometry.tickIndex]
            
            // Draw labels using the label renderer
            if !tick.labels.isEmpty {
                labelRenderer.drawLabels(
                    context: &context,
                    labels: tick.labels,
                    xPos: geometry.xPos,
                    tickHeight: geometry.tickHeight,
                    tickDirection: definition.tickDirection,
                    size: size,
                    tickRelativeLength: tick.style.relativeLength
                )
            } else if let labelText = tick.label {
                // Backward compatibility: simple label rendering
                labelRenderer.drawSimpleLabel(
                    context: &context,
                    text: labelText,
                    xPos: geometry.xPos,
                    tickHeight: geometry.tickHeight,
                    tickDirection: definition.tickDirection,
                    size: size,
                    tickRelativeLength: tick.style.relativeLength
                )
            }
        }
    }
    
    /// Draws a vertical gradient background in the Canvas
    /// This replaces SwiftUI's .background() modifier to eliminate preference propagation
    ///
    /// **Optimization (December 2025):**
    /// Moving gradient drawing from .background() modifier into Canvas eliminates
    /// VStack preference updates during drag gestures (reduces ~3000 updates to near zero)
    private func drawBackgroundGradient(
        context: inout GraphicsContext,
        size: CGSize,
        gradient: ScaleBackgroundGradient
    ) {
        // Convert ScaleBackgroundGradient stops to SwiftUI Gradient.Stop
        let swiftUIStops = gradient.stops.map { stop in
            Gradient.Stop(color: stop.color, location: stop.location)
        }
        
        let swiftUIGradient = Gradient(stops: swiftUIStops)
        
        // Create the appropriate gradient based on direction
        let shading: GraphicsContext.Shading
        if gradient.isVertical {
            shading = .linearGradient(
                swiftUIGradient,
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        } else {
            shading = .linearGradient(
                swiftUIGradient,
                startPoint: CGPoint(x: 0, y: size.height / 2),
                endPoint: CGPoint(x: size.width, y: size.height / 2)
            )
        }
        
        // Fill the entire canvas area with the gradient
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: shading)
    }
}
