# Test Folder Organization Scheme for SlideRuleCoreV3
**Version**: 1.0  
**Date**: December 13, 2025  
**Status**: Implemented

---

## Executive Summary

With **~40 current test files**, **90+ implemented scales**, and plans for more slide rules and scales, we need a scalable folder structure that:
- Groups related tests logically
- Scales to 100+ test files without confusion
- Makes rule-specific and scale-specific tests easily discoverable
- Follows Swift Testing best practices

---

## Current State Analysis

### By the Numbers
- **41 test files** (current)
- **90+ scales implemented** (most untested)
- **10 scale-specific test files**
- **2-3 rule-specific test files** (Pickett N16-ES, Hemmi 266)
- **925+ @Test annotations**

### Future Projections
- **100+ potential scale tests** (one per scale)
- **10-20+ rule-specific suites** (historical slide rules)
- **Total: 150-200+ test files** at full coverage

---

## Proposed Folder Structure

```
SlideRuleCoreV3Tests/
├── Infrastructure/
│   ├── TestTags.swift (renamed from TestTags+Local.swift)
│   ├── TestUtilities/ (existing)
│   └── SharedTestUtilities.swift (if exists)
│
├── Core/
│   ├── Calculator/
│   │   ├── PositionCalculationTests.swift
│   │   ├── ScaleCalculatorPrecisionTests.swift
│   │   └── ScalePositionCalculationsTests.swift
│   │
│   ├── Parser/
│   │   ├── ParserAndErrorHandlingTests.swift
│   │   ├── SlideRuleAssemblyFuzzTests.swift
│   │   ├── SlideRuleAssemblyParserCountTests.swift
│   │   └── TickDirectionModifierTests.swift
│   │
│   ├── Functions/
│   │   ├── ScaleFunctionImplementationsTests.swift
│   │   ├── ElectricalEngineeringScaleFunctionsTests.swift
│   │   └── HyperbolicScaleFunctionsTests.swift
│   │
│   └── Utilities/
│       ├── ScaleUtilitiesTests.swift
│       └── SlideRuleCorePerformanceTests.swift
│
├── Scales/
│   ├── Individual/
│   │   ├── StandardScales/
│   │   │   ├── CScaleTests.swift (consolidate C scale tests)
│   │   │   ├── DScaleTests.swift
│   │   │   ├── KScaleTests.swift (consolidate K scale tests)
│   │   │   ├── LScaleTests.swift (consolidate L scale tests)
│   │   │   └── WScaleTests.swift
│   │   │
│   │   ├── FoldedScales/
│   │   │   └── DFmScaleTests.swift
│   │   │
│   │   ├── InvertedScales/
│   │   │   └── InvertedScalesSubsectionTests.swift
│   │   │
│   │   ├── LogLogScales/
│   │   │   └── StandardScalesExoticTests.swift (LL scales)
│   │   │
│   │   └── SpecializedScales/
│   │       ├── ElectricalEngineeringScalesTests.swift
│   │       └── HyperbolicScalesTests.swift
│   │
│   ├── Parity/
│   │   ├── StandardScalesABParityTests.swift (renamed)
│   │   ├── StandardScalesCDParityTests.swift (renamed)
│   │   └── StandardScalesCFDFParityTests.swift (renamed)
│   │
│   ├── Geometry/
│   │   ├── ScaleCircularGeometryTests.swift
│   │   ├── LabelLevelsTests.swift
│   │   └── ModuloTickGenerationTests.swift
│   │
│   └── Cursor/
│       ├── CursorPrecisionIntegrationTests.swift
│       ├── CursorPrecisionTests.swift
│       ├── CursorValueBoundaryTests.swift
│       ├── CursorValueKnownValueTests.swift
│       └── CursorValueRoundTripTests.swift
│
├── Rules/
│   ├── PickettN16ES/
│   │   ├── PickettN16ESScalesTests.swift (renamed from PickettN16ESTests.swift)
│   │   └── PickettN16ESOmegaTauAlignmentTests.swift (renamed from OmegaTauAlignmentTests.swift)
│   │
│   ├── Hemmi266/
│   │   ├── Hemmi266ParserTests.swift
│   │   └── Hemmi266LogLogScalesTests.swift
│   │
│   ├── KeuffelEsser4081/ (FUTURE)
│   │   └── KE4081LogLogDuplexDecitrigTests.swift
│   │
│   ├── Pickett803/ (FUTURE)
│   │   └── Pickett803Tests.swift
│   │
│   └── FaberCastell/ (FUTURE)
│       └── FaberCastell283NTests.swift
│
└── testing-docs/
    ├── TEST_ORGANIZATION_SUMMARY.md
    ├── TEST_ORGANIZATION_RECOMMENDATIONS.md
    ├── TAG_USAGE_GUIDE.md
    └── TEST_FOLDER_ORGANIZATION_SCHEME.md (this file)
```

