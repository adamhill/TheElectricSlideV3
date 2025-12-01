//
//  ViewMode.swift
//  TheElectricSlide
//
//  View mode types for displaying slide rule sides
//

import Foundation

// MARK: - View Mode

/// Represents the viewing mode for displaying slide rule sides.
/// The available modes are device-dependent:
/// - Compact devices (iPhone, Apple Watch) support only single-side views: .front or .back
/// - Regular devices (iPad, Mac, Vision Pro) support all modes: .front, .back, and .both
enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case front = "Front"
    case back = "Back"
    case both = "Both"
    
    var id: String { rawValue }
    
    // MARK: - Device-Aware Mode Selection
    
    /// Returns the list of view modes available for a given device category.
    ///
    /// Compact devices (phone, watch) are restricted to single-side views only,
    /// while regular devices (pad, mac, vision) can display multiple sides simultaneously.
    ///
    /// - Parameter category: The device category to query
    /// - Returns: Array of available ViewMode cases for the device
    ///
    /// ## Examples
    /// ```swift
    /// ViewMode.availableModes(for: .phone)   // [.front, .back]
    /// ViewMode.availableModes(for: .pad)     // [.front, .back, .both]
    /// ViewMode.availableModes(for: .watch)   // [.front, .back]
    /// ```
    static func availableModes(for category: DeviceCategory) -> [ViewMode] {
        switch category {
        case .phone, .watch:
            // Compact devices: single-side only
            return [.front, .back]
        case .pad, .mac, .vision:
            // Regular devices: all options including both sides
            return [.front, .back, .both]
        }
    }
    
    /// Constrains the current view mode to be compatible with the given device category.
    ///
    /// If the current mode is `.both` and the device is a compact device (phone or watch),
    /// this method returns `.front` as a fallback. Otherwise, it returns the current mode unchanged.
    ///
    /// This ensures that the view mode is always valid for the current device's capabilities.
    ///
    /// - Parameter category: The device category to constrain for
    /// - Returns: A ViewMode that is guaranteed to be available on the device
    ///
    /// ## Examples
    /// ```swift
    /// ViewMode.both.constrained(for: .phone)   // Returns .front (fallback)
    /// ViewMode.both.constrained(for: .pad)     // Returns .both (unchanged)
    /// ViewMode.front.constrained(for: .phone)  // Returns .front (unchanged)
    /// ```
    func constrained(for category: DeviceCategory) -> ViewMode {
        // If current mode is .both and device doesn't support multi-side view,
        // fall back to .front
        if self == .both && !category.supportsMultiSideView {
            return .front
        }
        // Otherwise, current mode is valid for this device
        return self
    }
}
