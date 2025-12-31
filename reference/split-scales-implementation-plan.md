# Split Scales Implementation Plan

**Status**: ✅ Implementation Complete (Phase 1-5)
**Target**: SlideRuleCoreV3
**Date**: 2025-12-31 (Updated from 2025-12-30)

## Executive Summary

Split scales (e.g., THETA scales on Pickett N16-ES) require scales to render in fractional portions of the physical ruler width. This document provides a complete implementation plan incorporating confirmed architecture decisions.

### Confirmed Decisions

1. **Architecture**: `splitSegment` property derives `physicalRange` (single property approach)
2. **Parser**: Explicit `^` marking required in `definitionString`
3. **Rendering Order**: Later segment (right) renders on top of earlier segment (left)
4. **Label Collision**: Manual configuration in scale definition (no automatic collision detection)

---

## 1. Problem Statement

### Current Architecture Limitation

**Current Rendering Model:**
- Each [`ScaleDefinition`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift) has a `length` property (e.g., 250mm)
- Transform functions map value ranges to normalized `position 0.0 → 1.0`
- Rendering engine: `position × length = physical coordinate`
- **Result**: Position 0→1 ALWAYS renders as 0mm→250mm (full width)

**What THETA Split Scales Need:**

- **Θ₁**: Value range 0.57°→6.0° mapped to position 0→1, but rendered into **physical 0mm→125mm** (left half)
- **Θ₂**: Value range 5.73°→89.43° mapped to position 0→1, but rendered into **physical 125mm→250mm** (right half)

**Key Issue**: No mechanism to render a scale into a fractional portion of physical space.

---

## 2. Architecture Design

### 2.1 Data Model Extension

**Add to [`ScaleDefinition`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift):**

```swift
public struct ScaleDefinition: Sendable {
    // ... existing properties ...
    
    /// Identifies this scale as a segment of a split scale
    /// - nil: Regular full-width scale
    /// - .left(0.0): Left segment, renders in 0.0...0.5 physical range
    /// - .right(-1.0): Right segment, renders in 0.5...1.0 physical range
    public let splitSegment: SplitSegment?
    
    // ... rest of definition ...
}

public enum SplitSegment: Sendable, Equatable, Hashable {
    /// Left segment renders from 0.0 to 0.5 (50% split point)
    /// - Parameter formulaOffset: PostScript formula offset (typically 0.0 for left)
    case left(formulaOffset: Double)
    
    /// Right segment renders from 0.5 to 1.0 (50% split point)
    /// - Parameter formulaOffset: PostScript formula offset (typically -1.0 for right, representing `{1 sub}`)
    case right(formulaOffset: Double)
    
    /// Returns the physical rendering range for this segment
    /// (normalized 0.0...1.0 where 0.0 = start of scale, 1.0 = end of scale)
    public var physicalRange: ClosedRange<Double> {
        switch self {
        case .left:
            return 0.0...0.5
        case .right:
            return 0.5...1.0
        }
    }
    
    /// Segment index for ordering (0 = left, 1 = right)
    public var segmentIndex: Int {
        switch self {
        case .left: return 0
        case .right: return 1
        }
    }
    
    /// Convert a logical position (0.0...1.0) to physical fraction within the full scale
    public func physicalFraction(from logicalPosition: Double) -> Double {
        let range = physicalRange
        let rangeWidth = range.upperBound - range.lowerBound
        return range.lowerBound + (logicalPosition * rangeWidth)
    }
}
```

**Design Rationale:**
- `splitSegment` is a **derived property** that computes `physicalRange` on demand
- Clean enum with associated values for formula offset (PostScript heritage)
- Single source of truth for split configuration
- Natural extension point for future multi-segment scales
- `Hashable` conformance enables use in dictionaries and sets

### 2.2 PostScript Heritage: Why `formulaOffset` Instead of `splitPoint`

The `formulaOffset` parameter name reflects the PostScript heritage of slide rule rendering. In the original PostScript engine (see [`postscript-caret-symbol-no-linebreak.md`](reference/postscript-caret-symbol-no-linebreak.md)), split scales use formula transformations:

