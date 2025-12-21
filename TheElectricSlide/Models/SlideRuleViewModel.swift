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
    /// Minimum zoom level (zoom out to 0.8× / 80%)
    static let minZoomScale: CGFloat = 0.8
    /// Default zoom level (1.0× / 100%)
    static let defaultZoomScale: CGFloat = 1.0
    /// Maximum zoom level (200%)
    static let maxZoomScale: CGFloat = 2.5
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
    /// Range: 1.0× to maxZoomScale (2.5×)
    var currentZoomScale: CGFloat = 1.0
    
    /// Base zoom at start of gesture (HOT - internal tracking only)
    @ObservationIgnored private var _baseZoomScale: CGFloat = 1.0
    
    // MARK: - Magnification Active State (for gesture conflict resolution)
    
    /// Whether a magnification (pinch zoom) gesture is currently active.
    /// Used to disable slide drag gestures during pinch-to-zoom to prevent
    /// unintentional slide movements when fingers spread across the slide component.
    ///
    /// ## Research-Backed Design (Apple Developer Documentation)
    /// - Per "Composing SwiftUI gestures" article: Use @GestureState with .updating()
    ///   to track transient gesture state that auto-resets when gesture ends.
    /// - Per "simultaneousGesture(_:isEnabled:)" API: Conditionally disable gestures
    ///   using the isEnabled parameter based on another gesture's active state.
    ///
    /// ## Architecture Note
    /// This is a COLD property (observed) because:
    /// 1. It needs to trigger view updates in SideView to enable/disable drag gestures
    /// 2. Changes are relatively infrequent (only on pinch start/end)
    /// 3. The performance cost is minimal compared to the UX improvement
    var isMagnifying: Bool = false
    
    // MARK: - Flip Link State (for gesture conflict resolution)
    
    /// Whether a vertical flick gesture (side change) is currently active.
    /// Used to disable slide drag gestures during vertical flicks to prevent
    /// unintentional slide movements.
    ///
    /// ## Architecture Note
    /// Matches the mutex lock pattern used for pinch-to-zoom (isMagnifying).
    var isFlipping: Bool = false
    
    // MARK: - Slide Pan State (for gesture conflict resolution)
    
    /// Whether a vertical pan gesture is currently active on the slide.
    /// Used to disable horizontal slide gestures during vertical panning.
    var isPanningSlide: Bool = false
    
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
        
        // Snap to min zoom if gesture reaches or goes below minimum scale
        if newScale <= ZoomConstants.minZoomScale {
            _baseZoomScale = ZoomConstants.minZoomScale
            currentZoomScale = ZoomConstants.minZoomScale
            // Reset pan offset when fully zoomed out
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
    
    /// Reset zoom to 1.0× (called by triple-tap or rule switch)
    func resetZoom() {
        #if DEBUG
        print("🔍 Zoom reset triggered - current: \(currentZoomScale)× → 1.0×")
        #endif
        
        currentZoomScale = ZoomConstants.defaultZoomScale
        _baseZoomScale = ZoomConstants.defaultZoomScale
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
    
    // MARK: - Magnification Active State Handlers
    
    /// Called when magnification gesture starts or is in progress.
    /// Sets `isMagnifying` to true to disable slide drag gestures during pinch.
    func setMagnificationActive(_ active: Bool) {
        isMagnifying = active
    }
    
    /// Called when vertical flip gesture starts or is in progress.
    /// Sets `isFlipping` to true to disable slide drag gestures during vertical flick.
    func setFlippingActive(_ active: Bool) {
        isFlipping = active
    }
    
    /// Called when vertical pan gesture starts on the slide (when zoomed).
    /// Sets `isPanningSlide` to true to disable horizontal slide gestures.
    func setPanningSlideActive(_ active: Bool) {
        isPanningSlide = active
    }
    
    // MARK: - State Queries
    
    /// Whether panning is currently enabled (any zoom level different from default)
    var isPanEnabled: Bool {
        // Allow panning at any non-default zoom level (including zoomed out)
        // This enables "cursor panning" (moving cursor while zoomed out) and viewport panning
        abs(currentZoomScale - ZoomConstants.defaultZoomScale) > 0.001
    }
    
    /// Whether zoom is currently active (any zoom level different from default)
    /// Used for "Vertical Panning Support" decision in GestureHandler
    var isZoomed: Bool {
        abs(currentZoomScale - ZoomConstants.defaultZoomScale) > 0.001
    }
}
