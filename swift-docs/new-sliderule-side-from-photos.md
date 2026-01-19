# Adding a New Slide Rule from Photos: Step-by-Step Guide

## Overview

This document guides you through adding a new slide rule to TheElectricSlide project when you have a clear photograph of one side of a slide rule. This process involves analyzing the photo, identifying scales, building the definition string, and creating the library entry.

**Important Limitation**: This guide covers adding **ONE SIDE AT A TIME**. If you're working with a two-sided slide rule, you'll need to go through this process twice - once for the front and once for the back. Each side requires its own photo analysis and definition.

---

## ⚠️ CRITICAL: Ask Clarifying Questions!

**DON'T BE SHY ABOUT ASKING THE HUMAN FOR HELP!**

Humans have better eyes than AI/computers for reading photo details. Photos can be blurry, have glare, show wear patterns, or have ambiguous markings. **It is always better to ask than to guess incorrectly.**

### When to Ask Questions

If you are **unsure about ANY of the following**, ASK THE HUMAN:

| Area of Uncertainty | Why It Matters |
|---------------------|----------------|
| **Scale names that are hard to read** | Getting the scale name wrong means using the wrong mathematical function |
| **Tick direction (up or down?)** | Affects visual appearance; `-` suffix changes rendering |
| **Colors of elements** | Red labels often indicate inverted/reciprocal scales |
| **Gauge marks (constants like π, e, M, C)** | These special markers need to be coded explicitly |
| **Whether a scale is on the stator or slide** | Determines which part moves; wrong placement breaks the rule |
| **Beginning and ending values** | Critical for setting scale range correctly |
| **Tick density changes/subsection boundaries** | Determines where tick spacing changes in the code |
| **Unusual symbols or notations** | May indicate specialized scales |

### Example Questions to Ask

**Scale Identification:**
- "I can see a scale name on row 3 but it's partially obscured. Can you tell me what it says?"
- "The label looks like it could be 'CI' or 'C1' - which is it?"
- "Is this scale labeled 'LL1' or 'LL01'? The digit is hard to read."

**Tick Direction:**
- "Do the tick marks on the L scale point upward or downward?"
- "I see the S scale - are its ticks oriented the same direction as the D scale?"

**Colors:**
- "Is the 'CI' label printed in red or black?"
- "Are there any red-colored tick marks on this scale?"

**Gauge Marks:**
- "I see what looks like a symbol at around position 3.14 on the C scale. Is that a π marker?"
- "Are there any special markers (π, e, √2, etc.) on the D scale?"

**Scale Position:**
- "Is the T scale part of the slide (movable) or on the stator (fixed)?"
- "Can you confirm which scales are on the movable slide vs. the fixed body?"

**Range and Boundaries:**
- "What value does the scale start with on the left edge?"
- "Where does the tick spacing change on this scale? Around 2? Around 4?"
- "I notice the tick density seems to change - can you confirm where?"

### Why This Matters

- **Incorrect scale names** → Wrong mathematical functions → Incorrect calculations
- **Wrong tick direction** → Visual mismatch with original rule
- **Missing gauge marks** → Incomplete reproduction of the original
- **Wrong subsection boundaries** → Incorrect tick spacing
- **Misidentified slide/stator** → Non-functional slide rule

**Bottom line: A quick question takes seconds. Fixing a wrong implementation takes much longer.**

---

## Prerequisites

- A clear, well-lit photograph showing one complete side of a slide rule
- The photo must show the entire length of the rule from left to right
- Scale names and formulas should be legible
- Manufacturer and model markings should be visible

## Architecture Overview

The project consists of two parts:

1. **SlideRuleCoreV3 Package**: Defines scales and their mathematical transformations
   - Location: `SlideRuleCoreV3/Sources/SlideRuleCoreV3/`
   - Key files: [`StandardScales.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift), [`StandardScalesFunctions.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScalesFunctions.swift)

2. **TheElectricSlide App**: Library of slide rule definitions
   - Location: [`TheElectricSlide/SlideRuleLibrary.swift`](../TheElectricSlide/SlideRuleLibrary.swift)

---

## Step 1: Photo Analysis

### 1.1 Identify the Manufacturer and Model

Look for engraved or printed text on the rule body (usually at one end):

- **Manufacturer**: Keuffel & Esser (K&E), Pickett, Hemmi, Post, Faber-Castell, etc.
- **Model Number/Name**: "4081-3", "N16-ES", "266", "Versalog", etc.
- **Side Indicator**: Some rules mark sides as "Front/Back" or "A/B"

**Example**:
```
Manufacturer: Keuffel & Esser Co.
Model: 4081-3
Side: Front
```
## Step 1.15: Research Before Deep Photo Analysis

Before detailed photo analysis, search for "[Manufacturer] [Model] manual":