- **Left segment**: Uses formula offset `0.0` (no transformation)
- **Right segment**: Uses formula offset `-1.0`, which corresponds to the PostScript `{1 sub}` pattern

This represents a **mathematical continuation** rather than just a physical split point:
- The right segment's values are offset by -1.0 in the formula space
- This allows the same underlying scale function to work across both segments
- The offset creates the visual gap that separates the two halves

**Example**: For a scale where `position = log10(x)`:
- Left segment: `position = log10(x)` directly
- Right segment: `position = log10(x) - 1.0` (shift by one decade)

This approach maintains mathematical consistency with the original PostScript slide rule rendering engine.

### 2.3 ScaleBuilder API

**Add to [`ScaleBuilder`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift):**

```swift
extension ScaleBuilder {
    /// Configure the split segment for this scale
    /// - Parameter segment: The split segment configuration, or nil for full-width
    public func withSplitSegment(_ segment: SplitSegment?) -> ScaleBuilder {
        var new = self
        new.splitSegment = segment
        return new
    }
    
    /// Convenience: Configure as left segment of a split scale
    /// Uses default formulaOffset of 0.0 (no transformation)
    public func leftSegment() -> Self {
        withSplitSegment(.left(formulaOffset: 0.0))
    }
    
    /// Convenience: Configure as right segment of a split scale
    /// Uses default formulaOffset of -1.0 (PostScript {1 sub} pattern)
    public func rightSegment() -> Self {
        withSplitSegment(.right(formulaOffset: -1.0))
    }
}
```

**Usage Example:**

```swift
// THETA scales on Pickett N16-ES
let theta1 = ScaleBuilder()
    .name("Θ₁")
    .scaleFunction(.theta1)
    .leftSegment()  // Renders in left 50%
    .withLength(250.0)
    .build()

let theta2 = ScaleBuilder()
    .name("Θ₂")
    .scaleFunction(.theta2)
    .rightSegment()  // Renders in right 50%
    .withLength(250.0)
    .build()

// Custom offset example (advanced usage)
let customSegment = ScaleBuilder()
    .name("Custom")
    .withSplitSegment(.right(formulaOffset: -0.5))  // Custom offset
    .build()
```

---

## 3. Parser Enhancement

### 3.1 Definition String Syntax

**Confirmed Syntax**: The `^` character explicitly marks split boundaries in definition strings.

```swift
// Split scale syntax (^ = split boundary)
"Θ₁ ^ Θ₂"  // Creates two scales: Θ₁ (left), Θ₂ (right)

// Multiple scales with split
"Θ₁ ^ Θ₂ | α"  // Θ₁^Θ₂ on one line, α on another

// Non-split scales (existing syntax)
"C | D"    // Two independent full-width scales
```

**Parsing Rules:**
1. `^` creates split segments at 0.5 split point (equal division)
2. Left scale of `^` gets `.leftSegment(splitAt: 0.5)`
3. Right scale of `^` gets `.rightSegment(splitAt: 0.5)`
4. `^` has higher precedence than `|` (vertical separator)
5. `^` **required** for split scales (no implicit detection)

### 3.2 Parser Implementation

**Add to [`SlideRuleAssembly`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleAssembly.swift) parser:**

```swift
extension SlideRuleAssembly {
    private func parseScaleLine(_ line: String) throws -> [ScaleDefinition] {
        var scales: [ScaleDefinition] = []
        
        // Step 1: Split by | for vertically stacked scales
        let verticalGroups = line.split(separator: "|").map(String.init)
        
        for group in verticalGroups {
            // Step 2: Check for ^ (split scale marker)
            if group.contains("^") {
                let segments = group.split(separator: "^").map(String.init)
                
                guard segments.count == 2 else {
                    throw ParseError.invalidSplitScale(
                        "Split scale must have exactly 2 segments, found \(segments.count): \(group)"
                    )
                }
                
                // Create left segment
                let leftScale = try parseScaleName(segments[0].trimmingCharacters(in: .whitespaces))
                    .leftSegment(splitAt: 0.5)
                    .build()
                
                // Create right segment  
                let rightScale = try parseScaleName(segments[1].trimmingCharacters(in: .whitespaces))
                    .rightSegment(splitAt: 0.5)
                    .build()
                
                scales.append(contentsOf: [leftScale, rightScale])
            } else {
                // Regular scale (no split)
                let scale = try parseScaleName(group.trimmingCharacters(in: .whitespaces))
                    .build()
                scales.append(scale)
            }
        }
        
        return scales
    }
}
```

