// File: TheElectricSlide/PDF/PDFExportConfiguration.swift

import Foundation
import SlideRuleCoreV3

/// Configuration for PDF export operation
struct PDFExportConfiguration: Sendable {
    /// Export size option
    enum Size: Sendable {
        case full      // 25 cm = 708.66 points (PostScript standard)
        case pocket    // 12.5 cm = 354.33 points
        
        var lengthInPoints: Distance {
            switch self {
            case .full: return 708.66   // 25 cm × 28.3465 points/cm
            case .pocket: return 354.33 // 12.5 cm × 28.3465 points/cm
            }
        }
    }
    
    /// Which side(s) to export
    enum ExportSide: Sendable {
        case frontOnly
        case backOnly
        case both  // front and back on separate pages
    }
    
    // MARK: - Properties
    
    let size: Size
    let side: ExportSide
    let slideRule: SlideRule
    let slideRuleName: String
    
    // Margins (in points)
    let topMargin: Distance
    let bottomMargin: Distance
    let leftMargin: Distance
    let rightMargin: Distance
    
    // PDF metadata
    let title: String
    let author: String
    let creator: String
    
    // MARK: - Computed Properties
    
    /// Total width of PDF page (17 inches in landscape)
    var pageWidth: Distance { 1224.0 }
    
    /// Total height of PDF page (11 inches in landscape)
    var pageHeight: Distance { 792.0 }
    
    /// Scale drawing area width (excluding margins)
    var scaleDrawingWidth: Distance {
        return size.lengthInPoints
    }

    /// Horizontal offset to center the content
    var contentOffsetX: Distance {
        (pageWidth - scaleDrawingWidth) / 2
    }

    /// Calculate spacing between scales (PostScript-based logic)
    /// C and D scales get 1-2mm extra spacing; others equally spaced at standard 4pt
    func spacingBetweenScales(_ scale1: GeneratedScale, _ scale2: GeneratedScale) -> Distance {
        let standardSpacing: Distance = 4.0 // ~1.4mm
        let extraSpacing: Distance = 5.67   // ~2mm in points (2mm * 2.83465)
        
        // Check if either scale is C or D (apply extra spacing)
        let scale1Name = scale1.definition.name
        let scale2Name = scale2.definition.name
        
        if scale1Name == "C" || scale1Name == "D" || scale2Name == "C" || scale2Name == "D" {
            return standardSpacing + extraSpacing // Total ~3.4mm
        }
        
        return standardSpacing
    }
    
    /// Calculate spacing between components (different physical parts)
    /// Back-to-back scales (same component, opposite tick directions): NO GAP
    /// Different components (stator-slide-stator): 2pt gap for cutting guide
    func spacingBetweenComponents() -> Distance {
        return 2.0 // 2pt gap for cutting guide between different components
    }

    /// Calculate total height for a given component container
    func totalHeight<T: ScaleContainer>(for component: T) -> Distance {
        let scalesHeight = component.totalScalesHeight
        var spacingHeight: Distance = 0.0
        
        // Calculate spacing based on scale pairs
        for i in 0..<(component.scales.count - 1) {
            spacingHeight += spacingBetweenScales(component.scales[i], component.scales[i + 1])
        }
        
        return scalesHeight + spacingHeight
    }

    /// Calculate total height for the entire rule side
    func totalRuleHeight(for side: ExportSide) -> Distance {
        let componentSpacing = spacingBetweenComponents()
        
        switch side {
        case .frontOnly:
            return totalHeight(for: slideRule.frontTopStator) +
                   totalHeight(for: slideRule.frontSlide) +
                   totalHeight(for: slideRule.frontBottomStator) +
                   (componentSpacing * 2) // Two gaps: between top stator-slide and slide-bottom stator
        case .backOnly:
            guard let top = slideRule.backTopStator,
                  let slide = slideRule.backSlide,
                  let bottom = slideRule.backBottomStator else { return 0 }
            return totalHeight(for: top) +
                   totalHeight(for: slide) +
                   totalHeight(for: bottom) +
                   (componentSpacing * 2)
        case .both:
            return totalRuleHeight(for: .frontOnly) // Use front as reference
        }
    }
    // MARK: - Initialization
    
    init(
        size: Size = .full,
        side: ExportSide = .frontOnly,
        slideRule: SlideRule,
        slideRuleName: String,
        topMargin: Distance = 36,
        bottomMargin: Distance = 36,
        leftMargin: Distance = 72,
        rightMargin: Distance = 72,
        author: String = "TheElectricSlide"
    ) {
        self.size = size
        self.side = side
        self.slideRule = slideRule
        self.slideRuleName = slideRuleName
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
        self.leftMargin = leftMargin
        self.rightMargin = rightMargin
        
        // PDF metadata
        self.title = "\(slideRuleName) - \(size == .full ? "Full Size" : "Pocket")"
        self.author = author
        self.creator = "TheElectricSlide v1.0"
    }
}
