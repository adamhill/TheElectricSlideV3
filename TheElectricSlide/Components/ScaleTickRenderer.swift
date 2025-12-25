//
//  ScaleTickRenderer.swift
//  TheElectricSlide
//
//  Encapsulates tick mark rendering logic for scale views.
//  Handles baseline drawing, tick mark positioning, and color application.
//
//  Extracted from ScaleView.swift for better separation of concerns.
//

import SwiftUI
import SlideRuleCoreV3
import CoreGraphics

/// Renders tick marks for scale views with baseline and color support
struct ScaleTickRenderer {
    let definition: ScaleDefinition
    
    /// Cached tick CGColor from definition (computed once per renderer instance)
    /// Stored as CGColor for direct use with CGContext drawing
    private let cachedTickCGColor: CGColor
    
    /// Pre-computed height multiplier for tick calculations
    private static let kHeightMultiplier: CGFloat = 0.5
    
    /// Width  multiplier for tick calculations
    private static let kWidthMultiplier: CGFloat = 1.0

    init(definition: ScaleDefinition) {
        self.definition = definition
        
        // Pre-compute tick color as CGColor once instead of per-tick
        // CGColor is required for CGContext drawing operations
        if let tupleColor = definition.labelColor,
           definition.colorApplication.scaleTicks {
            self.cachedTickCGColor = CGColor(
                red: CGFloat(tupleColor.red),
                green: CGFloat(tupleColor.green),
                blue: CGFloat(tupleColor.blue),
                alpha: 1.0
            )
        } else {
            self.cachedTickCGColor = CGColor(gray: 0, alpha: 1)
        }
    }
    
    // MARK: - Baseline Drawing
    
    /// Draw the scale baseline if enabled in definition
    func drawBaseline(context: inout GraphicsContext, size: CGSize) {
        guard definition.showBaseline else { return }
        
        let baselinePath = Path { path in
            switch definition.tickDirection {
            case .down:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size.width, y: 0))
            case .up:
                path.move(to: CGPoint(x: 0, y: size.height))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
            }
        }
        
        context.stroke(
            baselinePath,
            with: .color(.black),
            lineWidth: 2.0
        )
    }
    
    // MARK: - Tick Mark Drawing
    
    /// Draw a single tick mark and return its computed geometry for label positioning
    /// - Returns: Tuple of (xPos, tickHeight) for use by label renderer
    @discardableResult
    func drawTick(
        context: inout GraphicsContext,
        tick: TickMark,
        size: CGSize
    ) -> (xPos: CGFloat, tickHeight: CGFloat) {
        // Calculate horizontal position
        let xPos = tick.normalizedPosition * size.width
        
        // Calculate tick height based on relativeLength
        let tickHeight = tick.style.relativeLength * (size.height * Self.kHeightMultiplier)
        
        // Calculate tick start and end positions based on direction
        let (tickStartY, tickEndY): (CGFloat, CGFloat)
        switch definition.tickDirection {
        case .down:
            tickStartY = 0
            tickEndY = tickHeight
        case .up:
            tickStartY = size.height
            tickEndY = size.height - tickHeight
        }
        
        // Create tick path
        let tickPath = Path { path in
            path.move(to: CGPoint(x: xPos, y: tickStartY))
            path.addLine(to: CGPoint(x: xPos, y: tickEndY))
        }
        
        // Draw tick mark with anti-aliasing disabled for crisp 1-pixel lines
        // IMPORTANT: Must use CGContext drawing primitives (not SwiftUI context.stroke)
        // because setShouldAntialias only affects CGContext operations.
        // Per Apple docs: "Any state you set on the Core Graphics context is lost when the closure returns"
        // and SwiftUI's context.stroke() uses its own rendering path that ignores CGContext state.
        context.withCGContext { cgContext in
            cgContext.setShouldAntialias(false)
            cgContext.setStrokeColor(cachedTickCGColor)
            cgContext.setLineWidth(tick.style.lineWidth * ScaleTickRenderer.kWidthMultiplier)
            cgContext.addPath(tickPath.cgPath)
            cgContext.strokePath()
        }
        
        return (xPos, tickHeight)
    }
    
    // MARK: - Geometry Helpers
    
    /// Calculate tick geometry without drawing (useful for label-only operations)
    func tickGeometry(for tick: TickMark, size: CGSize) -> (xPos: CGFloat, tickHeight: CGFloat) {
        let xPos = tick.normalizedPosition * size.width
        let tickHeight = tick.style.relativeLength * (size.height * Self.kHeightMultiplier)
        return (xPos, tickHeight)
    }
}
