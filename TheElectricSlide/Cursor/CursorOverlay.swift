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
    
    // MARK: - Constants
    
    /// Left offset to align with scale rendering area (matches ScaleView label width)
    private let leftLabelOffset: CGFloat = 28
    
    /// Right offset for formula label area
    private let rightFormulaOffset: CGFloat = 40
    
    /// Cursor width (must match CursorView width)
    private let cursorWidth: CGFloat = 108
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let effectiveWidth = geometry.size.width - leftLabelOffset - rightFormulaOffset
            let basePosition = cursorState.position(for: side) * effectiveWidth
            let currentOffset = basePosition + cursorState.activeDragOffset
            
            // Use offset instead of HStack for smoother updates
            CursorView(height: height)
                .frame(width: cursorWidth, height: height)
                .modifier(CursorPositionModifier(offset: currentOffset))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { gesture in
                            // Update shared drag offset during gesture
                            // Note: Readings are NOT updated here for performance (would recalculate 20+ values per frame)
                            // Readings update only on drag end via setPosition()
                            withTransaction(Transaction(animation: nil)) {
                                cursorState.activeDragOffset = gesture.translation.width
                            }
                        }
                        .onEnded { gesture in
                            handleDragEnd(gesture, width: effectiveWidth)
                            withTransaction(Transaction(animation: nil)) {
                                cursorState.activeDragOffset = 0  // Reset drag offset
                            }
                        }
                )
                .padding(.leading, leftLabelOffset)
        }
        .frame(height: height)
        .allowsHitTesting(cursorState.isEnabled)
    }
    
    // MARK: - Gesture Handlers
    
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
        side: .front
    )
    .background(Color.gray.opacity(0.2))
    .frame(width: 800, height: 200)
}