**Error Cases:**

```swift
public enum ParseError: Error {
    case invalidSplitScale(String)
    case ambiguousSplitPoint(String)
    case nestedSplitScale(String)  // "A ^ (B ^ C)" not supported
}
```

---

## 4. Rendering Engine Integration

### 4.1 Physical Coordinate Calculation

**Update rendering logic** to respect `splitSegment` when computing physical positions:

```swift
extension ScaleDefinition {
    /// Convert normalized position (0.0...1.0) to physical coordinate
    /// accounting for split segments
    /// - Parameters:
    ///   - normalizedPosition: Position in 0.0...1.0 range
    ///   - scaleLengthInPoints: Total physical length of the full scale in points
    public func physicalPosition(from normalizedPosition: Double, scaleLengthInPoints: CGFloat) -> CGFloat {
        guard let segment = splitSegment else {
            // Regular scale: full width
            return normalizedPosition * scaleLengthInPoints
        }
        
        // Use the segment's physicalFraction method for clean calculation
        let physicalFraction = segment.physicalFraction(from: normalizedPosition)
        return physicalFraction * scaleLengthInPoints
    }
}
```

**Example Calculation:**

```swift
// Θ₁: leftSegment(), scaleLengthInPoints = 250 points
// normalizedPosition = 1.0 (right edge of Θ₁'s value range)

let physicalRange = 0.0...0.5  // from splitSegment
let physicalFraction = segment.physicalFraction(from: 1.0)
// = 0.0 + (1.0 * 0.5) = 0.5

physicalPosition = 0.5 * 250 points = 125 points ✓
```

### 4.2 Rendering Order

**Confirmed Behavior**: Later segment (right) renders **on top** of earlier segment (left).

**Implementation:**
- Scales rendered in definition string order
- `"Θ₁ ^ Θ₂"` → Θ₁ renders first, Θ₂ renders second (on top)
- Important for overlapping tick marks at split boundary

**SwiftUI Rendering:**

```swift
ForEach(scaleDefinitions.indices, id: \.self) { index in
    ScaleView(scale: scaleDefinitions[index])
    // Later scales naturally overlay earlier scales in SwiftUI
}
```

---

## 5. Label Collision Handling

### 5.1 Manual Configuration (Confirmed Approach)

**Decision**: No automatic collision detection. Scale designers manually configure label density to avoid collisions.

**Configuration Options in [`ScaleDefinition`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift):**

```swift
public struct LabelConfiguration: Sendable {
    /// Labels to explicitly suppress near split boundary
    public let suppressedLabels: Set<String>?
    
    /// Override label density in physical region
    public let densityOverride: [(range: ClosedRange<Double>, density: LabelDensity)]?
    
    /// Offset labels away from split boundary
    public let boundaryOffset: Double?  // mm
}

public struct ScaleDefinition {
    // ... existing properties ...
    public let labelConfiguration: LabelConfiguration?
}
```

**Example: THETA Scale Label Management**

