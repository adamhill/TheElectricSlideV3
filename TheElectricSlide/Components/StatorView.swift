//
//  StatorView.swift
//  TheElectricSlide
//
//  Renders multiple scales for a stator (fixed portion of slide rule)
//  Extracted from ContentView.swift for better organization
//
//  Phase 4 Bold Refactor: Added @Environment(\.gestureHandler) support
//  Pan and reset zoom gestures now prefer gestureHandler, fall back to callbacks.
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - StatorView Component (renders multiple scales)

struct StatorView: View, Equatable {
    @Environment(\.gestureHandler) private var gestureHandler
    
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    let cursorState: CursorState? // Reference to cursor state for interaction tracking
    let ruleId: UUID?  // Track rule identity for view updates
    let currentZoomScale: CGFloat  // Current zoom level to enable/disable pan
    
    // MARK: - Legacy Callbacks (for backward compatibility)
    let onPanChanged: ((DragGesture.Value) -> Void)?  // Pan gesture for zoomed content
    let onPanEnded: ((DragGesture.Value) -> Void)?  // Pan gesture end
    let onResetZoom: (() -> Void)?  // Triple-tap to reset zoom to 1.0×
    
    // ✅ Equatable conformance - only compare properties that affect rendering
    // Note: cursorState and pan handlers are not compared (references/closures)
    // ruleId is compared to force re-render when rule changes
    static func == (lhs: StatorView, rhs: StatorView) -> Bool {
        lhs.ruleId == rhs.ruleId &&  // Compare rule ID first to detect rule changes
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.stator.scales.count == rhs.stator.scales.count &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor &&
        lhs.currentZoomScale == rhs.currentZoomScale
    }
    
    // Calculate total max height based on number of scales
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(stator.scales.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stator.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    generatedScale: generatedScale,  // ✅ Pass entire GeneratedScale
                    width: width,
                    height: scaleHeight,
                    leftMarginWidth: leftMarginWidth,
                    rightMarginWidth: rightMarginWidth,
                    nameFont: nameFont,
                    formulaFont: formulaFont
                )
                .equatable()  // ✅ Prevent unnecessary redraws when inputs unchanged
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            Group {
                if stator.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())  // Make entire area tappable for cursor and pan gestures
        .simultaneousGesture(
            TapGesture(count: 3)
                .onEnded {
                    // Triple-tap to reset zoom to 1.0×
                    // Phase 4: Prefer gestureHandler, fall back to callback
                    if let handler = gestureHandler {
                        handler.handleResetZoom()
                    } else {
                        onResetZoom?()
                    }
                }
        )
        .onTapGesture {
            // Mark stator as touched (sticky readings)
            cursorState?.setStatorTouched()
        }
        .highPriorityGesture(
            // Pan gesture only enabled when zoomed in (>1.0x)
            // Phase 4: Check for gestureHandler OR callbacks
            (currentZoomScale > 1.0 && (gestureHandler != nil || (onPanChanged != nil && onPanEnded != nil))) ?
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        // Phase 4: Prefer gestureHandler, fall back to callback
                        if let handler = gestureHandler {
                            handler.handlePanChanged(gesture)
                        } else {
                            onPanChanged?(gesture)
                        }
                    }
                    .onEnded { gesture in
                        // Phase 4: Prefer gestureHandler, fall back to callback
                        if let handler = gestureHandler {
                            handler.handlePanEnded(gesture)
                        } else {
                            onPanEnded?(gesture)
                        }
                    }
                : nil
        )
    }
    
    // MARK: - Convenience Initializer (Environment-based, no callbacks)
    
    /// Convenience initializer for environment-based gesture handling.
    /// Use this when GestureHandler is available in the environment.
    init(
        stator: Stator,
        width: CGFloat,
        backgroundColor: Color,
        borderColor: Color,
        scaleHeight: CGFloat,
        leftMarginWidth: CGFloat,
        rightMarginWidth: CGFloat,
        nameFont: Font,
        formulaFont: Font,
        cursorState: CursorState?,
        ruleId: UUID?,
        currentZoomScale: CGFloat
    ) {
        self.stator = stator
        self.width = width
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.scaleHeight = scaleHeight
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
        self.nameFont = nameFont
        self.formulaFont = formulaFont
        self.cursorState = cursorState
        self.ruleId = ruleId
        self.currentZoomScale = currentZoomScale
        self.onPanChanged = nil
        self.onPanEnded = nil
        self.onResetZoom = nil
    }
    
    // MARK: - Full Initializer (Callback-based, backward compatible)
    
    /// Full initializer with all callbacks for backward compatibility.
    init(
        stator: Stator,
        width: CGFloat,
        backgroundColor: Color,
        borderColor: Color,
        scaleHeight: CGFloat,
        leftMarginWidth: CGFloat,
        rightMarginWidth: CGFloat,
        nameFont: Font,
        formulaFont: Font,
        cursorState: CursorState?,
        ruleId: UUID?,
        currentZoomScale: CGFloat,
        onPanChanged: ((DragGesture.Value) -> Void)?,
        onPanEnded: ((DragGesture.Value) -> Void)?,
        onResetZoom: (() -> Void)?
    ) {
        self.stator = stator
        self.width = width
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.scaleHeight = scaleHeight
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
        self.nameFont = nameFont
        self.formulaFont = formulaFont
        self.cursorState = cursorState
        self.ruleId = ruleId
        self.currentZoomScale = currentZoomScale
        self.onPanChanged = onPanChanged
        self.onPanEnded = onPanEnded
        self.onResetZoom = onResetZoom
    }
}
