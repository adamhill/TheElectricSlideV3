//
//  CursorReadings.swift
//  TheElectricSlide
//
//  Data structures for cursor reading feature
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
    
    enum ComponentType: String, Sendable {
        case statorTop = "Top Stator"
        case slide = "Slide"
        case statorBottom = "Bottom Stator"
    }
}

// MARK: - Cursor Readings

/// Complete set of cursor readings at a moment in time
struct CursorReadings: Sendable {
    /// Cursor position when readings were taken (0.0-1.0)
    let cursorPosition: Double
    
    /// Timestamp of reading capture
    let timestamp: Date
    
    /// All scale readings from front side
    let frontReadings: [ScaleReading]
    
    /// All scale readings from back side
    let backReadings: [ScaleReading]
    
    /// All readings in a flat array for iteration
    var allReadings: [ScaleReading] {
        frontReadings + backReadings
    }
    
    /// Get readings grouped by component type
    /// - Parameter component: The component type to filter by
    /// - Returns: Array of readings for that component
    func readings(for component: ScaleReading.ComponentType) -> [ScaleReading] {
        allReadings.filter { $0.component == component }
    }
    
    /// Find reading for a specific scale name on a specific side
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
    /// - Returns: ScaleReading with calculated value
    func calculateReading(
        at cursorPosition: Double,
        for scale: GeneratedScale,
        component: ScaleReading.ComponentType,
        side: RuleSide
    ) -> ScaleReading {
        // Use ScaleCalculator to get value (O(1) operation)
        let value = ScaleCalculator.value(
            at: cursorPosition,
            on: scale.definition
        )
        
        // Format display value using scale's formatter
        let displayValue = formatValueForDisplay(
            value: value,
            definition: scale.definition
        )
        
        return ScaleReading(
            scaleName: scale.definition.name,
            formula: scale.definition.formula,
            value: value,
            displayValue: displayValue,
            side: side,
            component: component,
            scaleDefinition: scale.definition
        )
    }
    
    /// Format value using scale's label formatter or smart default
    /// - Parameters:
    ///   - value: The value to format
    ///   - definition: The scale definition (may have custom formatter)
    /// - Returns: Formatted string for display
    private func formatValueForDisplay(
        value: Double,
        definition: ScaleDefinition
    ) -> String {
        // Handle non-finite values
        guard value.isFinite else {
            return "—"  // Em dash for undefined/infinite
        }
        
        // Use scale's custom formatter if available
        if let formatter = definition.labelFormatter {
            return formatter(value)
        }
        
        // Otherwise use smart default formatting
        return formatSmartDefault(value)
    }
    
    /// Smart default formatting based on value magnitude
    private func formatSmartDefault(_ value: Double) -> String {
        if abs(value) < 0.01 {
            return String(format: "%.4f", value)
        } else if abs(value) < 1 {
            return String(format: "%.3f", value)
        } else if abs(value) < 10 {
            return String(format: "%.2f", value)
        } else if abs(value) < 100 {
            return String(format: "%.1f", value)
        } else if abs(value - value.rounded()) < 0.01 {
            return String(Int(value.rounded()))
        } else {
            return String(format: "%.1f", value)
        }
    }
}