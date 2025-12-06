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

