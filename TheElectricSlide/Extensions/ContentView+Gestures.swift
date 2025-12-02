//
//  ContentView+Gestures.swift
//  TheElectricSlide
//
//  Gesture handlers extracted from ContentView.swift
//

import SwiftUI

// MARK: - Gesture Handlers

extension ContentView {
    
    // MARK: - Drag Gesture Handlers (Slide Movement)
    
    /// Handles drag gesture changes for slider movement
    /// Marks cursor state as dragging and delegates to viewModel
    func handleDragChanged(_ gesture: DragGesture.Value) {
        // Mark slide as dragging
        cursorState.setSlideDragging(true)
        viewModel.handleSliderDragChanged(translation: gesture.translation.width)
    }
    
    /// Handles drag gesture end for slider movement
    /// Commits slider position and marks drag as ended
    func handleDragEnded(_ gesture: DragGesture.Value) {
        viewModel.handleSliderDragEnded()
        // Mark slide drag as ended
        cursorState.setSlideDragging(false)
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
}
