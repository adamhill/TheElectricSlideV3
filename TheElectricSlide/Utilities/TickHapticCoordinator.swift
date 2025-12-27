//
//  TickHapticCoordinator.swift
//  TheElectricSlide
//
//  Coordinates haptic feedback when cursor crosses tick marks on the C scale
//  Issue #61: Navigation gestures and tick haptics
//

import Foundation
import SlideRuleCoreV3
import os.log

private let tickHapticLogger = Logger(subsystem: "com.theelectricslide", category: "TickHaptic")

/// Coordinates haptic feedback for tick mark crossings during slide movement
/// Tracks cursor position relative to C scale ticks and fires appropriate haptics
@Observable
final class TickHapticCoordinator {
    
    // MARK: - Configuration
    
    /// Whether tick haptics are enabled
    var isEnabled: Bool = true
    
    // MARK: - Dependencies
    
    /// The haptic service for triggering haptic feedback
    /// Injectable for testing; defaults to DefaultHapticService
    @ObservationIgnored private let hapticService: HapticService
    
    // MARK: - Debug Configuration
    
    /// Enable verbose logging for debugging tick haptics
    /// Set to false for production builds
    private static let debugLogging = false
    
    /// Counter to throttle debug logs (only log every Nth call)
    @ObservationIgnored private var debugCallCount = 0
    private static let debugLogInterval = 10  // Log every 10th call
    
    // MARK: - Internal State
    
    /// The last tick position that triggered a haptic (to avoid repeats)
    @ObservationIgnored private var lastTriggeredTickPosition: Double?
    
    /// Tolerance for tick position comparison (avoids floating-point issues)
    private static let tickPositionTolerance: Double = 0.0001
    
    /// Minimum tick level to trigger haptics (avoids too many haptics from tiny ticks)
    private static let minimumTickLevel: Double = 0.4
    
    // MARK: - Initialization
    
    /// Creates a new TickHapticCoordinator with an optional haptic service
    /// - Parameter hapticService: The haptic service to use. Defaults to DefaultHapticService.
    init(hapticService: HapticService = DefaultHapticService()) {
        self.hapticService = hapticService
    }
    
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
        debugCallCount += 1
        let shouldLog = Self.debugLogging && (debugCallCount % Self.debugLogInterval == 1)
        
        if shouldLog {
            tickHapticLogger.debug("checkTickCrossing called #\(self.debugCallCount): cursor=\(cursorNormalizedPosition, format: .fixed(precision: 4)), slideOffset=\(slideOffset), scaleWidth=\(scaleWidth), tickCount=\(cScale.tickMarks.count)")
        }
        
        guard isEnabled else {
            if shouldLog { tickHapticLogger.debug("  → SKIP: isEnabled=false") }
            return
        }
        
        guard scaleWidth > 0 else {
            if shouldLog { tickHapticLogger.debug("  → SKIP: scaleWidth <= 0") }
            return
        }
        
        // Calculate where the cursor falls on the C scale, accounting for slide offset
        // When slide moves right (positive offset), the effective cursor position on the scale decreases
        let slideOffsetNormalized = Double(slideOffset / scaleWidth)
        let effectiveCursorPosition = cursorNormalizedPosition - slideOffsetNormalized
        
        // Clamp to valid range
        let clampedPosition = min(max(effectiveCursorPosition, 0.0), 1.0)
        
        if shouldLog {
            tickHapticLogger.debug("  slideOffsetNorm=\(slideOffsetNormalized, format: .fixed(precision: 4)), effectivePos=\(effectiveCursorPosition, format: .fixed(precision: 4)), clamped=\(clampedPosition, format: .fixed(precision: 4))")
        }
        
        // Find the nearest tick at this position
        guard let nearestTick = findNearestTick(at: clampedPosition, in: cScale.tickMarks, shouldLog: shouldLog) else {
            if shouldLog { tickHapticLogger.debug("  → SKIP: No tick found within 1% threshold") }
            return
        }
        
