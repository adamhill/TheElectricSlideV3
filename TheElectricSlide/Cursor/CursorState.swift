//
//  CursorState.swift
//  TheElectricSlide
//
//  State management for glass cursor
//

import SwiftUI
import SlideRuleCoreV3

// Enable detailed cursor debugging (disabled by default to reduce log noise)
// Uncomment this line to enable verbose cursor reading logs during development
// #define DEBUG_CURSOR_READINGS

@Observable
final class CursorState {
    // MARK: - Core State Properties
    
    /// Normalized cursor position (0.0 = left edge, 1.0 = right edge)
    /// NOTE: This is the LEFT EDGE position. Add half cursor width to get hairline center.
    var normalizedPosition: Double = 0.5
    
    /// Current cursor behavior mode
    var cursorMode: CursorMode = .shared
    
    /// Whether cursor is visible and enabled
    var isEnabled: Bool = true
    
    /// Current drag offset in pixels (for live dragging feedback)
    var activeDragOffset: CGFloat = 0
    
    // MARK: - Interaction State Properties
    
    /// Whether cursor is currently being dragged
    var isCursorDragging: Bool = false
    
    /// Whether slide is currently being dragged
    var isSlideDragging: Bool = false
    
    /// Whether stator was touched (sticky state)
    var statorWasTouched: Bool = false
    
    /// Computed property: Should readings be visible?
    /// True when: cursor dragging OR slide dragging OR stator was touched
    var shouldShowReadings: Bool {
        isCursorDragging || isSlideDragging || statorWasTouched
    }
    
    // MARK: - Per-Side Positions (for future independent mode)
    
    private var frontPosition: Double = 0.5
    private var backPosition: Double = 0.5
    
    // MARK: - Reading Feature Properties
    
    // HOT property - internal cache, changes frequently, not observed
    @ObservationIgnored private var _internalReadings: CursorReadings? = nil
    @ObservationIgnored private var _updateCounter: Int = 0
    
    // COLD property - public display, only updates when values change
    private(set) var currentReadings: CursorReadings?
    
    /// Whether to enable automatic reading updates
    var enableReadings: Bool = true
    
    // Debug logging throttle - only log every Nth update to reduce noise
    @ObservationIgnored private var _debugLogCounter: Int = 0
    @ObservationIgnored private static let debugLogInterval = 10
    
    /// Reference to slide rule data provider
    private var slideRuleProvider: SlideRuleProvider?
    
    // MARK: - Position Management
    
    /// Get position for a specific side based on current mode
    /// - Parameter side: The rule side (nil for default position)
    /// - Returns: Normalized position (0.0-1.0)
    func position(for side: RuleSide?) -> Double {
        switch cursorMode {
        case .shared:
            return normalizedPosition
        case .independent:
            guard let side = side else { return normalizedPosition }
            return side == .front ? frontPosition : backPosition
        case .activeSideOnly:
            return normalizedPosition
        }
    }
    
    /// Set position for a specific side based on current mode
    /// - Parameters:
    ///   - position: New normalized position (will be clamped to 0.0-1.0)
    ///   - side: The rule side (nil for default)
    func setPosition(_ position: Double, for side: RuleSide?) {
        let clamped = min(max(position, 0.0), 1.0)
        
        switch cursorMode {
        case .shared:
            normalizedPosition = clamped
        case .independent:
            guard let side = side else {
                normalizedPosition = clamped
                return
            }
            if side == .front {
                frontPosition = clamped
            } else {
                backPosition = clamped
            }
        case .activeSideOnly:
            normalizedPosition = clamped
        }
        
        // Trigger reading update when position changes
        if enableReadings {
            updateReadings()
        }
    }
    
    /// Convert normalized position to absolute pixel position
    /// - Parameters:
    ///   - width: Available width for cursor movement
    ///   - side: The rule side (nil for default)
    /// - Returns: Absolute position in points
    func absolutePosition(width: CGFloat, side: RuleSide? = nil) -> CGFloat {
        position(for: side) * width
    }
    
    // MARK: - Mode Management
    
    /// Switch to a different cursor mode
    /// - Parameter mode: The new cursor mode
    func switchMode(to mode: CursorMode) {
        cursorMode = mode
    }
    
    // MARK: - Reading Methods
    
    /// Set the slide rule data provider
    /// - Parameter provider: Object conforming to SlideRuleProvider
    func setSlideRuleProvider(_ provider: SlideRuleProvider) {
        self.slideRuleProvider = provider
        // Initial reading update
        updateReadings()
    }
    
    /// Update readings based on current cursor position
    /// Called automatically when position changes (if enableReadings is true)
    func updateReadings() {
        updateReadings(at: normalizedPosition)
    }
    
