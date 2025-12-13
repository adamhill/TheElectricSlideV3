# Tag Usage Guide for SlideRuleCoreV3 Tests
**Last Updated**: December 13, 2025

---

## Tag Taxonomy Overview

The SlideRuleCoreV3 test suite uses a hierarchical tag system for efficient test filtering and organization. Tags are defined in `TestTags+Local.swift` and follow consistent naming conventions.

---

## Tag Categories

### 1. Workflow Tags
Used to control which tests run in different contexts.

| Tag | Purpose | When to Use | Example |
|-----|---------|-------------|---------|
| `.fast` | Quick-running tests (< 1 sec) | Tests suitable for watch mode, pre-commit hooks | Position calculations, simple transforms |
| `.regression` | Tests that verify fixed bugs | All tests that prevent known issues from returning | Alignment bugs, parser edge cases |
| `.flaky` | Known unreliable tests | Temporarily mark tests that fail intermittently (fix root cause ASAP) | Network-dependent tests, timing-sensitive |

**CLI Examples:**
```bash
# Run only fast tests (development watch mode)
swift test --filter .fast

# Run regression suite (pre-merge validation)
swift test --filter .regression

# Run all tests except flaky ones (CI environment)
swift test --skip .flaky
```

### 2. Feature Tags
Categorize tests by functional area.

| Tag | Purpose | When to Use |
|-----|---------|-------------|
| `.parsing` | Rule definition parser tests | Tests that exercise `RuleDefinitionParser` |
| `.formatting` | Label and number formatting | Tests for `LabelFormatter`, number display |
| `.alignment` | Scale alignment verification | Tests that verify scale relationships (e.g., F × λ = 300) |
| `.circular` | Circular scale geometry | Tests specific to circular/radial scale layouts |
| `.performance` | Performance benchmarks | Tests that measure execution time, not correctness |
| `.tickGeneration` | Tick mark generation | Tests for `ScaleCalculator.generateTickMarks()` |
| `.labelLevels` | Label level behavior | Tests for label density and leveling |
| `.density` | Label density tests | Tests that verify label spacing and density |

**CLI Examples:**
```bash
# Run all parser tests
swift test --filter .parsing

# Run all alignment verification tests
swift test --filter .alignment

# Run formatting tests (useful when working on label display)
swift test --filter .formatting
```

### 3. Scale-Specific Tags
Filter tests for individual scales.

| Tag | Scale | Use Case |
|-----|-------|----------|
| `.cScale` | C scale | C scale implementation work |
| `.dScale` | D scale | D scale implementation work |
| `.ciScale` | CI scale (inverted) | Inverted C scale work |
| `.diScale` | DI scale (inverted) | Inverted D scale work |
| `.cfScale` | CF scale (folded) | Folded C scale work |
| `.dfScale` | DF scale (folded) | Folded D scale work |
| `.cifScale` | CIF scale (inverted folded) | CIF implementation work |
| `.difScale` | DIF scale (inverted folded) | DIF implementation work |
| `.dfmScale` | DF_M scale | DF_M (folded at modulus) |
| `.kscale` | K scale (cubes) | K scale work |
| `.bScale` | B scale | B scale work |
| `.foldedScale` | All folded scales | Any folded scale type |

**CLI Examples:**
```bash
# Run all C scale tests while working on C scale improvements
swift test --filter .cScale

# Run all inverted scale tests
swift test --filter .ciScale --filter .diScale

# Run all folded scale tests
swift test --filter .foldedScale
```

### 4. Historical Slide Rule Tags
Tests for specific historical slide rule models.

| Tag | Slide Rule | Use Case |
|-----|-----------|----------|
| `.pickettN16ES` | Pickett N-16 ES | Electronics slide rule (1960s) |
| `.hemmi266` | Hemmi 266 | Electronics slide rule |
| `.keuffelEsser4081` | K&E 4081-3 | Log-Log Duplex Decitrig (1943-1975) |
| `.pickett803` | Pickett 803 | Slide rule with DF_M scale |
| `.historicalAccuracy` | Any historical rule | Tests verifying against documented specs |
| `.historicalExample` | Any historical rule | Tests based on worked examples from manuals |

**CLI Examples:**
```bash
# Run all Pickett N-16 ES tests
swift test --filter .pickettN16ES

# Run all historical accuracy tests
swift test --filter .historicalAccuracy

# Run all Hemmi 266 tests
swift test --filter .hemmi266
```

