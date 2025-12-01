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

// MARK: - Pan Position Modifier

/// Custom modifier for pan positioning without animation
/// Ensures offset changes are applied immediately without SwiftUI animation interpolation
struct PanPositionModifier: ViewModifier {
    let offset: CGSize
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .animation(nil, value: offset)  // Explicitly disable animation
    }
}
// MARK: - DynamicSlideRuleContent

struct DynamicSlideRuleContent: View {
    // Dependencies from ContentView
    let viewMode: ViewMode
    let slideRule: SlideRule
    let ruleId: UUID?  // Track rule identity for view updates
    let calculatedDimensions: Dimensions
    let nameFont: Font
    let formulaFont: Font
    @Binding var sliderOffset: CGFloat
    let cursorState: CursorState
    let cursorDisplayMode: CursorDisplayMode
    @Binding var cursorReadingCycleMode: CursorReadingCycleMode
    let currentZoomScale: CGFloat  // Current zoom level for pan gesture control
    let handleDragChanged: (DragGesture.Value) -> Void
    let handleDragEnded: (DragGesture.Value) -> Void
    let handlePanChanged: ((DragGesture.Value) -> Void)?  // Pan gesture for zoomed content
    let handlePanEnded: ((DragGesture.Value) -> Void)?  // Pan gesture end
    let handleResetZoom: (() -> Void)?  // Triple-tap to reset zoom to 1.0×
    let totalScaleHeight: (RuleSide) -> CGFloat
    let selectedRuleDefinition: SlideRuleDefinitionModel?  // For displaying rule name
    let deviceCategory: DeviceCategory  // For layout decisions
    
    // MARK: - Stable Dimensions (debounced to avoid intermediate animation values)
    // The system animates geometry changes through intermediate widths (e.g., 876→856→836→816→796)
    // We use stableDimensions to only render with the final settled value
    @State private var stableDimensions: Dimensions?
    @State private var dimensionUpdateTask: Task<Void, Never>?
    
