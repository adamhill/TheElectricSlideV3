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

/// TEST FLAG: Set to true to suppress ALL formulas for Phase 2 annotation testing
/// TODO: Remove this flag after testing is complete
private let DEBUG_SUPPRESS_ALL_FORMULAS = false

// MARK: - RuleDisplaySettings Environment Key

/// Environment key for rule-level display settings
/// Allows ScaleView to access rule-level name/formula visibility settings
/// without prop drilling through StatorView/SlideView/ScaleContainerView
private struct RuleDisplaySettingsKey: EnvironmentKey {
    static let defaultValue: RuleDisplaySettings = .standard
}

extension EnvironmentValues {
    var ruleDisplaySettings: RuleDisplaySettings {
        get { self[RuleDisplaySettingsKey.self] }
        set { self[RuleDisplaySettingsKey.self] = newValue }
    }
}

// MARK: - ScaleView Component

struct ScaleView: View, Equatable {
    @Environment(\.ruleDisplaySettings) private var ruleDisplaySettings
    @Environment(\.dimensions) private var dimensions
    
    let generatedScale: GeneratedScale  // ✅ Use pre-computed GeneratedScale
    
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
        backgroundGradient: ScaleBackgroundGradient? = nil
    ) {
        self.generatedScale = generatedScale
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
    // Note: dimensions come from @Environment and are compared via SwiftUI's environment diffing
    static func == (lhs: ScaleView, rhs: ScaleView) -> Bool {
        lhs.generatedScale.definition.name == rhs.generatedScale.definition.name &&
        lhs.generatedScale.tickMarks.count == rhs.generatedScale.tickMarks.count &&
        lhs.backgroundGradient == rhs.backgroundGradient
    }
    
    // MARK: - Computed Margin Content
    
    /// Determines which margin the scale name should appear in, considering rule and scale settings
    /// Priority: per-scale scaleNameMargin > rule default > legacy suppressScaleNameLabel
    private var effectiveScaleNameMargin: MarginSide {
        // If rule-level says don't show names, return .none
        guard ruleDisplaySettings.showScaleNames else { return .none }
        
        // Check for per-scale override first
        if let perScaleMargin = generatedScale.definition.scaleNameMargin {
            // DEBUG: Log when per-scale margin is found
            print("📛 Scale '\(generatedScale.definition.name)' has per-scale margin: \(perScaleMargin)")
            return perScaleMargin
        }
        
        // Fall back to legacy suppress flag for backward compatibility
        if generatedScale.definition.suppressScaleNameLabel {
            return .none
        }
        
        // Use rule-level default
        return ruleDisplaySettings.defaultScaleNameMargin
    }
    
    /// Determines which margin the formula should appear in, considering rule and scale settings
    /// Priority: per-scale formulaMargin > rule default > legacy suppressFormulaLabel
    private var effectiveFormulaMargin: MarginSide {
        // If rule-level says don't show formulas, return .none
        guard ruleDisplaySettings.showFormulas else { return .none }
        
        // Check for per-scale override first
        if let perScaleMargin = generatedScale.definition.formulaMargin {
            return perScaleMargin
        }
        
        // Fall back to legacy suppress flag for backward compatibility
        if generatedScale.definition.suppressFormulaLabel {
            return .none
        }
        
        // Use rule-level default
        return ruleDisplaySettings.defaultFormulaMargin
    }
    
    var body: some View {
        let scaleLabel = generatedScale.definition.displayName ?? generatedScale.definition.name
        let nameMargin = effectiveScaleNameMargin
        let formulaMargin = effectiveFormulaMargin
        
        HStack(alignment: .center, spacing: CursorCoordinateSystem.scaleHStackSpacing) {
            // Left margin content
            leftMarginContent(scaleLabel: scaleLabel, nameMargin: nameMargin, formulaMargin: formulaMargin)
            
            // Scale view (tick marks and labels)
            scaleCanvas
            
            // Right margin content
            rightMarginContent(scaleLabel: scaleLabel, nameMargin: nameMargin, formulaMargin: formulaMargin)
        }
        .frame(height: dimensions.scaleHeight)  // Ensure consistent height for split scale ZStack alignment
        .accessibilityIdentifier("scaleview-\(generatedScale.definition.name)")
    }
    
    /// Left margin content: custom annotations, scale name, formula, or empty spacer
    @ViewBuilder
    private func leftMarginContent(scaleLabel: String, nameMargin: MarginSide, formulaMargin: MarginSide) -> some View {
        // Priority 1: Custom left annotations (if non-empty)
        if !generatedScale.definition.leftAnnotations.isEmpty {
            leftMarginAnnotationsView
                .frame(width: dimensions.leftMarginWidth, alignment: .trailing)
                .accessibilityIdentifier("scale-left-annotations-\(scaleLabel)")
        }
        // Priority 2: Scale name (if configured for left margin)
        else if nameMargin == .left {
            Text(scaleLabel)
                .font(dimensions.nameFont)
                .foregroundColor(scaleLabelColor)
                .offset(
                    x: generatedScale.definition.nameNudge?.horizontalOffset ?? 0,
                    y: generatedScale.definition.nameNudge?.verticalOffset ?? 0
                )
                .frame(width: dimensions.leftMarginWidth, alignment: .trailing)
                .accessibilityIdentifier("scale-name-\(scaleLabel)")
        }
        // Priority 3: Formula (if configured for left margin - unusual but supported)
        else if formulaMargin == .left {
            Text(generatedScale.definition.formula)
                .font(dimensions.formulaFont)
                .tracking((generatedScale.definition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black)
                .frame(width: dimensions.leftMarginWidth, alignment: .trailing)
                .accessibilityIdentifier("scale-formula-left-\(generatedScale.definition.name)")
        }
        // Priority 4: Empty spacer to maintain layout
        else {
            Spacer()
                .frame(width: dimensions.leftMarginWidth)
        }
    }
    
    /// Right margin content: custom annotations, formula, scale name, or empty spacer
    @ViewBuilder
    private func rightMarginContent(scaleLabel: String, nameMargin: MarginSide, formulaMargin: MarginSide) -> some View {
        // Priority 1: Custom right annotations (if non-empty)
        if !generatedScale.definition.rightAnnotations.isEmpty {
            rightMarginAnnotationsView
                .frame(width: dimensions.rightMarginWidth, alignment: .leading)
                .accessibilityIdentifier("scale-right-annotations-\(generatedScale.definition.name)")
        }
        // Priority 2: Formula (if configured for right margin - traditional)
        else if formulaMargin == .right {
            Text(generatedScale.definition.formula)
                .font(dimensions.formulaFont)
                .tracking((generatedScale.definition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black)
                .frame(width: dimensions.rightMarginWidth, alignment: .leading)
                .accessibilityIdentifier("scale-formula-\(generatedScale.definition.name)")
        }
        // Priority 3: Scale name (if configured for right margin - Graphoplex style)
        else if nameMargin == .right {
            Text(scaleLabel)
                .font(dimensions.nameFont)
                .foregroundColor(scaleLabelColor)
                .offset(
                    x: generatedScale.definition.nameNudge?.horizontalOffset ?? 0,
                    y: generatedScale.definition.nameNudge?.verticalOffset ?? 0
                )
                .frame(width: dimensions.rightMarginWidth, alignment: .leading)
                .accessibilityIdentifier("scale-name-right-\(scaleLabel)")
        }
        // Priority 4: Empty spacer to maintain layout
        else {
            Spacer()
                .frame(width: dimensions.rightMarginWidth)
        }
    }
    
    /// Scale canvas view - tick marks and labels
    private var scaleCanvas: some View {
        ZStack(alignment: .topLeading) {
            // Tick marks and labels
            Canvas { context, size in
                // DEBUG: Log Canvas size for split scales
                if DEBUG_SPLIT_CANVAS && (generatedScale.definition.name.contains("Θ") || generatedScale.definition.name.contains("θ")) {
                    print("🎨 [CANVAS] \(generatedScale.definition.name): size=(\(size.width), \(size.height)), passed height=\(dimensions.scaleHeight), tickDir=\(generatedScale.definition.tickDirection)")
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
        .frame(width: dimensions.width, height: dimensions.scaleHeight)
        .accessibilityIdentifier("scale-tickarea-\(generatedScale.definition.name)")
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
                print("🎨 [Canvas REDRAW #\(redrawId)] scale=\(definition.name) size=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height))) width_prop=\(String(format: "%.2f", dimensions.width)) height_prop=\(String(format: "%.2f", dimensions.scaleHeight)) tickCount=\(tickMarks.count)")
                
                // Log if there's a mismatch between passed size and view property
                if abs(size.width - dimensions.width) > 0.5 || abs(size.height - dimensions.scaleHeight) > 0.5 {
                    print("⚠️ SIZE MISMATCH: Canvas size differs from view props! canvas=(\(String(format: "%.2f", size.width))x\(String(format: "%.2f", size.height))) props=(\(String(format: "%.2f", dimensions.width))x\(String(format: "%.2f", dimensions.scaleHeight)))")
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
    
    // MARK: - Margin Annotation Views
    
    /// Renders left margin annotations as a vertical stack
    /// Used when `leftAnnotations` is non-empty to replace the default scale name
    @ViewBuilder
    private var leftMarginAnnotationsView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(generatedScale.definition.leftAnnotations.enumerated()), id: \.offset) { _, annotation in
                marginAnnotationText(annotation, alignment: .trailing)
            }
        }
    }
    
    /// Renders right margin annotations as a vertical stack
    /// Used when `rightAnnotations` is non-empty to replace the default formula
    @ViewBuilder
    private var rightMarginAnnotationsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(generatedScale.definition.rightAnnotations.enumerated()), id: \.offset) { _, annotation in
                marginAnnotationText(annotation, alignment: .leading)
            }
        }
    }
    
    /// Creates a Text view for a single margin annotation with proper styling
    /// - Parameters:
    ///   - annotation: The MarginAnnotation containing text, color, offset, and font size multiplier
    ///   - alignment: Text alignment (.trailing for left margin, .leading for right margin)
    @ViewBuilder
    private func marginAnnotationText(_ annotation: MarginAnnotation, alignment: Alignment) -> some View {
        let baseFont = alignment == .trailing ? dimensions.nameFont : dimensions.formulaFont
        let color = Color(
            red: annotation.color.red,
            green: annotation.color.green,
            blue: annotation.color.blue,
            opacity: annotation.color.alpha
        )
        
        Text(annotation.text)
            .font(baseFont)
            .foregroundColor(color)
            .offset(x: annotation.offset.horizontal, y: annotation.offset.vertical)
    }
}
