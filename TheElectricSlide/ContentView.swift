//
//  ContentView.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/18/25.
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

// MARK: - Responsive Layout Constants

/// Breakpoint widths for responsive layout tiers
/// Based on common device widths: iPhone SE (320pt), standard phones (480pt), tablets/wide windows (640pt+)
nonisolated(unsafe) private let kExtraLargeBreakpoint: CGFloat = 640
nonisolated(unsafe) private let kLargeBreakpoint: CGFloat = 480
nonisolated(unsafe) private let kMediumBreakpoint: CGFloat = 320

/// Margin widths for each responsive tier
/// Progressively smaller margins accommodate narrower screens while maintaining readability
nonisolated(unsafe) private let kExtraLargeMargin: CGFloat = 64
nonisolated(unsafe) private let kLargeMargin: CGFloat = 56
nonisolated(unsafe) private let kMediumMargin: CGFloat = 48
nonisolated(unsafe) private let kSmallMargin: CGFloat = 40

// NOTE:
// `onGeometryChange(for:)` requires the value type to be usable across isolation domains.
// A main-actor–isolated conformance to `Equatable` cannot satisfy a generic `Sendable` requirement.
// By making the type's conformances `nonisolated` and using `@unchecked Sendable` for this trivial
// value type, we assert it's safe to pass across tasks/actors.
// This avoids the compiler error: "Main actor-isolated conformance ... cannot satisfy conformance
// requirement for a 'Sendable' type parameter".
nonisolated struct Dimensions: Equatable, @unchecked Sendable {
    var width: CGFloat
    var scaleHeight: CGFloat
    var leftMarginWidth: CGFloat
    var rightMarginWidth: CGFloat
}

// MARK: - Responsive Layout Configuration

/// Responsive breakpoint tiers for layout adaptation
enum LayoutTier {
    case extraLarge  // 640pt+ width
    case large       // 480-639pt width
    case medium      // 320-479pt width
    case small       // <320pt width
    
    /// Determine layout tier from available width
    nonisolated static func from(availableWidth: CGFloat) -> LayoutTier {
        switch availableWidth {
        case kExtraLargeBreakpoint...:
            return .extraLarge
        case kLargeBreakpoint..<kExtraLargeBreakpoint:
            return .large
        case kMediumBreakpoint..<kLargeBreakpoint:
            return .medium
        default:
            return .small
        }
    }
    
    /// Margin width for this tier
    nonisolated var marginWidth: CGFloat {
        switch self {
        case .extraLarge: return kExtraLargeMargin
        case .large: return kLargeMargin
        case .medium: return kMediumMargin
        case .small: return kSmallMargin
        }
    }
    
    /// Font size for this tier
    nonisolated var font: Font {
        switch self {
        case .extraLarge: return .body
        case .large: return .callout
        case .medium: return .caption
        case .small: return .caption2
        }
    }
}

// MARK: - View Mode

enum ViewMode: String, CaseIterable, Identifiable {
    case front = "Front"
    case back = "Back"
    case both = "Both"
    
    var id: String { rawValue }
}

// MARK: - Cursor Display Mode

/// Defines what cursor information to display on the slide rule
/// - gradients: Display only gradient overlay lines
/// - values: Display only numerical reading values
/// - both: Display both gradients and values
enum CursorDisplayMode: String, CaseIterable, Identifiable {
    case gradients
    case values
    case both
    
    var id: String { rawValue }
    
    /// User-facing display text for picker
    var displayText: String {
        switch self {
        case .gradients: return "Gradients"
        case .values: return "Values"
        case .both: return "Both"
        }
    }
    
    /// Whether gradient lines should be displayed
    var showGradients: Bool {
        switch self {
        case .gradients, .both:
            return true
        case .values:
            return false
        }
    }
    
    /// Whether reading values should be displayed
    var showReadings: Bool {
        switch self {
        case .values, .both:
            return true
        case .gradients:
            return false
        }
    }
}

// MARK: - Rule Side

/// Represents which side of the slide rule is being displayed
/// - front: The primary (front) side
/// - back: The reverse (back) side
enum RuleSide: String, Sendable {
    case front
    case back
    
    /// Border color for visual distinction between sides
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
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let marginFont: Font
    
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
                .font(marginFont)
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
                .font(marginFont)
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

// MARK: - StatorView Component (renders multiple scales)

struct StatorView: View, Equatable {
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let marginFont: Font
    let cursorState: CursorState? // NEW: Reference to cursor state for interaction tracking
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    // Note: cursorState is not compared (it's a reference)
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
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
                    height: scaleHeight,
                    leftMarginWidth: leftMarginWidth,
                    rightMarginWidth: rightMarginWidth,
                    marginFont: marginFont
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
        .contentShape(Rectangle())  // Make entire area tappable
        .onTapGesture {
            // Mark stator as touched (sticky readings)
            cursorState?.setStatorTouched()
        }
    }
}

