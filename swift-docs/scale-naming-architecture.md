# Scale Naming Architecture

This document explains the complete naming system for scales in The Electric Slide, including the two-layer naming model, how they interact, and the resolution hierarchy.

## Overview: The Two Layers of Scale Names

The naming system is intentionally simple:

```mermaid
flowchart TB
    subgraph "Layer 1: Internal Identity"
        NAME["name<br/>Unique canonical identifier<br/>e.g., 'Sq1', 'LL03', 'C'"]
    end
    
    subgraph "Layer 2: Display Override"
        DISPLAY["displayName<br/>Optional rendered label<br/>e.g., 'W1', 'dB L', nil"]
    end
    
    NAME --> RENDER_CHECK{displayName set?}
    DISPLAY --> RENDER_CHECK
    RENDER_CHECK -->|Yes| SHOW_DISPLAY[Render displayName]
    RENDER_CHECK -->|No| SHOW_NAME[Render name]
    SHOW_DISPLAY --> FINAL[Rendered Scale Label]
    SHOW_NAME --> FINAL
```

### The Two Names

| Property | Purpose | Set By | Example |
|----------|---------|--------|---------|
| **`name`** | Unique internal identifier, accessibility, configuration lookup | `ScaleBuilder.withName()` | `"Sq1"`, `"LL03"`, `"C"` |
| **`displayName`** | Optional override for rendered label | `ScaleBuilder.withDisplayName()` or Parser | `"W1"`, `"㏈ L"`, `nil` |

**Rendering Rule**: `displayName ?? name` — If `displayName` is set, render it; otherwise render `name`.

---

## How Names Flow Through the System

### Complete Resolution Flow

```mermaid
flowchart TB
    subgraph "1. Definition String"
        TOKEN["Token in definitionString<br/>(e.g., 'W1', 'H266LL03', 'C')"]
    end
    
    subgraph "2. Factory Lookup"
        CASE["StandardScales.scale(named:)<br/>Switch statement maps token → factory"]
        FACTORY["Factory function returns<br/>ScaleDefinition with name & displayName"]
    end
    
    subgraph "3. Parser Processing"
        PARSER_CHECK{"Factory set<br/>displayName?"}
        AUTO_DISPLAY["Parser auto-sets<br/>displayName = token<br/>(if name ≠ token)"]
        KEEP["Keep factory's displayName"]
    end
    
    subgraph "4. Rendering"
        RENDER["ScaleView renders:<br/>displayName ?? name"]
    end
    
    TOKEN --> CASE
    CASE --> FACTORY
    FACTORY --> PARSER_CHECK
    PARSER_CHECK -->|No| AUTO_DISPLAY
    PARSER_CHECK -->|Yes| KEEP
    AUTO_DISPLAY --> RENDER
    KEEP --> RENDER
```

---

## Detailed Layer Explanations

### Layer 1: `name` (Canonical Internal Identifier)

**Location**: `ScaleDefinition.name`

```swift
/// Human-readable name/label for the scale (e.g., "C", "D", "LL03")
public let name: String
```

**Set via**: `ScaleBuilder.withName("...")`

**Purpose**:
1. **Unique identifier** — Each scale type has one canonical name
2. **Accessibility** — Used for `.accessibilityIdentifier("scaleview-\(name)")`
3. **Configuration API** — `ScaleKey` selectors use canonical names
4. **Fallback rendering** — If `displayName` is nil, `name` is rendered
5. **Debugging/logging** — Internal references use `name`

**Examples**:
| Factory Function | `name` Value |
|-----------------|--------------|
| `cScale()` | `"C"` |
| `r1Scale()` | `"Sq1"` |
| `hemmi266LL03Scale()` | `"LL03"` |
| `hemmi266LScale()` | `"L"` |

---

### Layer 2: `displayName` (Rendered Label Override)

**Location**: `ScaleDefinition.displayName`

```swift
/// Optional display name override for rendering
/// Used when the rendered label should differ from the canonical name
public let displayName: String?
```

**Set via**: 
1. `ScaleBuilder.withDisplayName("...")` — Factory explicitly sets it
2. Parser auto-assignment — When definition string token differs from `name`

