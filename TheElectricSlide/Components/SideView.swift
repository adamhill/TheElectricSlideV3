//
//  SideView.swift
//  TheElectricSlide
//
//  Renders a complete side of the slide rule: top stator, slide, bottom stator
//  Extracted from ContentView.swift for better organization
//
//  Phase 4 Bold Refactor: Replaced callback prop drilling with @Environment(\.gestureHandler)
//  Views now call gestureHandler methods directly instead of passing callbacks through layers.
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
    
    // MARK: - Legacy Callbacks (for backward compatibility during migration)
    // These will be removed once all parent views inject GestureHandler via environment
    let onDragChanged: ((DragGesture.Value, Bool) -> Void)?  // Bool = isPrecision (optional)
    let onDragEnded: ((DragGesture.Value, Bool) -> Void)?  // Bool = isPrecision (optional)
    let onPanChanged: ((DragGesture.Value) -> Void)?  // Pan gesture for zoomed content (optional)
    let onPanEnded: ((DragGesture.Value) -> Void)?  // Pan gesture end (optional)
    let onResetZoom: (() -> Void)?  // Triple-tap to reset zoom to 1.0× (optional)
    let onFlip: (() -> Void)?  // Vertical swipe to flip between front/back sides (optional)
    
    // MARK: - Convenience Initializer (without callbacks - uses environment)
    
    init(
        side: RuleSide,
        topStator: Stator,
        slide: Slide,
        bottomStator: Stator,
        width: CGFloat,
        scaleHeight: CGFloat,
        leftMarginWidth: CGFloat,
        rightMarginWidth: CGFloat,
        nameFont: Font,
        formulaFont: Font,
        sliderOffset: CGFloat,
        cursorState: CursorState?,
        ruleId: UUID?,
        currentZoomScale: CGFloat
    ) {
        self.side = side
        self.topStator = topStator
        self.slide = slide
        self.bottomStator = bottomStator
        self.width = width
        self.scaleHeight = scaleHeight
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
        self.nameFont = nameFont
        self.formulaFont = formulaFont
        self.sliderOffset = sliderOffset
        self.cursorState = cursorState
        self.ruleId = ruleId
        self.currentZoomScale = currentZoomScale
        self.onDragChanged = nil
        self.onDragEnded = nil
        self.onPanChanged = nil
        self.onPanEnded = nil
        self.onResetZoom = nil
        self.onFlip = nil
    }
    
    // MARK: - Full Initializer (with callbacks - for backward compatibility)
    
    init(
        side: RuleSide,
        topStator: Stator,
        slide: Slide,
        bottomStator: Stator,
        width: CGFloat,
        scaleHeight: CGFloat,
        leftMarginWidth: CGFloat,
        rightMarginWidth: CGFloat,
        nameFont: Font,
        formulaFont: Font,
        sliderOffset: CGFloat,
        cursorState: CursorState?,
        ruleId: UUID?,
        currentZoomScale: CGFloat,
        onDragChanged: ((DragGesture.Value, Bool) -> Void)?,
        onDragEnded: ((DragGesture.Value, Bool) -> Void)?,
        onPanChanged: ((DragGesture.Value) -> Void)?,
        onPanEnded: ((DragGesture.Value) -> Void)?,
        onResetZoom: (() -> Void)?,
        onFlip: (() -> Void)?
    ) {
        self.side = side
        self.topStator = topStator
        self.slide = slide
        self.bottomStator = bottomStator
        self.width = width
        self.scaleHeight = scaleHeight
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
        self.nameFont = nameFont
        self.formulaFont = formulaFont
        self.sliderOffset = sliderOffset
        self.cursorState = cursorState
        self.ruleId = ruleId
        self.currentZoomScale = currentZoomScale
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.onPanChanged = onPanChanged
        self.onPanEnded = onPanEnded
        self.onResetZoom = onResetZoom
        self.onFlip = onFlip
    }
    
    // MARK: - Vertical Swipe State
    
    /// Threshold for vertical swipe detection (points)
    private static let verticalSwipeThreshold: CGFloat = 50
    
    /// Tracks if a vertical swipe has been triggered during current gesture
    @State private var hasTriggeredFlip: Bool = false
    
    // MARK: - Slide Precision Mode State
    
    /// Whether precision mode is active (for GestureState tracking - auto-resets)
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
                // Phase 4: Prefer gestureHandler, fall back to callback
                if let handler = gestureHandler {
                    handler.handleResetZoom()
                } else {
                    onResetZoom?()
                }
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
                        // Phase 4: Prefer gestureHandler, fall back to callback
                        if let handler = gestureHandler {
                            handler.handleSlideDragChanged(gesture, isPrecision: false)
                        } else {
                            onDragChanged?(gesture, false)  // false = not precision
                        }
                    }
                    .onEnded { gesture in
                        // Block if precision sequence is active for slide
                        guard precisionCoordinator.activeTarget != .slide else {
                            #if DEBUG
                            print("⚠️ [Slide.NormalDrag.onEnded] BLOCKED - precision active")
                            #endif
                            return
                        }
                        // Phase 4: Prefer gestureHandler, fall back to callback
                        if let handler = gestureHandler {
                            handler.handleSlideDragEnded(gesture, isPrecision: false)
                        } else {
                            onDragEnded?(gesture, false)  // false = not precision
                        }
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
                                // Phase 4: Prefer gestureHandler, fall back to callback
                                if let handler = gestureHandler {
                                    handler.handleSlideDragChanged(drag, isPrecision: true)
                                } else {
                                    onDragChanged?(drag, true)  // true = precision mode
                                }
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
                            // Call with the gesture but handler should use coordinator's lastAppliedTranslation
                            // Phase 4: Prefer gestureHandler, fall back to callback
                            if let handler = gestureHandler {
                                handler.handleSlideDragEnded(drag, isPrecision: true)
                            } else {
                                onDragEnded?(drag, true)  // true = precision mode
                            }
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
                    // Phase 4: Check gestureHandler OR callback availability
                    let canHandleFlip = gestureHandler != nil || onFlip != nil
                    guard !hasTriggeredFlip, canHandleFlip else { return }
                    
                    let verticalDistance = abs(gesture.translation.height)
                    let horizontalDistance = abs(gesture.translation.width)
                    
                    // Require vertical motion to be significantly greater than horizontal
                    // and exceed threshold
                    if verticalDistance > Self.verticalSwipeThreshold &&
                       verticalDistance > horizontalDistance * 1.5 {
                        hasTriggeredFlip = true
                        haptics.fire(.flip)
                        // Phase 4: Prefer gestureHandler, fall back to callback
                        if let handler = gestureHandler {
                            handler.handleFlip()
                        } else {
                            onFlip?()
                        }
                    }
                }
                .onEnded { _ in
                    // Reset flip trigger for next gesture
                    hasTriggeredFlip = false
                }
        )
    }
}
