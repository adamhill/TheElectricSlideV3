//
//  RuleSide.swift
//  TheElectricSlide
//
//  Rule side enumeration for identifying front/back of slide rule
//

import SwiftUI

// MARK: - Rule Side

/// Represents which side of the slide rule is being displayed
/// - front: The primary (front) side
/// - back: The reverse (back) side
enum RuleSide: String, Sendable {
    case front
    case back
    
    /// Border color for visual distinction between sides
    var borderColor: Color {
        switch self {
        case .front: return .blue
        case .back: return .green
        }
    }
}
