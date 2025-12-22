//
//  PDFExportConfiguration.swift
//  TheElectricSlide
//
//  Configurable dimensions for PDF export of slide rule scales.
//  All measurements in points (72 points = 1 inch).
//
//  Reference: PostScript engine uses:
//  - /inch {72 mul} def
//  - /cm {28.3464567 mul} def
//  - /mm {2.83464567 mul} def
//

import Foundation
import CoreGraphics

// MARK: - Unit Conversion Helpers

/// Points per inch (standard PDF/PostScript unit)
public let kPointsPerInch: CGFloat = 72.0

/// Points per centimeter
public let kPointsPerCM: CGFloat = 28.3464567

/// Points per millimeter
public let kPointsPerMM: CGFloat = 2.83464567

/// Convert inches to points
public func inches(_ value: CGFloat) -> CGFloat {
    value * kPointsPerInch
}

/// Convert millimeters to points
public func mm(_ value: CGFloat) -> CGFloat {
    value * kPointsPerMM
}

/// Convert centimeters to points
public func cm(_ value: CGFloat) -> CGFloat {
    value * kPointsPerCM
}

// MARK: - Rule Size

/// Predefined slide rule scale lengths
public enum RuleSize: String, CaseIterable, Identifiable, Sendable {
    case fullSize = "Full Size (10\")"
    case pocket = "Pocket (6\")"
    
    public var id: String { rawValue }
    
    /// Scale length in points (logarithmic portion only, excludes margins)
    public var scaleLength: CGFloat {
        switch self {
        case .fullSize: return inches(10)  // 720pt
        case .pocket: return inches(6)     // 432pt
        }
    }
    
    /// Display name for UI
    public var displayName: String {
        switch self {
        case .fullSize: return "Full Size (10\")"
        case .pocket: return "Pocket (6\")"
        }
    }
    
    /// Short name for filename suffix
    public var filenameSuffix: String {
        switch self {
        case .fullSize: return "10in"
        case .pocket: return "6in"
        }
    }
}

// MARK: - PDF Export Configuration

/// Complete configuration for PDF export dimensions and options
public struct PDFExportConfiguration: Sendable {
    
    // MARK: - Page Dimensions
    
    /// Page width in points (default: 11" = 792pt for letter landscape)
    public let pageWidth: CGFloat
    
    /// Page height in points (default: 8.5" = 612pt for letter landscape)
    public let pageHeight: CGFloat
    
    // MARK: - Scale Dimensions
    
    /// Length of the logarithmic scale portion in points
    public let scaleLength: CGFloat
    
    // MARK: - Margins
    
    /// Left margin for scale names (points)
    public let leftMargin: CGFloat
    
    /// Right margin for formulas (points)
    public let rightMargin: CGFloat
    
    /// Top page margin (points)
    public let topMargin: CGFloat
    
    /// Bottom page margin (points)
    public let bottomMargin: CGFloat
    
    /// Gap between front and back sides when both on same page (points)
    public let gapBetweenSides: CGFloat
    
    // MARK: - Crop Mark Settings
    
    /// Whether to draw crop marks for cutting guides
    public let showCropMarks: Bool
    
    /// Length of each crop mark line (points)
    public let cropMarkLength: CGFloat
    
    /// Gap between content edge and crop mark start (points)
    public let cropMarkOffset: CGFloat
    
    /// Diameter of registration mark circles (points)
    public let registrationMarkSize: CGFloat
    
    // MARK: - Font Settings
    
    /// Scale factor for fonts (print may need larger fonts than screen)
    public let fontScaleFactor: CGFloat
    
    /// Base font size for major tick labels (points)
    public let majorLabelFontSize: CGFloat
    
    /// Base font size for medium tick labels (points)
    public let mediumLabelFontSize: CGFloat
    
    /// Base font size for minor tick labels (points)
    public let minorLabelFontSize: CGFloat
    
    /// Font size for scale names in left margin (points)
    public let scaleNameFontSize: CGFloat
    
    /// Font size for formulas in right margin (points)
    public let formulaFontSize: CGFloat
    
    // MARK: - Line Settings
    
    /// Line width for baseline (points)
    public let baselineWidth: CGFloat
    
    /// Line width multiplier for ticks (applied to tick.style.lineWidth)
    public let tickLineWidthMultiplier: CGFloat
    
    // MARK: - Scale Height Ratios
    
    /// Height per scale row as fraction of total stator/slide height
    /// Actual height = (statorMM or slideMM in points) / number of scales
    public let minScaleHeight: CGFloat
    
    /// Maximum scale height to prevent oversized labels
    public let maxScaleHeight: CGFloat
    
    // MARK: - Initializer
    