**Research provides (that photos can't):**
- Exact mathematical formulas
- Scale ranges and domains
- Back side layout (if only front photo)
- Gauge mark meanings

**Key sites:** udel.edu/~mm/sliderule, sliderulemuseum.com, oughtred.org

**Then verify against your photo** - research may miss visual details like 
actual tick directions, color coding schemes, or combined scale rows (e.g., D/LL0).

### 1.2 Identify Scale Names

Scale names appear on the **left side** of each scale line. Read from top to bottom:

**Key Observations**:
- Scales are stacked vertically
- Upper scales = top stator
- Middle scales = slide (the movable part)
- Lower scales = bottom stator
- Some rules have a back side with different scales

**Example Layout**:
```
Top of rule (fixed):    LL01  �? Scale name on left
                        K
                        A
Middle (movable):       B     �? These are on the slide
                        CI
                        C
Bottom (fixed):         D
                        L
```

### 1.3 Identify Formulas

Formulas appear on the **right side** of scales. These help verify the scale's mathematical function:

**Common Formulas**:
- `x` = linear scale
- `x�` = square scale
- `x�` = cube scale
- `1/x` = reciprocal/inverted scale
- `log x` = logarithmic scale
- `e^x` = exponential scale
- `sin x`, `tan x` = trigonometric scales

### 1.4 Determine Tick Directions

Look at the small tick marks on each scale:

- **Ticks pointing UP**: Default orientation
- **Ticks pointing DOWN**: Requires `-` suffix in definition
- This affects visual appearance only, not calculations

### 1.5 Identify Physical Boundaries

Note which scales are grouped together:

- **Slide boundaries**: Usually visible as a physical gap or different color
- **Separator lines**: Solid lines between scales (marked with `|` in definition)
- **Same-line scales**: Scales that share a horizontal line without separation

### 1.6 Colors and Visual Styling

**📷 If colors are hard to see in the photo, ASK THE HUMAN!**

#### Scale Name Colors

Note if scale names are in RED vs BLACK:

- **Red labels** typically indicate inverted/reciprocal scales (CI, DI, CIF, DIF, etc.)
- **Black labels** are standard
- Some manufacturers use other colors for special scales (green, blue)

**Ask if unsure:** "Is the scale name 'CI' printed in red or black? Red usually indicates an inverted scale."

#### Tick Mark Colors

- Most ticks are black
- Some special scales have red tick marks
- Red ticks often indicate special values or warning zones

**Ask if unsure:** "Are the tick marks on the LL scales black or red?"

#### Background/Row Colors

Premium rules often have colored backgrounds for different rows:

| Manufacturer | Common Colors |
|--------------|---------------|
| **Faber-Castell** | Light blue, light green sections |
| **Hemmi 266** | Distinct colored bands for scale groups |
| **K&E** | Cream/ivory backgrounds |
| **Pickett** | Yellow aluminum (distinctive) |

**Note:** Background colors are useful to document for future styling enhancements, though not currently implemented in rendering code.

#### Representing Colors in Code

When you need to add colored labels:

```swift
.withLabelColor(red: 1.0, green: 0.0, blue: 0.0)  // Red label
.withColorApplication(ScaleColorPresets.labelsOnly)
```

Standard color configurations:
```swift
ScaleColorPresets.labelsOnly      // Only labels are colored
ScaleColorPresets.ticksOnly       // Only ticks are colored
ScaleColorPresets.labelsAndTicks  // Both colored
```

### 1.7 Gauge Marks and Constants

**📷 Gauge marks are small and easy to miss - ASK THE HUMAN if unsure!**

Look for special tick marks with **symbols instead of numbers**. These are gauge marks representing mathematical constants:

| Symbol | Value | Common Scales | Description |
|--------|-------|---------------|-------------|
| **π** | ≈ 3.14159 | C, D, CF, DF | Pi - circle calculations |
| **e** | ≈ 2.718 | LL scales | Euler's number - exponentials |
| **M** or **log�?₀e** | ≈ 0.4343 | DFm scales | Modulus of common logs |
| **C** | varies | Specialized | Speed of light or other constants |
| **?** (rho) | varies | Engineering | Density constant |
| **√2** | ≈ 1.414 | C, D, A | Square root of 2 |
| **√3** | ≈ 1.732 | C, D | Square root of 3 |
| **√10** | ≈ 3.162 | C, D | Square root of 10 |
| **1/π** | ≈ 0.318 | CI, DI | Reciprocal of pi |
| **π/4** | ≈ 0.785 | Trig scales | Quarter pi |
| **c** | ≈ 1.128 | C, D | √(4/π) - circle/square conversion |

#### Identifying Gauge Marks in Photos

- Usually a **small vertical tick** with a symbol label
- Often positioned at non-integer locations
- May have a different tick style (longer, thicker, or colored)

**Questions to ask:**
- "I see what looks like a small mark at around 3.14 on the D scale. Is that a π gauge mark?"
- "Are there any gauge marks (π, e, √2, etc.) on the C scale that I should include?"
- "Does the DFm scale have an 'M' marker?"

#### Adding Gauge Marks in Code

Gauge marks go in the scale definition using `.addConstant()`:

```swift
// Single constant
.addConstant(value: .pi, label: "π", style: .medium)

// Multiple constants
.addConstant(value: Double.e, label: "e", style: .major)
.addConstant(value: sqrt(2), label: "√2", style: .minor)
.addConstant(value: 1.0 / .pi, label: "1/π", style: .medium)
```

Constant styles:
- `.major` - Prominent marker (like a labeled major tick)
- `.medium` - Standard visibility
- `.minor` - Subtle marker

### 1.8 When Scale Names or Formulas are Missing

**📷 Not all slide rules have clearly labeled scales. When labels are missing or unreadable, ASK THE HUMAN!**

#### Strategy 1: Visual Pattern Recognition

If you can't read the scale name, try to identify by characteristics:

| Pattern Observed | Likely Scale |
|------------------|--------------|
| Range 1-10, one decade | C, D, or variants |
| Range 1-100, two decades | A, B |
| Range 1-1000, three decades | K |
| Range 0-1, linear appearance | L |
| Numbers decreasing left-to-right | Inverted scale (CI, DI, etc.) |
| Degree symbols (°) on labels | Trigonometric (S, T, ST) |
| Very small numbers (1.001-1.01) | LL0/LL00 |
| Large numbers (e to 22000+) | LL3 |

#### Strategy 2: Historical Research

Research the specific slide rule model:

1. **Oughtred Society** (oughtred.org)
   - Extensive database of slide rule manuals
   - Member forums for identification help
   
2. **International Slide Rule Museum** (sliderulemuseum.com)
   - Photos and scale layouts for many models
   - Manufacturer documentation
   
3. **Search format**: "[Manufacturer] [Model] scale layout"
   - Example: "Hemmi 266 scale layout"
   - Example: "K&E 4081-3 manual"

#### Strategy 3: ASK THE HUMAN

Specific questions to ask:

- "Can you read the scale name on the left side of row [N]?"
- "What value does this scale start with on the left edge?"
- "What value does this scale end with on the right edge?"
- "Does this look like a C/D scale or something specialized?"
- "I see numbers like [X, Y, Z] - does this match any scale you recognize?"
- "Could you check the manufacturer's documentation for this model?"

**Remember:** The human may be able to read faded or worn labels that appear illegible in the photo.

---

## Step 2: Scale Identification

### 2.1 Map Scale Names to Standard Scales

Use the scale name and formula to identify which standard scale it is. Refer to the [Appendix: Common Scale Reference](#appendix-common-scale-reference) below.

**Common Mappings**:
```
Photo Label → Standard Name → Function
C           → C              → log(x)
D           → D              → log(x)
CI          → CI             → log(1/x)
A           → A              → log(x�)
B           → B              → log(x�)
K           → K              → log(x�)
L           → L              → x (linear)
S           → S              → asin(x)
T           → T              → atan(x)
ST          → ST             → asin(x) for small angles
LL01        → LL01           → log(log(x)) for e^(0.01x)
```

### 2.2 Identify Unknown Scales

If a scale isn't in the standard list, you'll need to create it (see Step 4).

**Indicators of a new scale**:
- Scale name not found in [`StandardScales.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift)
- Unusual formula on the right side
- Manufacturer-specific markings (e.g., Hemmi's "H266LL01")

### 2.3 Group Scales by Component

Organize scales into three groups:

1. **Top Stator** (fixed, above slide)
2. **Slide** (movable middle section)
3. **Bottom Stator** (fixed, below slide)

**Example**:
```
Top Stator:    LL01, K, A
Slide:         B, CI, C
Bottom Stator: D, L
```

### 2.4 Identifying Subsection Boundaries

**📷 Tick density changes are subtle - ASK THE HUMAN to confirm boundaries!**

Scales change tick density at certain values. Look for where tick marks become more or less dense:

#### Common Subsection Patterns

**For C/D scales (1-10):**
| Range | Tick Density | Description |
|-------|--------------|-------------|
| 1.0 to 2.0 | Finest | Most gradations, smallest increments |
| 2.0 to 4.0 | Medium | Moderate spacing |
| 4.0 to 10.0 | Coarsest | Fewest intermediate ticks |

**For K scale (1-1000):**
- Each decade has different density
- Boundaries at 10, 100
- First decade (1-10) densest, third decade (100-1000) coarsest

**For A/B scales (1-100):**
- First decade (1-10): finer ticks
- Second decade (10-100): coarser ticks

**For Log-Log scales:**
- Density varies dramatically based on mathematical compression
- LL0 has very dense ticks (small range)
- LL3 has sparse ticks (enormous range)

#### Why This Matters

Each density change marks a **subsection boundary** in the code. Getting these wrong results in tick marks that don't match the original rule.

```swift
.withSubsections([
    // Dense region: 1.0 to 2.0 (finest graduations)
    ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.1, 0.05, 0.01], ...),
    
    // Medium region: 2.0 to 4.0
    ScaleSubsection(startValue: 2.0, tickIntervals: [1.0, 0.5, 0.1, 0.05], ...),
    
    // Sparse region: 4.0 to 10.0 (coarsest graduations)
    ScaleSubsection(startValue: 4.0, tickIntervals: [1.0, 0.5, 0.1, 0.02], ...)
])
```

#### Questions to Ask

**If unsure about density changes:**
- "I notice the tick density seems to change around value [X]. Can you confirm where the tick spacing changes?"
- "Looking at the C scale, does the tick spacing change at 2, at 4, or somewhere else?"
- "Are there any points where the graduation pattern noticeably changes?"
- "How many tiny ticks are there between 1.0 and 1.1? Between 2.0 and 2.1? Between 5.0 and 5.1?"

**Counting method:** Ask the human to count tick marks in specific regions:
- "How many tick marks (including the endpoints) are between 1.0 and 2.0?"
- "How many tick marks are between 5.0 and 6.0?"

This helps determine the exact tick intervals for each subsection.

---

## Step 3: Definition String Construction

### 3.1 Basic Syntax

The definition string format:
```
(topStator scales [ slide scales ] bottomStator scales : backSide definition)
```

**Rules**:
- Parentheses `()` enclose the entire definition
- Square brackets `[]` enclose slide scales
- Colon `:` separates front from back side
- Spaces separate scale names
- Vertical bar `|` creates separator lines between scales

### 3.2 Apply Scale Modifiers

Add suffixes to scale names as needed:

| Modifier | Meaning | Example |
|----------|---------|---------|
| `-` | Ticks point DOWN | `L-` |
| `+` | Ticks point UP (explicit) | `DFm+` |
| `^` | No line break, continue on same line | `LL01^` |
| `|` | Separator line AFTER this scale | `CI | C` means line after CI |

### 3.3 Build the Definition String

**Example 1 - Simple Mannheim**:
```
Photo shows:
  Top:    A
  Slide:  B, CI, C
  Bottom: D, L

Definition: "(A [ B CI C ] D L)"
```

**Example 2 - K&E 4081-3 Front (with tick modifiers)**:
```
Photo shows:
  Top:    LL01 (up), K (up), A (up)
  Slide:  B (up), separator, T (down), ST (down), S (down)
  Bottom: D (up), L (down), LL1 (down)

Note: LL1 appears as "LL1-" on the rule (ticks pointing down)

Definition: "(LL01 K A [ B | T ST S ] D L- LL1-)"
```

**Example 3 - Hemmi 266 Front (with ^ modifier)**:
```
Photo shows:
  Top:    H266LL03, H266LL01 (continues on same line ^), LL02B, LL2B (down)-, A
  Slide:  B, BI, CI, C
  Bottom: D, L (down)-, S, T (down)-

Definition: "(H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T-)"
```

### 3.4 Handle Back Side

If you're only adding one side for now, you can:

1. **Leave it empty for now**: Just end the string before the colon
   ```
   "(LL01 K A [ B CI C ] D L)"
   ```

2. **Add placeholder**: Use `blank` scales
   ```
   "(LL01 K A [ B CI C ] D L : blank [ blank ] blank)"
   ```

3. **Complete both sides**: If you have photos of both sides, process them both
   ```
   "(front scales : back scales)"
   ```

---

## Step 4: Check for New Scales Needed

### 4.1 Verify Scale Availability

Check if all identified scales exist in [`StandardScales.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift).

