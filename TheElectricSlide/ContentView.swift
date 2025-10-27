//
//  ContentView.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/18/25.
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

// NOTE:
// `onGeometryChange(for:)` requires the value type to be usable across isolation domains.
// A main-actor–isolated conformance to `Equatable` cannot satisfy a generic `Sendable` requirement.
// By making the type's conformances `nonisolated` and using `@unchecked Sendable` for this trivial
// value type (two `CGFloat`s), we assert it's safe to pass across tasks/actors.
// This avoids the compiler error: "Main actor-isolated conformance ... cannot satisfy conformance
// requirement for a 'Sendable' type parameter".
nonisolated struct Dimensions: Equatable, @unchecked Sendable {
    var width: CGFloat
    var scaleHeight: CGFloat
}

// MARK: - View Mode

enum ViewMode: String, CaseIterable, Identifiable {
    case front = "Front"
    case back = "Back"
    case both = "Both"
    
    var id: String { rawValue }
}

// MARK: - Rule Side

enum RuleSide: String, Sendable {
    case front = "Front (Side A)"
    case back = "Back (Side B)"
    
    var displayName: String { rawValue }
    var borderColor: Color {
        switch self {
        case .front: return .blue
        case .back: return .green
        }
    }
}

// MARK: - ScaleView Component

struct ScaleView: View {
    let generatedScale: GeneratedScale  // ✅ Use pre-computed GeneratedScale
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Scale name label on the left (right-aligned with minimum width)
            Text(generatedScale.definition.name)
                .font(.caption2)
                .foregroundColor(.black)
                .frame(minWidth: 28, alignment: .trailing)
            
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
            
