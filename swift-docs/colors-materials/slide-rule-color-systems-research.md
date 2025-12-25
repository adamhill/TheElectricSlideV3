# Slide Rule Color Systems: 1950s-1970s

## Research Summary for The Electric Slide App

This document catalogs the color systems, conventions, and technical specifications used by major slide rule manufacturers during the "golden age" of slide rule production (roughly 1950-1976). Understanding these color systems is essential for authentic digital reproduction.

---

## 1. Pickett: Eye-Saver Yellow System

### The Science Behind Eye-Saver Yellow

Pickett introduced their revolutionary "Eye-Saver" yellow coating in **1959**, becoming their trademark distinguishing feature.

**Technical Specifications:**
- **Wavelength**: 5600 Angstroms (560 nm)
- **Color designation**: Yellow-green
- **Scientific basis**: Chromatic aberration research establishing 560nm as optimal for "eye-ease"

**Marketing Claims (from original Pickett literature):**
> "Chromatic aberration tests establish that Angstrom '5600' is the point on the spectrum for optimum eye-ease. Pickett Eye-Saver yellow-green exactly duplicates this color value."

**Optical Theory:**
- Reds place the image behind the retina
- Blues place the image in front of the retina
- Eye-Saver "5600" places the image directly on the retina
- Absorbs actinic (UV) rays that produce "tired eyes"
- Reduces glare under all lighting conditions (sunlight, fluorescent, incandescent)

**Model Suffix Conventions:**
| Suffix | Meaning |
|--------|---------|
| `-ES` | Eye-Saver yellow coating |
| `-T` | "Traditional" white/natural aluminum |
| `N` prefix | Nylon cursor (introduced 1958) |

### Pickett Scale Markings

- **Primary scales**: Black lithographed markings
- **Special scales**: Red markings for inverted/reciprocal scales
- **Background**: Solid yellow (ES) or white (T) aluminum

### Implementation Colors (RGB approximations)

```swift
// Pickett Eye-Saver Yellow (560nm equivalent)
static let pickettEyeSaverYellow = Color(
    red: 0.95,
    green: 0.90,
    blue: 0.40
)

// Pickett Natural Aluminum
static let pickettNaturalAluminum = Color(
    red: 0.85,
    green: 0.85,
    blue: 0.87
)
```

---

## 2. Faber-Castell: Mint Green & Pale Blue System

### Signature Color Scheme

Faber-Castell is renowned for their distinctive scale highlighting system, particularly on premium models like the **2/83N Novo-Duplex**.

**Scale Background Colors:**
| Color | Scales Applied | Description |
|-------|----------------|-------------|
| Mint Green | C, CF, D, DF (primary multiplication scales) | Signature "Castell" trademark stripe |
| Pale Blue | A, B (square/square root scales) | Secondary highlighting |
| White/Ivory | All other scales | Base background |

**Scale Marking Colors:**
- **Black**: Standard scale labels and tick marks
- **Red**: Inverted/reciprocal scales (CI, DI, CIF, DIF, BI)

### Premium Features

- **Self-documenting scales**: Mathematical formula at right end of each scale
- **Gold anodized aluminum end braces**: Premium construction indicator
- **Two-color (red/black) scale markings**: Clear visual differentiation

### Implementation Colors (RGB approximations)

```swift
// Faber-Castell Mint Green (signature color)
static let faberCastellMintGreen = Color(
    red: 0.75,
    green: 0.95,
    blue: 0.80
)

// Faber-Castell Pale Blue
static let faberCastellPaleBlue = Color(
    red: 0.85,
    green: 0.92,
    blue: 0.98
)

// Faber-Castell Ivory/White base
static let faberCastellIvory = Color(
    red: 0.98,
    green: 0.97,
    blue: 0.94
)
```

---

## 3. Keuffel & Esser (K&E): Ivory Celluloid System

### Construction & Materials

K&E rules featured mahogany cores with **ivory-colored celluloid** facing, creating their characteristic warm cream appearance.

**Color Characteristics:**
- **New**: Bright ivory/white celluloid
- **Aged**: Yellowing over time (celluloid oxidation)
- **Base material**: Visible mahogany wood on edges and ends

### Scale Color Conventions

