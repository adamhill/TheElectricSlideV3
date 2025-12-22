# PDF Generation Implementation Plan

## Overview

Implement a print-ready PDF export feature that renders slide rule scales at exact physical dimensions using the existing `SlideRuleLibrary` definitions and rendering logic.

### Key Requirements

1. **Physical Accuracy**: Scales at exactly 10" (full-size) or 6" (pocket) for logarithmic portion
2. **Both Rules on One Page**: 8.5" × 11" letter paper in landscape orientation
3. **Crop Marks & Registration**: Optional guides for precise cutting/alignment
4. **Configurable Dimensions**: All sizes externally configurable
5. **Code Reuse**: Leverage existing `SlideRuleLibrary`, tick mark calculations, and rendering logic

---

## Reference Materials

### PostScript Engine (Original Implementation)

The original PostScript slide rule engine (`reference/postscript-engine-for-sliderules.ps`) provides the mathematical and layout foundations:

```postscript
% Rule definition syntax
/KE4081-3 [14 mm 13 mm 14 mm] (LL01 K A [ B | T ST S ] D L- LL1- : ...) definerule def

% Key measurements from PostScript
/inch {72 mul} def      % 1 inch = 72 points
/cm {28.3464567 mul} def
/mm {2.83464567 mul} def
```

Key insights from PostScript engine:
- **Position calculation**: `tickx = formula(value/xfactor) × scalelen + scalestart`
- **Scale heights**: Defined in mm (14mm stator, 13mm slide for K&E 4081-3)
- **Tick lengths**: Array `[.30cm .28cm .15cm .09cm]` for Primary/Secondary/Tertiary/Quaternary
- **Label positioning**: `Ntop`, `Nleft`, `Nright`, `Ncent` functions

### Current Swift Implementation

**SlideRuleCoreV3** provides:
- `GeneratedScale.tickMarks` - Pre-computed tick positions (normalized 0.0-1.0)
- `TickMark.normalizedPosition` - Position as fraction of scale length
- `TickStyle.relativeLength` - Tick height as fraction (1.0 = full, 0.5 = half)
- `ScaleDefinition` - Scale metadata (name, formula, tick direction)

**TheElectricSlide** provides:
- `ScaleTickRenderer` - Canvas-based tick drawing logic
- `ScaleLabelRenderer` - Canvas-based label drawing logic
- Font size mapping: `fontSizeForTick()` returns 8.0/6.5/5.0 based on `relativeLength`

---

## Architecture

### New Files to Create

```
TheElectricSlide/
├── PDFExport/
│   ├── PDFExportConfiguration.swift    # Configurable dimensions
│   ├── PDFScaleRenderer.swift          # Core Graphics scale drawing
│   ├── SlideRulePDFExporter.swift      # PDF document orchestrator
│   ├── PDFCropMarkRenderer.swift       # Crop marks and registration
│   └── PDFExportSheet.swift            # SwiftUI export modal
└── Components/
    └── SlideRuleSidebarView.swift      # (Modified) Add Generate PDF action
```

---

## Implementation Details

### 1. PDFExportConfiguration

Configurable dimensions for all export parameters:

```swift
public struct PDFExportConfiguration: Sendable {
    // Page dimensions
    let pageWidth: CGFloat      // 11" = 792pt (letter landscape)
    let pageHeight: CGFloat     // 8.5" = 612pt
    
    // Scale dimensions
    let fullSizeScaleLength: CGFloat   // 10" = 720pt
    let pocketScaleLength: CGFloat     // 6" = 432pt
    
    // Margins (for scale labels and formulas)
    let leftMargin: CGFloat     // ~72pt (1") for scale names
    let rightMargin: CGFloat    // ~72pt (1") for formulas
    let topMargin: CGFloat      // ~36pt (0.5")
    let bottomMargin: CGFloat   // ~36pt (0.5")
    
    // Crop mark settings
    let showCropMarks: Bool
    let cropMarkLength: CGFloat     // 18pt (0.25")
    let cropMarkOffset: CGFloat     // 9pt gap from content
    let registrationMarkSize: CGFloat  // 12pt diameter
    
    // Font scaling (relative to screen rendering)
    let fontScaleFactor: CGFloat    // 1.5x for print clarity
    
    // Presets
    static let fullSize = PDFExportConfiguration(...)
    static let pocket = PDFExportConfiguration(...)
}
```

### 2. PDFScaleRenderer