    /// Update readings for a specific position (used during drag)
    /// - Parameter position: The position to calculate readings for (0.0-1.0)
    func updateReadings(at position: Double) {
        #if DEBUG && DEBUG_CURSOR_READINGS
        // Throttled logging: only log every Nth call to reduce noise during drag
        _debugLogCounter += 1
        if _debugLogCounter % Self.debugLogInterval == 0 {
            print("📊 updateReadings(at: \(position)) - enableReadings=\(enableReadings), provider=\(slideRuleProvider != nil ? "set" : "nil")")
        }
        #endif
        
        guard enableReadings,
              let provider = slideRuleProvider else {
            #if DEBUG && DEBUG_CURSOR_READINGS
            if _debugLogCounter % Self.debugLogInterval == 0 {
                print("📊 updateReadings: GUARD FAILED - enableReadings=\(enableReadings), provider=\(slideRuleProvider != nil)")
            }
            #endif
            currentReadings = nil
            return
        }
        
        // Adjust position to hairline center (position is left edge of cursor)
        let scaleWidth = provider.getScaleWidth()
        let halfCursorWidthNormalized = (CursorView.cursorWidth / 2.0) / scaleWidth
        let hairlinePosition = position + halfCursorWidthNormalized
        
        var frontReadings: [ScaleReading] = []
        var backReadings: [ScaleReading] = []
        
        // Query front side scales (if visible)
        if let frontData = provider.getFrontScaleData() {
            frontReadings = queryScales(
                topStator: frontData.topStator,
                slide: frontData.slide,
                bottomStator: frontData.bottomStator,
                position: hairlinePosition,
                slideOffset: provider.getSlideOffset(),
                scaleWidth: scaleWidth,
                side: .front
            )
        }
        
        // Query back side scales (if visible)
        if let backData = provider.getBackScaleData() {
            backReadings = queryScales(
                topStator: backData.topStator,
                slide: backData.slide,
                bottomStator: backData.bottomStator,
                position: hairlinePosition,
                slideOffset: provider.getSlideOffset(),
                scaleWidth: scaleWidth,
                side: .back
            )
        }
        
        // Create new readings
        let newReadings = CursorReadings(
            cursorPosition: hairlinePosition,
            timestamp: Date(),
            frontReadings: frontReadings,
            backReadings: backReadings
        )
        
        // Update internal cache (not observed)
        _internalReadings = newReadings
        _updateCounter += 1
        
        // Only update observable property when display values actually changed AND throttled
        // The %3 throttle reduces UI updates during gross slide dragging (for show, not precision)
        // Precision work happens at slow speeds where throttling has minimal impact
        if newReadings != currentReadings && _updateCounter % 3 == 0 {
            currentReadings = newReadings
        }
        
        // Debug: Print sample readings for verification (throttled to reduce log noise)
        #if DEBUG && DEBUG_CURSOR_READINGS
        if _debugLogCounter % Self.debugLogInterval == 0, let readings = currentReadings {
            print("📍 Cursor hairline at position: \(String(format: "%.3f", readings.cursorPosition))")
            if let cReading = readings.reading(forScale: "C", side: .front) {
                print("  C scale: \(cReading.displayValue) (value: \(String(format: "%.4f", cReading.value)))")
            }
            if let dReading = readings.reading(forScale: "D", side: .front) {
                print("  D scale: \(dReading.displayValue) (value: \(String(format: "%.4f", dReading.value)))")
            }
        }
        #endif
    }
    
    /// Query all scales in a side's components
    private func queryScales(
        topStator: Stator,
        slide: Slide,
        bottomStator: Stator,
        position: Double,
        slideOffset: CGFloat,
        scaleWidth: CGFloat,
        side: RuleSide
    ) -> [ScaleReading] {
        var readings: [ScaleReading] = []
        
        #if DEBUG && DEBUG_CURSOR_READINGS
        if _debugLogCounter % Self.debugLogInterval == 0 {
            print("📊 queryScales[\(side.rawValue)]: topStator=\(topStator.scales.count), slide=\(slide.scales.count), bottomStator=\(bottomStator.scales.count), scaleWidth=\(scaleWidth)")
        }
        #endif
        
        // Read top stator scales (fixed, no offset needed)
        var componentPosition = 0
        for scale in topStator.scales {
            let reading = calculateReading(
                at: position,
                for: scale,
                component: .statorTop,
                side: side,
                componentPosition: componentPosition
            )
            readings.append(reading)
            componentPosition += 1
        }
        
        // Read slide scales (account for slide offset)
        let slideOffsetNormalized = slideOffset / scaleWidth
        let slidePosition = position - slideOffsetNormalized
        let clampedSlidePosition = min(max(slidePosition, 0.0), 1.0)
        
        componentPosition = 0  // Reset for slide component
        for scale in slide.scales {
            let reading = calculateReading(
                at: clampedSlidePosition,
                for: scale,
                component: .slide,
                side: side,
                componentPosition: componentPosition
            )
            readings.append(reading)
            componentPosition += 1
        }
        
        // Read bottom stator scales (fixed, no offset needed)
        componentPosition = 0  // Reset for bottom stator component
        for scale in bottomStator.scales {
            let reading = calculateReading(
                at: position,
                for: scale,
                component: .statorBottom,
                side: side,
                componentPosition: componentPosition
            )
            readings.append(reading)
            componentPosition += 1
        }
        
        return readings
    }
    
    // MARK: - Interaction State Management
    
    /// Update cursor drag state
    /// - Parameter dragging: Whether cursor is currently being dragged
    func setCursorDragging(_ dragging: Bool) {
        isCursorDragging = dragging
        
        // Clear stator sticky state when cursor drag ends
        if !dragging && !isSlideDragging {
            statorWasTouched = false
        }
    }
    
    /// Update slide drag state
    /// - Parameter dragging: Whether slide is currently being dragged
    func setSlideDragging(_ dragging: Bool) {
        isSlideDragging = dragging
        
        // Clear stator sticky state when slide drag ends
        if !dragging && !isCursorDragging {
            statorWasTouched = false
        }
    }
    
    /// Mark that stator was touched (sticky state)
    func setStatorTouched() {
        statorWasTouched = true
    }
}