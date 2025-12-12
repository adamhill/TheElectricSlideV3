//
//  GestureService.swift
//  TheElectricSlide
//
//  Protocol-based gesture service following the same pattern as HapticService.
//  Wraps pure GestureCalculator functions with haptic feedback integration.
//

import Foundation
import CoreGraphics

// MARK: - Gesture Service Protocol

/// Protocol for gesture handling - enables testing and swappable implementations
@MainActor
protocol GestureService {
    /// Process slide drag input and return calculated result
    func handleSlide(_ input: SlideGestureInput) -> SlideGestureResult
    
    /// Process cursor drag input and return calculated result
    func handleCursor(_ input: CursorGestureInput) -> CursorGestureResult
    
    /// Process zoom input and return calculated result
    func handleZoom(_ input: ZoomGestureInput) -> ZoomGestureResult
    
    /// Process pan input (zoomed content) and return bounded result
    func handlePan(_ input: PanGestureInput) -> PanGestureResult
}

// MARK: - Default Implementation

/// Production implementation of GestureService with haptic feedback integration
final class DefaultGestureService: GestureService {
    
    private let hapticService: HapticService
    
    /// Track last boundary state to avoid repeated haptics
    private var lastSlideBoundaryEdge: BoundaryEdge?
    private var lastCursorBoundaryEdge: BoundaryEdge?
    private var lastPanBoundedAxes: Set<BoundaryEdge> = []
    
    init(hapticService: HapticService = DefaultHapticService()) {
        self.hapticService = hapticService
    }
    
    func handleSlide(_ input: SlideGestureInput) -> SlideGestureResult {
        var result = GestureCalculator.calculateSlideOffset(
            translation: input.translation,
            baseOffset: input.baseOffset,
            scaleWidth: input.scaleWidth,
            isPrecision: input.isPrecisionMode,
            precisionFactor: input.precisionFactor
        )
        
        // Add momentum if velocity available
        if let velocity = input.velocity {
            result = SlideGestureResult(
                offset: result.offset,
                isBounded: result.isBounded,
                boundaryEdge: result.boundaryEdge,
                momentum: GestureCalculator.calculateMomentum(
                    velocity: velocity,
                    axis: .horizontal
                )
            )
        }
        
        // Fire haptic on NEW boundary hit (not sustained contact)
        if result.isBounded, 
           let edge = result.boundaryEdge,
           edge != lastSlideBoundaryEdge {
            hapticService.fire(.boundaryHit(edge: edge))
        }
        lastSlideBoundaryEdge = result.boundaryEdge
        
        return result
    }
    
    func handleCursor(_ input: CursorGestureInput) -> CursorGestureResult {
        var result = GestureCalculator.calculateCursorPosition(
            translation: input.translation,
            basePosition: input.basePosition,
            viewWidth: input.viewWidth,
            isPrecision: input.isPrecisionMode,
            precisionFactor: input.precisionFactor
        )
        
        // Add momentum if velocity available
        if let velocity = input.velocity {
            result = CursorGestureResult(
                normalizedPosition: result.normalizedPosition,
                isBounded: result.isBounded,
                boundaryEdge: result.boundaryEdge,
                momentum: GestureCalculator.calculateMomentum(
                    velocity: velocity,
                    axis: .horizontal
                )
            )
        }
        
        // Fire haptic on NEW boundary hit
        if result.isBounded,
           let edge = result.boundaryEdge,
           edge != lastCursorBoundaryEdge {
            hapticService.fire(.boundaryHit(edge: edge))
        }
        lastCursorBoundaryEdge = result.boundaryEdge
        
        return result
    }
    
    func handleZoom(_ input: ZoomGestureInput) -> ZoomGestureResult {
        let result = GestureCalculator.calculateZoom(
            magnification: input.magnification,
            baseScale: input.baseScale,
            minScale: input.minScale,
            maxScale: input.maxScale
        )
        
        // Fire haptic when snapping to default zoom
        if result.snappedToDefault {
            hapticService.fire(.zoomSnap)
        }
        
        return result
    }
    
    func handlePan(_ input: PanGestureInput) -> PanGestureResult {
        var result = GestureCalculator.calculateBoundedPan(
            offset: CGSize(
                width: input.baseOffset.width + input.translation.width,
                height: input.baseOffset.height + input.translation.height
            ),
            zoomScale: input.zoomScale,
            contentSize: input.contentSize,
            viewportSize: input.viewportSize
        )
        
        // Add momentum if velocity available
        if let velocity = input.velocity {
            result = PanGestureResult(
                offset: result.offset,
                boundedAxes: result.boundedAxes,
                momentum: GestureCalculator.calculateMomentum(
                    velocity: velocity,
                    axis: .horizontal  // Could choose based on dominant axis
                )
            )
        }
        
        // Fire haptic for NEW boundary hits
        let newBoundedAxes = result.boundedAxes.subtracting(lastPanBoundedAxes)
        for edge in newBoundedAxes {
            hapticService.fire(.boundaryHit(edge: edge))
        }
        lastPanBoundedAxes = result.boundedAxes
        
        return result
    }
    
    /// Reset boundary tracking state (call when gesture ends)
    func resetBoundaryState() {
        lastSlideBoundaryEdge = nil
        lastCursorBoundaryEdge = nil
        lastPanBoundedAxes = []
    }
}
