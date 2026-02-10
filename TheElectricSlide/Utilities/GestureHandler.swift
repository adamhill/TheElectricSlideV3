//
//  GestureHandler.swift
//  TheElectricSlide
//
//  Phase 4 Bold Refactor: Consolidated gesture handling to eliminate callback prop drilling.
//  Phase 5: Added momentum scrolling, bounded pan, and gesture haptic feedback.
//
//  This class encapsulates all gesture logic that was previously spread across ContentView+Gestures.swift
//  and passed through multiple view layers via callbacks.
//
//  Views access this via @Environment(\.gestureHandler) and call methods directly.
//

import SwiftUI
import SlideRuleCoreV3
import os.log

private let gestureLogger = Logger(subsystem: "com.theelectricslide", category: "GestureHandler")

// MARK: - GestureHandler Protocol

/// Protocol for gesture handling - enables testing and swappable implementations
@MainActor
protocol GestureHandlerProtocol: AnyObject {
    // MARK: - Slide Drag
    func handleSlideDragChanged(_ gesture: DragGesture.Value, isPrecision: Bool)
    func handleSlideDragEnded(_ gesture: DragGesture.Value, isPrecision: Bool)
    
    // MARK: - Zoom
    func handleZoomChanged(_ scale: CGFloat)
    func handleZoomEnded(_ scale: CGFloat)
    
    // MARK: - Pan (Zoomed Content)
    func handlePanChanged(_ gesture: DragGesture.Value)
    func handlePanEnded(_ gesture: DragGesture.Value)
    
    // MARK: - Reset Zoom
    func handleResetZoom()
    
    // MARK: - Flip
    func handleFlip()
    
    // MARK: - Cursor Drag (for tick haptics)
    func handleCursorDragChanged(_ cursorNormalizedPosition: CGFloat)
    func handleCursorDragEnded()
}

// MARK: - Momentum Configuration

/// Configuration constants for momentum scrolling behavior
enum MomentumConfig {
    /// Minimum velocity (points/second) to trigger momentum scrolling
    static let minimumVelocity: CGFloat = 50.0
    
    /// Maximum duration for momentum animation
    static let maxDuration: TimeInterval = 0.5
    
    /// Deceleration multiplier for final offset calculation
    static let decelerationMultiplier: CGFloat = 0.15
    
    /// Spring response for momentum animation
    static let springResponse: CGFloat = 0.4
    
    /// Spring damping for momentum animation
    static let springDamping: CGFloat = 0.85
}

// MARK: - GestureHandler Implementation

/// Centralized gesture handler that encapsulates all gesture logic.
/// Replaces callback prop drilling through the view hierarchy.
///
/// ## Phase 5 Features
/// - Momentum scrolling using `predictedEndTranslation`
/// - Bounded pan for zoomed content (prevents content from going off-screen)
/// - Haptic feedback on boundary hits
/// - Zoom snap haptic feedback when returning to 1.0×
@MainActor @Observable
final class GestureHandler: GestureHandlerProtocol {
    
    // MARK: - Dependencies (injected)
    
    private let viewModel: SlideRuleViewModel
    private let cursorState: CursorState
    private let tickHapticCoordinator: TickHapticCoordinator
    private let hapticService: HapticService
    
    /// Closure to get current view mode (changes over time)
    private let getViewMode: () -> ViewMode
    
    /// Closure to get current slide rule (changes when user switches rules)
    private let getSlideRule: () -> SlideRule
    
    /// Closure to get current dimensions (changes on geometry updates)
    private let getDimensions: () -> Dimensions
    
    // MARK: - Phase 5: Boundary Hit Tracking
    
    /// Track the last boundary hit to avoid duplicate haptics
    @ObservationIgnored private var lastBoundaryEdge: BoundaryEdge?
    
    // MARK: - Slide Gesture State (Phase 6: Vertical Panning)
    
    /// Direction lock for current slide gesture
    private enum GestureDirection {
        case horizontal
        case vertical
    }
    
    /// Current direction lock for the active gesture
    @ObservationIgnored private var currentSlideGestureDirection: GestureDirection?
    
    /// Base slide offset at the start of the current drag gesture
    /// Captured on first drag changed call, reset on drag ended
    @ObservationIgnored private var slideBaseOffset: CGFloat?
    
    // MARK: - Initialization
    
