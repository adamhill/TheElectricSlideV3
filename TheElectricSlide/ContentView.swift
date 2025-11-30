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
nonisolated(unsafe) private let kExtraLargeMargin: CGFloat = 72
nonisolated(unsafe) private let kLargeMargin: CGFloat = 64
nonisolated(unsafe) private let kMediumMargin: CGFloat = 56
nonisolated(unsafe) private let kSmallMargin: CGFloat = 48

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
    var tier: LayoutTier
}

// MARK: - Responsive Layout Configuration

/// Responsive breakpoint tiers for layout adaptation
enum LayoutTier: Sendable {
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
    
    /// Font size for scale names (left margin) - always bold
    nonisolated var nameFont: Font {
        #if os(macOS)
        // macOS: 2pt larger than standard
        switch self {
        case .extraLarge: return .system(size: 14, weight: .bold)  // caption ≈12pt + 2pt
        case .large: return .system(size: 14, weight: .bold)
        case .medium: return .system(size: 12, weight: .bold)  // caption2 ≈10pt + 2pt
        case .small: return .system(size: 12, weight: .bold)
        }
        #else
        // iOS/iPadOS: standard sizes
        switch self {
        case .extraLarge: return .caption.weight(.bold)
        case .large: return .caption.weight(.bold)
        case .medium: return .caption2.weight(.bold)
        case .small: return .caption2.weight(.bold)
        }
        #endif
    }
    
    /// Font size for formulas (right margin) - slightly smaller than names
    nonisolated var formulaFont: Font {
        switch self {
        case .extraLarge: return .caption.weight(.medium)
        case .large: return .caption.weight(.medium)
        case .medium: return .caption2
        case .small: return .caption2
        }
    }
}

// Explicit nonisolated Equatable conformance for LayoutTier
extension LayoutTier: Equatable {
    nonisolated static func == (lhs: LayoutTier, rhs: LayoutTier) -> Bool {
        switch (lhs, rhs) {
        case (.extraLarge, .extraLarge), (.large, .large), (.medium, .medium), (.small, .small):
            return true
        default:
            return false
        }
    }
}

// MARK: - View Mode

/// Represents the viewing mode for displaying slide rule sides.
/// The available modes are device-dependent:
/// - Compact devices (iPhone, Apple Watch) support only single-side views: .front or .back
/// - Regular devices (iPad, Mac, Vision Pro) support all modes: .front, .back, and .both
enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case front = "Front"
    case back = "Back"
    case both = "Both"
    
    var id: String { rawValue }
    
    // MARK: - Device-Aware Mode Selection
    
    /// Returns the list of view modes available for a given device category.
    ///
    /// Compact devices (phone, watch) are restricted to single-side views only,
    /// while regular devices (pad, mac, vision) can display multiple sides simultaneously.
    ///
    /// - Parameter category: The device category to query
    /// - Returns: Array of available ViewMode cases for the device
    ///
    /// ## Examples
    /// ```swift
    /// ViewMode.availableModes(for: .phone)   // [.front, .back]
    /// ViewMode.availableModes(for: .pad)     // [.front, .back, .both]
    /// ViewMode.availableModes(for: .watch)   // [.front, .back]
    /// ```
    static func availableModes(for category: DeviceCategory) -> [ViewMode] {
        switch category {
        case .phone, .watch:
            // Compact devices: single-side only
            return [.front, .back]
        case .pad, .mac, .vision:
            // Regular devices: all options including both sides
            return [.front, .back, .both]
        }
    }
    
    /// Constrains the current view mode to be compatible with the given device category.
    ///
    /// If the current mode is `.both` and the device is a compact device (phone or watch),
    /// this method returns `.front` as a fallback. Otherwise, it returns the current mode unchanged.
    ///
    /// This ensures that the view mode is always valid for the current device's capabilities.
    ///
    /// - Parameter category: The device category to constrain for
    /// - Returns: A ViewMode that is guaranteed to be available on the device
    ///
    /// ## Examples
    /// ```swift
    /// ViewMode.both.constrained(for: .phone)   // Returns .front (fallback)
    /// ViewMode.both.constrained(for: .pad)     // Returns .both (unchanged)
    /// ViewMode.front.constrained(for: .phone)  // Returns .front (unchanged)
    /// ```
    func constrained(for category: DeviceCategory) -> ViewMode {
        // If current mode is .both and device doesn't support multi-side view,
        // fall back to .front
        if self == .both && !category.supportsMultiSideView {
            return .front
        }
        // Otherwise, current mode is valid for this device
        return self
    }
}

