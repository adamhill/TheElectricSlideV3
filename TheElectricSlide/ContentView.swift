//
//  ContentView.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/18/25.
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

// Types extracted to Models/:
// - Dimensions, LayoutTier (Models/LayoutConfiguration.swift)
// - ViewMode (Models/ViewMode.swift)
// - CursorDisplayMode, CursorReadingCycleMode (Models/CursorDisplayMode.swift)
// - RuleSide (Models/RuleSide.swift)
// - SlideRuleViewModel (Models/SlideRuleViewModel.swift)

// Components extracted to Components/:
// - ScaleView (Components/ScaleView.swift)
// - StatorView (Components/StatorView.swift)
// - SlideView (Components/SlideView.swift)
// - SideView (Components/SideView.swift)
// - SlideRuleSidebarView (Components/SlideRuleSidebarView.swift)
// - SlideRuleDetailView (Components/SlideRuleDetailView.swift)
// - DynamicSlideRuleContent (Components/DynamicSlideRuleContent.swift)

// Extensions:
// - ContentView+Gestures (Extensions/ContentView+Gestures.swift) - Drag, zoom, pan gesture handlers
// - ContentView+Persistence (Extensions/ContentView+Persistence.swift) - SwiftData load/save/parse

// MARK: - ContentView

struct ContentView: View {
    // Note: internal access for extension in ContentView+Persistence.swift
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query var currentRuleQuery: [CurrentSlideRule]
    @Query(sort: \SlideRuleDefinitionModel.sortOrder) private var availableRules: [SlideRuleDefinitionModel]
    
    // MARK: - View Model (uses hot/cold property pattern for performance)
    // See slide-rule-performance-decisions-and-planning.md for rationale
    // Note: internal access for extension in ContentView+Gestures.swift
    @State var viewModel = SlideRuleViewModel()
    
    // MARK: - Tick Haptic Coordinator
    // Provides haptic feedback when cursor crosses C scale tick marks during slide movement
    @State var tickHapticCoordinator = TickHapticCoordinator()
    
    // MARK: - Precision Drag Coordinator
    // Unified precision mode state management for slide and cursor (Phase 3 refactoring)
    @State var precisionCoordinator = PrecisionDragCoordinator()
    
    // MARK: - Gesture Handler
    // Phase 4 Bold Refactor: Centralized gesture handling via environment
    // Eliminates callback prop drilling through SlideRuleDetailView → DynamicSlideRuleContent → SideView/CursorOverlay
    @State private var gestureHandler: GestureHandler?
    
    // MARK: - View State (kept as @State per performance doc - avoid circular dependencies)
    // Note: viewMode is internal for access from ContentView+Gestures extension
    @State var viewMode: ViewMode = .both  // View mode selector
    @State private var cursorDisplayMode: CursorDisplayMode = .both  // Cursor display mode
    @State private var cursorReadingCycleMode: CursorReadingCycleMode = .currentSide  // Cycle mode for reading display
    @State private var deviceCategory: DeviceCategory = DeviceDetection.currentDeviceCategory()  // Device detection for adaptive UI
    
    // ✅ State for calculated dimensions - only updates when window size changes
    // Note: internal access for extensions
    @State var calculatedDimensions: Dimensions = .default
    @State var cursorState = CursorState()
    
    // Current slide rule selection (persisted via SwiftData)
    // Note: internal access for extension in ContentView+Persistence.swift
    @State var selectedRuleDefinition: SlideRuleDefinitionModel?
    @State var selectedRuleId: UUID? // Track ID separately for onChange
    
    // Parsed slide rule from definition - published state to trigger re-renders
    // Note: internal access for extension in ContentView+Persistence.swift
    @State var currentSlideRule: SlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
    
    // Access current slide rule (now a @State variable, not computed)
    private var slideRule: SlideRule {
        currentSlideRule
    }
    
