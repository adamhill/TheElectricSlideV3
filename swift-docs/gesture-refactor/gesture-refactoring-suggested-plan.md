# Gesture System Refactoring Plan: Making It More Functional

> Comprehensive plan to refactor the gesture system following the HapticService pattern
> Date: December 2025

## Executive Summary

Following the same pattern that made [`HapticService`](../../TheElectricSlide/Utilities/HapticService.swift) more functional and testable, this plan proposes refactoring the gesture system to be:
- **Protocol-driven** with injectable implementations
- **Unit-testable** with pure function calculations
- **Composable** with clear separation of concerns
- **Feature-rich** with momentum, boundaries, and accessibility

---

## Part 1: Architecture Overview

### Current State Problems

```mermaid
graph TB
    subgraph "Current Problems"
        P1[Business logic in<br/>gesture handlers]
        P2[Duplicated<br/>precision state]
        P3[8+ callbacks<br/>prop-drilled]
        P4[No velocity/<br/>momentum]
        P5[Unbounded<br/>pan offset]
    end
    
    subgraph "Impacts"
        P1 --> I1[Not testable]
        P2 --> I2[DRY violation]
        P3 --> I3[Tight coupling]
        P4 --> I4[Unnatural feel]
        P5 --> I5[Content off-screen]
    end
```

| Issue | Current Location | Impact |
|-------|------------------|--------|
| Business logic in gesture handlers | [`CursorOverlay.swift:302-334`](../../TheElectricSlide/Cursor/CursorOverlay.swift:302) | Not testable |
| Duplicated precision state | CursorOverlay vs SideView | DRY violation |
| 8+ callbacks prop-drilled | [`ContentView.swift:137-147`](../../TheElectricSlide/ContentView.swift:137) | Coupling |
| No velocity/momentum | All gesture handlers | Unnatural feel |
| Unbounded pan offset | [`SlideRuleViewModel.swift:162`](../../TheElectricSlide/Models/SlideRuleViewModel.swift:162) | Content goes off-screen |

### Proposed Architecture

```mermaid
graph TB
    subgraph "GESTURE LAYER"
        SV[SideView<br/>.gesture]
        CO[CursorOverlay<br/>.gesture]
        ST[StatorView<br/>.gesture]
    end
    
    subgraph "SERVICE LAYER"
        GS[GestureService<br/>Protocol]
        DGS[DefaultGestureService<br/>Implementation]
    end
    
    subgraph "CALCULATION LAYER"
        GC[GestureCalculator<br/>Pure Functions]
    end
    
    subgraph "STATE LAYER"
        VM[SlideRuleViewModel<br/>Observable]
        CS[CursorState<br/>Observable]
        HS[HapticService<br/>Protocol]
    end
    
    SV --> GS
    CO --> GS
    ST --> GS
    
    GS --> DGS
    DGS --> GC
    DGS --> HS
    
    GC --> VM
    GC --> CS
```

**Key Principles:**
1. **Protocol-based service** - `GestureService` protocol like `HapticService`
2. **Pure calculation functions** - `GestureCalculator` with static methods
3. **Environment injection** - No prop drilling, use SwiftUI Environment
4. **Testability** - All business logic in testable functions

---

## Part 2: New Components

### 2.1 GestureService Protocol (Mirrors HapticService Pattern)

```swift
// TheElectricSlide/Utilities/GestureService.swift

/// Protocol for gesture handling - enables testing and swappable implementations
protocol GestureService {
    /// Process slide drag input and return calculated result
    func handleSlide(_ input: SlideGestureInput) -> SlideGestureResult
    
    /// Process cursor drag input and return calculated result
    func handleCursor(_ input: CursorGestureInput) -> CursorGestureResult
    
    /// Process zoom input and return calculated result
    func handleZoom(_ input: ZoomGestureInput) -> ZoomGestureResult
    
    /// Process pan input (zoomed content) and return bounded result
    func handlePan(_ input: PanGestureInput) -> PanGestureResult
}
```

### 2.2 Gesture Input/Output Value Types

