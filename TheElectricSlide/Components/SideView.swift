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
    let sliderOffset: CGFloat
    let cursorState: CursorState?
    let ruleId: UUID?  // Track rule identity for view updates
    let currentZoomScale: CGFloat  // Current zoom level for pan gesture control
    
    // Manufacturer colorway support
    let useManufacturerColors: Bool
    let colorScheme: SlideRuleColorScheme?
    let manufacturer: SlideRuleManufacturer?
    
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
    
    /// Whether vertical flick gesture is active (for GestureState tracking - auto-resets)
    @GestureState private var isFlippingGesture: Bool = false
    
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
        // Disable when magnification (pinch-zoom) or flick gesture is active
        let isMagnifying = viewModel?.isMagnifying ?? false
        let isFlipping = viewModel?.isFlipping ?? false
        let enabled = !isMagnifying && !isFlipping
        
        #if DEBUG
        // Log when gestures are disabled - this is a key diagnostic for sticking
        if !enabled {
            print("🚫 [isSlideDragEnabled] DISABLED side=\(side) isMagnifying=\(isMagnifying) isFlipping=\(isFlipping)")
        }
        #endif
        
        return enabled
    }
    
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
                cursorState: cursorState,
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
            .offset(x: sliderOffset)
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
                        #if DEBUG
                        // DIAGNOSTIC: Log all blocking conditions to debug slide sticking
                        let isMagnifying = viewModel?.isMagnifying ?? false
                        let isFlipping = viewModel?.isFlipping ?? false
                        let precisionTarget = precisionCoordinator.activeTarget
                        let isPrecisionBlocking = { if case .slide = precisionTarget { return true } else { return false } }()
                        
                        print("🔵 [Slide.NormalDrag.onChanged] side=\(side) " +
                              "translation=(\(String(format: "%.1f", gesture.translation.width)), \(String(format: "%.1f", gesture.translation.height))) " +
                              "isSlideDragEnabled=\(isSlideDragEnabled) " +
                              "isMagnifying=\(isMagnifying) isFlipping=\(isFlipping) " +
                              "precisionBlocking=\(isPrecisionBlocking) " +
                              "precisionTarget=\(String(describing: precisionTarget))")
                        #endif
                        
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
                cursorState: cursorState,
                ruleId: ruleId,  // Pass rule ID for identity tracking
                currentZoomScale: currentZoomScale,  // For pan gesture control
                useManufacturerColors: useManufacturerColors,
                colorScheme: colorScheme
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
                // MARK: Flip Gesture Mutex Lock
                // Track gesture state to disable competing gestures
                .updating($isFlippingGesture) { value, state, _ in
                    // Only lock if gesture is clearly a vertical flip intent:
                    // - Pure vertical (horizontal < 10pt, vertical > 40pt) OR
                    // - Dominant vertical (horizontal > 15pt, vertical > 2× horizontal, vertical > 25pt)
                    let vertical = abs(value.translation.height)
                    let horizontal = abs(value.translation.width)
                    
                    let isPureVertical = horizontal < 10 && vertical > 40
                    let isDominantVertical = horizontal > 15 && vertical > horizontal * 2.0 && vertical > 25
                    
                    if isPureVertical || isDominantVertical {
                        state = true
                    }
                }
                .onChanged { gesture in
                    // Phase 6: Disable flip gesture when zoomed in (to allow vertical panning)
                    if currentZoomScale > 1.0 {
                        return
                    }
                    
                    // Record start time on first movement
                    if flipGestureStartTime == nil {
                        flipGestureStartTime = Date()
                    }
                    
                    // Update mutex lock state in ViewModel (COLD property)
                    // FIX: Use strict criteria to prevent false positives during slide drag:
                    // 1. Must have meaningful horizontal movement (>15pt) to compare ratio
                    //    - Prevents end-of-drag finger drift from triggering
                    // 2. Vertical must dominate by 2× (stricter than 1.5× onEnded threshold)
                    // 3. Vertical must exceed 25pt minimum
                    let vertical = abs(gesture.translation.height)
                    let horizontal = abs(gesture.translation.width)
                    
                    // Require meaningful horizontal movement before ratio comparison
                    // If horizontal < 15pt, the ratio is meaningless (end-of-drag drift)
                    let hasSignificantHorizontal = horizontal > 15
                    let isVerticalDominant = vertical > horizontal * 2.0  // Stricter ratio
                    let meetsMinimumThreshold = vertical > 25  // Higher threshold
                    
                    // Only activate if this looks like an intentional vertical gesture:
                    // - Either purely vertical (minimal horizontal)
                    // - Or strongly vertical dominant with significant horizontal
                    let isPureVertical = horizontal < 10 && vertical > 40
                    let isDominantVertical = hasSignificantHorizontal && isVerticalDominant && meetsMinimumThreshold
                    
                    if isPureVertical || isDominantVertical {
                        viewModel?.setFlippingActive(true)
                        #if DEBUG
                        print("🔴 [FlipGesture.onChanged] ACTIVATED isFlipping=true " +
                              "vertical=\(String(format: "%.1f", vertical)) horizontal=\(String(format: "%.1f", horizontal)) " +
                              "reason=\(isPureVertical ? "pureVertical" : "dominantVertical")")
                        #endif
                    } else {
                        // Release lock if gesture doesn't meet flip criteria
                        let wasFlipping = viewModel?.isFlipping ?? false
                        viewModel?.setFlippingActive(false)
                        #if DEBUG
                        if wasFlipping {
                            print("🟢 [FlipGesture.onChanged] DEACTIVATED isFlipping=false " +
                                  "(gesture doesn't meet flip criteria)")
                        }
                        #endif
                    }
                }
                .onEnded { gesture in
                    #if DEBUG
                    print("🟢 [FlipGesture.onEnded] Releasing mutex, was isFlipping=\(viewModel?.isFlipping ?? false)")
                    #endif
                    
                    // Phase 6: Disable flip gesture when zoomed in
                    if currentZoomScale > 1.0 {
                        viewModel?.setFlippingActive(false)
                        return
                    }
                    
                    // Release mutex lock immediately
                    viewModel?.setFlippingActive(false)
                    
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
