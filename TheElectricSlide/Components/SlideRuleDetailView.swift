//  SlideRuleDetailView.swift
//  TheElectricSlide
//
//  Extracted from ContentView.swift
//
//  Phase 7 Cleanup: Removed gesture callbacks - zoom gestures now use
//  @Environment(\.gestureHandler). Child views handle their own gestures via environment.
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
    @Environment(\.gestureHandler) private var gestureHandler
    @Environment(\.slideRuleViewModel) private var viewModel
    
    // MARK: - Magnification Gesture State
    
    /// Tracks whether a pinch-to-zoom gesture is currently active.
    /// This @GestureState auto-resets to false when the gesture ends.
    ///
    /// ## Apple Best Practice: @GestureState for Transient Gesture Tracking
    /// Per "Composing SwiftUI gestures" documentation:
    /// - @GestureState is designed for tracking values during an active gesture
    /// - Automatically resets when gesture becomes inactive
    /// - Perfect for "is gesture active?" boolean flags
    ///
    /// ## Why This Solves the Pinch-Zoom Conflict
    /// When pinch-zooming, user's fingers may spread across the slide component,
    /// inadvertently triggering its drag gesture. By tracking `isMagnifying` and
    /// using the `gesture(_:isEnabled:)` API on slide drag gestures, we can
    /// temporarily disable slide movement during active pinch operations.
    @GestureState private var isMagnifying: Bool = false
    
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
                currentZoomScale: currentZoomScale,
                panOffset: $panOffset,
                totalScaleHeight: totalScaleHeight,
                selectedRuleDefinition: selectedRuleDefinition,
                deviceCategory: deviceCategory
            )
            // NOTE: Only the internal components (SideView) are scaled now, not the container
            // This ensures cursor readings remain fixed scale/position
            
            // NOTE: .drawingGroup() removed - was causing scale shift bug at high zoom levels
            // The Metal rasterization cache wasn't updating correctly during geometry animations
            .simultaneousGesture(
                MagnificationGesture()
                    // MARK: Magnification Active State Tracking
                    // Use .updating() to track whether pinch gesture is active.
                    // Per Apple docs: @GestureState auto-resets when gesture ends.
                    // This drives isMagnifying state that disables slide drag gestures.
                    .updating($isMagnifying) { _, state, _ in
                        state = true
                    }
                    .onChanged { scale in
                        // Sync magnification active state to viewModel for child views
                        // This propagates via @Environment(\.slideRuleViewModel) to SideView
                        viewModel?.setMagnificationActive(true)
                        
                        // Phase 7: Use gestureHandler for zoom
                        if let handler = gestureHandler {
                            handler.handleZoomChanged(scale)
                        }
                    }
                    .onEnded { scale in
                        // Clear magnification active state when gesture completes
                        viewModel?.setMagnificationActive(false)
                        
                        // Phase 7: Use gestureHandler for zoom
                        if let handler = gestureHandler {
                            handler.handleZoomEnded(scale)
                        }
                    }
            )
            // macOS: Scroll wheel / trackpad two-finger scroll for zoom
            .onScrollWheelZoom(
                speed: 1,
                onZoomChanged: { scale in
                    if let handler = gestureHandler {
                        handler.handleZoomChanged(scale)
                    }
                },
                onZoomEnded: { scale in
                    if let handler = gestureHandler {
                        handler.handleZoomEnded(scale)
                    }
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
    /// Tapping cycles through available view modes (Front → Back → Both → Front...)
    @ViewBuilder
    private func combinedPickersSection() -> some View {
        let availableModes = ViewMode.availableModes(for: deviceCategory).filter { mode in
            mode == .front || (currentSlideRule.backTopStator != nil)
        }
        
        HStack(spacing: 16) {
            // Slide rule name label with side indicator (matching iPhone styling, larger fonts)
            if let ruleName = selectedRuleDefinition?.name {
                HStack(spacing: 10) {
                    Text(ruleName)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text("•")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(viewMode == .front ? "Front" : (viewMode == .back ? "Back" : "Both"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Current slide rule: \(ruleName), \(viewMode.rawValue) side")
                .accessibilityIdentifier("currentSlideRuleName")
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 44)  // Minimum 44pt tap target (Apple HIG)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())  // Make entire header area tappable
        .onTapGesture {
            // Cycle through available view modes: Front → Back → Both → Front...
            guard availableModes.count > 1 else { return }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                if let currentIndex = availableModes.firstIndex(of: viewMode) {
                    let nextIndex = (currentIndex + 1) % availableModes.count
                    viewMode = availableModes[nextIndex]
                } else {
                    // Fallback: if current mode not in available modes, select first
                    viewMode = availableModes[0]
                }
            }
        }
        .accessibilityHint("Tap to cycle through view modes: Front, Back, Both")
    }
}
