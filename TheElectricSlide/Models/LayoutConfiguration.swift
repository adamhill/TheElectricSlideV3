//
//  LayoutConfiguration.swift
//  TheElectricSlide
//
//  Layout configuration types for responsive slide rule rendering
//

import SwiftUI

// MARK: - Layout Constants

/// Responsive layout configuration with breakpoints and margin values
/// Marked nonisolated to allow access from nonisolated contexts (onGeometryChange closures)
nonisolated enum LayoutConstants {
    // Breakpoint widths for responsive layout tiers
    // Based on common device widths: iPhone SE (320pt), standard phones (480pt), tablets/wide windows (640pt+)
    static let extraLargeBreakpoint: CGFloat = 640
    static let largeBreakpoint: CGFloat = 480
    static let mediumBreakpoint: CGFloat = 320
    
    // Margin widths for each responsive tier
    // Progressively smaller margins accommodate narrower screens while maintaining readability
    static let extraLargeMargin: CGFloat = 72
    static let largeMargin: CGFloat = 64
    static let mediumMargin: CGFloat = 56
    static let smallMargin: CGFloat = 48
}

// MARK: - Dimensions

// NOTE:
// `onGeometryChange(for:)` requires the value type to be usable across isolation domains.
// A main-actor–isolated conformance to `Equatable` cannot satisfy a generic `Sendable` requirement.
// By making the type's conformances `nonisolated` and using `@unchecked Sendable` for this trivial
// value type, we assert it's safe to pass across tasks/actors.
// This avoids the compiler error: "Main actor-isolated conformance ... cannot satisfy conformance
// requirement for a 'Sendable' type parameter".
nonisolated struct Dimensions: Equatable, @unchecked Sendable {
    var width: CGFloat
    var scaleHeight: CGFloat
    var leftMarginWidth: CGFloat
    var rightMarginWidth: CGFloat
    var tier: LayoutTier
    
    /// Default dimensions for initial state
    static let `default` = Dimensions(
        width: 800,
        scaleHeight: 25,
        leftMarginWidth: 64,
        rightMarginWidth: 64,
        tier: .extraLarge
    )
}

// MARK: - Layout Tier

/// Responsive breakpoint tiers for layout adaptation
enum LayoutTier: Sendable {
    case extraLarge  // 640pt+ width
    case large       // 480-639pt width
    case medium      // 320-479pt width
    case small       // <320pt width
    
    /// Determine layout tier from available width
    nonisolated static func from(availableWidth: CGFloat) -> LayoutTier {
        switch availableWidth {
        case LayoutConstants.extraLargeBreakpoint...:
            return .extraLarge
        case LayoutConstants.largeBreakpoint..<LayoutConstants.extraLargeBreakpoint:
            return .large
        case LayoutConstants.mediumBreakpoint..<LayoutConstants.largeBreakpoint:
            return .medium
        default:
            return .small
        }
    }
    
    /// Margin width for this tier
    nonisolated var marginWidth: CGFloat {
        switch self {
        case .extraLarge: return LayoutConstants.extraLargeMargin
        case .large: return LayoutConstants.largeMargin
        case .medium: return LayoutConstants.mediumMargin
        case .small: return LayoutConstants.smallMargin
        }
    }
    
    /// Font size for scale names (left margin) - always bold
    nonisolated var nameFont: Font {
        #if os(macOS)
        // macOS: 2pt larger than standard
        switch self {
        case .extraLarge: return .system(size: 14, weight: .bold)  // caption ≈12pt + 2pt
        case .large: return .system(size: 14, weight: .bold)
        case .medium: return .system(size: 12, weight: .bold)  // caption2 ≈10pt + 2pt
        case .small: return .system(size: 12, weight: .bold)
        }
        #else
        // iOS/iPadOS: standard sizes
        switch self {
        case .extraLarge: return .caption.weight(.bold)
        case .large: return .caption.weight(.bold)
        case .medium: return .caption2.weight(.bold)
        case .small: return .caption2.weight(.bold)
        }
        #endif
    }
    
    /// Font size for formulas (right margin) - slightly smaller than names
    nonisolated var formulaFont: Font {
        switch self {
        case .extraLarge: return .caption.weight(.medium)
        case .large: return .caption.weight(.medium)
        case .medium: return .caption2
        case .small: return .caption2
        }
    }
}

// Explicit nonisolated Equatable conformance for LayoutTier
extension LayoutTier: Equatable {
    nonisolated static func == (lhs: LayoutTier, rhs: LayoutTier) -> Bool {
        switch (lhs, rhs) {
        case (.extraLarge, .extraLarge), (.large, .large), (.medium, .medium), (.small, .small):
            return true
        default:
            return false
        }
    }
}
