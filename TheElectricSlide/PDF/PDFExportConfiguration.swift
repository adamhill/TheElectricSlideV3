// File: TheElectricSlide/PDF/PDFExportConfiguration.swift

import Foundation
import SlideRuleCoreV3

/// Configuration for PDF export operation
struct PDFExportConfiguration: Sendable {
    /// Export size option
    enum Size: Sendable {
        case full      // 9.84" = 708 points
        case pocket    // 4.92" = 354 points
        
        var lengthInPoints: Distance {
            switch self {
            case .full: return 708.0    // 9.84 inches × 72
            case .pocket: return 354.0  // 4.92 inches × 72
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
    
    /// Total width of PDF page
    /// Total width of PDF page (11 inches)
    var pageWidth: Distance { 792.0 }
    
    /// Total height of PDF page (17 inches)
    var pageHeight: Distance { 1224.0 }
    
    /// Scale drawing area width (excluding margins)
    var scaleDrawingWidth: Distance {
        return size.lengthInPoints
    }

    /// Horizontal offset to center the content
    var contentOffsetX: Distance {
        (pageWidth - scaleDrawingWidth) / 2
    }

    /// Calculate total height for a given component container
    func totalHeight<T: ScaleContainer>(for component: T) -> Distance {
        let scalesHeight = component.totalScalesHeight
        let spacingHeight = Distance(max(0, component.scales.count - 1)) * 4.0
        return scalesHeight + spacingHeight
    }

    /// Calculate total height for the entire rule side
    func totalRuleHeight(for side: ExportSide) -> Distance {
        switch side {
        case .frontOnly:
            return totalHeight(for: slideRule.frontTopStator) +
                   totalHeight(for: slideRule.frontSlide) +
                   totalHeight(for: slideRule.frontBottomStator) +
                   8.0 // Spacing between components (2 * 4pt)
        case .backOnly:
            guard let top = slideRule.backTopStator,
                  let slide = slideRule.backSlide,
                  let bottom = slideRule.backBottomStator else { return 0 }
            return totalHeight(for: top) +
                   totalHeight(for: slide) +
                   totalHeight(for: bottom) +
                   8.0
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