    /// Calculate total vertical height for all scales on a given side
    /// - Parameter side: The rule side to calculate height for
    /// - Returns: Total height in points
    private func totalScaleHeight(for side: RuleSide) -> CGFloat {
        let stator: Stator
        let slide: Slide
        let bottomStator: Stator
        
        switch side {
        case .front:
            stator = slideRule.frontTopStator
            slide = slideRule.frontSlide
            bottomStator = slideRule.frontBottomStator
        case .back:
            guard let backTop = slideRule.backTopStator,
                  let backSlide = slideRule.backSlide,
                  let backBottom = slideRule.backBottomStator else {
                return 0
            }
            stator = backTop
            slide = backSlide
            bottomStator = backBottom
        }
        
        let scaleCount = stator.scales.count +
                         slide.scales.count +
                         bottomStator.scales.count
        return CGFloat(scaleCount) * calculatedDimensions.scaleHeight
    }
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR: List of available slide rules
            SlideRuleSidebarView(
                selectedRule: $selectedRuleDefinition,
                viewMode: $viewMode,
                cursorDisplayMode: $cursorDisplayMode,
                availableRules: availableRules,
                hasBackSide: currentSlideRule.backTopStator != nil,
                deviceCategory: deviceCategory,
                onRuleSelected: { rule in
                    selectedRuleDefinition = rule
                    selectedRuleId = rule.id
                }
            )
        } detail: {
            // DETAIL: Slide rule visualization
            if selectedRuleDefinition != nil {
                SlideRuleDetailView(
                    viewMode: $viewMode,
                    cursorDisplayMode: $cursorDisplayMode,
                    cursorReadingCycleMode: $cursorReadingCycleMode,
                    deviceCategory: deviceCategory,
                    currentSlideRule: currentSlideRule,
                    ruleId: selectedRuleId,
                    selectedRuleDefinition: selectedRuleDefinition,
                    calculatedDimensions: $calculatedDimensions,
                    sliderOffset: $viewModel.sliderOffset,
                    cursorState: cursorState,
                    currentZoomScale: $viewModel.currentZoomScale,
                    panOffset: $viewModel.panOffset,
                    handleDragChanged: handleDragChanged,
                    handleDragEnded: handleDragEnded,
                    handleZoomChanged: handleZoomChanged,
                    handleZoomEnded: handleZoomEnded,
                    handlePanChanged: handlePanChanged,
                    handlePanEnded: handlePanEnded,
                    handleResetZoom: handleResetZoom,
                    handleFlip: handleFlip,
                    totalScaleHeight: totalScaleHeight,
                    handleCursorDragChanged: handleCursorDragChanged,  // Tick haptics during cursor drag
                    handleCursorDragEnded: handleCursorDragEnded  // Reset tick haptic coordinator
                )
                .onGeometryChange(for: Dimensions.self) { proxy in
                    let size = proxy.size
                    return Dimensions.calculate(
                        availableWidth: size.width,
                        availableHeight: size.height,
                        viewMode: viewMode,
                        slideRule: currentSlideRule
                    )
                } action: { newDimensions in
                    // Disable animation on geometry changes to prevent drawingGroup cache issues
                    withTransaction(Transaction(animation: nil)) {
                        calculatedDimensions = newDimensions
                        // Update viewModel's scale width for offset clamping
                        viewModel.updateScaleWidth(newDimensions.width)
                    }
                }
            } else {
                // Empty state when no rule selected
                ContentUnavailableView(
                    "Select a Slide Rule",
                    systemImage: "ruler",
                    description: Text("Choose a slide rule from the sidebar to begin")
                )
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        // Phase 3 & 4: Inject environment values for gesture handling
        .environment(\.precisionCoordinator, precisionCoordinator)
        .environment(\.slideRuleViewModel, viewModel)
        .environment(\.tickHapticCoordinator, tickHapticCoordinator)
        .environment(\.gestureHandler, gestureHandler)
        .onAppear {
            // Phase 4: Create GestureHandler with closures for dynamic data
            let handler = GestureHandler(
                viewModel: viewModel,
                cursorState: cursorState,
                tickHapticCoordinator: tickHapticCoordinator,
                getViewMode: { [self] in self.viewMode },
                getSlideRule: { [self] in self.currentSlideRule },
                getDimensions: { [self] in self.calculatedDimensions }
            )
            // Set up flip callback (handleFlip modifies viewMode binding)
            handler.onFlipRequested = { [self] in
                self.handleFlip()
            }
            gestureHandler = handler
            
            cursorState.setSlideRuleProvider(self)
            cursorState.enableReadings = true
            // Set stator touched to show readings by default
            cursorState.setStatorTouched()
            // Initialize device category
            deviceCategory = DeviceDetection.currentDeviceCategory()
            #if DEBUG
            print("[ViewMode] Device category initialized: \(deviceCategory.rawValue)")
            #endif
            
            // CRITICAL: Constrain viewMode to device capabilities on launch
            let constrainedMode = viewMode.constrained(for: deviceCategory)
            if constrainedMode != viewMode {
                #if DEBUG
                print("[ViewMode] Constraining on launch: \(viewMode.rawValue) → \(constrainedMode.rawValue)")
                #endif
                viewMode = constrainedMode
            }
            
            loadCurrentRule()
        }
        .onChange(of: selectedRuleDefinition) { oldValue, newValue in
            print("🔄 selectedRuleDefinition changed (object)")
            selectedRuleId = newValue?.id
        }
        .onChange(of: selectedRuleId) { oldValue, newValue in
            print("🔄 Rule selection changed: \(oldValue?.uuidString ?? "nil") -> \(newValue?.uuidString ?? "nil")")
            print("   New rule: \(selectedRuleDefinition?.name ?? "nil")")
            parseAndUpdateSlideRule()
            viewModel.resetSlider()
            // Force cursor readings update for new slide rule scales
            cursorState.updateReadings()
            saveCurrentRule()
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            // Re-detect device category when size class changes
            deviceCategory = DeviceDetection.currentDeviceCategory()
            #if DEBUG
            print("[ViewMode] Horizontal size class changed, device category updated: \(deviceCategory.rawValue)")
            #endif
            
            // Constrain viewMode to device capabilities after size class change
            let constrainedMode = viewMode.constrained(for: deviceCategory)
            if constrainedMode != viewMode {
                #if DEBUG
                print("[ViewMode] Constraining after size class change: \(viewMode.rawValue) → \(constrainedMode.rawValue)")
                #endif
                viewMode = constrainedMode
            }
        }
        .onChange(of: deviceCategory) { oldCategory, newCategory in
            #if DEBUG
            print("[ViewMode] Device category changed: \(oldCategory.rawValue) → \(newCategory.rawValue)")
            #endif
            let constrainedMode = viewMode.constrained(for: newCategory)
            if constrainedMode != viewMode {
                #if DEBUG
                print("[ViewMode] Constraining after device category change: \(viewMode.rawValue) → \(constrainedMode.rawValue)")
                #endif
                viewMode = constrainedMode
            }
        }
        .onChange(of: viewMode) { oldValue, newValue in
            #if DEBUG
            print("[ViewMode] View mode changed: \(oldValue.rawValue) → \(newValue.rawValue)")
            #endif
            // Update cursor readings when view mode changes to reflect new visible scales
            cursorState.updateReadings()
        }
    }
}

// MARK: - SlideRuleProvider Conformance

extension ContentView: SlideRuleProvider {
    func getFrontScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)? {
        // Always return front data - the view decides what to display
        // This allows cursor readings to show opposite side or both sides
        return (
            topStator: currentSlideRule.frontTopStator,
            slide: currentSlideRule.frontSlide,
            bottomStator: currentSlideRule.frontBottomStator
        )
    }
    
    func getBackScaleData() -> (topStator: Stator, slide: Slide, bottomStator: Stator)? {
        // Always return back data if it exists - the view decides what to display
        // This allows cursor readings to show opposite side or both sides
        guard let backTop = currentSlideRule.backTopStator,
              let backSlide = currentSlideRule.backSlide,
              let backBottom = currentSlideRule.backBottomStator else {
            return nil
        }
        return (backTop, backSlide, backBottom)
    }
    
    func getSlideOffset() -> CGFloat {
        viewModel.sliderOffset
    }
    
    func getScaleWidth() -> CGFloat {
        calculatedDimensions.width
    }
}

#Preview {
    ContentView()
        .frame(width: 900)
}
