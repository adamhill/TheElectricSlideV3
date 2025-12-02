//
//  CursorDisplayMode.swift
//  TheElectricSlide
//
//  Cursor display mode types for controlling cursor visualization
//

import Foundation

// MARK: - Cursor Display Mode

/// Defines what cursor information to display on the slide rule
/// - gradients: Display only gradient overlay lines
/// - values: Display only numerical reading values
/// - both: Display both gradients and values
enum CursorDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case gradients
    case values
    case both
    
    var id: String { rawValue }
    
    /// User-facing display text for picker
    var displayText: String {
        switch self {
        case .gradients: return "Gradients"
        case .values: return "Values"
        case .both: return "Both"
        }
    }
    
    /// Whether gradient lines should be displayed
    var showGradients: Bool {
        switch self {
        case .gradients, .both:
            return true
        case .values:
            return false
        }
    }
    
    /// Whether reading values should be displayed
    var showReadings: Bool {
        switch self {
        case .values, .both:
            return true
        case .gradients:
            return false
        }
    }
}

// MARK: - Cursor Reading Cycle Mode

/// Defines which side's readings to display in the cursor readings area
/// - currentSide: Show only the current side's readings (front or back)
/// - oppositeSide: Show only the opposite side's readings
/// - both: Show both sides' readings stacked vertically
/// - none: Show nothing (collapsed)
enum CursorReadingCycleMode: String, CaseIterable, Sendable {
    case currentSide
    case oppositeSide
    case both
    case none
    
    /// Get next cycle mode (4-state cycle)
    func next() -> CursorReadingCycleMode {
        switch self {
        case .currentSide: return .oppositeSide
        case .oppositeSide: return .both
        case .both: return .none
        case .none: return .currentSide
        }
    }
}
