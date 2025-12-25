//
//  SlideView.swift
//  TheElectricSlide
//
//  Renders multiple scales for a slide (movable portion of slide rule)
//  Extracted from ContentView.swift for better organization
//
//  Refactored to use ScaleContainerView to eliminate duplication with StatorView
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - SlideView Component (renders multiple scales)

struct SlideView: View, Equatable {
    let slide: Slide
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    let ruleId: UUID?
    
    /// Whether THIS slide is in precision mode
    var isPrecisionActive: Bool = false
    
    // Manufacturer colorway support
    let useManufacturerColors: Bool
    let colorScheme: SlideRuleColorScheme?
    let manufacturer: SlideRuleManufacturer?
    
    // Equatable conformance - delegate to ScaleContainerView's comparison
    static func == (lhs: SlideView, rhs: SlideView) -> Bool {
        lhs.ruleId == rhs.ruleId &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor &&
        lhs.isPrecisionActive == rhs.isPrecisionActive &&
        lhs.useManufacturerColors == rhs.useManufacturerColors &&
        lhs.colorScheme?.primaryBackground == rhs.colorScheme?.primaryBackground &&
        lhs.manufacturer == rhs.manufacturer
    }
    
    var body: some View {
        ZStack {
            // Slide rendering - precision mode intensifies scale colors via ScaleContainerView
            ScaleContainerView(
                container: slide,
                width: width,
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: nameFont,
                formulaFont: formulaFont,
                ruleId: ruleId,
                scaleCount: slide.scales.count,
                useManufacturerColors: useManufacturerColors,
                colorScheme: colorScheme,
                isPrecisionActive: isPrecisionActive
            )
            .equatable()
            
            // Precision overlay for slide
            // - Faber-Castell ALWAYS uses green gradient (regardless of manufacturer colors toggle)
            // - Other manufacturers use red-orange overlay when scale highlights are not enabled
            if isPrecisionActive && !hasScaleHighlightsEnabled {
                // Get precision color from color scheme (centralized in SlideRuleColorScheme)
                let precisionColor: Color = colorScheme?.precisionOverlayColor ?? Color(red: 1.0, green: 0.4, blue: 0.3)
                
                VStack(spacing: 0) {
                    // Top edge gradient
                    LinearGradient(
                        colors: [
                            precisionColor.opacity(0.5),
                            precisionColor.opacity(0.3),
                            precisionColor.opacity(0.12),
                            precisionColor.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: width, height: slideHeight * 0.25)
                    .allowsHitTesting(false)
                    
                    Spacer()
                    
                    // Bottom edge gradient
                    LinearGradient(
                        colors: [
                            precisionColor.opacity(0.0),
                            precisionColor.opacity(0.12),
                            precisionColor.opacity(0.3),
                            precisionColor.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: width, height: slideHeight * 0.25)
                    .allowsHitTesting(false)
                }
                .frame(width: width, height: slideHeight)
                .allowsHitTesting(false)
            }
        }
    }
    
    /// Whether scale highlights are enabled and available
    /// True only if manufacturer colors are ON and the color scheme has highlight colors
    private var hasScaleHighlightsEnabled: Bool {
        useManufacturerColors && (colorScheme?.hasScaleHighlights ?? false)
    }
    
    /// Calculate total height of all scales in slide
    private var slideHeight: CGFloat {
        scaleHeight * CGFloat(slide.scales.count)
    }
}