**Purpose**: 
- Allows a scale to render with a different label than its internal identifier
- Supports manufacturer-specific notation (e.g., "㏈ L" instead of "L")
- Enables aliases (e.g., "W1" renders for canonical "Sq1")

**When to set `displayName` in factory**:
- **Custom manufacturer scales**: `hemmi266LScale()` → `displayName: "㏈ L"`
- **Special notation**: Mathematical symbols, Unicode characters
- **Manufacturer-specific labels**: Historical accuracy

**When parser auto-sets `displayName`**:
- When token in definition string ≠ factory's `name`
- Example: Token "W1" → factory returns `name: "Sq1"` → parser sets `displayName: "W1"`

---

## Practical Examples

### Example 1: Standard Scale (C)

Token matches canonical name — no `displayName` needed.

```mermaid
sequenceDiagram
    participant DS as Definition String
    participant SS as StandardScales
    participant P as Parser
    participant R as Renderer
    
    DS->>SS: Token "C"
    SS->>SS: case "C": return cScale()
    SS->>P: ScaleDefinition(name="C", displayName=nil)
    P->>P: "C" == "C" → no auto-assignment
    P->>R: GeneratedScale(name="C", displayName=nil)
    R->>R: displayName ?? name = "C"
    Note over R: Renders "C"
```

### Example 2: Alias (W1 → Sq1)

Parser auto-assigns `displayName` because token differs from `name`.

```mermaid
sequenceDiagram
    participant DS as Definition String
    participant SS as StandardScales
    participant P as Parser
    participant R as Renderer
    
    DS->>SS: Token "W1"
    SS->>SS: case "W1": return r1Scale()
    SS->>P: ScaleDefinition(name="Sq1", displayName=nil)
    P->>P: "Sq1" ≠ "W1" → set displayName="W1"
    P->>R: GeneratedScale(name="Sq1", displayName="W1")
    R->>R: displayName ?? name = "W1"
    Note over R: Renders "W1"
```

### Example 3: Manufacturer Scale with Custom Display (Hemmi 266 L)

Factory explicitly sets `displayName` for manufacturer-specific notation.

```mermaid
sequenceDiagram
    participant DS as Definition String
    participant SS as StandardScales
    participant P as Parser
    participant R as Renderer
    
    DS->>SS: Token "H266L"
    SS->>SS: case "H266L": return hemmi266LScale()
    Note over SS: Factory sets displayName="㏈ L"
    SS->>P: ScaleDefinition(name="L", displayName="㏈ L")
    P->>P: displayName already set → keep it
    P->>R: GeneratedScale(name="L", displayName="㏈ L")
    R->>R: displayName ?? name = "㏈ L"
    Note over R: Renders "㏈ L"
```

### Example 4: Pickett N-16 ES Dual-Name Scale (D/Q)

Factory sets custom `displayName` showing dual purpose.

```mermaid
sequenceDiagram
    participant DS as Definition String
    participant SS as StandardScales
    participant P as Parser
    participant R as Renderer
    
    DS->>SS: Token "N16_DQ"
    SS->>SS: case "N16_DQ": return pickettN16DQScale()
    Note over SS: Factory sets displayName="D/Q"
    SS->>P: ScaleDefinition(name="DQ", displayName="D/Q")
    P->>P: displayName already set → keep it
    P->>R: GeneratedScale(name="DQ", displayName="D/Q")
    R->>R: displayName ?? name = "D/Q"
    Note over R: Renders "D/Q"
```

---

## Summary Table

| Concept | Location | Set By | Purpose |
|---------|----------|--------|---------|
| **Definition String Token** | `definitionString` | User/Library | Lookup key for factory |
| **Case Statement Key** | `StandardScales.scale(named:)` | Developer | Map tokens to factories |
| **`name`** | `ScaleDefinition.name` | `ScaleBuilder.withName()` | Unique canonical identifier |
| **`displayName`** | `ScaleDefinition.displayName` | Factory or Parser | Rendered label override |

---

## When to Use What

### Creating a Standard Scale (token = name)

