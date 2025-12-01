# The `^` Symbol in the PostScript Slide Rule Engine

## Overview

The `^` (caret) symbol is a suffix modifier in Derek Pressnall's PostScript slide rule engine that suppresses the automatic line break after drawing a scale. This allows multiple partial scale definitions to render on the same horizontal row.

## Purpose

From the engine's documentation:

> A "^" symbol following a scale means not to do a line break. Useful if you have two partial scale definitions that need to appear on the same rule line.

## The Parsing Logic

The magic happens in the `definerule` function. When parsing scale tokens from the scale list string, it examines suffix characters from right to left:

```postscript
{ curtoken dup length lensub 1 add sub get
    {
        { dup 45 eq { /newtickdir -1 def /lensub ++ pop false exit} }
        { dup 43 eq { /newtickdir 1 def /lensub ++ pop false exit} }
        { dup 94 eq { /donewline false def /lensub ++ pop false exit} }
        { true { pop true exit } }
    } { exec if } forall
} loop
```

### ASCII Code Reference

| Code | Character | Effect |
|------|-----------|--------|
| 45   | `-`       | Tick marks point down (`/newtickdir -1`) |
| 43   | `+`       | Tick marks point up (`/newtickdir 1`) |
| 94   | `^`       | Suppress line break (`/donewline false`) |

## The Line Break Decision

After stripping suffixes and generating the scale, the engine checks the `donewline` flag:

```postscript
donewline true eq {
    {
        dup /tickdir get 1 eq {
            /curline skip -= gen_scale
        } {
            gen_scale /curline skip -=
        } ifelse
    } {} forall
    /i ++
} {
    {gen_scale} {} forall    % <-- Just draw, no line advance!
} ifelse
```

### Normal Behavior (`donewline = true`)

1. Advance `curline` by `skip` (the vertical spacing between scale rows)
2. Call `gen_scale` to render the scale
3. Increment the scale counter `/i`

### Caret Behavior (`donewline = false`)

1. Call `gen_scale` to render the scale
2. **No** vertical position change
3. **No** counter increment

The next scale in the list will render at the same `curline` position, effectively compositing multiple scales onto one row.

## Real-World Examples

### Hemmi 266 Electronic Slide Rule

```postscript
/H266 [15 mm 15 mm 15 mm] (H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank) definerule def
```

Here `H266LL01^` draws a partial Log-Log scale on the **same line** as `LL02B` which follows it. This allows two range-limited scale definitions to occupy a single visual row.

### Hemmi 266 ThinkGeek Variant

```postscript
/H266-TG [13 mm 22 mm 13 mm] (H266LL03 H266LL01^ LL02B LL2B- A [ B BI Sh1 Sh2 Th CI C ] D DI P L : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ ST S | T- eeLi eeCf eeCz ] eeL eeZ eeFo blank) definerule def
```

Multiple uses of `^`:
- `H266LL01^` - partial LL scale continues on same line
- `eeP^` - electronic scale continues on same line  
- `eer2^` - another electronic scale continues on same line

## How Scale Positioning Works with `^`

A natural follow-up question: when the `^` symbol suppresses the line break, how does the *next* scale know where to start drawing horizontally?

### The Elegant Answer: It Doesn't Need To

There is **no explicit hand-off mechanism**. Each scale independently calculates its own horizontal position using its own formula. The scale definitions are mathematically designed so adjacent partial scales map to the correct physical locations.

### The Position Calculation

The critical line in `gen_scale` computes each tick's x-position:

```postscript
/tickx curtick xfactor div formula exec scalelen mul scalestart add def %x position
```

This breaks down to:

```
tickx = formula(domain_value) × scalelen + scalestart
```

Where:
- **`formula`** - the scale's mathematical function (e.g., `{log}`, `{sinh 10 mul log}`)
- **`scalelen`** - global physical length of the scale (constant across all scales on the rule)
- **`scalestart`** - global starting x-coordinate (constant)

Since `scalelen` and `scalestart` are global constants, the formula alone determines where each tick lands on the rule.

### How Adjacent Scales Align

Each scale has its own `beginscale`, `endscale`, and `formula`. The trick is in how scale authors design these to produce seamless visual results.

#### Example: Split Hyperbolic Sine Scales (Sh1/Sh2)

