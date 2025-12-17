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
        lhs.isPrecisionActive == rhs.isPrecisionActive
    }
    
    var body: some View {
        ZStack {
            // Original slide rendering
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
            
            // Precision mode gradient overlay
            if isPrecisionActive {
                let precisionColor = Color(red: 1.0, green: 0.4, blue: 0.3)
                
                VStack(spacing: 0) {
                    // Top edge gradient
                    LinearGradient(
                        colors: [
                            precisionColor.opacity(0.3),
                            precisionColor.opacity(0.15),
                            precisionColor.opacity(0.05),
                            precisionColor.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: width, height: slideHeight * 0.2)
                    .allowsHitTesting(false)
                    
                    Spacer()
                    
                    // Bottom edge gradient
                    LinearGradient(
                        colors: [
                            precisionColor.opacity(0.0),
                            precisionColor.opacity(0.05),
                            precisionColor.opacity(0.15),
                            precisionColor.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: width, height: slideHeight * 0.2)
                    .allowsHitTesting(false)
                }
                .frame(width: width, height: slideHeight)
                .allowsHitTesting(false)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isPrecisionActive)
            }
        }
    }
    
    /// Calculate total height of all scales in slide
    private var slideHeight: CGFloat {
        scaleHeight * CGFloat(slide.scales.count)
    }
}
