//  SlideRuleDetailView.swift
//  TheElectricSlide
//
//  Extracted from ContentView.swift
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

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
        // Use VStack to stack: fixed cursor readings (top) + transformed slide rule content (bottom)
        VStack(spacing: 0) {
            // Fixed cursor readings - never transformed, always at top
            cursorReadingsArea()
                .padding(.horizontal, 8)
                .padding(.top, 8)
            
            // Main transformable slide rule content - pan/zoom applied here
            DynamicSlideRuleContent(
                viewMode: $viewMode,
                slideRule: currentSlideRule,
                ruleId: ruleId,
                calculatedDimensions: calculatedDimensions,
                nameFont: calculatedDimensions.tier.nameFont,
                formulaFont: calculatedDimensions.tier.formulaFont,
                sliderOffset: $sliderOffset,
                cursorState: cursorState,
                cursorDisplayMode: $cursorDisplayMode,
                cursorReadingCycleMode: $cursorReadingCycleMode,
                currentZoomScale: currentZoomScale,  // For pan gesture control
                handleDragChanged: handleDragChanged,
                handleDragEnded: handleDragEnded,
                handlePanChanged: handlePanChanged,  // Pan gesture for zoomed content
                handlePanEnded: handlePanEnded,  // Pan gesture end
                handleResetZoom: handleResetZoom,  // Triple-tap to reset zoom
                totalScaleHeight: totalScaleHeight,
                selectedRuleDefinition: selectedRuleDefinition,
                deviceCategory: deviceCategory,
                showCursorReadings: false  // Don't show cursor readings in content - shown above
            )
            .modifier(PanPositionModifier(offset: panOffset))  // Use custom modifier for jitter-free pan
            .scaleEffect(currentZoomScale, anchor: .top)  // Scale from top to prevent vertical shift
        }
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
        // macOS: Scroll wheel / trackpad two-finger scroll for zoom
        .onScrollWheelZoom(
            speed: 1,
            onZoomChanged: handleZoomChanged,
            onZoomEnded: handleZoomEnded
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
        // STICKY HEADER: Use .safeAreaInset to place header OUTSIDE the transformed coordinate space
        // This ensures the header stays fixed at the top regardless of pan/zoom transforms
        .safeAreaInset(edge: .top, spacing: 0) {
            if deviceCategory.supportsMultiSideView {
                VStack(spacing: 0) {
                    Divider()
                    
                    combinedPickersSection()
                    
                    Divider()
                }
                .frame(maxWidth: .infinity)
                .background(systemBackgroundColor())
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
            // Slide rule name and side indicator
            if let ruleName = selectedRuleDefinition?.name {
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
                .contentShape(Rectangle())
                .onTapGesture {
                    // Cycle through available view modes
                    viewMode = viewMode.next(for: deviceCategory)
                }
                #if os(iOS)
                .hoverEffect(.highlight)
                #endif
                .accessibilityLabel("Current slide rule: \(ruleName), \(viewMode.rawValue) side")
                .accessibilityHint("Tap to cycle through view modes")
                .accessibilityIdentifier("slideRuleNameHeader_\(viewMode.rawValue.lowercased())")
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Cursor Readings Area (Fixed, Not Transformed)
    
    /// Creates the cursor readings display - extracted from DynamicSlideRuleContent
    /// to prevent it from being transformed by zoom/pan operations
    @ViewBuilder
    private func cursorReadingsArea() -> some View {
        let frontReadings = cursorState.currentReadings?.frontReadings ?? []
        let backReadings = cursorState.currentReadings?.backReadings ?? []
        let hasBackSide = currentSlideRule.backTopStator != nil
        
        // Determine which readings to show based on cycle mode and current view mode
        let (shouldShowFront, shouldShowBack): (Bool, Bool) = {
            switch viewMode {
            case .both:
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)
                case .oppositeSide:
                    return (false, hasBackSide)
                case .both:
                    return (true, hasBackSide)
                case .none:
                    return (false, false)
                }
            case .front:
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)
                case .oppositeSide:
                    return (false, hasBackSide)
                case .both:
                    return (true, hasBackSide)
                case .none:
                    return (false, false)
                }
            case .back:
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (false, true)
                case .oppositeSide:
                    return (true, false)
                case .both:
                    return (true, true)
                case .none:
                    return (false, false)
                }
            }
        }()
        
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
            
            if cursorReadingCycleMode == .none {
                Color.clear
                    .frame(height: 12)
            }
        }
        .frame(minHeight: 50)
        .background(systemBackgroundColor())
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                cursorReadingCycleMode = cursorReadingCycleMode.next()
            }
        }
        .accessibilityLabel("Cycle cursor reading mode")
        .accessibilityHint("Tap to cycle reading display modes")
        .accessibilityIdentifier("cursorReadingCycleToggle")
        .opacity(0.95)
    }
}

