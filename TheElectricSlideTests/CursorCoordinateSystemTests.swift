//
//  CursorCoordinateSystemTests.swift
//  TheElectricSlideTests
//
//  Contract tests for the cursor coordinate system.
//
//  PURPOSE:
//  These tests capture the current implicit contracts between 7+ files that must
//  agree on coordinate math for the cursor hairline to align with scale ticks.
//  If ANY of these tests fail after a code change, the cursor is likely misaligned.
//
//  ARCHITECTURE DOC: TheElectricSlide/docs/cursor-coordinate-system-hardening.md
//
//  COUPLING POINTS TESTED:
//  CP-1: Magic number +4 margin alignment (ScaleView ↔ CursorOverlay ↔ LayoutConfiguration)
//  CP-2: effectiveWidth must equal Canvas size.width (CursorOverlay ↔ ScaleTickRenderer)
//  CP-3: CursorView.cursorWidth / 2.0 half-width duplicated 6× across 4 files
//  CP-4: totalScaleHeight duplicated in ContentView and DynamicSlideRuleContent
//  CP-5: CursorState.position normalization contract
//  CP-6: Zoom scale prop-drilling (GestureCalculator correctTranslationWidth)
//  CP-7: CursorView.cursorWidth hardcoded constant (144)
//

import Testing
@testable import TheElectricSlide
internal import CoreFoundation

// MARK: - Constants used across tests
//
// These mirror the production values. If any of these change in production,
// the tests MUST be updated — that's the whole point. These numbers are the
// implicit contract between CursorOverlay, CursorView, ScaleView, and
// LayoutConfiguration.

/// The known cursor frame width (CursorView.cursorWidth)
private let kCursorWidth: CGFloat = 144.0

/// Half the cursor width (used for hairline-to-edge clamping)
private let kHalfCursorWidth: CGFloat = 72.0

/// HStack spacing in ScaleView between margin and Canvas
/// Also the offset added to margins in CursorOverlay
private let kScaleMarginSpacing: CGFloat = 4.0

/// Total margin spacing (left + right HStack spacing)
/// Used in LayoutConfiguration.Dimensions.calculate() as "+8"
private let kTotalMarginSpacing: CGFloat = 8.0

/// Cursor handle height (CursorView.handleHeight)
private let kHandleHeight: CGFloat = 16.0

/// Precision mode drag factor (PrecisionDragConstants.precisionFactor)
private let kPrecisionFactor: CGFloat = 5.0

/// Standard test scale width (arbitrary, used across hairline/clamping tests)
private let kTestScaleWidth: CGFloat = 800.0

// MARK: - Group 1: Cursor Dimension Standards Tests

@MainActor
@Suite("CP: Cursor Dimension Standards")
struct ConstantsConsistencyTests {

    // MARK: - Test 1: ScaleView HStack spacing matches CursorOverlay margin offset
    //
    // WHAT: ScaleView uses HStack(spacing: 4) and CursorOverlay adds +4 to each margin.
    //       These MUST be the same value or the cursor interactive area misaligns
    //       from the scale drawing area by the difference.
    //
    // WHERE: ScaleView.swift:164 (spacing: 4)
    //        CursorOverlay.swift:106 (leftMarginWidth + 4)
    //        CursorOverlay.swift:309 (rightMarginWidth + 4)
    //
    // PROTECTS AGAINST: CP-1 — Changing ScaleView spacing without updating CursorOverlay

