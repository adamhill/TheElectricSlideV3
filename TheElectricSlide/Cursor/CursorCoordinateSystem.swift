//
//  CursorCoordinateSystem.swift
//  TheElectricSlide
//
//  Single source of truth for cursor coordinate math and layout constants.
//
//  COORDINATE CONTRACT:
//  ────────────────────
//  • **Cursor position (0.0…1.0)** is the normalized position of the cursor frame's
//    LEFT EDGE relative to the scale drawing area.
//  • **Position 0.0** = cursor left edge is at the left edge of the scale area.
//    The hairline is at +halfCursorWidth (72pt) from the left scale edge —
//    NOT at the leftmost tick.
//  • **Position 1.0** = cursor left edge is at the right edge of the scale area.
//    The hairline is past the rightmost tick by halfCursorWidth (72pt).
//  • **Hairline position** = cursorLeftEdge + halfCursorWidth.
//    This is the CENTER of the cursor frame, where the vertical red line is drawn.
//  • **Why the cursor frame extends past scale edges:**
//    To let the hairline reach x=0 and x=scaleWidth (the first and last ticks),
//    the cursor LEFT EDGE is clamped to [-halfCursorWidth, scaleWidth - halfCursorWidth].
//    This places the hairline at [0, scaleWidth].
//
//  COUPLING POINTS CENTRALIZED:
//  CP-1: scaleHStackSpacing (ScaleView ↔ CursorOverlay ↔ LayoutConfiguration)
//  CP-3: halfCursorWidth (6 sites across 4 files → one constant)
//  CP-4: totalScaleHeight formula (ContentView ↔ DynamicSlideRuleContent)
//  CP-7: cursorFrameWidth (CursorView.cursorWidth → shared constant)
//
//  ARCHITECTURE DOC: TheElectricSlide/docs/cursor-coordinate-system-hardening.md
//

import Foundation
import CoreGraphics

/// Centralized coordinate math and layout constants for cursor-to-scale alignment.
///
/// This is a pure-math namespace — no SwiftUI, no state, no side effects.
/// All functions are `static` and deterministic for hot-path gesture performance.
nonisolated enum CursorCoordinateSystem {

    // MARK: - Constants

    /// Width of the cursor frame in points (the glass rectangle the user drags).
    /// Derivation: chosen to allow readable scale name + value on each side of the hairline.
    static let cursorFrameWidth: CGFloat = 144

    /// Half the cursor frame width.  Used to convert between cursor left-edge
    /// position and hairline (center) position.
    static let halfCursorWidth: CGFloat = cursorFrameWidth / 2.0

    /// Height of the drag handle that sits above/below the slide rule frame.
    static let handleHeight: CGFloat = 16

    /// HStack spacing used by ``ScaleView`` between the margin spacer and the
    /// Canvas, on each side.  ``CursorOverlay`` adds this same value to its
    /// margin spacers so the cursor interactive area aligns with the scale area.
    static let scaleHStackSpacing: CGFloat = 4

    /// Total margin spacing deducted from available width in
    /// ``LayoutConfiguration.Dimensions.calculate()``.
    /// Equals `scaleHStackSpacing × 2` (left side + right side).
    static let totalMarginSpacing: CGFloat = scaleHStackSpacing * 2

    /// Precision mode drag factor — divides raw translation to slow cursor movement.
    /// Matches ``PrecisionDragConstants.precisionFactor``.
    static let precisionFactor: CGFloat = 5.0

    // MARK: - Pure Math Functions

    /// Convert a normalized cursor position to a pixel position for the cursor's **left edge**.
    ///
    /// - Parameters:
    ///   - normalizedPosition: Cursor position in `[0.0, 1.0]`.
    ///   - scaleWidth: Pixel width of the scale drawing area.
    /// - Returns: The cursor frame's left-edge pixel position.
    @inlinable
    static func cursorPixelPosition(normalizedPosition: CGFloat, scaleWidth: CGFloat) -> CGFloat {
        normalizedPosition * scaleWidth
    }

    /// Convert a cursor **left-edge** pixel position to the hairline **center** pixel position.
    ///
    /// `hairline = cursorLeftEdge + halfCursorWidth`
    ///
    /// - Parameter cursorLeftEdge: Pixel position of the cursor frame's left edge.
    /// - Returns: The hairline's pixel position (center of cursor frame).
    @inlinable
    static func hairlinePixelPosition(cursorLeftEdge: CGFloat) -> CGFloat {
        cursorLeftEdge + halfCursorWidth
    }

    /// Clamp a proposed cursor pixel position so the hairline stays within `[0, scaleWidth]`.
    ///
    /// The cursor left edge is allowed to range from `-halfCursorWidth` (hairline at 0)
    /// to `scaleWidth - halfCursorWidth` (hairline at scaleWidth).
    ///
    /// - Parameters:
    ///   - proposedPixelPosition: The unclamped left-edge pixel position.
    ///   - scaleWidth: Pixel width of the scale drawing area.
    /// - Returns: The clamped left-edge pixel position.
    @inlinable
    static func clampCursorPosition(proposedPixelPosition: CGFloat, scaleWidth: CGFloat) -> CGFloat {
        min(max(proposedPixelPosition, -halfCursorWidth), scaleWidth - halfCursorWidth)
    }

    /// Calculate the cursor overlay margin spacer width to align with ScaleView's HStack.
    ///
    /// ScaleView's `HStack(spacing: scaleHStackSpacing)` inserts spacing between the
    /// margin and the Canvas.  CursorOverlay must add the same amount to its clear-color
    /// spacers so the cursor interactive area starts at the exact same x as the Canvas.
    ///
    /// - Parameter marginWidth: The left or right margin width from ``Dimensions``.
    /// - Returns: `marginWidth + scaleHStackSpacing`
    @inlinable
    static func cursorMarginSpacerWidth(marginWidth: CGFloat) -> CGFloat {
        marginWidth + scaleHStackSpacing
    }

    /// Calculate total scale height from scale count and per-scale height.
    ///
    /// Used by both ``ContentView.totalScaleHeight(for:)`` and
    /// ``DynamicSlideRuleContent.consistentTotalScaleHeight(for:)`` to keep the
    /// cursor overlay height in sync with the actual rendered scale rows.
    ///
    /// - Parameters:
    ///   - scaleCount: Number of scales (top stator + slide + bottom stator).
    ///   - scaleHeight: Height of a single scale row in points.
    /// - Returns: `CGFloat(scaleCount) * scaleHeight`
    @inlinable
    static func totalScaleHeight(scaleCount: Int, scaleHeight: CGFloat) -> CGFloat {
        CGFloat(scaleCount) * scaleHeight
    }

}
