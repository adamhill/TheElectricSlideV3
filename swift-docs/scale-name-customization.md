# Scale Name Customization

## Overview

The Electric Slide uses a simple two-layer naming system that allows scales to display custom labels while maintaining stable internal identifiers. This supports historical accuracy where different manufacturers labeled the same scale differently (e.g., Hemmi 266 labels the L scale as "㏈ L").

## Architecture

### The Two-Name Model

Every scale has two name properties:

| Property | Purpose | Required | Example |
|----------|---------|----------|---------|
| **`name`** | Internal canonical identifier | ✅ Yes | `"L"`, `"Sq1"`, `"DQ"` |
| **`displayName`** | Rendered label override | ❌ No | `"㏈ L"`, `"W1"`, `"D/Q"` |

**Rendering rule**: `displayName ?? name`

If `displayName` is set, that's what the user sees. Otherwise, `name` is rendered.

### Setting Names via ScaleBuilder

```swift
public static func hemmi266LScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: lScale(length: length))
        .withName("L")             // Internal identifier (for config, accessibility)
        .withDisplayName("㏈ L")   // What user sees rendered
        .build()
}
```

---

## When to Customize Display Names

### 1. Manufacturer-Specific Notation

Different manufacturers used different labels for equivalent scales:

```swift
// Hemmi 266: L scale shows decibel notation
public static func hemmi266LScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: lScale(length: length))
        .withDisplayName("㏈ L")
        .build()
}

// Standard slide rules: L scale shows just "L"
public static func lScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder()
        .withName("L")
        // No displayName needed — "L" renders directly
        .build()
}
```

### 2. Dual-Purpose Scales

Some scales serve multiple functions and should show both purposes:

```swift
// Pickett N-16 ES: D scale that doubles as Q scale for electronics
public static func pickettN16DQScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: dScale(length: length))
        .withName("DQ")           // Unique internal ID
        .withDisplayName("D/Q")   // Shows both functions
        .build()
}

// Pickett N-16 ES: Combined impedance scales
public static func pickettN16ZsXcScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder()
        .withName("ZsXc")
        .withDisplayName("Zs/Xc")
        .build()
}
```

### 3. Mathematical Notation

Use Unicode for proper mathematical symbols:

```swift
// Log-Log scales with overbar notation
public static func hemmi266LL01Scale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: ll01Scale(length: length))
        .withDisplayName("L̅L̅1")  // Overbar notation
        .build()
}

// Reciprocal scales
public static func ciScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder()
        .withName("CI")
        .withDisplayName("C⁻¹")   // Or keep as "CI" — manufacturer preference
        .build()
}
```

---

## How It Works

### Parser Behavior

The `RuleDefinitionParser` has automatic display name handling:

1. **Token lookup**: Parser reads token from definition string (e.g., "W1")
2. **Factory call**: Calls `StandardScales.scale(named: "W1")` → returns `r1Scale()`
3. **Auto-assignment check**:
   - If factory already set `displayName` → **keep it**
   - If factory's `name` ≠ token AND `displayName` is nil → **set displayName = token**
4. **Result**: Scale has correct internal name AND correct display name

```swift
// In SlideRuleAssembly.swift (simplified)
let definition = StandardScales.scale(named: token)

// Preserve original token as displayName if:
// 1. Factory didn't set displayName
// 2. Factory's name differs from token
if definition.displayName == nil && definition.name != token {
    definition = ScaleBuilder(from: definition)
        .withDisplayName(token)
        .build()
}
```

### Example Flow

**Definition string**: `"(... W1 ...)"`

```
Token "W1" 
  → StandardScales.scale(named: "W1")
  → r1Scale() returns: name="Sq1", displayName=nil
  → Parser sees: "Sq1" ≠ "W1", displayName=nil
  → Parser sets: displayName="W1"
  → Final: name="Sq1", displayName="W1"
  → Renders: "W1" ✓
```

---

## Implementation Guidelines

### Creating a New Manufacturer Scale

1. **Add case to switch statement**:
```swift
case "H266L": return hemmi266LScale()
```

2. **Create factory function**:
```swift
public static func hemmi266LScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: lScale(length: length))
        .withName("L")             // Keep canonical name for config
        .withDisplayName("㏈ L")   // Custom display
        .build()
}
```

3. **Use in definition string**:
```swift
definitionString: "(... H266L ...)"
```

### Creating Aliases (No Custom Display Needed)

For simple aliases where the token should display as-is:

```swift
// Multiple tokens → same factory
case "R1", "SQ1", "W1", "W1'", "W1P": return r1Scale()

// Factory does NOT set displayName
public static func r1Scale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder()
        .withName("Sq1")  // Canonical internal name
        // Parser will auto-set displayName to match whichever token was used
        .build()
}
```

---

## Migration from scaleNameOverrides (Historical)

The previous system used a `scaleNameOverrides` dictionary that was applied post-parse. This has been simplified:

### Before (Removed)
```swift
// OLD: Post-parse dictionary override
SlideRuleDefinitionModel(
    definitionString: "(... L ...)",
    scaleNameOverrides: ["L": "㏈ L"]  // ❌ No longer supported
)
```

### After (Current)
```swift
// NEW: Factory sets displayName directly
case "H266L": return hemmi266LScale()

public static func hemmi266LScale(length: Distance = 250.0) -> ScaleDefinition {
    ScaleBuilder(from: lScale(length: length))
        .withDisplayName("㏈ L")  // ✅ Set at creation time
        .build()
}

// Definition string uses manufacturer-specific token
SlideRuleDefinitionModel(
    definitionString: "(... H266L ...)"  // Uses custom token
)
```

### Benefits of New Approach

1. **Single source of truth** — Look at factory to see what renders
2. **No mutation** — Scale definition immutable after creation
3. **Type-safe** — No string dictionary keys to mistype
4. **Discoverable** — IDE autocomplete shows available scales

---

## Quick Reference

### Common Patterns

| Scenario | `name` | `displayName` | Notes |
|----------|--------|---------------|-------|
| Standard scale | `"C"` | `nil` | Name renders directly |
| Alias | `"Sq1"` | `"W1"` (auto) | Parser sets from token |
| Manufacturer label | `"L"` | `"㏈ L"` | Factory sets explicitly |
| Dual-purpose | `"DQ"` | `"D/Q"` | Factory sets explicitly |
| Unicode notation | `"LL01"` | `"L̅L̅1"` | Factory sets explicitly |

### Checklist for New Scales

- [ ] Add case(s) to `StandardScales.scale(named:)` switch
- [ ] Create factory function with `.withName()`
- [ ] Add `.withDisplayName()` only if rendering should differ from name
- [ ] Update definition strings to use new token
- [ ] Add tests verifying correct rendering

---

## See Also

- [Scale Naming Architecture](scale-naming-architecture.md) — Full technical details
- [StandardScales.swift](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/StandardScales.swift) — Scale factory implementations
- [ScaleDefinition.swift](../SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift) — Core type definitions