---

## Tag Combination Patterns

### Pattern 1: Rule-Specific Historical Tests
Use both rule tag and historical tag:
```swift
@Suite("ω and τ Scale Alignment", .tags(.pickettN16ES, .alignment, .historicalAccuracy))
struct OmegaTauAlignmentTests { ... }
```

**Why:** Makes it easy to filter by rule OR by historical accuracy category.

**CLI Usage:**
```bash
# All Pickett N-16 ES tests
swift test --filter .pickettN16ES

# All historical accuracy tests (across all rules)
swift test --filter .historicalAccuracy
```

### Pattern 2: Feature + Workflow Tags
Combine feature tags with workflow tags:
```swift
@Suite("Parser and Error Handling Tests", .tags(.parsing, .regression))
struct ParserAndErrorHandlingTests { ... }
```

**Why:** Identifies what the test does AND when it should run.

**CLI Usage:**
```bash
# All parser tests (any workflow)
swift test --filter .parsing

# All regression tests (any feature)
swift test --filter .regression
```

### Pattern 3: Scale + Feature Tags
For scale-specific feature tests:
```swift
@Suite("C Scale First Subsection Formatter", .tags(.cScale, .dScale, .formatting))
struct CScaleFirstSubsectionFormatterTests { ... }
```

**Why:** Identifies which scales are affected AND what aspect is being tested.

### Pattern 4: Multiple Scale Tags
When tests apply to multiple scales:
```swift
@Suite("Inverted Scales Subsection Tests", .tags(.ciScale, .diScale))
struct InvertedScalesSubsectionTests { ... }
```

**CLI Usage:**
```bash
# All CI scale tests OR all DI scale tests
swift test --filter .ciScale --filter .diScale
```

---

## Naming Conventions

### Scale Tags
- **Format**: camelCase starting with lowercase
- **Examples**: `.cScale`, `.ll3Scale`, `.dfmScale`
- **Pattern**: `.[scaleName]Scale` where scaleName is the canonical name

### Rule Tags  
- **Format**: camelCase with manufacturer prefix
- **Examples**: `.pickettN16ES`, `.hemmi266`, `.keuffelEsser4081`
- **Pattern**: `.[manufacturer][model]` with no spaces or special characters

### Feature Tags
- **Format**: descriptive nouns, camelCase
- **Examples**: `.parsing`, `.formatting`, `.alignment`, `.tickGeneration`
- **Pattern**: `.[featureName]` describing the functional area

### Workflow Tags
- **Format**: lowercase single word
- **Examples**: `.fast`, `.slow`, `.regression`, `.flaky`
- **Pattern**: `.[adjective]` describing test characteristic

---

## When to Add a New Tag

### ✅ Good Reasons to Add a Tag
1. **New Historical Rule**: Adding tests for a new slide rule model
   - Example: `.faber-castell2/83n` for Faber-Castell 2/83 N
2. **New Functional Area**: Adding a distinct new feature category
   - Example: `.import` for tests of scale import functionality
3. **New Workflow Need**: Need to filter tests by execution characteristic
   - Example: `.slow` for tests taking > 10 seconds

### ❌ Poor Reasons to Add a Tag
1. **One-off Grouping**: If only 1-2 tests would use it
   - Solution: Use nested @Suite instead
2. **Too Granular**: Tag for every minor variation
   - Example: `.cScaleFirstSubsection` (too specific - use nested suite)
3. **Duplicate Category**: Tag that overlaps existing ones
   - Example: `.quickTests` when `.fast` already exists

---

## Tag Usage in Test Files

### Example 1: Simple Suite with Single Tag
```swift
@Suite("K Scale Label Density Verification", .tags(.kscale, .density))
struct KScaleLabelDensityTests {
    // Tests...
}
```

### Example 2: Nested Suites with Inherited Tags
```swift
@Suite("Pickett N-16 ES Electronic Scales", .tags(.pickettN16ES, .historicalAccuracy))
struct PickettN16ESTests {
    
    @Suite("Resonant Frequency Calculations")
    struct ResonantFrequencyTests {
        // Inherits .pickettN16ES and .historicalAccuracy from parent
        
        @Test("Tank circuit example from N-16 ES manual")
        func testTankCircuit() { ... }
    }
}
```