            // Formula label on the right
            Text(generatedScale.definition.formula)
                .font(.caption2)
                .tracking((generatedScale.definition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black)
                .frame(width: 40, alignment: .leading)
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
            let tickPath = Path { path in
                path.move(to: CGPoint(x: xPos, y: tickStartY))
                path.addLine(to: CGPoint(x: xPos, y: tickEndY))
            }
            
            context.withCGContext { cgContext in
                cgContext.setShouldAntialias(false)
                context.stroke(
                    tickPath,
                    with: .color(.black),
                    lineWidth: tick.style.lineWidth / 1.5
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
                    tickRelativeLength: tick.style.relativeLength
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
            
            let text = Text(labelConfig.text)
                .font(font)
                .foregroundColor(colorFromLabelColor(labelConfig.color))
            
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
        tickRelativeLength: Double
    ) {
        let fontSize = fontSizeForTick(tickRelativeLength)
        guard fontSize > 0 else { return }
        
        let label = Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(.black)
        
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

// MARK: - StatorView Component (renders multiple scales)

struct StatorView: View, Equatable {
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.stator.scales.count == rhs.stator.scales.count &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor
    }
    
    // Calculate total max height based on number of scales
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(stator.scales.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stator.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    generatedScale: generatedScale,  // ✅ Pass entire GeneratedScale
                    width: width,
                    height: scaleHeight
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            Group {
                if stator.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - SlideView Component (renders multiple scales)

struct SlideView: View, Equatable {
    let slide: Slide
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    static func == (lhs: SlideView, rhs: SlideView) -> Bool {
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor
    }
    
    // Calculate total max height based on number of scales
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(slide.scales.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(slide.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    generatedScale: generatedScale,  // ✅ Pass entire GeneratedScale
                    width: width,
                    height: scaleHeight
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            Group {
                if slide.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - SideView Component (renders complete side: top stator, slide, bottom stator)

struct SideView: View, Equatable {
    let side: RuleSide
    let topStator: Stator
    let slide: Slide
    let bottomStator: Stator
    let width: CGFloat
    let scaleHeight: CGFloat
    let sliderOffset: CGFloat
    let showLabel: Bool  // Whether to show "Front (Side A)" / "Back (Side B)" label
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    // ✅ Equatable conformance - only compare properties affecting rendering (not closures)
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        lhs.side == rhs.side &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.sliderOffset == rhs.sliderOffset &&
        lhs.showLabel == rhs.showLabel &&
        lhs.topStator.scales.count == rhs.topStator.scales.count &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.bottomStator.scales.count == rhs.bottomStator.scales.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Optional side label
            if showLabel {
                Text(side.displayName)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            // Top Stator (Fixed)
            StatorView(
                stator: topStator,
                width: width,
                backgroundColor: .white,
                borderColor: side.borderColor,
                scaleHeight: scaleHeight
            )
            .equatable()
            .id("\(side.rawValue)-topStator")
            
            // Slide (Movable)
            SlideView(
                slide: slide,
                width: width,
                backgroundColor: .white,
                borderColor: .orange,
                scaleHeight: scaleHeight
            )
            .equatable()
            .offset(x: sliderOffset)
            .gesture(
                DragGesture()
                    .onChanged(onDragChanged)
                    .onEnded(onDragEnded)
            )
            .animation(.interactiveSpring(), value: sliderOffset)
            .id("\(side.rawValue)-slide")
            
            // Bottom Stator (Fixed)
            StatorView(
                stator: bottomStator,
                width: width,
                backgroundColor: .white,
                borderColor: side.borderColor,
                scaleHeight: scaleHeight
            )
            .equatable()
            .id("\(side.rawValue)-bottomStator")
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var currentRuleQuery: [CurrentSlideRule]
    
    @State private var sliderOffset: CGFloat = 0
    @State private var sliderBaseOffset: CGFloat = 0  // ✅ Persists offset between gestures
    @State private var viewMode: ViewMode = .both  // View mode selector
    // ✅ State for calculated dimensions - only updates when window size changes

    @State private var calculatedDimensions: Dimensions = .init(width: 800, scaleHeight: 25)
    @State private var cursorState = CursorState()
    
    // Current slide rule selection (persisted via SwiftData)
    @State private var selectedRuleDefinition: SlideRuleDefinitionModel?
    @State private var selectedRuleId: UUID? // Track ID separately for onChange
    
    // Parsed slide rule from definition - published state to trigger re-renders
    @State private var currentSlideRule: SlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
    
    // ✅ Helper to create a blank spacer scale for balancing
    private func createSpacerScale(length: Double) -> GeneratedScale {
        let spacerDefinition = ScaleDefinition(
            name: "",
            formula: "",
            function: LinearFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: length,
            layout: .linear,
            tickDirection: .up,
            subsections: [],
            showBaseline: false,
            formulaTracking: 1.0
        )
        return GeneratedScale(definition: spacerDefinition)
    }
    
    // Scale height configuration
    private let minScaleHeight: CGFloat = 20   // Minimum height for a scale
    private let idealScaleHeight: CGFloat = 25 // Ideal height per scale
    private let maxScaleHeight: CGFloat = 30   // Maximum height per scale
    
    // Target aspect ratio (width:height) for slide rule
    // Slide rules are typically very wide and relatively short (10:1 to 8:1)
    private let targetAspectRatio: CGFloat = 10.0
    
    // Padding around the slide rule
    private let padding: CGFloat = 40
    
    // Access current slide rule (now a @State variable, not computed)
    private var slideRule: SlideRule {
        currentSlideRule
    }
    
    // ✅ Balanced stators and slides - adds spacers to match scale counts
    private var balancedFrontTopStator: Stator {
        guard viewMode == .both,
              let backTop = slideRule.backTopStator else {
            return slideRule.frontTopStator
        }
        
        let frontCount = slideRule.frontTopStator.scales.count
        let backCount = backTop.scales.count
        
        if frontCount < backCount {
            let spacersNeeded = backCount - frontCount
            var balancedScales = slideRule.frontTopStator.scales
            for _ in 0..<spacersNeeded {
                balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
            }
            return Stator(
                name: slideRule.frontTopStator.name,
                scales: balancedScales,
                heightInPoints: slideRule.frontTopStator.heightInPoints,
                showBorder: slideRule.frontTopStator.showBorder
            )
        }
        return slideRule.frontTopStator
    }
    
    private var balancedFrontSlide: Slide {
        guard viewMode == .both,
              let backSlide = slideRule.backSlide else {
            return slideRule.frontSlide
        }
        
        let frontCount = slideRule.frontSlide.scales.count
        let backCount = backSlide.scales.count
        
        if frontCount < backCount {
            let spacersNeeded = backCount - frontCount
            var balancedScales = slideRule.frontSlide.scales
            for _ in 0..<spacersNeeded {
                balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
            }
            return Slide(
                name: slideRule.frontSlide.name,
                scales: balancedScales,
                heightInPoints: slideRule.frontSlide.heightInPoints,
                showBorder: slideRule.frontSlide.showBorder
            )
        }
        return slideRule.frontSlide
    }
    
    private var balancedFrontBottomStator: Stator {
        guard viewMode == .both,
              let backBottom = slideRule.backBottomStator else {
            return slideRule.frontBottomStator
        }
        
        let frontCount = slideRule.frontBottomStator.scales.count
        let backCount = backBottom.scales.count
        
        if frontCount < backCount {
            let spacersNeeded = backCount - frontCount
            var balancedScales = slideRule.frontBottomStator.scales
            for _ in 0..<spacersNeeded {
                balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
            }
            return Stator(
                name: slideRule.frontBottomStator.name,
                scales: balancedScales,
                heightInPoints: slideRule.frontBottomStator.heightInPoints,
                showBorder: slideRule.frontBottomStator.showBorder
            )
        }
        return slideRule.frontBottomStator
    }
    
    private var balancedBackTopStator: Stator? {
        guard viewMode == .both,
              let backTop = slideRule.backTopStator else {
            return slideRule.backTopStator
        }
        
        let frontCount = slideRule.frontTopStator.scales.count
        let backCount = backTop.scales.count
        
        if backCount < frontCount {
            let spacersNeeded = frontCount - backCount
            var balancedScales = backTop.scales
            for _ in 0..<spacersNeeded {
                balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
            }
            return Stator(
                name: backTop.name,
                scales: balancedScales,
                heightInPoints: backTop.heightInPoints,
                showBorder: backTop.showBorder
            )
        }
        return backTop
    }
    
    private var balancedBackSlide: Slide? {
        guard viewMode == .both,
              let backSlide = slideRule.backSlide else {
            return slideRule.backSlide
        }
        
        let frontCount = slideRule.frontSlide.scales.count
        let backCount = backSlide.scales.count
        
        if backCount < frontCount {
            let spacersNeeded = frontCount - backCount
            var balancedScales = backSlide.scales
            for _ in 0..<spacersNeeded {
                balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
            }
            return Slide(
                name: backSlide.name,
                scales: balancedScales,
                heightInPoints: backSlide.heightInPoints,
                showBorder: backSlide.showBorder
            )
        }
        return backSlide
    }
    
    private var balancedBackBottomStator: Stator? {
        guard viewMode == .both,
              let backBottom = slideRule.backBottomStator else {
            return slideRule.backBottomStator
        }
        
        let frontCount = slideRule.frontBottomStator.scales.count
        let backCount = backBottom.scales.count
        
        if backCount < frontCount {
            let spacersNeeded = frontCount - backCount
            var balancedScales = backBottom.scales
            for _ in 0..<spacersNeeded {
                balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
            }
            return Stator(
                name: backBottom.name,
                scales: balancedScales,
                heightInPoints: backBottom.heightInPoints,
                showBorder: backBottom.showBorder
            )
        }
        return backBottom
    }
    
    // Calculate total number of scales based on view mode
    private var totalScaleCount: Int {
        var count = 0
        
        // Front side scales
        if viewMode == .front || viewMode == .both {
            count += slideRule.frontTopStator.scales.count +
                     slideRule.frontSlide.scales.count +
                     slideRule.frontBottomStator.scales.count
        }
        
        // Back side scales (if available)
        if (viewMode == .back || viewMode == .both),
           let backTop = slideRule.backTopStator,
           let backSlide = slideRule.backSlide,
           let backBottom = slideRule.backBottomStator {
            count += backTop.scales.count +
                     backSlide.scales.count +
                     backBottom.scales.count
        }
        
        return count
    }
    
    // Calculate number of "gaps" between sides for spacing
    private var sideGapCount: Int {
        // If showing both sides, we have 1 gap between them (20pt spacing)
        if viewMode == .both && slideRule.backTopStator != nil {
            return 1
        }
        return 0
    }
    
    // Vertical spacing between sides when showing both
    private let sideSpacing: CGFloat = 20
    
    // Estimate total vertical space needed for labels (when showing both sides)
    private var labelHeight: CGFloat {
        if viewMode == .both && slideRule.backTopStator != nil {
            return 30  // ~15pt per label × 2 labels
        }
        return 0
    }
    
    // Helper function to calculate responsive dimensions
    @MainActor
    private func calculateDimensions(availableWidth: CGFloat, availableHeight: CGFloat) -> Dimensions {
        let maxWidth = availableWidth - (padding * 2)
        let maxHeight = availableHeight - (padding * 2)
        
        // Account for spacing between sides and labels
        let totalSpacingHeight = (CGFloat(sideGapCount) * sideSpacing) + labelHeight
        let availableHeightForScales = maxHeight - totalSpacingHeight
        
        // Calculate scale height based on available height
        let calculatedScaleHeight = min(
            availableHeightForScales / CGFloat(totalScaleCount),
            maxScaleHeight
        )
        let scaleHeight = max(calculatedScaleHeight, minScaleHeight)
        
        // Calculate total height needed for all scales
        let totalHeight = scaleHeight * CGFloat(totalScaleCount) + totalSpacingHeight
        
        // Calculate width based on aspect ratio
        let widthFromAspectRatio = totalHeight * targetAspectRatio
        
        // Use the smaller of the two to ensure it fits within window
        let width = min(maxWidth, widthFromAspectRatio)
        
        return Dimensions(width: width, scaleHeight: scaleHeight)
    }
    
    /// Calculate total vertical height for all scales on a given side
    /// - Parameter side: The rule side to calculate height for
    /// - Returns: Total height in points
    private func totalScaleHeight(for side: RuleSide) -> CGFloat {
        let stator: Stator
        let slide: Slide
        let bottomStator: Stator
        
        switch side {
        case .front:
            stator = balancedFrontTopStator
            slide = balancedFrontSlide
            bottomStator = balancedFrontBottomStator
        case .back:
            guard let backTop = balancedBackTopStator,
                  let backSlide = balancedBackSlide,
                  let backBottom = balancedBackBottomStator else {
                return 0
            }
            stator = backTop
            slide = backSlide
            bottomStator = backBottom
        }
        
        let scaleCount = stator.scales.count +
                         slide.scales.count +
                         bottomStator.scales.count
        return CGFloat(scaleCount) * calculatedDimensions.scaleHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Slide Rule Picker
            SlideRulePicker(currentRule: $selectedRuleDefinition)
            
            Divider()
            
            // View Mode Picker
            HStack {
                Spacer()
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                .padding(.horizontal)
                .padding(.top, 8)
                // Disable back/both if no back side available
                .disabled(slideRule.backTopStator == nil && (viewMode == .back || viewMode == .both))
                Spacer()
            }
            
            // Main slide rule content
            VStack(spacing: 20) {
                // Front side - show if mode is .front or .both
                if viewMode == .front || viewMode == .both {
                    VStack(spacing: 4) {
                        // Cursor readings display above slide rule
                        if cursorState.isEnabled {
                            CursorReadingsDisplayView(
                                readings: cursorState.currentReadings?.frontReadings ?? [],
                                side: .front
                            )
                            .frame(maxWidth: calculatedDimensions.width)
                        }
                        
                        SideView(
                            side: .front,
                            topStator: balancedFrontTopStator,
                            slide: balancedFrontSlide,
                            bottomStator: balancedFrontBottomStator,
                            width: calculatedDimensions.width,
                            scaleHeight: calculatedDimensions.scaleHeight,
                            sliderOffset: sliderOffset,
                            showLabel: viewMode == .both,
                            onDragChanged: handleDragChanged,
                            onDragEnded: handleDragEnded
                        )
                        .equatable()
                        .overlay {
                            CursorOverlay(
                                cursorState: cursorState,
                                width: calculatedDimensions.width,
                                height: totalScaleHeight(for: .front),
                                side: .front
                            )
                        }
                    }
                }
                
                // Back side - show if mode is .back or .both (and back side exists)
                if (viewMode == .back || viewMode == .both),
                   let backTop = balancedBackTopStator,
                   let backSlide = balancedBackSlide,
                   let backBottom = balancedBackBottomStator {
                    VStack(spacing: 4) {
                        // Cursor readings display above slide rule
                        if cursorState.isEnabled {                            CursorReadingsDisplayView(
                                readings: cursorState.currentReadings?.backReadings ?? [],
                                side: .back
                            )
                            .frame(maxWidth: calculatedDimensions.width)
                        }
                        
                        SideView(
                            side: .back,
                            topStator: backTop,
                            slide: backSlide,
                            bottomStator: backBottom,
                            width: calculatedDimensions.width,
                            scaleHeight: calculatedDimensions.scaleHeight,
                            sliderOffset: sliderOffset,
                            showLabel: viewMode == .both,
                            onDragChanged: handleDragChanged,
                            onDragEnded: handleDragEnded
                        )
                        .equatable()
                        .overlay {
                            CursorOverlay(
                                cursorState: cursorState,
                                width: calculatedDimensions.width,
                                height: totalScaleHeight(for: .back),
                                side: .back
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(padding)
        }
        // ✅ onGeometryChange - only updates calculatedDimensions when size actually changes
        .onGeometryChange(for: Dimensions.self) { proxy in
            // Extract ONLY the dimensions we need
            let size = proxy.size
            return calculateDimensions(
                availableWidth: size.width,
                availableHeight: size.height
            )
        } action: { newDimensions in
            // ONLY called when dimensions actually change (not on every geometry event)
            calculatedDimensions = newDimensions
        }
        .onAppear {
            // Connect cursor state to slide rule data
            cursorState.setSlideRuleProvider(self)
            // Enable cursor readings
            cursorState.enableReadings = true
            
            // Initialize current rule from persistence
            loadCurrentRule()
        }
        .onChange(of: sliderOffset) { oldValue, newValue in
            // Update cursor readings when slide moves
            // This ensures slide scale values update in real-time
            cursorState.updateReadings()
        }
        .onChange(of: selectedRuleDefinition) { oldValue, newValue in
            print("🔄 selectedRuleDefinition changed (object)")
            // Update ID tracker
            selectedRuleId = newValue?.id
        }
        .onChange(of: selectedRuleId) { oldValue, newValue in
            print("🔄 Rule selection changed: \(oldValue?.uuidString ?? "nil") -> \(newValue?.uuidString ?? "nil")")
            print("   New rule: \(selectedRuleDefinition?.name ?? "nil")")
            
            // Parse new slide rule when selection changes
            parseAndUpdateSlideRule()
            
            // Reset slider position when switching rules
            sliderOffset = 0
            sliderBaseOffset = 0
            
            // Persist selection
            saveCurrentRule()
        }
    }
    
    // ✅ Drag gesture handlers - single implementation for both sides
    private func handleDragChanged(_ gesture: DragGesture.Value) {
        let newOffset = sliderBaseOffset + gesture.translation.width
        sliderOffset = min(max(newOffset, -calculatedDimensions.width), 
                          calculatedDimensions.width)
    }
    
    private func handleDragEnded(_ gesture: DragGesture.Value) {
        sliderBaseOffset = sliderOffset
    }
    
    // MARK: - Persistence Helpers
    
    private func loadCurrentRule() {
        if let currentRule = currentRuleQuery.first {
            selectedRuleDefinition = currentRule.selectedRule
            selectedRuleId = currentRule.selectedRule?.id
        }
        // Parse initial slide rule
        parseAndUpdateSlideRule()
    }
    
    private func saveCurrentRule() {
        if let current = currentRuleQuery.first {
            current.updateSelection(selectedRuleDefinition!)
        } else {
            let newCurrent = CurrentSlideRule(selectedRule: selectedRuleDefinition)
            modelContext.insert(newCurrent)
        }
        
        try? modelContext.save()
    }
    
    private func parseAndUpdateSlideRule() {
        guard let definition = selectedRuleDefinition else {
            // Use default rule
            print("⚠️ No definition selected, using default")
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
            return
        }
        
        print("🔧 Parsing slide rule: \(definition.name)")
        print("   Definition: \(definition.definitionString)")
        
        do {
            let parsed = try definition.parseSlideRule(scaleLength: 1000)
            currentSlideRule = parsed
            print("✅ Successfully loaded slide rule: \(definition.name)")
            print("   Front scales: \(parsed.frontTopStator.scales.count) + \(parsed.frontSlide.scales.count) + \(parsed.frontBottomStator.scales.count)")
        } catch {
            print("❌ Failed to parse slide rule '\(definition.name)': \(error)")
            // Fallback to basic rule
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
        }
    }
}

// MARK: - SlideRuleProvider Conformance

extension ContentView: SlideRuleProvider {
    func getFrontScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)? {
        // Only return data if front side is visible
        guard viewMode == .front || viewMode == .both else {
            return nil
        }
        return (
            topStator: balancedFrontTopStator,
            slide: balancedFrontSlide,
            bottomStator: balancedFrontBottomStator
        )
    }
    
    func getBackScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)? {
        // Only return data if back side is visible
        guard viewMode == .back || viewMode == .both,
              let backTop = balancedBackTopStator,
              let backSlide = balancedBackSlide,
              let backBottom = balancedBackBottomStator else {
            return nil
        }
        return (backTop, backSlide, backBottom)
    }
    
    func getSlideOffset() -> CGFloat {
        sliderOffset
    }
    
    func getScaleWidth() -> CGFloat {
        calculatedDimensions.width
    }
}

#Preview {
    ContentView()
        .frame(width: 900)
}