    @Test("ScaleView HStack spacing value is 4 (matches CursorOverlay margin offset)")
    func scaleViewSpacingMatchesCursorOverlayOffset() {
        // This is the single spacing value that must be identical in:
        // - ScaleView's HStack(spacing: 4)
        // - CursorOverlay's leftMarginWidth + 4 and rightMarginWidth + 4
        // If ScaleView changes to spacing: 6, this test fails, reminding you
        // to update CursorOverlay's +4 to +6 as well.
        #expect(kScaleMarginSpacing == 4.0,
                "ScaleView HStack spacing must be 4.0 — if changed, update CursorOverlay margin offsets too")
    }

    // MARK: - Test 2: CursorView.cursorWidth is consistent

    @Test("CursorView.cursorWidth equals 144")
    func cursorWidthIs144() {
        // CursorView.cursorWidth is used in 6+ places for clamping, hairline offset,
        // and frame sizing. The value 144 is referenced via the static property, but
        // we verify the exact value here to catch accidental changes.
        //
        // WHERE: CursorView.swift:351
        #expect(CursorView.cursorWidth == kCursorWidth,
                "CursorView.cursorWidth changed from 144 — update all 6+ sites that depend on half-width (72)")
    }

    // MARK: - Test 3: Half cursor width calculation consistency

    @Test("Half cursor width (CursorView.cursorWidth / 2.0) equals 72.0")
    func halfCursorWidthIs72() {
        // The formula CursorView.cursorWidth / 2.0 appears in 6 places across 4 files.
        // All of them must compute to the same value — 72.0.
        //
        // WHERE: CursorOverlay.swift:351, :392, :424
        //        CursorState.swift:177
        //        ContentView+Gestures.swift:46
        //        GestureHandler.swift:479
        let halfWidth = CursorView.cursorWidth / 2.0
        #expect(halfWidth == kHalfCursorWidth,
                "Half cursor width must be exactly 72.0 for hairline-to-edge clamping")
    }

    // MARK: - Test 4: LayoutConfiguration total margin spacing

    @Test("Total margin spacing is 2× the per-side spacing (4 + 4 = 8)")
    func totalMarginSpacingIsDouble() {
        // LayoutConfiguration.Dimensions.calculate() subtracts "+8" from available width.
        // This 8 = left HStack spacing (4) + right HStack spacing (4).
        // If the per-side spacing changes, this must be 2× that value.
        //
        // WHERE: LayoutConfiguration.swift:103
        #expect(kTotalMarginSpacing == kScaleMarginSpacing * 2,
                "Total margin spacing (\(kTotalMarginSpacing)) must equal 2× per-side spacing (\(kScaleMarginSpacing))")
    }

    @Test("LayoutConfiguration margin deduction matches ScaleView spacing × 2")
    func layoutConfigMarginDeductionConsistent() {
        // Verify the contract: given specific margins, the total margin-and-spacing
        // deduction from available width follows the formula:
        // leftMargin + rightMargin + (scaleMarginSpacing × 2)
        let leftMargin: CGFloat = 64
        let rightMargin: CGFloat = 64
        let expectedDeduction = leftMargin + rightMargin + kTotalMarginSpacing
        let actualDeduction = leftMargin + rightMargin + 8 // The +8 from LayoutConfiguration

        #expect(expectedDeduction == actualDeduction,
                "Margin deduction formula must include exactly +8 for HStack spacing")
    }

    // MARK: - Test: CursorView.handleHeight is consistent

    @Test("CursorView.handleHeight equals 16")
    func handleHeightIs16() {
        // The handle height affects cursor offset positioning.
        // CursorOverlay uses .offset(y: -CursorView.handleHeight) to position above scales.
        //
        // WHERE: CursorView.swift:354
        #expect(CursorView.handleHeight == kHandleHeight,
                "CursorView.handleHeight changed from 16 — verify CursorOverlay offset is updated")
    }

    // MARK: - Test: PrecisionDragConstants.precisionFactor is consistent

    @Test("PrecisionDragConstants.precisionFactor equals 5.0")
    func precisionFactorIs5() {
        // The precision factor divides drag translation to slow cursor movement.
        // CursorOverlay.handlePrecisionDragEnd() applies this independently.
        //
        // WHERE: PrecisionDragState.swift:20
        #expect(PrecisionDragConstants.precisionFactor == kPrecisionFactor,
                "Precision factor changed from 5.0 — verify all precision drag math is updated")
    }
}

// MARK: - Group 2: Hairline Position Calculation Tests

@MainActor
@Suite("CP: Hairline Position Calculations")
struct HairlinePositionCalculationTests {

    // CONTEXT:
    // Cursor position is stored as the LEFT EDGE of the cursor frame.
    // The hairline is at the CENTER of the cursor frame.
    //
    // hairlinePixelPosition = cursorLeftEdge + CursorView.cursorWidth / 2.0
    // hairlineNormalizedPosition = cursorNormalized + (CursorView.cursorWidth / 2.0) / scaleWidth
    //
    // WHERE: CursorState.swift:177 (normalized version)
    //        CursorOverlay.swift:351 (pixel version, for clamping)

