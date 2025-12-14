//
//  StatorView.swift
//  TheElectricSlide
//
//  Renders multiple scales for a stator (fixed portion of slide rule)
//  Extracted from ContentView.swift for better organization
//
//  Phase 7 Cleanup: Removed callback prop drilling - all gestures now use
//  @Environment(\.gestureHandler). No more legacy callback initializers.
//
//  Refactored to use ScaleContainerView to eliminate duplication with SlideView
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - StatorView Component (renders multiple scales)

struct StatorView: View, Equatable {
    @Environment(\.gestureHandler) private var gestureHandler
    
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    let cursorState: CursorState?
    let ruleId: UUID?
    let currentZoomScale: CGFloat
    
    // Equatable conformance - delegate to ScaleContainerView's comparison plus zoom scale
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        lhs.ruleId == rhs.ruleId &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.stator.scales.count == rhs.stator.scales.count &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor &&
        lhs.currentZoomScale == rhs.currentZoomScale
    }
    
    var body: some View {
        ScaleContainerView(
            container: stator,
            width: width,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth,
            nameFont: nameFont,
            formulaFont: formulaFont,
            ruleId: ruleId,
            scaleCount: stator.scales.count
        )
        .equatable()
        .contentShape(Rectangle())  // Make entire area tappable for cursor and pan gestures
        .highPriorityGesture(
            (currentZoomScale > 1.0 && gestureHandler != nil) ?
                DragGesture(minimumDistance: 0, coordinateSpace: .global)  // .global prevents jitter
                    .onChanged { gesture in
                        #if DEBUG
                        print("🟠 [PanJitter] StatorView-onChanged: stator translation=(\(String(format: "%.2f", gesture.translation.width)), \(String(format: "%.2f", gesture.translation.height)))")
                        #endif
                        gestureHandler?.handlePanChanged(gesture)
                    }
                    .onEnded { gesture in
                        #if DEBUG
                        print("🟠 [PanJitter] StatorView-onEnded: stator translation=(\(String(format: "%.2f", gesture.translation.width)), \(String(format: "%.2f", gesture.translation.height)))")
                        #endif
                        gestureHandler?.handlePanEnded(gesture)
                    }
                : nil
        )
        .onTapGesture(count: 3) {
            gestureHandler?.handleResetZoom()
        }
        .onTapGesture {
            // Mark stator as touched (sticky readings)
            cursorState?.setStatorTouched()
        }
    }
}