---

## Naming Conventions

### File Naming Pattern
**Pattern**: `[Scope][Scale/Feature][Type]Tests.swift`

Examples:
- `CScaleTests.swift` - Individual scale tests
- `StandardScalesABParityTests.swift` - Parity comparison
- `PickettN16ESScalesTests.swift` - Rule-specific scale tests
- `ParserAndErrorHandlingTests.swift` - Feature tests
- `CursorPrecisionIntegrationTests.swift` - Integration tests

### Consolidation Rules
When multiple test files exist for the same scale/feature:

**Before:**
```
CScaleFirstSubsectionFormatterTests.swift
CScaleLabelDensityTests.swift
CScaleTickMarkTests.swift
```

**After:**
```
Scales/Individual/StandardScales/CScaleTests.swift
@Suite("C Scale Tests")
struct CScaleTests {
    @Suite("First Subsection Formatter")
    struct FirstSubsectionFormatterTests { ... }
    
    @Suite("Label Density")
    struct LabelDensityTests { ... }
    
    @Suite("Tick Mark Generation")
    struct TickMarkTests { ... }
}
```

### Suffix Consistency
Always use **"Tests"** (plural) suffix:
- ✅ `CScaleTests.swift`
- ✅ `ParserAndErrorHandlingTests.swift`
- ❌ `CScaleTest.swift` (singular - incorrect)

---

## Folder Categories Explained

### 1. Infrastructure/
**Purpose**: Test support files, tags, utilities

**Contains**:
- Tag definitions (`TestTags.swift`)
- Test utilities and helpers (`TestUtilities/`)
- Shared test infrastructure

**Why separate**: These aren't tests themselves, they support tests.

### 2. Core/
**Purpose**: Tests for core SlideRuleCoreV3 functionality