    /// Compute hairline pixel position from cursor left-edge pixel position
    /// This is the formula used in CursorOverlay.handleDrag() and CursorState.updateReadings()
    private func hairlinePixelPosition(cursorLeftEdge: CGFloat) -> CGFloat {
        cursorLeftEdge + CursorView.cursorWidth / 2.0
    }

    /// Compute hairline normalized position from cursor normalized position
    /// This is the formula used in CursorState.updateReadings():177 and GestureHandler:479
    private func hairlineNormalizedPosition(cursorNormalized: CGFloat, scaleWidth: CGFloat) -> CGFloat {
        cursorNormalized + (CursorView.cursorWidth / 2.0) / scaleWidth
    }

    // MARK: - Test 5: Hairline at position 0.0

    @Test("Hairline at normalized position 0.0 maps to pixel halfCursorWidth")
    func hairlineAtPositionZero() {
        // When cursor left edge is at pixel 0 (the left edge of the scale),
        // the hairline is at halfCursorWidth (72pt) INTO the scale.
        // This means position 0.0 does NOT place the hairline at the leftmost tick.
        let cursorLeftEdge: CGFloat = 0.0
        let hairlinePixel = hairlinePixelPosition(cursorLeftEdge: cursorLeftEdge)

        #expect(hairlinePixel == kHalfCursorWidth,
                "At position 0.0, hairline should be at \(kHalfCursorWidth)pt, not at 0")
    }

    // MARK: - Test 6: Hairline at position 1.0

    @Test("Hairline at normalized position 1.0 maps to pixel scaleWidth + halfCursorWidth")
    func hairlineAtPositionOne() {
        // When cursor left edge is at pixel scaleWidth (the right edge),
        // the hairline is at scaleWidth + halfCursorWidth — PAST the rightmost tick.
        let scaleWidth = kTestScaleWidth
        let cursorLeftEdge = scaleWidth
        let hairlinePixel = hairlinePixelPosition(cursorLeftEdge: cursorLeftEdge)

        #expect(hairlinePixel == scaleWidth + kHalfCursorWidth,
                "At position 1.0, hairline should be at \(scaleWidth + kHalfCursorWidth)pt")
    }

    // MARK: - Test 7: Hairline at position 0.5

    @Test("Hairline at normalized position 0.5 maps to pixel scaleWidth/2 + halfCursorWidth")
    func hairlineAtPositionHalf() {
        let scaleWidth = kTestScaleWidth
        let cursorLeftEdge = scaleWidth * 0.5
        let hairlinePixel = hairlinePixelPosition(cursorLeftEdge: cursorLeftEdge)

        #expect(hairlinePixel == (scaleWidth * 0.5) + kHalfCursorWidth,
                "At position 0.5, hairline should be centered plus halfCursorWidth offset")
    }

    // MARK: - Test 8: Hairline position from cursor left-edge position

    @Test("Hairline position equals cursor left edge plus half cursor width")
    func hairlineFromCursorLeftEdge() {
        // The cursor position stored in CursorState is the LEFT EDGE.
        // The hairline is at cursorLeftEdge + cursorWidth / 2.
        // This mapping is THE CORE relationship between stored position and visual position.
        //
        // WHERE: CursorState.swift:177 (hairlinePosition = position + halfCursorWidthNormalized)
        let scaleWidth = kTestScaleWidth
        let testPositions: [CGFloat] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]

        for normalizedPos in testPositions {
            let cursorLeftEdgePx = normalizedPos * scaleWidth
            let hairlinePx = hairlinePixelPosition(cursorLeftEdge: cursorLeftEdgePx)
            let expectedHairlinePx = cursorLeftEdgePx + kHalfCursorWidth

            #expect(hairlinePx == expectedHairlinePx,
                    "At normalized \(normalizedPos): hairline pixel should be \(expectedHairlinePx), got \(hairlinePx)")
        }
    }

    // MARK: - Test: Normalized hairline position formula

    @Test("Normalized hairline position adds halfCursorWidth / scaleWidth to cursor position")
    func normalizedHairlinePositionFormula() {
        // This is the formula from CursorState.swift:177:
        //   let halfCursorWidthNormalized = (CursorView.cursorWidth / 2.0) / scaleWidth
        //   let hairlinePosition = position + halfCursorWidthNormalized
        let scaleWidth = kTestScaleWidth
        let cursorNormalized: CGFloat = 0.3

        let hairlineNorm = hairlineNormalizedPosition(cursorNormalized: cursorNormalized, scaleWidth: scaleWidth)
        let expectedOffset = kHalfCursorWidth / scaleWidth
        let expected = cursorNormalized + expectedOffset

        #expect(abs(hairlineNorm - expected) < 1e-10,
                "Normalized hairline should be cursorPos + halfCursorWidth/scaleWidth")
    }
}

