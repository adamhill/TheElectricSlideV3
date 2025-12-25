import SwiftUI

/// Comprehensive color scheme definitions for major slide rule manufacturers (1950-1976)
/// Each scheme captures the authentic visual identity of historical instruments
enum SlideRuleManufacturer: String, CaseIterable, Identifiable {
    case pickett
    case faberCastell
    case keuffelEsser
    case hemmi
    case aristo
    case nestler
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pickett: return "Pickett"
        case .faberCastell: return "Faber-Castell"
        case .keuffelEsser: return "Keuffel & Esser"
        case .hemmi: return "Hemmi (Sun)"
        case .aristo: return "Aristo"
        case .nestler: return "Nestler"
        }
    }
    
    var countryOfOrigin: String {
        switch self {
        case .pickett: return "USA"
        case .faberCastell: return "Germany"
        case .keuffelEsser: return "USA"
        case .hemmi: return "Japan"
        case .aristo: return "Germany"
        case .nestler: return "Germany"
        }
    }
    
    var colorScheme: SlideRuleColorScheme {
        switch self {
        case .pickett: return .pickett
        case .faberCastell: return .faberCastell
        case .keuffelEsser: return .keuffelEsser
        case .hemmi: return .hemmi
        case .aristo: return .aristo
        case .nestler: return .nestler
        }
    }
}

/// Complete color scheme for authentic slide rule reproduction
struct SlideRuleColorScheme {
    // MARK: - Background Colors
    let primaryBackground: Color        // Main body/stator background
    let slideBackground: Color          // Slide (center) background
    let alternateBackground: Color?     // For aged/variant appearances
    
    // MARK: - Scale Highlighting
    let primaryHighlight: Color?        // Primary scale stripe (C, D, CF, DF)
    let secondaryHighlight: Color?      // Secondary scale stripe (A, B)
    let tertiaryHighlight: Color?       // Additional highlighting
    
    // MARK: - Marking Colors
    let standardMarkings: Color         // Default tick marks and labels
    let invertedMarkings: Color         // CI, DI, CIF, LL/n scales
    let specialMarkings: Color?         // Gauge marks, constants
    
    // MARK: - Label Colors
    let standardLabelColor: Color       // Scale names (left side)
    let invertedLabelColor: Color       // Inverted scale names
    let formulaColor: Color             // Right-side formulas (self-documenting)
    
    // MARK: - Branding Colors
    let brandingColor: Color            // Company logo, model numbers
    let accentColor: Color?             // Additional accent (cursor marks, etc.)
    
    // MARK: - Material Appearance
    let bodyMaterial: BodyMaterial
    let hasVisibleWoodGrain: Bool
    let cursorFrameColor: Color
    
    enum BodyMaterial: String {
        case aluminum           // Pickett
        case plastic            // Faber-Castell, Aristo, late Nestler
        case celluloidOnWood    // K&E (mahogany)
        case celluloidOnBamboo  // Hemmi
        case celluloidOnMixed   // Early Nestler
    }
}

// MARK: - Manufacturer-Specific Color Schemes

extension SlideRuleColorScheme {
    
