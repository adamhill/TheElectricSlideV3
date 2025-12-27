//
//  LayoutConfiguration.swift
//  TheElectricSlide
//
//  Layout configuration types for responsive slide rule rendering
//

import SwiftUI
import SlideRuleCoreV3

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
    
    // MARK: - Layout Constants
    
    /// Scale height configuration
    private static let minScaleHeight: CGFloat = 20   // Minimum height for a scale
    private static let maxScaleHeight: CGFloat = 30   // Maximum height per scale
    
    /// Target aspect ratio (width:height) for slide rule
    /// Slide rules are typically very wide and relatively short (10:1 to 8:1)
    private static let targetAspectRatio: CGFloat = 10.0
    
    /// Padding around the slide rule
    private static let padding: CGFloat = 40
    
    /// Vertical spacing between sides when showing both
    private static let sideSpacing: CGFloat = 20
    
    // MARK: - Dimension Calculation
    
    /// Calculate responsive dimensions for the slide rule layout
    /// - Parameters:
    ///   - availableWidth: Available width from geometry
    ///   - availableHeight: Available height from geometry
    ///   - viewMode: Current view mode (front, back, both)
    ///   - slideRule: The current slide rule for scale counts
    ///   - deviceCategory: Device category for platform-specific adjustments
    /// - Returns: Calculated dimensions for layout
    nonisolated static func calculate(
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        viewMode: ViewMode,
        slideRule: SlideRule,
        deviceCategory: DeviceCategory
    ) -> Dimensions {
        // Account for device-specific horizontal padding applied in DynamicSlideRuleContent
        // iPhone: 8pt × 2 = 16pt, iPad/Mac: 20pt × 2 = 40pt
        let devicePadding: CGFloat = deviceCategory == .phone ? 16 : 40
        let maxWidth = availableWidth - devicePadding
        let maxHeight = availableHeight - (padding * 2)
        
        // Determine layout tier based on available width
        let tier = LayoutTier.from(availableWidth: availableWidth)
        
        // Use symmetric margins based on layout tier for all platforms
        // This maximizes scale width while maintaining readable scale labels
        let leftMarginWidth = tier.marginWidth
        let rightMarginWidth = tier.marginWidth
        
        // HStack spacing: 4pt between left margin and scale, 4pt between scale and right margin
        let totalMarginAndSpacing = leftMarginWidth + rightMarginWidth + 8
        
        // Calculate side gap count (1 gap between sides when showing both)
        let sideGapCount: Int
        if viewMode == .both && slideRule.backTopStator != nil {
            sideGapCount = 1
        } else {
            sideGapCount = 0
        }
        
        // Estimate total vertical space needed for labels (when showing both sides)
        let labelHeight: CGFloat
        if viewMode == .both && slideRule.backTopStator != nil {
            labelHeight = 30  // ~15pt per label × 2 labels
        } else {
            labelHeight = 0
        }
        
        // Calculate total scale count
        var totalScaleCount = 0
        if viewMode == .front || viewMode == .both {
            totalScaleCount += slideRule.frontTopStator.scales.count +
                               slideRule.frontSlide.scales.count +
                               slideRule.frontBottomStator.scales.count
        }
        if (viewMode == .back || viewMode == .both),
           let backTop = slideRule.backTopStator,
           let backSlide = slideRule.backSlide,
           let backBottom = slideRule.backBottomStator {
            totalScaleCount += backTop.scales.count +
                               backSlide.scales.count +
                               backBottom.scales.count
        }
        
        // Account for spacing between sides and labels
        let totalSpacingHeight = (CGFloat(sideGapCount) * sideSpacing) + labelHeight
        let availableHeightForScales = maxHeight - totalSpacingHeight
        
        // Calculate scale height based on available height
        let calculatedScaleHeight = min(
            availableHeightForScales / CGFloat(totalScaleCount),
            maxScaleHeight
        )
        let scaleHeight = max(calculatedScaleHeight, minScaleHeight)
        
        // Calculate total height needed for all scales
        let totalHeight = scaleHeight * CGFloat(totalScaleCount) + totalSpacingHeight
        
        // Calculate width based on aspect ratio
        let widthFromAspectRatio = totalHeight * targetAspectRatio
        
        // Use the smaller of the two to ensure it fits within window
        // Then subtract margins to get the actual scale width
        let totalAvailableWidth = min(maxWidth, widthFromAspectRatio)
        let scaleWidth = max(totalAvailableWidth - totalMarginAndSpacing, 100) // 100pt minimum scale width
        
        return Dimensions(
            width: scaleWidth,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth,
            tier: tier
        )
    }
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