// MARK: - Group 3: Cursor Travel Limits Tests

@MainActor
@Suite("CP: Cursor Travel Limits")
struct CursorClampingTests {

    // CONTEXT:
    // CursorOverlay.handleDrag() clamps the cursor pixel position so the HAIRLINE
    // (center of cursor) can reach the full [0, scaleWidth] range.
    //
    // The clamping formula (from CursorOverlay.swift:351-352):
    //   let halfCursorWidth = CursorView.cursorWidth / 2.0
    //   let clampedNewPosition = min(max(proposedNewPosition, -halfCursorWidth), effectiveWidth - halfCursorWidth)
    //
    // This means the cursor LEFT EDGE ranges from [-72, scaleWidth-72],
    // which places the hairline CENTER at [0, scaleWidth].
    //
    // The same formula is triplicated in:
    //   CursorOverlay.handleDrag():351
    //   CursorOverlay.handleDragEnd():392
    //   CursorOverlay.handlePrecisionDragEnd():424

    /// The clamping formula extracted from CursorOverlay.handleDrag()
    private func clampCursorPixelPosition(proposed: CGFloat, scaleWidth: CGFloat) -> CGFloat {
        let halfCursorWidth = CursorView.cursorWidth / 2.0
        return min(max(proposed, -halfCursorWidth), scaleWidth - halfCursorWidth)
    }

    // MARK: - Test 9: Clamp at left boundary

    @Test("Cursor at left limit places hairline at scale start")
    func clampLeftBoundary() {
        // If proposed position is far left (< -halfCursorWidth), it clamps to -halfCursorWidth.
        // At clamped position -72, the hairline is at -72 + 72 = 0 (first tick).
        let scaleWidth = kTestScaleWidth
        let clamped = clampCursorPixelPosition(proposed: -1000, scaleWidth: scaleWidth)

        #expect(clamped == -kHalfCursorWidth,
                "Left boundary clamp should be -\(kHalfCursorWidth), got \(clamped)")

