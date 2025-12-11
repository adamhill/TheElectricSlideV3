# Cursor Readings Consolidation Architecture

## Executive Summary

The cursor readings rendering logic exists in TWO separate locations with **~90% code duplication**:
1. [`ContentView.swift:cursorReadingsOverlay()`](TheElectricSlide/ContentView.swift:316) - For multi-side devices (iPad/Mac)
2. [`SlideRuleDetailView.swift:cursorReadingsArea()`](TheElectricSlide/Components/SlideRuleDetailView.swift:120) - For compact devices (iPhone)

This document proposes consolidating to a **single source of truth** by creating a reusable `CursorReadingsContainer` component.

---

## Current State Analysis

### Location 1: ContentView.swift

**Method**: [`cursorReadingsOverlay()`](TheElectricSlide/ContentView.swift:316-400)  
**Lines**: 318-400 (83 lines)  
**Placement**: ZStack overlay with `.zIndex(1000)` and `.ignoresSafeArea(edges: .top)`  
**Conditional**: Only rendered when `deviceCategory.supportsMultiSideView`  

**Key Characteristics**:
- Positioned as floating overlay above slide rule content
- Header shown separately via [`stickyHeader()`](TheElectricSlide/ContentView.swift:284) method
- VStack spacing: `-4` (tighter for overlay context)
- Always uses `minHeight: 50`

### Location 2: SlideRuleDetailView.swift

**Method**: [`cursorReadingsArea()`](TheElectricSlide/Components/SlideRuleDetailView.swift:120-224)  
**Lines**: 125-224 (100 lines)  
**Placement**: Inline VStack, positioned after device header spacing  
**Conditional**: Only rendered when `!deviceCategory.supportsMultiSideView`  

**Key Characteristics**:
- Embedded inline in detail view layout
- Header embedded within method (lines 171-184)
- VStack spacing: `2` inner, `0` outer (more space for inline)
- Dynamic minHeight: `30` when `.none`, else `50`

---

## Duplication Analysis

### Identical Logic (~90% duplicate)

Both methods share **IDENTICAL** implementations for:

#### 1. Reading Data Extraction (3 lines)
```swift
let frontReadings = cursorState.currentReadings?.frontReadings ?? []
let backReadings = cursorState.currentReadings?.backReadings ?? []
let hasBackSide = currentSlideRule.backTopStator != nil
```

#### 2. Display Determination Logic (52 lines!)
Complex switch statement determining `shouldShowFront` and `shouldShowBack`:
- **Input factors**: `viewMode`, `cursorReadingCycleMode`, `hasBackSide`
- **Output**: Tuple `(shouldShowFront: Bool, shouldShowBack: Bool)`
- **Logic**: Identical 3-level nested switch (viewMode → cycleMode → results)

**This 52-line block is DUPLICATED VERBATIM**:
```swift
let (shouldShowFront, shouldShowBack): (Bool, Bool) = {
    switch viewMode {
    case .both:
        switch cursorReadingCycleMode {
        case .currentSide: return (true, false)
        case .oppositeSide: return (false, hasBackSide)
        case .both: return (true, hasBackSide)
        case .none: return (false, false)
        }
    case .front:
        switch cursorReadingCycleMode {
        case .currentSide: return (true, false)
        case .oppositeSide: return (false, hasBackSide)
        case .both: return (true, hasBackSide)
        case .none: return (false, false)
        }
    case .back:
        switch cursorReadingCycleMode {
        case .currentSide: return (false, true)
        case .oppositeSide: return (true, false)
        case .both: return (true, true)
        case .none: return (false, false)
        }
    }
}()
```

#### 3. VStack Display Structure (20+ lines)
- Conditional front readings: `CursorReadingsDisplayView(readings: frontReadings, side: .front)`
- Conditional back readings: `CursorReadingsDisplayView(readings: backReadings, side: .back)`
- Clear placeholder when `cursorReadingCycleMode == .none`
- `.equatable()` modifier optimization

#### 4. Gesture Handling (8 lines)
- Tap gesture: `cursorReadingCycleMode = cursorReadingCycleMode.next()`
- Animation: `.easeInOut(duration: 0.2)`
- Accessibility labels: identical

