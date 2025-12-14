//
//  SideView.swift
//  TheElectricSlide
//
//  Renders a complete side of the slide rule: top stator, slide, bottom stator
//  Extracted from ContentView.swift for better organization
//
//  Phase 7 Cleanup: Removed callback prop drilling - all gestures now use
//  @Environment(\.gestureHandler). No more legacy callback initializers.
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - SideView Component (renders complete side: top stator, slide, bottom stator)

struct SideView: View, Equatable {
    @Environment(\.hapticService) private var haptics
    @Environment(\.precisionCoordinator) private var precisionCoordinator
    @Environment(\.gestureHandler) private var gestureHandler
    
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
    
    // MARK: - Vertical Swipe State
    
    /// Threshold for vertical swipe detection (points)
    private static let verticalSwipeThreshold: CGFloat = 50
    
    /// Maximum duration for a quick flick gesture (seconds)
    /// Gestures longer than this are considered slow pans and won't trigger flip
    private static let flipMaxDuration: TimeInterval = 0.4
    
    /// Tracks if a vertical swipe has been triggered during current gesture
    @State private var hasTriggeredFlip: Bool = false
    
    /// Tracks when the vertical swipe gesture started (for duration calculation)
    @State private var flipGestureStartTime: Date?
    
    // MARK: - Slide Precision Mode State
    
    /// Whether precision mode is active (for GestureState tracking - auto-resets)
    @GestureState private var isSlidePrecisionDragging: Bool = false
    
    // ✅ Equatable conformance - only compare properties affecting rendering
    // Note: cursorState is not compared in Equatable
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
                currentZoomScale: currentZoomScale  // For pan gesture control
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
                gestureHandler?.handleResetZoom()
            }
            // Normal drag gesture for standard slide movement
            // Suppressed when precision sequence is active for slide
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Block if precision sequence is active for slide
                        guard precisionCoordinator.activeTarget != .slide else {
                            #if DEBUG
                            print("⚠️ [Slide.NormalDrag.onChanged] BLOCKED - precision active")
                            #endif
                            return
                        }
                        gestureHandler?.handleSlideDragChanged(gesture, isPrecision: false)
                    }
                    .onEnded { gesture in
                        // Block if precision sequence is active for slide
                        guard precisionCoordinator.activeTarget != .slide else {
                            #if DEBUG
                            print("⚠️ [Slide.NormalDrag.onEnded] BLOCKED - precision active")
                            #endif
                            return
                        }
                        gestureHandler?.handleSlideDragEnded(gesture, isPrecision: false)
                    }
            )
            // Long-press sequenced with drag for precision slide movement
            .simultaneousGesture(
                LongPressGesture(minimumDuration: PrecisionDragConstants.longPressMinimumDuration)
                    .onEnded { _ in
                        // Enter precision sequence with haptic feedback
                        precisionCoordinator.activate(for: .slide)
                        haptics.fire(.longBuzz)
                        #if DEBUG
                        print("🎯 [Slide.Precision] MODE ACTIVATED via PrecisionDragCoordinator")
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
                                precisionCoordinator.recordTranslation(drag.translation)
                                #if DEBUG
                                print("🎯 [Slide.Precision.onChanged] translation=\(String(format: "%.2f", drag.translation.width))")
                                #endif
                                gestureHandler?.handleSlideDragChanged(drag, isPrecision: true)
                            }
                        default:
                            break
                        }
                    }
                    .onEnded { value in
                        #if DEBUG
                        print("🎯 [Slide.Precision.onEnded] Using coordinator's lastAppliedTranslation")
                        #endif
                        
                        // Create a synthetic gesture value using last applied translation
                        // to prevent finger-lift jitter
                        if case .second(true, let drag) = value, let drag = drag {
                            gestureHandler?.handleSlideDragEnded(drag, isPrecision: true)
                        }
                        
                        // End precision session with cooldown
                        precisionCoordinator.deactivate()
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
                currentZoomScale: currentZoomScale  // For pan gesture control
            )
            .equatable()
            .id("\(idPrefix)-bottomStator")  // Use rule-aware ID to force re-render on rule change
        }
        #if os(iOS)
        // MARK: - Vertical Swipe Gesture for Side Flip (iOS/iPadOS only)
        // NOTE: Disabled on macOS where swipe gestures feel unnatural with trackpad
        // macOS users can tap the header to cycle view modes instead
        // Requires QUICK FLICK (short duration) to distinguish from slow panning
        .simultaneousGesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onChanged { gesture in
                    // Record start time on first movement
                    if flipGestureStartTime == nil {
                        flipGestureStartTime = Date()
                    }
                }
                .onEnded { gesture in
                    // Calculate gesture duration
                    let duration = flipGestureStartTime.map { Date().timeIntervalSince($0) } ?? 0
                    
                    // Reset state for next gesture
                    flipGestureStartTime = nil
                    
                    // Skip if already triggered or no handler
                    guard !hasTriggeredFlip, gestureHandler != nil else {
                        hasTriggeredFlip = false
                        return
                    }
                    
                    let verticalDistance = abs(gesture.translation.height)
                    let horizontalDistance = abs(gesture.translation.width)
                    
                    // Require ALL conditions for flip:
                    // 1. Vertical motion exceeds threshold (50px)
                    // 2. Vertical motion dominates horizontal (1.5× ratio)
                    // 3. Gesture was quick (< 0.4 seconds) - distinguishes flick from slow pan
                    let isVerticalEnough = verticalDistance > Self.verticalSwipeThreshold
                    let isVerticalDominant = verticalDistance > horizontalDistance * 1.5
                    let isQuickFlick = duration < Self.flipMaxDuration
                    
                    if isVerticalEnough && isVerticalDominant && isQuickFlick {
                        hasTriggeredFlip = true
                        haptics.fire(.flip)
                        gestureHandler?.handleFlip()
                    }
                    
                    // Reset flip trigger for next gesture
                    hasTriggeredFlip = false
                }
        )
        #endif
    }
}
