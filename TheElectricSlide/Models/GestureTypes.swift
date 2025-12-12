//
//  GestureTypes.swift
//  TheElectricSlide
//
//  Pure value types for gesture input and output.
//  Enables testable, deterministic gesture calculations.
//

import Foundation
import CoreGraphics

// MARK: - Input Types (from SwiftUI gestures)

struct SlideGestureInput {
    let translation: CGSize
    let velocity: CGSize?           // iOS 18+ or predicted
    let baseOffset: CGFloat
    let scaleWidth: CGFloat
    let isPrecisionMode: Bool
    let precisionFactor: CGFloat
}

struct CursorGestureInput {
    let translation: CGSize
    let velocity: CGSize?
    let basePosition: CGFloat       // 0.0-1.0 normalized
    let viewWidth: CGFloat
    let isPrecisionMode: Bool
    let precisionFactor: CGFloat
}

struct ZoomGestureInput {
    let magnification: CGFloat
    let baseScale: CGFloat
    let minScale: CGFloat
    let maxScale: CGFloat
}

struct PanGestureInput {
    let translation: CGSize
    let velocity: CGSize?
    let baseOffset: CGSize
    let zoomScale: CGFloat
    let contentSize: CGSize
    let viewportSize: CGSize
}

// MARK: - Output Types (pure calculation results)

struct SlideGestureResult {
    let offset: CGFloat
    let isBounded: Bool             // True if hit boundary
    let boundaryEdge: BoundaryEdge? // .leading or .trailing
    let momentum: MomentumResult?   // For onEnded
}

struct CursorGestureResult {
    let normalizedPosition: CGFloat // 0.0-1.0
    let isBounded: Bool
    let boundaryEdge: BoundaryEdge?
    let momentum: MomentumResult?
}

struct ZoomGestureResult {
    let scale: CGFloat
    let snappedToDefault: Bool      // True if snapped to 1.0×
}

struct PanGestureResult {
    let offset: CGSize
    let boundedAxes: Set<BoundaryEdge>
    let momentum: MomentumResult?
}

struct MomentumResult {
    let finalOffset: CGFloat        // Predicted end position
    let duration: TimeInterval      // Animation duration
    let curve: MomentumCurve        // Deceleration curve
    
    enum MomentumCurve: Equatable {
        case friction(CGFloat)       // Natural deceleration
        case spring                  // Bounce back
    }
}

enum BoundaryEdge: Hashable {
    case leading, trailing, top, bottom
}

enum Axis {
    case horizontal, vertical
}
