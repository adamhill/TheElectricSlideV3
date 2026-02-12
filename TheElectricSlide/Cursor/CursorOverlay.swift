//
//  CursorOverlay.swift
//  TheElectricSlide
//
//  Overlay container with gesture handling for glass cursor
//
//  Phase 7 Cleanup: Removed callback prop drilling - all gestures now use
//  @Environment(\.gestureHandler). No more legacy callback properties.
//

import SwiftUI
import SlideRuleCoreV3

/// Custom modifier for cursor positioning without animation
struct CursorPositionModifier: ViewModifier {
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .animation(nil, value: offset)  // Explicitly disable animation
    }
}

struct CursorOverlay: View {
    // MARK: - Properties
    
    @Environment(\.hapticService) private var haptics
    @Environment(\.precisionCoordinator) private var precisionCoordinator
    @Environment(\.gestureHandler) private var gestureHandler
    @Environment(\.slideRuleViewModel) private var viewModel
    @Environment(\.cursorState) private var cursorState  // Non-optional with default instance
    @Environment(\.dimensions) private var dimensions
    
    /// Total available height (totalScaleHeight for this side — NOT from Dimensions)
    let height: CGFloat
    
    /// Which side this overlay is for
    let side: RuleSide?
    
    /// Display configuration for scale readings
    var displayConfig: CursorReadingDisplayConfig = .large
    
    /// Whether to show scale readings (names and values)
    var showReadings: Bool = true
    
    /// Whether to show gradient backgrounds
    var showGradients: Bool = true
    
    /// Current zoom scale for display on cursor handle
    var currentZoomScale: CGFloat = 1.0
    
    /// Current manufacturer (for precision mode gradient color selection)
    var manufacturer: SlideRuleManufacturer? = nil
    
    /// Color scheme for precision mode colors (centralized source of truth)
    var colorScheme: SlideRuleColorScheme? = nil
    
    /// Binding to cursor display mode for toggle on double-tap
    @Binding var cursorDisplayMode: CursorDisplayMode
    
    /// Currently highlighted scale index during precision mode
    @State private var highlightedScaleIndex: Int? = nil
    
    // MARK: - Precision Mode State
    
    /// Whether precision (slow-move) mode is active - using @GestureState for automatic reset
    @GestureState private var isPrecisionDragging: Bool = false
    
    // NOTE: Other precision state (isPrecisionSequenceActive, sessionID, lastAppliedTranslation)
    // now managed by PrecisionDragCoordinator via @Environment(\.precisionCoordinator)
    
    // MARK: - Computed Properties for Gesture Control
    
    /// Whether cursor drag gestures should be enabled.
    /// Disables drags during active magnification/pinch-zoom to prevent unintentional
    /// cursor movements when fingers spread across the cursor component.
    ///
    /// ## Apple Best Practice: gesture(_:isEnabled:)
    /// Per Apple Documentation ("simultaneousGesture(_:isEnabled:)"):
    /// "You can also use the `isEnabled` parameter to conditionally disable the gesture."
    /// This is the recommended approach for dynamically enabling/disabling gestures.
    private var isCursorDragEnabled: Bool {
        // Disable when magnification (pinch-zoom) or flick gesture is active
        !(viewModel?.isMagnifying ?? false) && !(viewModel?.isFlipping ?? false)
    }
    
    // MARK: - Body
    