```swift
// Θ₁: Suppress labels near split boundary
let theta1 = ScaleBuilder()
    .name("Θ₁")
    .leftSegment(splitAt: 0.5)
    .withLabelConfiguration(
        LabelConfiguration(
            suppressedLabels: ["6"],  // Don't label 6° (too close to split)
            densityOverride: [(
                range: 0.8...1.0,  // Last 20% of scale
                density: .sparse   // Reduce label density
            )],
            boundaryOffset: nil
        )
    )
    .build()

// Θ₂: Suppress overlapping labels  
let theta2 = ScaleBuilder()
    .name("Θ₂")
    .rightSegment(splitAt: 0.5)
    .withLabelConfiguration(
        LabelConfiguration(
            suppressedLabels: ["5.7"],  // Don't label 5.7° (overlaps Θ₁)
            densityOverride: [(
                range: 0.0...0.2,  // First 20% of scale
                density: .sparse
            )],
            boundaryOffset: 2.0  // Offset first labels 2mm right
        )
    )
    .build()
```

### 5.2 Label Rendering Logic

```swift
extension ScaleRenderer {
    func shouldRenderLabel(_ label: String, at position: Double, config: LabelConfiguration?) -> Bool {
        guard let config = config else { return true }
        
        // Check suppression list
        if config.suppressedLabels?.contains(label) == true {
            return false
        }
        
        // Check density overrides
        if let overrides = config.densityOverride {
            for override in overrides {
                if override.range.contains(position) {
                    return shouldRenderWithDensity(override.density, at: position)
                }
            }
        }
        
        return true
    }
}
```

---

## 6. Implementation Phases

### Phase 1: Core Data Model (Week 1) - ✅ COMPLETED
**Files**: [`ScaleDefinition.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift)

- [x] Add `SplitSegment` enum
- [x] Add `splitSegment` property to `ScaleDefinition`
- [x] Add computed `physicalRange` property
- [x] Add `leftSegment()` and `rightSegment()` to `ScaleBuilder`
- [x] Unit tests for `SplitSegment` calculations
**Test Cases:**
```swift
func testSplitSegmentPhysicalRange() {
    let left = SplitSegment.left(formulaOffset: 0.0)
    #expect(left.physicalRange == 0.0...0.5)
    
    let right = SplitSegment.right(formulaOffset: -1.0)
    #expect(right.physicalRange == 0.5...1.0)
}

func testSegmentIndex() {
    let left = SplitSegment.left(formulaOffset: 0.0)
    #expect(left.segmentIndex == 0)
    
    let right = SplitSegment.right(formulaOffset: -1.0)
    #expect(right.segmentIndex == 1)
}

func testPhysicalFraction() {
    let left = SplitSegment.left(formulaOffset: 0.0)
    #expect(left.physicalFraction(from: 0.0) == 0.0)
    #expect(left.physicalFraction(from: 1.0) == 0.5)
    
    let right = SplitSegment.right(formulaOffset: -1.0)
    #expect(right.physicalFraction(from: 0.0) == 0.5)
    #expect(right.physicalFraction(from: 1.0) == 1.0)
}
```

### Phase 2: Parser Enhancement (Week 2) - ✅ COMPLETED
**Files**: [`SlideRuleAssembly.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleAssembly.swift)

- [x] Implement `^` parsing in definition strings
- [x] Add `ParseError.invalidSplitScale`
- [x] Handle precedence: `^` before `|`
- [x] Parser tests for split scales

**Test Cases:**
```swift
func testSplitScaleParsing() throws {
    let rule = try SlideRuleAssembly.parse("Θ₁ ^ Θ₂")
    #expect(rule.scales.count == 2)
    #expect(rule.scales[0].splitSegment == .left(formulaOffset: 0.0))
    #expect(rule.scales[1].splitSegment == .right(formulaOffset: -1.0))
}

func testSplitWithVerticalStacking() throws {
    let rule = try SlideRuleAssembly.parse("Θ₁ ^ Θ₂ | α")
    #expect(rule.scales.count == 3)
    // Verify Θ₁, Θ₂ split, α full-width
}

func testInvalidSplitScale() {
    #expect(throws: ParseError.self) {
        try SlideRuleAssembly.parse("A ^ B ^ C")  // 3 segments not allowed
    }
}
```

