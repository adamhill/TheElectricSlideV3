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
    @Environment(\.slideRuleViewModel) private var viewModel
    
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
    let ruleId: UUID?  // Track rule identity for view updates
    let currentZoomScale: CGFloat  // Current zoom level for pan gesture control
    let isActiveForSliderOffset: Bool  // OPTIMIZATION: Only true for visible side to prevent back side from observing sliderOffset
    
    // Manufacturer colorway support
    let useManufacturerColors: Bool
    let colorScheme: SlideRuleColorScheme?
    let manufacturer: SlideRuleManufacturer?
    
    // MARK: - Vertical Swipe State
    
    /// Minimum vertical velocity required for flip gesture (points/second)
    /// A quick flick typically generates 800-2000+ pt/sec
    private static let flipMinVelocity: CGFloat = 600
    
    /// Minimum vertical distance for flip gesture (points)
    private static let flipMinDistance: CGFloat = 30
    
    /// Tracks if a vertical swipe has been triggered during current gesture
    @State private var hasTriggeredFlip: Bool = false
    
    // MARK: - Slide Precision Mode State
    
    /// Whether precision mode is active (for GestureState tracking - auto-resets)
    @GestureState private var isSlidePrecisionDragging: Bool = false
    
    /// Tracks if a slide drag is currently in progress (for flip gesture exclusion)
    @State private var isSlideDragActive: Bool = false
    
    // MARK: - Computed Properties for Gesture Control
    
    /// Whether slide drag gestures should be enabled.
    /// Disables drags during active magnification/pinch-zoom to prevent unintentional
    /// slide movements when fingers spread across the slide component.
    ///
    /// ## Apple Best Practice: gesture(_:isEnabled:)
    /// Per Apple Documentation ("simultaneousGesture(_:isEnabled:)"):
    /// "You can also use the `isEnabled` parameter to conditionally disable the gesture."
    /// This is the recommended approach for dynamically enabling/disabling gestures.
    private var isSlideDragEnabled: Bool {
        // Only disable when magnification (pinch-zoom) is active
        // Note: isFlipping mutex removed - flip gesture now requires slide to be stationary
        let isMagnifying = viewModel?.isMagnifying ?? false
        
        #if DEBUG
        if isMagnifying {
            print("🚫 [isSlideDragEnabled] DISABLED side=\(side) isMagnifying=\(isMagnifying)")
        }
        #endif
        
        return !isMagnifying
    }
    
    // ✅ Equatable conformance - only compare properties affecting rendering
    // Note: sliderOffset is NOT compared - it's read directly from viewModel and only affects .offset() modifier
    // Note: isActiveForSliderOffset IS compared - determines if this side observes sliderOffset
    // ruleId is compared to force re-render when rule changes
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        lhs.side == rhs.side &&
        lhs.ruleId == rhs.ruleId &&  // Compare rule ID to detect rule changes
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.currentZoomScale == rhs.currentZoomScale &&
        lhs.isActiveForSliderOffset == rhs.isActiveForSliderOffset &&
        lhs.useManufacturerColors == rhs.useManufacturerColors &&
        lhs.topStator.scales.count == rhs.topStator.scales.count &&
        lhs.slide.scales.count == rhs.slide.scales.count &&
        lhs.bottomStator.scales.count == rhs.bottomStator.scales.count
    }
    
    /// Unique identifier string combining side and rule ID for child view identity
    private var idPrefix: String {
        "\(side.rawValue)-\(ruleId?.uuidString ?? "default")"
    }
    
    /// Computed background color for stators based on manufacturer colorway toggle
    private var statorBackgroundColor: Color {
        if useManufacturerColors, let scheme = colorScheme {
            return scheme.primaryBackground
        }
        return .white
    }
    
    /// Computed background color for slide based on manufacturer colorway toggle
    private var slideBackgroundColor: Color {
        if useManufacturerColors, let scheme = colorScheme {
            return scheme.slideBackground
        }
        return .white
    }
    
    var body: some View {
        // 🔍 DIAGNOSTIC: See which properties trigger body re-evaluation
        #if DEBUG
        let _ = Self._printChanges()
        #endif

        VStack(spacing: 0) {
            // Top Stator (Fixed)
            StatorView(
                stator: topStator,
                width: width,
                backgroundColor: statorBackgroundColor,
                borderColor: side.borderColor,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: nameFont,
                formulaFont: formulaFont,
                ruleId: ruleId,  // Pass rule ID for identity tracking
                currentZoomScale: currentZoomScale,  // For pan gesture control
                useManufacturerColors: useManufacturerColors,
                colorScheme: colorScheme
            )
            .equatable()
            .id("\(idPrefix)-topStator")  // Use rule-aware ID to force re-render on rule change
            
            // Slide (Movable) - triple-tap to reset zoom
            SlideView(
                slide: slide,
                width: width,
                backgroundColor: slideBackgroundColor,
                borderColor: .orange,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: nameFont,
                formulaFont: formulaFont,
                ruleId: ruleId,  // Pass rule ID for identity tracking
                isPrecisionActive: precisionCoordinator.isActive(for: .slide(side)),
                useManufacturerColors: useManufacturerColors,
                colorScheme: colorScheme,
                manufacturer: manufacturer
            )
            .equatable()
            // OPTIMIZATION: Only observe sliderOffset when this side is active (visible).
            // Back side uses 0 offset to prevent observation cascade when not displayed.
            // This reduces AttributeGraph updates by ~50% during drag gestures.
            .offset(x: isActiveForSliderOffset ? (viewModel?.sliderOffset ?? 0) : 0)
            .onTapGesture(count: 3) {
                // Triple-tap to reset zoom to 1.0×
                gestureHandler?.handleResetZoom()
            }
            // MARK: Normal Slide Drag Gesture
            // Standard horizontal drag for slide movement.
            // Disabled during:
            // 1. Active magnification (pinch-zoom) - prevents unintentional slide when fingers spread
            // 2. Active precision sequence - defers to the long-press + drag gesture
            //
            // ## Apple Best Practice: gesture(_:isEnabled:)
            // Uses the isEnabled parameter per Apple's "gesture(_:isEnabled:)" documentation
            // to conditionally disable based on isSlideDragEnabled computed property.
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)  // minimumDistance: 0 prevents initial jump; .global prevents pan jitter under scaleEffect
                    .onChanged { gesture in
                        // Mark slide drag as active (blocks flip gesture)
                        isSlideDragActive = true
                        
                        // Block if precision sequence is active for ANY slide (prevents conflicting moves)
                        if case .slide = precisionCoordinator.activeTarget {
                            #if DEBUG
                            print("⚠️ [Slide.NormalDrag.onChanged] BLOCKED - precision active for slide")
                            #endif
                            return
                        }
                        gestureHandler?.handleSlideDragChanged(gesture, isPrecision: false)
                    }
                    .onEnded { gesture in
                        // Mark slide drag as inactive (allows flip gesture)
                        isSlideDragActive = false
                        
                        // Block if precision sequence is active for ANY slide (prevents conflicting moves)
                        if case .slide = precisionCoordinator.activeTarget {
                            #if DEBUG
                            print("⚠️ [Slide.NormalDrag.onEnded] BLOCKED - precision active for slide")
                            #endif
                            return
                        }
                        gestureHandler?.handleSlideDragEnded(gesture, isPrecision: false)
                    },
                isEnabled: isSlideDragEnabled  // Disables during pinch-zoom to prevent gesture conflict
            )
            // MARK: Precision Slide Drag Gesture (Long-press + Drag)
            // Allows fine-grained slide positioning with reduced sensitivity.
            // Also disabled during magnification to prevent conflicts.
            .simultaneousGesture(
                LongPressGesture(minimumDuration: PrecisionDragConstants.longPressMinimumDuration)
                    .onEnded { _ in
                        // Enter precision sequence with haptic feedback
                        precisionCoordinator.activate(for: .slide(side))
                        haptics.fire(.longBuzz)
                        #if DEBUG
                        print("🎯 [Slide.Precision] MODE ACTIVATED for \(side) via PrecisionDragCoordinator")
                        #endif
                    }
                    .sequenced(before: DragGesture(minimumDistance: 0))
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
                    },
                isEnabled: isSlideDragEnabled  // Disables during pinch-zoom to prevent gesture conflict
            )
            // NOTE: Removed `.animation(.interactiveSpring(), value: sliderOffset)` - was causing
            // slide sticking/stuttering on iPhone. Momentum animation is handled in
            // GestureHandler.handleSlideDragEnded() with its own spring animation.
            .id("\(idPrefix)-slide")  // Use rule-aware ID to force re-render on rule change
            
            // Bottom Stator (Fixed)
            StatorView(
                stator: bottomStator,
                width: width,
                backgroundColor: statorBackgroundColor,
                borderColor: side.borderColor,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: nameFont,
                formulaFont: formulaFont,
                ruleId: ruleId,  // Pass rule ID for identity tracking
                currentZoomScale: currentZoomScale,  // For pan gesture control
                useManufacturerColors: useManufacturerColors,
                colorScheme: colorScheme
            )
            .equatable()
            .id("\(idPrefix)-bottomStator")  // Use rule-aware ID to force re-render on rule change
        }
        #if os(iOS)
        // MARK: - Vertical Flick Gesture for Side Flip (iOS/iPadOS only)
        // Velocity-based detection: requires a QUICK vertical flick when slide is stationary.
        // This prevents accidental flips during horizontal slide dragging.
        //
        // Requirements for flip:
        // 1. Slide must NOT be actively dragging (isSlideDragActive == false)
        // 2. High vertical velocity (600+ pt/sec) - indicates quick flick
        // 3. Vertical velocity dominates horizontal (2× ratio)
        // 4. Minimum vertical distance (30pt) - prevents tiny accidental gestures
        //
        // NOTE: Disabled on macOS where swipe gestures feel unnatural with trackpad.
        // macOS users can tap the header to cycle view modes instead.
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { gesture in
                    // CRITICAL: Only allow flip when slide is NOT being dragged
                    guard !isSlideDragActive else {
                        #if DEBUG
                        print("🚫 [FlipGesture] BLOCKED - slide drag is active")
                        #endif
                        return
                    }
                    
                    // Disable flip gesture when zoomed in (to allow vertical panning)
                    guard currentZoomScale <= 1.0 else {
                        #if DEBUG
                        print("🚫 [FlipGesture] BLOCKED - zoomed in (zoom=\(String(format: "%.2f", currentZoomScale)))")
                        #endif
                        return
                    }
                    
                    // Skip if already triggered or no handler
                    guard !hasTriggeredFlip, gestureHandler != nil else {
                        hasTriggeredFlip = false
                        return
                    }
                    
                    // Extract velocity (points/second)
                    let verticalVelocity = abs(gesture.velocity.height)
                    let horizontalVelocity = abs(gesture.velocity.width)
                    
                    // Extract distance
                    let verticalDistance = abs(gesture.translation.height)
                    let horizontalDistance = abs(gesture.translation.width)
                    
                    #if DEBUG
                    print("🎯 [FlipGesture.onEnded] velocity=(\(String(format: "%.0f", gesture.velocity.width)), \(String(format: "%.0f", gesture.velocity.height))) " +
                          "translation=(\(String(format: "%.1f", gesture.translation.width)), \(String(format: "%.1f", gesture.translation.height)))")
                    #endif
                    
                    // Require ALL conditions for flip:
                    // 1. High vertical velocity (quick flick)
                    let hasHighVelocity = verticalVelocity > Self.flipMinVelocity
                    // 2. Vertical velocity dominates horizontal (2× ratio)
                    let isVelocityVertical = verticalVelocity > horizontalVelocity * 2.0
                    // 3. Minimum vertical distance traveled
                    let hasMinDistance = verticalDistance > Self.flipMinDistance
                    // 4. Distance is also vertically dominant
                    let isDistanceVertical = verticalDistance > horizontalDistance * 1.5
                    
                    if hasHighVelocity && isVelocityVertical && hasMinDistance && isDistanceVertical {
                        hasTriggeredFlip = true
                        haptics.fire(.flip)
                        gestureHandler?.handleFlip()
                        #if DEBUG
                        print("✅ [FlipGesture] TRIGGERED! velocity=\(String(format: "%.0f", verticalVelocity)) pt/sec")
                        #endif
                    } else {
                        #if DEBUG
                        print("❌ [FlipGesture] NOT triggered: " +
                              "highVel=\(hasHighVelocity) velVertical=\(isVelocityVertical) " +
                              "minDist=\(hasMinDistance) distVertical=\(isDistanceVertical)")
                        #endif
                    }
                    
                    // Reset flip trigger for next gesture
                    hasTriggeredFlip = false
                }
        )
        #endif
        .accessibilityIdentifier("side-view-\(side.rawValue)")
    }
}