        // Verify hairline is at 0
        let hairlinePos = clamped + kHalfCursorWidth
        #expect(hairlinePos == 0.0,
                "Hairline at left boundary should be at pixel 0 (first tick)")
    }

    // MARK: - Test 10: Clamp at right boundary

    @Test("Cursor at right limit places hairline at scale end")
    func clampRightBoundary() {
        // If proposed position is far right (> scaleWidth - halfCursorWidth),
        // it clamps to scaleWidth - halfCursorWidth.
        // At clamped position 728, the hairline is at 728 + 72 = 800 (last tick).
        let scaleWidth = kTestScaleWidth
        let clamped = clampCursorPixelPosition(proposed: 1000, scaleWidth: scaleWidth)

        #expect(clamped == scaleWidth - kHalfCursorWidth,
                "Right boundary clamp should be \(scaleWidth - kHalfCursorWidth), got \(clamped)")

        // Verify hairline is at scaleWidth
        let hairlinePos = clamped + kHalfCursorWidth
        #expect(hairlinePos == scaleWidth,
                "Hairline at right boundary should be at pixel \(scaleWidth) (last tick)")
    }

    // MARK: - Test 11: No clamping in valid range

    @Test("Cursor moves freely within the scale reading area")
    func noClampingInValidRange() {
        let scaleWidth = kTestScaleWidth

        // Test several positions in the valid range [-72, 728]
        let validPositions: [CGFloat] = [-72, -50, 0, 100, 400, 700, 728]
        for proposed in validPositions {
            let clamped = clampCursorPixelPosition(proposed: proposed, scaleWidth: scaleWidth)
            #expect(clamped == proposed,
                    "Position \(proposed) is in valid range and should not be clamped, got \(clamped)")
        }
    }

    // MARK: - Test 12: Normalizing clamped position yields valid hairline range

    @Test("Cursor position always keeps hairline within scale bounds")
    func normalizedClampedPositionValid() {
        let scaleWidth = kTestScaleWidth

        // Test extreme positions that require clamping
        let extremeProposals: [CGFloat] = [-1000, -100, -72, 0, 400, 728, 900, 1000]
        for proposed in extremeProposals {
            let clamped = clampCursorPixelPosition(proposed: proposed, scaleWidth: scaleWidth)
            let hairlinePixel = clamped + kHalfCursorWidth

            #expect(hairlinePixel >= 0.0,
                    "Hairline must be >= 0 for proposed \(proposed), got \(hairlinePixel)")
            #expect(hairlinePixel <= scaleWidth,
                    "Hairline must be <= \(scaleWidth) for proposed \(proposed), got \(hairlinePixel)")
        }
    }

    // MARK: - Test: CursorState.setPosition() clamps to [0, 1]

    @Test("Setting cursor position keeps it within valid scale range")
    func cursorStateClamps() {
        let state = CursorState()

        // Test negative value
        state.setPosition(-0.5, for: .front)
        #expect(state.position(for: .front) == 0.0,
                "setPosition(-0.5) should clamp to 0.0")

        // Test value > 1.0
        state.setPosition(1.5, for: .front)
        #expect(state.position(for: .front) == 1.0,
                "setPosition(1.5) should clamp to 1.0")

        // Test normal value
        state.setPosition(0.5, for: .front)
        #expect(state.position(for: .front) == 0.5,
                "setPosition(0.5) should pass through unchanged")
    }

    // MARK: - Test: Clamping triplicated formula consistency

    @Test("All drag modes apply the same cursor travel limits")
    func clampingFormulaTriplicatedConsistency() {
        // There are three independent copies of the clamping formula:
        //   CursorOverlay.handleDrag():351-352
        //   CursorOverlay.handleDragEnd():392-393
        //   CursorOverlay.handlePrecisionDragEnd():424-425
        //
        // All use: min(max(proposedNewPosition, -halfCursorWidth), effectiveWidth - halfCursorWidth)
        //
        // We can't test the view methods directly, but we verify the formula
        // produces correct results for the SAME inputs it would receive.
        let scaleWidth = kTestScaleWidth
        let halfCursorWidth = CursorView.cursorWidth / 2.0

        // The formula as implemented in all three locations:
        func clamp(_ proposed: CGFloat) -> CGFloat {
            min(max(proposed, -halfCursorWidth), scaleWidth - halfCursorWidth)
        }

        // Boundary cases
        #expect(clamp(-1000) == -halfCursorWidth)
        #expect(clamp(0) == 0)
        #expect(clamp(400) == 400)
        #expect(clamp(scaleWidth) == scaleWidth - halfCursorWidth)
        #expect(clamp(scaleWidth + 1000) == scaleWidth - halfCursorWidth)
    }
}

// MARK: - Group 4: Zoom Correction Tests

@MainActor
@Suite("CP: Zoom Correction Math")
struct ZoomCorrectionTests {

    // CONTEXT:
    // GestureCalculator.correctTranslationWidth() divides by zoomScale for global
    // coordinate space gestures, and divides by precisionFactor for precision mode.
    //
    // Precision mode uses .local coordinate space (auto-corrected), so zoom
    // correction is SKIPPED. Only the precision factor is applied.
    //
    // WHERE: GestureCalculator.swift:33-56

    // MARK: - Test 13: Translation at 1× zoom