### Example 3: Test-Level Tags (Override or Add)
```swift
@Suite("Parser Tests", .tags(.parsing))
struct ParserTests {
    
    @Test("Fast parser smoke test", .tags(.fast))
    func quickParseTest() { ... }
    
    @Test("Comprehensive fuzz test", .tags(.slow))
    func fuzzTest() { ... }
}
```

**Note**: Test-level tags are ADDED to suite-level tags (not replaced).

---

## CLI Filtering Reference

### Basic Filtering

```bash
# Run tests with specific tag
swift test --filter .pickettN16ES

# Run tests WITHOUT specific tag
swift test --skip .flaky

# Multiple filters (OR logic - any tag matches)
swift test --filter .cScale --filter .dScale

# Combined filter and skip
swift test --filter .regression --skip .slow
```

### Advanced Filtering

```bash
# Run fast tests for specific rule
swift test --filter .fast --filter .pickettN16ES

# Run all historical tests except slow ones
swift test --filter .historicalAccuracy --skip .slow

# Development workflow: fast tests excluding flaky
swift test --filter .fast --skip .flaky
```

### Xcode Test Plan Integration

In Xcode Test Plans, you can:
1. **Include Tags**: Only run tests with specific tags
2. **Exclude Tags**: Skip tests with specific tags
3. **Build Configurations**: Different tag sets for Debug vs Release

**Example Test Plan Configuration:**
- **Development Plan**: Include `.fast`, Exclude `.slow`, `.flaky`
- **CI Plan**: Include `.regression`, Exclude `.flaky`
- **Historical Validation Plan**: Include `.historicalAccuracy`

---

## Tag Maintenance

### Periodic Review Checklist

Every 3-6 months, review:

- [ ] Are all tags actually used? (Search: `grep -r "\.tags(.*\.tagName" Tests/`)
- [ ] Are there tags with < 3 tests? (Consider removing)
- [ ] Are there duplicate/overlapping tags?
- [ ] Do tag names still make sense?
- [ ] Are new rule-specific tags needed?

### Deprecating Tags

If a tag is no longer useful:

1. Comment it out in `TestTags+Local.swift` with deprecation notice:
```swift
// @Tag public static var oldTag: Self  // DEPRECATED: Use .newTag instead
```

2. Update all test files to use new tag

3. After one release cycle, remove the tag completely

---

## Examples from Codebase

### Excellent Tag Usage

**PickettN16ESTests.swift:**
```swift
@Suite("Pickett N-16 ES Electronic Scales", .tags(.pickettN16ES, .historicalAccuracy))
struct PickettN16ESTests { ... }

@Suite("F × λ = 300 Scale Alignment", .tags(.pickettN16ES))
struct FLambdaAlignmentTests { ... }
```
✅ Clear rule identification, historical accuracy tag

**Hemmi266ParserTests.swift:**
```swift
@Suite("Hemmi 266 Parser Definition Tests", .tags(.hemmi266, .parsing, .fast, .regression))
struct Hemmi266ParserTests { ... }
```
✅ Rule + feature + workflow tags for maximum flexibility

**CScaleFirstSubsectionFormatterTests.swift:**
```swift
@Suite("C Scale First Subsection Formatter", .tags(.cScale, .dScale, .formatting))
struct CScaleFirstSubsectionFormatterTests { ... }
```
✅ Multiple scale tags + feature tag

---

## Quick Reference Card

```
WORKFLOW        FEATURE              SCALE           RULE
.fast           .parsing             .cScale         .pickettN16ES
.regression     .formatting          .dScale         .hemmi266
.flaky          .alignment           .ciScale        .keuffelEsser4081
.slow           .circular            .kscale         .pickett803
                .performance         .ll3Scale       
                .tickGeneration      .dfmScale       .historicalAccuracy
                .labelLevels         .foldedScale    .historicalExample
                .density
```

**Tag Combination Template:**
```swift
@Suite("Test Name", .tags(.[rule], .[feature], .[workflow]))
```

---

## Summary

- **Use multiple tags** for better filtering options
- **Follow naming conventions** for consistency
- **Document WHY** tests matter in rule-specific tests
- **Review tags periodically** to prevent tag proliferation
- **CLI filtering** is the primary use case - optimize for that

---

**Document Version**: 1.0  
**Author**: AI Coding Agent  
**Last Updated**: December 13, 2025