**Subcategories**:
- **Calculator/**: Position calculations, value lookups
- **Parser/**: Rule definition parsing, error handling
- **Functions/**: Scale function implementations (transform/inverse)
- **Utilities/**: Utility functions, performance benchmarks

**Why separate**: Core library functionality vs. scale-specific behavior.

### 3. Scales/
**Purpose**: Tests for scale behavior and properties

**Subcategories**:
- **Individual/**: Tests for specific scales
  - **StandardScales/**: C, D, A, B, K, L, etc.
  - **FoldedScales/**: CF, DF, DF_M, etc.
  - **InvertedScales/**: CI, DI, CIF, DIF, etc.
  - **LogLogScales/**: LL1, LL2, LL3, LL00, etc.
  - **SpecializedScales/**: EE scales, hyperbolic, trigonometric
- **Parity/**: Cross-scale validation (A/B match, C/D match, etc.)
- **Geometry/**: Tick marks, labels, circular geometry
- **Cursor/**: Cursor precision and value reading

**Why separate**: Scales are the primary domain objects. Different scale types have different behaviors.

**Scalability**: With 90+ scales, this structure keeps related tests together without cluttering a single directory.

### 4. Rules/
**Purpose**: Tests for specific historical slide rules

**Organization**: One folder per manufacturer/model

**Contents**: Each rule folder contains:
- Scale alignment tests (e.g., F × λ = 300 for Pickett N16-ES)
- Parser definition tests
- Historical accuracy verification
- Worked examples from manuals

**Why separate**: 
- Rule-specific tests verify historical accuracy
- Different rules have different scale combinations
- Tests document WHY alignments matter (educational)

**Scalability**: As we add K&E 4081-3, Faber-Castell 2/83N, etc., each gets its own folder.

---

## Migration Strategy

### Phase 1: Create Folder Structure ✅
Create all directories in the new structure.

### Phase 2: Move Files with Git (Preserves History) ✅
Use `git mv` to preserve file history:

```bash
# Move individual scale tests
git mv CScaleFirstSubsectionFormatterTests.swift Scales/Individual/StandardScales/CScaleTests.swift

# Move rule-specific tests
git mv PickettN16ESTests.swift Rules/PickettN16ES/PickettN16ESScalesTests.swift
git mv OmegaTauAlignmentTests.swift Rules/PickettN16ES/PickettN16ESOmegaTauAlignmentTests.swift

# Move core functionality tests
git mv ParserAndErrorHandlingTests.swift Core/Parser/ParserAndErrorHandlingTests.swift
git mv PositionCalculationTests.swift Core/Calculator/PositionCalculationTests.swift
```

### Phase 3: Update Package.swift (if needed) ✅
Swift Package Manager automatically discovers test files in any subdirectory of `Tests/`.

No changes needed unless using explicit file lists.

### Phase 4: Consolidate Related Tests (Optional)
Merge related test files into single files with nested suites:

**Example: K Scale Consolidation**
```swift
// Scales/Individual/StandardScales/KScaleTests.swift
@Suite("K Scale Tests", .tags(.kscale))
struct KScaleTests {
    @Suite("Label Formatter")
    struct FormatterTests {
        // Move content from KScaleFormatterTests.swift
    }
    
    @Suite("Label Density Verification", .tags(.density))
    struct LabelDensityTests {
        // Move content from KScaleLabelDensityTests.swift
    }
}
```

### Phase 5: Rename for Consistency ✅
Ensure all files use "Tests" plural suffix.

### Phase 6: Update Documentation ✅
Update all documentation to reference new paths.

---

## File Mapping (Current → New)

### Infrastructure
```
TestTags+Local.swift → Infrastructure/TestTags.swift
TestUtilities/ → Infrastructure/TestUtilities/ (no change)
```

### Core
```
PositionCalculationTests.swift → Core/Calculator/PositionCalculationTests.swift
ScaleCalculatorPrecisionTests.swift → Core/Calculator/ScaleCalculatorPrecisionTests.swift
ScalePositionCalculationsTests.swift → Core/Calculator/ScalePositionCalculationsTests.swift

ParserAndErrorHandlingTests.swift → Core/Parser/ParserAndErrorHandlingTests.swift
SlideRuleAssemblyFuzzTests.swift → Core/Parser/SlideRuleAssemblyFuzzTests.swift
SlideRuleAssemblyParserCountTests.swift → Core/Parser/SlideRuleAssemblyParserCountTests.swift
TickDirectionModifierTests.swift → Core/Parser/TickDirectionModifierTests.swift

ScaleFunctionImplementationsTests.swift → Core/Functions/ScaleFunctionImplementationsTests.swift
ElectricalEngineeringScaleFunctionsTests.swift → Core/Functions/ElectricalEngineeringScaleFunctionsTests.swift
HyperbolicScaleFunctionsTests.swift → Core/Functions/HyperbolicScaleFunctionsTests.swift

ScaleUtilitiesTests.swift → Core/Utilities/ScaleUtilitiesTests.swift
SlideRuleCorePerformanceTests.swift → Core/Utilities/SlideRuleCorePerformanceTests.swift
```

### Scales
```
CScaleFirstSubsectionFormatterTests.swift → Scales/Individual/StandardScales/CScaleTests.swift (consolidate)
KScaleFormatterTests.swift → Scales/Individual/StandardScales/KScaleTests.swift (consolidate)
KScaleLabelDensityTests.swift → Scales/Individual/StandardScales/KScaleTests.swift (consolidate)
LScaleModuloAlgorithmTest.swift → Scales/Individual/StandardScales/LScaleTests.swift (consolidate)
LScaleRenderingDebugTest.swift → Scales/Individual/StandardScales/LScaleTests.swift (consolidate)
LScaleTickMarkTests.swift → Scales/Individual/StandardScales/LScaleTests.swift (consolidate)
WScaleLabelTests.swift → Scales/Individual/StandardScales/WScaleTests.swift

DFmScaleTests.swift → Scales/Individual/FoldedScales/DFmScaleTests.swift

InvertedScalesSubsectionTests.swift → Scales/Individual/InvertedScales/InvertedScalesSubsectionTests.swift

StandardScalesExoticTests.swift → Scales/Individual/LogLogScales/StandardScalesExoticTests.swift

ElectricalEngineeringScalesTests.swift → Scales/Individual/SpecializedScales/ElectricalEngineeringScalesTests.swift
HyperbolicScalesTests.swift → Scales/Individual/SpecializedScales/HyperbolicScalesTests.swift

StandardScalesABParityTest.swift → Scales/Parity/StandardScalesABParityTests.swift (rename)
StandardScalesCDParityTest.swift → Scales/Parity/StandardScalesCDParityTests.swift (rename)
StandardScalesCFDFParityTest.swift → Scales/Parity/StandardScalesCFDFParityTests.swift (rename)

ScaleCircularGeometryTests.swift → Scales/Geometry/ScaleCircularGeometryTests.swift
LabelLevelsTests.swift → Scales/Geometry/LabelLevelsTests.swift
ModuloTickGenerationTests.swift → Scales/Geometry/ModuloTickGenerationTests.swift

CursorPrecisionIntegrationTests.swift → Scales/Cursor/CursorPrecisionIntegrationTests.swift
CursorPrecisionTests.swift → Scales/Cursor/CursorPrecisionTests.swift
CursorValueBoundaryTests.swift → Scales/Cursor/CursorValueBoundaryTests.swift
CursorValueKnownValueTests.swift → Scales/Cursor/CursorValueKnownValueTests.swift
CursorValueRoundTripTests.swift → Scales/Cursor/CursorValueRoundTripTests.swift
```

### Rules
```
PickettN16ESTests.swift → Rules/PickettN16ES/PickettN16ESScalesTests.swift (rename)
OmegaTauAlignmentTests.swift → Rules/PickettN16ES/PickettN16ESOmegaTauAlignmentTests.swift (rename)

Hemmi266ParserTests.swift → Rules/Hemmi266/Hemmi266ParserTests.swift
Hemmi266LogLogScalesTests.swift → Rules/Hemmi266/Hemmi266LogLogScalesTests.swift
```

### Cleanup
```
DummyTst.swift → DELETE (placeholder file)
```

---

## Benefits of This Structure

### 1. Scalability
- **Current**: 41 files in flat directory (manageable but cluttered)
- **With 100 scales**: 100+ files in flat directory (overwhelming)
- **With folders**: Logical grouping, ~15 files per folder max

### 2. Discoverability
**Before**: "Where are the Pickett N16-ES tests?"
**After**: `Rules/PickettN16ES/` - clear and obvious

**Before**: "Which tests cover the C scale?"
**After**: `Scales/Individual/StandardScales/CScaleTests.swift`

### 3. Maintainability
- Related tests grouped together
- Clear boundaries between core, scales, and rules
- Easier to navigate in IDE

### 4. Educational Value
- `Rules/` folder documents historical slide rules
- Each rule folder is self-contained
- Clear separation of concerns

### 5. Future Growth
- Adding new scale: Create file in `Scales/Individual/[Category]/`
- Adding new rule: Create folder in `Rules/[Manufacturer]/`
- Adding new core feature: Add to appropriate `Core/` subfolder

---

## Testing the Migration

### Verify Structure
```bash
# Check folder structure
find SlideRuleCoreV3Tests -type d | sort

# Count files per directory
find SlideRuleCoreV3Tests -name "*.swift" -type f | xargs dirname | sort | uniq -c

# Verify test discovery
swift test --list-tests
```

### Run Tests After Migration
```bash
# Run all tests to ensure nothing broke
swift test

# Run by tag to verify tags still work
swift test --filter .pickettN16ES
swift test --filter .parsing
swift test --filter .fast
```

### Check Git History
```bash
# Verify file history preserved
git log --follow Rules/PickettN16ES/PickettN16ESScalesTests.swift

# Should show history from original file
```

---

## Future Additions Guide

### Adding a New Scale Test
**Location**: `Scales/Individual/[Category]/[ScaleName]Tests.swift`

**Example: Adding LL01 Scale Tests**
```swift
// Scales/Individual/LogLogScales/LL01ScaleTests.swift
@Suite("LL01 Scale Tests", .tags(.ll01Scale, .logLogScale))
struct LL01ScaleTests {
    @Suite("Range Verification")
    struct RangeTests { ... }
    
    @Suite("Transform Accuracy")
    struct TransformTests { ... }
}
```

### Adding a New Rule Test Suite
**Location**: `Rules/[Manufacturer][Model]/`

**Example: Adding Keuffel & Esser 4081-3**
```
Rules/KeuffelEsser4081/
├── KE4081LogLogDuplexDecitrigTests.swift
├── KE4081LLScaleAlignmentTests.swift
└── KE4081DecitrigLayoutTests.swift
```

**Template in**: `TEST_ORGANIZATION_RECOMMENDATIONS.md` section 6

### Adding a New Core Feature
**Location**: `Core/[Category]/[Feature]Tests.swift`

**Example: Adding Import/Export Tests**
```swift
// Core/Utilities/ImportExportTests.swift
@Suite("Import/Export Utilities", .tags(.import, .export))
struct ImportExportTests { ... }
```

---

## Implementation Checklist

- [x] Create folder structure
- [x] Move files with git mv (preserve history)
- [x] Rename files for consistency ("Tests" suffix)
- [x] Update TestTags.swift location reference
- [x] Verify Package.swift doesn't need changes
- [x] Update documentation with new paths
- [ ] Optional: Consolidate C, K, L scale tests (future)
- [ ] Optional: Run full test suite verification (future)

---

## FAQs

### Q: Will this break existing imports?
**A**: No. Swift Package Manager discovers test files recursively. No import changes needed.

### Q: Should we consolidate all scale tests now?
**A**: No. Move files first, consolidate later. Don't mix restructuring with refactoring.

### Q: What about the "testing-docs" folder?
**A**: Keep at root level. It's documentation, not test infrastructure.

### Q: How do I run tests for a specific rule?
**A**: Use tags: `swift test --filter .pickettN16ES`

### Q: Can I still run tests from Xcode?
**A**: Yes. Xcode's test navigator shows the same structure. Files are grouped by folder.

---

## Summary

This organization scheme:
- ✅ Handles current 41 test files
- ✅ Scales to 150-200+ test files
- ✅ Groups by logical category (Core, Scales, Rules)
- ✅ Makes rule-specific tests prominent
- ✅ Preserves git history with git mv
- ✅ Follows Swift Testing best practices
- ✅ Educational and maintainable

**Next Steps**: Implement Phase 1 (create folders) and Phase 2 (move files).

---

**Document Version**: 1.0  
**Author**: AI Coding Agent  
**Date**: December 13, 2025  
**Status**: Ready for implementation
