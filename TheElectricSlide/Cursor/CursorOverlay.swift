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
    
    /// Shared cursor state
    let cursorState: CursorState
    
    /// Total available width
    let width: CGFloat
    
    /// Total available height
    let height: CGFloat
    
    /// Which side this overlay is for
    let side: RuleSide?
    
    /// Height of each scale (for vertical positioning of readings)
    let scaleHeight: CGFloat
    
    /// Left margin width (from Dimensions) - aligns cursor with scale area
    let leftMarginWidth: CGFloat
    
    /// Right margin width (from Dimensions) - aligns cursor with scale area
    let rightMarginWidth: CGFloat
    
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
                .frame(width: leftMarginWidth + 4)
            
            // Cursor interactive area - matches scale width exactly
            GeometryReader { geometry in
                let effectiveWidth = width  // Use passed scale width directly
                let basePosition = cursorState.position(for: side) * effectiveWidth
                
                // Get current readings for this side
                let readings = getReadingsForSide()
                CursorView(
                    height: height,
                    readings: readings,
                    scaleHeight: scaleHeight,
                    displayConfig: displayConfig,
                    showReadings: showReadings,
                    showGradients: showGradients,
                    zoomScale: currentZoomScale,
                    cursorDisplayMode: $cursorDisplayMode,
                    highlightedScaleIndex: highlightedScaleIndex,
                    isPrecisionActive: precisionCoordinator.activeTarget == .cursor,
                    manufacturer: manufacturer
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
                            handleDrag(gesture, effectiveWidth: effectiveWidth, isPrecision: false)
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
                            handleDragEnd(gesture, width: effectiveWidth, isPrecision: false)
                            cursorState.setCursorDragging(false)
                            withTransaction(Transaction(animation: nil)) {
                                cursorState.activeDragOffset = 0
                            }
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
                                    let index = Int(floor(drag.location.y / scaleHeight))
                                    let readings = getReadingsForSide()
                                    if index >= 0 && index < readings.count {
                                        highlightedScaleIndex = index
                                    } else {
                                        highlightedScaleIndex = nil
                                    }
                                    
                                    // Store the translation via coordinator (for use in onEnded)
                                    precisionCoordinator.recordTranslation(drag.translation)
                                    #if DEBUG
                                    print("🎯 [Cursor.Precision.onChanged] .second - dragging, translation=\(String(format: "%.2f", drag.translation.width))")
                                    #endif
                                    handleDrag(drag, effectiveWidth: effectiveWidth, isPrecision: true)
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
                                // Create a synthetic position based on last applied translation
                                handlePrecisionDragEnd(lastAppliedTranslation: lastApplied, width: effectiveWidth)
                            } else {
                                #if DEBUG
                                print("🎯 [Cursor.Precision.onEnded] No drag to commit (long press only, no movement)")
                                #endif
                            }
                            
                            cursorState.setCursorDragging(false)
                            withTransaction(Transaction(animation: nil)) {
                                cursorState.activeDragOffset = 0
                            }
                            
                            // Snapshot position before clearing state
                            let finalPosition = cursorState.position(for: side)
                            #if DEBUG
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
            .frame(width: width)  // Constrain to scale width
            
            // Right margin spacer (matches ScaleView right margin + spacing)
            Color.clear
                .frame(width: rightMarginWidth + 4)
        }
        .frame(height: height)
        .allowsHitTesting(cursorState.isEnabled)
    }
    
    // MARK: - Gesture Handlers
    
    /// Get readings array for the current side
    private func getReadingsForSide() -> [ScaleReading] {
        guard let side = side else { return [] }
        
        if side == .front {
            return cursorState.currentReadings?.frontReadings ?? []
        } else {
            return cursorState.currentReadings?.backReadings ?? []
        }
    }
    
    /// Handle cursor drag - supports both normal and precision modes
    /// - Parameters:
    ///   - gesture: The drag gesture value
    ///   - effectiveWidth: Available width for cursor movement
    ///   - isPrecision: Whether precision mode is active (4x slower movement)
    private func handleDrag(_ gesture: DragGesture.Value, effectiveWidth: CGFloat, isPrecision: Bool) {
        // Mark cursor as dragging
        cursorState.setCursorDragging(true)
        
        #if DEBUG && os(macOS)
        print("🐛 [macOS.Cursor.handleDrag] currentZoomScale=\(String(format: "%.4f", currentZoomScale)), isPrecision=\(isPrecision), rawTranslation=\(String(format: "%.2f", gesture.translation.width))")
        #endif
        
        // Use GestureCalculator for zoom/precision correction
        // Handles both zoom scale and precision factor in one call
        let correctedTranslation = GestureCalculator.correctTranslationWidth(
            gesture.translation.width,
            zoomScale: currentZoomScale,
            isPrecision: isPrecision
        )
        
        #if DEBUG && os(macOS)
        print("🐛 [macOS.Cursor.handleDrag] correctedTranslation=\(String(format: "%.2f", correctedTranslation))")
        #endif
        
        // Calculate what the new position would be with this translation
        let currentPosition = cursorState.position(for: side)
        let currentPixelPosition = currentPosition * effectiveWidth
        let proposedNewPosition = currentPixelPosition + correctedTranslation
        
        // Clamp to slide bounds [0, effectiveWidth]
        let clampedNewPosition = min(max(proposedNewPosition, 0), effectiveWidth)
        
        // Calculate the actual translation we can apply (clamped)
        let clampedTranslation = clampedNewPosition - currentPixelPosition
        
        // Update shared drag offset with CLAMPED translation
        withTransaction(Transaction(animation: nil)) {
            cursorState.activeDragOffset = clampedTranslation
        }
        
        // Realtime reading updates
        let normalizedPosition = clampedNewPosition / effectiveWidth
        let clampedPosition = min(max(normalizedPosition, 0.0), 1.0)
        cursorState.updateReadings(at: clampedPosition)
        
        // Trigger tick haptics via gestureHandler
        gestureHandler?.handleCursorDragChanged(clampedPosition)
    }
    
    /// Handle cursor drag end - commit the final position
    /// - Parameters:
    ///   - gesture: The drag gesture value
    ///   - width: Effective width for movement
    ///   - isPrecision: Whether precision mode is active (must match the mode used during drag)
    private func handleDragEnd(_ gesture: DragGesture.Value, width: CGFloat, isPrecision: Bool) {
        // Use GestureCalculator for zoom/precision correction (matches handleDrag)
        let correctedTranslation = GestureCalculator.correctTranslationWidth(
            gesture.translation.width,
            zoomScale: currentZoomScale,
            isPrecision: isPrecision
        )
        
        // Calculate new position based on translation from current position
        let currentPosition = cursorState.position(for: side)
        let currentPixelPosition = currentPosition * width
        let newPixelPosition = currentPixelPosition + correctedTranslation
        let normalizedPosition = newPixelPosition / width
        let clampedPosition = min(max(normalizedPosition, 0.0), 1.0)
        
        // Update immediately without animation to prevent vibration
        // Note: Position stored is for the LEFT EDGE of cursor
        // Reading calculations must add half cursor width to get hairline position
        cursorState.setPosition(clampedPosition, for: side)
        
        // Reset tick haptic coordinator via gestureHandler
        gestureHandler?.handleCursorDragEnded()
    }
    
    /// Handle precision drag end using the LAST APPLIED translation instead of gesture's final value
    /// This prevents "finger lift jitter" where the onEnded translation differs from the last onChanged
    /// - Parameters:
    ///   - lastAppliedTranslation: The raw translation from the last onChanged event (before precision factor)
    ///   - width: Effective width for movement
    private func handlePrecisionDragEnd(lastAppliedTranslation: CGFloat, width: CGFloat) {
        // Apply precision factor (same as during onChanged)
        let translationWidth = lastAppliedTranslation / PrecisionDragConstants.precisionFactor
        
        // Calculate new position based on translation from current position
        let currentPosition = cursorState.position(for: side)
        let currentPixelPosition = currentPosition * width
        let newPixelPosition = currentPixelPosition + translationWidth
        let normalizedPosition = newPixelPosition / width
        let clampedPosition = min(max(normalizedPosition, 0.0), 1.0)
        
        // Update immediately without animation to prevent vibration
        cursorState.setPosition(clampedPosition, for: side)
        
        // Reset tick haptic coordinator via gestureHandler
        gestureHandler?.handleCursorDragEnded()
    }
}

// MARK: - Preview

#Preview {
    let state = CursorState()
    
    CursorOverlay(
        cursorState: state,
        width: 800,
        height: 200,
        side: .front,
        scaleHeight: 25,
        leftMarginWidth: 64,
        rightMarginWidth: 64,
        cursorDisplayMode: .constant(.values)
    )
    .background(Color.gray.opacity(0.2))
    .frame(width: 800, height: 200)
}
