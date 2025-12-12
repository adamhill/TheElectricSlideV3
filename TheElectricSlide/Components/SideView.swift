//
//  SideView.swift
//  TheElectricSlide
//
//  Renders a complete side of the slide rule: top stator, slide, bottom stator
//  Extracted from ContentView.swift for better organization
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - SideView Component (renders complete side: top stator, slide, bottom stator)

struct SideView: View, Equatable {
    @Environment(\.hapticService) private var haptics
    
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
    let currentZoomScale: CGFloat  // Current zoom level for pan gesture control
    let onDragChanged: (DragGesture.Value, Bool) -> Void  // Bool = isPrecision
    let onDragEnded: (DragGesture.Value, Bool) -> Void  // Bool = isPrecision
    let onPanChanged: ((DragGesture.Value) -> Void)?  // Pan gesture for zoomed content
    let onPanEnded: ((DragGesture.Value) -> Void)?  // Pan gesture end
    let onResetZoom: (() -> Void)?  // Triple-tap to reset zoom to 1.0×
    let onFlip: (() -> Void)?  // Vertical swipe to flip between front/back sides
    
    // MARK: - Vertical Swipe State
    
    /// Threshold for vertical swipe detection (points)
    private static let verticalSwipeThreshold: CGFloat = 50
    
    /// Tracks if a vertical swipe has been triggered during current gesture
    @State private var hasTriggeredFlip: Bool = false
    
    // MARK: - Slide Precision Mode State
    
    /// Precision drag state for the slide (shared constants, local state)
    @State private var slidePrecisionState = PrecisionDragState()
    
    /// Whether precision mode is active (for GestureState tracking)
    @GestureState private var isSlidePrecisionDragging: Bool = false
    
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
        lhs.currentZoomScale == rhs.currentZoomScale &&
        lhs.topStator.scales.count == rhs.topStator.scales.count &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.bottomStator.scales.count == rhs.bottomStator.scales.count
        // Note: onFlip closure not compared (same pattern as other closures)
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
                ruleId: ruleId,  // Pass rule ID for identity tracking
                currentZoomScale: currentZoomScale,  // For pan gesture control
                onPanChanged: onPanChanged,  // Pan gesture for zoomed content
                onPanEnded: onPanEnded,  // Pan gesture end
                onResetZoom: onResetZoom  // Triple-tap to reset zoom
            )
            .equatable()
            .id("\(idPrefix)-topStator")  // Use rule-aware ID to force re-render on rule change
            
            // Slide (Movable) - triple-tap to reset zoom
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
            .onTapGesture(count: 3) {
                // Triple-tap to reset zoom to 1.0×
                onResetZoom?()
            }
            // Normal drag gesture for standard slide movement
            // Suppressed when precision sequence is active
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Block if precision sequence is active
                        guard !slidePrecisionState.isSequenceActive else {
                            #if DEBUG
                            print("⚠️ [Slide.NormalDrag.onChanged] BLOCKED - precision active")
                            #endif
                            return
                        }
                        onDragChanged(gesture, false)  // false = not precision
                    }
                    .onEnded { gesture in
                        // Block if precision sequence is active
                        guard !slidePrecisionState.isSequenceActive else {
                            #if DEBUG
                            print("⚠️ [Slide.NormalDrag.onEnded] BLOCKED - precision active")
                            #endif
                            return
                        }
                        onDragEnded(gesture, false)  // false = not precision
                    }
            )
            // Long-press sequenced with drag for precision slide movement
            .simultaneousGesture(
                LongPressGesture(minimumDuration: PrecisionDragConstants.longPressMinimumDuration)
                    .onEnded { _ in
                        // Enter precision sequence with haptic feedback
                        slidePrecisionState.beginSession()
                        haptics.fire(.longBuzz)
                        #if DEBUG
                        print("🎯 [Slide.Precision] MODE ACTIVATED")
                        #endif
                    }
                    .sequenced(before: DragGesture())
                    .updating($isSlidePrecisionDragging) { value, state, _ in
                        if case .second(true, _) = value {
                            state = true
                        }
                    }
                    .onChanged { value in
                        switch value {
                        case .first(true):
                            // Long press in progress
                            break
                        case .second(true, let drag):
                            if let drag = drag {
                                // Track translation for use in onEnded
                                slidePrecisionState.trackTranslation(drag.translation.width)
                                #if DEBUG
                                print("🎯 [Slide.Precision.onChanged] translation=\(String(format: "%.2f", drag.translation.width))")
                                #endif
                                onDragChanged(drag, true)  // true = precision mode
                            }
                        default:
                            break
                        }
                    }
                    .onEnded { value in
                        #if DEBUG
                        print("🎯 [Slide.Precision.onEnded] Using last applied translation=\(String(format: "%.2f", slidePrecisionState.lastAppliedTranslation))")
                        #endif
                        
                        // Create a synthetic gesture value using last applied translation
                        // to prevent finger-lift jitter
                        if case .second(true, let drag) = value, let drag = drag {
                            // Call with the gesture but handler should use lastAppliedTranslation
                            onDragEnded(drag, true)  // true = precision mode
                        }
                        
                        // End precision session with cooldown
                        slidePrecisionState.endSession()
                    }
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
                ruleId: ruleId,  // Pass rule ID for identity tracking
                currentZoomScale: currentZoomScale,  // For pan gesture control
                onPanChanged: onPanChanged,  // Pan gesture for zoomed content
                onPanEnded: onPanEnded,  // Pan gesture end
                onResetZoom: onResetZoom  // Triple-tap to reset zoom
            )
            .equatable()
            .id("\(idPrefix)-bottomStator")  // Use rule-aware ID to force re-render on rule change
        }
        // MARK: - Vertical Swipe Gesture for Side Flip
        .simultaneousGesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onChanged { gesture in
                    // Only trigger flip once per gesture and only if vertical motion dominates
                    guard !hasTriggeredFlip,
                          onFlip != nil else { return }
                    
                    let verticalDistance = abs(gesture.translation.height)
                    let horizontalDistance = abs(gesture.translation.width)
                    
                    // Require vertical motion to be significantly greater than horizontal
                    // and exceed threshold
                    if verticalDistance > Self.verticalSwipeThreshold &&
                       verticalDistance > horizontalDistance * 1.5 {
                        hasTriggeredFlip = true
                        haptics.fire(.flip)
                        onFlip?()
                    }
                }
                .onEnded { _ in
                    // Reset flip trigger for next gesture
                    hasTriggeredFlip = false
                }
        )
    }
}