// MARK: - Cursor Display Mode

/// Defines what cursor information to display on the slide rule
/// - gradients: Display only gradient overlay lines
/// - values: Display only numerical reading values
/// - both: Display both gradients and values
enum CursorDisplayMode: String, CaseIterable, Identifiable, Sendable {
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

// MARK: - Cursor Reading Cycle Mode

/// Defines which side's readings to display in the cursor readings area
/// - currentSide: Show only the current side's readings (front or back)
/// - oppositeSide: Show only the opposite side's readings
/// - both: Show both sides' readings stacked vertically
/// - none: Show nothing (collapsed)
enum CursorReadingCycleMode: String, CaseIterable, Sendable {
    case currentSide
    case oppositeSide
    case both
    case none
    
    /// Get next cycle mode (4-state cycle)
    func next() -> CursorReadingCycleMode {
        switch self {
        case .currentSide: return .oppositeSide
        case .oppositeSide: return .both
        case .both: return .none
        case .none: return .currentSide
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

// MARK: - StatorView Component (renders multiple scales)

struct StatorView: View, Equatable {
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    let cursorState: CursorState? // NEW: Reference to cursor state for interaction tracking
    let ruleId: UUID?  // Track rule identity for view updates
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    // Note: cursorState is not compared (it's a reference)
    // ruleId is compared to force re-render when rule changes
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        lhs.ruleId == rhs.ruleId &&  // Compare rule ID first to detect rule changes
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
                    nameFont: nameFont,
                    formulaFont: formulaFont
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
    let nameFont: Font
    let formulaFont: Font
    let ruleId: UUID?  // Track rule identity for view updates
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    // ruleId is compared to force re-render when rule changes
    static func == (lhs: SlideView, rhs: SlideView) -> Bool {
        lhs.ruleId == rhs.ruleId &&  // Compare rule ID first to detect rule changes
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
                    nameFont: nameFont,
                    formulaFont: formulaFont
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
    let nameFont: Font
    let formulaFont: Font
    let sliderOffset: CGFloat
    let cursorState: CursorState?
    let ruleId: UUID?  // Track rule identity for view updates
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    // ✅ Equatable conformance - only compare properties affecting rendering
    // Note: Closures and cursorState are not compared in Equatable
    // ruleId is compared to force re-render when rule changes
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        lhs.side == rhs.side &&
        lhs.ruleId == rhs.ruleId &&  // Compare rule ID to detect rule changes
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.sliderOffset == rhs.sliderOffset &&
        lhs.topStator.scales.count == rhs.topStator.scales.count &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.bottomStator.scales.count == rhs.bottomStator.scales.count
    }
    
    /// Unique identifier string combining side and rule ID for child view identity
    private var idPrefix: String {
        "\(side.rawValue)-\(ruleId?.uuidString ?? "default")"
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
                nameFont: nameFont,
                formulaFont: formulaFont,
                cursorState: cursorState,
                ruleId: ruleId  // Pass rule ID for identity tracking
            )
            .equatable()
            .id("\(idPrefix)-topStator")  // Use rule-aware ID to force re-render on rule change
            
            // Slide (Movable)
            SlideView(
                slide: slide,
                width: width,
                backgroundColor: .white,
                borderColor: .orange,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: nameFont,
                formulaFont: formulaFont,
                ruleId: ruleId  // Pass rule ID for identity tracking
            )
            .equatable()
            .offset(x: sliderOffset)
            .gesture(
                DragGesture()
                    .onChanged(onDragChanged)
                    .onEnded(onDragEnded)
            )
            .animation(.interactiveSpring(), value: sliderOffset)
            .id("\(idPrefix)-slide")  // Use rule-aware ID to force re-render on rule change
            
            // Bottom Stator (Fixed)
            StatorView(
                stator: bottomStator,
                width: width,
                backgroundColor: .white,
                borderColor: side.borderColor,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: nameFont,
                formulaFont: formulaFont,
                cursorState: cursorState,
                ruleId: ruleId  // Pass rule ID for identity tracking
            )
            .equatable()
            .id("\(idPrefix)-bottomStator")  // Use rule-aware ID to force re-render on rule change
        }
    }
}
// MARK: - DynamicSlideRuleContent

struct DynamicSlideRuleContent: View {
    // Dependencies from ContentView
    let viewMode: ViewMode
    let slideRule: SlideRule
    let ruleId: UUID?  // Track rule identity for view updates
    let calculatedDimensions: Dimensions
    let nameFont: Font
    let formulaFont: Font
    @Binding var sliderOffset: CGFloat
    let cursorState: CursorState
    let cursorDisplayMode: CursorDisplayMode
    @Binding var cursorReadingCycleMode: CursorReadingCycleMode
    let handleDragChanged: (DragGesture.Value) -> Void
    let handleDragEnded: (DragGesture.Value) -> Void
    let totalScaleHeight: (RuleSide) -> CGFloat
    let selectedRuleDefinition: SlideRuleDefinitionModel?  // For displaying rule name
    let deviceCategory: DeviceCategory  // For layout decisions
    
