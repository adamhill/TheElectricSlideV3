# K Scale Label Analysis

## Expected Labels (from real slide rule)
- **1-10**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 (10 labels)
- **10-100**: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 (10 labels, 1 duplicate at 10)
- **100-1000**: 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000 (10 labels, 1 duplicate at 100)
- **Total unique**: 28 labels

## PostScript Label Strategy

Looking at PostScript K scale (lines 710-727):

```postscript
/plabel1 0 {.5 add cvi} NumFont1 MedF /Ntop load scaleLvars def
/plabel10 0 {10 div .5 add cvi} NumFont1 MedF /Ntop load scaleLvars def
/plabel100 0 {100 div .5 add cvi} NumFont1 MedF /Ntop load scaleLvars def
/plabel1000 0 {1000 div .5 add cvi} NumFont1 MedF /Ntop load scaleLvars def
```

The `0` in each definition means "label interval level 0" (primary ticks only).

## Subsection-by-Subsection Analysis

### Subsection 1: 1-3
```postscript
1 [1 .5 .1 .05] [plabel1] scaleSvars
```
- Primary interval: 1.0
- Labels level 0 (primary): **1, 2, 3**
- Formatter: `plabel1` (shows value as-is)

### Subsection 2: 3-6
```postscript
3 [1 null .5 .1] [plabel1] scaleSvars
```
- Primary interval: 1.0
- Labels level 0 (primary): **3, 4, 5, 6**
- Formatter: `plabel1` (shows value as-is)
- Note: 3 is duplicate (will be removed)

### Subsection 3: 6-10
```postscript
6 [1 null null .2] [plabel1] scaleSvars
```
- Primary interval: 1.0
- Labels level 0 (primary): **6, 7, 8, 9, 10**
- Formatter: `plabel1` (shows value as-is)
- Note: 6 is duplicate (will be removed)

### Subsection 4: 10-30
```postscript
10 [10 5 1 .5] [plabel10] scaleSvars
```
- Primary interval: 10.0
- Labels level 0 (primary): **10, 20, 30**
- Formatter: `plabel10` (divides by 10: shows as 1, 2, 3)
- **WAIT!** The formatter divides by 10, so it shows "1, 2, 3" not "10, 20, 30"!

### Subsection 5: 30-60
```postscript
30 [10 null 5 1] [plabel10] scaleSvars
```
- Primary interval: 10.0
- Labels level 0 (primary): **30, 40, 50, 60**
- Formatter: `plabel10` (divides by 10: shows as 3, 4, 5, 6)

### Subsection 6: 60-100
```postscript
60 [10 null null 2] [plabel10] scaleSvars
```
- Primary interval: 10.0
- Labels level 0 (primary): **60, 70, 80, 90, 100**
- Formatter: `plabel10` (divides by 10: shows as 6, 7, 8, 9, 10)

### Subsection 7: 100-300
```postscript
100 [100 50 10 5] [plabel100] scaleSvars
```
- Primary interval: 100.0
- Labels level 0 (primary): **100, 200, 300**
- Formatter: `plabel100` (divides by 100: shows as 1, 2, 3)

### Subsection 8: 300-600
```postscript
300 [100 null 50 10] [plabel100] scaleSvars
```
- Primary interval: 100.0
- Labels level 0 (primary): **300, 400, 500, 600**
- Formatter: `plabel100` (divides by 100: shows as 3, 4, 5, 6)

### Subsection 9: 600-1000
```postscript
600 [100 null null 20] [plabel100] scaleSvars
```
- Primary interval: 100.0
- Labels level 0 (primary): **600, 700, 800, 900, 1000**
- Formatter: `plabel100` (divides by 100: shows as 6, 7, 8, 9, 10)

### Subsection 10: 1000
```postscript
1000 [1000 500 100 50] [plabel1000] scaleSvars
```
- Primary interval: 1000.0
- Labels level 0 (primary): **1000**
- Formatter: `plabel1000` (divides by 1000: shows as 1)

## What Labels Actually Appear on the Scale

Looking at the **displayed text** (after formatters):

### Range 1-10 (subsections 1-3):
- Values: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
- **Display**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

### Range 10-100 (subsections 4-6):
- Values: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
- Formatter: divide by 10
- **Display**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

### Range 100-1000 (subsections 7-9):
- Values: 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000
- Formatter: divide by 100
- **Display**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

### Value 1000 (subsection 10):
- Value: 1000
- Formatter: divide by 1000
- **Display**: 1

## THE PROBLEM!

The PostScript K scale shows **the same digits 1-10 three times** across the scale!

- First decade (1-10): shows "1 2 3 4 5 6 7 8 9 10"
- Second decade (10-100): shows "1 2 3 4 5 6 7 8 9 10" (but represents 10-100)
- Third decade (100-1000): shows "1 2 3 4 5 6 7 8 9 10" (but represents 100-1000)

This is **BY DESIGN** - slide rules use this pattern to save space!

## Swift Implementation Issue

Our Swift implementation uses `StandardLabelFormatter.integer` which formats values as-is:
- 10 → "10"
- 20 → "20"
- 100 → "100"

But PostScript uses custom formatters:
- `plabel10`: divides by 10, so 10 → "1", 20 → "2"
- `plabel100`: divides by 100, so 100 → "1", 200 → "2"

## Solution Plan

We need to implement **custom label formatters per subsection** that match PostScript:

1. **Subsections 1-3** (1-10 range): Format as-is (1, 2, 3, ..., 10)
2. **Subsections 4-6** (10-100 range): Divide by 10 (10→1, 20→2, ..., 100→10)
3. **Subsections 7-9** (100-1000 range): Divide by 100 (100→1, 200→2, ..., 1000→10)
4. **Subsection 10** (1000): Divide by 1000 (1000→1)

This will give us the compact "1-10, 1-10, 1-10" pattern seen on real slide rules.