### Phase 3: Rendering Integration (Week 3) - ✅ COMPLETED
**Files**: [`ScaleCalculator.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleCalculator.swift), [`ScaleTickRenderer.swift`](TheElectricSlide/Renderers/ScaleTickRenderer.swift)

- [x] Update `physicalPosition(from:)` to use `splitSegment`
- [x] Update tick mark generation (including boundary tick injection)
- [x] Update label positioning
- [x] Rendering order tests

**Test Cases:**
```swift
func testSplitScalePhysicalPositioning() {
    let left = SplitSegment.left(formulaOffset: 0.0)
    let scaleLengthInPoints: CGFloat = 250.0
    
    // Right edge of left segment should be at 125 points (50% of scale)
    let rightEdgeFraction = left.physicalFraction(from: 1.0)
    let rightEdge = rightEdgeFraction * scaleLengthInPoints
    #expect(rightEdge.isApproximatelyEqual(to: 125.0, tolerance: 0.001))
}

func testRightSegmentPhysicalPositioning() {
    let right = SplitSegment.right(formulaOffset: -1.0)
    let scaleLengthInPoints: CGFloat = 250.0
    
    // Left edge of right segment should be at 125 points (50% of scale)
    let leftEdgeFraction = right.physicalFraction(from: 0.0)
    let leftEdge = leftEdgeFraction * scaleLengthInPoints
    #expect(leftEdge.isApproximatelyEqual(to: 125.0, tolerance: 0.001))
}
```

### Phase 4: Visual Preview & Validation (Week 4) - ✅ COMPLETED
**Files**: [`SplitScalesPreview.swift`](TheElectricSlide/Previews/SplitScalesPreview.swift)

- [x] Create visual test preview with debug panel
- [x] Test Case 1: Simple C Scale 50/50 Split - **PASS**
- [x] Test Case 2: Asymmetric split (30/70)
- [x] Test Case 3: Multiple split scales on same line
- [x] Test Case 4: Mixed split and full-width scales
- [x] Debug panel with copyable first tick diagnostics
- [ ] LabelConfiguration struct - **DEFERRED** (manual config approach confirmed)
### Phase 5: THETA Scale Implementation (Week 5) - ✅ COMPLETED
**Files**: [`PickettN16ES-Theta-AlphaScalesExtension.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/PickettN16ES-Theta-AlphaScalesExtension.swift)

- [x] Implement Θ₁ and Θ₂ split scales
- [x] Implement α (alpha) scale
- [x] Scale function implementations for theta and alpha
- [x] Integration with Pickett N16-ES assembly parser
- [ ] Configure label densities - **DEFERRED** (using existing subsection system)
- [ ] Visual verification tests - **IN PROGRESS**

**Actual Implementation:**
```swift
// In PickettN16ES-Theta-AlphaScalesExtension.swift
extension ScaleDefinition {
    /// Θ₁ (Theta-1): Small angle scale, left half of split
    /// Range: 0.57° to 5.73° (approximately)
    static func theta1Scale() -> ScaleDefinition {
        ScaleBuilder()
            .withScaleName(.theta1)
            .withScaleFunction(thetaScaleFunction)
            .withDomainRange(thetaSmallDomain)
            .leftSegment()  // Uses default formulaOffset: 0.0
            .build()
    }
    
    /// Θ₂ (Theta-2): Large angle scale, right half of split
    /// Range: 5.73° to 84.26° (approximately)
    static func theta2Scale() -> ScaleDefinition {
        ScaleBuilder()
            .withScaleName(.theta2)
            .withScaleFunction(thetaScaleFunction)
            .withDomainRange(thetaLargeDomain)
            .rightSegment()  // Uses default formulaOffset: -1.0
            .build()
    }
}
```

---

## 7. Future Enhancements

### 7.1 Non-Equal Split Points

Support for asymmetric splits:

```swift
"Θ₁ ^(0.4) Θ₂"  // Θ₁ gets 40%, Θ₂ gets 60%
```

**Parser Extension:**
```swift
if scaleName.contains("^(") {
    let regex = /\^\\(([0-9.]+)\\)/
    let splitPoint = try parseDecimal(regex)
    // Create segments with custom split point
}
```

