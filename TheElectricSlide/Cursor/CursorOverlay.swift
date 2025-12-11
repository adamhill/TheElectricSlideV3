//
//  CursorOverlay.swift
//  TheElectricSlide
//
//  Overlay container with gesture handling for glass cursor
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
    
    /// Triple-tap callback to reset zoom to 1.0×
    var onResetZoom: (() -> Void)? = nil
    
    /// Current zoom scale for display on cursor handle
    var currentZoomScale: CGFloat = 1.0
    
    /// Binding to cursor display mode for toggle on double-tap
    @Binding var cursorDisplayMode: CursorDisplayMode
    
    // MARK: - Precision Mode State
    
    /// Whether precision (slow-move) mode is active
    @State private var isPrecisionMode: Bool = false
    
    /// Cooldown period after precision mode ends to prevent normal gesture interference
    @State private var isPrecisionCooldown: Bool = false
    
    // MARK: - Precision Mode Constants (tweak these values)
    
    /// Long press duration required to activate precision mode (seconds)
    private static let longPressMinimumDuration: TimeInterval = 1.0
    
    /// Precision mode reduces drag sensitivity by this factor
    private static let precisionFactor: CGFloat = 4.0
    
    /// Cooldown duration after precision mode ends (seconds)
    private static let precisionCooldownDuration: TimeInterval = 0.75
    
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
                    onResetZoom?()
                }
                // Normal drag gesture for standard cursor movement
                // Suppressed during precision mode and cooldown period
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { gesture in
                            #if DEBUG
                            if isPrecisionMode || isPrecisionCooldown {
                                print("⚠️ [NormalDrag.onChanged] BLOCKED - precisionMode=\(isPrecisionMode), cooldown=\(isPrecisionCooldown), translation=\(String(format: "%.2f", gesture.translation.width))")
                            }
                            #endif
                            // Skip if in precision mode or cooldown
                            guard !isPrecisionMode && !isPrecisionCooldown else { return }
                            #if DEBUG
                            print("📍 [NormalDrag.onChanged] ALLOWED - translation=\(String(format: "%.2f", gesture.translation.width))")
                            #endif
                            handleDrag(gesture, effectiveWidth: effectiveWidth, isPrecision: false)
                        }
                        .onEnded { gesture in
                            #if DEBUG
                            if isPrecisionMode || isPrecisionCooldown {
                                print("⚠️ [NormalDrag.onEnded] BLOCKED - precisionMode=\(isPrecisionMode), cooldown=\(isPrecisionCooldown), translation=\(String(format: "%.2f", gesture.translation.width))")
                            }
                            #endif
                            // Skip if in precision mode or cooldown
                            guard !isPrecisionMode && !isPrecisionCooldown else { return }
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
                // Long-press sequenced with drag for precision mode (4x slower)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: Self.longPressMinimumDuration)
                        .onEnded { _ in
                            // Enter precision mode with haptic feedback
                            isPrecisionMode = true
                            HapticManager.longBuzz()
                            #if DEBUG
                            print("🎯 [Precision] MODE ACTIVATED - longPress completed")
                            #endif
                        }
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onChanged { value in
                            // Handle the sequenced gesture phases
                            switch value {
                            case .first(true):
                                // Long press recognized but drag not started yet
                                #if DEBUG
                                print("🎯 [Precision.onChanged] .first(true) - long press in progress")
                                #endif
                                break
                            case .second(true, let drag):
                                // Now in precision drag mode
                                if let drag = drag {
                                    #if DEBUG
                                    print("🎯 [Precision.onChanged] .second - dragging, translation=\(String(format: "%.2f", drag.translation.width))")
                                    #endif
                                    handleDrag(drag, effectiveWidth: effectiveWidth, isPrecision: true)
                                }
                            default:
                                #if DEBUG
                                print("🎯 [Precision.onChanged] default case")
                                #endif
                                break
                            }
                        }
                        .onEnded { value in
                            #if DEBUG
                            print("🎯 [Precision.onEnded] START - value=\(value)")
                            #endif
                            
                            // Commit position if we were dragging
                            if case .second(true, let drag) = value, let drag = drag {
                                #if DEBUG
                                print("🎯 [Precision.onEnded] Committing position, translation=\(String(format: "%.2f", drag.translation.width))")
                                #endif
                                handleDragEnd(drag, width: effectiveWidth, isPrecision: true)
                            } else {
                                #if DEBUG
                                print("🎯 [Precision.onEnded] No drag to commit (long press only, no movement)")
                                #endif
                            }
                            
                            cursorState.setCursorDragging(false)
                            withTransaction(Transaction(animation: nil)) {
                                cursorState.activeDragOffset = 0
                            }
                            
                            // Exit precision mode and enter cooldown to prevent normal gesture interference
                            isPrecisionMode = false
                            isPrecisionCooldown = true
                            
                            #if DEBUG
                            print("🎯 [Precision.onEnded] MODE OFF, COOLDOWN ON (\(Self.precisionCooldownDuration)s)")
                            #endif
                            
                            // Clear cooldown after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + Self.precisionCooldownDuration) {
                                isPrecisionCooldown = false
                                #if DEBUG
                                print("🎯 [Precision] COOLDOWN ENDED")
                                #endif
                            }
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
            ? gesture.translation.width / Self.precisionFactor
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
    }
    
    /// Handle cursor drag end - commit the final position
    /// - Parameters:
    ///   - gesture: The drag gesture value
    ///   - width: Effective width for movement
    ///   - isPrecision: Whether precision mode is active (must match the mode used during drag)
    private func handleDragEnd(_ gesture: DragGesture.Value, width: CGFloat, isPrecision: Bool) {
        // Apply precision factor if in precision mode (must match drag calculation)
        let translationWidth = isPrecision
            ? gesture.translation.width / Self.precisionFactor
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