| Element | Color | Usage |
|---------|-------|-------|
| Model numbers | Red | Left end of slide (e.g., "4053-3") |
| Company logo | Red | "K&E" or "KEUFFEL & ESSER CO." |
| Patent text | Red | Patent numbers and dates |
| Standard scales | Black | All primary computation scales |
| Inverted scales | Red numbers | CI, DI, and similar reciprocal scales |

**Evolution Notes:**
- ~1930: Switched from serif to sans-serif fonts for scale labels
- 1936: Introduced thin frame to secure glass cursor
- 1949: "N" prefix adopted for updated models

### Implementation Colors

```swift
// K&E Ivory Celluloid (new condition)
static let keIvoryNew = Color(
    red: 0.98,
    green: 0.96,
    blue: 0.90
)

// K&E Ivory Celluloid (aged/patinated)
static let keIvoryAged = Color(
    red: 0.95,
    green: 0.90,
    blue: 0.75
)

// K&E Mahogany edge
static let keMahogany = Color(
    red: 0.45,
    green: 0.25,
    blue: 0.15
)

// K&E Red (labels, logos)
static let keRed = Color(
    red: 0.75,
    green: 0.10,
    blue: 0.10
)
```

---

## 4. Hemmi (Sun Hemmi): Bamboo & Celluloid System

### Materials & Construction

Hemmi pioneered the use of **bamboo** (Phyllostachys pubescens from Kyushu, Japan) with celluloid laminate:

- **Bamboo advantages**: Self-lubricating, dimensionally stable, humidity resistant
- **Celluloid**: White/ivory facing for scale engraving
- **Patent**: Japanese (1912), British (1917), American (1920)

### Scale Color Conventions

Hemmi used a consistent **red, navy (dark blue), and black** color system:

| Element | Color | Usage |
|---------|-------|-------|
| Standard scales | Navy/Dark Blue | Primary multiplication and trig scales |
| Inverted scales | Red | CI, CIF, LL/0, LL/1, LL/2, LL/3 |
| Special scales | Red or Navy | Varies by model |
| Scale labels | Black | Scale names at left end |

**Post-branded Hemmi rules (Versalog series):**
- Same color conventions as Hemmi-branded
- Post logo in red
- Navy used for non-inverted scales

### Late Plastic Models

Hemmi's later plastic models (1960s-1970s) introduced:
- Blue highlighting on some scales
- Two-tone plastic cases (blue/white)
- Maintained red/navy marking conventions

### Implementation Colors

```swift
// Hemmi White Celluloid
static let hemmiWhiteCelluloid = Color(
    red: 0.98,
    green: 0.97,
    blue: 0.95
)

// Hemmi Bamboo (exposed areas)
static let hemmiBamboo = Color(
    red: 0.90,
    green: 0.82,
    blue: 0.65
)

// Hemmi Navy Blue
static let hemmiNavy = Color(
    red: 0.10,
    green: 0.15,
    blue: 0.35
)

// Hemmi Red
static let hemmiRed = Color(
    red: 0.75,
    green: 0.12,
    blue: 0.12
)
```

---

## 5. Aristo (Dennert & Pape): Yellow Highlight System

### German Engineering Color Scheme

Aristo rules are noted for their **yellow** scale highlights, distinguishing them from Faber-Castell's green/blue system.

**Color Characteristics:**
- **Yellow stripe**: Primary scale highlighting
- **White background**: Base for all scales
- **Black/red markings**: Standard German convention

### Implementation Colors

```swift
// Aristo Yellow Highlight
static let aristoYellow = Color(
    red: 0.98,
    green: 0.92,
    blue: 0.65
)
```

---

## 6. Nestler: Blue-Green Highlight System

### German Color Conventions

Nestler used a distinctive **blue-green** (teal) highlighting system:

- **Blue-green stripes**: Scale background highlighting
- **White/ivory base**: Standard celluloid on wood core
- **Black markings**: Primary scale divisions

### Implementation Colors

```swift
// Nestler Blue-Green
static let nestlerBlueGreen = Color(
    red: 0.45,
    green: 0.75,
    blue: 0.70
)
```

---

## 7. Universal Color Conventions

### Red for Inverted/Reciprocal Scales

**Industry-wide standard**: Red coloring indicates scales that run in the opposite direction or represent reciprocal values.

