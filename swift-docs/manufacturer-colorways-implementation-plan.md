# Manufacturer Colorways Implementation Plan

> **Version:** 2.0.0  
> **Last Updated:** December 26, 2025  
> **Status:** ✅ Fully Implemented  
> **Changelog:**
> - v2.0.0 (2025-12-26): All phases complete; precision colors centralized in SlideRuleColorScheme
> - v1.0.0 (2025-12): Initial implementation plan

## Overview

Enable authentic manufacturer color schemes for slide rules in The Electric Slide app, starting with:
1. **Pickett Eye-Saver Yellow** - Toggle to apply distinctive 5600Å yellow background
2. **Faber-Castell Scale Highlighting** - Toggle for mint green (C, CF, D, DF) and pale blue (A, B) scale stripes

The existing `SlideRuleColorScheme` infrastructure provides all color definitions; this plan wires them through the rendering pipeline with user-facing toggles that only appear when the selected rule has a manufacturer association.

---

## Phase 1: SwiftData Model Update

### 1.1 Add Manufacturer Property to SlideRuleDefinitionModel

**File:** `TheElectricSlide/CurrentSlideRule.swift`

Add a new `manufacturer` property with SwiftData versioning:

```swift
/// Manufacturer associated with this rule (for color scheme application)
/// nil for generic/educational rules without manufacturer-specific colors
var manufacturer: String?  // Store as String for SwiftData compatibility

/// Computed property to get the SlideRuleManufacturer enum
var manufacturerEnum: SlideRuleManufacturer? {
    guard let manufacturer else { return nil }
    return SlideRuleManufacturer(rawValue: manufacturer)
}
```

### 1.2 SwiftData Migration

**Migration Strategy:** Lightweight migration with default nil value

Since `manufacturer` is optional and defaults to `nil`, SwiftData can perform automatic lightweight migration. Increment `libraryVersion` in `SlideRuleLibrary.swift` to trigger rule refresh with manufacturer data.

**Version Bump:** `libraryVersion = 12` (was 11)

---

## Phase 2: Update SlideRuleLibrary

### 2.1 Manufacturer Assignments

| Rule Name | Manufacturer |
|-----------|--------------|
| `Pickett N-16 ES Electronic` | `.pickett` |
| `Pickett N3 Powerlog` | `.pickett` |
| `Faber-Castell 62/83 N` | `.faberCastell` |
| `K&E 4081-3 Log-Log Duplex Decitrig` | `.keuffelEsser` |
| `K&E KeLon` | `.keuffelEsser` |
| `Hemmi 266` | `.hemmi` |
| `Hemmi 266 ThinkGeek Edition` | `.hemmi` |
| All others | `nil` (generic) |

### 2.2 Factory Method Updates

Add `manufacturer` parameter to init calls:

```swift
static func pickettN16ESElectronic() -> SlideRuleDefinitionModel {
    SlideRuleDefinitionModel(
        name: "Pickett N-16 ES Electronic",
        // ... existing params ...
        manufacturer: SlideRuleManufacturer.pickett.rawValue  // NEW
    )
}
```

---

## Phase 3: Color Toggle State

### 3.1 Add Toggle to ContentView

**File:** `TheElectricSlide/ContentView.swift`

```swift
// Persisted user preference for manufacturer color scheme
@AppStorage("useManufacturerColors") private var useManufacturerColors: Bool = false
```

### 3.2 Conditional Toggle Display

Only show toggle when `selectedRuleDefinition?.manufacturer != nil`:

```swift
// In SlideRuleSidebarView or StaticHeaderSection
if selectedRuleDefinition?.manufacturer != nil {
    Toggle("Manufacturer Colors", isOn: $useManufacturerColors)
}
```

---

## Phase 4: Gradient Background System

### 4.1 Four-Stop Gradient Definition

**File:** `TheElectricSlide/Utilities/SlideRuleColorScheme.swift`

Add gradient generation method:

```swift
extension SlideRuleColorScheme {
    /// Creates a 4-stop vertical gradient for scale highlighting
    /// Simulates the authentic "stripe" appearance on historical rules
    /// 
    /// Gradient structure (top to bottom):
    /// - Stop 1 (0.0): Highlight color at 30% opacity (subtle edge)
    /// - Stop 2 (0.15): Highlight color at 70% opacity (ramp up)
    /// - Stop 3 (0.85): Highlight color at 70% opacity (main body)
    /// - Stop 4 (1.0): Highlight color at 30% opacity (subtle edge)
    func scaleBackgroundGradient(for scaleName: String) -> LinearGradient? {
        let highlightColor: Color?
        
        if ScaleColorMapping.primaryHighlightScales.contains(scaleName) {
            highlightColor = primaryHighlight
        } else if ScaleColorMapping.secondaryHighlightScales.contains(scaleName) {
            highlightColor = secondaryHighlight
        } else {
            return nil  // No gradient for non-highlighted scales
        }
        
        guard let color = highlightColor else { return nil }
        
        return LinearGradient(
            stops: [
                .init(color: color.opacity(0.3), location: 0.0),
                .init(color: color.opacity(0.7), location: 0.15),
                .init(color: color.opacity(0.7), location: 0.85),
                .init(color: color.opacity(0.3), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
```