1. Open [`StandardScales.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift)
2. Find the `scale(named:)` factory method
3. Look for each scale name in the switch statement

**If a scale is missing**, you need to create it.

### 4.2 Research the Scale's Mathematics

#### Research the Model for Mathematical Formulas

When you need to create a custom scale, research the specific slide rule model:

**Search queries:**
- "[Manufacturer] [Model] scale layout"
- "[Manufacturer] [Model] manual" or "instructions"
- "[Manufacturer] [Model] [scale name] formula"

**This research provides:**
- Mathematical formulas you can't derive from a photo alone
- Transform functions and their mathematical basis
- Back side layout if you only have front photo
- Gauge mark meanings and special constants
- Historical context and scale naming conventions

**Resources:**
- [International Slide Rule Museum](http://www.sliderulemuseum.com/)
- [Oughtred Society Journal](http://oughtred.org/)
- Reference manuals in `reference/` directory
- Manufacturer documentation and historical archives

**⚠️ Important:** Always verify research against the actual photo - documentation may describe a different variant, or be incomplete/incorrect about visual details like tick directions and separator lines.

#### Determine Scale Properties

For custom/unknown scales, determine:

1. **Range**: What values does the scale cover? (e.g., 1 to 10, 0.01 to 1)
2. **Transform Function**: What mathematical operation? (e.g., log(x), x�, e^x)
3. **Tick Intervals**: How are ticks spaced? (major, medium, minor, tiny)
4. **Label Pattern**: Which ticks get labeled?

### 4.3 Create the Scale Function

Create a new struct in [`StandardScalesFunctions.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScalesFunctions.swift):