| Scale | Meaning | Red Colored By |
|-------|---------|----------------|
| CI | C Inverted (1/x) | All manufacturers |
| DI | D Inverted (1/x) | All manufacturers |
| CIF | CF Inverted | All manufacturers |
| DIF | DF Inverted | Some manufacturers |
| BI | B Inverted | Some manufacturers |
| LL/0 - LL/3 | Reciprocal log-log | Hemmi, Post |

### Gauge Mark Colors

Special gauge marks (π, e, √2, etc.) typically rendered:
- **Primary ticks**: Same color as scale (black)
- **Special emphasis**: Sometimes in red or alternate color
- **Unique styling**: Longer, thicker, or diamond-shaped ticks

---

## 8. Implementation Recommendations

### Color Palette Structure

```swift
enum SlideRuleManufacturer {
    case pickett
    case faberCastell
    case keuffelEsser
    case hemmi
    case aristo
    case nestler
    
    var primaryBackground: Color { ... }
    var highlightColor: Color? { ... }
    var secondaryHighlight: Color? { ... }
    var standardMarkings: Color { ... }
    var invertedMarkings: Color { ... }
    var labelColor: Color { ... }
}
```

### Historical Accuracy Notes

1. **Aging effects**: Period-authentic reproductions should consider aged appearances
   - Celluloid yellowing
   - Ink fading
   - Metal patina

2. **Manufacturing variations**: Slight color variations existed within production runs

3. **Regional differences**: Same models sometimes had regional color variations

4. **Restoration vs. original**: Many surviving specimens have been cleaned, affecting apparent colors

---

## 9. Color Specification Summary Table

| Manufacturer | Base | Highlight 1 | Highlight 2 | Standard Marks | Inverted Marks |
|--------------|------|-------------|-------------|----------------|----------------|
| **Pickett** | Yellow (ES) / Aluminum (T) | — | — | Black | Black |
| **Faber-Castell** | Ivory | Mint Green | Pale Blue | Black | Red |
| **K&E** | Ivory Celluloid | — | — | Black | Red |
| **Hemmi** | White Celluloid | — | — | Navy/Black | Red |
| **Aristo** | White | Yellow | — | Black | Red |
| **Nestler** | White | Blue-Green | — | Black | Red |

---

## 10. Sources & References

### Project Knowledge
- "All About Slide Rules" - Oughtred Society Publication
- "The Pickett N-16 ES: Advanced Analog Computing for Electronics Engineers"
- "Slide Rules Through Time: 1787 to 1905"

### External Sources
- Smithsonian National Museum of American History collections
- International Slide Rule Museum
- Eric's Slide Rules collection (sliderule.ca)
- Sphere Research Corporation archives

---

---

## 11. Complete Swift Implementation

### SlideRuleColorScheme Enum

```swift
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
```

---

## 12. Visual Reference Links

### Representative Models by Manufacturer

Use these links to see authentic examples of each manufacturer's color scheme:

#### Pickett (Eye-Saver Yellow)