    var body: some View {
        // Create a container that matches the scale drawing area exactly
        HStack(spacing: 0) {
            // Left margin spacer (matches ScaleView left margin + spacing)
            Color.clear
                .frame(width: CursorCoordinateSystem.cursorMarginSpacerWidth(marginWidth: dimensions.leftMarginWidth))
            
            // Cursor interactive area - matches scale width exactly
            VStack(spacing: 0) {
                let effectiveWidth = dimensions.width  // Use dimensions scale width
                let basePosition = cursorState.position(for: side) * effectiveWidth
                
                // CursorView reads currentReadings internally to isolate Observable dependency
                // This prevents CursorOverlay.body from being invalidated on reading changes
                CursorView(
                    height: height,
                    cursorState: cursorState,  // Pass state, let CursorView read readings
                    side: side,
                    displayConfig: displayConfig,
                    showReadings: showReadings,
                    showGradients: showGradients,
                    zoomScale: currentZoomScale,
                    cursorDisplayMode: $cursorDisplayMode,
                    highlightedScaleIndex: highlightedScaleIndex,
                    isPrecisionActive: precisionCoordinator.activeTarget == .cursor,
                    manufacturer: manufacturer,
                    colorScheme: colorScheme
                )
                    .frame(width: CursorView.cursorWidth, alignment: .top)
                    .offset(y: -CursorView.handleHeight)
                    .modifier(CursorPositionModifier(offset: basePosition + cursorState.activeDragOffset))
                    .frame(width: effectiveWidth, height: height, alignment: .topLeading)
                .onTapGesture(count: 3) {
                    // Triple-tap to reset zoom to 1.0×
                    gestureHandler?.handleResetZoom()
                }
                // MARK: Normal Cursor Drag Gesture
                // Standard horizontal drag for cursor movement.
                // Disabled during:
                // 1. Active magnification (pinch-zoom) - prevents unintentional cursor when fingers spread
                // 2. Active precision sequence - defers to the long-press + drag gesture
                //
                // ## Apple Best Practice: gesture(_:isEnabled:)
                // Uses the isEnabled parameter per Apple's "gesture(_:isEnabled:)" documentation
                // to conditionally disable based on isCursorDragEnabled computed property.
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { gesture in
                            // Block if precision sequence is active for cursor
                            guard precisionCoordinator.activeTarget != .cursor else {
                                #if DEBUG
                                print("⚠️ [NormalDrag.onChanged] BLOCKED - precision sequence active")
                                #endif
                                return
                            }
                            
                            // Check if this gesture would be a micro-movement (stale event)
                            let proposedNormalizedDelta = abs(gesture.translation.width) / effectiveWidth
                            if proposedNormalizedDelta < PrecisionDragConstants.minimumMovementThreshold {
                                #if DEBUG
                                print("⚠️ [NormalDrag.onChanged] IGNORED - below threshold (\(String(format: "%.6f", proposedNormalizedDelta)) < \(PrecisionDragConstants.minimumMovementThreshold))")
                                #endif
                                return
                            }
                            
                            #if DEBUG
                            print("📍 [NormalDrag.onChanged] ALLOWED - translation=\(String(format: "%.2f", gesture.translation.width))")
                            #endif
                            gestureHandler?.handleCursorPositionDragChanged(
                                gesture,
                                effectiveWidth: effectiveWidth,
                                currentZoomScale: currentZoomScale,
                                side: side,
                                isPrecision: false
                            )
                        }
                        .onEnded { gesture in
                            // Block if precision sequence is active for cursor
                            guard precisionCoordinator.activeTarget != .cursor else {
                                #if DEBUG
                                print("⚠️ [NormalDrag.onEnded] BLOCKED - precision sequence active")
                                #endif
                                return
                            }
                            
                            // Check if this gesture would be a micro-movement (stale event)
                            let proposedNormalizedDelta = abs(gesture.translation.width) / effectiveWidth
                            if proposedNormalizedDelta < PrecisionDragConstants.minimumMovementThreshold {
                                #if DEBUG
                                print("⚠️ [NormalDrag.onEnded] IGNORED - below threshold (\(String(format: "%.6f", proposedNormalizedDelta)) < \(PrecisionDragConstants.minimumMovementThreshold))")
                                #endif
                                return
                            }
                            
                            #if DEBUG
                            print("📍 [NormalDrag.onEnded] ALLOWED - translation=\(String(format: "%.2f", gesture.translation.width))")
                            #endif
                            gestureHandler?.handleCursorPositionDragEnded(
                                gesture,
                                effectiveWidth: effectiveWidth,
                                currentZoomScale: currentZoomScale,
                                side: side,
                                isPrecision: false
                            )
                        },
                    isEnabled: isCursorDragEnabled  // Disables during pinch-zoom to prevent gesture conflict
                )
                // MARK: Precision Cursor Drag Gesture (Long-press + Drag)
                // Allows fine-grained cursor positioning with reduced sensitivity.
                // Also disabled during magnification to prevent conflicts.
                .simultaneousGesture(
                                    // Use same long press duration on all platforms to prevent accidental activation
                                    // macOS: Previously 0.2s caused normal cursor drags to trigger precision mode
                                    // Now: 1.0s matches iOS and requires intentional long press
                                    LongPressGesture(minimumDuration: PrecisionDragConstants.longPressMinimumDuration)
                        .onEnded { _ in
                            // Enter precision sequence with haptic feedback via coordinator
                            precisionCoordinator.activate(for: .cursor, startPosition: cursorState.position(for: side))
                            haptics.fire(.longBuzz)
                            #if DEBUG
                            print("🎯 [Cursor.Precision] MODE ACTIVATED via PrecisionDragCoordinator")
                            #endif
                        }
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .updating($isPrecisionDragging) { value, state, _ in
                            // Track active drag state via @GestureState (auto-resets on gesture end)
                            if case .second(true, _) = value {
                                state = true
                            }
                        }
                        .onChanged { value in
                            // Handle the sequenced gesture phases
                            switch value {
                            case .first(true):
                                // Long press recognized but drag not started yet
                                #if DEBUG
                                print("🎯 [Cursor.Precision.onChanged] .first(true) - long press in progress")
                                #endif
                                break
                            case .second(true, let drag):
                                // Now in precision drag mode
                                if let drag = drag {
                                    // Calculate highlighted scale index
                                    // Use readings count from cursorState
                                    let readingsCount = side == .front 
                                        ? cursorState.currentReadings?.frontReadings.count ?? 0
                                        : cursorState.currentReadings?.backReadings.count ?? 0
                                    let index = Int(floor(drag.location.y / dimensions.scaleHeight))
                                    if index >= 0 && index < readingsCount {
                                        highlightedScaleIndex = index
                                    } else {
                                        highlightedScaleIndex = nil
                                    }
                                    
                                    // Store the translation via coordinator (for use in onEnded)
                                    precisionCoordinator.recordTranslation(drag.translation)
                                    #if DEBUG
                                    print("🎯 [Cursor.Precision.onChanged] .second - dragging, translation=\(String(format: "%.2f", drag.translation.width))")
                                    #endif
                                    gestureHandler?.handleCursorPositionDragChanged(
                                        drag,
                                        effectiveWidth: effectiveWidth,
                                        currentZoomScale: currentZoomScale,
                                        side: side,
                                        isPrecision: true
                                    )
                                }
                            default:
                                #if DEBUG
                                print("🎯 [Cursor.Precision.onChanged] default case")
                                #endif
                                break
                            }
                        }
                        .onEnded { value in
                            #if DEBUG
                            print("🎯 [Cursor.Precision.onEnded] START")
                            #endif
                            
                            // Commit position using the LAST APPLIED translation from coordinator
                            // This prevents "finger lift jitter" where onEnded has different translation than last onChanged
                            if case .second(true, _) = value {
                                let lastApplied = precisionCoordinator.lastTranslationWidth
                                #if DEBUG
                                print("🎯 [Cursor.Precision.onEnded] Using coordinator's last applied translation=\(String(format: "%.2f", lastApplied))")
                                #endif
                                // Delegate to GestureHandler for precision drag end
                                // (handles position commit, state cleanup, and haptic reset)
                                gestureHandler?.handleCursorPrecisionDragEnded(
                                    lastAppliedTranslation: lastApplied,
                                    effectiveWidth: effectiveWidth,
                                    side: side
                                )
                            } else {
                                #if DEBUG
                                print("🎯 [Cursor.Precision.onEnded] No drag to commit (long press only, no movement)")
                                #endif
                                cursorState.setCursorDragging(false)
                                withTransaction(Transaction(animation: nil)) {
                                    cursorState.activeDragOffset = 0
                                }
                            }
                            
                            #if DEBUG
                            let finalPosition = cursorState.position(for: side)
                            print("🎯 [Cursor.Precision.onEnded] Final position=\(String(format: "%.6f", finalPosition))")
                            #endif
                            
                            // Reset touch position and highlight
                            highlightedScaleIndex = nil
                            
                            // Deactivate precision mode via coordinator (handles cooldown internally)
                            precisionCoordinator.deactivate()
                            #if DEBUG
                            print("🎯 [Cursor.Precision] DEACTIVATED via PrecisionDragCoordinator")
                            #endif
                        },
                    isEnabled: isCursorDragEnabled  // Disables during pinch-zoom to prevent gesture conflict
                )
            }
            .frame(width: dimensions.width)  // Constrain to scale width
            
            // Right margin spacer (matches ScaleView right margin + spacing)
            Color.clear
                .frame(width: CursorCoordinateSystem.cursorMarginSpacerWidth(marginWidth: dimensions.rightMarginWidth))
        }
        .frame(height: height)
        .allowsHitTesting(cursorState.isEnabled)
    }
    // NOTE: Cursor gesture math (handleDrag, handleDragEnd, handlePrecisionDragEnd)
    // moved to GestureHandler in Phase 8. CursorOverlay now delegates all cursor
    // position calculations to gestureHandler?.handleCursorPositionDrag* methods.
}

// MARK: - Preview

#Preview {
    let state = CursorState()
    
    CursorOverlay(
        height: 200,
        side: .front,
        cursorDisplayMode: .constant(.values)
    )
    .environment(\.cursorState, state)
    .environment(\.dimensions, .default)
    .background(Color.gray.opacity(0.2))
    .frame(width: 800, height: 200)
}
