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

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var currentRuleQuery: [CurrentSlideRule]
    @Query(sort: \SlideRuleDefinitionModel.sortOrder) private var availableRules: [SlideRuleDefinitionModel]
    
    // MARK: - View Model (uses hot/cold property pattern for performance)
    // See slide-rule-performance-decisions-and-planning.md for rationale
    // Note: internal access for extension in ContentView+Gestures.swift
    @State var viewModel = SlideRuleViewModel()
    
    // MARK: - View State (kept as @State per performance doc - avoid circular dependencies)
    @State private var viewMode: ViewMode = .both  // View mode selector
    @State private var cursorDisplayMode: CursorDisplayMode = .both  // Cursor display mode
    @State private var cursorReadingCycleMode: CursorReadingCycleMode = .currentSide  // Cycle mode for reading display
    @State private var deviceCategory: DeviceCategory = DeviceDetection.currentDeviceCategory()  // Device detection for adaptive UI
    
    // ✅ State for calculated dimensions - only updates when window size changes
    // Note: internal access for extension in ContentView+Gestures.swift
    @State var calculatedDimensions: Dimensions = .default
    @State var cursorState = CursorState()
    
    // Current slide rule selection (persisted via SwiftData)
    @State private var selectedRuleDefinition: SlideRuleDefinitionModel?
    @State private var selectedRuleId: UUID? // Track ID separately for onChange
    
    // Parsed slide rule from definition - published state to trigger re-renders
    @State private var currentSlideRule: SlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
    
    
    // Scale height configuration
    private let minScaleHeight: CGFloat = 20   // Minimum height for a scale
    private let idealScaleHeight: CGFloat = 25 // Ideal height per scale
    private let maxScaleHeight: CGFloat = 30   // Maximum height per scale
    
    // Target aspect ratio (width:height) for slide rule
    // Slide rules are typically very wide and relatively short (10:1 to 8:1)
    private let targetAspectRatio: CGFloat = 10.0
    
    // Padding around the slide rule
    private let padding: CGFloat = 40
    
    // Access current slide rule (now a @State variable, not computed)
    private var slideRule: SlideRule {
        currentSlideRule
    }
    
    // Calculate total number of scales based on view mode
    private var totalScaleCount: Int {
        var count = 0
        
        // Front side scales
        if viewMode == .front || viewMode == .both {
            count += slideRule.frontTopStator.scales.count +
                     slideRule.frontSlide.scales.count +
                     slideRule.frontBottomStator.scales.count
        }
        
        // Back side scales (if available)
        if (viewMode == .back || viewMode == .both),
           let backTop = slideRule.backTopStator,
           let backSlide = slideRule.backSlide,
           let backBottom = slideRule.backBottomStator {
            count += backTop.scales.count +
                     backSlide.scales.count +
                     backBottom.scales.count
        }
        
        return count
    }
    
    // Calculate number of "gaps" between sides for spacing
    private var sideGapCount: Int {
        // If showing both sides, we have 1 gap between them (20pt spacing)
        if viewMode == .both && slideRule.backTopStator != nil {
            return 1
        }
        return 0
    }
    
    // Vertical spacing between sides when showing both
    private let sideSpacing: CGFloat = 20
    
    // Estimate total vertical space needed for labels (when showing both sides)
    private var labelHeight: CGFloat {
        if viewMode == .both && slideRule.backTopStator != nil {
            return 30  // ~15pt per label × 2 labels
        }
        return 0
    }
    
    // Helper function to calculate responsive dimensions
    nonisolated private func calculateDimensions(availableWidth: CGFloat, availableHeight: CGFloat) -> Dimensions {
        let maxWidth = availableWidth
        let maxHeight = availableHeight - (padding * 2)
        
        // Determine layout tier based on available width
        let tier = LayoutTier.from(availableWidth: availableWidth)
        
        // Use symmetric margins based on layout tier for all platforms
        // This maximizes scale width while maintaining readable scale labels
        let leftMarginWidth = tier.marginWidth
        let rightMarginWidth = tier.marginWidth
        
        // HStack spacing: 4pt between left margin and scale, 4pt between scale and right margin
        let totalMarginAndSpacing = leftMarginWidth + rightMarginWidth + 8
        
        // Calculate local values instead of accessing @State properties
        let localSideGapCount: Int
        if viewMode == .both && currentSlideRule.backTopStator != nil {
            localSideGapCount = 1
        } else {
            localSideGapCount = 0
        }
        
        let localLabelHeight: CGFloat
        if viewMode == .both && currentSlideRule.backTopStator != nil {
            localLabelHeight = 30
        } else {
            localLabelHeight = 0
        }
        
        // Calculate total scale count locally
        var localTotalScaleCount = 0
        if viewMode == .front || viewMode == .both {
            localTotalScaleCount += currentSlideRule.frontTopStator.scales.count +
                                     currentSlideRule.frontSlide.scales.count +
                                     currentSlideRule.frontBottomStator.scales.count
        }
        if (viewMode == .back || viewMode == .both),
           let backTop = currentSlideRule.backTopStator,
           let backSlide = currentSlideRule.backSlide,
           let backBottom = currentSlideRule.backBottomStator {
            localTotalScaleCount += backTop.scales.count +
                                     backSlide.scales.count +
                                     backBottom.scales.count
        }
        
        // Account for spacing between sides and labels
        let totalSpacingHeight = (CGFloat(localSideGapCount) * sideSpacing) + localLabelHeight
        let availableHeightForScales = maxHeight - totalSpacingHeight
        
        // Calculate scale height based on available height
        let calculatedScaleHeight = min(
            availableHeightForScales / CGFloat(localTotalScaleCount),
            maxScaleHeight
        )
        let scaleHeight = max(calculatedScaleHeight, minScaleHeight)
        
        // Calculate total height needed for all scales
        let totalHeight = scaleHeight * CGFloat(localTotalScaleCount) + totalSpacingHeight
        
        // Calculate width based on aspect ratio
        let widthFromAspectRatio = totalHeight * targetAspectRatio
        
        // Use the smaller of the two to ensure it fits within window
        // Then subtract margins to get the actual scale width
        let totalAvailableWidth = min(maxWidth, widthFromAspectRatio)
        let scaleWidth = max(totalAvailableWidth - totalMarginAndSpacing, 100) // 100pt minimum scale width
        
        return Dimensions(
            width: scaleWidth,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth,
            tier: tier
        )
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
                    totalScaleHeight: totalScaleHeight
                )
                .onGeometryChange(for: Dimensions.self) { proxy in
                    let size = proxy.size
                    return calculateDimensions(
                        availableWidth: size.width,
                        availableHeight: size.height
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
        .onAppear {
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
    
    // MARK: - Persistence Helpers
    
    private func loadCurrentRule() {
        if let currentRule = currentRuleQuery.first {
            selectedRuleDefinition = currentRule.selectedRule
            selectedRuleId = currentRule.selectedRule?.id
        }
        // Parse initial slide rule
        parseAndUpdateSlideRule()
    }
    
    private func saveCurrentRule() {
        guard let selectedRuleDefinition = selectedRuleDefinition else {
            print("⚠️ Cannot save: selectedRuleDefinition is nil")
            return
        }
        if let current = currentRuleQuery.first {
            current.updateSelection(selectedRuleDefinition)
        } else {
            let newCurrent = CurrentSlideRule(selectedRule: selectedRuleDefinition)
            modelContext.insert(newCurrent)
        }
        
        try? modelContext.save()
    }
    
    private func parseAndUpdateSlideRule() {
        guard let definition = selectedRuleDefinition else {
            // Use default rule
            print("⚠️ No definition selected, using default")
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
            cursorState.updateReadings()
            return
        }
        
        print("🔧 Parsing slide rule: \(definition.name)")
        print("   Definition: \(definition.definitionString)")
        
        do {
            let parsed = try definition.parseSlideRule(scaleLength: 1000)
            currentSlideRule = parsed
            print("✅ Successfully loaded slide rule: \(definition.name)")
            print("   Front scales: \(parsed.frontTopStator.scales.count) + \(parsed.frontSlide.scales.count) + \(parsed.frontBottomStator.scales.count)")
            
            // Update cursor readings immediately after parsing new slide rule
            cursorState.updateReadings()
        } catch {
            print("❌ Failed to parse slide rule '\(definition.name)': \(error)")
            // Fallback to basic rule
            currentSlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000)
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