| Model | Description | Visual References |
|-------|-------------|-------------------|
| **N600-ES** | Apollo Program slide rule | [Smithsonian Collection](https://americanhistory.si.edu/collections/object/nmah_694174) • [Virtual Simulator](https://sliderulemuseum.com/VirtualSR/n600es/virtual-n600-es.shtml) • [Air & Space Museum (Apollo 13)](https://airandspace.si.edu/collection-objects/slide-rule-5-inch-pickett-n600-es-apollo-13/nasm_A19840160000) |
| **N1010-ES** | Standard 10" duplex | [ISRM Gallery](https://www.sliderulemuseum.com/Pickett.shtml) • [Sphere Research](https://www.sphere.bc.ca/oldsite/test/pickett.html) |
| **N-16 ES** | Electronics specialist | [Sphere Electronics Archive](https://www.sphere.bc.ca/type/pickett/) |

#### Faber-Castell (Mint Green & Pale Blue)

| Model | Description | Visual References |
|-------|-------------|-------------------|
| **2/83N Novo-Duplex** | "Finest slide rule ever made" | [Stefan's Collection](https://www.stefanv.com/calculators/fc283n.html) • [University of Delaware](https://udel.edu/~mm/sliderule/collection/faberCastell/2-83N/) • [ISRM Gallery](http://sliderulemuseum.com/Faber.shtml) |
| **62/83N** | Pocket version | [My Rules Collection](https://sites.google.com/gpapps.galenaparkisd.com/myrules/all-purpose/faber-castell-283n-6283n) |
| **52/82 D-Stab** | Student model | [Sphere Research](https://www.sphere.bc.ca/type/fc/) |

#### Keuffel & Esser (Ivory Celluloid)

| Model | Description | Visual References |
|-------|-------------|-------------------|
| **4081-3 Log Log Duplex Decitrig** | Flagship model | [Smithsonian Collection](https://americanhistory.si.edu/collections/object/nmah_1214626) • [McCoy's K&E Catalogs](http://www.mccoys-kecatalogs.com/KEModels/ke4081-3family.htm) |
| **68-1000 Deci-Lon** | Late plastic model | [ISRM Standard Gallery](https://sliderulemuseum.com/KE_Standard.shtml) |
| **4181-1** | Pocket version | [My Rules Collection](https://sites.google.com/gpapps.galenaparkisd.com/myrules/all-purpose/ke-4081-log-log-decitrig) |

#### Hemmi / Sun (Navy & Red on Bamboo)

| Model | Description | Visual References |
|-------|-------------|-------------------|
| **266 Electronics** | Electronics engineering | [Virtual Simulator](https://www.sliderulemuseum.com/VirtualSR/hemmi-266/virtual-hemmi-266.shtml) • [Sphere Research](https://www.sphere.bc.ca/oldsite/test/hemmi.html) |
| **259 Mechanical Engineering** | General engineering | [MAAS Collection (Australia)](https://collection.maas.museum/object/378743) |
| **257 Chemical Engineering** | Chemistry specialist | [Powerhouse Collection](https://collection.powerhouse.com.au/object/378742) |
| **Post Versalog 1460** | Hemmi-made for Post | [Smithsonian Collection](https://americanhistory.si.edu/collections/object/nmah_1215024) |

#### Aristo / Dennert & Pape (Yellow Highlights)

| Model | Description | Visual References |
|-------|-------------|-------------------|
| **0972 Hyperlog** | Top-of-range 31 scales | [Science Museum UK](https://collection.sciencemuseumgroup.org.uk/objects/co61142/10-inch-hyperlog-0972-aristo-slide-rule-from-the-1973-catalogue-slide-rule) • [Rod's Collection](https://sliderules.lovett.com/aristohyperlog0972/aristohyperlog0972.htm) • [Ron Manley's Site](http://www.sliderules.info/collection/10inch/100/1109-aristo-0972.htm) |
| **0971 Hyperbolog** | Predecessor model | [My Rules Collection](https://sites.google.com/gpapps.galenaparkisd.com/myrules/all-purpose/aristo-hyperlog-0972) |

#### Nestler (Blue-Green/Teal Highlights)

| Model | Description | Visual References |
|-------|-------------|-------------------|
| **0292 Polymath** | Advanced duplex | [Eric's Collection](https://www.sliderule.ca/nestler.htm) |
| **0210 Darmstadt** | Classic Darmstadt | [ISRM Gallery](https://www.sliderulemuseum.com/Nestler.htm) |
| **0218 Duplex** | Scientific duplex | [Sphere Research](https://www.sphere.bc.ca/oldsite/test/nestler.html) |

### Museum & Archive Collections

For highest-quality reference images:

| Institution | Focus Area | URL |
|-------------|------------|-----|
| **Smithsonian NMAH** | American manufacturers (K&E, Pickett) | [americanhistory.si.edu](https://americanhistory.si.edu/collections/search?edan_q=slide%20rule) |
| **International Slide Rule Museum** | Comprehensive all manufacturers | [sliderulemuseum.com](https://sliderulemuseum.com) |
| **Sphere Research Corporation** | Detailed manufacturer archives | [sphere.bc.ca](https://www.sphere.bc.ca/oldsite/test/) |
| **Science Museum UK** | European manufacturers | [collection.sciencemuseumgroup.org.uk](https://collection.sciencemuseumgroup.org.uk) |
| **MAAS/Powerhouse (Australia)** | Hemmi collection | [collection.maas.museum](https://collection.maas.museum) |

---

*Document prepared for The Electric Slide project - December 2024*