```swift
// Token, case key, and name all match
case "C": return cScale()

public static func cScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder()
        .withName("C")  // Matches case key and token
        // displayName NOT needed — name renders directly
        .build()
}
```

### Creating an Alias (multiple tokens → same scale)

```swift
// Multiple tokens point to same factory
case "R1", "SQ1", "W1", "W1'", "W1P": return r1Scale()

// Factory returns canonical name; parser auto-sets displayName to match token
public static func r1Scale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder()
        .withName("Sq1")  // Canonical name (internal)
        // NO displayName — parser will set it to "W1", "R1", etc. based on token
        .build()
}
```

### Creating a Manufacturer-Specific Scale

```swift
// Unique token for manufacturer variant
case "H266L": return hemmi266LScale()

// Factory MUST set displayName for special rendering
public static func hemmi266LScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: lScale(length: length))
        .withName("L")             // Canonical name (for config/accessibility)
        .withDisplayName("㏈ L")   // REQUIRED: manufacturer-specific notation
        .build()
}
```

### Creating a Dual-Purpose Scale

```swift
// Pickett N-16 ES: D scale that also serves as Q scale
case "N16_DQ": return pickettN16DQScale()

public static func pickettN16DQScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: dScale(length: length))
        .withName("DQ")           // Unique identifier for this dual-purpose scale
        .withDisplayName("D/Q")   // Shows both purposes to user
        .build()
}
```

---

## Architecture Diagram

```mermaid
classDiagram
    class SlideRuleDefinitionModel {
        +String definitionString
        +parseSlideRule() SlideRule
    }
    
    class StandardScales {
        +scale(named: String) ScaleDefinition?
        +cScale() ScaleDefinition
        +r1Scale() ScaleDefinition
        +hemmi266LScale() ScaleDefinition
    }
    
    class ScaleDefinition {
        +String name
        +String? displayName
        +String formula
    }
    
    class ScaleBuilder {
        +withName(String) ScaleBuilder
        +withDisplayName(String?) ScaleBuilder
        +build() ScaleDefinition
    }
    
    class RuleDefinitionParser {
        +parse(String) SlideRule
        -autoAssignDisplayName()
    }
    
    class ScaleView {
        +generatedScale: GeneratedScale
        -renderName(): String
    }
    
    SlideRuleDefinitionModel --> RuleDefinitionParser : definitionString
    RuleDefinitionParser --> StandardScales : lookup token
    StandardScales --> ScaleDefinition : returns
    ScaleBuilder --> ScaleDefinition : builds
    RuleDefinitionParser --> ScaleView : GeneratedScale
    
    note for ScaleView "Renders: displayName ?? name"
```

---

## FAQ

**Q: Why do we need both `name` and `displayName`?**

A: `name` is the stable internal identifier used for configuration selectors, accessibility, and debugging. `displayName` allows the rendered text to differ without breaking internal references. This separation keeps the system predictable while allowing visual customization.

**Q: When should I set `displayName` in the factory vs. let the parser handle it?**

A: 
- **Factory sets it**: When the scale needs special notation (Unicode, manufacturer-specific labels like "㏈ L")
- **Parser handles it**: When it's just an alias (W1 vs Sq1) — the parser auto-assigns `displayName` to match the token

**Q: What happened to `scaleNameOverrides`?**

A: It was removed to simplify the architecture. All custom display names are now set at scale factory time via `ScaleBuilder.withDisplayName()`. This is cleaner because:
1. Names are defined once, in one place (the factory)
2. No post-parse mutation of scale definitions
3. Easier to understand — look at the factory to see what renders

**Q: How do I add a manufacturer-specific label for an existing scale?**

A: Create a new factory function that wraps the base scale:
```swift
case "H266L": return hemmi266LScale()

public static func hemmi266LScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: lScale(length: length))
        .withDisplayName("㏈ L")
        .build()
}
```

**Q: What's the difference between an "alias" and a "manufacturer variant"?**

A: 
- **Alias**: Multiple tokens map to the same factory, same scale properties (W1, R1, SQ1 → `r1Scale()`)
- **Manufacturer variant**: New factory with modified properties and/or custom `displayName` (H266L → `hemmi266LScale()`)
