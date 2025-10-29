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
            size: 10,
            color: .black,
            weight: .regular,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,  // System font
            size: 10,
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
            size: 16,
            color: .black,
            weight: .bold,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,
            size: 14,
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
            size: 10,
            color: .black,
            weight: .bold,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,
            size: 10,
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
            size: 10,
            color: .black,
            weight: .regular,
            design: .default,
            outline: .default,
            gradient: .default
        ),
        scaleValueFont: FontConfig(
            name: nil,
            size: 10,
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
        
        /// Default gradient: subtle dark to clear from left to right
        static let `default` = GradientConfig(
            colors: [
                Color.black.opacity(0.3),
                Color.black.opacity(0.15),
                Color.black.opacity(0.05),
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
    }
    
    /// Create a SwiftUI Font from this configuration
    func makeFont() -> Font {
        if let name = name {
            return .custom(name, size: size)
        } else {
            return .system(size: size, weight: weight, design: design)
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
    
    // MARK: - Constants
    
    /// Width of the cursor frame
    static let cursorWidth: CGFloat = 144
    
    /// Height of the drag handle (positioned ABOVE the slide rule)
    static let handleHeight: CGFloat = 32
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Gray handle at the very top - OUTSIDE the slide rule area
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.5).opacity(0.7))
                .frame(width: Self.cursorWidth, height: Self.handleHeight)
                .overlay(
                    // Visual indicator for dragging
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 2)
                            .cornerRadius(1)
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 2)
                            .cornerRadius(1)
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 2)
                            .cornerRadius(1)
                    }
                )
            
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
                    VStack(spacing: 0) {
                        ForEach(readings) { reading in
                            ZStack {
                                // Scale name gradient (left side)
                                if let gradient = displayConfig.scaleNameFont.gradient {
                                    HStack(spacing: 0) {
                                        LinearGradient(
                                            colors: gradient.colors,
                                            startPoint: gradient.startPoint,
                                            endPoint: gradient.endPoint
                                        )
                                        .opacity(gradient.opacity)
                                        .frame(width: Self.cursorWidth / 2)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // Scale value gradient (right side)
                                if let gradient = displayConfig.scaleValueFont.gradient {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        
                                        LinearGradient(
                                            colors: gradient.colors,
                                            startPoint: gradient.endPoint,  // Flip: start from trailing edge
                                            endPoint: gradient.startPoint   // Flip: end toward center/hairline
                                        )
                                        .opacity(gradient.opacity)
                                        .frame(width: Self.cursorWidth / 2)
                                    }
                                }
                            }
                            .frame(width: Self.cursorWidth, height: scaleHeight)
                        }
                    }
                }
                
                // 1pt hairline down center - solid black
                Rectangle()
                    .fill(.black)
                    .frame(width: 1, height: height)
                    .offset(x: Self.cursorWidth / 2)
                
                // Scale readings drawn with Canvas for maximum performance
                if showReadings {
                    Canvas { context, size in
                        drawScaleReadings(context: context, size: size)
                    }
                    .frame(width: Self.cursorWidth, height: height)
                }
            }
        }
    }
    
    // MARK: - Drawing Methods
    
    /// Draw scale readings using Canvas for maximum performance
    private func drawScaleReadings(context: GraphicsContext, size: CGSize) {
        let halfWidth = size.width / 2
        
        for reading in readings {
            // Calculate vertical position based on overallPosition
            let yPosition = CGFloat(reading.overallPosition) * scaleHeight + (scaleHeight / 2)
            
            // Skip if outside visible area
            guard yPosition >= 0 && yPosition <= size.height else { continue }
            
            // Draw scale name on the left (aligned left, against frame edge)
            drawText(
                context: context,
                text: reading.scaleName,
                fontConfig: displayConfig.scaleNameFont,
                xPosition: displayConfig.labelPadding,
                yPosition: yPosition,
                maxWidth: halfWidth
            )
            
            // Draw value on the right (aligned right, against frame edge)
            let valueText = Text(reading.displayValue)
                .font(displayConfig.scaleValueFont.makeFont())
                .foregroundColor(displayConfig.scaleValueFont.color)
            
            let resolvedValue = context.resolve(valueText)
            let valueSize = resolvedValue.measure(in: CGSize(width: halfWidth, height: scaleHeight))
            
            let valueX = size.width - valueSize.width - displayConfig.labelPadding
            
            drawText(
                context: context,
                text: reading.displayValue,
                fontConfig: displayConfig.scaleValueFont,
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
        maxWidth: CGFloat
    ) {
        let textView = Text(text)
            .font(fontConfig.makeFont())
            .foregroundColor(fontConfig.color)
        
        let resolved = context.resolve(textView)
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
            let outlineResolved = context.resolve(outlineText)
            
            for (dx, dy) in offsets {
                let outlineRect = CGRect(
                    x: rect.origin.x + dx,
                    y: rect.origin.y + dy,
                    width: rect.width,
                    height: rect.height
                )
                context.draw(outlineResolved, in: outlineRect)
            }
        }
        
        // Draw main text on top
        context.draw(resolved, in: rect)
    }
}

// MARK: - Preview

#Preview {
    CursorView(
        height: 200,
        readings: [],
        scaleHeight: 25
    )
    .frame(width: 100, height: 200)
    .background(Color.gray.opacity(0.2))
}