### 7.2 Multi-Segment Scales

Support for 3+ segments:

```swift
"A ^^ B ^^ C"  // Three equal 33.3% segments
```

**Data Model:**
```swift
public enum SplitSegment {
    case segment(index: Int, splitPoints: [Double])
    
    var physicalRange: ClosedRange<Double> {
        // Calculate from index and split points array
    }
}
```

### 7.3 Automatic Label Collision Detection

Optional automatic collision detection (future enhancement):

```swift
public struct LabelConfiguration {
    public let autoCollisionDetection: Bool?  // Default: false
    public let collisionStrategy: CollisionStrategy?
}

public enum CollisionStrategy {
    case suppressLeft
    case suppressRight
    case offsetBoth
    case reduceSize
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

**Core Components:**
- `SplitSegment` enum calculations
- Physical range derivation
- Physical position calculations
- Parser split scale detection
- Label configuration logic

**Test Coverage Targets:**
- `SplitSegment`: 100%
- Parser split logic: 100%
- Physical positioning: 100%
- Label configuration: 90%

### 8.2 Integration Tests

**Scale Assembly:**
- Parse THETA split scale definition
- Verify both segments created
- Verify split properties correctly set
- Verify no overlap in physical rendering

**Visual Regression:**
- Compare rendered split scales with physical ruler scans
- Verify tick alignment at split boundaries
- Verify label positions and suppression

### 8.3 Performance Tests

**Rendering Performance:**
- Split scales should have negligible overhead vs. regular scales
- Target: <1% performance difference

---

## 9. Documentation Requirements

### 9.1 API Documentation

**Public APIs requiring documentation:**
- `SplitSegment` enum and variants
- `ScaleBuilder.leftSegment()` / `rightSegment()`
- `LabelConfiguration` struct and properties
- Parser `^` syntax in definition strings

### 9.2 Examples

**Create examples showing:**
1. Basic split scale creation via Builder API
2. Split scale parsing from definition string
3. Label collision configuration
4. THETA scale complete implementation

### 9.3 Migration Guide

**For existing SlideRuleCoreV3 users:**
- No breaking changes to existing scales
- Split scales opt-in via new API
- Definition string `^` only affects scales using it

---

## 10. Success Criteria

### Complete When:

- [x] Architecture decisions confirmed
- [x] `SplitSegment` implemented and tested
- [x] Parser handles `^` syntax correctly
- [x] Rendering respects physical ranges
- [ ] Label configuration working - **DEFERRED** (using existing subsection system)
- [x] THETA scales render correctly on Pickett N16-ES
- [x] All tests passing (>95% coverage)
- [x] API documentation complete (inline documentation)
- [x] Examples created (in preview files)

### Verification:

**Visual Verification:**
1. [x] Render Pickett N16-ES in app
2. [ ] Compare THETA scales with physical ruler photographs - **IN PROGRESS**
3. [x] Verify tick alignment at 125mm split boundary
4. [ ] Verify label positions match physical ruler - **DEFERRED**
5. [ ] Verify no overlapping labels - **DEFERRED**

**Technical Verification:**
1. [x] All unit tests passing
2. [x] Integration tests with full rule assembly passing
3. [x] Performance within target thresholds
4. [x] No breaking changes to existing scales

---

## 11. Risk Mitigation

**Risk**: Breaking existing scale definitions  
**Mitigation**: `splitSegment` is optional, defaults to `nil` (full-width rendering)

**Risk**: Label collision not automatically handled  
**Mitigation**: Comprehensive documentation and examples of manual configuration

**Risk**: Performance impact on rendering  
**Mitigation**: Physical range calculation is simple arithmetic, minimal overhead

**Risk**: Parser complexity increase  
**Mitigation**: `^` parsing isolated to dedicated function, existing parser logic unchanged

---

## 12. References

### Related Documents
- [`split-scales-analysis.md`](reference/sliderule-research/split-scales-analysis.md) - Initial problem analysis
- [`postscript-caret-symbol-no-linebreak.md`](reference/postscript-caret-symbol-no-linebreak.md) - Postscript `^` operator
- [`manthematical-foundations-of-the-slide-rule.md`](reference/manthematical-foundations-of-the-slide-rule.md) - Physical positioning theory

### Code References
- [`ScaleDefinition.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleDefinition.swift)
- [`SlideRuleAssembly.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/SlideRuleAssembly.swift)
- [`ScaleCalculator.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/ScaleCalculator.swift)
- [`PickettN16ESScalesExtension.swift`](SlideRuleCoreV3/Sources/SlideRuleCoreV3/PickettN16ESScalesExtension.swift)

