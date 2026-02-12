//
//  SideView.swift
//  TheElectricSlide
//
//  Renders a complete side of the slide rule: top stator, slide, bottom stator
//  Originally extracted from ContentView.swift for better organization.
//
//  Phase 8 Refactor: Collapsed StatorView and SlideView into SideView.
//  StatorView and SlideView were thin wrappers around ScaleContainerView that
//  existed only to attach gestures and the precision overlay. Their functionality
//  is now inlined here as private @ViewBuilder methods, eliminating 2 intermediate
//  view types and ~30 repeated parameters across their init signatures.
//
//  Gesture coordination remains here — all gestures use @Environment(\.gestureHandler).
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - SideView Component (renders complete side: top stator, slide, bottom stator)

struct SideView: View, Equatable {
    @Environment(\.hapticService) private var haptics
    @Environment(\.precisionCoordinator) private var precisionCoordinator
    @Environment(\.gestureHandler) private var gestureHandler
    @Environment(\.slideRuleViewModel) private var viewModel
    @Environment(\.cursorState) private var cursorState
    
    let side: RuleSide
    let topStator: Stator
    let slide: Slide
    let bottomStator: Stator
    /// Layout dimensions — stored property for `.equatable()` compatibility.
    /// `@Environment` values are invisible to `static func ==`, so `.equatable()` would
    /// block dimension-change re-renders. Passing as a stored `let` makes it part of the
    /// value identity that `.equatable()` compares.
    let dimensions: Dimensions
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
    // Note: dimensions is a stored property (not @Environment) so .equatable() can detect changes
    static func == (lhs: SideView, rhs: SideView) -> Bool {
        lhs.side == rhs.side &&
        lhs.dimensions == rhs.dimensions &&  // Critical: detect layout changes for .equatable()
        lhs.ruleId == rhs.ruleId &&  // Compare rule ID to detect rule changes
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
    
    // MARK: - Body
    
    var body: some View {
        // 🔍 DIAGNOSTIC: See which properties trigger body re-evaluation
        #if DEBUG
        let _ = Self._printChanges()
        #endif

        VStack(spacing: 0) {
            // Top Stator (Fixed)
            statorContent(stator: topStator)
                .id("\(idPrefix)-topStator")
            
            // Slide (Movable) - with drag gestures and precision overlay
            slideContent
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
                .id("\(idPrefix)-slide")
            
            // Bottom Stator (Fixed)
            statorContent(stator: bottomStator)
                .id("\(idPrefix)-bottomStator")
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
    
    // MARK: - Stator Content (formerly StatorView)
    
    /// Renders a stator (fixed portion) with ScaleContainerView, pan gestures, and tap gestures.
    /// This replaces the standalone StatorView type — all parameters come from SideView's properties.
    @ViewBuilder
    private func statorContent(stator: Stator) -> some View {
        ScaleContainerView(
            container: stator,
            dimensions: dimensions,
            backgroundColor: statorBackgroundColor,
            borderColor: side.borderColor,
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
    }
    
    // MARK: - Slide Content (formerly SlideView)
    
    /// Renders the slide (movable portion) with ScaleContainerView and precision overlay.
    /// Drag gestures are attached in body rather than here, because they need @GestureState
    /// and other state that's more naturally managed at the body level.
    @ViewBuilder
    private var slideContent: some View {
        let isPrecisionActive = precisionCoordinator.isActive(for: .slide(side))
        
        ZStack {
            // Slide rendering - precision mode intensifies scale colors via ScaleContainerView
            ScaleContainerView(
                container: slide,
                dimensions: dimensions,
                backgroundColor: slideBackgroundColor,
                borderColor: .orange,
                ruleId: ruleId,
                scaleCount: slide.scales.count,
                useManufacturerColors: useManufacturerColors,
                colorScheme: colorScheme,
                isPrecisionActive: isPrecisionActive
            )
            .equatable()
            
            // Precision overlay for slide - ALWAYS shown when precision is active
            // - Faber-Castell uses green gradient
            // - Other manufacturers use red-orange overlay
            // The overlay provides visual feedback in addition to any scale highlighting
            if isPrecisionActive {
                slidePrecisionOverlay
            }
        }
        .accessibilityIdentifier("slide-view-root")
    }
    
    /// Precision mode visual overlay for the slide component.
    /// Renders gradient edges (top/bottom) to indicate precision drag mode is active.
    @ViewBuilder
    private var slidePrecisionOverlay: some View {
        // Get precision color from color scheme (centralized in SlideRuleColorScheme)
        let precisionColor: Color = colorScheme?.precisionOverlayColor ?? Color(red: 1.0, green: 0.4, blue: 0.3)
        let slideHeight = dimensions.scaleHeight * CGFloat(slide.scales.count)
        
        VStack(spacing: 0) {
            // Top edge gradient - increased opacity for better visibility
            LinearGradient(
                colors: [
                    precisionColor.opacity(0.65),
                    precisionColor.opacity(0.45),
                    precisionColor.opacity(0.2),
                    precisionColor.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: dimensions.width, height: slideHeight * 0.25)
            .allowsHitTesting(false)
            .accessibilityIdentifier("slide-precision-gradient-top")
            
            Spacer()
            
            // Bottom edge gradient - increased opacity for better visibility
            LinearGradient(
                colors: [
                    precisionColor.opacity(0.0),
                    precisionColor.opacity(0.2),
                    precisionColor.opacity(0.45),
                    precisionColor.opacity(0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: dimensions.width, height: slideHeight * 0.25)
            .allowsHitTesting(false)
            .accessibilityIdentifier("slide-precision-gradient-bottom")
        }
        .frame(width: dimensions.width, height: slideHeight)
        .allowsHitTesting(false)
        .accessibilityIdentifier("slide-precision-overlay-container")
    }
}