### 4.2 Scale Color Mapping (Already Exists)

```swift
struct ScaleColorMapping {
    static let primaryHighlightScales: Set<String> = ["C", "CF", "D", "DF"]
    static let secondaryHighlightScales: Set<String> = ["A", "B"]
    static let invertedScales: Set<String> = ["CI", "DI", "CIF", "DIF", "BI", "LL/0"...]
}
```

---

## Phase 5: Thread Color Scheme Through Views

### 5.1 Update View Hierarchy

```
ContentView
  └─ SlideRuleDetailView (add: colorScheme, useManufacturerColors)
       └─ DynamicSlideRuleContent (add: colorScheme, useManufacturerColors)
            └─ SideView (add: colorScheme, useManufacturerColors)
                 ├─ StatorView (add: colorScheme, useManufacturerColors)
                 │    └─ ScaleContainerView (add: colorScheme, useManufacturerColors)
                 └─ SlideView (add: colorScheme, useManufacturerColors)
                      └─ ScaleContainerView (add: colorScheme, useManufacturerColors)
```

### 5.2 ScaleContainerView Changes

**Key modification:** Apply per-scale background based on scale name:

```swift
struct ScaleContainerView<Container: ScaleContainer>: View, Equatable {
    // ... existing properties ...
    let colorScheme: SlideRuleColorScheme?  // NEW
    let useManufacturerColors: Bool          // NEW
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(container.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(...)
                    .background(
                        scaleBackground(for: generatedScale.definition.name)
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(containerBackground)
        )
        // ...
    }
    
    @ViewBuilder
    private func scaleBackground(for scaleName: String) -> some View {
        if useManufacturerColors, let scheme = colorScheme,
           let gradient = scheme.scaleBackgroundGradient(for: scaleName) {
            gradient
        } else {
            Color.clear
        }
    }
    
    private var containerBackground: Color {
        if useManufacturerColors, let scheme = colorScheme {
            return scheme.primaryBackground
        }
        return backgroundColor
    }
}
```

---

## Phase 6: Toggle UI Location

### Option A: Sidebar (Recommended for MVP)

Add to `SlideRuleSidebarView.swift` in the rule details section:

```swift
Section("Display Options") {
    if selectedRule?.manufacturer != nil {
        Toggle("Manufacturer Colors", isOn: $useManufacturerColors)
            .help("Apply authentic \(selectedRule?.manufacturerEnum?.displayName ?? "") color scheme")
    }
}
```

### Option B: Header (Not Implemented)

Earlier drafts considered placing this toggle in `StaticHeaderSection.swift` for always-visible access, but the final architecture keeps the control in `SlideRuleSidebarView.swift` only to align with the sidebar-based rule details flow.

---

## File Changes Summary

| File | Changes |
|------|---------|
| `CurrentSlideRule.swift` | Add `manufacturer: String?` property, computed `manufacturerEnum` |
| `SlideRuleLibrary.swift` | Bump version to 12, add manufacturer to factory methods |
| `SlideRuleColorScheme.swift` | Add `scaleBackgroundGradient(for:)` method |
| `ContentView.swift` | Add `@AppStorage("useManufacturerColors")` |
| `SlideRuleSidebarView.swift` | Add conditional toggle UI |
| `SlideRuleDetailView.swift` | Pass colorScheme, useManufacturerColors |
| `DynamicSlideRuleContent.swift` | Pass colorScheme, useManufacturerColors |
| `SideView.swift` | Pass colorScheme, useManufacturerColors |
| `StatorView.swift` | Pass colorScheme, useManufacturerColors |
| `SlideView.swift` | Pass colorScheme, useManufacturerColors |
| `ScaleContainerView.swift` | Apply per-scale gradient backgrounds |

---

## Testing Strategy

1. **Build on macOS** using Xcodebuild MCP
2. **Verify toggle visibility** - only shows when rule has manufacturer
3. **Test Pickett rules** - background turns Eye-Saver yellow when toggle on
4. **Test Faber-Castell** - C/D/CF/DF get mint green, A/B get pale blue gradients
5. **Test generic rules** - toggle hidden, no color changes

---

## Future Enhancements

1. **Per-rule color override** - Allow users to customize colors per rule
2. **Aged appearance toggle** - Switch between "new" and "patinated" color variants
3. **Inverted scale colors** - Apply red markings to CI, DI, CIF scales
4. **Material effects** - Wood grain overlay for K&E, bamboo texture for Hemmi

---

*Created: December 24, 2025*
*Author: AI Agent for The Electric Slide project*