#### 5. Styling (6 lines)
- Background: `systemBackgroundColor()` with `.opacity(0.95)`
- `.contentShape(Rectangle())`
- `.accessibilityIdentifier("cursorReadingCycleToggle")`

### Minor Differences (~10%)

| Aspect | ContentView | SlideRuleDetailView | Impact |
|--------|-------------|---------------------|--------|
| **Header** | Separate method | Embedded inline | Structural only |
| **VStack spacing** | `-4` | `2` inner, `0` outer | Visual tuning |
| **MinHeight** | Always `50` | Dynamic `30`/`50` | Minor optimization |
| **Padding** | On overlay call | Inline | No difference |

---

## Architecture Problems

### 1. DRY Violation 🔴
**52 lines of identical switch logic** duplicated. Any change to reading display behavior requires updating TWO files.

### 2. Maintenance Risk 🔴
- Bug fixes need dual implementation
- Feature additions (new cycle modes) need dual updates  
- Testing complexity doubles
- Merge conflict potential increases

### 3. Inconsistency Risk 🟡
Current workaround uses `if !deviceCategory.supportsMultiSideView` guards, but this is a band-aid that doesn't address root duplication.

### 4. Coupling 🟡
**Display logic** (what to show) is tightly coupled with **placement logic** (where to show it), violating separation of concerns.

---

## Proposed Solution: Single Source of Truth

### Architecture Principles

1. **Separation of Concerns**: Display logic separate from placement
2. **Composition**: Single component usable in multiple contexts
3. **Configuration**: Minimal configuration for placement differences
4. **Testability**: Logic testable in isolation

### Component Design

#### New Component: `CursorReadingsContainer`

**File**: `TheElectricSlide/Components/CursorReadingsContainer.swift`

**Responsibilities**:
- ✅ Encapsulate ALL reading display determination logic
- ✅ Render cursor readings using `CursorReadingsDisplayView`
- ✅ Handle tap gesture for cycle mode changes
- ✅ Optionally show title section
- ✅ Accept configuration for layout variations

**Not Responsible For**:
- ❌ Device detection (passed as parameter)
- ❌ Placement context (overlay vs inline)
- ❌ Padding/spacing around container (applied by caller)

#### Configuration Object

```swift
struct CursorReadingsConfiguration {
    var showTitle: Bool          // Show rule name + side indicator?
    var minHeight: CGFloat       // Minimum container height
    var readingsSpacing: CGFloat // VStack spacing between readings
    
    static let overlay = CursorReadingsConfiguration(
        showTitle: false,  // Title shown separately in header
        minHeight: 50,
        readingsSpacing: -4
    )
    
    static let inline = CursorReadingsConfiguration(
        showTitle: true,   // Title embedded  
        minHeight: 30,     // Dynamic based on cycle mode handled internally
        readingsSpacing: 2
    )
}
```

#### Component API

```swift
struct CursorReadingsContainer: View {
    // State
    let viewMode: ViewMode
    @Binding var cursorReadingCycleMode: CursorReadingCycleMode
    let currentReadings: CursorReadings?
    let hasBackSide: Bool
    
    // Optional title
    let ruleName: String?
    
    // Configuration
    let configuration: CursorReadingsConfiguration
    
    var body: some View { /* ... */ }
}
```

---

## Migration Plan

### Phase 1: Create New Component ✨

**File**: `TheElectricSlide/Components/CursorReadingsContainer.swift`

**Steps**:
1. Create new file with component structure
2. Extract display determination logic (52-line switch)
3. Add title section rendering (conditional)
4. Add readings section rendering (VStack with `CursorReadingsDisplayView`)
5. Add tap gesture handler
6. Add accessibility labels
7. Apply styling and opacity

**Estimated Lines**: ~150 lines (well-structured, single responsibility)

### Phase 2: Update ContentView ⚡

**File**: `TheElectricSlide/ContentView.swift`

