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
                
                // Cursor readings with tap-to-cycle - uses reusable CursorReadingsContainer
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
}