```postscript
/Sh1scale Shscale ddup def Sh1scale begin
    /title (Sh1) def
    /beginscale .1 def
    /endscale .90 def
end

/Sh2scale Shscale ddup def Sh2scale begin
    /title (Sh2) def
    /beginscale .88 def
    /endscale 3 def
    /formula dup {1 sub} xappend def   % ← Key: shifts the formula!
end
```

Notice that Sh2's formula has `{1 sub}` appended. This shifts its output by -1, which is the mechanism that makes Sh2 start where Sh1 ends *physically*—even though their domain values overlap slightly (0.88-0.90).

#### Example: Square Root Scales (R1/R2)

```postscript
/R1scale Cscale20 ddup def R1scale begin
    /title (Sq1) def
    /endscale 3.2 def
end

/R2scale Cscale20 ddup def R2scale begin
    /title (Sq2) def
    /beginscale 3.1 def
    /formula dup {1 sub} xappend def
end
```

Same pattern: R2 uses `{1 sub}` to shift its formula output, causing it to render in the right half of the scale row while R1 covers the left half.

#### Example: Cube Root Scales (Q1/Q2/Q3)

```postscript
/Q1scale Cscale30 ddup def Q1scale begin
    /title (Q1) def
    /endscale 2.16 def
end

/Q2scale Cscale30 ddup def Q2scale begin
    /title (Q2) def
    /beginscale 2.15 def
    /endscale 4.7 def
    /formula dup {1 sub} xappend def
end

/Q3scale Cscale30 ddup def Q3scale begin
    /title (Q3) def
    /beginscale 4.6 def
    /formula dup {2 sub} xappend def   % ← Shifts by 2 for third segment!
end
```

Here Q3 uses `{2 sub}` because it's the third segment—each successive scale shifts by an additional unit.

### The Design Pattern

The `^` symbol simply says "don't move the vertical cursor." The horizontal positioning is entirely self-contained within each scale's formula. Scale authors must:

1. **Design formulas** that produce the correct normalized output range (typically 0-1 for linear scales)
2. **Use formula modifiers** (like `{1 sub}`, `{2 sub}`) to shift scales that continue from previous ones
3. **Overlap `beginscale`/`endscale`** slightly for visual continuity at the junction

### Functional Programming Analogy

This is pure functional composition in the LISP tradition. Each scale is a pure function of its domain value—no shared mutable state, no explicit "cursor position" being passed between scales. The composition happens through mathematical design:

```
Scale1: domain → formula₁(x) → physical position
Scale2: domain → formula₂(x) → physical position  (where formula₂ includes offset)
```

The `^` modifier is simply a rendering directive that says "these two pure functions should paint on the same canvas row." The math handles the rest.

### Visual Representation

```
Without ^:                          With ^:
┌─────────────────────────┐        ┌─────────────────────────┐
│ Scale A (row 1)         │        │ Scale A    │  Scale B   │  ← Same row!
├─────────────────────────┤        │ (left)     │  (right)   │
│ Scale B (row 2)         │        ├─────────────────────────┤
├─────────────────────────┤        │ Scale C (row 2)         │
│ Scale C (row 3)         │        └─────────────────────────┘
└─────────────────────────┘

curline advances after each       curline stays put after A^,
scale render                      advances after B
```

## Use Cases

The `^` modifier is essential when:

1. **Partial Scale Ranges**: A scale covers only part of the domain (e.g., LL01 covering 1.001-1.01) and another partial scale covers an adjacent range

2. **Composite Scales**: Two mathematically distinct scales need to appear as one continuous row for visual or functional reasons

3. **Split Definitions**: A complex scale is easier to define as multiple simpler definitions that render together

## Analogy

Think of it like a functional programming continuation—the `^` says "I'm not done rendering this row yet, keep the cursor where it is for the next scale." It's the PostScript equivalent of suppressing a newline in a print statement.

## Summary of Scale List Special Characters

| Character | Position | Effect |
|-----------|----------|--------|
| `:`       | Standalone | Flip rule to other side |
| `\|`      | Standalone | Draw solid line between scales |
| `[` `]`   | Standalone | Delimit slide section |
| `-`       | Suffix | Override tick direction to down |
| `+`       | Suffix | Override tick direction to up |
| `^`       | Suffix | Suppress line break after scale |
| `blank`   | Scale name | Skip a line without drawing |

---

*Source: PostScript Slide Rule Engine by Derek Pressnall, 2011 (GNU GPL v3)*
