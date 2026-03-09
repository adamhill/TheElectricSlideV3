//
//  GestureCalculatorTests.swift
//  TheElectricSlideTests
//
//  Comprehensive unit tests for gesture calculation functions.
//  Uses Swift Testing framework for modern, expressive test syntax.
//

import Testing
@testable import TheElectricSlide
internal import CoreFoundation

@MainActor
@Suite("Slide Rule Gesture Calculations")
struct GestureCalculatorTests {
    
    // MARK: - Translation Correction Tests
    
    @Test("Normal gesture at 1× zoom has no correction")
    func normalGestureAtDefaultZoom() {
        let result = GestureCalculator.correctTranslation(
            CGSize(width: 100, height: 50),
            zoomScale: 1.0,
            isPrecision: false
        )
        
        #expect(result.width == 100)
        #expect(result.height == 50)
    }
    
    @Test("Normal gesture at 2× zoom is halved")
    func normalGestureAtTwoXZoom() {
        let result = GestureCalculator.correctTranslation(
            CGSize(width: 100, height: 50),
            zoomScale: 2.0,
            isPrecision: false
        )
        
        #expect(result.width == 50)
        #expect(result.height == 25)
    }
    
    @Test("Precision gesture skips zoom correction but applies precision factor")
    func precisionGestureSkipsZoomCorrection() {
        let result = GestureCalculator.correctTranslation(
            CGSize(width: 100, height: 50),
            zoomScale: 2.0,  // Would normally halve the translation
            isPrecision: true,
            precisionFactor: 5.0
        )
        
        // Precision mode: skip zoom correction, apply precision factor
        // 100 / 5.0 = 20
        #expect(result.width == 20)
        #expect(result.height == 10)
    }
    
    @Test("Width-only translation correction matches full correction")
    func correctTranslationWidthConvenience() {
        let result = GestureCalculator.correctTranslationWidth(
            100,
            zoomScale: 2.0,
            isPrecision: false
        )
        
        #expect(result == 50)
    }
    
    // MARK: - Slide Offset Tests
    
