//
//  GestureServiceTests.swift
//  TheElectricSlideTests
//
//  Tests for GestureService integration - verifies that DefaultGestureService
//  correctly uses GestureCalculator and fires haptics.
//

import Testing
import Foundation
import CoreGraphics
@testable import TheElectricSlide

@Suite("GestureService Integration Tests")
@MainActor
struct GestureServiceTests {
    
    // MARK: - Setup
    
    let mockHaptic: MockHapticService
    var service: DefaultGestureService
    
    init() {
        self.mockHaptic = MockHapticService()
        self.service = DefaultGestureService(hapticService: mockHaptic)
    }
    
    // MARK: - Slide Tests
    
    @Test("handleSlide returns calculated offset")
    func slideReturnsCalculatedOffset() {
        let input = SlideGestureInput(
            translation: CGSize(width: 100, height: 0),
            velocity: nil,
            baseOffset: 50,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        let result = service.handleSlide(input)
        
        #expect(result.offset == 150)  // 50 base + 100 translation
        #expect(result.isBounded == false)
        #expect(result.boundaryEdge == nil)
    }
    
    @Test("handleSlide fires haptic on boundary hit")
    func slideFiresHapticOnBoundary() {
        let input = SlideGestureInput(
            translation: CGSize(width: 600, height: 0),
            velocity: nil,
            baseOffset: 0,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        let result = service.handleSlide(input)
        
        #expect(result.isBounded == true)
        #expect(result.boundaryEdge == .trailing)
        #expect(mockHaptic.firedEvents.count == 1)
        if case .boundaryHit(let edge) = mockHaptic.firedEvents.first {
            #expect(edge == .trailing)
        } else {
            Issue.record("Expected boundaryHit event")
        }
    }
    
    @Test("handleSlide does not fire repeated haptics for same boundary")
    func slideNoRepeatedHaptics() {
        let input = SlideGestureInput(
            translation: CGSize(width: 600, height: 0),
            velocity: nil,
            baseOffset: 0,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        // First call fires haptic
        _ = service.handleSlide(input)
        #expect(mockHaptic.firedEvents.count == 1)
        
        // Second call with same boundary does NOT fire again
        _ = service.handleSlide(input)
        #expect(mockHaptic.firedEvents.count == 1)  // Still just 1
        
        // Moving away from boundary
        let inputAway = SlideGestureInput(
            translation: CGSize(width: 100, height: 0),
            velocity: nil,
            baseOffset: 0,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        _ = service.handleSlide(inputAway)
        
        // Coming back to boundary fires again
        _ = service.handleSlide(input)
        #expect(mockHaptic.firedEvents.count == 2)
    }
    
    @Test("handleSlide includes momentum when velocity provided")
    func slideIncludesMomentum() {
        let input = SlideGestureInput(
            translation: CGSize(width: 100, height: 0),
            velocity: CGSize(width: 500, height: 0),
            baseOffset: 0,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        let result = service.handleSlide(input)
        
        #expect(result.momentum != nil)
        #expect(result.momentum!.finalOffset > 0)
    }
    
    // MARK: - Cursor Tests
    
    @Test("handleCursor normalizes position correctly")
    func cursorNormalizesPosition() {
        let input = CursorGestureInput(
            translation: CGSize(width: 100, height: 0),
            velocity: nil,
            basePosition: 0.5,
            viewWidth: 400,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        let result = service.handleCursor(input)
        
        // 0.5 + (100 / 400) = 0.5 + 0.25 = 0.75
        #expect(result.normalizedPosition == 0.75)
    }
    
    @Test("handleCursor fires haptic on leading boundary")
    func cursorFiresHapticOnLeadingBoundary() {
        let input = CursorGestureInput(
            translation: CGSize(width: -300, height: 0),
            velocity: nil,
            basePosition: 0.5,
            viewWidth: 400,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        let result = service.handleCursor(input)
        
        #expect(result.normalizedPosition == 0.0)
        #expect(result.isBounded == true)
        #expect(result.boundaryEdge == .leading)
        
        if case .boundaryHit(let edge) = mockHaptic.firedEvents.first {
            #expect(edge == .leading)
        } else {
            Issue.record("Expected boundaryHit event")
        }
    }
    
    // MARK: - Zoom Tests
    
    @Test("handleZoom clamps to max scale")
    func zoomClampsToMax() {
        let input = ZoomGestureInput(
            magnification: 10.0,  // Way over max
            baseScale: 1.0,
            minScale: 1.0,
            maxScale: 4.0
        )
        
        let result = service.handleZoom(input)
        
        #expect(result.scale == 4.0)
    }
    
    @Test("handleZoom fires haptic when snapping to default")
    func zoomFiresHapticOnSnap() {
        let input = ZoomGestureInput(
            magnification: 0.95,  // Just below 1.0
            baseScale: 1.0,
            minScale: 1.0,
            maxScale: 4.0
        )
        
        let result = service.handleZoom(input)
        
        #expect(result.snappedToDefault == true)
        #expect(result.scale == 1.0)
        
        if case .zoomSnap = mockHaptic.firedEvents.first {
            // Success
        } else {
            Issue.record("Expected zoomSnap event")
        }
    }
    
    // MARK: - Pan Tests
    
    @Test("handlePan bounds to viewport")
    func panBoundsToViewport() {
        let input = PanGestureInput(
            translation: CGSize(width: 1000, height: 0),
            velocity: nil,
            baseOffset: .zero,
            zoomScale: 2.0,
            contentSize: CGSize(width: 500, height: 100),
            viewportSize: CGSize(width: 400, height: 100)
        )
        
        let result = service.handlePan(input)
        
        // At 2× zoom: content is 1000pt, viewport is 400pt
        // Max pan = (1000 - 400) / 2 = 300pt
        #expect(result.offset.width == 300)
    }
    
    @Test("handlePan fires haptic for new boundary only")
    func panFiresHapticForNewBoundary() {
        let input = PanGestureInput(
            translation: CGSize(width: 1000, height: 0),
            velocity: nil,
            baseOffset: .zero,
            zoomScale: 2.0,
            contentSize: CGSize(width: 500, height: 100),
            viewportSize: CGSize(width: 400, height: 100)
        )
        
        // First call
        _ = service.handlePan(input)
        #expect(mockHaptic.firedEvents.count == 1)
        
        // Second call with same boundary - no new haptic
        _ = service.handlePan(input)
        #expect(mockHaptic.firedEvents.count == 1)
    }
}

// MARK: - Mock GestureService Tests

@Suite("MockGestureService Tests")
@MainActor
struct MockGestureServiceTests {
    
    @Test("Mock tracks slide calls")
    func mockTracksSlideCall() {
        let mock = MockGestureService()
        
        let input = SlideGestureInput(
            translation: CGSize(width: 100, height: 0),
            velocity: nil,
            baseOffset: 0,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        _ = mock.handleSlide(input)
        
        #expect(mock.slideCallCount == 1)
        #expect(mock.lastSlideInput?.translation.width == 100)
    }
    
    @Test("Mock returns stubbed result")
    func mockReturnsStubbedResult() {
        let mock = MockGestureService()
        
        mock.stubbedSlideResult = SlideGestureResult(
            offset: 999,
            isBounded: true,
            boundaryEdge: .trailing,
            momentum: nil
        )
        
        let input = SlideGestureInput(
            translation: CGSize(width: 1, height: 0),
            velocity: nil,
            baseOffset: 0,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        
        let result = mock.handleSlide(input)
        
        #expect(result.offset == 999)
        #expect(result.isBounded == true)
    }
    
    @Test("Mock reset clears all state")
    func mockResetClearsState() {
        let mock = MockGestureService()
        
        let slideInput = SlideGestureInput(
            translation: CGSize(width: 100, height: 0),
            velocity: nil,
            baseOffset: 0,
            scaleWidth: 500,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        _ = mock.handleSlide(slideInput)
        
        let cursorInput = CursorGestureInput(
            translation: CGSize(width: 50, height: 0),
            velocity: nil,
            basePosition: 0.5,
            viewWidth: 400,
            isPrecisionMode: false,
            precisionFactor: 5.0
        )
        _ = mock.handleCursor(cursorInput)
        
        mock.reset()
        
        #expect(mock.totalCallCount == 0)
        #expect(mock.stubbedSlideResult == nil)
    }
}