```swift
/// Brief description of what this scale calculates
public struct MyNewScaleFunction: ScaleFunction {
    public let name = "my-scale"  // Identifier for debugging
    
    public init() {}
    
    /// Transform input value to position on scale
    public func transform(_ value: ScaleValue) -> Double {
        // Example: for a square scale
        return log10(value.numericValue * value.numericValue)
    }
    
    /// Convert position back to value
    public func inverseTransform(_ transformedValue: Double) -> ScaleValue {
        // Example: for a square scale
        let squared = pow(10, transformedValue)
        return .numeric(sqrt(squared))
    }
}
```

**Key Points**:
- `transform()`: Converts a real-world value to a position (0.0 to 1.0 on the scale)
- `inverseTransform()`: Converts a position back to a real-world value
- Both must be exact inverses of each other for cursor readings to work

### 4.4 Create the Scale Definition

Add a new factory method to [`StandardScales.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift):

```swift
/// Brief description of the scale
/// - Parameter length: Physical length in mm (default: 250mm standard)
/// - Returns: Configured scale definition
public static func myNewScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder()
        .withName("MYNEW")           // Display name (short)
        .withFormula("x�")           // Formula shown on right
        .withFunction(MyNewScaleFunction())
        .withRange(begin: 1, end: 10)  // Value range
        .withLength(length)
        .withTickDirection(.up)      // or .down
        .withSubsections([
            // Main section (1 to 10)
            ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.5, 0.1, 0.05],  // [major, medium, minor, tiny]
                labelLevels: [0],                       // Label major ticks only
                labelFormatter: StandardLabelFormatter.integer
            )
        ])
        .build()
}
```

**Subsection Configuration**:

- **tickIntervals**: Array of [major, medium, minor, tiny] spacing
  - Major: Biggest ticks with labels (e.g., 1, 2, 3...)
  - Medium: Mid-size ticks (e.g., 1.5, 2.5...)
  - Minor: Small ticks (e.g., 1.1, 1.2...)
  - Tiny: Smallest ticks (e.g., 1.05, 1.15...)

- **labelLevels**: Which tick levels get labels
  - `[0]` = only major ticks
  - `[0, 1]` = major and medium ticks
  - `[]` = no labels (used for separator scales)

- **labelFormatter**: How to format labels
  - `StandardLabelFormatter.integer` → "1", "2", "3"
  - `StandardLabelFormatter.decimal(places: 1)` → "1.0", "1.5", "2.0"
  - Custom function for special formatting

**Multiple Subsections Example** (for scales with different densities):

```swift
.withSubsections([
    // Dense region (1 to 2)
    ScaleSubsection(
        startValue: 1.0,
        tickIntervals: [0.1, 0.05, 0.01, 0.005],
        labelLevels: [0, 1],
        labelFormatter: StandardLabelFormatter.decimal(places: 1)
    ),
    // Sparse region (2 to 10)
    ScaleSubsection(
        startValue: 2.0,
        tickIntervals: [1.0, 0.5, 0.1, 0.05],
        labelLevels: [0],
        labelFormatter: StandardLabelFormatter.integer
    )
])
```

### 4.5 Register in Factory Method

Add a case to the `scale(named:)` switch statement in [`StandardScales.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift):

