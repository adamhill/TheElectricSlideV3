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
    @Environment(\.cursorState) private var cursorState
    
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    let ruleId: UUID?
    let currentZoomScale: CGFloat
    
    // Manufacturer colorway support
    let useManufacturerColors: Bool
    let colorScheme: SlideRuleColorScheme?
    
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
        lhs.currentZoomScale == rhs.currentZoomScale &&
        lhs.useManufacturerColors == rhs.useManufacturerColors &&
        lhs.colorScheme?.primaryBackground == rhs.colorScheme?.primaryBackground
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
            scaleCount: stator.scales.count,
            useManufacturerColors: useManufacturerColors,
            colorScheme: colorScheme
        )
        .equatable()
        .contentShape(Rectangle())  // Make entire area tappable for cursor and pan gestures
        // Triple-tap must be simultaneousGesture to not be blocked by high-priority pan
        .simultaneousGesture(
            TapGesture(count: 3)
                .onEnded { _ in
                    gestureHandler?.handleResetZoom()
                }
        )
        // Pan gesture for zoomed content - responds immediately (minimumDistance: 0)
        // .global coordinate space prevents jitter
        // Enabled for ANY non-default zoom level (including zoomed out)
        .highPriorityGesture(
            (abs(currentZoomScale - ZoomConstants.defaultZoomScale) > 0.001 && gestureHandler != nil) ?
                DragGesture(minimumDistance: 0, coordinateSpace: .global)  // Immediate response; .global prevents jitter
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
        // Single-tap as simultaneousGesture - works alongside pan gesture
        .simultaneousGesture(
            TapGesture(count: 1)
                .onEnded { _ in
                    // Mark stator as touched (sticky readings)
                    cursorState.setStatorTouched()
                }
        )
        .accessibilityIdentifier("stator-view-root")
    }
}