        if shouldLog {
            tickHapticLogger.debug("  nearestTick: pos=\(nearestTick.normalizedPosition, format: .fixed(precision: 4)), relLen=\(nearestTick.style.relativeLength, format: .fixed(precision: 2))")
        }
        
        // Only trigger haptics for ticks above minimum level
        guard nearestTick.style.relativeLength >= Self.minimumTickLevel else {
            if shouldLog { tickHapticLogger.debug("  → SKIP: relativeLength \(nearestTick.style.relativeLength) < minimum \(Self.minimumTickLevel)") }
            return
        }
        
        // Check if this is a new tick (different from last triggered)
        let tickPosition = nearestTick.normalizedPosition
        if let lastPosition = lastTriggeredTickPosition {
            // Skip if we're still at the same tick
            if abs(tickPosition - lastPosition) < Self.tickPositionTolerance {
                if shouldLog { tickHapticLogger.debug("  → SKIP: Same tick as last (\(lastPosition, format: .fixed(precision: 4)))") }
                return
            }
        }
        
        // We crossed to a new tick - trigger haptic
        lastTriggeredTickPosition = tickPosition
        
        // Use the new HapticService with TickLevel conversion
        let tickLevel = HapticEvent.TickLevel(relativeLength: nearestTick.style.relativeLength)
        hapticService.fire(.tickCrossed(level: tickLevel))
    }
    
    /// Reset the coordinator (call when starting a new drag)
    func reset() {
        lastTriggeredTickPosition = nil
    }
    
    // MARK: - Centralized Scale Selection
    
    /// Centralized scale selection for haptic feedback based on view mode
    /// This eliminates duplication across ContentView+Gestures handlers
    ///
    /// Priority: C scale (if available), then first scale on the appropriate slide
    /// For .both mode (iPad), check front slide first for C scale, then back slide
    ///
    /// - Parameters:
    ///   - viewMode: The current view mode (.front, .back, or .both)
    ///   - currentSlideRule: The current slide rule with front/back slides
    /// - Returns: The selected scale for haptic feedback, or nil if no suitable scale found
    static func selectHapticScale(
        viewMode: ViewMode,
        currentSlideRule: SlideRule
    ) -> GeneratedScale? {
        switch viewMode {
        case .front:
            // Front only: check front slide
            return currentSlideRule.frontSlide.scales.first(where: { $0.definition.name == "C" })
                ?? currentSlideRule.frontSlide.scales.first
            
        case .back:
            // Back only: check back slide
            return currentSlideRule.backSlide?.scales.first(where: { $0.definition.name == "C" })
                ?? currentSlideRule.backSlide?.scales.first
            
        case .both:
            // Both sides visible (iPad): prioritize C scale from either slide, preferring front
            if let cScale = currentSlideRule.frontSlide.scales.first(where: { $0.definition.name == "C" }) {
                return cScale
            }
            if let cScale = currentSlideRule.backSlide?.scales.first(where: { $0.definition.name == "C" }) {
                return cScale
            }
            // No C scale on either side, fall back to first scale on front slide (or back if no front)
            return currentSlideRule.frontSlide.scales.first
                ?? currentSlideRule.backSlide?.scales.first
        }
    }
    
    // MARK: - Private Helpers
    
    /// Find the nearest tick mark to the given position
    /// Uses binary search for efficiency with large tick arrays
    private func findNearestTick(at position: Double, in tickMarks: [TickMark], shouldLog: Bool = false) -> TickMark? {
        guard !tickMarks.isEmpty else {
            if shouldLog { tickHapticLogger.debug("  findNearestTick: tickMarks array is EMPTY") }
            return nil
        }
        
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
        
        if shouldLog {
            tickHapticLogger.debug("  findNearestTick: pos=\(position, format: .fixed(precision: 4)), leftDist=\(leftDistance, format: .fixed(precision: 4)), rightDist=\(rightDistance, format: .fixed(precision: 4)), closerDist=\(closerDistance, format: .fixed(precision: 4)), threshold=0.01")
        }
        
        // Only return if within 1% of scale width
        return closerDistance < 0.01 ? closerTick : nil
    }
}