```swift
public static func scale(named: ScaleName, length: Distance = 250.0) -> ScaleDefinition {
    switch named {
    // ... existing cases ...
    
    case .myNew:
        return myNewScale(length: length)
        
    // ... rest of cases ...
    }
}
```

And add the scale name to [`ScaleName.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleName.swift):

```swift
public enum ScaleName: String, CaseIterable {
    // ... existing cases ...
    case myNew = "MYNEW"
    // ... rest of cases ...
}
```

---

## Step 5: Create the Library Entry

### 5.1 Open SlideRuleLibrary.swift

Navigate to [`TheElectricSlide/SlideRuleLibrary.swift`](../TheElectricSlide/SlideRuleLibrary.swift).

### 5.2 Add to Available Definitions

Add your new slide rule to the `availableDefinitions` array:

```swift
private static let availableDefinitions: [SlideRuleDefinitionModel] = [
    // ... existing definitions ...
    
    SlideRuleDefinitionModel(
        name: "K&E 4081-3",                    // Human-readable name
        description: "Keuffel & Esser Log Log Duplex Decitrig slide rule. " +
                     "Front: LL01, K, A, B, T, ST, S, D, L, LL1. " +
                     "Professional engineering rule with log-log scales.",
        definitionString: "(LL01 K A [ B | T ST S ] D L- LL1-)",
        topStatorMM: 14,          // Height of top stator in mm
        slideMM: 13,              // Height of slide in mm
        bottomStatorMM: 14,       // Height of bottom stator in mm
        sortOrder: 0              // Lower = appears first in library
    ),
    
    // ... rest of definitions ...
]
```

### 5.3 Set Physical Dimensions

Measure or estimate the heights of each component:

**Standard dimensions** (most 10-inch rules):
- Top Stator: 14mm
- Slide: 13mm
- Bottom Stator: 14mm

**For different rule sizes**:
- 5-inch pocket rules: Scale proportionally (7mm, 6.5mm, 7mm)
- Specialty rules: Measure from the photo if possible

### 5.4 Custom Scale Display Names (Optional)

If a manufacturer uses non-standard scale labels, create a custom scale factory with
`ScaleBuilder.withDisplayName()`. For example, Hemmi 266 displays "㏈ L" instead of "L":

```swift
// In StandardScales.swift
case "H266L": return hemmi266LScale()

public static func hemmi266LScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: lScale(length: length))
        .withDisplayName("㏈ L")
        .build()
}
```

Then use the custom token in your definition string: `"(... H266L ...)"`

See [scale-naming-architecture.md](scale-naming-architecture.md) for full details.

### 5.5 Increment Library Version

At the top of the file, increment the `libraryVersion`:

```swift
private static var libraryVersion: Int {
    return 5  // Increment from 4 to 5
}
```

This ensures the app reloads the library on next launch.

### 5.6 Set Sort Order

The `sortOrder` field determines where the rule appears in the library list:

- `0` = appears first (most common/important)
- `100` = appears last
- Group related rules together with similar sort orders

**Example ordering**:
```swift
sortOrder: 0   // Mannheim (basic)
sortOrder: 10  // K&E 4081-3 (common professional)
sortOrder: 20  // Pickett N16-ES (specialized)
sortOrder: 30  // Hemmi 266 (Japanese import)
sortOrder: 100 // Experimental or rare rules
```

---

## Step 6: Testing

### 6.1 Build and Run

1. Open the project in Xcode
2. Build the project (`Cmd+B`)
3. Fix any compilation errors
4. Run the app (`Cmd+R`)

### 6.2 Verify the Library Entry

1. Launch the app
2. Open the slide rule picker
3. Find your new rule in the list
4. Verify the name and description appear correctly

### 6.3 Visual Verification

1. Select your new slide rule
2. Check the displayed scales:
   - Are all scales present?
   - Are they in the correct order (top to bottom)?
   - Are the names correct?
   - Are tick directions correct?

2. Test the slide:
   - Can you drag the slide left/right?
   - Do the scales move correctly?
   - Are the fixed scales (stators) stationary?

3. Check scale alignment:
   - Do corresponding points line up (e.g., C=1 should align with D=1)?
   - Are the scales the same length?

### 6.4 Test Cursor Readings

1. Enable the cursor
2. Move it to known positions
3. Verify readings on each scale:
   - C scale at position 2 should read approximately 2
   - D scale at position 2 should read approximately 2
   - A scale at position 4 should read approximately 2 (since A is x�)
   - CI scale at position 2 should read approximately 0.5 (since CI is 1/x)

### 6.5 Create Unit Tests (Recommended)

Create a test file to verify scale accuracy:

```swift
import Testing
@testable import SlideRuleCoreV3