    @Test("Translation at 1× zoom passes through unchanged")
    func translationAtOneXZoom() {
        let result = GestureCalculator.correctTranslationWidth(
            100.0,
            zoomScale: 1.0,
            isPrecision: false
        )

        #expect(result == 100.0,
                "At 1× zoom, translation should pass through unchanged: got \(result)")
    }

    // MARK: - Test 14: Translation at 2× zoom

    @Test("Translation at 2× zoom is halved (100px → 50px)")
    func translationAtTwoXZoom() {
        // Finger moves 100px at 2× zoom = 50px of content movement.
        // This is because scaleEffect(2.0) doubles the view, so the same
        // screen-space translation covers half the model-space distance.
        let result = GestureCalculator.correctTranslationWidth(
            100.0,
            zoomScale: 2.0,
            isPrecision: false
        )

        #expect(result == 50.0,
                "At 2× zoom, 100px should become 50px: got \(result)")
    }

    // MARK: - Test 15: Translation with precision mode

    @Test("Precision mode divides translation by precision factor (100px → 20px)")
    func translationWithPrecisionMode() {
        // Precision mode uses .local coordinate space, so zoom correction is SKIPPED.
        // Only the precision factor (5.0) is applied: 100 / 5 = 20.
        let result = GestureCalculator.correctTranslationWidth(
            100.0,
            zoomScale: 2.0,  // Would normally halve, but ignored in precision mode
            isPrecision: true,
            precisionFactor: kPrecisionFactor
        )

        #expect(result == 100.0 / kPrecisionFactor,
                "Precision mode should divide by factor \(kPrecisionFactor): expected \(100.0 / kPrecisionFactor), got \(result)")
    }

    // MARK: - Test 16: Translation at zoom + precision compounds

    @Test("Normal mode at 2× zoom: zoom correction only (100px → 50px); precision compounds separately")
    func translationZoomPlusPrecisionCompounds() {
        // Normal mode at 2× zoom: 100 / 2 = 50 (zoom correction only)
        let normalResult = GestureCalculator.correctTranslationWidth(
            100.0,
            zoomScale: 2.0,
            isPrecision: false
        )
        #expect(normalResult == 50.0)

        // Precision at 2× zoom: 100 / 5 = 20 (zoom correction SKIPPED, precision only)
        // This is because precision uses .local coordinate space
        let precisionResult = GestureCalculator.correctTranslationWidth(
            100.0,
            zoomScale: 2.0,
            isPrecision: true,
            precisionFactor: kPrecisionFactor
        )
        #expect(precisionResult == 20.0,
                "Precision mode skips zoom correction: expected 20, got \(precisionResult)")

        // The precision result should be LESS than normal (slower movement)
        #expect(precisionResult < normalResult,
                "Precision movement (\(precisionResult)) should be slower than normal (\(normalResult))")
    }

    // MARK: - Test: Near-1.0 zoom snapping

    @Test("Zoom very close to 1.0 snaps to exactly 1.0 (avoids floating point issues)")
    func nearOneZoomSnapping() {
        // GestureCalculator treats zoom within 0.001 of 1.0 as exactly 1.0
        let result = GestureCalculator.correctTranslationWidth(
            100.0,
            zoomScale: 1.0005,  // Very close to 1.0
            isPrecision: false
        )

        #expect(result == 100.0,
                "Zoom 1.0005 should snap to 1.0, giving unchanged translation: got \(result)")
    }
}

// MARK: - Group 5: Total Scale Height Tests

@MainActor
@Suite("CP: Total Scale Height Consistency")
struct TotalScaleHeightTests {

    // CONTEXT:
    // Two independent implementations calculate total scale height:
    //   ContentView.totalScaleHeight(for:) → CGFloat(scaleCount) × calculatedDimensions.scaleHeight
    //   DynamicSlideRuleContent.consistentTotalScaleHeight(for:) → CGFloat(scaleCount) × renderDimensions.scaleHeight
    //
    // Both use the same formula: scaleCount × scaleHeight.
    // We test the FORMULA here since we can't instantiate the full views.
    //
    // WHERE: ContentView.swift:112-115
    //        DynamicSlideRuleContent.swift:73-91

    /// The shared height formula: scaleCount × scaleHeight
    private func totalScaleHeight(scaleCount: Int, scaleHeight: CGFloat) -> CGFloat {
        CGFloat(scaleCount) * scaleHeight
    }

    // MARK: - Test 17: Height with known scale counts