    public init(
        pageWidth: CGFloat = inches(17),
        pageHeight: CGFloat = inches(11),
        scaleLength: CGFloat = inches(10),
        leftMargin: CGFloat = inches(0.75),
        rightMargin: CGFloat = inches(0.75),
        topMargin: CGFloat = inches(0.5),
        bottomMargin: CGFloat = inches(0.5),
        gapBetweenSides: CGFloat = inches(0.75),
        showCropMarks: Bool = true,
        cropMarkLength: CGFloat = inches(0.25),
        cropMarkOffset: CGFloat = inches(0.125),
        registrationMarkSize: CGFloat = 12,
        fontScaleFactor: CGFloat = 1.0,
        majorLabelFontSize: CGFloat = 8.0,
        mediumLabelFontSize: CGFloat = 6.5,
        minorLabelFontSize: CGFloat = 5.0,
        scaleNameFontSize: CGFloat = 9.0,
        formulaFontSize: CGFloat = 7.0,
        baselineWidth: CGFloat = 1.5,
        tickLineWidthMultiplier: CGFloat = 1.0,
        minScaleHeight: CGFloat = mm(8),
        maxScaleHeight: CGFloat = mm(20)
    ) {
        self.pageWidth = pageWidth
        self.pageHeight = pageHeight
        self.scaleLength = scaleLength
        self.leftMargin = leftMargin
        self.rightMargin = rightMargin
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
        self.gapBetweenSides = gapBetweenSides
        self.showCropMarks = showCropMarks
        self.cropMarkLength = cropMarkLength
        self.cropMarkOffset = cropMarkOffset
        self.registrationMarkSize = registrationMarkSize
        self.fontScaleFactor = fontScaleFactor
        self.majorLabelFontSize = majorLabelFontSize
        self.mediumLabelFontSize = mediumLabelFontSize
        self.minorLabelFontSize = minorLabelFontSize
        self.scaleNameFontSize = scaleNameFontSize
        self.formulaFontSize = formulaFontSize
        self.baselineWidth = baselineWidth
        self.tickLineWidthMultiplier = tickLineWidthMultiplier
        self.minScaleHeight = minScaleHeight
        self.maxScaleHeight = maxScaleHeight
    }
    
    // MARK: - Computed Properties
    
    /// Total content width (margins + scale)
    public var contentWidth: CGFloat {
        leftMargin + scaleLength + rightMargin
    }
    
    /// Available height for rule content (excludes page margins and gap)
    public var availableContentHeight: CGFloat {
        pageHeight - topMargin - bottomMargin - gapBetweenSides
    }
    
    /// Height available for each side (front/back) when both are on one page
    public var heightPerSide: CGFloat {
        availableContentHeight / 2
    }
    
    // MARK: - Presets
    
    /// Full-size slide rule (10" scales) on letter landscape
    public static let fullSize = PDFExportConfiguration(
        scaleLength: inches(10)
    )
    
    /// Pocket slide rule (6" scales) on letter landscape
    public static let pocket = PDFExportConfiguration(
        scaleLength: inches(6),
        leftMargin: inches(0.75),  // More margin space for pocket
        rightMargin: inches(0.75)
    )
    
    /// Create configuration for a specific rule size
    public static func forRuleSize(_ size: RuleSize, showCropMarks: Bool = true) -> PDFExportConfiguration {
        switch size {
        case .fullSize:
            return PDFExportConfiguration(
                scaleLength: size.scaleLength,
                showCropMarks: showCropMarks
            )
        case .pocket:
            return PDFExportConfiguration(
                scaleLength: size.scaleLength,
                leftMargin: inches(0.75),
                rightMargin: inches(0.75),
                showCropMarks: showCropMarks
            )
        }
    }
    
    // MARK: - Font Size Helpers
    
    /// Get font size for a tick based on its relative length
    public func fontSizeForTick(_ relativeLength: Double) -> CGFloat {
        let baseSize: CGFloat
        if relativeLength >= 0.9 {
            baseSize = majorLabelFontSize
        } else if relativeLength >= 0.7 {
            baseSize = mediumLabelFontSize
        } else if relativeLength >= 0.4 {
            baseSize = minorLabelFontSize
        } else {
            return 0  // No label for tiny ticks
        }
        return baseSize * fontScaleFactor
    }
}

// MARK: - PDF Export Error

/// Errors that can occur during PDF export
public enum PDFExportError: Error, LocalizedError, Sendable {
    case parseError(String)
    case renderingError(String)
    case fileSystemError(String)
    case insufficientSpace(required: CGFloat, available: CGFloat)
    case noScalesFound
    case contextCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .parseError(let message):
            return "Failed to parse slide rule definition: \(message)"
        case .renderingError(let message):
            return "Failed to render PDF: \(message)"
        case .fileSystemError(let message):
            return "File operation failed: \(message)"
        case .insufficientSpace(let required, let available):
            return String(format: "Insufficient space: requires %.1fpt, only %.1fpt available", required, available)
        case .noScalesFound:
            return "No scales found in the slide rule definition"
        case .contextCreationFailed:
            return "Failed to create PDF graphics context"
        }
    }
}
