# PDF Rendering PostScript Alignment

## Overview

Updated the PDF rendering system to align with PostScript reference implementation (`reference/postscript-engine-for-sliderules.ps`) for accurate scale sizing, spacing, and registration mark positioning.

## Changes Made

### 1. Scale Length (PDFExportConfiguration.swift)

**Updated scale length to PostScript standard:**
- Full size: 25 cm = 708.66 points (was 708.0)
- Pocket size: 12.5 cm = 354.33 points (was 354.0)

**Reference**: PostScript line 2221 (`/scalelen 25 cm def`)

### 2. Scale Spacing Rules (PDFExportConfiguration.swift)

**Implemented PostScript-based spacing logic:**

#### a) C/D Scale Extra Spacing
- Standard spacing: 4.0 pts (~1.4mm) for all scales
- C and D scales: Additional 5.67 pts (~2mm) extra spacing
- Total C/D spacing: ~3.4mm

**Implementation**: [`spacingBetweenScales()`](TheElectricSlide/PDF/PDFExportConfiguration.swift:68-80)

#### b) Component-Based Gaps
- **Within same component** (back-to-back scales): Standard spacing only
- **Between components** (stator-slide-stator): 2pt gap for cutting guides

**Implementation**: [`spacingBetweenComponents()`](TheElectricSlide/PDF/PDFExportConfiguration.swift:82-87)

**Reference**: PostScript lines 32-35 show component sizes (`[14 mm 13 mm 14 mm]` format indicates three physical components with spacing)

### 3. Registration Marks (PDFRenderContext.swift)

**Relocated registration marks from content corners to margins:**

#### Old Implementation
- Positioned at content rectangle corners (on scales)
- 24pt crosshairs + 8pt circles

#### New Implementation (PostScript-aligned)
- Positioned in margins: 31mm (~87.9pt) clearance from scale edges
- 5mm x 4mm rectangles (PostScript standard)
- Vertical offset: 8.5mm from top/bottom scales
- 0.2pt line width

**Reference**: PostScript lines 42-72 show registration mark positioning:
```postscript
scalestart 29 mm sub curline 8.5 mm add moveto
5 mm 0 rlineto 0 -4 mm rlineto -5 mm 0 rlineto 0 4 mm rlineto
```

### 4. Rendering Updates (PDFGenerator.swift)

**Updated component and scale rendering:**

#### Component Spacing
- Applied [`spacingBetweenComponents()`](TheElectricSlide/PDF/PDFExportConfiguration.swift:82-87) for gaps between stators and slide
- Changed from fixed 4pt to dynamic 2pt component gap

#### Scale Spacing
- Applied [`spacingBetweenScales()`](TheElectricSlide/PDF/PDFExportConfiguration.swift:68-80) for per-scale-pair spacing
- Respects C/D extra spacing rules
- Iterates through scale pairs with proper spacing calculation

## PostScript Reference Dimensions

### Scale Heights (from reference implementations)
- **KE4081-3**: `[14 mm 13 mm 14 mm]` (39.7, 36.9, 39.7 pts)
- **Hemmi 266**: `[15 mm 15 mm 15 mm]` (42.5, 42.5, 42.5 pts)
- **KeLon**: `[19 mm 19 mm 19 mm]` (53.9, 53.9, 53.9 pts)

*Note: Current implementation uses 36pt default scale heights. Individual scale heights should be adjusted per rule definition for complete PostScript alignment.*

### Conversion Constants
- 1 mm = 2.83465 points
- 1 cm = 28.3465 points
- 25 cm = 708.66 points

## Files Modified

1. [`TheElectricSlide/PDF/PDFExportConfiguration.swift`](TheElectricSlide/PDF/PDFExportConfiguration.swift:1-145)
   - Updated scale length constants
   - Added [`spacingBetweenScales()`](TheElectricSlide/PDF/PDFExportConfiguration.swift:68-80) method
   - Added [`spacingBetweenComponents()`](TheElectricSlide/PDF/PDFExportConfiguration.swift:82-87) method
   - Updated [`totalHeight()`](TheElectricSlide/PDF/PDFExportConfiguration.swift:89-98) calculation

2. [`TheElectricSlide/PDF/PDFGenerator.swift`](TheElectricSlide/PDF/PDFGenerator.swift:1-239)
   - Updated [`renderComponent()`](TheElectricSlide/PDF/PDFGenerator.swift:200-229) to use dynamic spacing
   - Applied component spacing in front/back page rendering

3. [`TheElectricSlide/PDF/PDFRenderContext.swift`](TheElectricSlide/PDF/PDFRenderContext.swift:1-198)
   - Completely rewrote [`drawRegistrationMarks()`](TheElectricSlide/PDF/PDFRenderContext.swift:123-173)
   - Positioned marks in margins with PostScript clearances
   - Changed from circles to rectangles (5mm x 4mm)

## Testing

Build verified successful:
```bash
xcodebuild -scheme TheElectricSlide -destination 'platform=macOS' build
# Result: ** BUILD SUCCEEDED **
```

## Future Enhancements

1. **Per-rule scale heights**: Implement variable scale heights matching PostScript definitions (14-19mm)
2. **Precise registration marks**: Add horizontal/vertical cut lines as shown in PostScript examples
3. **Cut line indicators**: Implement partial cut lines at component boundaries (PostScript `partialcutlines`)
4. **Title positioning**: Match PostScript title gap and positioning (`/titlegap .42 cm def`)

## Related Documentation

- PostScript Reference: `reference/postscript-engine-for-sliderules.ps`
- Lines 32-35: Rule component sizes
- Lines 42-72: Registration mark positioning
- Line 2221: Scale length definition