    init(
        viewModel: SlideRuleViewModel,
        cursorState: CursorState,
        tickHapticCoordinator: TickHapticCoordinator,
        hapticService: HapticService = DefaultHapticService(),
        getViewMode: @escaping () -> ViewMode,
        getSlideRule: @escaping () -> SlideRule,
        getDimensions: @escaping () -> Dimensions
    ) {
        self.viewModel = viewModel
        self.cursorState = cursorState
        self.tickHapticCoordinator = tickHapticCoordinator
        self.hapticService = hapticService
        self.getViewMode = getViewMode
        self.getSlideRule = getSlideRule
        self.getDimensions = getDimensions
    }
    
    // MARK: - Slide Drag Handlers
    
    /// Handles drag gesture changes for slider movement
    /// Marks cursor state as dragging, delegates to viewModel, and triggers tick haptics.
    /// Also checks for boundary hits and fires haptic feedback.
    func handleSlideDragChanged(_ gesture: DragGesture.Value, isPrecision: Bool) {
        // PHASE 6: Vertical Panning Support
        // If zoomed in and not in precision mode, check for vertical pan intent
        if viewModel.isZoomed && !isPrecision {
            // Determine direction if not yet locked
            if currentSlideGestureDirection == nil {
                let dx = abs(gesture.translation.width)
                let dy = abs(gesture.translation.height)
                
                // Threshold for direction lock (10pt ensures intent)
                if dx > 10 || dy > 10 {
                    if dy > dx * 1.5 { // Vertical bias for pan
                        currentSlideGestureDirection = .vertical
                        viewModel.setPanningSlideActive(true)
                    } else {
                        currentSlideGestureDirection = .horizontal
                        viewModel.setPanningSlideActive(false)
                    }
                } else {
                    // Waiting for threshold - swallow small movements to prevent jitter
                    return
                }
            }
            
            // If locked to vertical, handle as pan
            if currentSlideGestureDirection == .vertical {
                handlePanChanged(gesture)
                return
            }
        }
        
        // Capture base offset at start of gesture
        if slideBaseOffset == nil {
            slideBaseOffset = viewModel.sliderOffset
        }
        
        // Mark slide as dragging
        cursorState.setSlideDragging(true)
        
        // Use GestureCalculator for zoom/precision correction and boundary detection
        let dimensions = getDimensions()
        let scaleWidth = dimensions.width
        
        // Get corrected translation (handles both zoom and precision factor)
        let correctedTranslation = GestureCalculator.correctTranslationWidth(
            gesture.translation.width,
            zoomScale: viewModel.currentZoomScale,
            isPrecision: isPrecision
        )
        
        // Use the corrected translation for boundary detection
        // Pass zoomScale: 1.0 and isPrecision: false since correction was already applied
        let result = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: correctedTranslation, height: 0),
            baseOffset: slideBaseOffset ?? viewModel.sliderOffset,
            scaleWidth: scaleWidth,
            zoomScale: 1.0,
            isPrecision: false
        )
        
        // Fire boundary haptic if we hit a new boundary
        if result.isBounded, let edge = result.boundaryEdge {
            if lastBoundaryEdge != edge {
                lastBoundaryEdge = edge
                hapticService.fire(.boundaryHit(edge: edge))
            }
        } else {
            lastBoundaryEdge = nil
        }
        
        viewModel.handleSliderDragChanged(translation: correctedTranslation)
        
        // Update cursor readings after slide offset changes
        // Moved here from DynamicSlideRuleContent.onChange(of: sliderOffset) to eliminate
        // sliderOffset observation cascade through the view hierarchy.
        cursorState.updateReadings()
        
        // Trigger tick haptics when crossing tick marks on the slide
        let hapticScale = TickHapticCoordinator.selectHapticScale(
            viewMode: getViewMode(),
            currentSlideRule: getSlideRule()
        )
        
        if let scale = hapticScale {
            let halfCursorWidthNormalized = CursorCoordinateSystem.halfCursorWidth / scaleWidth
            let hairlinePosition = cursorState.normalizedPosition + halfCursorWidthNormalized
            
            tickHapticCoordinator.checkTickCrossing(
                cursorNormalizedPosition: hairlinePosition,
                slideOffset: viewModel.sliderOffset,
                scaleWidth: scaleWidth,
                cScale: scale
            )
        }
    }
    
    /// Handles drag gesture end for slider movement.
    /// Applies momentum scrolling using `predictedEndTranslation` for a natural feel.
    func handleSlideDragEnded(_ gesture: DragGesture.Value, isPrecision: Bool) {
        // PHASE 6: Vertical Panning Support
        // If we were vertically panning, redirect to pan ended handler
        if currentSlideGestureDirection == .vertical {
            handlePanEnded(gesture)
            // Reset direction lock
            currentSlideGestureDirection = nil
            viewModel.setPanningSlideActive(false)
            cursorState.updateReadings()
            return
        }
        
        // Reset direction lock for next gesture
        currentSlideGestureDirection = nil
        viewModel.setPanningSlideActive(false)
        
        // Reset boundary tracking
        lastBoundaryEdge = nil
        
        // Reset slide base offset for next gesture
        slideBaseOffset = nil
        
        // Calculate momentum from predicted end translation
        // Use GestureCalculator for consistent zoom/precision correction
        let momentumDelta = gesture.predictedEndTranslation.width - gesture.translation.width
        let adjustedMomentum = GestureCalculator.correctTranslationWidth(
            momentumDelta,
            zoomScale: viewModel.currentZoomScale,
            isPrecision: isPrecision
        )
        
        // Only apply momentum if significant
        if abs(adjustedMomentum) > MomentumConfig.minimumVelocity {
            let dimensions = getDimensions()
            let scaleWidth = dimensions.width
            
            // Calculate target offset with momentum
            let currentOffset = viewModel.sliderOffset
            let targetOffset = (currentOffset + adjustedMomentum * MomentumConfig.decelerationMultiplier)
                .clamped(to: -scaleWidth...scaleWidth)
            
            // Check if momentum will hit boundary
            let hitsBoundary = targetOffset == -scaleWidth || targetOffset == scaleWidth
            
            // Animate to target with spring physics
            withAnimation(.spring(
                response: MomentumConfig.springResponse,
                dampingFraction: MomentumConfig.springDamping
            )) {
                viewModel.handleSliderDragEnded()
                viewModel.handleSliderDragChanged(translation: targetOffset - currentOffset)
                viewModel.handleSliderDragEnded()
            }
            
            // Fire boundary haptic if momentum ends at boundary
            if hitsBoundary {
                // Delayed to sync with animation end
                DispatchQueue.main.asyncAfter(deadline: .now() + MomentumConfig.springResponse) { [weak self] in
                    self?.hapticService.fire(.momentumStop)
                }
            }
        } else {
            viewModel.handleSliderDragEnded()
        }
        
        cursorState.setSlideDragging(false)
        tickHapticCoordinator.reset()
    }
    
    // MARK: - Zoom Handlers
    
    /// Handles zoom gesture changes during pinch
    func handleZoomChanged(_ scale: CGFloat) {
        viewModel.handleZoomChanged(scale: scale)
    }
    
    /// Handles zoom gesture end and commits the zoom level.
    /// Fires zoom snap haptic when snapping back to 1.0×.
    func handleZoomEnded(_ scale: CGFloat) {
        let previousScale = viewModel.currentZoomScale
        viewModel.handleZoomEnded(scale: scale)
        
        // Fire haptic if we snapped back to 1.0×
        if previousScale > ZoomConstants.minZoomScale && viewModel.currentZoomScale == ZoomConstants.minZoomScale {
            hapticService.fire(.zoomSnap)
        }
        
        #if DEBUG
        gestureLogger.debug("Zoom ended at scale: \(scale, format: .fixed(precision: 2))")
        #endif
    }
    
    // MARK: - Pan Handlers (Zoomed Content)
    
    /// Estimated number of scales visible at once for height calculation
    /// A typical slide rule shows 8-12 scales per side
    private static let estimatedScaleCount: CGFloat = 10.0
    
    /// Handles pan gesture changes during drag to pan zoomed content.
    /// Uses bounded pan calculation to prevent content from going off-screen.
    func handlePanChanged(_ gesture: DragGesture.Value) {
        #if DEBUG
        print("🔴 [PanJitter] GH-Changed: " +
              "gesture.translation=(\(String(format: "%.2f", gesture.translation.width)), \(String(format: "%.2f", gesture.translation.height))) " +
              "currentPanOffset=(\(String(format: "%.2f", viewModel.panOffset.width)), \(String(format: "%.2f", viewModel.panOffset.height)))")
        #endif
        
        let dimensions = getDimensions()
        
        // Approximate content height from scaleHeight × estimated scale count
        let contentHeight = dimensions.scaleHeight * Self.estimatedScaleCount
        let contentSize = CGSize(width: dimensions.width, height: contentHeight)
        
        // Viewport is approximately the same as content at 1× zoom
        let viewportSize = contentSize
        
        // BUG FIX: Let ViewModel calculate position FIRST (it uses base + translation correctly)
        // Then use the resulting panOffset for boundary checking.
        // Previously, we incorrectly calculated newPan = currentPan + translation,
        // but gesture.translation is ABSOLUTE from drag start, and currentPan already
        // equals base + translation. This was doubling the offset.
        //
        // Pan uses .global coordinate space, so apply zoom correction via centralized helper
        // Note: isPrecision=false because pan never uses precision mode
        let zoomCorrectedTranslation = GestureCalculator.correctTranslation(
            gesture.translation,
            zoomScale: viewModel.currentZoomScale,
            isPrecision: false  // Pan always uses global coordinate space, never precision
        )
        withTransaction(Transaction(animation: nil)) {
            viewModel.handlePanChanged(translation: zoomCorrectedTranslation)
        }
        
        // Now use the correctly calculated panOffset for boundary checking
        let result = GestureCalculator.calculateBoundedPan(
            offset: viewModel.panOffset,
            zoomScale: viewModel.currentZoomScale,
            contentSize: contentSize,
            viewportSize: viewportSize
        )
        
        // Fire boundary haptics only for VERTICAL boundaries (top/bottom)
        // Horizontal edges (leading/trailing) are too easily triggered when panning
        // content that extends off-screen, causing unwanted haptic spam
        for edge in result.boundedAxes where edge == .top || edge == .bottom {
            if lastBoundaryEdge != edge {
                lastBoundaryEdge = edge
                hapticService.fire(.boundaryHit(edge: edge))
                break // Only one haptic per gesture update
            }
        }
        
        // Only reset boundary tracking if NO vertical boundaries are hit
        let hasVerticalBoundary = result.boundedAxes.contains { $0 == .top || $0 == .bottom }
        if !hasVerticalBoundary {
            lastBoundaryEdge = nil
        }
    }
    
    /// Handles pan gesture end and commits the new base offset.
    /// Applies bounded pan to ensure content stays visible.
    func handlePanEnded(_ gesture: DragGesture.Value) {
        #if DEBUG
        print("🟢 [PanJitter] GH-Ended: " +
              "gesture.translation=(\(String(format: "%.2f", gesture.translation.width)), \(String(format: "%.2f", gesture.translation.height))) " +
              "finalPanOffset=(\(String(format: "%.2f", viewModel.panOffset.width)), \(String(format: "%.2f", viewModel.panOffset.height)))")
        #endif
        
        // Reset boundary tracking
        lastBoundaryEdge = nil
        
        let dimensions = getDimensions()
        
        // Approximate content/viewport sizes (same logic as handlePanChanged)
        let contentHeight = dimensions.scaleHeight * Self.estimatedScaleCount
        let contentSize = CGSize(width: dimensions.width, height: contentHeight)
        let viewportSize = contentSize
        
        // Calculate final bounded position
        let result = GestureCalculator.calculateBoundedPan(
            offset: viewModel.panOffset,
            zoomScale: viewModel.currentZoomScale,
            contentSize: contentSize,
            viewportSize: viewportSize
        )
        
        // If we need to snap back into bounds, animate it
        if !result.boundedAxes.isEmpty {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.handlePanEnded()
            }
        } else {
            withTransaction(Transaction(animation: nil)) {
                viewModel.handlePanEnded()
            }
        }
    }
    // MARK: - Reset Zoom Handler
    
    /// Handles triple-tap to reset zoom to 1.0× and clear pan offset.
    /// Fires zoom snap haptic when resetting from a zoomed state.
    func handleResetZoom() {
        // Check if we're actually zoomed (not 1.0) before resetting
        let wasZoomed = abs(viewModel.currentZoomScale - ZoomConstants.defaultZoomScale) > 0.001
        
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.resetZoom()
        }
        
        // Fire haptic if we were zoomed and now reset to 1.0×
        if wasZoomed {
            hapticService.fire(.zoomSnap)
        }
    }
    
    // MARK: - Flip Handler
    
    /// Handles vertical swipe to flip between front and back sides
    /// Note: This modifies viewMode which requires the binding in ContentView
    /// For now, this will be handled via a callback until we add @Bindable viewMode
    @ObservationIgnored
    var onFlipRequested: (() -> Void)?
    
    func handleFlip() {
        onFlipRequested?()
    }
    
    // MARK: - Cursor Drag Handlers (Tick Haptics)
    
    /// Handles cursor drag changes for tick haptics
    func handleCursorDragChanged(_ cursorNormalizedPosition: CGFloat) {
        let hapticScale = TickHapticCoordinator.selectHapticScale(
            viewMode: getViewMode(),
            currentSlideRule: getSlideRule()
        )
        
        if let scale = hapticScale {
            let dimensions = getDimensions()
            let scaleWidth = dimensions.width
            let halfCursorWidthNormalized = CursorCoordinateSystem.halfCursorWidth / scaleWidth
            let hairlinePosition = cursorNormalizedPosition + halfCursorWidthNormalized
            
            tickHapticCoordinator.checkTickCrossing(
                cursorNormalizedPosition: hairlinePosition,
                slideOffset: viewModel.sliderOffset,
                scaleWidth: scaleWidth,
                cScale: scale
            )
        }
    }
    
    /// Handles cursor drag end for tick haptics
    func handleCursorDragEnded() {
        tickHapticCoordinator.reset()
    }
}

