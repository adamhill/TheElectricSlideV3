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
    
    // Equatable conformance - delegate to ScaleContainerView's comparison
    static func == (lhs: SlideView, rhs: SlideView) -> Bool {
        lhs.ruleId == rhs.ruleId &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor
    }
    
    var body: some View {
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
            scaleCount: slide.scales.count
        )
        .equatable()
    }
}
