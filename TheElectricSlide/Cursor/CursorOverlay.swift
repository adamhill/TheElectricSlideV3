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
                    showGradients: showGradients
                )
                    .frame(width: CursorView.cursorWidth, alignment: .top)
                    .offset(y: -CursorView.handleHeight)
                    .modifier(CursorPositionModifier(offset: basePosition + cursorState.activeDragOffset))
                    .frame(width: effectiveWidth, height: height, alignment: .topLeading)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { gesture in
                            // Mark cursor as dragging
                            cursorState.setCursorDragging(true)
                            
                            // Calculate what the new position would be with this translation
                            // Position is normalized (0.0-1.0) and represents hairline position
                            let currentPosition = cursorState.position(for: side)
                            let currentPixelPosition = currentPosition * effectiveWidth
                            let proposedNewPosition = currentPixelPosition + gesture.translation.width
                            
                            // Clamp to slide bounds [0, effectiveWidth]
                            let clampedNewPosition = min(max(proposedNewPosition, 0), effectiveWidth)
                            
                            // Calculate the actual translation we can apply (clamped)
                            let clampedTranslation = clampedNewPosition - currentPixelPosition
                            
                            // Update shared drag offset with CLAMPED translation
                            withTransaction(Transaction(animation: nil)) {
                                cursorState.activeDragOffset = clampedTranslation
                            }
                            
                            // Realtime reading updates with modulo 3 throttling
                            // Use the clamped position for reading updates
                            let normalizedPosition = clampedNewPosition / effectiveWidth
                            let clampedPosition = min(max(normalizedPosition, 0.0), 1.0)
                            
                            // Update readings at current drag position
                            // Note: Modulo 3 throttling is handled internally by updateReadings()
                            cursorState.updateReadings(at: clampedPosition)
                        }
                        .onEnded { gesture in
                            handleDragEnd(gesture, width: effectiveWidth)
                            
                            // Mark cursor drag as ended
                            cursorState.setCursorDragging(false)
                            
                            withTransaction(Transaction(animation: nil)) {
                                cursorState.activeDragOffset = 0  // Reset drag offset
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
    
    /// Handle cursor drag end - commit the final position
    /// - Parameters:
    ///   - gesture: The drag gesture value
    ///   - width: Effective width for movement
    private func handleDragEnd(_ gesture: DragGesture.Value, width: CGFloat) {
        // Calculate new position based on translation from current position
        let currentPosition = cursorState.position(for: side)
        let currentPixelPosition = currentPosition * width
        let newPixelPosition = currentPixelPosition + gesture.translation.width
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
    
    return CursorOverlay(
        cursorState: state,
        width: 800,
        height: 200,
        side: .front,
        scaleHeight: 25,
        leftMarginWidth: 64,
        rightMarginWidth: 64
    )
    .background(Color.gray.opacity(0.2))
    .frame(width: 800, height: 200)
}
