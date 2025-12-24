# Scale Height Fix Analysis

## Problem Summary
Individual scale heights are set too large (default 36pt = 12.7mm each). When a stator contains 4-5 scales and should total only 14-15mm, the current 36pt per scale would require 50-64mm total - a 3.5x oversize error.

## PostScript Reference Examples
- KE4081-3: Top stator = 14mm total, contains ~4 scales → each scale ≈ 3.5mm (9.9pt)
- Hemmi 266: Each component = 15mm total, contains ~4-5 scales → each scale ≈ 3mm-3.75mm (8.5-10.6pt)
- KeLon: Each component = 19mm total, contains ~4-6 scales → each scale ≈ 3.2-4.75mm (9-13.5pt)

## Current Architecture

### File Locations
1. **Default Height**: `SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift:123`
   - `height: Distance = 36.0` in ScaleDefinition init
2. **Component Heights**: `TheElectricSlide/SlideRuleLibrary.swift`
   - Defined as `topStatorMM`, `slideMM`, `bottomStatorMM`
3. **Parser**: `SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleAssembly.swift`
   - `RuleDefinitionParser` converts mm to points and assembles components

### Data Flow
```
SlideRuleLibrary (mm values) 
  → RuleDefinitionParser.Dimensions (points)
  → parseComponents() → StandardScales.scale()
  → ScaleDefinition(height: 36.0)  ← PROBLEM: hardcoded default
```

## Required Fix Strategy

### Option 1: Pass Height Through Parser ✓ (CHOSEN)
Modify `RuleDefinitionParser.parseComponents()` to:
1. Count scales in each component (top/slide/bottom)
2. Calculate per-scale height = component_height / scale_count
3. Pass explicit height when creating ScaleDefinition

**Pros:**
- Minimal API changes
- Scales automatically fit component boundaries
- No need to modify every scale factory method

**Cons:**
- Requires modifying parser logic
- Need to update ScaleDefinition to preserve custom heights

### Fix Implementation
1. Modify `SlideRuleAssembly.swift`:
   - Add scale height calculation in `parseComponents()`
   - Pass height explicitly when creating GeneratedScale
   - Update ScaleDefinition copying to include height

2. Keep default 36pt for:
   - Standalone scales (not in components)
   - Tests that create scales directly
   - Preview/debugging code

## Scale Count Examples
From SlideRuleLibrary.swift definitions:

### K&E 4081-3 (14mm/13mm/14mm)
```
Front: (LL01 K A [ B | T ST S ] D L- LL1-)
- Top: LL01, K, A = 3 scales → 14mm/3 = 4.67mm = 13.2pt each
- Slide: B, T, ST, S = 4 scales → 13mm/4 = 3.25mm = 9.2pt each
- Bottom: D, L-, LL1- = 3 scales → 14mm/3 = 4.67mm = 13.2pt each
```

### Hemmi 266 (15mm/15mm/15mm)
```
Front: (H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T-)
- Top: H266LL03, H266LL01^, LL02B, LL2B-, A = 5 scales → 15mm/5 = 3mm = 8.5pt each
- Slide: B, BI, CI, C = 4 scales → 15mm/4 = 3.75mm = 10.6pt each
- Bottom: D, L-, S, T- = 4 scales → 15mm/4 = 3.75mm = 10.6pt each
```

### Pickett N-16 ES (15mm/15mm/15mm)
```
Front: (SH1 SH2- TH DF [ CF L S Cos ST T CI C ] D LL3 LL2 LL1 Ln)
- Top: SH1, SH2-, TH, DF = 4 scales → 15mm/4 = 3.75mm = 10.6pt each
- Slide: CF, L, S, Cos, ST, T, CI, C = 8 scales → 15mm/8 = 1.875mm = 5.3pt each
- Bottom: D, LL3, LL2, LL1, Ln = 5 scales → 15mm/5 = 3mm = 8.5pt each
```

## Validation Checks
1. Sum of scale heights in component = component height (within 0.1mm tolerance)
2. No scale height < 5pt (minimum render size)
3. No scale height > 20pt (maximum reasonable size)
4. Build succeeds
5. Tests pass
