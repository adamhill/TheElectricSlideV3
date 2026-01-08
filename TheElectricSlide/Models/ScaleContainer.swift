//
//  ScaleContainer.swift
//  TheElectricSlide
//
//  Protocol abstraction for components that contain scales (Slide and Stator)
//  Enables generic rendering logic to eliminate duplication
//

import SlideRuleCoreV3

/// Protocol for slide rule components that contain scales
/// Both Slide and Stator conform to this protocol
protocol ScaleContainer {
    var scales: [GeneratedScale] { get }
    var showBorder: Bool { get }
    
    /// Approximate total height of all scales in this container.
    ///
    /// This calculation assumes a uniform 4pt spacing between adjacent scales and is
    /// intended for simple layout heuristics. It does **not** account for any
    /// PostScript/PDF-export-specific spacing rules (such as additional spacing for
    /// particular scale combinations like C/D).
    ///
    /// For configuration-aware spacing that matches PDF export behavior, use
    /// `totalScalesHeight(spacingProvider:)` with a spacing function that mirrors
    /// the rules from `PDFExportConfiguration.spacingBetweenScales`.
    var totalScalesHeight: Distance { get }
}

extension ScaleContainer {
    /// Default implementation that uses no between scales. 
    /// Because the internal scaling gives good enough spacing.
    var totalScalesHeight: Distance {
        let scalesHeight = scales.map { $0.definition.height }.reduce(0.0, +)
        //let spacing = scales.isEmpty ? 0.0 : Double(scales.count - 1) * 0.1
        return scalesHeight // + spacing
    }
    
    /// Computes the total height of all scales using a configuration-aware spacing rule.
    ///
    /// - Parameter spacingProvider: A closure that returns the spacing, in points,
    ///   between two adjacent scales. Callers can pass a function that mirrors the
    ///   logic of `PDFExportConfiguration.spacingBetweenScales` to ensure that the
    ///   computed total height matches the actual rendered spacing (including any
    ///   special cases such as extra spacing for C/D scales).
    /// - Returns: The sum of all scale heights plus the spacing between each adjacent
    ///   pair of scales as defined by `spacingProvider`.
    func totalScalesHeight(
        spacingProvider: (_ upperScale: GeneratedScale, _ lowerScale: GeneratedScale) -> Distance
    ) -> Distance {
        let scalesHeight = scales.map { $0.definition.height }.reduce(0.0, +)
        
        guard scales.count > 1 else {
            return scalesHeight
        }
        
        let adjacentPairs = zip(scales, scales.dropFirst())
        let totalSpacing = adjacentPairs
            .map { upper, lower in spacingProvider(upper, lower) }
            .reduce(0.0, +)
        
        return scalesHeight + totalSpacing
    }
}

// MARK: - Protocol Conformance

extension Slide: ScaleContainer {}
extension Stator: ScaleContainer {}