**Changes**:
```swift
// BEFORE (lines 316-400, 83 lines)
@ViewBuilder
private func cursorReadingsOverlay() -> some View {
    let frontReadings = cursorState.currentReadings?.frontReadings ?? []
    let backReadings = cursorState.currentReadings?.backReadings ?? []
    // ... 52 lines of duplicate logic ...
    VStack(spacing: -4) {
        if shouldShowFront { /* ... */ }
        if shouldShowBack { /* ... */ }
    }
    // ... styling ...
}

// AFTER (simplified to ~10 lines)
@ViewBuilder
private func cursorReadingsOverlay() -> some View {
    CursorReadingsContainer(
        viewMode: viewMode,
        cursorReadingCycleMode: $cursorReadingCycleMode,
        currentReadings: cursorState.currentReadings,
        hasBackSide: currentSlideRule.backTopStator != nil,
        ruleName: nil,  // Title shown in separate stickyHeader()
        configuration: .overlay
    )
}
```

**Impact**: 
- Delete: ~70 lines of duplicate logic
- Add: ~10 lines of component usage
- Net: **-60 lines**

### Phase 3: Update SlideRuleDetailView ⚡

**File**: `TheElectricSlide/Components/SlideRuleDetailView.swift`

**Changes**:
```swift
// BEFORE (lines 120-224, 100 lines)
@ViewBuilder
private func cursorReadingsArea() -> some View {
    let frontReadings = cursorState.currentReadings?.frontReadings ?? []
    let backReadings = cursorState.currentReadings?.backReadings ?? []
    // ... 52 lines of duplicate logic ...
    VStack(spacing: 0) {
        // Title section (14 lines)
        if let ruleName = selectedRuleDefinition?.name { /* ... */ }
        
        // Readings (remaining lines)
        VStack(spacing: 2) {
            if shouldShowFront { /* ... */ }
            if shouldShowBack { /* ... */ }
        }
    }
    // ... styling ...
}

// AFTER (simplified to ~10 lines)
@ViewBuilder
private func cursorReadingsArea() -> some View {
    CursorReadingsContainer(
        viewMode: viewMode,
        cursorReadingCycleMode: $cursorReadingCycleMode,
        currentReadings: cursorState.currentReadings,
        hasBackSide: currentSlideRule.backTopStator != nil,
        ruleName: selectedRuleDefinition?.name,  // Title embedded inline
        configuration: .inline
    )
}
```

**Impact**:
- Delete: ~90 lines of duplicate logic  
- Add: ~10 lines of component usage
- Net: **-80 lines**

### Phase 4: Verification 🧪

**Testing checklist**:
- [ ] iPad: Overlay rendering correct with separate header
- [ ] iPhone: Inline rendering correct with embedded title
- [ ] Mac: Overlay rendering correct
- [ ] Cycle mode behavior identical on all devices
- [ ] Tap gesture works on all devices
- [ ] Accessibility labels preserved
- [ ] Visual spacing matches original (overlay: -4, inline: 2)
- [ ] MinHeight behavior correct (dynamic for inline)
- [ ] No regression in cursor reading updates
- [ ] Performance unchanged (<0.3ms reading updates)

---

## Benefits of Proposed Architecture

### 1. Maintainability ✅
- **Single location** for display logic changes
- Bug fixes applied once, affect all contexts
- 52-line switch statement exists in ONE place

### 2. Consistency ✅
- Impossible for implementations to drift apart
- Guaranteed identical behavior across devices
- Configuration makes differences explicit

### 3. Testability ✅
- Display logic testable in isolation
- Can write unit tests for decision table
- Preview provider for visual verification

### 4. Code Reduction ✅
- Net reduction: **~140 lines** (-60 from ContentView, -80 from SlideRuleDetailView)
- Cleaner call sites (10 lines vs 80-100)
- Easier to understand intent

### 5. Extensibility ✅
- Adding new cycle modes: change ONE location
- New device categories: add configuration preset
- A/B testing: swap configuration easily

---

## SwiftUI Best Practices Alignment

### ✅ Composition Over Inheritance
Component is composable, not inherited. Can be embedded in any view hierarchy.

### ✅ Single Responsibility
Component has ONE job: determine and render cursor readings. Placement is caller's responsibility.

### ✅ Declarative Configuration
Configuration object makes behavior explicit and discoverable.

