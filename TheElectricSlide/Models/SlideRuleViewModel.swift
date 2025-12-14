//
//  SlideRuleViewModel.swift
//  TheElectricSlide
//
//  Observable view model for slide rule interaction state
//  Uses hot/cold property pattern per slide-rule-performance-decisions-and-planning.md
//
//  PERFORMANCE NOTES:
//  - @ObservationIgnored for high-frequency internal state (hot properties)
//  - Published properties only update when values change meaningfully (cold properties)
//  - Gesture base values are internal implementation details, not observed
//  - See WWDC 2023 "Discover Observation in SwiftUI" for pattern rationale
//

import SwiftUI
import Observation

// MARK: - Zoom Constants

/// Constants for zoom behavior
enum ZoomConstants {
    /// Minimum zoom level (no zoom out below 1.0×)
    static let minZoomScale: CGFloat = 1.0
    /// Maximum zoom level (400%)
    static let maxZoomScale: CGFloat = 4.0
}

// MARK: - Slide Rule View Model

/// Observable view model for slide rule interaction state
/// Groups related state (slider, zoom, pan) with hot/cold property pattern
/// for optimal SwiftUI performance.
///
/// ## Performance Pattern
/// Following the hot/cold property pattern from Phase 1 optimizations:
/// - **Hot properties** (@ObservationIgnored): Internal state that changes frequently
///   during gestures (base offsets, gesture tracking)
/// - **Cold properties** (observed): Published state that triggers view updates
///   only when meaningful changes occur
///
/// This pattern reduced hitches by 85% in cursor reading updates (see performance doc).
@Observable
final class SlideRuleViewModel {
    
    // MARK: - Slider State (Hot/Cold Pattern)
    
    /// Current slider offset in points (COLD - triggers view updates)
    /// This is the rendered position of the slide
    var sliderOffset: CGFloat = 0
    
    /// Base offset at start of gesture (HOT - internal tracking only)
    /// Does NOT trigger view updates - used for gesture calculation
    @ObservationIgnored private var _sliderBaseOffset: CGFloat = 0
    
    // MARK: - Zoom State (Hot/Cold Pattern)
    
    /// Current zoom scale (COLD - triggers view updates)
    /// Range: 1.0× to maxZoomScale (4.0×)
    var currentZoomScale: CGFloat = 1.0
    
    /// Base zoom at start of gesture (HOT - internal tracking only)
    @ObservationIgnored private var _baseZoomScale: CGFloat = 1.0
    
    // MARK: - Pan State (Hot/Cold Pattern)
    
    /// Current pan offset for moving zoomed content (COLD - triggers view updates)
    var panOffset: CGSize = .zero
    
    /// Base pan offset at start of gesture (HOT - internal tracking only)
    @ObservationIgnored private var _basePanOffset: CGSize = .zero
    
    // MARK: - Scale Width (for offset clamping)
    
    /// Current scale width in points (used for slider clamping)
    /// Updated via dimensions changes
    @ObservationIgnored private var _scaleWidth: CGFloat = 800
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Scale Width Update
    
    /// Update the scale width for offset clamping calculations
    /// Called when dimensions change
    func updateScaleWidth(_ width: CGFloat) {
        _scaleWidth = width
    }
    
    // MARK: - Slider Gesture Handlers
    
    /// Handle slider drag gesture change
    /// - Parameter translation: The drag translation from gesture
    func handleSliderDragChanged(translation: CGFloat) {
        let newOffset = _sliderBaseOffset + translation
        // Clamp to valid range
        sliderOffset = min(max(newOffset, -_scaleWidth), _scaleWidth)
    }
    
    /// Handle slider drag gesture end
    /// Commits the current offset as the new base
    func handleSliderDragEnded() {
        _sliderBaseOffset = sliderOffset
    }
    
    /// Reset slider to center position
    func resetSlider() {
        sliderOffset = 0
        _sliderBaseOffset = 0
    }
    
    // MARK: - Zoom Gesture Handlers
    
    /// Handle pinch zoom gesture change
    /// - Parameter scale: The magnification scale from gesture
    func handleZoomChanged(scale: CGFloat) {
        let newScale = _baseZoomScale * scale
        // Clamp to valid range (no zoom out below 1.0×)
        currentZoomScale = min(max(newScale, ZoomConstants.minZoomScale), ZoomConstants.maxZoomScale)
    }
    
    /// Handle pinch zoom gesture end
    /// - Parameter scale: The final magnification scale from gesture
    func handleZoomEnded(scale: CGFloat) {
        let newScale = _baseZoomScale * scale
        
        // Snap to 1.0× if gesture reaches or goes below default scale
        if newScale <= ZoomConstants.minZoomScale {
            _baseZoomScale = ZoomConstants.minZoomScale
            currentZoomScale = ZoomConstants.minZoomScale
            // Reset pan offset when zooming back to 1.0×
            panOffset = .zero
            _basePanOffset = .zero
        } else {
            _baseZoomScale = min(newScale, ZoomConstants.maxZoomScale)
            currentZoomScale = _baseZoomScale
        }
        
        #if DEBUG
        print("🔍 Zoom final: currentZoomScale=\(currentZoomScale)")
        #endif
    }
    
    /// Reset zoom to 1.0× (called by triple-tap)
    func resetZoom() {
        #if DEBUG
        print("🔍 Zoom reset triggered - current: \(currentZoomScale)× → 1.0×")
        #endif
        
        currentZoomScale = ZoomConstants.minZoomScale
        _baseZoomScale = ZoomConstants.minZoomScale
        panOffset = .zero
        _basePanOffset = .zero
    }
    
    // MARK: - Pan Gesture Handlers
    
    /// Handle pan gesture change for zoomed content
    /// - Parameter translation: The drag translation from gesture
    /// Note: Uses withTransaction in caller to suppress animations
    func handlePanChanged(translation: CGSize) {
        #if DEBUG
        let oldOffset = panOffset
        #endif
        
        panOffset = CGSize(
            width: _basePanOffset.width + translation.width,
            height: _basePanOffset.height + translation.height
        )
        
        #if DEBUG
        print("🔵 [PanJitter] VM-Update: " +
              "oldOffset=(\(String(format: "%.2f", oldOffset.width)), \(String(format: "%.2f", oldOffset.height))) " +
              "newOffset=(\(String(format: "%.2f", panOffset.width)), \(String(format: "%.2f", panOffset.height))) " +
              "base=(\(String(format: "%.2f", _basePanOffset.width)), \(String(format: "%.2f", _basePanOffset.height))) " +
              "translation=(\(String(format: "%.2f", translation.width)), \(String(format: "%.2f", translation.height)))")
        #endif
    }
    
    /// Handle pan gesture end
    /// Commits the current offset as the new base
    func handlePanEnded() {
        #if DEBUG
        print("🟣 [PanJitter] VM-Ended: " +
              "oldBase=(\(String(format: "%.2f", _basePanOffset.width)), \(String(format: "%.2f", _basePanOffset.height))) " +
              "newBase=(\(String(format: "%.2f", panOffset.width)), \(String(format: "%.2f", panOffset.height)))")
        #endif
        
        _basePanOffset = panOffset
    }
    
    // MARK: - State Queries
    
    /// Whether panning is currently enabled (only when zoomed in)
    var isPanEnabled: Bool {
        currentZoomScale > ZoomConstants.minZoomScale
    }
    
    /// Whether zoom is currently active (above 1.0×)
    var isZoomed: Bool {
        currentZoomScale > ZoomConstants.minZoomScale
    }
}
