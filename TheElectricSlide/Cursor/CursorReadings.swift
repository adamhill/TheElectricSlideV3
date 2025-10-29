//
//  CursorReadings.swift
//  TheElectricSlide
//
//  Data structures for cursor reading feature
//  Precision is determined by scale definitions using subsection-based intervals
//

import Foundation
import SlideRuleCoreV3

// MARK: - Scale Reading

/// Represents a single scale reading at the cursor position
struct ScaleReading: Sendable, Identifiable {
    let id = UUID()
    
    /// Scale identifier (e.g., "C", "D", "A", "K")
    let scaleName: String
    
    /// Formula/function display (e.g., "x", "x²", "x³")
    let formula: String
    
    /// Calculated value at cursor position
    let value: Double
    
    /// Formatted display string (respects scale's label formatter)
    let displayValue: String
    
    /// Which side this reading is from
    let side: RuleSide
    
    /// Component location (stator top/slide/stator bottom)
    let component: ComponentType
    
    /// Original scale definition (for reference)
    let scaleDefinition: ScaleDefinition
    
    /// Position within component (0, 1, 2...)
    let componentPosition: Int
    
    /// Overall position on rule face (top to bottom)
    let overallPosition: Int
    
    enum ComponentType: String, Sendable {
        case statorTop = "Top Stator"
        case slide = "Slide"
        case statorBottom = "Bottom Stator"
    }
}

// MARK: - Cursor Readings

/// Complete set of cursor readings at a moment in time
struct CursorReadings: Sendable, Equatable {
    /// Cursor position when readings were taken (0.0-1.0)
    let cursorPosition: Double
    
    /// Timestamp of reading capture
    let timestamp: Date
    
    /// All scale readings from front side (stored for backward compatibility)
    let frontReadings: [ScaleReading]
    
    /// All scale readings from back side (stored for backward compatibility)
    let backReadings: [ScaleReading]
    
    /// All readings sorted by overall position (ordered array for iteration)
    let allReadings: [ScaleReading]
    
    /// Readings from top stator component only
    let statorTopReadings: [ScaleReading]
    
    /// Readings from slide component only
    let slideReadings: [ScaleReading]
    
    /// Readings from bottom stator component only
    let statorBottomReadings: [ScaleReading]
    
    /// Initialize with readings arrays, automatically building ordered and filtered arrays
    /// - Parameters:
    ///   - cursorPosition: Normalized cursor position (0.0-1.0)
    ///   - timestamp: Time when readings were captured
    ///   - frontReadings: Readings from front side
    ///   - backReadings: Readings from back side
    init(
        cursorPosition: Double,
        timestamp: Date,
        frontReadings: [ScaleReading],
        backReadings: [ScaleReading]
    ) {
        self.cursorPosition = cursorPosition
        self.timestamp = timestamp
        self.frontReadings = frontReadings
        self.backReadings = backReadings
        
        // Build ordered array sorted by overall position
        let combined = frontReadings + backReadings
        self.allReadings = combined.sorted { $0.overallPosition < $1.overallPosition }
        
        // Build component-filtered arrays
        self.statorTopReadings = combined.filter { $0.component == .statorTop }
        self.slideReadings = combined.filter { $0.component == .slide }
        self.statorBottomReadings = combined.filter { $0.component == .statorBottom }
    }
    
    // MARK: - Equatable Conformance
    
    /// Compare readings based on formatted display values only
    /// This prevents unnecessary updates when display strings haven't changed
    static func == (lhs: CursorReadings, rhs: CursorReadings) -> Bool {
        // Compare only the formatted display strings, not raw positions or timestamps
        lhs.frontReadings.elementsEqual(rhs.frontReadings) { $0.displayValue == $1.displayValue } &&
        lhs.backReadings.elementsEqual(rhs.backReadings) { $0.displayValue == $1.displayValue }
    }
    
    /// Get readings grouped by component type
    /// - Parameter component: The component type to filter by
    /// - Returns: Array of readings for that component
    func readings(for component: ScaleReading.ComponentType) -> [ScaleReading] {
        switch component {
        case .statorTop:
            return statorTopReadings
        case .slide:
            return slideReadings
        case .statorBottom:
            return statorBottomReadings
        }
    }
    
    /// Find reading for a specific scale name on a specific side (efficient lookup)
    /// - Parameters:
    ///   - name: Scale name to find (e.g., "C", "D")
    ///   - side: Which side to search
    /// - Returns: The reading if found
    func reading(forScale name: String, side: RuleSide) -> ScaleReading? {
        let readings = side == .front ? frontReadings : backReadings
        return readings.first { $0.scaleName == name }
    }
}

// MARK: - Slide Rule Provider Protocol

/// Protocol for providing slide rule data to cursor for reading calculations
/// ContentView conforms to this protocol
protocol SlideRuleProvider {
    /// Get front side scale data (returns nil if front not visible)
    func getFrontScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)?
    
    /// Get back side scale data (returns nil if back not visible)
    func getBackScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)?
    
    /// Get current slide offset in points
    func getSlideOffset() -> CGFloat
    
    /// Get scale width in points (for offset normalization)
    func getScaleWidth() -> CGFloat
}

// MARK: - Reading Calculation Helpers

extension CursorState {
    /// Calculate scale value at cursor position
    /// - Parameters:
    ///   - cursorPosition: Normalized position (0.0-1.0)
    ///   - scale: The generated scale to query
    ///   - component: Component type (for metadata)
    ///   - side: Rule side (for metadata)
    ///   - componentPosition: Position within component (0, 1, 2...)
    ///   - overallPosition: Overall position on rule face
    func calculateReading(
        at cursorPosition: Double,
        for scale: GeneratedScale,
        component: ScaleReading.ComponentType,
        side: RuleSide,
        componentPosition: Int,
        overallPosition: Int
    ) -> ScaleReading {
        // Use ScaleCalculator to get value (O(1) operation)
        let value = ScaleCalculator.value(
            at: cursorPosition,
            on: scale.definition
        )
        
        // Get precision from scale definition
        let decimalPlaces = scale.definition.cursorDecimalPlaces(at: cursorPosition, zoomLevel: 1.0)
        
        // Format with calculated precision
        let displayValue = formatValueForCursor(
            value: value,
            decimalPlaces: decimalPlaces
        )
        
        return ScaleReading(
            scaleName: scale.definition.name,
            formula: scale.definition.formula,
            value: value,
            displayValue: displayValue,
            side: side,
            component: component,
            scaleDefinition: scale.definition,
            componentPosition: componentPosition,
            overallPosition: overallPosition
        )
    }
    
    /// Format value for cursor reading display using specified decimal places
    /// - Parameters:
    ///   - value: The value to format
    ///   - decimalPlaces: Number of decimal places (from scale definition)
    /// - Returns: Formatted string for display
    private func formatValueForCursor(
        value: Double,
        decimalPlaces: Int
    ) -> String {
        // Handle non-finite values
        guard value.isFinite else {
            return "—"  // Em dash for undefined/infinite
        }
        
        // Format with specified decimal places
        return String(format: "%.\(decimalPlaces)f", value)
    }
}