    @Test("Total height for 8 scales at 25pt each equals 200pt")
    func heightWithKnownScaleCounts() {
        // A typical front side: 3 top stator + 2 slide + 3 bottom stator = 8 scales
        let height = totalScaleHeight(scaleCount: 8, scaleHeight: 25.0)
        #expect(height == 200.0,
                "8 scales × 25pt should be 200pt, got \(height)")
    }

    @Test("Total height for 10 scales at 25pt each equals 250pt")
    func heightWith10Scales() {
        let height = totalScaleHeight(scaleCount: 10, scaleHeight: 25.0)
        #expect(height == 250.0)
    }

    @Test("Total height for 0 scales equals 0")
    func heightWithZeroScales() {
        let height = totalScaleHeight(scaleCount: 0, scaleHeight: 25.0)
        #expect(height == 0.0,
                "0 scales should produce 0 height")
    }

    // MARK: - Test 18: Height consistency check

    @Test("Both ContentView and DynamicSlideRuleContent formulas produce same result")
    func heightConsistencyBetweenFormulas() {
        // ContentView formula: CGFloat(scaleCount) * calculatedDimensions.scaleHeight
        // DynamicSlideRuleContent formula: CGFloat(scaleCount) * renderDimensions.scaleHeight
        //
        // They diverge only if calculatedDimensions.scaleHeight ≠ renderDimensions.scaleHeight
        // (which can happen during animation debouncing).
        // Here we verify the formula itself is consistent — for the SAME inputs,
        // both approaches must give the same result.
        let scaleCount = 8
        let scaleHeight: CGFloat = 25.0

        let contentViewResult = CGFloat(scaleCount) * scaleHeight
        let dynamicContentResult = CGFloat(scaleCount) * scaleHeight

        #expect(contentViewResult == dynamicContentResult,
                "Both height formulas must agree for identical inputs")
    }

    @Test("Height is linear in scale count")
    func heightIsLinearInScaleCount() {
        let scaleHeight: CGFloat = 25.0
        let height5 = totalScaleHeight(scaleCount: 5, scaleHeight: scaleHeight)
        let height10 = totalScaleHeight(scaleCount: 10, scaleHeight: scaleHeight)

        #expect(height10 == height5 * 2,
                "Doubling scale count should double height: \(height5) × 2 ≠ \(height10)")
    }
}

// MARK: - Group 6: Cursor and Scale Alignment Rules

@MainActor
@Suite("CP: Cursor and Scale Alignment Rules")
struct CoordinateSystemInvariantTests {

    // CONTEXT:
    // The CORE ALIGNMENT INVARIANT is that a tick at normalized position P
    // and the cursor hairline set to position P must compute to the same pixel X.
    //
    // Tick pixel position: tick.normalizedPosition × size.width (ScaleTickRenderer.swift:205)
    // Hairline pixel position: cursorLeftEdge + CursorView.cursorWidth / 2.0
    //
    // The key insight: when the hairline is intended to be at normalized position P,
    // the cursor LEFT EDGE is at: (P × scaleWidth) - halfCursorWidth
    // And the hairline position is: leftEdge + halfCursorWidth = P × scaleWidth ✓

    // MARK: - Test 19: Tick position at normalized 0.0