@Suite("My New Rule Tests")
struct MyNewRuleTests {
    
    @Test("Scale parsing")
    func testParsing() {
        let parsed = try SlideRuleAssembly.parseDefinition(
            "(LL01 K A [ B | T ST S ] D L- LL1-)"
        )
        
        #expect(parsed.topStator.count == 3)
        #expect(parsed.slide.count == 4)
        #expect(parsed.bottomStator.count == 3)
    }
    
    @Test("Known value accuracy")
    func testKnownValues() {
        let scale = StandardScales.scale(named: .c)
        
        // Test at C=2
        let pos = scale.calculator.position(for: .numeric(2.0))
        let value = scale.calculator.value(at: pos)
        
        #expect(abs(value.numericValue - 2.0) < 0.001)
    }
}
```

---

## Appendix: Common Scale Reference

### Basic Logarithmic Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **C** | 1-10 | x | log(x) | Main calculation scale (slide) |
| **D** | 1-10 | x | log(x) | Main calculation scale (stator) |
| **CI** | 10-1 | 1/x | log(1/x) | C Inverted - reciprocals |
| **DI** | 10-1 | 1/x | log(1/x) | D Inverted - reciprocals |

### Folded Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **CF** | π-10π | x | log(x/π) | C Folded at π |
| **DF** | π-10π | x | log(x/π) | D Folded at π |
| **CIF** | 10π-π | 1/x | log(π/x) | CI Folded at π |
| **DIF** | 10π-π | 1/x | log(π/x) | DI Folded at π |

### Power Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **A** | 1-100 | x� | log(x)/2 | Square scale (two decades) |
| **B** | 1-100 | x� | log(x)/2 | Square scale on slide |
| **K** | 1-1000 | x� | log(x)/3 | Cube scale (three decades) |
| **AI** | 100-1 | 1/x� | -log(x)/2 | A Inverted |
| **BI** | 100-1 | 1/x� | -log(x)/2 | B Inverted |

### Root Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **R1**, **SQ1** | 1-10 | √x | 2×log(x) | Square root (left half) |
| **R2**, **SQ2** | 10-100 | √x | 2×log(x)-1 | Square root (right half) |

### Trigonometric Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **S** | 5.7°-90° | x | log(sin(x)) | Sine |
| **T** | 5.7°-45° | x | log(tan(x)) | Tangent |
| **ST** | 0.57°-5.7° | x | log(sin(x))≈log(x) | Small angle sine/tangent |
| **T1** | 45°-84.3° | x | log(tan(x)) | Tangent (large angles) |
| **T2** | 84.3°-89.4° | x | log(cot(x)) | Cotangent |

### Logarithmic Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **L** | 0-1 | log(x) | x | Common logarithm (base 10) |
| **LN** | 0-2.3 | ln(x) | x/ln(10) | Natural logarithm (base e) |

### Log-Log Scales (Exponential)

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **LL0** | 1.001-1.01 | e^(0.01x) | log(log(x)) | e^0.01 to e^0.1 |
| **LL1** | 1.01-1.105 | e^(0.1x) | log(log(x)) | e^0.1 to e^1 |
| **LL2** | 1.105-2.718 | e^x | log(log(x)) | e^1 to e^10 |
| **LL3** | 2.718-22026 | e^(10x) | log(log(x)) | e^10 to e^100 |
| **LL00** | 1.0001-1.001 | e^(0.001x) | log(log(x)) | e^0.001 to e^0.01 |
| **LL01** | Same as LL0 | e^(0.01x) | log(log(x)) | Alternate notation |
| **LL02** | Same as LL1 | e^(0.1x) | log(log(x)) | Alternate notation |
| **LL03** | Same as LL2 | e^x | log(log(x)) | Alternate notation |

### Hyperbolic Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **SH** | 0.8-5.3 | sinh(x) | log(sinh(x)) | Hyperbolic sine |
| **SH1** | 0.08-0.8 | sinh(x) | log(sinh(x)) | Hyperbolic sine (small) |
| **SH2** | 5.3-9 | sinh(x) | log(sinh(x)) | Hyperbolic sine (large) |
| **CH** | 0-5.3 | cosh(x) | log(cosh(x)) | Hyperbolic cosine |
| **TH** | 0-3 | tanh(x) | log(tanh(x)) | Hyperbolic tangent |

### Special Purpose Scales

| Name | Range | Formula | Function | Description |
|------|-------|---------|----------|-------------|
| **P** | 1-100 | √(1-x�) | special | Pythagorean scale |
| **blank** | - | - | - | Empty placeholder scale |

---

---

## Complete Scales Reference

For a comprehensive listing of ALL implemented scales including their functions, ranges, subsections, and use cases, see:

📚 **[Implemented Scales Reference](implemented-scales-reference.md)**

This reference includes:
- All standard scales (C, D, A, B, K, etc.)
- Log-log scales (LL0-LL3 and reciprocal variants LL00-LL03)
- Trigonometric scales (S, T, ST variants and K&E versions)
- Hyperbolic scales (Ch, Sh, Th, H1, H2, P)
- Electrical engineering scales (XL, Xc, F, Z, r1, r2, P, Q, etc.)
- Pickett N-16 ES specialized scales (Lr, Cr, ω, ?, Θ, cos Θ, dB, τ, Q)
- All alternate scale names and aliases (89 unique names total)

The comprehensive reference provides:
- **Transform functions** used by each scale with clickable source links
- **All alternate names** accepted by the factory method
- **Subsection patterns** explaining tick density changes
- **Quick lookup table** for finding scales by any alias
- **Mathematical formulas** in both Swift and mathematical notation

Use this reference when:
- Identifying scales from photos (check all possible aliases)
- Understanding scale mathematical properties
- Finding which source file defines a specific scale
- Determining if a new scale needs to be created
- Verifying transform function implementations


## Troubleshooting

### Scale Not Parsing

**Error**: "Unknown scale name: XYZ"

**Solution**: The scale doesn't exist in StandardScales. Either:
1. Check for typos in the scale name
2. Find the correct standard name for this scale
3. Create a new scale (see Step 4)

### Scales in Wrong Order

**Error**: Scales appear in wrong visual order

**Solution**:
1. Re-examine the photo - count from top to bottom carefully
2. Check which scales are on the slide vs. stators
3. Verify the definition string structure matches: `(top [slide] bottom)`

### Ticks Pointing Wrong Direction

**Error**: Ticks appear upside down

**Solution**:
1. Add `-` suffix to scale names for downward ticks
2. Example: `L-` instead of `L`
3. Or remove `-` if they should point up

### Cursor Not Aligned

**Error**: Cursor readings don't match expected values

**Solution**:
1. Verify the scale function's `transform()` and `inverseTransform()` are correct
2. Check that they are exact mathematical inverses
3. Test with known values (e.g., C=2 should read 2 on D)
4. Add unit tests to verify accuracy

### Compilation Errors

**Error**: "Cannot find scale in scope"

**Solution**:
1. Ensure you added the scale to `ScaleName` enum
2. Ensure you added a case to the `scale(named:)` factory method
3. Rebuild the project

### Can't Read the Scale Name Clearly

**Error**: Scale label is worn, faded, or obscured in the photo

**Solution**: **ASK THE HUMAN!**
- "I can't clearly read the scale name on row [N]. Can you tell me what it says?"
- "The label looks like it might be [X] or [Y] - which is correct?"
- Try researching the specific slide rule model online

### Not Sure What a Gauge Mark Represents

**Error**: Unknown symbol on the scale

**Solution**:
1. **ASK THE HUMAN**: "I see a symbol that looks like [description] at approximately position [X]. What does it represent?"
2. **Research online**: Search for "[Manufacturer] [Model] gauge marks"
3. Common symbols: π, e, M, C, ?, √2, √3
4. Check the Oughtred Society resources

### The Color Scheme is Unusual

**Error**: Scale colors don't match standard patterns

**Solution**:
1. Document the colors for future reference (even if not currently supported in code)
2. Note: "Scale [X] has [color] labels" in comments
3. Red labels typically indicate inverted scales
4. If colors seem important, **ASK THE HUMAN** about their significance

### The Tick Pattern Doesn't Match Any Standard Scale

**Error**: Unfamiliar tick spacing or range

**Solution**:
1. This may be a specialized or manufacturer-specific scale
2. **Research required**: Look up the manufacturer's documentation
3. Check the scale's formula (right side of the scale)
4. **ASK THE HUMAN**: "This scale has an unusual pattern. Can you describe what calculations it's used for?"
5. May need to create a custom scale function (see Step 4)

### Subsection Boundaries Look Wrong

**Error**: Tick density doesn't match the photo

**Solution**:
1. Re-examine where tick spacing changes
2. **ASK THE HUMAN**: "Where does the tick spacing change on scale [X]?"
3. Count ticks between known values in the photo vs. your implementation
4. Adjust `ScaleSubsection` boundaries and `tickIntervals` accordingly

---

## Best Practices

1. **Work incrementally**: Add one scale at a time, test, then proceed
2. **Document formulas**: Add comments explaining the mathematical basis
3. **Write unit tests**: Verify scale accuracy with known values
4. **Match the photo**: Strive for visual accuracy to the original rule
5. **Use consistent naming**: Follow existing scale naming conventions
6. **Preserve history**: Include manufacturer and model details in the description
7. **Cross-reference**: Check similar rules for consistency

---

## Example: Complete Workflow

Let's walk through adding the K&E 4081-3 front side:

### 1. Photo Analysis
```
Manufacturer: Keuffel & Esser Co.
Model: 4081-3
Side: Front