// MARK: - Environment Key

private struct GestureHandlerKey: EnvironmentKey {
    static let defaultValue: GestureHandler? = nil
}

extension EnvironmentValues {
    /// The gesture handler for centralized gesture processing.
    /// Views access this to handle gestures directly without callback prop drilling.
    var gestureHandler: GestureHandler? {
        get { self[GestureHandlerKey.self] }
        set { self[GestureHandlerKey.self] = newValue }
    }
}

extension View {
    /// Injects the GestureHandler into the environment.
    /// Child views can call gesture methods directly.
    func gestureHandler(_ handler: GestureHandler) -> some View {
        environment(\.gestureHandler, handler)
    }
}

// MARK: - Mock for Testing

/// Mock gesture handler for testing
@MainActor
final class MockGestureHandler: GestureHandlerProtocol {
    var slideDragChangedCallCount = 0
    var slideDragEndedCallCount = 0
    var zoomChangedCallCount = 0
    var zoomEndedCallCount = 0
    var panChangedCallCount = 0
    var panEndedCallCount = 0
    var resetZoomCallCount = 0
    var flipCallCount = 0
    var cursorDragChangedCallCount = 0
    var cursorDragEndedCallCount = 0
    
    var lastPrecisionMode: Bool?
    var lastZoomScale: CGFloat?
    var lastCursorPosition: CGFloat?
    
