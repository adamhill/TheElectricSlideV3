import CoreGraphics

/// Centralized font sizing configuration for slide rule rendering
public struct FontSizeConfiguration {
    /// Tick relative length threshold for major ticks
    public static let majorTickThreshold: Double = 0.9
    
    /// Tick relative length threshold for medium ticks
    public static let mediumTickThreshold: Double = 0.7
    
    /// Tick relative length threshold for minor ticks
    public static let minorTickThreshold: Double = 0.4
    
    // On-screen font sizes (optimized for digital viewing)
    public static let screenMajorFontSize: CGFloat = 8.0
    public static let screenMediumFontSize: CGFloat = 6.5
    public static let screenMinorFontSize: CGFloat = 5.0
    
    // PDF/PostScript font sizes (optimized for printing)
    public static let pdfMajorFontSize: CGFloat = 4.5   // PostScript LargeF
    public static let pdfMediumFontSize: CGFloat = 3.8  // PostScript MedF
    public static let pdfMinorFontSize: CGFloat = 3.2   // PostScript SmallF
}