Scales (top to bottom):
Top Stator:    LL01, K, A (all ticks up)
Slide:         B (up), separator line, T (down), ST (down), S (down)
Bottom Stator: D (up), L (down), LL1 (down)
```

### 2. Identify Standard Scales
```
LL01 → stdandard LL01 (log-log e^0.01x)
K    → standard K (cube x�)
A    → standard A (square x�)
B    → standard B (square x�)
T    → standard T (tangent)
ST   → standard ST (small angle tangent)
S    → standard S (sine)
D    → standard D (main scale)
L    → standard L (logarithm)
LL1  → standard LL1 (log-log e^0.1x)
```

All scales exist in StandardScales.swift ✓

### 3. Build Definition String
```
(LL01 K A [ B | T ST S ] D L- LL1-)

Breakdown:
- LL01 K A = top stator
- [ ... ] = slide section
- B | T ST S = B on slide, then separator, then T, ST, S
- D L- LL1- = bottom stator (L and LL1 have ticks down)
```

### 4. No New Scales Needed
All scales already exist ✓

### 5. Create Library Entry
```swift
SlideRuleDefinitionModel(
    name: "K&E 4081-3",
    description: "Keuffel & Esser Log Log Duplex Decitrig. " +
                 "Professional 10-inch engineering slide rule with " +
                 "log-log scales for exponential calculations.",
    definitionString: "(LL01 K A [ B | T ST S ] D L- LL1-)",
    topStatorMM: 14,
    slideMM: 13,
    bottomStatorMM: 14,
    sortOrder: 10
)
```

### 6. Test
- Build ✓
- Run app ✓
- Find "K&E 4081-3" in library ✓
- Verify visual appearance ✓
- Test cursor readings ✓
- Success! ✓

---

## Quick Reference: File Locations

- Scale Functions: [`SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScalesFunctions.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScalesFunctions.swift)
- Scale Definitions: [`SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift)
- Scale Names: [`SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleName.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleName.swift)
- Library: [`TheElectricSlide/SlideRuleLibrary.swift`](../TheElectricSlide/SlideRuleLibrary.swift)
- Parser: [`SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleAssembly.swift`](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleAssembly.swift)

---

## Additional Resources

- International Slide Rule Museum: http://www.sliderulemuseum.com/
- Oughtred Society: http://oughtred.org/
- Project references: [`reference/`](../reference/) directory
- Existing implementations: [`SlideRuleLibrary.swift`](../TheElectricSlide/SlideRuleLibrary.swift) for examples

---

*This document was created to enable AI assistants to add slide rules to TheElectricSlide project from photos with no prior context. For questions or improvements, please update this guide.*