// MARK: - SlideView Component (renders multiple scales)

struct SlideView: View, Equatable {
    let slide: Slide
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let marginFont: Font
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    static func == (lhs: SlideView, rhs: SlideView) -> Bool {
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
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
                    height: scaleHeight,
                    leftMarginWidth: leftMarginWidth,
                    rightMarginWidth: rightMarginWidth,
                    marginFont: marginFont
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
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let marginFont: Font
    let sliderOffset: CGFloat
    let cursorState: CursorState?
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    // ✅ Equatable conformance - only compare properties affecting rendering
    // Note: Closures and cursorState are not compared in Equatable
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        lhs.side == rhs.side &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.sliderOffset == rhs.sliderOffset &&
        lhs.topStator.scales.count == rhs.topStator.scales.count &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.bottomStator.scales.count == rhs.bottomStator.scales.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Stator (Fixed)
            StatorView(
                stator: topStator,
                width: width,
                backgroundColor: .white,
                borderColor: side.borderColor,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                marginFont: marginFont,
                cursorState: cursorState
            )
            .equatable()
            .id("\(side.rawValue)-topStator")
            
            // Slide (Movable)
            SlideView(
                slide: slide,
                width: width,
                backgroundColor: .white,
                borderColor: .orange,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                marginFont: marginFont
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
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                marginFont: marginFont,
                cursorState: cursorState
            )
            .equatable()
            .id("\(side.rawValue)-bottomStator")
        }
    }
}
// MARK: - StaticHeaderSection

struct StaticHeaderSection: View, Equatable {
    @Binding var selectedRule: SlideRuleDefinitionModel?
    @Binding var viewMode: ViewMode
    @Binding var cursorDisplayMode: CursorDisplayMode
    let hasBackSide: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            SlideRulePicker(currentRule: $selectedRule)
            
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
                .disabled(!hasBackSide && (viewMode == .back || viewMode == .both))
                Spacer()
            }
            
            // Cursor Display Mode Picker
            HStack {
                Spacer()
                Picker("Cursor Display", selection: $cursorDisplayMode) {
                    ForEach(CursorDisplayMode.allCases) { mode in
                        Text(mode.displayText).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                .padding(.horizontal)
                .padding(.top, 4)
                Spacer()
            }
        }
    }
    
    static func == (lhs: StaticHeaderSection, rhs: StaticHeaderSection) -> Bool {
        // Only compare values that affect rendering
        lhs.selectedRule?.id == rhs.selectedRule?.id &&
        lhs.viewMode == rhs.viewMode &&
        lhs.hasBackSide == rhs.hasBackSide &&
        lhs.cursorDisplayMode == rhs.cursorDisplayMode
    }
}

// MARK: - DynamicSlideRuleContent

struct DynamicSlideRuleContent: View {
    // Dependencies from ContentView
    let viewMode: ViewMode
    let balancedFrontTopStator: Stator
    let balancedFrontSlide: Slide
    let balancedFrontBottomStator: Stator
    let balancedBackTopStator: Stator?
    let balancedBackSlide: Slide?
    let balancedBackBottomStator: Stator?
    let calculatedDimensions: Dimensions
    let marginFont: Font
    @Binding var sliderOffset: CGFloat
    let cursorState: CursorState
    let cursorDisplayMode: CursorDisplayMode
    let handleDragChanged: (DragGesture.Value) -> Void
    let handleDragEnded: (DragGesture.Value) -> Void
    let totalScaleHeight: (RuleSide) -> CGFloat
    
    var body: some View {
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
                        .equatable()
                        .frame(maxWidth: calculatedDimensions.width)
                    }
                    