    // ═══════════════════════════════════════════════════════════════════
    // PICKETT - Eye-Saver Yellow System (1959+)
    // ═══════════════════════════════════════════════════════════════════
    /// Pickett's distinctive "Eye-Saver" yellow at 5600 Angstroms (560nm)
    /// Designed to reduce eye strain during extended calculation sessions
    static let pickett = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.95, green: 0.90, blue: 0.40),    // Eye-Saver Yellow
        slideBackground: Color(red: 0.95, green: 0.90, blue: 0.40),
        alternateBackground: Color(red: 0.92, green: 0.92, blue: 0.90),  // Traditional white/aluminum
        primaryHighlight: nil,  // Pickett uses solid color, no stripes
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color.black,  // Pickett didn't use red for inverted
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color.black,
        formulaColor: Color.black,
        brandingColor: Color.black,
        accentColor: nil,
        bodyMaterial: .aluminum,
        hasVisibleWoodGrain: false,
        cursorFrameColor: Color(red: 0.3, green: 0.3, blue: 0.3)  // Nylon/plastic
    )
    
    /// Pickett Traditional (white/natural aluminum) variant
    static let pickettTraditional = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.95, green: 0.95, blue: 0.93),
        slideBackground: Color(red: 0.95, green: 0.95, blue: 0.93),
        alternateBackground: nil,
        primaryHighlight: nil,
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color.black,
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color.black,
        formulaColor: Color.black,
        brandingColor: Color.black,
        accentColor: nil,
        bodyMaterial: .aluminum,
        hasVisibleWoodGrain: false,
        cursorFrameColor: Color(red: 0.3, green: 0.3, blue: 0.3)
    )
    
    // ═══════════════════════════════════════════════════════════════════
    // FABER-CASTELL - Mint Green & Pale Blue System
    // ═══════════════════════════════════════════════════════════════════
    /// Faber-Castell's signature color-coded scale highlighting
    /// Mint green for primary scales (C, CF, D, DF), pale blue for A, B
    static let faberCastell = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.98, green: 0.97, blue: 0.94),    // Ivory/cream plastic
        slideBackground: Color(red: 0.98, green: 0.97, blue: 0.94),
        alternateBackground: nil,
        primaryHighlight: Color(red: 0.75, green: 0.95, blue: 0.80),     // Signature mint green
        secondaryHighlight: Color(red: 0.85, green: 0.92, blue: 0.98),   // Pale blue
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color(red: 0.75, green: 0.10, blue: 0.10),     // Red for CI, DI, CIF
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.75, green: 0.10, blue: 0.10),   // Red labels
        formulaColor: Color.black,                                        // Self-documenting formulas
        brandingColor: Color(red: 0.20, green: 0.45, blue: 0.25),        // Castell green
        accentColor: Color(red: 0.75, green: 0.65, blue: 0.35),          // Gold anodized braces
        bodyMaterial: .plastic,
        hasVisibleWoodGrain: false,
        cursorFrameColor: Color(red: 0.75, green: 0.65, blue: 0.35)      // Gold anodized
    )
    
    // ═══════════════════════════════════════════════════════════════════
    // KEUFFEL & ESSER - Ivory Celluloid on Mahogany
    // ═══════════════════════════════════════════════════════════════════
    /// K&E's classic American style with ivory celluloid facing
    /// Red used for branding, model numbers, and inverted scale numbers
    static let keuffelEsser = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.98, green: 0.96, blue: 0.90),    // Ivory celluloid (new)
        slideBackground: Color(red: 0.98, green: 0.96, blue: 0.90),
        alternateBackground: Color(red: 0.95, green: 0.90, blue: 0.75),  // Aged/yellowed
        primaryHighlight: nil,  // K&E didn't use scale stripes
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color(red: 0.70, green: 0.10, blue: 0.10),     // Red numbers on CI, etc.
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.70, green: 0.10, blue: 0.10),
        formulaColor: Color.black,
        brandingColor: Color(red: 0.70, green: 0.10, blue: 0.10),        // K&E red branding
        accentColor: nil,
        bodyMaterial: .celluloidOnWood,
        hasVisibleWoodGrain: true,                                        // Mahogany edges visible
        cursorFrameColor: Color(red: 0.45, green: 0.25, blue: 0.15)      // Mahogany
    )
    
    /// K&E aged appearance (yellowed celluloid)
    static let keuffelEsserAged = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.95, green: 0.90, blue: 0.75),
        slideBackground: Color(red: 0.95, green: 0.90, blue: 0.75),
        alternateBackground: nil,
        primaryHighlight: nil,
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color(red: 0.65, green: 0.12, blue: 0.12),
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.65, green: 0.12, blue: 0.12),
        formulaColor: Color.black,
        brandingColor: Color(red: 0.65, green: 0.12, blue: 0.12),
        accentColor: nil,
        bodyMaterial: .celluloidOnWood,
        hasVisibleWoodGrain: true,
        cursorFrameColor: Color(red: 0.40, green: 0.22, blue: 0.12)
    )
    
    // ═══════════════════════════════════════════════════════════════════
    // HEMMI (SUN) - Navy & Red on White Celluloid/Bamboo
    // ═══════════════════════════════════════════════════════════════════
    /// Hemmi's distinctive Japanese style with navy blue standard scales
    /// Red for all inverted and reciprocal log-log scales
    static let hemmi = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.98, green: 0.97, blue: 0.95),    // White celluloid
        slideBackground: Color(red: 0.98, green: 0.97, blue: 0.95),
        alternateBackground: Color(red: 0.90, green: 0.82, blue: 0.65),  // Exposed bamboo
        primaryHighlight: nil,  // Hemmi bamboo rules typically no stripes
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color(red: 0.10, green: 0.15, blue: 0.35),     // Navy blue
        invertedMarkings: Color(red: 0.75, green: 0.12, blue: 0.12),     // Red
        specialMarkings: Color(red: 0.10, green: 0.15, blue: 0.35),
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.75, green: 0.12, blue: 0.12),
        formulaColor: Color.black,
        brandingColor: Color.black,                                       // "SUN HEMMI" in black
        accentColor: Color(red: 0.75, green: 0.12, blue: 0.12),          // Red Post logo
        bodyMaterial: .celluloidOnBamboo,
        hasVisibleWoodGrain: false,                                       // Bamboo usually covered
        cursorFrameColor: Color(red: 0.50, green: 0.50, blue: 0.52)      // Metal frame
    )
    
    /// Hemmi plastic models (late 1960s-1970s) with blue highlighting
    static let hemmiPlastic = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.96, green: 0.96, blue: 0.96),
        slideBackground: Color(red: 0.96, green: 0.96, blue: 0.96),
        alternateBackground: nil,
        primaryHighlight: Color(red: 0.80, green: 0.88, blue: 0.95),     // Light blue
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color(red: 0.10, green: 0.15, blue: 0.35),
        invertedMarkings: Color(red: 0.75, green: 0.12, blue: 0.12),
        specialMarkings: Color(red: 0.10, green: 0.15, blue: 0.35),
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.75, green: 0.12, blue: 0.12),
        formulaColor: Color.black,
        brandingColor: Color.black,
        accentColor: nil,
        bodyMaterial: .plastic,
        hasVisibleWoodGrain: false,
        cursorFrameColor: Color(red: 0.30, green: 0.30, blue: 0.32)
    )
    
    // ═══════════════════════════════════════════════════════════════════
    // ARISTO (Dennert & Pape) - Yellow Highlight System
    // ═══════════════════════════════════════════════════════════════════
    /// Aristo's trademark yellow scale stripes matching their packaging
    static let aristo = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.97, green: 0.97, blue: 0.95),    // White plastic
        slideBackground: Color(red: 0.97, green: 0.97, blue: 0.95),
        alternateBackground: nil,
        primaryHighlight: Color(red: 0.98, green: 0.92, blue: 0.65),     // Aristo yellow
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color(red: 0.75, green: 0.10, blue: 0.10),
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.75, green: 0.10, blue: 0.10),
        formulaColor: Color.black,
        brandingColor: Color(red: 0.20, green: 0.35, blue: 0.55),        // Aristo blue
        accentColor: Color(red: 0.98, green: 0.92, blue: 0.65),
        bodyMaterial: .plastic,                                           // Astralon/Aristopal PVC
        hasVisibleWoodGrain: false,
        cursorFrameColor: Color(red: 0.35, green: 0.35, blue: 0.38)
    )
    
    // ═══════════════════════════════════════════════════════════════════
    // NESTLER - Blue-Green (Teal) Highlight System
    // ═══════════════════════════════════════════════════════════════════
    /// Nestler's distinctive blue-green scale highlighting
    static let nestler = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.97, green: 0.96, blue: 0.93),    // Ivory
        slideBackground: Color(red: 0.97, green: 0.96, blue: 0.93),
        alternateBackground: nil,
        primaryHighlight: Color(red: 0.45, green: 0.75, blue: 0.70),     // Nestler teal/blue-green
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color(red: 0.75, green: 0.10, blue: 0.10),
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.75, green: 0.10, blue: 0.10),
        formulaColor: Color.black,
        brandingColor: Color.black,
        accentColor: nil,
        bodyMaterial: .plastic,                                           // Later models
        hasVisibleWoodGrain: false,
        cursorFrameColor: Color(red: 0.50, green: 0.50, blue: 0.52)
    )
    
    /// Nestler wood/celluloid models (pre-1960s)
    static let nestlerWood = SlideRuleColorScheme(
        primaryBackground: Color(red: 0.96, green: 0.94, blue: 0.88),
        slideBackground: Color(red: 0.96, green: 0.94, blue: 0.88),
        alternateBackground: nil,
        primaryHighlight: Color(red: 0.45, green: 0.75, blue: 0.70),
        secondaryHighlight: nil,
        tertiaryHighlight: nil,
        standardMarkings: Color.black,
        invertedMarkings: Color(red: 0.75, green: 0.10, blue: 0.10),
        specialMarkings: Color.black,
        standardLabelColor: Color.black,
        invertedLabelColor: Color(red: 0.75, green: 0.10, blue: 0.10),
        formulaColor: Color.black,
        brandingColor: Color.black,
        accentColor: nil,
        bodyMaterial: .celluloidOnMixed,
        hasVisibleWoodGrain: true,
        cursorFrameColor: Color(red: 0.50, green: 0.50, blue: 0.52)
    )
}

