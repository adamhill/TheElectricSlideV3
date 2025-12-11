//
//  TickHapticCoordinator.swift
//  TheElectricSlide
//
//  Coordinates haptic feedback when cursor crosses tick marks on the C scale
//  Issue #61: Navigation gestures and tick haptics
//

import Foundation
import SlideRuleCoreV3

/// Coordinates haptic feedback for tick mark crossings during slide movement
/// Tracks cursor position relative to C scale ticks and fires appropriate haptics
@Observable
final class TickHapticCoordinator {
    
    // MARK: - Configuration
    
    /// Whether tick haptics are enabled
    var isEnabled: Bool = true
    
    // MARK: - Internal State
    
    /// The last tick position that triggered a haptic (to avoid repeats)
    @ObservationIgnored private var lastTriggeredTickPosition: Double?
    
    /// Tolerance for tick position comparison (avoids floating-point issues)
    private static let tickPositionTolerance: Double = 0.0001
    
    /// Minimum tick level to trigger haptics (avoids too many haptics from tiny ticks)
    private static let minimumTickLevel: Double = 0.4
    
    // MARK: - Public API
    
    /// Check for tick crossings and trigger haptics
    /// Call this when the slide position changes
    /// - Parameters:
    ///   - cursorNormalizedPosition: The cursor's normalized position (0.0-1.0)
    ///   - slideOffset: The current slide offset in pixels
    ///   - scaleWidth: The total scale width in pixels
    ///   - cScale: The C scale GeneratedScale to check against
    func checkTickCrossing(
        cursorNormalizedPosition: Double,
        slideOffset: CGFloat,
        scaleWidth: CGFloat,
        cScale: GeneratedScale
    ) {
        guard isEnabled, scaleWidth > 0 else { return }
        
        // Calculate where the cursor falls on the C scale, accounting for slide offset
        // When slide moves right (positive offset), the effective cursor position on the scale decreases
        let slideOffsetNormalized = Double(slideOffset / scaleWidth)
        let effectiveCursorPosition = cursorNormalizedPosition - slideOffsetNormalized
        
        // Clamp to valid range
        let clampedPosition = min(max(effectiveCursorPosition, 0.0), 1.0)
        
        // Find the nearest tick at this position
        guard let nearestTick = findNearestTick(at: clampedPosition, in: cScale.tickMarks) else {
            return
        }
        
        // Only trigger haptics for ticks above minimum level
        guard nearestTick.style.relativeLength >= Self.minimumTickLevel else {
            return
        }
        
        // Check if this is a new tick (different from last triggered)
        let tickPosition = nearestTick.normalizedPosition
        if let lastPosition = lastTriggeredTickPosition {
            // Skip if we're still at the same tick
            if abs(tickPosition - lastPosition) < Self.tickPositionTolerance {
                return
            }
        }
        
        // We crossed to a new tick - trigger haptic
        lastTriggeredTickPosition = tickPosition
        HapticManager.tickHaptic(forLevel: nearestTick.style.relativeLength)
    }
    
    /// Reset the coordinator (call when starting a new drag)
    func reset() {
        lastTriggeredTickPosition = nil
    }
    
    // MARK: - Private Helpers
    
    /// Find the nearest tick mark to the given position
    /// Uses binary search for efficiency with large tick arrays
    private func findNearestTick(at position: Double, in tickMarks: [TickMark]) -> TickMark? {
        guard !tickMarks.isEmpty else { return nil }
        
        // Binary search to find the insertion point
        var low = 0
        var high = tickMarks.count - 1
        
        while low < high {
            let mid = (low + high) / 2
            if tickMarks[mid].normalizedPosition < position {
                low = mid + 1
            } else {
                high = mid
            }
        }
        
        // Check which of the adjacent ticks is closer
        let rightIndex = low
        let leftIndex = max(0, low - 1)
        
        let leftTick = tickMarks[leftIndex]
        let rightTick = tickMarks[rightIndex]
        
        let leftDistance = abs(leftTick.normalizedPosition - position)
        let rightDistance = abs(rightTick.normalizedPosition - position)
        
        // Return the closer tick, but only if it's within a reasonable range
        // This prevents triggering haptics when cursor is far from any tick
        let closerTick = leftDistance < rightDistance ? leftTick : rightTick
        let closerDistance = min(leftDistance, rightDistance)
        
        // Only return if within 1% of scale width
        return closerDistance < 0.01 ? closerTick : nil
    }
}