    /// The dimensions to use for rendering - uses stable (debounced) value if available
    private var renderDimensions: Dimensions {
        stableDimensions ?? calculatedDimensions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Consolidated cursor readings display - centered under title
            // Shows readings based on cycle mode with tap-to-cycle gesture
            VStack(spacing: 2) {
                // Rule name and side indicator (always shown on compact devices)
                if !deviceCategory.supportsMultiSideView, let ruleName = selectedRuleDefinition?.name {
                    HStack(spacing: 8) {
                        Text(ruleName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(viewMode == .front ? "Front" : (viewMode == .back ? "Back" : "Both"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 1)
                    .accessibilityLabel("Current slide rule: \(ruleName), \(viewMode.rawValue) side")
                    .accessibilityIdentifier("slideRuleNameHeader_\(viewMode.rawValue.lowercased())")
                }
                
                // Cursor readings with tap-to-cycle - compact stacked layout
                cursorReadingsDisplayArea()
                    .padding(.horizontal, 8)
            }
            
            // Front side - show if mode is .front or .both
            if viewMode == .front || viewMode == .both {
                VStack(spacing: 2) {
                    
                    SideView(
                        side: .front,
                        topStator: slideRule.frontTopStator,
                        slide: slideRule.frontSlide,
                        bottomStator: slideRule.frontBottomStator,
                        width: renderDimensions.width,
                        scaleHeight: renderDimensions.scaleHeight,
                        leftMarginWidth: renderDimensions.leftMarginWidth,
                        rightMarginWidth: renderDimensions.rightMarginWidth,
                        nameFont: nameFont,
                        formulaFont: formulaFont,
                        sliderOffset: sliderOffset,
                        cursorState: cursorState,
                        ruleId: ruleId,  // Pass rule ID for identity tracking
                        currentZoomScale: currentZoomScale,  // For pan gesture control
                        onDragChanged: handleDragChanged,
                        onDragEnded: handleDragEnded,
                        onPanChanged: handlePanChanged,  // Pan gesture for zoomed content
                        onPanEnded: handlePanEnded,  // Pan gesture end
                        onResetZoom: handleResetZoom  // Triple-tap to reset zoom
                    )
                    .equatable()
                    .id("front-\(ruleId?.uuidString ?? "default")")  // Force view recreation on rule change
                    // Disable animation on geometry/dimension changes to prevent intermediate width values
                    .animation(nil, value: renderDimensions.width)
                    .overlay {
                        CursorOverlay(
                            cursorState: cursorState,
                            width: renderDimensions.width,
                            height: totalScaleHeight(.front),
                            side: .front,
                            scaleHeight: renderDimensions.scaleHeight,
                            leftMarginWidth: renderDimensions.leftMarginWidth,
                            rightMarginWidth: renderDimensions.rightMarginWidth,
                            showReadings: cursorState.shouldShowReadings,
                            showGradients: cursorDisplayMode.showGradients,
                            onResetZoom: handleResetZoom,  // Triple-tap on cursor to reset zoom
                            currentZoomScale: currentZoomScale
                        )
                    }
                }
                // Phase 5: Flip transition animation for compact devices (iPhone/Watch)
                // Creates a natural vertical flip effect when switching sides
                // - New view slides up from the bottom with fade-in
                // - Old view slides up to the top with fade-out
                // Animation is triggered by FlipButton's spring animation (response: 0.3s, damping: 0.8)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Spacing between front and back sides when showing both
            if viewMode == .both && slideRule.backTopStator != nil {
                Spacer()
                    .frame(height: 40)
            }

            // Back side - show if mode is .back or .both (and back side exists)
            if (viewMode == .back || viewMode == .both),
               let backTop = slideRule.backTopStator,
               let backSlide = slideRule.backSlide,
               let backBottom = slideRule.backBottomStator {
                VStack(spacing: 2) {
                    SideView(
                        side: .back,
                        topStator: backTop,
                        slide: backSlide,
                        bottomStator: backBottom,
                        width: renderDimensions.width,
                        scaleHeight: renderDimensions.scaleHeight,
                        leftMarginWidth: renderDimensions.leftMarginWidth,
                        rightMarginWidth: renderDimensions.rightMarginWidth,
                        nameFont: nameFont,
                        formulaFont: formulaFont,
                        sliderOffset: sliderOffset,
                        cursorState: cursorState,
                        ruleId: ruleId,  // Pass rule ID for identity tracking
                        currentZoomScale: currentZoomScale,  // For pan gesture control
                        onDragChanged: handleDragChanged,
                        onDragEnded: handleDragEnded,
                        onPanChanged: handlePanChanged,  // Pan gesture for zoomed content
                        onPanEnded: handlePanEnded,  // Pan gesture end
                        onResetZoom: handleResetZoom  // Triple-tap to reset zoom
                    )
                    .equatable()
                    .id("back-\(ruleId?.uuidString ?? "default")")  // Force view recreation on rule change
                    // Disable animation on geometry/dimension changes to prevent intermediate width values
                    .animation(nil, value: renderDimensions.width)
                    .overlay {
                        CursorOverlay(
                            cursorState: cursorState,
                            width: renderDimensions.width,
                            height: totalScaleHeight(.back),
                            side: .back,
                            scaleHeight: renderDimensions.scaleHeight,
                            leftMarginWidth: renderDimensions.leftMarginWidth,
                            rightMarginWidth: renderDimensions.rightMarginWidth,
                            showReadings: cursorState.shouldShowReadings,
                            showGradients: cursorDisplayMode.showGradients,
                            onResetZoom: handleResetZoom,  // Triple-tap on cursor to reset zoom
                            currentZoomScale: currentZoomScale
                        )
                    }
                }
                // Phase 5: Flip transition animation for compact devices (iPhone/Watch)
                // Creates a natural vertical flip effect when switching sides
                // - New view slides up from the bottom with fade-in
                // - Old view slides up to the top with fade-out
                // Animation is triggered by FlipButton's spring animation (response: 0.3s, damping: 0.8)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container, edges: .horizontal)
        .padding(.horizontal, deviceCategory == .phone ? 8 : 20)
        .padding(.bottom, 40)
        // Suppress all animations on dimension changes to prevent scale/cursor desync
        // This fixes the geometry animation bug where intermediate widths cause visual shifts
        .transaction { transaction in
            transaction.animation = nil
        }
        // MARK: - Dimension Debounce Logic
        // The system animates geometry changes through intermediate widths during orientation changes
        // (e.g., 876→856→836→816→796). We debounce updates to only render with the final settled value.
        .onChange(of: calculatedDimensions.width) { oldWidth, newWidth in
            // Cancel any pending update
            dimensionUpdateTask?.cancel()
            
            // Start a new debounce task
            dimensionUpdateTask = Task { @MainActor in
                // Wait for geometry to settle (typical animation is ~0.3s, use 0.1s debounce)
                try? await Task.sleep(for: .milliseconds(100))
                
                // If not cancelled, this is the final value - update stableDimensions
                if !Task.isCancelled {
                    stableDimensions = calculatedDimensions
                }
            }
        }
        .onAppear {
            // Initialize stableDimensions on first appear
            stableDimensions = calculatedDimensions
        }
        .onChange(of: sliderOffset) {
            cursorState.updateReadings()
        }
    }
    
    // MARK: - Cursor Readings Display Area with Tap-to-Cycle
    
    /// Creates the cursor readings display with tap-to-cycle functionality
    /// Cycles through 4 states: currentSide → oppositeSide → both → none → repeat
    @ViewBuilder
    private func cursorReadingsDisplayArea() -> some View {
        let frontReadings = cursorState.currentReadings?.frontReadings ?? []
        let backReadings = cursorState.currentReadings?.backReadings ?? []
        let hasBackSide = slideRule.backTopStator != nil
        
        // Determine which readings to show based on cycle mode and current view mode
        // Cycle mode controls display for all view modes, allowing selective reading visibility
        let (shouldShowFront, shouldShowBack): (Bool, Bool) = {
            switch viewMode {
            case .both:
                // In "both" view mode, respect cycle mode for selective display
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)  // Show front only
                case .oppositeSide:
                    return (false, hasBackSide)  // Show back only (if exists)
                case .both:
                    return (true, hasBackSide)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            case .front:
                // Currently viewing front side
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)  // Show front only
                case .oppositeSide:
                    return (false, hasBackSide)  // Show back only (if exists)
                case .both:
                    return (true, hasBackSide)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            case .back:
                // Currently viewing back side
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (false, true)  // Show back only
                case .oppositeSide:
                    return (true, false)  // Show front only
                case .both:
                    return (true, true)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            }
        }()
        
        // Stacked layout with tap gesture - negative spacing for tight rows
        VStack(spacing: -4) {
            if shouldShowFront {
                CursorReadingsDisplayView(
                    readings: frontReadings,
                    side: .front
                )
                .equatable()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
            }
            
            if shouldShowBack {
                CursorReadingsDisplayView(
                    readings: backReadings,
                    side: .back
                )
                .equatable()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
            }
            
            // Show placeholder when in "none" mode to maintain tap target
            if cursorReadingCycleMode == .none {
                Color.clear
                    .frame(height: 12)  // Minimal height for tap target
            }
        }
        .frame(minHeight: 50)  // CRITICAL: Maintain consistent minimum height across all cycle modes
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap to cycle through all display states, regardless of view mode
            withAnimation(.easeInOut(duration: 0.2)) {
                cursorReadingCycleMode = cursorReadingCycleMode.next()
            }
        }
        .accessibilityLabel("Cycle cursor reading mode")
        .accessibilityHint("Tap to cycle reading display modes")
        .accessibilityIdentifier("cursorReadingCycleToggle")
        // Subtle opacity feedback
        .opacity(0.95)
    }
}


// MARK: - Platform Color Helpers

#if os(iOS)
private func systemBackgroundColor() -> Color {
    Color(uiColor: .systemBackground)
}
#else
private func systemBackgroundColor() -> Color {
    Color(nsColor: .windowBackgroundColor)
}
#endif

// MARK: - Sidebar View (List of Slide Rules)

struct SlideRuleSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedRule: SlideRuleDefinitionModel?
    @Binding var viewMode: ViewMode
    @Binding var cursorDisplayMode: CursorDisplayMode
    let availableRules: [SlideRuleDefinitionModel]
    let hasBackSide: Bool
    let deviceCategory: DeviceCategory
    let onRuleSelected: (SlideRuleDefinitionModel) -> Void
    
    /// Available view modes based on device category and slide rule capabilities
    private var availableModes: [ViewMode] {
        ViewMode.availableModes(for: deviceCategory).filter { mode in
            mode == .front || hasBackSide
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Cursor Display Mode Picker at top
            VStack(spacing: 8) {
                Text("Cursor Display")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Cursor Display", selection: $cursorDisplayMode) {
                    ForEach(CursorDisplayMode.allCases) { mode in
                        Text(mode.displayText).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding()
            .background(systemBackgroundColor())

            Divider()
            
            // View Mode Picker (Front | Back | Both)
            Picker("View Mode", selection: $viewMode) {
                ForEach(availableModes) { mode in
                    Text(mode.rawValue).tag(mode)
                        .accessibilityLabel("\(mode.rawValue) side")
                        .accessibilityIdentifier("viewModeOption_\(mode.rawValue.lowercased())")
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
            .allowsHitTesting(true)
            .accessibilityLabel("View mode selector")
            .accessibilityIdentifier("viewModePicker")
            .accessibilityValue(viewMode.rawValue)
            .accessibilityHint("Select which side of the slide rule to display")
            
            Divider()
            
            // List of slide rules
            List(availableRules, selection: $selectedRule) { rule in
                Button {
                    onRuleSelected(rule)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                    // Icon
                    Image(systemName: rule.circularSpec != nil ? "circle.hexagongrid.circle" : "ruler.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.name)
                            .font(.headline)
                        
                        Text(rule.ruleDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            }
            .navigationTitle("Slide Rules")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            #endif
            .onAppear {
                initializeLibraryIfNeeded()
            }
        }
    }
    
    /// Initialize or update library with standard rules
    /// Detects version changes and updates modified rules
    private func initializeLibraryIfNeeded() {
        let standardRules = SlideRuleLibrary.standardRules()
        
        if availableRules.isEmpty {
            // First time: insert all rules
            print("📚 Initializing slide rule library (version \(SlideRuleLibrary.libraryVersion))")
            for rule in standardRules {
                modelContext.insert(rule)
            }
        } else {
            // Check if library version has changed
            let maxExistingVersion = availableRules.map { $0.libraryVersion }.max() ?? 0
            
            if maxExistingVersion < SlideRuleLibrary.libraryVersion {
                print("📚 Updating slide rule library: v\(maxExistingVersion) → v\(SlideRuleLibrary.libraryVersion)")
                
                // Create a lookup of existing rules by name
                var existingRulesByName: [String: SlideRuleDefinitionModel] = [:]
                for rule in availableRules {
                    existingRulesByName[rule.name] = rule
                }
                
                // Update or insert each standard rule
                for standardRule in standardRules {
                    if let existingRule = existingRulesByName[standardRule.name] {
                        // Update existing rule with new definition
                        print("  ↻ Updating: \(standardRule.name)")
                        existingRule.ruleDescription = standardRule.ruleDescription
                        existingRule.definitionString = standardRule.definitionString
                        existingRule.topStatorMM = standardRule.topStatorMM
                        existingRule.slideMM = standardRule.slideMM
                        existingRule.bottomStatorMM = standardRule.bottomStatorMM
                        existingRule.circularSpec = standardRule.circularSpec
                        existingRule.sortOrder = standardRule.sortOrder
                        existingRule.scaleNameOverrides = standardRule.scaleNameOverrides
                        existingRule.libraryVersion = standardRule.libraryVersion
                        // Preserve user's favorite status
                    } else {
                        // New rule: insert it
                        print("  + Adding: \(standardRule.name)")
                        modelContext.insert(standardRule)
                    }
                }
                
                // Optionally: Remove rules that no longer exist in standard library
                // (commented out to preserve user-created custom rules)
                /*
                let standardRuleNames = Set(standardRules.map { $0.name })
                for existingRule in availableRules {
                    if !standardRuleNames.contains(existingRule.name) && existingRule.libraryVersion > 0 {
                        print("  - Removing: \(existingRule.name)")
                        modelContext.delete(existingRule)
                    }
                }
                */
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Slide rule library synchronized")
        } catch {
            print("❌ Failed to save slide rule library: \(error)")
        }
    }
}

// MARK: - Detail View (Slide Rule Visualization)

struct SlideRuleDetailView: View {
    @Binding var viewMode: ViewMode
    @Binding var cursorDisplayMode: CursorDisplayMode
    @Binding var cursorReadingCycleMode: CursorReadingCycleMode
    let deviceCategory: DeviceCategory
    let currentSlideRule: SlideRule
    let ruleId: UUID?  // Track rule identity for view updates
    let selectedRuleDefinition: SlideRuleDefinitionModel?  // For displaying rule name
    
    @Binding var calculatedDimensions: Dimensions
    @Binding var sliderOffset: CGFloat
    let cursorState: CursorState
    @Binding var currentZoomScale: CGFloat  // Current zoom level for pinch-to-zoom
    @Binding var panOffset: CGSize  // Pan offset for moving zoomed content
    
    let handleDragChanged: (DragGesture.Value) -> Void
    let handleDragEnded: (DragGesture.Value) -> Void
    let handleZoomChanged: (CGFloat) -> Void  // Pinch zoom changed
    let handleZoomEnded: (CGFloat) -> Void  // Pinch zoom ended
    let handlePanChanged: (DragGesture.Value) -> Void  // Pan gesture for zoomed content
    let handlePanEnded: (DragGesture.Value) -> Void  // Pan gesture end
    let handleResetZoom: () -> Void  // Triple-tap to reset zoom
    let totalScaleHeight: (RuleSide) -> CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Header controls (ViewMode picker for iPad/Mac)
            // NOTE: Cursor Display picker is now in the sidebar
            if deviceCategory.supportsMultiSideView {
                VStack(spacing: 0) {
                    Divider()
                    
                    combinedPickersSection()
                    
                    Divider()
                }
                .background(systemBackgroundColor())
                .allowsHitTesting(true)
                .zIndex(100)
            }
            
            // Dynamic content - responds to sliderOffset and zoom
            DynamicSlideRuleContent(
                viewMode: viewMode,
                slideRule: currentSlideRule,
                ruleId: ruleId,
                calculatedDimensions: calculatedDimensions,
                nameFont: calculatedDimensions.tier.nameFont,
                formulaFont: calculatedDimensions.tier.formulaFont,
                sliderOffset: $sliderOffset,
                cursorState: cursorState,
                cursorDisplayMode: cursorDisplayMode,
                cursorReadingCycleMode: $cursorReadingCycleMode,
                currentZoomScale: currentZoomScale,  // For pan gesture control
                handleDragChanged: handleDragChanged,
                handleDragEnded: handleDragEnded,
                handlePanChanged: handlePanChanged,  // Pan gesture for zoomed content
                handlePanEnded: handlePanEnded,  // Pan gesture end
                handleResetZoom: handleResetZoom,  // Triple-tap to reset zoom
                totalScaleHeight: totalScaleHeight,
                selectedRuleDefinition: selectedRuleDefinition,
                deviceCategory: deviceCategory
            )
            .modifier(PanPositionModifier(offset: panOffset))  // Use custom modifier for jitter-free pan
            .scaleEffect(currentZoomScale, anchor: .top)  // Scale from top to prevent vertical shift
            // NOTE: .drawingGroup() removed - was causing scale shift bug at high zoom levels
            // The Metal rasterization cache wasn't updating correctly during geometry animations
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        handleZoomChanged(scale)
                    }
                    .onEnded { scale in
                        handleZoomEnded(scale)
                    }
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: currentZoomScale)
            .overlay(alignment: .bottomLeading) {
                // Floating flip button for compact devices (iPhone, Apple Watch)
                // Positioned at bottom-left, horizontally aligned under NavigationView's disclosure widget
                if !deviceCategory.supportsMultiSideView && currentSlideRule.backTopStator != nil {
                    FlipButton(viewMode: $viewMode)
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                }
            }
        }
    }
    
    /// View Mode picker section for regular devices (iPad, Mac, Vision Pro)
    @ViewBuilder
    private func combinedPickersSection() -> some View {
        let availableModes = ViewMode.availableModes(for: deviceCategory).filter { mode in
            mode == .front || (currentSlideRule.backTopStator != nil)
        }
        
        HStack(spacing: 16) {
            // Slide rule name label
            if let ruleName = selectedRuleDefinition?.name {
                Text(ruleName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Current slide rule: \(ruleName)")
                    .accessibilityIdentifier("currentSlideRuleName")
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var currentRuleQuery: [CurrentSlideRule]
    @Query(sort: \SlideRuleDefinitionModel.sortOrder) private var availableRules: [SlideRuleDefinitionModel]
    
    // MARK: - View Model (uses hot/cold property pattern for performance)
    // See slide-rule-performance-decisions-and-planning.md for rationale
    @State private var viewModel = SlideRuleViewModel()
    
    // MARK: - View State (kept as @State per performance doc - avoid circular dependencies)
    @State private var viewMode: ViewMode = .both  // View mode selector
    @State private var cursorDisplayMode: CursorDisplayMode = .both  // Cursor display mode
    @State private var cursorReadingCycleMode: CursorReadingCycleMode = .currentSide  // Cycle mode for reading display
    @State private var deviceCategory: DeviceCategory = DeviceDetection.currentDeviceCategory()  // Device detection for adaptive UI
    
    // ✅ State for calculated dimensions - only updates when window size changes
    @State private var calculatedDimensions: Dimensions = .default
    @State private var cursorState = CursorState()
    
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
    
    // ✅ Drag gesture handlers - delegate to viewModel (uses hot/cold pattern)
    private func handleDragChanged(_ gesture: DragGesture.Value) {
        // Mark slide as dragging
        cursorState.setSlideDragging(true)
        viewModel.handleSliderDragChanged(translation: gesture.translation.width)
    }
    
    private func handleDragEnded(_ gesture: DragGesture.Value) {
        viewModel.handleSliderDragEnded()
        // Mark slide drag as ended
        cursorState.setSlideDragging(false)
    }
    
    // ✅ Zoom gesture handlers - delegate to viewModel (uses hot/cold pattern)
    private func handleZoomChanged(_ scale: CGFloat) {
        viewModel.handleZoomChanged(scale: scale)
    }
    
    private func handleZoomEnded(_ scale: CGFloat) {
        viewModel.handleZoomEnded(scale: scale)
        
        // Log cursor and scale info for debugging
        #if DEBUG
        print("🔍 [Zoom Debug] Cursor normalized position: \(cursorState.normalizedPosition)")
        print("🔍 [Zoom Debug] Dimensions - width: \(calculatedDimensions.width), leftMargin: \(calculatedDimensions.leftMarginWidth)")
        if let readings = cursorState.currentReadings {
            print("🔍 [Zoom Debug] Hairline position: \(String(format: "%.4f", readings.cursorPosition))")
            // Log K, C, D scales if available
            for scaleName in ["K", "C", "D", "A"] {
                if let reading = readings.reading(forScale: scaleName, side: .front) {
                    print("🔍 [Zoom Debug]   \(scaleName) scale: \(reading.displayValue) (raw: \(String(format: "%.6f", reading.value)))")
                }
            }
        }
        #endif
    }
    
    // MARK: - Pan Handlers
    
    /// Handles pan gesture changes during drag to pan zoomed content
    /// Uses withTransaction to suppress animations for smooth, jitter-free tracking
    private func handlePanChanged(_ gesture: DragGesture.Value) {
        withTransaction(Transaction(animation: nil)) {
            viewModel.handlePanChanged(translation: gesture.translation)
        }
    }
    
    /// Handles pan gesture end and commits the new base offset
    /// Uses withTransaction to suppress animations for immediate response
    private func handlePanEnded(_ gesture: DragGesture.Value) {
        withTransaction(Transaction(animation: nil)) {
            viewModel.handlePanEnded()
        }
    }
    
    /// Handles triple-tap to reset zoom to 1.0× and clear pan offset
    /// Animates the zoom reset for visual feedback
    private func handleResetZoom() {
        // Reset zoom with animation for visual feedback
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.resetZoom()
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