    var body: some View {
        VStack(spacing: 0) {
            // Consolidated cursor readings display - centered under title
            // Shows readings based on cycle mode with tap-to-cycle gesture
            VStack(spacing: 2) {
                // Rule name and side indicator (always shown on compact devices)
                if !deviceCategory.supportsMultiSideView, let ruleName = selectedRuleDefinition?.name {
                    HStack(spacing: 8) {
                        Text(ruleName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(viewMode == .front ? "Front" : (viewMode == .back ? "Back" : "Both"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 1)
                    .accessibilityLabel("Current slide rule: \(ruleName), \(viewMode.rawValue) side")
                    .accessibilityIdentifier("slideRuleNameHeader_\(viewMode.rawValue.lowercased())")
                }
                
                // Cursor readings with tap-to-cycle - compact stacked layout
                cursorReadingsDisplayArea()
                    .padding(.horizontal, 8)
            }
            
            // Front side - show if mode is .front or .both
            if viewMode == .front || viewMode == .both {
                VStack(spacing: 2) {
                    
                    SideView(
                        side: .front,
                        topStator: slideRule.frontTopStator,
                        slide: slideRule.frontSlide,
                        bottomStator: slideRule.frontBottomStator,
                        width: calculatedDimensions.width,
                        scaleHeight: calculatedDimensions.scaleHeight,
                        leftMarginWidth: calculatedDimensions.leftMarginWidth,
                        rightMarginWidth: calculatedDimensions.rightMarginWidth,
                        nameFont: nameFont,
                        formulaFont: formulaFont,
                        sliderOffset: sliderOffset,
                        cursorState: cursorState,
                        ruleId: ruleId,  // Pass rule ID for identity tracking
                        onDragChanged: handleDragChanged,
                        onDragEnded: handleDragEnded
                    )
                    .equatable()
                    .id("front-\(ruleId?.uuidString ?? "default")")  // Force view recreation on rule change
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
                // Phase 5: Flip transition animation for compact devices (iPhone/Watch)
                // Creates a natural vertical flip effect when switching sides
                // - New view slides up from the bottom with fade-in
                // - Old view slides up to the top with fade-out
                // Animation is triggered by FlipButton's spring animation (response: 0.3s, damping: 0.8)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Spacing between front and back sides when showing both
            if viewMode == .both && slideRule.backTopStator != nil {
                Spacer()
                    .frame(height: 40)
            }

            // Back side - show if mode is .back or .both (and back side exists)
            if (viewMode == .back || viewMode == .both),
               let backTop = slideRule.backTopStator,
               let backSlide = slideRule.backSlide,
               let backBottom = slideRule.backBottomStator {
                VStack(spacing: 2) {
                    SideView(
                        side: .back,
                        topStator: backTop,
                        slide: backSlide,
                        bottomStator: backBottom,
                        width: calculatedDimensions.width,
                        scaleHeight: calculatedDimensions.scaleHeight,
                        leftMarginWidth: calculatedDimensions.leftMarginWidth,
                        rightMarginWidth: calculatedDimensions.rightMarginWidth,
                        nameFont: nameFont,
                        formulaFont: formulaFont,
                        sliderOffset: sliderOffset,
                        cursorState: cursorState,
                        ruleId: ruleId,  // Pass rule ID for identity tracking
                        onDragChanged: handleDragChanged,
                        onDragEnded: handleDragEnded
                    )
                    .equatable()
                    .id("back-\(ruleId?.uuidString ?? "default")")  // Force view recreation on rule change
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
                }
                // Phase 5: Flip transition animation for compact devices (iPhone/Watch)
                // Creates a natural vertical flip effect when switching sides
                // - New view slides up from the bottom with fade-in
                // - Old view slides up to the top with fade-out
                // Animation is triggered by FlipButton's spring animation (response: 0.3s, damping: 0.8)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container, edges: .horizontal)
        .padding(.horizontal, deviceCategory == .phone ? 8 : 20)
        .padding(.bottom, 40)
        .onChange(of: sliderOffset) {
            cursorState.updateReadings()
        }
    }
    
    // MARK: - Cursor Readings Display Area with Tap-to-Cycle
    
    /// Creates the cursor readings display with tap-to-cycle functionality
    /// Cycles through 4 states: currentSide → oppositeSide → both → none → repeat
    @ViewBuilder
    private func cursorReadingsDisplayArea() -> some View {
        let frontReadings = cursorState.currentReadings?.frontReadings ?? []
        let backReadings = cursorState.currentReadings?.backReadings ?? []
        let hasBackSide = slideRule.backTopStator != nil
        
        // Determine which readings to show based on cycle mode and current view mode
        // Cycle mode controls display for all view modes, allowing selective reading visibility
        let (shouldShowFront, shouldShowBack): (Bool, Bool) = {
            switch viewMode {
            case .both:
                // In "both" view mode, respect cycle mode for selective display
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)  // Show front only
                case .oppositeSide:
                    return (false, hasBackSide)  // Show back only (if exists)
                case .both:
                    return (true, hasBackSide)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            case .front:
                // Currently viewing front side
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)  // Show front only
                case .oppositeSide:
                    return (false, hasBackSide)  // Show back only (if exists)
                case .both:
                    return (true, hasBackSide)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            case .back:
                // Currently viewing back side
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (false, true)  // Show back only
                case .oppositeSide:
                    return (true, false)  // Show front only
                case .both:
                    return (true, true)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            }
        }()
        
        // Stacked layout with tap gesture - negative spacing for tight rows
        VStack(spacing: -4) {
            if shouldShowFront {
                CursorReadingsDisplayView(
                    readings: frontReadings,
                    side: .front
                )
                .equatable()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
            }
            
            if shouldShowBack {
                CursorReadingsDisplayView(
                    readings: backReadings,
                    side: .back
                )
                .equatable()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
            }
            
            // Show placeholder when in "none" mode to maintain tap target
            if cursorReadingCycleMode == .none {
                Color.clear
                    .frame(height: 12)  // Minimal height for tap target
            }
        }
        .frame(minHeight: 50)  // CRITICAL: Maintain consistent minimum height across all cycle modes
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap to cycle through all display states, regardless of view mode
            withAnimation(.easeInOut(duration: 0.2)) {
                cursorReadingCycleMode = cursorReadingCycleMode.next()
            }
        }
        .accessibilityLabel("Cycle cursor reading mode")
        .accessibilityHint("Tap to cycle reading display modes")
        .accessibilityIdentifier("cursorReadingCycleToggle")
        // Subtle opacity feedback
        .opacity(0.95)
    }
}


// MARK: - Platform Color Helpers

#if os(iOS)
private func systemBackgroundColor() -> Color {
    Color(uiColor: .systemBackground)
}
#else
private func systemBackgroundColor() -> Color {
    Color(nsColor: .windowBackgroundColor)
}
#endif

// MARK: - Sidebar View (List of Slide Rules)

struct SlideRuleSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedRule: SlideRuleDefinitionModel?
    @Binding var viewMode: ViewMode
    @Binding var cursorDisplayMode: CursorDisplayMode
    let availableRules: [SlideRuleDefinitionModel]
    let hasBackSide: Bool
    let deviceCategory: DeviceCategory
    let onRuleSelected: (SlideRuleDefinitionModel) -> Void
    
    /// Available view modes based on device category and slide rule capabilities
    private var availableModes: [ViewMode] {
        ViewMode.availableModes(for: deviceCategory).filter { mode in
            mode == .front || hasBackSide
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Cursor Display Mode Picker at top
            VStack(spacing: 8) {
                Text("Cursor Display")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Cursor Display", selection: $cursorDisplayMode) {
                    ForEach(CursorDisplayMode.allCases) { mode in
                        Text(mode.displayText).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding()
            .background(systemBackgroundColor())

            Divider()
            
            // View Mode Picker (Front | Back | Both)
            Picker("View Mode", selection: $viewMode) {
                ForEach(availableModes) { mode in
                    Text(mode.rawValue).tag(mode)
                        .accessibilityLabel("\(mode.rawValue) side")
                        .accessibilityIdentifier("viewModeOption_\(mode.rawValue.lowercased())")
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
            .allowsHitTesting(true)
            .accessibilityLabel("View mode selector")
            .accessibilityIdentifier("viewModePicker")
            .accessibilityValue(viewMode.rawValue)
            .accessibilityHint("Select which side of the slide rule to display")
            
            
            Divider()
            
            // List of slide rules
            List(availableRules, selection: $selectedRule) { rule in
                Button {
                    onRuleSelected(rule)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                    // Icon
                    Image(systemName: rule.circularSpec != nil ? "circle.hexagongrid.circle" : "ruler.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.name)
                            .font(.headline)
                        
                        Text(rule.ruleDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            }
            .navigationTitle("Slide Rules")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            #endif
            .onAppear {
                initializeLibraryIfNeeded()
            }
        }
    }
    
    /// Initialize or update library with standard rules
    /// Detects version changes and updates modified rules
    private func initializeLibraryIfNeeded() {
        let standardRules = SlideRuleLibrary.standardRules()
        
        if availableRules.isEmpty {
            // First time: insert all rules
            print("📚 Initializing slide rule library (version \(SlideRuleLibrary.libraryVersion))")
            for rule in standardRules {
                modelContext.insert(rule)
            }
        } else {
            // Check if library version has changed
            let maxExistingVersion = availableRules.map { $0.libraryVersion }.max() ?? 0
            
            if maxExistingVersion < SlideRuleLibrary.libraryVersion {
                print("📚 Updating slide rule library: v\(maxExistingVersion) → v\(SlideRuleLibrary.libraryVersion)")
                
                // Create a lookup of existing rules by name
                var existingRulesByName: [String: SlideRuleDefinitionModel] = [:]
                for rule in availableRules {
                    existingRulesByName[rule.name] = rule
                }
                
                // Update or insert each standard rule
                for standardRule in standardRules {
                    if let existingRule = existingRulesByName[standardRule.name] {
                        // Update existing rule with new definition
                        print("  ↻ Updating: \(standardRule.name)")
                        existingRule.ruleDescription = standardRule.ruleDescription
                        existingRule.definitionString = standardRule.definitionString
                        existingRule.topStatorMM = standardRule.topStatorMM
                        existingRule.slideMM = standardRule.slideMM
                        existingRule.bottomStatorMM = standardRule.bottomStatorMM
                        existingRule.circularSpec = standardRule.circularSpec
                        existingRule.sortOrder = standardRule.sortOrder
                        existingRule.scaleNameOverrides = standardRule.scaleNameOverrides
                        existingRule.libraryVersion = standardRule.libraryVersion
                        // Preserve user's favorite status
                    } else {
                        // New rule: insert it
                        print("  + Adding: \(standardRule.name)")
                        modelContext.insert(standardRule)
                    }
                }
                
                // Optionally: Remove rules that no longer exist in standard library
                // (commented out to preserve user-created custom rules)
                /*
                let standardRuleNames = Set(standardRules.map { $0.name })
                for existingRule in availableRules {
                    if !standardRuleNames.contains(existingRule.name) && existingRule.libraryVersion > 0 {
                        print("  - Removing: \(existingRule.name)")
                        modelContext.delete(existingRule)
                    }
                }
                */
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Slide rule library synchronized")
        } catch {
            print("❌ Failed to save slide rule library: \(error)")
        }
    }
}

// MARK: - Detail View (Slide Rule Visualization)

struct SlideRuleDetailView: View {
    @Binding var viewMode: ViewMode
    @Binding var cursorDisplayMode: CursorDisplayMode
    @Binding var cursorReadingCycleMode: CursorReadingCycleMode
    let deviceCategory: DeviceCategory
    let currentSlideRule: SlideRule
    let ruleId: UUID?  // Track rule identity for view updates
    let selectedRuleDefinition: SlideRuleDefinitionModel?  // For displaying rule name
    
    @Binding var calculatedDimensions: Dimensions
    @Binding var sliderOffset: CGFloat
    let cursorState: CursorState
    
    let handleDragChanged: (DragGesture.Value) -> Void
    let handleDragEnded: (DragGesture.Value) -> Void
    let totalScaleHeight: (RuleSide) -> CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Header controls (ViewMode picker for iPad/Mac)
            // NOTE: Cursor Display picker is now in the sidebar
            if deviceCategory.supportsMultiSideView {
                VStack(spacing: 0) {
                    Divider()
                    
                    combinedPickersSection()
                    
                    Divider()
                }
                .background(systemBackgroundColor())
                .allowsHitTesting(true)
                .zIndex(100)
            }
            
            // Dynamic content - responds to sliderOffset
            DynamicSlideRuleContent(
                viewMode: viewMode,
                slideRule: currentSlideRule,
                ruleId: ruleId,
                calculatedDimensions: calculatedDimensions,
                nameFont: calculatedDimensions.tier.nameFont,
                formulaFont: calculatedDimensions.tier.formulaFont,
                sliderOffset: $sliderOffset,
                cursorState: cursorState,
                cursorDisplayMode: cursorDisplayMode,
                cursorReadingCycleMode: $cursorReadingCycleMode,
                handleDragChanged: handleDragChanged,
                handleDragEnded: handleDragEnded,
                totalScaleHeight: totalScaleHeight,
                selectedRuleDefinition: selectedRuleDefinition,
                deviceCategory: deviceCategory
            )
            .overlay(alignment: .bottomLeading) {
                // Floating flip button for compact devices (iPhone, Apple Watch)
                // Positioned at bottom-left, horizontally aligned under NavigationView's disclosure widget
                if !deviceCategory.supportsMultiSideView && currentSlideRule.backTopStator != nil {
                    FlipButton(viewMode: $viewMode)
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                }
            }
        }
    }
    
    /// View Mode picker section for regular devices (iPad, Mac, Vision Pro)
    @ViewBuilder
    private func combinedPickersSection() -> some View {
        let availableModes = ViewMode.availableModes(for: deviceCategory).filter { mode in
            mode == .front || (currentSlideRule.backTopStator != nil)
        }
        
        HStack(spacing: 16) {
            // Slide rule name label
            if let ruleName = selectedRuleDefinition?.name {
                Text(ruleName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Current slide rule: \(ruleName)")
                    .accessibilityIdentifier("currentSlideRuleName")
            }
            
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var currentRuleQuery: [CurrentSlideRule]
    @Query(sort: \SlideRuleDefinitionModel.sortOrder) private var availableRules: [SlideRuleDefinitionModel]
    
    @State private var sliderOffset: CGFloat = 0
    @State private var sliderBaseOffset: CGFloat = 0  // ✅ Persists offset between gestures
    @State private var viewMode: ViewMode = .both  // View mode selector
    @State private var cursorDisplayMode: CursorDisplayMode = .both  // Cursor display mode
    @State private var cursorReadingCycleMode: CursorReadingCycleMode = .currentSide  // Cycle mode for reading display
    @State private var deviceCategory: DeviceCategory = DeviceDetection.currentDeviceCategory()  // Device detection for adaptive UI
    // ✅ State for calculated dimensions - only updates when window size changes

    @State private var calculatedDimensions: Dimensions = .init(width: 800, scaleHeight: 25, leftMarginWidth: 64, rightMarginWidth: 64, tier: .extraLarge)
    @State private var cursorState = CursorState()
    
    // Current slide rule selection (persisted via SwiftData)
    @State private var selectedRuleDefinition: SlideRuleDefinitionModel?
    @State private var selectedRuleId: UUID? // Track ID separately for onChange
    
    // Parsed slide rule from definition - published state to trigger re-renders
    @State private var currentSlideRule: SlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
    
    
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
    nonisolated private func calculateDimensions(availableWidth: CGFloat, availableHeight: CGFloat) -> Dimensions {
        let maxWidth = availableWidth
        let maxHeight = availableHeight - (padding * 2)
        
        // Determine layout tier based on available width
        let tier = LayoutTier.from(availableWidth: availableWidth)
        
        // On iPhone, use asymmetric margins to maximize space on the side without Dynamic Island
        let leftMarginWidth: CGFloat
        let rightMarginWidth: CGFloat
        
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone: NavigationSplitView collapses to single stack, so we have full width available
            // Left margin must accommodate scale names (e.g., "LL00", "CI", "CIF")
            // Minimum 28pt for scale names in bold caption2 font
            let orientation = UIDevice.current.orientation
            
            switch orientation {
            case .landscapeLeft:
                // Dynamic Island on RIGHT in landscapeLeft
                // Left needs space for scale names, right can go tighter
                leftMarginWidth = 20
                rightMarginWidth = 8  // Restored from 4
            case .landscapeRight:
                // Dynamic Island on LEFT in landscapeRight
                // Left needs space for scale names + Dynamic Island clearance, right minimal
                leftMarginWidth = 24
                rightMarginWidth = 4  // Restored from 0
            default:
                // Portrait or unknown: use balanced margins with scale name space
                leftMarginWidth = 28
                rightMarginWidth = 28
            }
        } else {
            // iPad: Keep symmetric margins based on tier (already sufficient)
            leftMarginWidth = tier.marginWidth
            rightMarginWidth = tier.marginWidth
        }
        #else
        // macOS/other: Keep symmetric margins
        leftMarginWidth = tier.marginWidth
        rightMarginWidth = tier.marginWidth
        #endif
        
        // HStack spacing: 4pt between left margin and scale, 4pt between scale and right margin
        let totalMarginAndSpacing = leftMarginWidth + rightMarginWidth + 8
        
        // Calculate local values instead of accessing @State properties
        let localSideGapCount: Int
        if viewMode == .both && currentSlideRule.backTopStator != nil {
            localSideGapCount = 1
        } else {
            localSideGapCount = 0
        }
        
        let localLabelHeight: CGFloat
        if viewMode == .both && currentSlideRule.backTopStator != nil {
            localLabelHeight = 30
        } else {
            localLabelHeight = 0
        }
        
        // Calculate total scale count locally
        var localTotalScaleCount = 0
        if viewMode == .front || viewMode == .both {
            localTotalScaleCount += currentSlideRule.frontTopStator.scales.count +
                                     currentSlideRule.frontSlide.scales.count +
                                     currentSlideRule.frontBottomStator.scales.count
        }
        if (viewMode == .back || viewMode == .both),
           let backTop = currentSlideRule.backTopStator,
           let backSlide = currentSlideRule.backSlide,
           let backBottom = currentSlideRule.backBottomStator {
            localTotalScaleCount += backTop.scales.count +
                                     backSlide.scales.count +
                                     backBottom.scales.count
        }
        
        // Account for spacing between sides and labels
        let totalSpacingHeight = (CGFloat(localSideGapCount) * sideSpacing) + localLabelHeight
        let availableHeightForScales = maxHeight - totalSpacingHeight
        
        // Calculate scale height based on available height
        let calculatedScaleHeight = min(
            availableHeightForScales / CGFloat(localTotalScaleCount),
            maxScaleHeight
        )
        let scaleHeight = max(calculatedScaleHeight, minScaleHeight)
        
        // Calculate total height needed for all scales
        let totalHeight = scaleHeight * CGFloat(localTotalScaleCount) + totalSpacingHeight
        
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
            rightMarginWidth: rightMarginWidth,
            tier: tier
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
            stator = slideRule.frontTopStator
            slide = slideRule.frontSlide
            bottomStator = slideRule.frontBottomStator
        case .back:
            guard let backTop = slideRule.backTopStator,
                  let backSlide = slideRule.backSlide,
                  let backBottom = slideRule.backBottomStator else {
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
        NavigationSplitView {
            // SIDEBAR: List of available slide rules
            SlideRuleSidebarView(
                selectedRule: $selectedRuleDefinition,
                viewMode: $viewMode,
                cursorDisplayMode: $cursorDisplayMode,
                availableRules: availableRules,
                hasBackSide: currentSlideRule.backTopStator != nil,
                deviceCategory: deviceCategory,
                onRuleSelected: { rule in
                    selectedRuleDefinition = rule
                    selectedRuleId = rule.id
                }
            )
        } detail: {
            // DETAIL: Slide rule visualization
            if selectedRuleDefinition != nil {
                SlideRuleDetailView(
                    viewMode: $viewMode,
                    cursorDisplayMode: $cursorDisplayMode,
                    cursorReadingCycleMode: $cursorReadingCycleMode,
                    deviceCategory: deviceCategory,
                    currentSlideRule: currentSlideRule,
                    ruleId: selectedRuleId,
                    selectedRuleDefinition: selectedRuleDefinition,
                    calculatedDimensions: $calculatedDimensions,
                    sliderOffset: $sliderOffset,
                    cursorState: cursorState,
                    handleDragChanged: handleDragChanged,
                    handleDragEnded: handleDragEnded,
                    totalScaleHeight: totalScaleHeight
                )
                .onGeometryChange(for: Dimensions.self) { proxy in
                    let size = proxy.size
                    return calculateDimensions(
                        availableWidth: size.width,
                        availableHeight: size.height
                    )
                } action: { newDimensions in
                    calculatedDimensions = newDimensions
                }
            } else {
                // Empty state when no rule selected
                ContentUnavailableView(
                    "Select a Slide Rule",
                    systemImage: "ruler",
                    description: Text("Choose a slide rule from the sidebar to begin")
                )
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onAppear {
            cursorState.setSlideRuleProvider(self)
            cursorState.enableReadings = true
            // Set stator touched to show readings by default
            cursorState.setStatorTouched()
            // Initialize device category
            deviceCategory = DeviceDetection.currentDeviceCategory()
            #if DEBUG
            print("[ViewMode] Device category initialized: \(deviceCategory.rawValue)")
            #endif
            
            // CRITICAL: Constrain viewMode to device capabilities on launch
            let constrainedMode = viewMode.constrained(for: deviceCategory)
            if constrainedMode != viewMode {
                #if DEBUG
                print("[ViewMode] Constraining on launch: \(viewMode.rawValue) → \(constrainedMode.rawValue)")
                #endif
                viewMode = constrainedMode
            }
            
            loadCurrentRule()
            
            #if os(iOS)
            // Start listening for orientation changes
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            #endif
        }
        .onDisappear {
            #if os(iOS)
            // Stop listening for orientation changes
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            #endif
        }
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // Force recalculation when orientation changes (triggers onGeometryChange)
            // The geometry will be the same, but we need to recalculate margins based on new orientation
            if UIDevice.current.userInterfaceIdiom == .phone {
                #if DEBUG
                print("[Orientation] Device orientation changed, recalculating dimensions")
                #endif
                // Trigger dimension recalculation by forcing the geometry change handler
                let currentSize = CGSize(width: calculatedDimensions.width + calculatedDimensions.leftMarginWidth + calculatedDimensions.rightMarginWidth + 8,
                                        height: CGFloat(totalScaleCount) * calculatedDimensions.scaleHeight)
                let newDimensions = calculateDimensions(availableWidth: currentSize.width + (padding * 2), 
                                                       availableHeight: currentSize.height + (padding * 2))
                calculatedDimensions = newDimensions
            }
        }
        #endif
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
            // Force cursor readings update for new slide rule scales
            cursorState.updateReadings()
            saveCurrentRule()
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            // Re-detect device category when size class changes
            deviceCategory = DeviceDetection.currentDeviceCategory()
            #if DEBUG
            print("[ViewMode] Horizontal size class changed, device category updated: \(deviceCategory.rawValue)")
            #endif
            
            // Constrain viewMode to device capabilities after size class change
            let constrainedMode = viewMode.constrained(for: deviceCategory)
            if constrainedMode != viewMode {
                #if DEBUG
                print("[ViewMode] Constraining after size class change: \(viewMode.rawValue) → \(constrainedMode.rawValue)")
                #endif
                viewMode = constrainedMode
            }
        }
        .onChange(of: deviceCategory) { oldCategory, newCategory in
            #if DEBUG
            print("[ViewMode] Device category changed: \(oldCategory.rawValue) → \(newCategory.rawValue)")
            #endif
            let constrainedMode = viewMode.constrained(for: newCategory)
            if constrainedMode != viewMode {
                #if DEBUG
                print("[ViewMode] Constraining after device category change: \(viewMode.rawValue) → \(constrainedMode.rawValue)")
                #endif
                viewMode = constrainedMode
            }
        }
        .onChange(of: viewMode) { oldValue, newValue in
            #if DEBUG
            print("[ViewMode] View mode changed: \(oldValue.rawValue) → \(newValue.rawValue)")
            #endif
            // Update cursor readings when view mode changes to reflect new visible scales
            cursorState.updateReadings()
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
            cursorState.updateReadings()
            return
        }
        
        print("🔧 Parsing slide rule: \(definition.name)")
        print("   Definition: \(definition.definitionString)")
        
        do {
            let parsed = try definition.parseSlideRule(scaleLength: 1000)
            currentSlideRule = parsed
            print("✅ Successfully loaded slide rule: \(definition.name)")
            print("   Front scales: \(parsed.frontTopStator.scales.count) + \(parsed.frontSlide.scales.count) + \(parsed.frontBottomStator.scales.count)")
            
            // Update cursor readings immediately after parsing new slide rule
            cursorState.updateReadings()
        } catch {
            print("❌ Failed to parse slide rule '\(definition.name)': \(error)")
            // Fallback to basic rule
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
            cursorState.updateReadings()
        }
    }
}

// MARK: - SlideRuleProvider Conformance

extension ContentView: SlideRuleProvider {
    func getFrontScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)? {
        // Always return front data - the view decides what to display
        // This allows cursor readings to show opposite side or both sides
        return (
            topStator: currentSlideRule.frontTopStator,
            slide: currentSlideRule.frontSlide,
            bottomStator: currentSlideRule.frontBottomStator
        )
    }
    
    func getBackScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)? {
        // Always return back data if it exists - the view decides what to display
        // This allows cursor readings to show opposite side or both sides
        guard let backTop = currentSlideRule.backTopStator,
              let backSlide = currentSlideRule.backSlide,
              let backBottom = currentSlideRule.backBottomStator else {
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