Core Graphics-based renderer (adapts SwiftUI Canvas logic to CGContext):

```swift
struct PDFScaleRenderer {
    let configuration: PDFExportConfiguration
    
    func drawScale(
        _ generatedScale: GeneratedScale,
        in context: CGContext,
        at origin: CGPoint,
        width: CGFloat,
        height: CGFloat
    )
    
    private func drawBaseline(context: CGContext, origin: CGPoint, width: CGFloat, definition: ScaleDefinition)
    private func drawTick(context: CGContext, tick: TickMark, origin: CGPoint, width: CGFloat, height: CGFloat, definition: ScaleDefinition)
    private func drawLabel(context: CGContext, tick: TickMark, xPos: CGFloat, tickHeight: CGFloat, definition: ScaleDefinition)
    private func drawScaleName(context: CGContext, name: String, at origin: CGPoint, height: CGFloat)
    private func drawFormula(context: CGContext, formula: String, at origin: CGPoint, height: CGFloat)
}
```

**Key Position Calculation** (from PostScript engine):
```swift
let xPos = origin.x + leftMargin + (tick.normalizedPosition * scaleLength)
let tickHeight = tick.style.relativeLength * (height * 0.5)
```

### 3. SlideRulePDFExporter

Orchestrates complete PDF document creation:

```swift
final class SlideRulePDFExporter {
    let configuration: PDFExportConfiguration
    
    func generatePDF(
        for slideRule: SlideRule,
        ruleSize: RuleSize  // .fullSize or .pocket
    ) throws -> Data
    
    // Layout: Both sides (front/back) on same page
    private func layoutPage(slideRule: SlideRule, pageRect: CGRect) -> PDFPageLayout
    
    // Draw complete stator/slide assembly
    private func drawSide(_ side: RuleSide, in context: CGContext, at origin: CGPoint, width: CGFloat)
    
    private func drawStator(_ stator: Stator, in context: CGContext, at origin: CGPoint, width: CGFloat)
    private func drawSlide(_ slide: Slide, in context: CGContext, at origin: CGPoint, width: CGFloat)
}

enum RuleSize: String, CaseIterable {
    case fullSize = "Full Size (10\")"
    case pocket = "Pocket (6\")"
    
    var scaleLength: CGFloat {
        switch self {
        case .fullSize: return 720  // 10" × 72pt
        case .pocket: return 432    // 6" × 72pt
        }
    }
}
```

### 4. PDFCropMarkRenderer

Registration and cutting guides:

```swift
struct PDFCropMarkRenderer {
    func drawCropMarks(context: CGContext, contentRect: CGRect, config: PDFExportConfiguration)
    func drawRegistrationMarks(context: CGContext, pageRect: CGRect, config: PDFExportConfiguration)
    func drawCenterLines(context: CGContext, contentRect: CGRect)  // Optional alignment guides
}
```

### 5. PDFExportSheet

SwiftUI modal for export options:

```swift
struct PDFExportSheet: View {
    let rule: SlideRuleDefinitionModel
    @State private var selectedSize: RuleSize = .fullSize
    @State private var showCropMarks: Bool = true
    @State private var isExporting: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Size picker (Full Size / Pocket)
        // Crop marks toggle
        // Preview thumbnail
        // Export button → triggers NSSavePanel
    }
    
    private func exportPDF() async throws {
        let slideRule = try rule.parseSlideRule(scaleLength: selectedSize.scaleLength)
        let exporter = SlideRulePDFExporter(configuration: .init(ruleSize: selectedSize, showCropMarks: showCropMarks))
        let pdfData = try exporter.generatePDF(for: slideRule, ruleSize: selectedSize)
        
        // Present save dialog
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(rule.name).pdf"
        // ...
        #else
        // Use UIActivityViewController for iOS
        #endif
    }
}
```

### 6. Sidebar Integration

Add to `SlideRuleSidebarView.swift`:

```swift
// In the List row Button, add context menu:
.contextMenu {
    Button {
        selectedRuleForExport = rule
        showingExportSheet = true
    } label: {
        Label("Generate PDF...", systemImage: "doc.richtext")
    }
}

// State for sheet presentation:
@State private var showingExportSheet = false
@State private var selectedRuleForExport: SlideRuleDefinitionModel?

// Sheet modifier:
.sheet(isPresented: $showingExportSheet) {
    if let rule = selectedRuleForExport {
        PDFExportSheet(rule: rule)
    }
}
```

---