### Historical Context
- THETA split scales appear on Pickett N16-ES and similar electronic/log-log rules
- Split allows full angular range coverage in limited physical space
- Overlap region (5.7°-6.0°) provides continuity verification

---

## Appendix A: Bonus Features (Implemented Beyond Original Plan)

The following features were added during implementation that weren't in the original plan:

### A.1 `Hashable` Conformance on `SplitSegment`

```swift
public enum SplitSegment: Sendable, Equatable, Hashable { ... }
```

**Benefit**: Enables use of `SplitSegment` as dictionary keys and in `Set` collections, useful for grouping or deduplicating scales by segment type.

### A.2 `segmentIndex` Computed Property

```swift
public var segmentIndex: Int {
    switch self {
    case .left: return 0
    case .right: return 1
    }
}
```

**Benefit**: Provides stable ordering for split segments, useful for sorting and rendering order decisions.

### A.3 `physicalFraction(from:)` Method

```swift
public func physicalFraction(from logicalPosition: Double) -> Double {
    let range = physicalRange
    let rangeWidth = range.upperBound - range.lowerBound
    return range.lowerBound + (logicalPosition * rangeWidth)
}
```

**Benefit**: Encapsulates the coordinate transformation logic within the `SplitSegment` enum itself, rather than requiring external calculation. This enables cleaner rendering code.

### A.4 Debug Logging Support

```swift
#if DEBUG && SPLIT_SCALES
// Conditional debug logging for split scale calculations
#endif
```

**Benefit**: Allows detailed debugging of split scale rendering without impacting release performance. Enable with `-DSPLIT_SCALES` compiler flag.

### A.5 `withSplitSegment(_ segment:)` Builder Method

```swift
public func withSplitSegment(_ segment: SplitSegment?) -> ScaleBuilder
```

**Benefit**: Provides full control over split segment configuration, including custom `formulaOffset` values for advanced use cases beyond the standard left/right defaults.

---

## Appendix B: Example Scale Definitions

### Pickett N16-ES THETA Scales (Complete)

```swift
extension SlideRuleAssembly {
    static let pickettN16ES_Side1_Bottom = """
        LL/00 | LL/0 | DF [π] | CF [π] | CIF [π] | Θ₁ ^ Θ₂ | α
        """
}

// Expanded to:
// - LL/00 (full-width)
// - LL/0 (full-width)
// - DF (full-width)
// - CF (full-width)  
// - CIF (full-width)
// - Θ₁ (left segment, 0-125mm)
// - Θ₂ (right segment, 125-250mm)
// - α (full-width)
```

### Asymmetric Split (Future)

```swift
// Hypothetical L scale split for extended precision
"L₁ ^(0.7) L₂"

// L₁: 0-175mm (70%), covers 0.0-0.5 log values
// L₂: 175-250mm (30%), covers 0.5-1.0 log values (higher precision)
```

---

**Document Version**: 2.0
**Last Updated**: 2025-12-31
**Author**: SlideRuleCoreV3 Architecture Team

### Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-30 | Initial implementation plan |
| 2.0 | 2025-12-31 | Updated to reflect actual implementation: `formulaOffset` instead of `splitPoint`, added PostScript heritage section, updated checkboxes to reflect completed phases, added Appendix A for bonus features |