    @Test("Slide stops at the right end of the scale")
    func slideOffsetClampsTrailing() {
        let result = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 1000, height: 0),
            baseOffset: 0,
            scaleWidth: 500
        )
        
        #expect(result.offset == 500)
        #expect(result.isBounded == true)
        #expect(result.boundaryEdge == .trailing)
    }
    
    @Test("Slide stops at the left end of the scale")
    func slideOffsetClampsLeading() {
        let result = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: -1000, height: 0),
            baseOffset: 0,
            scaleWidth: 500
        )
        
        #expect(result.offset == -500)
        #expect(result.isBounded == true)
        #expect(result.boundaryEdge == .leading)
    }
    
    @Test("Slide offset within bounds")
    func slideOffsetWithinBounds() {
        let result = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 100, height: 0),
            baseOffset: 50,
            scaleWidth: 500
        )
        
        #expect(result.offset == 150)
        #expect(result.isBounded == false)
        #expect(result.boundaryEdge == nil)
    }
    
    @Test("Precision mode reduces translation by factor")
    func precisionModeReduction() {
        let normal = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 100, height: 0),
            baseOffset: 0,
            scaleWidth: 500,
            isPrecision: false
        )
        
        let precision = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 100, height: 0),
            baseOffset: 0,
            scaleWidth: 500,
            isPrecision: true,
            precisionFactor: 5.0
        )
        
        #expect(normal.offset == 100)
        #expect(precision.offset == 20)
    }
    
    @Test("Slide offset with zoom correction")
    func slideOffsetWithZoomCorrection() {
        // At 2× zoom, 200pt gesture becomes 100pt model-space translation
        let result = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 200, height: 0),
            baseOffset: 0,
            scaleWidth: 500,
            zoomScale: 2.0,
            isPrecision: false
        )
        
        #expect(result.offset == 100)  // 200 / 2.0 = 100
        #expect(result.isBounded == false)
    }
    
    @Test("Slide offset with combined zoom and precision")
    func slideOffsetZoomAndPrecision() {
        // In precision mode, zoom correction is skipped (local coordinate space)
        // but precision factor is applied
        let result = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 100, height: 0),
            baseOffset: 0,
            scaleWidth: 500,
            zoomScale: 2.0,
            isPrecision: true,
            precisionFactor: 5.0
        )
        
        // Precision mode: 100 / 5.0 = 20 (zoom correction skipped)
        #expect(result.offset == 20)
    }
    
    // MARK: - Cursor Position Tests
    
    @Test("Cursor stays within scale at the right edge")
    func cursorPositionNormalizes() {
        let result = GestureCalculator.calculateCursorPosition(
            translation: CGSize(width: 300, height: 0),  // 0.75 delta, exceeds 1.0
            basePosition: 0.5,
            viewWidth: 400
        )
        
        #expect(result.normalizedPosition == 1.0)  // Clamped to max
        #expect(result.isBounded == true)
        #expect(result.boundaryEdge == .trailing)
    }
    
    @Test("Cursor within bounds")
    func cursorWithinBounds() {
        let result = GestureCalculator.calculateCursorPosition(
            translation: CGSize(width: 40, height: 0),
            basePosition: 0.5,
            viewWidth: 400
        )
        
        #expect(result.normalizedPosition == 0.6)
        #expect(result.isBounded == false)
    }
    
    @Test("Cursor stays within scale at the left edge")
    func cursorClampsLower() {
        let result = GestureCalculator.calculateCursorPosition(
            translation: CGSize(width: -300, height: 0),
            basePosition: 0.5,
            viewWidth: 400
        )
        
        #expect(result.normalizedPosition == 0.0)
        #expect(result.isBounded == true)
        #expect(result.boundaryEdge == .leading)
    }
    
    @Test("Cursor position with zoom correction")
    func cursorPositionWithZoomCorrection() {
        // At 2× zoom, 80pt gesture becomes 40pt model-space translation
        // 40 / 400 = 0.1 delta, so 0.5 + 0.1 = 0.6
        let result = GestureCalculator.calculateCursorPosition(
            translation: CGSize(width: 80, height: 0),
            basePosition: 0.5,
            viewWidth: 400,
            zoomScale: 2.0,
            isPrecision: false
        )
        
        #expect(result.normalizedPosition == 0.6)
        #expect(result.isBounded == false)
    }
    
    // MARK: - Momentum Tests
    
    @Test("Momentum calculation produces sensible values")
    func momentumCalculation() {
        let result = GestureCalculator.calculateMomentum(
            velocity: CGSize(width: 500, height: 0),
            axis: .horizontal
        )
        
        #expect(result.finalOffset > 0)
        #expect(result.duration > 0)
        #expect(result.duration <= 2.0)
    }
    
    @Test("Low velocity produces short duration")
    func lowVelocityShortDuration() {
        let result = GestureCalculator.calculateMomentum(
            velocity: CGSize(width: 30, height: 0),
            axis: .horizontal
        )
        
        #expect(result.duration == 0.3)
    }
    
    // MARK: - Pan Bounds Tests
    
    @Test("Pan bounds respect zoom level")
    func panBoundsZoomAware() {
        let result = GestureCalculator.calculateBoundedPan(
            offset: CGSize(width: 500, height: 0),
            zoomScale: 2.0,
            contentSize: CGSize(width: 500, height: 100),
            viewportSize: CGSize(width: 400, height: 100)
        )
        
        // At 2× zoom, content is 1000pt, viewport is 400pt
        // Max pan = (1000 - 400) / 2 = 300pt
        #expect(result.offset.width == 300)
        #expect(result.boundedAxes.contains(.trailing))
    }
    
    @Test("Pan at 1x zoom has zero bounds")
    func panAtOneXZoom() {
        let result = GestureCalculator.calculateBoundedPan(
            offset: CGSize(width: 100, height: 0),
            zoomScale: 1.0,
            contentSize: CGSize(width: 400, height: 100),
            viewportSize: CGSize(width: 400, height: 100)
        )
        
        // At 1× zoom, content equals viewport, no pan allowed
        #expect(result.offset.width == 0)
        #expect(result.boundedAxes.contains(.trailing))
    }
    
    // MARK: - Zoom Tests
    
    @Test("Zoom level cannot exceed maximum magnification")
    func zoomClampsToMax() {
        let result = GestureCalculator.calculateZoom(
            magnification: 5.0,
            baseScale: 1.0,
            minScale: 1.0,
            maxScale: 4.0
        )
        
        #expect(result.scale == 4.0)
        #expect(result.snappedToDefault == false)
    }
    
    @Test("Zoom snaps to default when below threshold")
    func zoomSnapsToDefault() {
        let result = GestureCalculator.calculateZoom(
            magnification: 0.95,
            baseScale: 1.0,
            minScale: 1.0,
            maxScale: 4.0,
            snapThreshold: 0.1
        )
        
        #expect(result.scale == 1.0)
        #expect(result.snappedToDefault == true)
    }
    
    @Test("Zoom within range")
    func zoomWithinRange() {
        let result = GestureCalculator.calculateZoom(
            magnification: 2.0,
            baseScale: 1.0,
            minScale: 1.0,
            maxScale: 4.0
        )
        
        #expect(result.scale == 2.0)
        #expect(result.snappedToDefault == false)
    }
}
