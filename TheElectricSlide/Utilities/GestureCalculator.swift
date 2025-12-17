//
//  GestureCalculator.swift
//  TheElectricSlide
//
//  Pure calculation functions for gesture mathematics.
//  All functions are static, deterministic, and side-effect-free.
//

import Foundation
import CoreGraphics

/// Pure calculation functions for gesture mathematics
/// All functions are static, deterministic, and side-effect-free
enum GestureCalculator {
    
    // MARK: - Translation Correction
    
    /// Corrects a translation from screen space to model space, accounting for zoom and precision mode.
    ///
    /// When using `.global` coordinate space, gesture translations are in screen points.
    /// If the view is scaled (e.g., via `scaleEffect(zoomScale)`), we must divide by zoomScale
    /// to get the correct model-space translation.
    ///
    /// **Precision mode** uses `.local` coordinate space, which automatically compensates for
    /// view transforms, so no zoom correction is needed.
    ///
    /// - Parameters:
    ///   - translation: Raw translation from gesture (screen space for `.global`, local for `.local`)
    ///   - zoomScale: Current zoom scale (e.g., 1.0 = no zoom, 2.0 = 2× magnified)
    ///   - isPrecision: Whether precision mode is active (uses `.local` coordinate space)
    ///   - precisionFactor: Divisor for precision mode (default 5.0 = 5× slower movement)
    /// - Returns: Corrected translation in model space
    static func correctTranslation(
        _ translation: CGSize,
        zoomScale: CGFloat,
        isPrecision: Bool,
        precisionFactor: CGFloat = PrecisionDragConstants.precisionFactor
    ) -> CGSize {
        // Treat zoom scales very close to 1.0 as exactly 1.0 to avoid floating point precision bugs
        let effectiveZoomScale = abs(zoomScale - 1.0) < 0.001 ? 1.0 : zoomScale
        
        // Step 1: Apply zoom correction for global coordinate space
        // Precision gestures use local space (auto-corrected), so skip zoom correction
        let zoomCorrected = isPrecision ? translation : CGSize(
            width: translation.width / effectiveZoomScale,
            height: translation.height / effectiveZoomScale
        )
        
        // Step 2: Apply precision factor if in precision mode
        let precisionCorrected = isPrecision ? CGSize(
            width: zoomCorrected.width / precisionFactor,
            height: zoomCorrected.height / precisionFactor
        ) : zoomCorrected
        
        return precisionCorrected
    }
    
    /// Convenience method for correcting just the width component of a translation
    static func correctTranslationWidth(
        _ width: CGFloat,
        zoomScale: CGFloat,
        isPrecision: Bool,
        precisionFactor: CGFloat = PrecisionDragConstants.precisionFactor
    ) -> CGFloat {
        let corrected = correctTranslation(
            CGSize(width: width, height: 0),
            zoomScale: zoomScale,
            isPrecision: isPrecision,
            precisionFactor: precisionFactor
        )
        return corrected.width
    }
    
    // MARK: - Slide Calculations
    
    /// Calculates the new slide offset from a drag gesture.
    ///
    /// - Parameters:
    ///   - translation: Raw translation from gesture
    ///   - baseOffset: Starting offset before this drag
    ///   - scaleWidth: Width of the scale (for boundary calculation)
    ///   - zoomScale: Current zoom scale (for coordinate correction)
    ///   - isPrecision: Whether precision mode is active
    ///   - precisionFactor: Divisor for precision mode movement
    /// - Returns: Result containing bounded offset and boundary information
    static func calculateSlideOffset(
        translation: CGSize,
        baseOffset: CGFloat,
        scaleWidth: CGFloat,
        zoomScale: CGFloat = 1.0,
        isPrecision: Bool = false,
        precisionFactor: CGFloat = PrecisionDragConstants.precisionFactor
    ) -> SlideGestureResult {
        // Apply zoom and precision correction
        let adjustedTranslation = correctTranslationWidth(
            translation.width,
            zoomScale: zoomScale,
            isPrecision: isPrecision,
            precisionFactor: precisionFactor
        )
        
        let rawOffset = baseOffset + adjustedTranslation
        let boundedOffset = rawOffset.clamped(to: -scaleWidth...scaleWidth)
        
        let hitBoundary = rawOffset != boundedOffset
        let edge: BoundaryEdge? = hitBoundary
            ? (rawOffset < boundedOffset ? .leading : .trailing)
            : nil
        
        return SlideGestureResult(
            offset: boundedOffset,
            isBounded: hitBoundary,
            boundaryEdge: edge,
            momentum: nil
        )
    }
    
