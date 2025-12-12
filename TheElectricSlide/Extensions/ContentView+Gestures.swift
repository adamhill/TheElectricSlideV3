//
//  ContentView+Gestures.swift
//  TheElectricSlide
//
//  Gesture handlers extracted from ContentView.swift
//

import SwiftUI
import SlideRuleCoreV3
import os.log

private let gestureLogger = Logger(subsystem: "com.theelectricslide", category: "Gestures")

// MARK: - Gesture Handlers

extension ContentView {
    
    // MARK: - Drag Gesture Handlers (Slide Movement)
    
    /// Handles drag gesture changes for slider movement
    /// Marks cursor state as dragging, delegates to viewModel, and triggers tick haptics
    /// - Parameters:
    ///   - gesture: The drag gesture value
    ///   - isPrecision: Whether precision mode is active (reduced sensitivity)
    func handleDragChanged(_ gesture: DragGesture.Value, isPrecision: Bool) {
        // Mark slide as dragging
        cursorState.setSlideDragging(true)
        
        // Apply precision factor if in precision mode
        let translationWidth = isPrecision
            ? gesture.translation.width / PrecisionDragConstants.precisionFactor
            : gesture.translation.width
        
        viewModel.handleSliderDragChanged(translation: translationWidth)
        
        // Trigger tick haptics when crossing tick marks on the slide
        // Use centralized scale selection from TickHapticCoordinator
        let hapticScale = TickHapticCoordinator.selectHapticScale(
            viewMode: viewMode,
            currentSlideRule: currentSlideRule
        )
        
        if let scale = hapticScale {
            // Calculate hairline position (cursor position + half cursor width)
            let scaleWidth = calculatedDimensions.width
            let halfCursorWidthNormalized = (CursorView.cursorWidth / 2.0) / scaleWidth
            let hairlinePosition = cursorState.normalizedPosition + halfCursorWidthNormalized
            
            tickHapticCoordinator.checkTickCrossing(
                cursorNormalizedPosition: hairlinePosition,
                slideOffset: viewModel.sliderOffset,
                scaleWidth: scaleWidth,
                cScale: scale
            )
        }
    }
    
    /// Handles drag gesture end for slider movement
    /// Commits slider position, marks drag as ended, and resets tick haptic coordinator
    /// - Parameters:
    ///   - gesture: The drag gesture value
    ///   - isPrecision: Whether precision mode is active (for consistent factor application)
    func handleDragEnded(_ gesture: DragGesture.Value, isPrecision: Bool) {
        // Note: For precision mode, the translation has already been tracked and applied
        // during onChanged, so we don't need to reapply the factor here
        viewModel.handleSliderDragEnded()
        // Mark slide drag as ended
        cursorState.setSlideDragging(false)
        // Reset tick haptic coordinator for next drag
        tickHapticCoordinator.reset()
    }
    
    // MARK: - Zoom Gesture Handlers (Pinch-to-Zoom)
    
    /// Handles zoom gesture changes during pinch
    /// Delegates to viewModel for live zoom updates
    func handleZoomChanged(_ scale: CGFloat) {
        viewModel.handleZoomChanged(scale: scale)
    }
    
    /// Handles zoom gesture end and commits the zoom level
    /// Includes debug logging for cursor alignment verification
    func handleZoomEnded(_ scale: CGFloat) {
        viewModel.handleZoomEnded(scale: scale)
        
        // Log cursor and scale info for debugging
        #if DEBUG
        print("🔍 [Zoom Debug] Cursor normalized position: \(cursorState.normalizedPosition)")
        print("🔍 [Zoom Debug] Dimensions - width: \(calculatedDimensions.width), leftMargin: \(calculatedDimensions.leftMarginWidth)")
        if let readings = cursorState.currentReadings {
            print("🔍 [Zoom Debug] Hairline position: \(String(format: "%.4f", readings.cursorPosition))")
            // Log K, C, D scales if available
            for scaleName in ["K", "C", "D", "A"] {
                if let reading = readings.reading(forScale: scaleName, side: .front) {
                    print("🔍 [Zoom Debug]   \(scaleName) scale: \(reading.displayValue) (raw: \(String(format: "%.6f", reading.value)))")
                }
            }
        }
        #endif
    }
    
    // MARK: - Pan Gesture Handlers (Zoomed Content Movement)
    
    /// Handles pan gesture changes during drag to pan zoomed content
    /// Uses withTransaction to suppress animations for smooth, jitter-free tracking
    func handlePanChanged(_ gesture: DragGesture.Value) {
        withTransaction(Transaction(animation: nil)) {
            viewModel.handlePanChanged(translation: gesture.translation)
        }
    }
    
    /// Handles pan gesture end and commits the new base offset
    /// Uses withTransaction to suppress animations for immediate response
    func handlePanEnded(_ gesture: DragGesture.Value) {
        withTransaction(Transaction(animation: nil)) {
            viewModel.handlePanEnded()
        }
    }
    
    // MARK: - Zoom Reset Handler
    
    /// Handles triple-tap to reset zoom to 1.0× and clear pan offset
    /// Animates the zoom reset for visual feedback
    func handleResetZoom() {
        // Reset zoom with animation for visual feedback
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.resetZoom()
        }
    }
    
    // MARK: - Flip Handler (Vertical Swipe)
    
    /// Handles vertical swipe to flip between front and back sides
    /// Uses the same animation as FlipButton for consistency
    func handleFlip() {
        // Only flip if there's a back side to flip to
        guard currentSlideRule.backTopStator != nil else { return }
        
        #if DEBUG
        let fromSide = viewMode.rawValue
        let toSide = (viewMode == .front) ? ViewMode.back.rawValue : ViewMode.front.rawValue
        print("[Flip] Swiping: \(fromSide) → \(toSide)")
        #endif
        
        // Animate the view mode transition with the same spring animation as FlipButton
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            // Toggle between front and back modes (don't toggle to .both)
            viewMode = (viewMode == .front) ? .back : .front
        }
    }
    
    // MARK: - Cursor Drag Haptic Handlers
    
    /// Handles cursor drag changes for tick haptics
    /// Uses centralized scale selection from TickHapticCoordinator (DRY)
    /// - Parameter cursorNormalizedPosition: The cursor's normalized position (0.0-1.0)
    func handleCursorDragChanged(_ cursorNormalizedPosition: CGFloat) {
        // Trigger tick haptics when crossing tick marks (cursor position changes)
        // Use centralized scale selection from TickHapticCoordinator
        let hapticScale = TickHapticCoordinator.selectHapticScale(
            viewMode: viewMode,
            currentSlideRule: currentSlideRule
        )
        
        if let scale = hapticScale {
            // Calculate hairline position (cursor position + half cursor width)
            let scaleWidth = calculatedDimensions.width
            let halfCursorWidthNormalized = (CursorView.cursorWidth / 2.0) / scaleWidth
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
    /// Resets the tick haptic coordinator for the next drag
    func handleCursorDragEnded() {
        tickHapticCoordinator.reset()
    }
}
