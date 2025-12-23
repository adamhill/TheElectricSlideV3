//
//  ScaleContainer.swift
//  TheElectricSlide
//
//  Protocol abstraction for components that contain scales (Slide and Stator)
//  Enables generic rendering logic to eliminate duplication
//

import SlideRuleCoreV3

/// Protocol for slide rule components that contain scales
/// Both Slide and Stator conform to this protocol
protocol ScaleContainer {
    var scales: [GeneratedScale] { get }
    var showBorder: Bool { get }
    
    /// Total height of all scales in this container, including 4pt spacing between them
    var totalScalesHeight: Distance { get }
}

extension ScaleContainer {
    var totalScalesHeight: Distance {
        let scalesHeight = scales.map { $0.definition.height }.reduce(0.0, +)
        let spacing = scales.isEmpty ? 0.0 : Double(scales.count - 1) * 4.0
        return scalesHeight + spacing
    }
}

// MARK: - Protocol Conformance

extension Slide: ScaleContainer {}
extension Stator: ScaleContainer {}