// MARK: - Convenience Extensions

extension SlideRuleColorScheme {
    /// Returns the appropriate color for a scale based on whether it's inverted
    func markingColor(forInvertedScale isInverted: Bool) -> Color {
        isInverted ? invertedMarkings : standardMarkings
    }
    
    /// Returns the appropriate label color for a scale
    func labelColor(forInvertedScale isInverted: Bool) -> Color {
        isInverted ? invertedLabelColor : standardLabelColor
    }
    
    /// Returns background color for a specific scale type
    func backgroundColor(forPrimaryScale isPrimary: Bool, isSecondary: Bool = false) -> Color {
        if isPrimary, let highlight = primaryHighlight {
            return highlight
        } else if isSecondary, let highlight = secondaryHighlight {
            return highlight
        }
        return primaryBackground
    }
    
    /// Creates a 4-stop vertical gradient for scale highlighting
    /// Simulates the authentic "stripe" appearance on historical rules
    /// 
    /// Gradient structure (top to bottom):
    /// - Stop 1 (0.0): Highlight color at 40% opacity (subtle edge blend)
    /// - Stop 2 (0.12): Highlight color at 85% opacity (ramp up)
    /// - Stop 3 (0.88): Highlight color at 85% opacity (main body)
    /// - Stop 4 (1.0): Highlight color at 40% opacity (subtle edge blend)
    ///
    /// - Parameter scaleName: The canonical name of the scale (e.g., "C", "D", "A", "B")
    /// - Returns: A LinearGradient if the scale should be highlighted, nil otherwise
    func scaleBackgroundGradient(for scaleName: String) -> LinearGradient? {
        let highlightColor: Color?
        
        if ScaleColorMapping.primaryHighlightScales.contains(scaleName) {
            highlightColor = primaryHighlight
        } else if ScaleColorMapping.secondaryHighlightScales.contains(scaleName) {
            highlightColor = secondaryHighlight
        } else {
            return nil  // No gradient for non-highlighted scales
        }
        
        guard let color = highlightColor else { return nil }
        
        return LinearGradient(
            stops: [
                .init(color: color.opacity(0.4), location: 0.0),
                .init(color: color.opacity(0.85), location: 0.12),
                .init(color: color.opacity(0.85), location: 0.88),
                .init(color: color.opacity(0.4), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Creates a precision-intensity gradient for scale highlighting
    /// Used when precision mode is active - colors are more saturated/intense
    /// 
    /// Gradient structure (top to bottom) - MUCH HIGHER OPACITY than normal:
    /// - Stop 1 (0.0): Highlight color at 80% opacity (strong visible edge)
    /// - Stop 2 (0.12): Highlight color at 100% opacity (full saturation)
    /// - Stop 3 (0.88): Highlight color at 100% opacity (full saturation)
    /// - Stop 4 (1.0): Highlight color at 80% opacity (strong visible edge)
    ///
    /// - Parameter scaleName: The canonical name of the scale (e.g., "C", "D", "A", "B")
    /// - Returns: A LinearGradient with intensified colors if the scale should be highlighted, nil otherwise
    func precisionScaleBackgroundGradient(for scaleName: String) -> LinearGradient? {
        let highlightColor: Color?
        
        if ScaleColorMapping.primaryHighlightScales.contains(scaleName) {
            highlightColor = primaryHighlight
        } else if ScaleColorMapping.secondaryHighlightScales.contains(scaleName) {
            highlightColor = secondaryHighlight
        } else {
            return nil  // No gradient for non-highlighted scales
        }
        
        guard let color = highlightColor else { return nil }
        
        // Precision mode: MAXIMUM opacity values for very intense/saturated appearance
        return LinearGradient(
            stops: [
                .init(color: color.opacity(0.8), location: 0.0),
                .init(color: color.opacity(1.0), location: 0.12),
                .init(color: color.opacity(1.0), location: 0.88),
                .init(color: color.opacity(0.8), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Whether this color scheme has any scale highlighting colors defined
    /// Used to determine if precision mode should use color intensification or an overlay
    var hasScaleHighlights: Bool {
        primaryHighlight != nil || secondaryHighlight != nil
    }
}

// MARK: - Scale-Specific Color Application

/// Defines which scales receive which color treatments
struct ScaleColorMapping {
    /// Scales that receive primary highlighting (mint green on F-C, yellow on Aristo)
    static let primaryHighlightScales: Set<String> = ["C", "CF", "D", "DF"]
    
    /// Scales that receive secondary highlighting (pale blue on F-C)
    static let secondaryHighlightScales: Set<String> = ["A", "B"]
    
    /// Scales with inverted (red) labeling - industry standard
    static let invertedScales: Set<String> = [
        "CI", "DI", "CIF", "DIF", "BI",
        "LL/0", "LL/1", "LL/2", "LL/3",
        "LL00", "LL01", "LL02", "LL03"
    ]
    
    /// Returns whether a scale should use inverted colors
    static func isInverted(_ scaleName: String) -> Bool {
        // Check exact match first
        if invertedScales.contains(scaleName) { return true }
        
        // Check for CI, DI patterns
        if scaleName.hasSuffix("I") && scaleName.count <= 3 { return true }
        
        // Check for reciprocal log-log scales (LL/n pattern)
        if scaleName.hasPrefix("LL/") || scaleName.hasPrefix("LL0") { return true }
        
        return false
    }
}