### ✅ View Identity
Component accepts minimal stable identity (`viewMode`, `cycleMode`, `readings`) - no derived state.

### ✅ Environment Independence
Doesn't rely on environment values for core logic. All dependencies explicit.

### ✅ Equatable Optimization
Can leverage `.equatable()` modifier since display decision is pure function of inputs.

---

## Alternative Approaches Considered

### Alternative 1: ViewModifier ❌

**Idea**: Create a view modifier that applies readings overlay/inline.

**Rejected because**:
- Modifiers can't conditionally change view hierarchy structure
- Can't switch between overlay and inline placement
- Would still need two implementations

### Alternative 2: @ViewBuilder Function ❌

**Idea**: Extract logic into standalone `@ViewBuilder` function.

**Rejected because**:
- No encapsulation of state
- No ability to add internal helpers
- Clutters namespace with function

### Alternative 3: Generic Component with Placement Strategy ⚠️

**Idea**: Component accepts generic placement strategy (overlay/inline).

**Rejected as over-engineering**:
- Only two placement contexts
- Configuration object simpler than strategy pattern
- YAGNI (You Aren't Gonna Need It)

---

## Migration Risks & Mitigation

### Risk 1: Visual Regression
**Mitigation**: Careful pixel-perfect testing on all device types before/after.

### Risk 2: Behavior Change
**Mitigation**: Extensive testing of cycle mode transitions. Screenshot tests.

### Risk 3: Performance Impact
**Mitigation**: Profile before/after. Component should be lighter (less duplication).

### Risk 4: Breaking Accessibility
**Mitigation**: VoiceOver testing on iOS. Verify all labels preserved.

---

## Implementation Checklist

### Pre-Implementation
- [ ] Review this document with team
- [ ] Approve architectural approach
- [ ] Schedule testing time for verification

### Implementation Phase 1: Create Component
- [ ] Create `CursorReadingsContainer.swift`
- [ ] Implement `CursorReadingsConfiguration` struct
- [ ] Implement display determination logic (extract from existing)
- [ ] Implement title section rendering
- [ ] Implement readings section rendering
- [ ] Add tap gesture handler
- [ ] Add accessibility support
- [ ] Create preview provider for testing

### Implementation Phase 2: ContentView Migration
- [ ] Replace [`cursorReadingsOverlay()`](TheElectricSlide/ContentView.swift:316) body with component call
- [ ] Pass `.overlay` configuration
- [ ] Verify overlay placement still correct
- [ ] Test cycle mode transitions
- [ ] Verify accessibility

### Implementation Phase 3: SlideRuleDetailView Migration
- [ ] Replace [`cursorReadingsArea()`](TheElectricSlide/Components/SlideRuleDetailView.swift:120) body with component call
- [ ] Pass `.inline` configuration with `ruleName`
- [ ] Verify inline placement still correct
- [ ] Test cycle mode transitions
- [ ] Verify accessibility

### Verification Phase
- [ ] Run full test suite
- [ ] Manual testing on physical devices (iPhone, iPad, Mac)
- [ ] VoiceOver accessibility testing
- [ ] Performance profiling
- [ ] Visual comparison screenshots (before/after)

### Cleanup Phase
- [ ] Remove old method implementations
- [ ] Update documentation
- [ ] Add inline comments explaining architecture choice
- [ ] Create this document as reference

---

## Conclusion

The proposed `CursorReadingsContainer` component consolidates **~180 lines of duplicated code** into a single, well-tested, configurable component. This improves maintainability, reduces bug risk, and aligns with SwiftUI best practices for composable architecture.

**Recommendation**: Proceed with implementation following the phased migration plan.

**Estimated Effort**: 2-3 hours for implementation + 1-2 hours for thorough testing.

**Files Modified**:
- ✨ NEW: `TheElectricSlide/Components/CursorReadingsContainer.swift` (~150 lines)
- ⚡ MODIFIED: `TheElectricSlide/ContentView.swift` (net -60 lines)
- ⚡ MODIFIED: `TheElectricSlide/Components/SlideRuleDetailView.swift` (net -80 lines)

**Total Impact**: +150 new, -140 deleted = **NET +10 lines** (improvement in organization, massive reduction in duplication)