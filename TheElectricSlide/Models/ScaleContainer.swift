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
}

// MARK: - Protocol Conformance

extension Slide: ScaleContainer {}
extension Stator: ScaleContainer {}
