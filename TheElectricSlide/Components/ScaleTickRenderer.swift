//
//  ScaleTickRenderer.swift
//  TheElectricSlide
//
//  Encapsulates tick mark rendering logic for scale views.
//  Handles baseline drawing, tick mark positioning, and color application.
//
//  Extracted from ScaleView.swift for better separation of concerns.
//
//  ## Optimization Notes (Step 2 - December 2025)
//
//  Key optimizations applied per WWDC2024 "Create custom visual effects with SwiftUI":
//  1. **Batched drawing**: Ticks grouped by line width to minimize CGContext state changes
//  2. **Single CGContext block**: One `withCGContext` call for all ticks (was per-tick)
//  3. **Direct CGMutablePath**: Avoid SwiftUI Path → CGPath conversion overhead
//  4. **Pre-computed geometry**: Tick positions calculated once, stored for label positioning
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
    
    /// Common line widths for batching (avoid dictionary allocation per draw)
    private static let kCommonLineWidths: [CGFloat] = [0.5, 1.0, 1.5, 2.0]

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
            lineWidth: 0.5
        )
    }
    
    /// Draw a separator line at the baseline if enabled in definition
    func drawSeparator(context: inout GraphicsContext, size: CGSize) {
        guard definition.hasBottomSeparator else { return }
        
        let separatorPath = Path { path in
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
            separatorPath,
            with: .color(.black),
            lineWidth: 1.0
        )
    }
    
    // MARK: - Tick Mark Drawing
    
    /// Draw a single tick mark and return its computed geometry for label positioning
    /// - Returns: Tuple of (xPos, tickHeight) for use by label renderer
    ///
    /// Note: For better performance with many ticks, use `drawTicksBatched()` instead.
    @discardableResult
    func drawTick(
        context: inout GraphicsContext,
        tick: TickMark,
        size: CGSize
    ) -> (xPos: CGFloat, tickHeight: CGFloat) {
        // ✅ GUARD: Skip ticks with invalid data (prevents CoreGraphics NaN error)
        // This can occur if scale generation produces invalid normalizedPosition values
        // (e.g., from log(0) in LnNormalizedFunction when begin=0)
        guard !tick.normalizedPosition.isNaN && !tick.normalizedPosition.isInfinite &&
              !tick.style.relativeLength.isNaN && !tick.style.relativeLength.isInfinite else {
            // Return default values without drawing to prevent CoreGraphics error
            return (0, 0)
        }
        
        // Calculate horizontal position
        // Note: tick.normalizedPosition already includes split segment mapping from ScaleCalculator
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
    
    // MARK: - Batched Tick Drawing (Optimized)
    
    /// Represents pre-computed tick geometry for batched drawing
    struct TickGeometry {
        let xPos: CGFloat
        let tickHeight: CGFloat
        let startY: CGFloat
        let endY: CGFloat
        let lineWidth: CGFloat
        let tickIndex: Int  // Reference back to original tick for label drawing
    }
    
    /// Draw all tick marks in a single batched operation, grouped by line width.
    /// Returns pre-computed geometry for each tick for use by label renderer.
    ///
    /// **Performance**: Single `withCGContext` call vs. one per tick.
    /// Groups ticks by line width to minimize `setLineWidth` state changes.
    func drawTicksBatched(
        context: inout GraphicsContext,
        tickMarks: [TickMark],
        size: CGSize
    ) -> [TickGeometry] {
        // Pre-compute all tick geometry
        var geometries: [TickGeometry] = []
        geometries.reserveCapacity(tickMarks.count)
        
        // Group ticks by line width for batched drawing
        // Using Dictionary for O(1) lookup vs O(n) linear search with array
        var ticksByWidth: [CGFloat: CGMutablePath] = [:]
        
        for (index, tick) in tickMarks.enumerated() {
            // Skip invalid ticks
            guard !tick.normalizedPosition.isNaN && !tick.normalizedPosition.isInfinite &&
                  !tick.style.relativeLength.isNaN && !tick.style.relativeLength.isInfinite else {
                geometries.append(TickGeometry(xPos: 0, tickHeight: 0, startY: 0, endY: 0, lineWidth: 0, tickIndex: index))
                continue
            }
            
            // Calculate geometry
            // Note: tick.normalizedPosition already includes split scale transformation from ScaleCalculator
            let xPos = tick.normalizedPosition * size.width
            let tickHeight = tick.style.relativeLength * (size.height * Self.kHeightMultiplier)
            let lineWidth = tick.style.lineWidth * Self.kWidthMultiplier
            
            let (startY, endY): (CGFloat, CGFloat)
            switch definition.tickDirection {
            case .down:
                startY = 0
                endY = tickHeight
            case .up:
                startY = size.height
                endY = size.height - tickHeight
            }
            
            geometries.append(TickGeometry(
                xPos: xPos,
                tickHeight: tickHeight,
                startY: startY,
                endY: endY,
                lineWidth: lineWidth,
                tickIndex: index
            ))
            
            // Find or create path for this line width
            if let existingPath = ticksByWidth[lineWidth] {
                existingPath.move(to: CGPoint(x: xPos, y: startY))
                existingPath.addLine(to: CGPoint(x: xPos, y: endY))
            } else {
                let newPath = CGMutablePath()
                newPath.move(to: CGPoint(x: xPos, y: startY))
                newPath.addLine(to: CGPoint(x: xPos, y: endY))
                ticksByWidth[lineWidth] = newPath
            }
        }
        
        // Draw all ticks in a single CGContext block
        context.withCGContext { cgContext in
            cgContext.setShouldAntialias(false)
            cgContext.setStrokeColor(cachedTickCGColor)
            
            // Draw each line width group
            for (width, path) in ticksByWidth {
                cgContext.setLineWidth(width)
                cgContext.addPath(path)
                cgContext.strokePath()
            }
        }
        
        return geometries
    }
    
    // MARK: - Geometry Helpers
    
    /// Calculate tick geometry without drawing (useful for label-only operations)
    func tickGeometry(for tick: TickMark, size: CGSize) -> (xPos: CGFloat, tickHeight: CGFloat) {
        // Note: tick.normalizedPosition already includes split scale transformation from ScaleCalculator
        let xPos = tick.normalizedPosition * size.width
        let tickHeight = tick.style.relativeLength * (size.height * Self.kHeightMultiplier)
        return (xPos, tickHeight)
    }
}
