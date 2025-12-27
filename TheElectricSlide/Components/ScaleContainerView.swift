//
//  ScaleContainerView.swift
//  TheElectricSlide
//
//  Generic view component for rendering scale containers (Slide or Stator)
//  Consolidates duplicate rendering logic between SlideView and StatorView
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Generic ScaleContainerView

struct ScaleContainerView<Container: ScaleContainer>: View, Equatable {
    let container: Container
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    let ruleId: UUID?
    let scaleCount: Int  // Cached for Equatable comparison
    
    // Manufacturer colorway support
    let useManufacturerColors: Bool
    let colorScheme: SlideRuleColorScheme?
    
    // Precision mode support - intensifies scale colors when active
    var isPrecisionActive: Bool = false
    
    // Equatable conformance - only compare properties that affect rendering
    static func == (lhs: ScaleContainerView, rhs: ScaleContainerView) -> Bool {
        lhs.ruleId == rhs.ruleId &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.scaleCount == rhs.scaleCount &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor &&
        lhs.useManufacturerColors == rhs.useManufacturerColors &&
        lhs.isPrecisionActive == rhs.isPrecisionActive &&
        lhs.colorScheme?.primaryHighlight == rhs.colorScheme?.primaryHighlight &&
        lhs.colorScheme?.secondaryHighlight == rhs.colorScheme?.secondaryHighlight
    }
    
    // Calculate total max height based on number of scales
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(container.scales.count)
    }
    
    /// Returns background gradient data for drawing directly in ScaleView's Canvas
    /// This eliminates VStack preference propagation from .background() modifiers
    ///
    /// **Optimization (December 2025):**
    /// Instead of using SwiftUI's .background() which creates preference nodes,
    /// gradient data is passed to ScaleView and drawn in its Canvas.
    /// This reduces ~3000 preference updates to near zero during drag gestures.
    private func scaleBackgroundGradientData(for scaleName: String) -> ScaleBackgroundGradient? {
        guard useManufacturerColors, let scheme = colorScheme else { return nil }
        
        // Use precision-intensity gradient when precision mode is active
        if isPrecisionActive {
            return scheme.precisionScaleBackgroundGradientData(for: scaleName)
        } else {
            return scheme.scaleBackgroundGradientData(for: scaleName)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(container.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    generatedScale: generatedScale,
                    width: width,
                    height: scaleHeight,
                    leftMarginWidth: leftMarginWidth,
                    rightMarginWidth: rightMarginWidth,
                    nameFont: nameFont,
                    formulaFont: formulaFont,
                    backgroundGradient: scaleBackgroundGradientData(for: generatedScale.definition.name)
                )
                .equatable()
                .accessibilityIdentifier("scale-row-\(generatedScale.definition.name)")
            }
        }
        .accessibilityIdentifier("scale-container-vstack")
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .accessibilityIdentifier("scale-container-bg")
        )
        .overlay(
            Group {
                if container.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                        .accessibilityIdentifier("scale-container-border")
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("scale-container-root")
    }
}
