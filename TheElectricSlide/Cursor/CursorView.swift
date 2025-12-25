//
//  CursorView.swift
//  TheElectricSlide
//
//  Visual component for glass cursor
//

import SwiftUI

// MARK: - Cursor Reading Display Configuration

/// Configuration for how scale readings are displayed on the cursor
///
/// Usage:
/// ```swift
/// CursorView(
///     height: 200,
///     readings: readings,
///     scaleHeight: 25,
///     displayConfig: .large  // or .bold, .monospaced, or custom
/// )
/// ```
///
/// Custom configuration:
/// ```swift
/// let customConfig = CursorReadingDisplayConfig(
///     scaleNameFont: FontConfig(
///         name: "Helvetica",  // or nil for system font
///         size: 11,
///         color: .blue,
///         weight: .semibold,
///         design: .default
///     ),
///     scaleValueFont: FontConfig(
///         name: nil,
///         size: 11,
///         color: .red,
///         weight: .bold,
///         design: .monospaced
///     ),
///     labelPadding: 6
/// )
/// ```
struct CursorReadingDisplayConfig {
    /// Font configuration for scale names
    var scaleNameFont: FontConfig
    
    /// Font configuration for scale values
    var scaleValueFont: FontConfig
    
    /// Horizontal padding from frame edge
    var labelPadding: CGFloat
    
    /// Default configuration
    static let `default` = CursorReadingDisplayConfig(
        scaleNameFont: FontConfig(
            name: nil,  // System font
            size: 8,
            color: .black,
            weight: .regular,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,  // System font
            size: 8,
            color: .black,
            weight: .regular,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        labelPadding: 4
    )
    
    /// Preset: Larger text for better visibility
    static let large = CursorReadingDisplayConfig(
        scaleNameFont: FontConfig(
            name: nil,
            size: 14,
            color: .black,
            weight: .bold,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,
            size: 12,
            color: .black,
            weight: .bold,
            design: .monospaced,
            outline: .default,
            gradient: .default
        ),
        labelPadding: 4
    )
    
    /// Preset: Bold styling
    static let bold = CursorReadingDisplayConfig(
        scaleNameFont: FontConfig(
            name: nil,
            size: 8,
            color: .black,
            weight: .bold,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,
            size: 8,
            color: .black,
            weight: .bold,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        labelPadding: 4
    )
    
    /// Preset: Monospaced values for alignment
    static let monospaced = CursorReadingDisplayConfig(
        scaleNameFont: FontConfig(
            name: nil,
            size: 8,
            color: .black,
            weight: .regular,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,
            size: 8,
            color: .black,
            weight: .regular,
            design: .monospaced,
            outline: .default,
            gradient: .default
        ),
        labelPadding: 4
    )
}

/// Font configuration structure
struct FontConfig {
    /// Custom font name (nil for system font)
    var name: String?
    
    /// Font size in points
    var size: CGFloat
    
    /// Text color
    var color: Color
    
    /// Font weight
    var weight: Font.Weight
    
    /// Font design (system, serif, rounded, monospaced)
    var design: Font.Design
    
    /// Outline/stroke configuration (nil for no outline)
    var outline: OutlineConfig?
    
    /// Gradient background configuration (nil for no gradient)
    var gradient: GradientConfig?
    
    /// Outline configuration for text
    struct OutlineConfig {
        /// Outline color
        var color: Color
        
        /// Outline width in points
        var width: CGFloat
        
        /// Default white outline, 1pt
        static let `default` = OutlineConfig(color: .white, width: 1.0)
    }
    
    /// Gradient configuration for background
    struct GradientConfig {
        /// Gradient colors
        var colors: [Color]
        
        /// Gradient start point
        var startPoint: UnitPoint
        
        /// Gradient end point
        var endPoint: UnitPoint
        
        /// Overall opacity of the gradient
        var opacity: Double
        
        /// Default gradient: subtle yellow to clear from left to right
        static let `default` = GradientConfig(
            colors: [
                Color.yellow.opacity(0.3),
                Color.yellow.opacity(0.15),
                Color.yellow.opacity(0.05),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing,
            opacity: 1.0
        )
        
        /// Subtle gradient: very light dark to clear
        static let subtle = GradientConfig(
            colors: [
                Color.black.opacity(0.15),
                Color.black.opacity(0.08),
                Color.black.opacity(0.03),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing,
            opacity: 1.0
        )
        
        /// Blue gradient
        static let blue = GradientConfig(
            colors: [
                Color.blue.opacity(0.3),
                Color.blue.opacity(0.15),
                Color.blue.opacity(0.05),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing,
            opacity: 1.0
        )
        
        /// Precision mode gradient: saturated red-orange for clear visual distinction
        /// More intense than the default yellow to indicate precision mode is active
        /// **Color Source:** SlideRuleColorScheme.precisionOverlayColor (red-orange: rgb(1.0, 0.4, 0.3))
        static let precision = GradientConfig(
            colors: [
                Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.5),
                Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.3),
                Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.12),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing,
            opacity: 1.0
        )
        
        /// Green gradient for Faber-Castell (normal mode)
        /// Matches the Faber-Castell mint green color scheme
        static let green = GradientConfig(
            colors: [
                Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.3),
                Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.15),
                Color(red: 0.4, green: 0.85, blue: 0.5).opacity(0.05),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing,
            opacity: 1.0
        )
        
        /// Precision mode gradient for Faber-Castell: INTENSE saturated green
        /// Much more visible than normal green to clearly indicate precision mode
        /// **Color Source:** SlideRuleColorScheme.faberCastell.precisionOverlayColor (green: rgb(0.2, 0.85, 0.4))
        static let precisionGreen = GradientConfig(
            colors: [
                Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.7),
                Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.5),
                Color(red: 0.2, green: 0.85, blue: 0.4).opacity(0.25),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing,
            opacity: 1.0
        )
    }
    
    /// Create a SwiftUI Font from this configuration
    /// Always uses monospacedDigit() for proper decimal point alignment
    func makeFont() -> Font {
        if let name = name {
            return .custom(name, size: size).monospacedDigit()
        } else {
            return .system(size: size, weight: weight, design: design).monospacedDigit()
        }
    }
}

struct CursorView: View {
    // MARK: - Properties
    
