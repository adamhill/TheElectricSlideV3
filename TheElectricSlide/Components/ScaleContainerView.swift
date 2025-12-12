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
    
    // Equatable conformance - only compare properties that affect rendering
    static func == (lhs: ScaleContainerView, rhs: ScaleContainerView) -> Bool {
        lhs.ruleId == rhs.ruleId &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.scaleCount == rhs.scaleCount &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor
    }
    
    // Calculate total max height based on number of scales
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(container.scales.count)
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
                    formulaFont: formulaFont
                )
                .equatable()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            Group {
                if container.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}
