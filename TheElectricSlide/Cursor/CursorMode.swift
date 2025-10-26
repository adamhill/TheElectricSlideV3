//
//  CursorMode.swift
//  TheElectricSlide
//
//  Glass cursor behavior modes
//

import Foundation

/// Defines how the cursor behaves across different rule sides
enum CursorMode: String, CaseIterable, Identifiable {
    /// Single cursor synchronized across both sides (default)
    case shared = "Shared"
    
    /// Independent cursor per side (future enhancement)
    case independent = "Independent"
    
    /// Cursor only on most recently interacted side (future enhancement)
    case activeSideOnly = "Active Only"
    
    var id: String { rawValue }
}