    /// Height of the cursor (spans full vertical space of slide rule)
    let height: CGFloat
    
    /// Scale readings to display on cursor
    let readings: [ScaleReading]
    
    /// Height of each scale row (for vertical positioning)
    let scaleHeight: CGFloat
    
    /// Display configuration for scale readings
    var displayConfig: CursorReadingDisplayConfig = .default
    
    /// Whether to show scale readings (names and values)
    var showReadings: Bool = true
    
    /// Whether to show gradient backgrounds
    var showGradients: Bool = true
    
    /// Current zoom scale to display on handle
    var zoomScale: CGFloat = 1.0
    
    /// Binding to cursor display mode for toggle on double-tap
    @Binding var cursorDisplayMode: CursorDisplayMode
    
    /// Currently highlighted scale index (from precision mode)
    var highlightedScaleIndex: Int? = nil
    
    /// Whether precision mode is active for THIS cursor
    var isPrecisionActive: Bool = false
    
    /// Current manufacturer (for selecting precision gradient color)
    /// Faber-Castell uses green, all others use red-orange
    var manufacturer: SlideRuleManufacturer? = nil
    
    /// Color scheme for precision mode colors (centralized source of truth)
    var colorScheme: SlideRuleColorScheme? = nil
    
    // MARK: - Constants
    
    /// Width of the cursor frame
    static let cursorWidth: CGFloat = 144
    
    /// Height of the drag handle (positioned ABOVE the slide rule)
    static let handleHeight: CGFloat = 16
    
