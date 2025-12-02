//
//  DynamicSlideRuleContent.swift
//  TheElectricSlide
//
//  Extracted from ContentView.swift
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

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
