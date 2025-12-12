//
//  MockGestureService.swift
//  TheElectricSlideTests
//
//  Mock implementation of GestureService for unit tests and SwiftUI previews.
//  Tracks calls and allows stubbing return values.
//

import Foundation
@testable import TheElectricSlide

/// Mock implementation for unit tests and SwiftUI previews
final class MockGestureService: GestureService {
    
    // MARK: - Call Tracking
    
    struct SlideCall {
        let input: SlideGestureInput
        let timestamp: Date
    }
    
    struct CursorCall {
        let input: CursorGestureInput
        let timestamp: Date
    }
    
    struct ZoomCall {
        let input: ZoomGestureInput
        let timestamp: Date
    }
    
    struct PanCall {
        let input: PanGestureInput
        let timestamp: Date
    }
    
    private(set) var slideCalls: [SlideCall] = []
    private(set) var cursorCalls: [CursorCall] = []
    private(set) var zoomCalls: [ZoomCall] = []
    private(set) var panCalls: [PanCall] = []
    
    // MARK: - Stubbed Results
    
    var stubbedSlideResult: SlideGestureResult?
    var stubbedCursorResult: CursorGestureResult?
    var stubbedZoomResult: ZoomGestureResult?
    var stubbedPanResult: PanGestureResult?
    
    // MARK: - GestureService Protocol
    
    func handleSlide(_ input: SlideGestureInput) -> SlideGestureResult {
        slideCalls.append(SlideCall(input: input, timestamp: Date()))
        
        if let stubbed = stubbedSlideResult {
            return stubbed
        }
        
        // Default: pass-through calculation without haptics
        return SlideGestureResult(
            offset: input.baseOffset + input.translation.width,
            isBounded: false,
            boundaryEdge: nil,
            momentum: nil
        )
    }
    
    func handleCursor(_ input: CursorGestureInput) -> CursorGestureResult {
        cursorCalls.append(CursorCall(input: input, timestamp: Date()))
        
        if let stubbed = stubbedCursorResult {
            return stubbed
        }
        
        // Default: simple position calculation
        let normalizedDelta = input.translation.width / input.viewWidth
        let newPosition = (input.basePosition + normalizedDelta).clamped(to: 0.0...1.0)
        
        return CursorGestureResult(
            normalizedPosition: newPosition,
            isBounded: false,
            boundaryEdge: nil,
            momentum: nil
        )
    }
    
    func handleZoom(_ input: ZoomGestureInput) -> ZoomGestureResult {
        zoomCalls.append(ZoomCall(input: input, timestamp: Date()))
        
        if let stubbed = stubbedZoomResult {
            return stubbed
        }
        
        // Default: simple zoom calculation
        let newScale = (input.baseScale * input.magnification).clamped(to: input.minScale...input.maxScale)
        
        return ZoomGestureResult(
            scale: newScale,
            snappedToDefault: false
        )
    }
    
    func handlePan(_ input: PanGestureInput) -> PanGestureResult {
        panCalls.append(PanCall(input: input, timestamp: Date()))
        
        if let stubbed = stubbedPanResult {
            return stubbed
        }
        
        // Default: simple pan calculation
        return PanGestureResult(
            offset: CGSize(
                width: input.baseOffset.width + input.translation.width,
                height: input.baseOffset.height + input.translation.height
            ),
            boundedAxes: [],
            momentum: nil
        )
    }
    
    // MARK: - Test Helpers
    
    var slideCallCount: Int { slideCalls.count }
    var cursorCallCount: Int { cursorCalls.count }
    var zoomCallCount: Int { zoomCalls.count }
    var panCallCount: Int { panCalls.count }
    
    var totalCallCount: Int {
        slideCallCount + cursorCallCount + zoomCallCount + panCallCount
    }
    
    var lastSlideInput: SlideGestureInput? { slideCalls.last?.input }
    var lastCursorInput: CursorGestureInput? { cursorCalls.last?.input }
    var lastZoomInput: ZoomGestureInput? { zoomCalls.last?.input }
    var lastPanInput: PanGestureInput? { panCalls.last?.input }
    
    func reset() {
        slideCalls.removeAll()
        cursorCalls.removeAll()
        zoomCalls.removeAll()
        panCalls.removeAll()
        stubbedSlideResult = nil
        stubbedCursorResult = nil
        stubbedZoomResult = nil
        stubbedPanResult = nil
    }
}

// MARK: - Comparable Extension for Testing

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