    /// True 1-pixel hairline width (accounts for screen scale factor)
    static var hairlineWidth: CGFloat {
        #if os(iOS) || os(tvOS)
        return 1.0 / UIScreen.main.scale
        #elseif os(macOS)
        return 1.0 / (NSScreen.main?.backingScaleFactor ?? 1.0)
        #else
        return 1.0
        #endif
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Gray handle at the very top - OUTSIDE the slide rule area
            HStack(spacing: 0) {
                // Zoom level label on left side of handle
                Text(String(format: "%.1f×", zoomScale))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 36, alignment: .center)
                
                // Handle with drag indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.5).opacity(0.7))
                    .frame(width: Self.cursorWidth - 36, height: Self.handleHeight)
                    .overlay(
                        // Visual indicator for dragging
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 30, height: 2)
                                .cornerRadius(1)
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 30, height: 2)
                                .cornerRadius(1)
                        }
                    )
            }
            .frame(width: Self.cursorWidth, height: Self.handleHeight)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.5).opacity(0.7))
            )
            .onTapGesture(count: 2) {
                // Double-tap toggles cursor values on/off
                cursorDisplayMode = cursorDisplayMode.showReadings ? .gradients : .both
            }
            
            // Cursor glass area - extends full height of slide rule
            ZStack(alignment: .topLeading) {
                // Clear glass area with gray frame border
                Rectangle()
                    .fill(.clear)
                    .frame(width: Self.cursorWidth, height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(white: 0.4), lineWidth: 2)
                    )
                
                // Gradient backgrounds for each scale row (if configured and enabled)
                if showGradients {
                    // Create dynamic gradient based on precision mode state and color scheme
                    // Uses centralized colors from SlideRuleColorScheme for single source of truth
                    let activeGradient: FontConfig.GradientConfig = {
                        if isPrecisionActive {
                            // Precision mode: Use centralized cursorPrecisionColor from color scheme
                            if let precisionColor = colorScheme?.cursorPrecisionColor {
                                // Create dynamic precision gradient from centralized color
                                return FontConfig.GradientConfig(
                                    colors: [
                                        precisionColor.opacity(0.7),
                                        precisionColor.opacity(0.5),
                                        precisionColor.opacity(0.25),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing,
                                    opacity: 1.0
                                )
                            } else {
                                // Fallback to static gradients if colorScheme not available
                                return manufacturer == .faberCastell ? .precisionGreen : .precision
                            }
                        } else {
                            // Normal mode gradients
                            if manufacturer == .faberCastell {
                                return .green  // Green for F-C
                            } else {
                                return displayConfig.scaleNameFont.gradient ?? .default  // Yellow for others
                            }
                        }
                    }()
                    
                    VStack(spacing: 0) {
                        ForEach(Array(readings.enumerated()), id: \.element.id) { index, reading in
                            ZStack {
                                // Scale name gradient (left side) - use active gradient color
                                HStack(spacing: 0) {
                                    LinearGradient(
                                        colors: activeGradient.colors,
                                        startPoint: activeGradient.startPoint,
                                        endPoint: activeGradient.endPoint
                                    )
                                    .opacity(activeGradient.opacity)
                                    .frame(width: Self.cursorWidth / 2)
                                    
                                    Spacer()
                                }
                                
                                // Scale value gradient (right side) - use active gradient color
                                HStack(spacing: 0) {
                                    Spacer()
                                    
                                    LinearGradient(
                                        colors: activeGradient.colors,
                                        startPoint: activeGradient.endPoint,  // Flip: start from trailing edge
                                        endPoint: activeGradient.startPoint   // Flip: end toward center/hairline
                                    )
                                    .opacity(activeGradient.opacity)
                                    .frame(width: Self.cursorWidth / 2)
                                }
                            }
                            .frame(width: Self.cursorWidth, height: scaleHeight)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: isPrecisionActive)
                }
                
                // True 1-pixel hairline down center - solid black
                Rectangle()
                    .fill(.black)
                    .frame(width: Self.hairlineWidth, height: height)
                    .offset(x: Self.cursorWidth / 2)
                
                // Scale readings drawn with Canvas for maximum performance
                if showReadings {
                    Canvas { context, size in
                        drawScaleReadings(context: context, size: size)
                    }
                    .frame(width: Self.cursorWidth, height: height)
                }
            }
            
            // Gray handle at the very bottom - OUTSIDE the slide rule area
            HStack(spacing: 0) {
                // Zoom level label on left side of handle
                Text(String(format: "%.1f×", zoomScale))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 36, alignment: .center)
                
                // Handle with drag indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.5).opacity(0.7))
                    .frame(width: Self.cursorWidth - 36, height: Self.handleHeight)
                    .overlay(
                        // Visual indicator for dragging
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 30, height: 2)
                                .cornerRadius(1)
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 30, height: 2)
                                .cornerRadius(1)
                        }
                    )
            }
            .frame(width: Self.cursorWidth, height: Self.handleHeight)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.5).opacity(0.7))
            )
            .onTapGesture(count: 2) {
                // Double-tap toggles cursor values on/off
                cursorDisplayMode = cursorDisplayMode.showReadings ? .gradients : .both
            }
        }
    }
    
    // MARK: - Drawing Methods
    
    /// Draw scale readings using Canvas for maximum performance
    private func drawScaleReadings(context: GraphicsContext, size: CGSize) {
        let halfWidth = size.width / 2
        
        // Use array index for vertical positioning (readings are in scale order)
        for (index, reading) in readings.enumerated() {
            let yPosition = CGFloat(index) * scaleHeight + (scaleHeight / 2)
            
            // Skip if outside visible area
            guard yPosition >= 0 && yPosition <= size.height else { continue }
            
            // Determine font config
            let nameConfig = displayConfig.scaleNameFont
            let valueConfig = displayConfig.scaleValueFont
            
            // Draw scale name on the left (aligned left, against frame edge)
            drawText(
                context: context,
                text: reading.scaleName,
                fontConfig: nameConfig,
                xPosition: displayConfig.labelPadding,
                yPosition: yPosition,
                maxWidth: halfWidth
            )
            
            // Draw value on the right (aligned right, against frame edge)
            // Note: We need to measure with the potentially modified font config
            let valueText = Text(reading.displayValue)
                .font(valueConfig.makeFont())
                .foregroundColor(valueConfig.color)
            
            let resolvedValue = context.resolve(valueText)
            let valueSize = resolvedValue.measure(in: CGSize(width: halfWidth, height: scaleHeight))
            
            let valueX = size.width - valueSize.width - displayConfig.labelPadding
            
            drawText(
                context: context,
                text: reading.displayValue,
                fontConfig: valueConfig,
                xPosition: valueX,
                yPosition: yPosition,
                maxWidth: halfWidth
            )
        }
    }
    
    
    /// Draw text with optional outline/stroke
    private func drawText(
        context: GraphicsContext,
        text: String,
        fontConfig: FontConfig,
        xPosition: CGFloat,
        yPosition: CGFloat,
        maxWidth: CGFloat,
        opacity: Double = 1.0
    ) {
        var ctx = context
        ctx.opacity = opacity
        
        let textView = Text(text)
            .font(fontConfig.makeFont())
            .foregroundColor(fontConfig.color)
        
        let resolved = ctx.resolve(textView)
        let textSize = resolved.measure(in: CGSize(width: maxWidth, height: scaleHeight))
        
        let rect = CGRect(
            x: xPosition,
            y: yPosition - (textSize.height / 2),
            width: textSize.width,
            height: textSize.height
        )
        
        // Draw outline/stroke if configured
        if let outline = fontConfig.outline {
            // Draw stroke by drawing the text multiple times with offset in a circle pattern
            // This creates a stroke effect by overlaying the outline color
            let offsets: [(CGFloat, CGFloat)] = [
                (-outline.width, 0), (outline.width, 0),
                (0, -outline.width), (0, outline.width),
                (-outline.width * 0.7, -outline.width * 0.7),
                (outline.width * 0.7, -outline.width * 0.7),
                (-outline.width * 0.7, outline.width * 0.7),
                (outline.width * 0.7, outline.width * 0.7)
            ]
            
            let outlineText = Text(text)
                .font(fontConfig.makeFont())
                .foregroundColor(outline.color)
            let outlineResolved = ctx.resolve(outlineText)
            
            for (dx, dy) in offsets {
                let outlineRect = CGRect(
                    x: rect.origin.x + dx,
                    y: rect.origin.y + dy,
                    width: rect.width,
                    height: rect.height
                )
                ctx.draw(outlineResolved, in: outlineRect)
            }
        }
        
        // Draw main text on top
        ctx.draw(resolved, in: rect)
    }
}

// MARK: - Equatable Conformance
extension FontConfig.GradientConfig: Equatable {
    static func == (lhs: FontConfig.GradientConfig, rhs: FontConfig.GradientConfig) -> Bool {
        return lhs.colors == rhs.colors &&
               lhs.startPoint == rhs.startPoint &&
               lhs.endPoint == rhs.endPoint &&
               lhs.opacity == rhs.opacity
    }
}

// MARK: - Preview

#Preview {
    CursorView(
        height: 200,
        readings: [],
        scaleHeight: 25,
        cursorDisplayMode: .constant(.values)
    )
    .frame(width: 100, height: 200)
    .background(Color.gray.opacity(0.2))
}