```swift
// TheElectricSlide/Models/GestureTypes.swift

// MARK: - Input Types (from SwiftUI gestures)

struct SlideGestureInput {
    let translation: CGSize
    let velocity: CGSize?           // iOS 18+ or predicted
    let baseOffset: CGFloat
    let scaleWidth: CGFloat
    let isPrecisionMode: Bool
    let precisionFactor: CGFloat
}

struct CursorGestureInput {
    let translation: CGSize
    let velocity: CGSize?
    let basePosition: CGFloat       // 0.0-1.0 normalized
    let viewWidth: CGFloat
    let isPrecisionMode: Bool
    let precisionFactor: CGFloat
}

struct ZoomGestureInput {
    let magnification: CGFloat
    let baseScale: CGFloat
    let minScale: CGFloat
    let maxScale: CGFloat
}

struct PanGestureInput {
    let translation: CGSize
    let velocity: CGSize?
    let baseOffset: CGSize
    let zoomScale: CGFloat
    let contentSize: CGSize
    let viewportSize: CGSize
}

// MARK: - Output Types (pure calculation results)

struct SlideGestureResult {
    let offset: CGFloat
    let isBounded: Bool             // True if hit boundary
    let boundaryEdge: BoundaryEdge? // .leading or .trailing
    let momentum: MomentumResult?   // For onEnded
}

struct CursorGestureResult {
    let normalizedPosition: CGFloat // 0.0-1.0
    let isBounded: Bool
    let boundaryEdge: BoundaryEdge?
    let momentum: MomentumResult?
}

struct ZoomGestureResult {
    let scale: CGFloat
    let snappedToDefault: Bool      // True if snapped to 1.0×
}

struct PanGestureResult {
    let offset: CGSize
    let boundedAxes: Set<BoundaryEdge>
    let momentum: MomentumResult?
}

struct MomentumResult {
    let finalOffset: CGFloat        // Predicted end position
    let duration: TimeInterval      // Animation duration
    let curve: MomentumCurve        // Deceleration curve
    
    enum MomentumCurve {
        case friction(CGFloat)       // Natural deceleration
        case spring                  // Bounce back
    }
}

enum BoundaryEdge {
    case leading, trailing, top, bottom
}
```

### 2.3 GestureCalculator (Pure Functions - Fully Testable)

