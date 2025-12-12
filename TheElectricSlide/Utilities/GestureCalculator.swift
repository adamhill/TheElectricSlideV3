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
    
    // MARK: - Slide Calculations
    
    static func calculateSlideOffset(
        translation: CGSize,
        baseOffset: CGFloat,
        scaleWidth: CGFloat,
        isPrecision: Bool = false,
        precisionFactor: CGFloat = 5.0
    ) -> SlideGestureResult {
        let adjustedTranslation = isPrecision 
            ? translation.width / precisionFactor 
            : translation.width
        
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
    
    static func calculateCursorPosition(
        translation: CGSize,
        basePosition: CGFloat,
        viewWidth: CGFloat,
        isPrecision: Bool = false,
        precisionFactor: CGFloat = 5.0
    ) -> CursorGestureResult {
        let adjustedTranslation = isPrecision
            ? translation.width / precisionFactor
            : translation.width
        
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