                    SideView(
                        side: .front,
                        topStator: balancedFrontTopStator,
                        slide: balancedFrontSlide,
                        bottomStator: balancedFrontBottomStator,
                        width: calculatedDimensions.width,
                        scaleHeight: calculatedDimensions.scaleHeight,
                        leftMarginWidth: calculatedDimensions.leftMarginWidth,
                        rightMarginWidth: calculatedDimensions.rightMarginWidth,
                        marginFont: marginFont,
                        sliderOffset: sliderOffset,
                        cursorState: cursorState,
                        onDragChanged: handleDragChanged,
                        onDragEnded: handleDragEnded
                    )
                    .equatable()
                    .overlay {
                        CursorOverlay(
                            cursorState: cursorState,
                            width: calculatedDimensions.width,
                            height: totalScaleHeight(.front),
                            side: .front,
                            scaleHeight: calculatedDimensions.scaleHeight,
                            leftMarginWidth: calculatedDimensions.leftMarginWidth,
                            rightMarginWidth: calculatedDimensions.rightMarginWidth,
                            showReadings: cursorState.shouldShowReadings,
                            showGradients: cursorDisplayMode.showGradients
                        )
                    }
                }
            }

            Spacer().frame(height: 5)

            // Back side - show if mode is .back or .both (and back side exists)
            if (viewMode == .back || viewMode == .both),
               let backTop = balancedBackTopStator,
               let backSlide = balancedBackSlide,
               let backBottom = balancedBackBottomStator {
                VStack(spacing: 4) {
                    SideView(
                        side: .back,
                        topStator: backTop,
                        slide: backSlide,
                        bottomStator: backBottom,
                        width: calculatedDimensions.width,
                        scaleHeight: calculatedDimensions.scaleHeight,
                        leftMarginWidth: calculatedDimensions.leftMarginWidth,
                        rightMarginWidth: calculatedDimensions.rightMarginWidth,
                        marginFont: marginFont,
                        sliderOffset: sliderOffset,
                        cursorState: cursorState,
                        onDragChanged: handleDragChanged,
                        onDragEnded: handleDragEnded
                    )
                    .equatable()
                    .overlay {
                        CursorOverlay(
                            cursorState: cursorState,
                            width: calculatedDimensions.width,
                            height: totalScaleHeight(.back),
                            side: .back,
                            scaleHeight: calculatedDimensions.scaleHeight,
                            leftMarginWidth: calculatedDimensions.leftMarginWidth,
                            rightMarginWidth: calculatedDimensions.rightMarginWidth,
                            showReadings: cursorState.shouldShowReadings,
                            showGradients: cursorDisplayMode.showGradients
                        )
                    }
                    // Cursor readings display above slide rule
                    if cursorState.isEnabled {
                        CursorReadingsDisplayView(
                            readings: cursorState.currentReadings?.backReadings ?? [],
                            side: .back
                        )
                        .equatable()
                        .frame(maxWidth: calculatedDimensions.width)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onChange(of: sliderOffset) {
            cursorState.updateReadings()
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
    @State private var cursorDisplayMode: CursorDisplayMode = .both  // Cursor display mode
    // ✅ State for calculated dimensions - only updates when window size changes

    @State private var calculatedDimensions: Dimensions = .init(width: 800, scaleHeight: 25, leftMarginWidth: 64, rightMarginWidth: 64)
    @State private var cursorState = CursorState()
    
    // Current slide rule selection (persisted via SwiftData)
    @State private var selectedRuleDefinition: SlideRuleDefinitionModel?
    @State private var selectedRuleId: UUID? // Track ID separately for onChange
    
    // Parsed slide rule from definition - published state to trigger re-renders
    @State private var currentSlideRule: SlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
    
    // ✅ Cached balanced components - updated only when dependencies change
    @State private var balancedFrontTopStator: Stator = Stator(name: "", scales: [], heightInPoints: 0, showBorder: false)
    @State private var balancedFrontSlide: Slide = Slide(name: "", scales: [], heightInPoints: 0, showBorder: false)
    @State private var balancedFrontBottomStator: Stator = Stator(name: "", scales: [], heightInPoints: 0, showBorder: false)
    @State private var balancedBackTopStator: Stator? = nil
    @State private var balancedBackSlide: Slide? = nil
    @State private var balancedBackBottomStator: Stator? = nil
    
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
    
    // ✅ Update cached balanced components - called when currentSlideRule or viewMode changes
    private func updateBalancedComponents() {
        // Front top stator
        if viewMode == .both, let backTop = slideRule.backTopStator {
            let frontCount = slideRule.frontTopStator.scales.count
            let backCount = backTop.scales.count
            
            if frontCount < backCount {
                let spacersNeeded = backCount - frontCount
                var balancedScales = slideRule.frontTopStator.scales
                for _ in 0..<spacersNeeded {
                    balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
                }
                balancedFrontTopStator = Stator(
                    name: slideRule.frontTopStator.name,
                    scales: balancedScales,
                    heightInPoints: slideRule.frontTopStator.heightInPoints,
                    showBorder: slideRule.frontTopStator.showBorder
                )
            } else {
                balancedFrontTopStator = slideRule.frontTopStator
            }
        } else {
            balancedFrontTopStator = slideRule.frontTopStator
        }
        
        // Front slide
        if viewMode == .both, let backSlide = slideRule.backSlide {
            let frontCount = slideRule.frontSlide.scales.count
            let backCount = backSlide.scales.count
            
            if frontCount < backCount {
                let spacersNeeded = backCount - frontCount
                var balancedScales = slideRule.frontSlide.scales
                for _ in 0..<spacersNeeded {
                    balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
                }
                balancedFrontSlide = Slide(
                    name: slideRule.frontSlide.name,
                    scales: balancedScales,
                    heightInPoints: slideRule.frontSlide.heightInPoints,
                    showBorder: slideRule.frontSlide.showBorder
                )
            } else {
                balancedFrontSlide = slideRule.frontSlide
            }
        } else {
            balancedFrontSlide = slideRule.frontSlide
        }
        
        // Front bottom stator
        if viewMode == .both, let backBottom = slideRule.backBottomStator {
            let frontCount = slideRule.frontBottomStator.scales.count
            let backCount = backBottom.scales.count
            
            if frontCount < backCount {
                let spacersNeeded = backCount - frontCount
                var balancedScales = slideRule.frontBottomStator.scales
                for _ in 0..<spacersNeeded {
                    balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
                }
                balancedFrontBottomStator = Stator(
                    name: slideRule.frontBottomStator.name,
                    scales: balancedScales,
                    heightInPoints: slideRule.frontBottomStator.heightInPoints,
                    showBorder: slideRule.frontBottomStator.showBorder
                )
            } else {
                balancedFrontBottomStator = slideRule.frontBottomStator
            }
        } else {
            balancedFrontBottomStator = slideRule.frontBottomStator
        }
        
        // Back top stator
        if viewMode == .both, let backTop = slideRule.backTopStator {
            let frontCount = slideRule.frontTopStator.scales.count
            let backCount = backTop.scales.count
            
            if backCount < frontCount {
                let spacersNeeded = frontCount - backCount
                var balancedScales = backTop.scales
                for _ in 0..<spacersNeeded {
                    balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
                }
                balancedBackTopStator = Stator(
                    name: backTop.name,
                    scales: balancedScales,
                    heightInPoints: backTop.heightInPoints,
                    showBorder: backTop.showBorder
                )
            } else {
                balancedBackTopStator = backTop
            }
        } else {
            balancedBackTopStator = slideRule.backTopStator
        }
        
        // Back slide
        if viewMode == .both, let backSlide = slideRule.backSlide {
            let frontCount = slideRule.frontSlide.scales.count
            let backCount = backSlide.scales.count
            
            if backCount < frontCount {
                let spacersNeeded = frontCount - backCount
                var balancedScales = backSlide.scales
                for _ in 0..<spacersNeeded {
                    balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
                }
                balancedBackSlide = Slide(
                    name: backSlide.name,
                    scales: balancedScales,
                    heightInPoints: backSlide.heightInPoints,
                    showBorder: backSlide.showBorder
                )
            } else {
                balancedBackSlide = backSlide
            }
        } else {
            balancedBackSlide = slideRule.backSlide
        }
        
        // Back bottom stator
        if viewMode == .both, let backBottom = slideRule.backBottomStator {
            let frontCount = slideRule.frontBottomStator.scales.count
            let backCount = backBottom.scales.count
            
            if backCount < frontCount {
                let spacersNeeded = frontCount - backCount
                var balancedScales = backBottom.scales
                for _ in 0..<spacersNeeded {
                    balancedScales.append(createSpacerScale(length: slideRule.totalLengthInPoints))
                }
                balancedBackBottomStator = Stator(
                    name: backBottom.name,
                    scales: balancedScales,
                    heightInPoints: backBottom.heightInPoints,
                    showBorder: backBottom.showBorder
                )
            } else {
                balancedBackBottomStator = backBottom
            }
        } else {
            balancedBackBottomStator = slideRule.backBottomStator
        }
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
    
    // Helper function to get font for margin text based on margin width (discrete tiers)
    private func fontForMarginWidth(_ marginWidth: CGFloat) -> Font {
        // Determine tier from margin width and return corresponding font
        if marginWidth >= kExtraLargeMargin {
            return LayoutTier.extraLarge.font
        } else if marginWidth >= kLargeMargin {
            return LayoutTier.large.font
        } else if marginWidth >= kMediumMargin {
            return LayoutTier.medium.font
        } else {
            return LayoutTier.small.font
        }
    }
    
    // Helper function to calculate responsive dimensions
    private nonisolated func calculateDimensions(availableWidth: CGFloat, availableHeight: CGFloat) -> Dimensions {
        let maxWidth = availableWidth - (padding * 2)
        let maxHeight = availableHeight - (padding * 2)
        
        // Determine layout tier based on available width
        let tier = LayoutTier.from(availableWidth: availableWidth)
        let leftMarginWidth = tier.marginWidth
        let rightMarginWidth = tier.marginWidth
        
        // HStack spacing: 4pt between left margin and scale, 4pt between scale and right margin
        let totalMarginAndSpacing = leftMarginWidth + rightMarginWidth + 8
        
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
        // Then subtract margins to get the actual scale width
        let totalAvailableWidth = min(maxWidth, widthFromAspectRatio)
        let scaleWidth = max(totalAvailableWidth - totalMarginAndSpacing, 100) // 100pt minimum scale width
        
        return Dimensions(
            width: scaleWidth,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth
        )
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
            // Static header - isolated from sliderOffset changes
            StaticHeaderSection(
                selectedRule: $selectedRuleDefinition,
                viewMode: $viewMode,
                cursorDisplayMode: $cursorDisplayMode,
                hasBackSide: currentSlideRule.backTopStator != nil
            )
            .equatable()
            
            // Dynamic content - responds to sliderOffset
            DynamicSlideRuleContent(
                viewMode: viewMode,
                balancedFrontTopStator: balancedFrontTopStator,
                balancedFrontSlide: balancedFrontSlide,
                balancedFrontBottomStator: balancedFrontBottomStator,
                balancedBackTopStator: balancedBackTopStator,
                balancedBackSlide: balancedBackSlide,
                balancedBackBottomStator: balancedBackBottomStator,
                calculatedDimensions: calculatedDimensions,
                marginFont: fontForMarginWidth(calculatedDimensions.leftMarginWidth),
                sliderOffset: $sliderOffset,
                cursorState: cursorState,
                cursorDisplayMode: cursorDisplayMode,
                handleDragChanged: handleDragChanged,
                handleDragEnded: handleDragEnded,
                totalScaleHeight: totalScaleHeight
            )
        }
        .onGeometryChange(for: Dimensions.self) { proxy in
            let size = proxy.size
            return calculateDimensions(
                availableWidth: size.width,
                availableHeight: size.height
            )
        } action: { newDimensions in
            calculatedDimensions = newDimensions
        }
        .onAppear {
            cursorState.setSlideRuleProvider(self)
            cursorState.enableReadings = true
            loadCurrentRule()
            updateBalancedComponents()
        }
        .onChange(of: selectedRuleDefinition) { oldValue, newValue in
            print("🔄 selectedRuleDefinition changed (object)")
            selectedRuleId = newValue?.id
        }
        .onChange(of: selectedRuleId) { oldValue, newValue in
            print("🔄 Rule selection changed: \(oldValue?.uuidString ?? "nil") -> \(newValue?.uuidString ?? "nil")")
            print("   New rule: \(selectedRuleDefinition?.name ?? "nil")")
            parseAndUpdateSlideRule()
            sliderOffset = 0
            sliderBaseOffset = 0
            saveCurrentRule()
        }
        .onChange(of: viewMode) { _, _ in
            updateBalancedComponents()
        }
    }
    
    // ✅ Drag gesture handlers - single implementation for both sides
    private func handleDragChanged(_ gesture: DragGesture.Value) {
        // Mark slide as dragging
        cursorState.setSlideDragging(true)
        
        let newOffset = sliderBaseOffset + gesture.translation.width
        sliderOffset = min(max(newOffset, -calculatedDimensions.width),
                          calculatedDimensions.width)
    }
    
    private func handleDragEnded(_ gesture: DragGesture.Value) {
        sliderBaseOffset = sliderOffset
        
        // Mark slide drag as ended
        cursorState.setSlideDragging(false)
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
        guard let selectedRuleDefinition = selectedRuleDefinition else {
            print("⚠️ Cannot save: selectedRuleDefinition is nil")
            return
        }
        if let current = currentRuleQuery.first {
            current.updateSelection(selectedRuleDefinition)
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
            updateBalancedComponents()
            print("✅ Successfully loaded slide rule: \(definition.name)")
            print("   Front scales: \(parsed.frontTopStator.scales.count) + \(parsed.frontSlide.scales.count) + \(parsed.frontBottomStator.scales.count)")
        } catch {
            print("❌ Failed to parse slide rule '\(definition.name)': \(error)")
            // Fallback to basic rule
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
            updateBalancedComponents()
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