```swift
// TheElectricSlide/Utilities/GestureCalculator.swift

/// Pure calculation functions for gesture mathematics
/// All functions are static, deterministic, and side-effect-free
enum GestureCalculator {
    
    // MARK: - Slide Calculations
    
    static func calculateSlideOffset(
        translation: CGSize,
        baseOffset: CGFloat,
        scaleWidth: CGFloat,
        isPrecision: Bool = false,
        precisionFactor: CGFloat = 5.0
    ) -> SlideGestureResult {
        let adjustedTranslation = isPrecision 
            ? translation.width / precisionFactor 
            : translation.width
        
        let rawOffset = baseOffset + adjustedTranslation
        let boundedOffset = rawOffset.clamped(to: -scaleWidth...scaleWidth)
        
        let hitBoundary = rawOffset != boundedOffset
        let edge: BoundaryEdge? = hitBoundary 
            ? (rawOffset < boundedOffset ? .leading : .trailing)
            : nil
        
        return SlideGestureResult(
            offset: boundedOffset,
            isBounded: hitBoundary,
            boundaryEdge: edge,
            momentum: nil
        )
    }
    
    // MARK: - Cursor Calculations
    
    static func calculateCursorPosition(
        translation: CGSize,
        basePosition: CGFloat,
        viewWidth: CGFloat,
        isPrecision: Bool = false,
        precisionFactor: CGFloat = 5.0
    ) -> CursorGestureResult {
        let adjustedTranslation = isPrecision
            ? translation.width / precisionFactor
            : translation.width
        
        let normalizedDelta = adjustedTranslation / viewWidth
        let rawPosition = basePosition + normalizedDelta
        let boundedPosition = rawPosition.clamped(to: 0.0...1.0)
        
        let hitBoundary = rawPosition != boundedPosition
        let edge: BoundaryEdge? = hitBoundary
            ? (rawPosition < 0.0 ? .leading : .trailing)
            : nil
        
        return CursorGestureResult(
            normalizedPosition: boundedPosition,
            isBounded: hitBoundary,
            boundaryEdge: edge,
            momentum: nil
        )
    }
    
    // MARK: - Momentum Calculations (NEW)
    
    static func calculateMomentum(
        velocity: CGSize,
        axis: Axis,
        decelerationRate: CGFloat = 0.998 // UIScrollView default
    ) -> MomentumResult {
        let v = axis == .horizontal ? velocity.width : velocity.height
        
        // Physics: d = v * (1 - decelerationRate^t) / (1 - decelerationRate)
        // Simplified for time-to-stop calculation
        let friction = 1.0 - decelerationRate
        let finalOffset = v * decelerationRate / friction
        let duration = abs(v) > 50 ? min(2.0, abs(v) / 1000.0) : 0.3
        
        return MomentumResult(
            finalOffset: finalOffset,
            duration: duration,
            curve: .friction(decelerationRate)
        )
    }
    
    // MARK: - Pan Boundary Calculations (NEW)
    
    static func calculateBoundedPan(
        offset: CGSize,
        zoomScale: CGFloat,
        contentSize: CGSize,
        viewportSize: CGSize
    ) -> PanGestureResult {
        let scaledContent = CGSize(
            width: contentSize.width * zoomScale,
            height: contentSize.height * zoomScale
        )
        
        let maxPanX = max(0, (scaledContent.width - viewportSize.width) / 2)
        let maxPanY = max(0, (scaledContent.height - viewportSize.height) / 2)
        
        let boundedX = offset.width.clamped(to: -maxPanX...maxPanX)
        let boundedY = offset.height.clamped(to: -maxPanY...maxPanY)
        
        var bounded: Set<BoundaryEdge> = []
        if offset.width != boundedX {
            bounded.insert(offset.width < boundedX ? .leading : .trailing)
        }
        if offset.height != boundedY {
            bounded.insert(offset.height < boundedY ? .top : .bottom)
        }
        
        return PanGestureResult(
            offset: CGSize(width: boundedX, height: boundedY),
            boundedAxes: bounded,
            momentum: nil
        )
    }
    
    // MARK: - Zoom Calculations
    
    static func calculateZoom(
        magnification: CGFloat,
        baseScale: CGFloat,
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 4.0,
        snapThreshold: CGFloat = 0.1
    ) -> ZoomGestureResult {
        let rawScale = baseScale * magnification
        var boundedScale = rawScale.clamped(to: minScale...maxScale)
        
        // Snap to 1.0× if within threshold
        let snapped = (rawScale < minScale && abs(rawScale - minScale) < snapThreshold)
        if snapped {
            boundedScale = minScale
        }
        
        return ZoomGestureResult(scale: boundedScale, snappedToDefault: snapped)
    }
}
```

### 2.4 Default GestureService Implementation

```mermaid
sequenceDiagram
    participant View
    participant GestureService
    participant GestureCalculator
    participant HapticService
    participant ViewModel
    
    View->>GestureService: handleSlide(input)
    GestureService->>GestureCalculator: calculateSlideOffset()
    GestureCalculator-->>GestureService: SlideGestureResult
    
    alt Hit Boundary
        GestureService->>HapticService: fire(.boundaryHit)
    end
    
    alt Has Velocity
        GestureService->>GestureCalculator: calculateMomentum()
        GestureCalculator-->>GestureService: MomentumResult
    end
    
    GestureService-->>View: Result with momentum
    View->>ViewModel: Update state
```

