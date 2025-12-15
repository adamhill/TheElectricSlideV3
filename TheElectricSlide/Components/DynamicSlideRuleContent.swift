//
//  DynamicSlideRuleContent.swift
//  TheElectricSlide
//
//  Extracted from ContentView.swift
//
//  Phase 7 Cleanup: Removed gesture callbacks - all gestures now handled via
//  @Environment(\.gestureHandler) in child views (SideView, CursorOverlay, StatorView).
//

import SwiftUI
import SwiftData
import SlideRuleCoreV3

// MARK: - Pan Position Modifier

/// Custom modifier for pan positioning using GPU-level transform
/// Uses CGAffineTransform instead of .offset() to avoid coordinate space disruption
/// during gesture tracking. .offset() goes through SwiftUI's layout system which can
/// cause gesture tracking to switch between pre/post-offset coordinate spaces.
struct PanPositionModifier: ViewModifier {
    let offset: CGSize
    
    func body(content: Content) -> some View {
        #if DEBUG
        let _ = print("🟤 [PanJitter] Render-Offset: " +
              "offset=(\(String(format: "%.2f", offset.width)), \(String(format: "%.2f", offset.height)))")
        #endif
        content
            .transformEffect(CGAffineTransform(translationX: offset.width, y: offset.height))
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
    @Binding var cursorDisplayMode: CursorDisplayMode
    @Binding var cursorReadingCycleMode: CursorReadingCycleMode
    let currentZoomScale: CGFloat  // Current zoom level for pan gesture control
    @Binding var panOffset: CGSize // Pan offset for moving zoomed content
    let totalScaleHeight: (RuleSide) -> CGFloat
    let selectedRuleDefinition: SlideRuleDefinitionModel?  // For displaying rule name
    let deviceCategory: DeviceCategory  // For layout decisions
    
    // MARK: - Stable Dimensions (debounced to avoid intermediate animation values)
    // The system animates geometry changes through intermediate widths (e.g., 876→856→836→816→796)
    // We use stableDimensions to only render with the final settled value
    @State private var stableDimensions: Dimensions?
    @State private var dimensionUpdateTask: Task<Void, Never>?
    
    // MARK: - Sidebar-Aware Dimension Tracking
    // Track the "baseline" width (without sidebar overlay) to detect sidebar-only changes
    // This prevents content shifting when the sidebar appears/disappears
    @State private var baselineWidth: CGFloat?
    
    /// The dimensions to use for rendering - uses stable (debounced) value if available
    private var renderDimensions: Dimensions {
        stableDimensions ?? calculatedDimensions
    }
    
    /// Calculate total scale height using renderDimensions for consistency with cursor overlay
    /// This ensures the cursor height matches the actual rendered scale row heights
    private func consistentTotalScaleHeight(for side: RuleSide) -> CGFloat {
        let scaleCount: Int
        switch side {
        case .front:
            scaleCount = slideRule.frontTopStator.scales.count +
                         slideRule.frontSlide.scales.count +
                         slideRule.frontBottomStator.scales.count
        case .back:
            guard let backTop = slideRule.backTopStator,
                  let backSlide = slideRule.backSlide,
                  let backBottom = slideRule.backBottomStator else {
                return 0
            }
            scaleCount = backTop.scales.count +
                         backSlide.scales.count +
                         backBottom.scales.count
        }
        return CGFloat(scaleCount) * renderDimensions.scaleHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Consolidated cursor readings display - centered under title
            // Shows readings based on cycle mode with tap-to-cycle gesture
            VStack(spacing: 2) {
                // Rule name and side indicator (always shown on compact devices, larger fonts)
                if !deviceCategory.supportsMultiSideView, let ruleName = selectedRuleDefinition?.name {
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .accessibilityLabel("Current slide rule: \(ruleName), \(viewMode.rawValue) side")
                    .accessibilityIdentifier("slideRuleNameHeader_\(viewMode.rawValue.lowercased())")
                }
                
                // Cursor readings with tap-to-cycle - uses reusable CursorReadingsContainer
                // IMPORTANT: This view remains fixed scale (zoom only affects slide rule below)
                CursorReadingsContainer(
                    viewMode: viewMode,
                    cursorReadingCycleMode: $cursorReadingCycleMode,
                    currentReadings: cursorState.currentReadings,
                    hasBackSide: slideRule.backTopStator != nil
                )
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
                        ruleId: ruleId,
                        currentZoomScale: currentZoomScale
                    )
                    .equatable()
                    .id("front-\(ruleId?.uuidString ?? "default")")  // Force view recreation on rule change
                    // Disable animation on geometry/dimension changes to prevent intermediate width values
                    .animation(nil, value: renderDimensions.width)
                    .overlay {
                        CursorOverlay(
                            cursorState: cursorState,
                            width: renderDimensions.width,
                            height: consistentTotalScaleHeight(for: .front),
                            side: .front,
                            scaleHeight: renderDimensions.scaleHeight,
                            leftMarginWidth: renderDimensions.leftMarginWidth,
                            rightMarginWidth: renderDimensions.rightMarginWidth,
                            showReadings: cursorDisplayMode.showReadings,
                            showGradients: cursorDisplayMode.showGradients,
                            currentZoomScale: currentZoomScale,
                            cursorDisplayMode: $cursorDisplayMode
                        )
                    }
                }
                // APPLY ZOOM AND PAN ONLY TO SLIDE RULE CONTENT
                .modifier(PanPositionModifier(offset: panOffset))
                .scaleEffect(currentZoomScale, anchor: .top)
                #if os(iOS)
                // Phase 5: Flip transition animation for compact devices (iPhone/Watch/iPad)
                // Creates a natural vertical flip effect when switching sides
                // - New view slides up from the bottom with fade-in
                // - Old view slides up to the top with fade-out
                // Animation is triggered by FlipButton's spring animation (response: 0.3s, damping: 0.8)
                // NOTE: Disabled on macOS where these transitions feel unnatural
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                #endif
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
                        ruleId: ruleId,
                        currentZoomScale: currentZoomScale
                    )
                    .equatable()
                    .id("back-\(ruleId?.uuidString ?? "default")")  // Force view recreation on rule change
                    // Disable animation on geometry/dimension changes to prevent intermediate width values
                    .animation(nil, value: renderDimensions.width)
                    .overlay {
                        CursorOverlay(
                            cursorState: cursorState,
                            width: renderDimensions.width,
                            height: consistentTotalScaleHeight(for: .back),
                            side: .back,
                            scaleHeight: renderDimensions.scaleHeight,
                            leftMarginWidth: renderDimensions.leftMarginWidth,
                            rightMarginWidth: renderDimensions.rightMarginWidth,
                            showReadings: cursorDisplayMode.showReadings,
                            showGradients: cursorDisplayMode.showGradients,
                            currentZoomScale: currentZoomScale,
                            cursorDisplayMode: $cursorDisplayMode
                        )
                    }
                }
                // APPLY ZOOM AND PAN ONLY TO SLIDE RULE CONTENT
                .modifier(PanPositionModifier(offset: panOffset))
                .scaleEffect(currentZoomScale, anchor: .top)
                #if os(iOS)
                // Phase 5: Flip transition animation for compact devices (iPhone/Watch/iPad)
                // Creates a natural vertical flip effect when switching sides
                // - New view slides up from the bottom with fade-in
                // - Old view slides up to the top with fade-out
                // Animation is triggered by FlipButton's spring animation (response: 0.3s, damping: 0.8)
                // NOTE: Disabled on macOS where these transitions feel unnatural
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                #endif
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
        // MARK: - Dimension Debounce Logic with Sidebar-Awareness
        // The system animates geometry changes through intermediate widths during orientation changes
        // (e.g., 876→856→836→816→796). We debounce updates to only render with the final settled value.
        //
        // Additionally, with prominentDetail NavigationSplitView style, the sidebar overlays content.
        // When sidebar appears/disappears, the geometry proxy may report width changes even though
        // the content should stay fixed beneath. We track a "baseline" width and ignore changes that
        // match typical sidebar width deltas (250-400pt on macOS).
        .onChange(of: calculatedDimensions.width) { oldWidth, newWidth in
            // Cancel any pending update
            dimensionUpdateTask?.cancel()
            
            // MARK: - Sidebar Width Change Detection
            // On macOS with prominentDetail style, sidebar overlays content.
            // Typical sidebar widths are 250-400pt. If the width change is approximately
            // this size, it's likely just the sidebar appearing/disappearing, not a real resize.
            #if os(macOS)
            let widthDelta = abs(newWidth - oldWidth)
            let isSidebarWidthChange = widthDelta >= 200 && widthDelta <= 450
            
            // If we have a baseline and the change matches sidebar width, ignore it
            if let baseline = baselineWidth, isSidebarWidthChange {
                // Check if we're returning close to baseline (sidebar hiding)
                let isReturningToBaseline = abs(newWidth - baseline) < 50
                // Check if we're moving away from baseline by sidebar width (sidebar showing)
                let isShowingSidebar = abs((oldWidth - widthDelta) - newWidth) < 50 ||
                                       abs((oldWidth + widthDelta) - newWidth) < 50
                
                if isReturningToBaseline || isShowingSidebar {
                    #if DEBUG
                    print("📐 [DynamicSlideRuleContent] Ignoring sidebar width change: \(oldWidth) → \(newWidth) (delta: \(widthDelta))")
                    #endif
                    // Don't update dimensions - keep stable dimensions at baseline-derived value
                    return
                }
            }
            
            // If we don't have a baseline yet or this is a real resize, update baseline
            // Use the larger width as baseline (represents full window without sidebar)
            if baselineWidth == nil || newWidth > (baselineWidth ?? 0) {
                baselineWidth = max(oldWidth, newWidth)
            }
            #endif
            
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
            // Initialize baseline width for sidebar detection
            baselineWidth = calculatedDimensions.width
        }
        .onChange(of: sliderOffset) {
            cursorState.updateReadings()
        }
    }
}
