//
//  CursorOverlay.swift
//  TheElectricSlide
//
//  Overlay container with gesture handling for glass cursor
//
//  Phase 4 Bold Refactor: Added @Environment(\.gestureHandler) support
//  Tick haptic callbacks now prefer gestureHandler, fall back to callbacks.
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
    
    /// Triple-tap callback to reset zoom to 1.0× (legacy callback, prefer gestureHandler)
    var onResetZoom: (() -> Void)? = nil
    
    /// Current zoom scale for display on cursor handle
    var currentZoomScale: CGFloat = 1.0
    
    /// Binding to cursor display mode for toggle on double-tap
    @Binding var cursorDisplayMode: CursorDisplayMode
    
    // MARK: - Legacy Callbacks (for backward compatibility, prefer gestureHandler)
    
    /// Callback for tick haptics during cursor drag (passes normalized cursor position)
    /// Called during drag so parent can trigger tick crossing haptics.
    /// Phase 4: Prefer gestureHandler.handleCursorDragChanged() when available.
    var onCursorDragChanged: ((CGFloat) -> Void)? = nil
    
    /// Callback when cursor drag ends (for resetting tick haptic coordinator)
    /// Phase 4: Prefer gestureHandler.handleCursorDragEnded() when available.
    var onCursorDragEnded: (() -> Void)? = nil
    // MARK: - Precision Mode State
    
    /// Whether precision (slow-move) mode is active - using @GestureState for automatic reset
    @GestureState private var isPrecisionDragging: Bool = false
    
    // NOTE: Other precision state (isPrecisionSequenceActive, sessionID, lastAppliedTranslation)
    // now managed by PrecisionDragCoordinator via @Environment(\.precisionCoordinator)
    
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
                    cursorDisplayMode: $cursorDisplayMode
                )
                    .frame(width: CursorView.cursorWidth, alignment: .top)
                    .offset(y: -CursorView.handleHeight)
                    .modifier(CursorPositionModifier(offset: basePosition + cursorState.activeDragOffset))
                    .frame(width: effectiveWidth, height: height, alignment: .topLeading)
                .onTapGesture(count: 3) {
                    // Triple-tap to reset zoom to 1.0×
                    // Phase 4: Prefer gestureHandler, fall back to callback
                    if let handler = gestureHandler {
                        handler.handleResetZoom()
                    } else {
                        onResetZoom?()
                    }
                }
                // Normal drag gesture for standard cursor movement
                // Suppressed when precision sequence is active for cursor
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
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
                        }
                )
                // Long-press sequenced with drag for precision mode (reduced sensitivity)
                // Uses @GestureState for automatic reset and PrecisionDragCoordinator for state
                .simultaneousGesture(
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
                            
                            // Deactivate precision mode via coordinator (handles cooldown internally)
                            precisionCoordinator.deactivate()
                            #if DEBUG
                            print("🎯 [Cursor.Precision] DEACTIVATED via PrecisionDragCoordinator")
                            #endif
                        }
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
        
        // Apply precision factor if in precision mode
        let translationWidth = isPrecision
            ? gesture.translation.width / PrecisionDragConstants.precisionFactor
            : gesture.translation.width
        
        // Calculate what the new position would be with this translation
        let currentPosition = cursorState.position(for: side)
        let currentPixelPosition = currentPosition * effectiveWidth
        let proposedNewPosition = currentPixelPosition + translationWidth
        
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
        
        // Trigger tick haptics
        // Phase 4: Prefer gestureHandler, fall back to callback
        if let handler = gestureHandler {
            handler.handleCursorDragChanged(clampedPosition)
        } else {
            onCursorDragChanged?(clampedPosition)
        }
    }
    
    /// Handle cursor drag end - commit the final position
    /// - Parameters:
    ///   - gesture: The drag gesture value
    ///   - width: Effective width for movement
    ///   - isPrecision: Whether precision mode is active (must match the mode used during drag)
    private func handleDragEnd(_ gesture: DragGesture.Value, width: CGFloat, isPrecision: Bool) {
        // Apply precision factor if in precision mode (must match drag calculation)
        let translationWidth = isPrecision
            ? gesture.translation.width / PrecisionDragConstants.precisionFactor
            : gesture.translation.width
        
        // Calculate new position based on translation from current position
        let currentPosition = cursorState.position(for: side)
        let currentPixelPosition = currentPosition * width
        let newPixelPosition = currentPixelPosition + translationWidth
        let normalizedPosition = newPixelPosition / width
        let clampedPosition = min(max(normalizedPosition, 0.0), 1.0)
        
        // Update immediately without animation to prevent vibration
        // Note: Position stored is for the LEFT EDGE of cursor
        // Reading calculations must add half cursor width to get hairline position
        cursorState.setPosition(clampedPosition, for: side)
        
        // Reset tick haptic coordinator
        // Phase 4: Prefer gestureHandler, fall back to callback
        if let handler = gestureHandler {
            handler.handleCursorDragEnded()
        } else {
            onCursorDragEnded?()
        }
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
        
        // Reset tick haptic coordinator
        // Phase 4: Prefer gestureHandler, fall back to callback
        if let handler = gestureHandler {
            handler.handleCursorDragEnded()
        } else {
            onCursorDragEnded?()
        }
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