```swift
// TheElectricSlide/Utilities/DefaultGestureService.swift

/// Production implementation of GestureService
final class DefaultGestureService: GestureService {
    
    private let hapticService: HapticService
    
    init(hapticService: HapticService = UIKitHapticService()) {
        self.hapticService = hapticService
    }
    
    func handleSlide(_ input: SlideGestureInput) -> SlideGestureResult {
        var result = GestureCalculator.calculateSlideOffset(
            translation: input.translation,
            baseOffset: input.baseOffset,
            scaleWidth: input.scaleWidth,
            isPrecision: input.isPrecisionMode,
            precisionFactor: input.precisionFactor
        )
        
        // Add momentum if velocity available
        if let velocity = input.velocity {
            result = SlideGestureResult(
                offset: result.offset,
                isBounded: result.isBounded,
                boundaryEdge: result.boundaryEdge,
                momentum: GestureCalculator.calculateMomentum(
                    velocity: velocity,
                    axis: .horizontal
                )
            )
        }
        
        // Fire haptic on boundary hit
        if result.isBounded, let edge = result.boundaryEdge {
            hapticService.fire(.boundaryHit(edge: edge))
        }
        
        return result
    }
    
    func handleCursor(_ input: CursorGestureInput) -> CursorGestureResult {
        var result = GestureCalculator.calculateCursorPosition(
            translation: input.translation,
            basePosition: input.basePosition,
            viewWidth: input.viewWidth,
            isPrecision: input.isPrecisionMode,
            precisionFactor: input.precisionFactor
        )
        
        if let velocity = input.velocity {
            result = CursorGestureResult(
                normalizedPosition: result.normalizedPosition,
                isBounded: result.isBounded,
                boundaryEdge: result.boundaryEdge,
                momentum: GestureCalculator.calculateMomentum(
                    velocity: velocity,
                    axis: .horizontal
                )
            )
        }
        
        if result.isBounded {
            hapticService.fire(.boundaryHit(edge: result.boundaryEdge!))
        }
        
        return result
    }
    
    func handleZoom(_ input: ZoomGestureInput) -> ZoomGestureResult {
        let result = GestureCalculator.calculateZoom(
            magnification: input.magnification,
            baseScale: input.baseScale,
            minScale: input.minScale,
            maxScale: input.maxScale
        )
        
        if result.snappedToDefault {
            hapticService.fire(.zoomSnap)
        }
        
        return result
    }
    
    func handlePan(_ input: PanGestureInput) -> PanGestureResult {
        var result = GestureCalculator.calculateBoundedPan(
            offset: CGSize(
                width: input.baseOffset.width + input.translation.width,
                height: input.baseOffset.height + input.translation.height
            ),
            zoomScale: input.zoomScale,
            contentSize: input.contentSize,
            viewportSize: input.viewportSize
        )
        
        if let velocity = input.velocity {
            result = PanGestureResult(
                offset: result.offset,
                boundedAxes: result.boundedAxes,
                momentum: GestureCalculator.calculateMomentum(
                    velocity: velocity,
                    axis: .horizontal
                )
            )
        }
        
        if !result.boundedAxes.isEmpty {
            for edge in result.boundedAxes {
                hapticService.fire(.boundaryHit(edge: edge))
            }
        }
        
        return result
    }
}
```

### 2.5 Updated HapticEvent (Add Boundary Events)

```swift
// Addition to existing HapticService.swift

enum HapticEvent {
    // Existing
    case flip
    case longBuzz
    case tickCrossed(level: TickHapticLevel)
    case buttonTap(style: HapticButtonStyle)
    
    // NEW: Gesture boundary feedback
    case boundaryHit(edge: BoundaryEdge)
    case zoomSnap
    case momentumStop
}
```

---

## Part 3: Unified Precision State

### 3.1 Shared PrecisionDragCoordinator

```mermaid
stateDiagram-v2
    [*] --> Inactive
    Inactive --> Pressing: Long press starts
    Pressing --> PrecisionActive: 1.0s elapsed
    PrecisionActive --> Cooldown: Gesture ends
    Cooldown --> Inactive: 0.3s elapsed
    
    note right of PrecisionActive
        5× sensitivity reduction
        Haptic confirmation fired
    end note
```

```swift
// TheElectricSlide/Utilities/PrecisionDragCoordinator.swift

/// Unified precision mode state management for all draggable components
@Observable
final class PrecisionDragCoordinator {
    
    enum DragTarget {
        case slide, cursor, none
    }
    
    // MARK: - Observable State
    var activeTarget: DragTarget = .none
    var isPrecisionActive: Bool = false
    
    // MARK: - Hot State (not observed)
    @ObservationIgnored private var lastAppliedTranslation: CGSize = .zero
    @ObservationIgnored private var cooldownTimer: Timer?
    
    // MARK: - Configuration
    let precisionFactor: CGFloat
    let activationDuration: TimeInterval
    let cooldownDuration: TimeInterval
    
    init(
        precisionFactor: CGFloat = 5.0,
        activationDuration: TimeInterval = 1.0,
        cooldownDuration: TimeInterval = 0.3
    ) {
        self.precisionFactor = precisionFactor
        self.activationDuration = activationDuration
        self.cooldownDuration = cooldownDuration
    }
    
    func activate(for target: DragTarget) {
        activeTarget = target
        isPrecisionActive = true
        lastAppliedTranslation = .zero
    }
    
    func deactivate() {
        isPrecisionActive = false
        activeTarget = .none
        lastAppliedTranslation = .zero
        startCooldown()
    }
    
    func recordTranslation(_ translation: CGSize) {
        lastAppliedTranslation = translation
    }
    
    func deltaFrom(newTranslation: CGSize) -> CGSize {
        CGSize(
            width: newTranslation.width - lastAppliedTranslation.width,
            height: newTranslation.height - lastAppliedTranslation.height
        )
    }
    
    private func startCooldown() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(
            withTimeInterval: cooldownDuration,
            repeats: false
        ) { [weak self] _ in
            // Cooldown complete
        }
    }
}
```

