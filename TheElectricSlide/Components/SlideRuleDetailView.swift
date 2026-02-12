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
    
    // Manufacturer colorway support
    let useManufacturerColors: Bool
    let colorScheme: SlideRuleColorScheme?
    
    var body: some View {
        VStack(spacing: 0) {
            // NOTE: Header with rule name and view mode is now ONLY in safeAreaInset(edge: .top)
            // to avoid duplication. Previously had duplicate header here for iPad/Mac.
            
            // Dynamic content - responds to sliderOffset and zoom
            DynamicSlideRuleContent(
                viewMode: viewMode,
                slideRule: currentSlideRule,
                ruleId: ruleId,
                calculatedDimensions: calculatedDimensions,
                cursorDisplayMode: $cursorDisplayMode,
                cursorReadingCycleMode: $cursorReadingCycleMode,
                currentZoomScale: currentZoomScale,
                totalScaleHeight: totalScaleHeight,
                selectedRuleDefinition: selectedRuleDefinition,
                deviceCategory: deviceCategory,
                useManufacturerColors: useManufacturerColors,
                colorScheme: colorScheme
            )
            // Inject rule-level display settings into environment for ScaleView to use
            .environment(\.ruleDisplaySettings, currentSlideRule.displaySettings)
            .modifier(PanPositionModifier(offset: panOffset))  // Use custom modifier for jitter-free pan
            .scaleEffect(currentZoomScale, anchor: .top)  // Scale from top to prevent vertical shift
            // NOTE: .drawingGroup() intentionally NOT applied here (Jan 2025, Issue #115)
            // Reason: .drawingGroup() rasterizes content at pre-zoom size, creating a fixed Metal buffer.
            // In Front/Back mode (single side), the smaller content height = smaller buffer = clipping when panned.
            // In Both mode (2 sides + spacer), taller content = larger buffer = no clipping.
            // Fix: Remove .drawingGroup() at this level. Individual ScaleView components use .drawingGroup()
            // for Canvas tick rendering performance (see ScaleView.swift).
            // Performance: Acceptable per Instruments testing (some hitches, large parameterList in Update).
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
            // MARK: - Anchored Header (safeAreaInset)
            // Uses safeAreaInset to keep header fixed at top during view mode transitions.
            // The header is layout-independent: content height changes don't affect header position.
            // Shows on ALL devices (iPhone, iPad, Mac) - iPhone also keeps FlipButton overlay.
            // spacing: 16 ensures slide rule content doesn't clip under cursor readings at default zoom
            .safeAreaInset(edge: .top, spacing: 16) {
                combinedPickersSection
                    .background(systemBackgroundColor())
                // Bottom border separator using overlay instead of Divider
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color(white: 0.5, opacity: 0.3))
                            .frame(height: 1)
                    }
            }
            .overlay(alignment: .bottomLeading) {
                // Floating flip button for compact devices (iPhone, Apple Watch)
                // Positioned at bottom-left, horizontally aligned under NavigationView's disclosure widget
                if !deviceCategory.supportsMultiSideView && currentSlideRule.backTopStator != nil {
                    FlipButton(viewMode: $viewMode)
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                }
            }
            // CRITICAL: Pin content to top of NavigationSplitView detail pane
            // Without this, detail pane centers content vertically, causing header to shift
            // when slide rule height changes during mode transitions (Both/Front/Back)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    @ViewBuilder
    private var combinedPickersSection: some View {
        let availableModes = ViewMode.availableModes(for: deviceCategory).filter { mode in
            mode == .front || (currentSlideRule.backTopStator != nil)
        }
        VStack(spacing: 4) {
            // Row 1: Rule name and side indicator
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
            .contentShape(Rectangle())
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
            
            // Row 2: Cursor readings display
            CursorReadingsContainer(
                viewMode: viewMode,
                cursorReadingCycleMode: $cursorReadingCycleMode,
                currentReadings: cursorState.currentReadings,
                hasBackSide: currentSlideRule.backTopStator != nil
            )
            .equatable()
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
