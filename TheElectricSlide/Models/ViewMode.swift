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
    
    /// Returns the next view mode in the cycle for the given device category.
    ///
    /// The cycle order depends on available modes:
    /// - Compact devices (phone, watch): .front → .back → .front → ...
    /// - Regular devices (pad, mac, vision): .front → .back → .both → .front → ...
    ///
    /// - Parameter category: The device category to determine available modes
    /// - Returns: The next ViewMode in the cycle
    ///
    /// ## Examples
    /// ```swift
    /// ViewMode.front.next(for: .phone)  // Returns .back
    /// ViewMode.back.next(for: .phone)   // Returns .front
    /// ViewMode.front.next(for: .pad)    // Returns .back
    /// ViewMode.back.next(for: .pad)     // Returns .both
    /// ViewMode.both.next(for: .pad)     // Returns .front
    /// ```
    func next(for category: DeviceCategory) -> ViewMode {
        let availableModes = ViewMode.availableModes(for: category)
        guard let currentIndex = availableModes.firstIndex(of: self) else {
            // Fallback to first mode if current mode is not available
            return availableModes.first ?? .front
        }
        let nextIndex = (currentIndex + 1) % availableModes.count
        return availableModes[nextIndex]
    }
}