---

## Part 4: Environment-Based Distribution

### 4.1 Environment Keys

```mermaid
graph TB
    subgraph "ContentView Setup"
        CV[ContentView]
    end
    
    subgraph "Environment Values"
        GS[GestureService]
        PC[PrecisionCoordinator]
        HS[HapticService]
    end
    
    subgraph "Child Views"
        SV[SideView]
        CO[CursorOverlay]
        ST[StatorView]
    end
    
    CV -->|.environment| GS
    CV -->|.environment| PC
    CV -->|.environment| HS
    
    GS --> SV
    GS --> CO
    GS --> ST
    
    PC --> SV
    PC --> CO
```

```swift
// TheElectricSlide/Utilities/GestureEnvironment.swift

private struct GestureServiceKey: EnvironmentKey {
    static let defaultValue: GestureService = DefaultGestureService()
}

private struct PrecisionCoordinatorKey: EnvironmentKey {
    static let defaultValue: PrecisionDragCoordinator = PrecisionDragCoordinator()
}

extension EnvironmentValues {
    var gestureService: GestureService {
        get { self[GestureServiceKey.self] }
        set { self[GestureServiceKey.self] = newValue }
    }
    
    var precisionCoordinator: PrecisionDragCoordinator {
        get { self[PrecisionCoordinatorKey.self] }
        set { self[PrecisionCoordinatorKey.self] = newValue }
    }
}
```

### 4.2 Usage in Views

```swift
// Before (prop drilling)
SideView(
    onDragStart: viewModel.handleSliderDragStart,
    onDragChanged: viewModel.handleSliderDragChanged,
    onDragEnded: viewModel.handleSliderDragEnded,
    // ...8 more callbacks
)

// After (environment)
SideView()
    .environment(\.gestureService, gestureService)
    .environment(\.precisionCoordinator, precisionCoordinator)

// In SideView:
struct SideView: View {
    @Environment(\.gestureService) private var gestureService
    @Environment(\.precisionCoordinator) private var precision
    
    var body: some View {
        // Use directly
    }
}
```

---

## Part 5: Test Coverage

### 5.1 GestureCalculator Tests (Pure Functions)

```mermaid
graph LR
    subgraph "Test Categories"
        T1[Boundary<br/>Clamping]
        T2[Precision Mode<br/>Sensitivity]
        T3[Momentum<br/>Calculation]
        T4[Pan<br/>Bounds]
    end
    
    T1 --> TC1[90+ tests]
    T2 --> TC1
    T3 --> TC1
    T4 --> TC1
```

```swift
// TheElectricSlideTests/GestureCalculatorTests.swift

@Suite("Gesture Calculator Tests")
struct GestureCalculatorTests {
    
    @Test("Slide offset clamps to scale width")
    func slideOffsetClamping() {
        let result = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 1000, height: 0),
            baseOffset: 0,
            scaleWidth: 500
        )
        
        #expect(result.offset == 500)
        #expect(result.isBounded == true)
        #expect(result.boundaryEdge == .trailing)
    }
    
    @Test("Precision mode reduces translation")
    func precisionModeReduction() {
        let normal = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 100, height: 0),
            baseOffset: 0,
            scaleWidth: 500,
            isPrecision: false
        )
        
        let precision = GestureCalculator.calculateSlideOffset(
            translation: CGSize(width: 100, height: 0),
            baseOffset: 0,
            scaleWidth: 500,
            isPrecision: true,
            precisionFactor: 5.0
        )
        
        #expect(normal.offset == 100)
        #expect(precision.offset == 20)
    }
    
    @Test("Momentum calculation produces sensible values")
    func momentumCalculation() {
        let result = GestureCalculator.calculateMomentum(
            velocity: CGSize(width: 500, height: 0),
            axis: .horizontal
        )
        
        #expect(result.finalOffset > 0)
        #expect(result.duration > 0)
        #expect(result.duration <= 2.0)
    }
    
    @Test("Pan bounds respect zoom level")
    func panBoundsZoomAware() {
        let result = GestureCalculator.calculateBoundedPan(
            offset: CGSize(width: 500, height: 0),
            zoomScale: 2.0,
            contentSize: CGSize(width: 500, height: 100),
            viewportSize: CGSize(width: 400, height: 100)
        )
        
        // At 2× zoom, content is 1000pt, viewport is 400pt
        // Max pan = (1000 - 400) / 2 = 300pt
        #expect(result.offset.width == 300)
        #expect(result.boundedAxes.contains(.trailing))
    }
}
```