    func handleSlideDragChanged(_ gesture: DragGesture.Value, isPrecision: Bool) {
        slideDragChangedCallCount += 1
        lastPrecisionMode = isPrecision
    }
    
    func handleSlideDragEnded(_ gesture: DragGesture.Value, isPrecision: Bool) {
        slideDragEndedCallCount += 1
        lastPrecisionMode = isPrecision
    }
    
    func handleZoomChanged(_ scale: CGFloat) {
        zoomChangedCallCount += 1
        lastZoomScale = scale
    }
    
    func handleZoomEnded(_ scale: CGFloat) {
        zoomEndedCallCount += 1
        lastZoomScale = scale
    }
    
    func handlePanChanged(_ gesture: DragGesture.Value) {
        panChangedCallCount += 1
    }
    
    func handlePanEnded(_ gesture: DragGesture.Value) {
        panEndedCallCount += 1
    }
    
    func handleResetZoom() {
        resetZoomCallCount += 1
    }
    
    func handleFlip() {
        flipCallCount += 1
    }
    
    func handleCursorDragChanged(_ cursorNormalizedPosition: CGFloat) {
        cursorDragChangedCallCount += 1
        lastCursorPosition = cursorNormalizedPosition
    }
    
    func handleCursorDragEnded() {
        cursorDragEndedCallCount += 1
    }
    
    func reset() {
        slideDragChangedCallCount = 0
        slideDragEndedCallCount = 0
        zoomChangedCallCount = 0
        zoomEndedCallCount = 0
        panChangedCallCount = 0
        panEndedCallCount = 0
        resetZoomCallCount = 0
        flipCallCount = 0
        cursorDragChangedCallCount = 0
        cursorDragEndedCallCount = 0
        lastPrecisionMode = nil
        lastZoomScale = nil
        lastCursorPosition = nil
    }
}