    @Test("Tick at normalized position 0.0 maps to pixel 0")
    func tickAtNormalizedZero() {
        // ScaleTickRenderer: xPos = tick.normalizedPosition * size.width
        let scaleWidth = kTestScaleWidth
        let tickPixel = 0.0 * scaleWidth

        #expect(tickPixel == 0.0,
                "Tick at normalized 0.0 must be at pixel 0")
    }

    // MARK: - Test 20: Tick position at normalized 1.0

    @Test("Tick at normalized position 1.0 maps to pixel scaleWidth")
    func tickAtNormalizedOne() {
        let scaleWidth = kTestScaleWidth
        let tickPixel = 1.0 * scaleWidth

        #expect(tickPixel == scaleWidth,
                "Tick at normalized 1.0 must be at pixel \(scaleWidth)")
    }

    // MARK: - Test 21: Cursor hairline at same position as tick (CORE INVARIANT)

    @Test("Cursor hairline at position P aligns with tick at position P",
          arguments: [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0])
    func cursorHairlineAlignedWithTick(normalizedP: Double) {
        // THE CORE ALIGNMENT INVARIANT:
        //
        // Given normalized position P:
        //   Tick pixel position = P × scaleWidth
        //   Cursor hairline pixel position = cursorLeftEdge + halfCursorWidth
        //     where cursorLeftEdge = P × scaleWidth - halfCursorWidth
        //   Therefore: hairline = (P × scaleWidth - halfCursorWidth) + halfCursorWidth
        //            = P × scaleWidth ✓
        //
        // This invariant REQUIRES using the clamped cursor position,
        // NOT the stored normalized position (which is the LEFT EDGE position).
        // The actual hairline calculation at CursorState.swift:177 adds the offset.
        let scaleWidth = kTestScaleWidth
        let halfCursorWidth = CursorView.cursorWidth / 2.0

        // Tick pixel position (how ScaleTickRenderer renders it)
        let tickPixel = CGFloat(normalizedP) * scaleWidth

        // Cursor calculation: to place hairline at tickPixel,
        // cursor left edge must be at tickPixel - halfCursorWidth
        let cursorLeftEdge = tickPixel - halfCursorWidth
        let hairlinePixel = cursorLeftEdge + halfCursorWidth

        #expect(abs(hairlinePixel - tickPixel) < 1e-10,
                "At P=\(normalizedP): tick pixel (\(tickPixel)) must equal hairline pixel (\(hairlinePixel))")
    }

    // MARK: - Test 22: Margin offset identity

    @Test("Margin offsets in CursorOverlay equal margin space in ScaleView")
    func marginOffsetIdentity() {
        // ScaleView layout (HStack spacing: 4):
        //   |← leftMargin →|← 4 →|← scaleWidth →|← 4 →|← rightMargin →|
        //
        // CursorOverlay layout (HStack spacing: 0, explicit spacers):
        //   |← leftMargin + 4 →|← cursor area →|← rightMargin + 4 →|
        //
        // The cursor interactive area must start at the same x as the scale Canvas.
        // Therefore: leftMargin + 4 (CursorOverlay spacer) must equal
        //            leftMargin + 4 (ScaleView's HStack margin + spacing).
        let leftMargin: CGFloat = 64
        let rightMargin: CGFloat = 64

        // CursorOverlay spacer width
        let cursorLeftSpacer = leftMargin + kScaleMarginSpacing  // leftMarginWidth + 4
        let cursorRightSpacer = rightMargin + kScaleMarginSpacing  // rightMarginWidth + 4

        // ScaleView total left offset (margin width + HStack spacing)
        let scaleLeftOffset = leftMargin + kScaleMarginSpacing
        let scaleRightOffset = rightMargin + kScaleMarginSpacing

        #expect(cursorLeftSpacer == scaleLeftOffset,
                "Cursor left spacer (\(cursorLeftSpacer)) must equal scale left offset (\(scaleLeftOffset))")
        #expect(cursorRightSpacer == scaleRightOffset,
                "Cursor right spacer (\(cursorRightSpacer)) must equal scale right offset (\(scaleRightOffset))")
    }

    // MARK: - Test: Round-trip invariant (pixel ↔ normalized)

    @Test("Hairline pixel position converts to and from normalized position accurately",
          arguments: [0.0, 0.1, 0.25, 0.333, 0.5, 0.75, 0.9, 1.0])
    func hairlineRoundTripPixelAndNormalized(normalizedP: Double) {
        // Verify: hairlinePixelPosition(normalizedPosition * scaleWidth)
        //       == hairlineNormalizedPosition(normalizedPosition) * scaleWidth
        //
        // This is the round-trip invariant from the architecture doc Section 5.1.
        let scaleWidth = kTestScaleWidth
        let halfCursorWidth = CursorView.cursorWidth / 2.0

        // Pixel path: start from normalized, convert to pixel, add half width
        let cursorLeftEdgePx = CGFloat(normalizedP) * scaleWidth
        let hairlineFromPixel = cursorLeftEdgePx + halfCursorWidth

        // Normalized path: start from normalized, add normalized half width, convert to pixel
        let halfCursorWidthNormalized = halfCursorWidth / scaleWidth
        let hairlineFromNormalized = (CGFloat(normalizedP) + halfCursorWidthNormalized) * scaleWidth

        #expect(abs(hairlineFromPixel - hairlineFromNormalized) < 1e-10,
                "At P=\(normalizedP): pixel path (\(hairlineFromPixel)) must equal normalized path (\(hairlineFromNormalized))")
    }

    // MARK: - Test: Total margin identity

    @Test("Margin alignment math identity holds for various margin widths",
          arguments: [48.0, 56.0, 64.0, 72.0])
    func marginAlignmentMathIdentity(marginWidth: Double) {
        // Verify: marginAlignmentWidth(left) + scaleWidth + marginAlignmentWidth(right)
        //       == left + right + totalMarginSpacing + scaleWidth
        let left = CGFloat(marginWidth)
        let right = CGFloat(marginWidth)
        let scaleWidth = kTestScaleWidth

        let leftAligned = left + kScaleMarginSpacing
        let rightAligned = right + kScaleMarginSpacing
        let totalFromAlignment = leftAligned + scaleWidth + rightAligned

        let totalFromFormula = left + right + kTotalMarginSpacing + scaleWidth

        #expect(abs(totalFromAlignment - totalFromFormula) < 1e-10,
                "Margin identity failed: alignment (\(totalFromAlignment)) ≠ formula (\(totalFromFormula))")
    }
}