### 5.2 Mock GestureService for View Tests

```swift
// TheElectricSlideTests/Mocks/MockGestureService.swift

final class MockGestureService: GestureService {
    var slideCallCount = 0
    var cursorCallCount = 0
    var zoomCallCount = 0
    var panCallCount = 0
    
    var stubbedSlideResult: SlideGestureResult?
    var stubbedCursorResult: CursorGestureResult?
    
    func handleSlide(_ input: SlideGestureInput) -> SlideGestureResult {
        slideCallCount += 1
        return stubbedSlideResult ?? SlideGestureResult(
            offset: input.baseOffset + input.translation.width,
            isBounded: false,
            boundaryEdge: nil,
            momentum: nil
        )
    }
    
    // ... similar for other methods
}
```

---

## Part 6: Implementation Phases

```mermaid
gantt
    title Gesture Refactoring Implementation Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1
    GestureTypes         :p1a, 2025-01-01, 2d
    GestureCalculator    :p1b, after p1a, 2d
    Calculator Tests     :p1c, after p1b, 2d
    Boundary Haptics     :p1d, after p1c, 1d
    
    section Phase 2
    GestureService Proto :p2a, after p1d, 2d
    DefaultGestureService:p2b, after p2a, 2d
    MockGestureService   :p2c, after p2b, 1d
    Environment Keys     :p2d, after p2c, 1d
    
    section Phase 3
    PrecisionCoordinator :p3a, after p2d, 2d
    Migrate CursorOverlay:p3b, after p3a, 1d
    Migrate SideView     :p3c, after p3b, 1d
    
    section Phase 4
    Refactor Gestures.swift:p4a, after p3c, 2d
    Update Views         :p4b, after p4a, 2d
    
    section Phase 5
    Momentum Features    :p5a, after p4b, 3d
    
    section Phase 6
    Polish & Docs        :p6a, after p5a, 2d
```

### Phase 1: Foundation (2-3 days)
- [ ] Create `GestureTypes.swift` with all input/output structs
- [ ] Create `GestureCalculator.swift` with pure calculation functions
- [ ] Write comprehensive tests for `GestureCalculator`
- [ ] Add boundary haptic events to `HapticService`

### Phase 2: Service Layer (2-3 days)
- [ ] Create `GestureService` protocol
- [ ] Implement `DefaultGestureService`
- [ ] Create `MockGestureService` for testing
- [ ] Set up environment keys

### Phase 3: Precision Consolidation (1-2 days)
- [ ] Create `PrecisionDragCoordinator`
- [ ] Migrate `CursorOverlay` to use shared coordinator
- [ ] Migrate `SideView` to use shared coordinator
- [ ] Remove duplicated `PrecisionDragState` class

### Phase 4: View Integration (2-3 days)
- [ ] Refactor `ContentView+Gestures.swift` to use `GestureService`
- [ ] Remove callback prop drilling
- [ ] Update `SideView` gesture handlers
- [ ] Update `CursorOverlay` gesture handlers
- [ ] Update `StatorView` gesture handlers

### Phase 5: New Features (2-3 days)
- [ ] Implement momentum scrolling for slide/cursor
- [ ] Implement bounded pan for zoomed content
- [ ] Add haptic feedback on boundary hits
- [ ] Add zoom snap haptic feedback

### Phase 6: Polish & Documentation (1-2 days)
- [ ] Performance profiling
- [ ] Documentation updates
- [ ] Update existing tests
- [ ] Final integration testing

---

## Part 7: File Changes Summary

### Files to Create

