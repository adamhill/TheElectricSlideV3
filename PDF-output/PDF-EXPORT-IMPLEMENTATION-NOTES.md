# PDF Export Implementation Notes

## Overview

PDF export functionality was added to The Electric Slide app to generate printable scale labels for physical slide rules. The implementation uses Core Graphics and CoreText for precise rendering at configurable physical dimensions.

## Files Created

### PDFExport/ Directory

1. **PDFExportConfiguration.swift**
   - Configurable dimensions for PDF output
   - Paper size: 11" × 17" tabloid landscape (default)
   - Scale sizes: 10" (full-size) or 6" (pocket)
   - Margins, gaps, and layout parameters
   - Unit conversion helpers (`inches()`, `mm()`)

2. **PDFScaleRenderer.swift**
   - Core Graphics-based scale rendering
   - CoreText for labels (CTFont, CTLine, CFAttributedString)
   - Methods: `drawScale()`, `drawScaleName()`, `drawFormula()`, `drawLabels()`
   - Tick mark rendering with configurable heights and styles

3. **PDFCropMarkRenderer.swift**
   - Crop marks at corners for cutting guides
   - Registration marks (crosshairs) for alignment
   - Side labels ("FRONT", "BACK")
   - Fold line indicators

4. **SlideRulePDFExporter.swift**
   - Main orchestration class
   - Creates PDF document with CGContext
   - Lays out front and back sides with proper spacing
   - Calculates proportional heights from stator/slide MM values

5. **PDFExportSheet.swift**
   - SwiftUI modal for export options
   - Size picker (Full-size 10" / Pocket 6")
   - NSSavePanel integration for file saving
   - Requires entitlements for sandbox file access

## Integration Points

- **SlideRuleSidebarView.swift** - Added context menu item "Export to PDF..."
- **TheElectricSlide.entitlements** - Added `com.apple.security.files.user-selected.read-write`

## Key Fixes Applied

### Text Rendering (Coordinate System)
- Removed all `context.scaleBy(x: 1, y: -1)` transforms
- PDF uses bottom-left origin natively; CoreText renders correctly without y-flipping
- Fixed in: `drawScaleName()`, `drawFormula()`, `drawLabels()`, `drawSimpleLabel()`
- Also fixed in PDFCropMarkRenderer and SlideRulePDFExporter text methods

### Scale Order
- Scales now render top-to-bottom matching definition order
- Changed from `origin.y + index * scaleHeight` to `origin.y + height - (index + 1) * scaleHeight`
- First scale in definition array appears at visual top of stator/slide

### Stator/Slide Layout
- Fixed vertical positioning of top stator, slide, bottom stator
- Top stator now at highest y-coordinate (visual top)
- Bottom stator at lowest y-coordinate (visual bottom)
- Corrected: `topOrigin = originY + bottomHeight + slideHeight`

### Content Rect Calculation
- Fixed margin application in `generatePDF()`
- Correct: `x: leftMargin, y: bottomMargin, width: pageWidth - left - right, height: pageHeight - top - bottom`

## Known Issues / TODO

### Labels Need Significant Work

1. **ST Scale Labels**
   - ST (small angle) scales have special labeling requirements
   - Current implementation doesn't handle ST scale label positioning correctly
   - Labels may overlap or be positioned incorrectly for these scales

2. **Tick Mark Direction**
   - Some scales have ticks pointing up, others pointing down
   - Label positioning relative to tick direction needs refinement
   - The `tickDirection` property exists but label placement logic needs work

3. **Label Collision Detection**
   - No current collision detection for overlapping labels
   - Dense scales (like LL scales) may have label overlap issues
   - Need algorithm to skip or adjust labels when space is insufficient

4. **Superscript/Subscript Rendering**
   - Formula display uses Unicode superscripts (e.g., "x²", "e⁰·⁰¹ˣ")
   - CoreText rendering may not match app's AttributedString rendering perfectly

5. **Scale-Specific Label Formats**
   - Different scales have different labeling conventions
   - Log-Log scales: exponential notation
   - Trig scales: degree markers
   - Some scales label at specific decade positions only

### Future Enhancements

- [ ] Color scale support (currently renders in black)
- [ ] Custom font selection
- [ ] Multiple pages for different scale configurations
- [ ] Preview before export
- [ ] iOS support (currently macOS only with NSSavePanel)

## Testing

To test PDF export:
1. Run the app
2. Select a slide rule in the sidebar
3. Right-click → "Export to PDF..."
4. Choose size and save location
5. Open PDF in Preview to verify output

## Technical Notes

- PDF points: 72 points = 1 inch
- kPointsPerMM = 72.0 / 25.4 ≈ 2.835
- CoreText requires `context.textMatrix = .identity` before drawing
- Use `context.textPosition` to set draw location for CTLineDraw