    // MARK: - Cursor Calculations
    
    /// Calculates the new cursor position from a drag gesture.
    ///
    /// - Parameters:
    ///   - translation: Raw translation from gesture
    ///   - basePosition: Starting normalized position (0.0-1.0) before this drag
    ///   - viewWidth: Width of the view (for normalization)
    ///   - zoomScale: Current zoom scale (for coordinate correction)
    ///   - isPrecision: Whether precision mode is active
    ///   - precisionFactor: Divisor for precision mode movement
    /// - Returns: Result containing bounded position and boundary information
    static func calculateCursorPosition(
        translation: CGSize,
        basePosition: CGFloat,
        viewWidth: CGFloat,
        zoomScale: CGFloat = 1.0,
        isPrecision: Bool = false,
        precisionFactor: CGFloat = PrecisionDragConstants.precisionFactor
    ) -> CursorGestureResult {
        // Apply zoom and precision correction
        let adjustedTranslation = correctTranslationWidth(
            translation.width,
            zoomScale: zoomScale,
            isPrecision: isPrecision,
            precisionFactor: precisionFactor
        )
        
        let normalizedDelta = adjustedTranslation / viewWidth
        let rawPosition = basePosition + normalizedDelta
        let boundedPosition = rawPosition.clamped(to: 0.0...1.0)
        
        let hitBoundary = rawPosition != boundedPosition
        let edge: BoundaryEdge? = hitBoundary
            ? (rawPosition < 0.0 ? .leading : .trailing)
            : nil
        
        return CursorGestureResult(
            normalizedPosition: boundedPosition,
            isBounded: hitBoundary,
            boundaryEdge: edge,
            momentum: nil
        )
    }
    
    // MARK: - Momentum Calculations
    
    static func calculateMomentum(
        velocity: CGSize,
        axis: Axis,
        decelerationRate: CGFloat = 0.998 // UIScrollView default
    ) -> MomentumResult {
        let v = axis == .horizontal ? velocity.width : velocity.height
        
        // Physics: d = v * (1 - decelerationRate^t) / (1 - decelerationRate)
        // Simplified for time-to-stop calculation
        let friction = 1.0 - decelerationRate
        let finalOffset = v * decelerationRate / friction
        let duration = abs(v) > 50 ? min(2.0, abs(v) / 1000.0) : 0.3
        
        return MomentumResult(
            finalOffset: finalOffset,
            duration: duration,
            curve: .friction(decelerationRate)
        )
    }
    
    // MARK: - Pan Boundary Calculations
    
    static func calculateBoundedPan(
        offset: CGSize,
        zoomScale: CGFloat,
        contentSize: CGSize,
        viewportSize: CGSize
    ) -> PanGestureResult {
        let scaledContent = CGSize(
            width: contentSize.width * zoomScale,
            height: contentSize.height * zoomScale
        )
        
        let maxPanX = max(0, (scaledContent.width - viewportSize.width) / 2)
        let maxPanY = max(0, (scaledContent.height - viewportSize.height) / 2)
        
        let boundedX = offset.width.clamped(to: -maxPanX...maxPanX)
        let boundedY = offset.height.clamped(to: -maxPanY...maxPanY)
        
        var bounded: Set<BoundaryEdge> = []
        if offset.width != boundedX {
            bounded.insert(offset.width < boundedX ? .leading : .trailing)
        }
        if offset.height != boundedY {
            bounded.insert(offset.height < boundedY ? .top : .bottom)
        }
        
        return PanGestureResult(
            offset: CGSize(width: boundedX, height: boundedY),
            boundedAxes: bounded,
            momentum: nil
        )
    }
    
    // MARK: - Zoom Calculations
    
    static func calculateZoom(
        magnification: CGFloat,
        baseScale: CGFloat,
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 4.0,
        snapThreshold: CGFloat = 0.1
    ) -> ZoomGestureResult {
        let rawScale = baseScale * magnification
        var boundedScale = rawScale.clamped(to: minScale...maxScale)
        
        // Snap to 1.0× if within threshold
        let snapped = (rawScale < minScale && abs(rawScale - minScale) < snapThreshold)
        if snapped {
            boundedScale = minScale
        }
        
        return ZoomGestureResult(scale: boundedScale, snappedToDefault: snapped)
    }
}

// MARK: - CGFloat Extension for Clamping

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