```mermaid
graph TB
    subgraph "New Files"
        F1[GestureTypes.swift]
        F2[GestureCalculator.swift]
        F3[GestureService.swift]
        F4[DefaultGestureService.swift]
        F5[PrecisionDragCoordinator.swift]
        F6[GestureEnvironment.swift]
        F7[GestureCalculatorTests.swift]
        F8[GestureServiceTests.swift]
        F9[MockGestureService.swift]
    end
    
    subgraph "Purpose"
        P1[Value Types]
        P2[Pure Functions]
        P3[Protocol]
        P4[Implementation]
        P5[State]
        P6[Environment]
        P7[Unit Tests]
        P8[Integration Tests]
        P9[Test Mock]
    end
    
    F1 --> P1
    F2 --> P2
    F3 --> P3
    F4 --> P4
    F5 --> P5
    F6 --> P6
    F7 --> P7
    F8 --> P8
    F9 --> P9
```

| Action | File | Description |
|--------|------|-------------|
| **CREATE** | `TheElectricSlide/Models/GestureTypes.swift` | Input/output value types |
| **CREATE** | `TheElectricSlide/Utilities/GestureCalculator.swift` | Pure calculation functions |
| **CREATE** | `TheElectricSlide/Utilities/GestureService.swift` | Protocol definition |
| **CREATE** | `TheElectricSlide/Utilities/DefaultGestureService.swift` | Production implementation |
| **CREATE** | `TheElectricSlide/Utilities/PrecisionDragCoordinator.swift` | Unified precision state |
| **CREATE** | `TheElectricSlide/Utilities/GestureEnvironment.swift` | Environment keys |
| **CREATE** | `TheElectricSlideTests/GestureCalculatorTests.swift` | Pure function tests |
| **CREATE** | `TheElectricSlideTests/GestureServiceTests.swift` | Service integration tests |
| **CREATE** | `TheElectricSlideTests/Mocks/MockGestureService.swift` | Test mock |

### Files to Modify

| Action | File | Description |
|--------|------|-------------|
| **MODIFY** | `TheElectricSlide/Utilities/HapticService.swift` | Add boundary events |
| **MODIFY** | `TheElectricSlide/Extensions/ContentView+Gestures.swift` | Use GestureService |
| **MODIFY** | `TheElectricSlide/Components/SideView.swift` | Remove callbacks, use environment |
| **MODIFY** | `TheElectricSlide/Cursor/CursorOverlay.swift` | Use shared precision coordinator |
| **MODIFY** | `TheElectricSlide/ContentView.swift` | Inject environment values |

### Files to Remove

| Action | Description |
|--------|-------------|
| **DELETE** | `PrecisionDragState` class (inline in SideView) - consolidated into `PrecisionDragCoordinator` |

---

## Part 8: Key Benefits

### 8.1 Testability Improvements

```mermaid
graph LR
    subgraph "Before"
        B1[Business Logic<br/>in Views]
        B2[Not Testable]
    end
    
    subgraph "After"
        A1[Pure Functions in<br/>GestureCalculator]
        A2[90%+ Test<br/>Coverage]
    end
    
    B1 --> B2
    A1 --> A2
    
    style B2 fill:#f99
    style A2 fill:#9f9
```

1. **90%+ Test Coverage**: All gesture logic in pure, testable `GestureCalculator` functions
2. **Mock Service**: Easy testing with `MockGestureService` for view tests
3. **Deterministic**: Pure functions ensure predictable behavior

### 8.2 Code Quality Improvements

1. **Consistency**: Single `PrecisionDragCoordinator` for all precision mode handling
2. **Decoupling**: Environment-based distribution eliminates 8+ callback props
3. **Maintainability**: Protocol-based design matches existing `HapticService` pattern
4. **Readability**: Clear separation between calculation, service, and view layers

### 8.3 Feature Improvements

1. **Momentum Scrolling**: Natural feel using velocity or `predictedEndTranslation`
2. **Boundary Feedback**: Haptic feedback prevents content from going off-screen
3. **Bounded Pan**: Safe pan boundaries based on zoom level
4. **Accessibility**: Foundation for VoiceOver gesture alternatives

---

## Summary

This refactoring plan transforms the gesture system from scattered, embedded view logic into a testable, composable service layer—**exactly mirroring what was done with haptics**. The layered architecture with pure functions, protocol-based services, and environment injection provides a solid foundation for future enhancements while maintaining excellent testability and code quality.