## Page Layout Calculation

### Letter Paper (8.5" × 11" Landscape)

```
┌────────────────────────────────────────────────────────────────────┐
│  ←0.5"→                                              ←0.5"→       │
│ ┌────┐                                              ┌────┐        │
│ │    │  FRONT SIDE                                  │    │  0.25" │
│ │ C  │  ┌──────────────────────────────────────────┐│ F  │        │
│ │ R  │  │ Scale Name │  <── 10" SCALE ──>  │Formula││ O  │        │
│ │ O  │  │            │                     │       ││ R  │        │
│ │ P  │  └──────────────────────────────────────────┘│ M  │        │
│ │    │                                              │ U  │        │
│ │ M  │  ════════════ SLIDE ═══════════════          │ L  │        │
│ │ A  │                                              │ A  │        │
│ │ R  │  └──────────────────────────────────────────┘│    │        │
│ │ K  │                                              │    │        │
│ └────┘                                              └────┘        │
│         ─────────────────────────────────────────────             │
│                         0.5" gap                                  │
│         ─────────────────────────────────────────────             │
│ ┌────┐                                              ┌────┐        │
│ │    │  BACK SIDE                                   │    │        │
│ │    │  ┌──────────────────────────────────────────┐│    │        │
│ │    │  │ Scale Name │  <── 10" SCALE ──>  │Formula││    │        │
│ │    │  └──────────────────────────────────────────┘│    │        │
│ └────┘                                              └────┘        │
└────────────────────────────────────────────────────────────────────┘
```

### Dimension Calculations

```swift
// Page: 792pt × 612pt (11" × 8.5" landscape)
let pageWidth: CGFloat = 11 * 72   // 792pt
let pageHeight: CGFloat = 8.5 * 72 // 612pt

// Full-size rule: 10" scale + 1" left margin + 1" right margin = 12"
// But we only have 11" width, so:
// - Scale: 10" = 720pt (non-negotiable per requirements)
// - Left margin (scale names): 0.5" = 36pt
// - Right margin (formulas): 0.5" = 36pt
// - Total: 10" + 0.5" + 0.5" = 11" ✓

let scaleLength: CGFloat = 720      // 10"
let leftMargin: CGFloat = 36        // 0.5" for scale names
let rightMargin: CGFloat = 36       // 0.5" for formulas
let contentWidth = leftMargin + scaleLength + rightMargin  // 792pt = 11"

// Vertical layout: front side + gap + back side
let topMargin: CGFloat = 36         // 0.5"
let bottomMargin: CGFloat = 36      // 0.5"
let gapBetweenSides: CGFloat = 36   // 0.5" visual separation
let availableHeight = pageHeight - topMargin - bottomMargin - gapBetweenSides
// 612 - 36 - 36 - 36 = 504pt for both sides
// Each side: ~252pt = ~3.5" (matches typical stator+slide+stator height)
```

---

## Font Size Mapping (Print vs Screen)

PostScript engine uses fixed point sizes:
- Large labels (primary ticks): 4.5pt
- Medium labels (secondary): 3.8pt
- Small labels (tertiary): 3.2pt

Current SwiftUI implementation:
- Major ticks (relativeLength ≥ 0.9): 8.0pt
- Medium ticks (relativeLength ≥ 0.7): 6.5pt
- Minor ticks (relativeLength ≥ 0.4): 5.0pt

**For PDF (print)**, scale appropriately:
```swift
func fontSizeForTick(_ relativeLength: Double, scaleFactor: CGFloat = 1.0) -> CGFloat {
    let baseSize: CGFloat
    if relativeLength >= 0.9 {
        baseSize = 8.0
    } else if relativeLength >= 0.7 {
        baseSize = 6.5
    } else if relativeLength >= 0.4 {
        baseSize = 5.0
    } else {
        return 0.0  // No label
    }
    return baseSize * scaleFactor
}
```

---

## Tick Drawing (Core Graphics)

Adapt from `ScaleTickRenderer`:

```swift
func drawTick(context: CGContext, tick: TickMark, origin: CGPoint, width: CGFloat, height: CGFloat, definition: ScaleDefinition) {
    // Calculate horizontal position
    let xPos = origin.x + (tick.normalizedPosition * width)
    
    // Calculate tick height
    let tickHeight = tick.style.relativeLength * (height * 0.5)
    
    // Determine start/end based on tick direction
    let (startY, endY): (CGFloat, CGFloat)
    switch definition.tickDirection {
    case .down:
        startY = origin.y
        endY = origin.y + tickHeight
    case .up:
        startY = origin.y + height
        endY = origin.y + height - tickHeight
    }
    
    // Draw tick line
    context.setStrokeColor(tickColor(for: definition).cgColor)
    context.setLineWidth(tick.style.lineWidth)
    context.move(to: CGPoint(x: xPos, y: startY))
    context.addLine(to: CGPoint(x: xPos, y: endY))
    context.strokePath()
}
```

---

## Crop Marks Implementation

```swift
func drawCropMarks(context: CGContext, contentRect: CGRect, config: PDFExportConfiguration) {
    context.saveGState()
    context.setStrokeColor(CGColor(gray: 0, alpha: 1))
    context.setLineWidth(0.5)
    
    let offset = config.cropMarkOffset
    let length = config.cropMarkLength
    
    // Top-left corner
    // Horizontal mark
    context.move(to: CGPoint(x: contentRect.minX - offset - length, y: contentRect.minY))
    context.addLine(to: CGPoint(x: contentRect.minX - offset, y: contentRect.minY))
    // Vertical mark
    context.move(to: CGPoint(x: contentRect.minX, y: contentRect.minY - offset - length))
    context.addLine(to: CGPoint(x: contentRect.minX, y: contentRect.minY - offset))
    
    // ... repeat for all four corners ...
    
    context.strokePath()
    context.restoreGState()
}

func drawRegistrationMarks(context: CGContext, pageRect: CGRect, config: PDFExportConfiguration) {
    let size = config.registrationMarkSize
    let centers = [
        CGPoint(x: pageRect.midX, y: pageRect.minY + size),  // Top center
        CGPoint(x: pageRect.midX, y: pageRect.maxY - size),  // Bottom center
        CGPoint(x: pageRect.minX + size, y: pageRect.midY),  // Left center
        CGPoint(x: pageRect.maxX - size, y: pageRect.midY),  // Right center
    ]
    
    for center in centers {
        // Draw crosshair + circle
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(0.5)
        
        // Circle
        context.addEllipse(in: CGRect(x: center.x - size/2, y: center.y - size/2, width: size, height: size))
        context.strokePath()
        
        // Crosshairs
        context.move(to: CGPoint(x: center.x - size, y: center.y))
        context.addLine(to: CGPoint(x: center.x + size, y: center.y))
        context.move(to: CGPoint(x: center.x, y: center.y - size))
        context.addLine(to: CGPoint(x: center.x, y: center.y + size))
        context.strokePath()
    }
}
```

---

## Error Handling

```swift
enum PDFExportError: Error, LocalizedError {
    case parseError(String)
    case renderingError(String)
    case fileSystemError(String)
    case insufficientSpace(required: CGFloat, available: CGFloat)
    
    var errorDescription: String? {
        switch self {
        case .parseError(let message):
            return "Failed to parse slide rule definition: \(message)"
        case .renderingError(let message):
            return "Failed to render PDF: \(message)"
        case .fileSystemError(let message):
            return "File operation failed: \(message)"
        case .insufficientSpace(let required, let available):
            return "Insufficient space: requires \(required)pt, only \(available)pt available"
        }
    }
}
```

---

## Testing Strategy

### Unit Tests (SlideRuleCoreV3Tests - if needed)
- N/A - PDF generation is in TheElectricSlide app, not the core package

### Integration Tests
- Test PDF generation with each library rule definition
- Verify PDF file creation and basic structure
- Test dimension calculations for various configurations

### Manual Testing
- Print generated PDFs at 100% scale
- Verify physical measurements with ruler
- Test crop mark accuracy
- Compare to original PostScript output

---

## Implementation Order

1. **PDFExportConfiguration** - Configuration struct with all dimensions
2. **PDFScaleRenderer** - Core tick/label drawing to CGContext
3. **PDFCropMarkRenderer** - Crop marks and registration guides
4. **SlideRulePDFExporter** - Complete PDF orchestration
5. **PDFExportSheet** - SwiftUI modal with save dialog
6. **SlideRuleSidebarView modification** - Add context menu action

---

## Future Enhancements

1. **Multiple rules per page** - Pack multiple pocket rules
2. **Custom scale selection** - Export only specific scales
3. **Color themes** - Match original rule colors (Hemmi orange, K&E green)
4. **SVG export** - Vector format for laser cutting
5. **Preview mode** - On-screen preview before export
