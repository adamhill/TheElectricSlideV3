//
//  DeviceDetection.swift
//  TheElectricSlide
//
//  Created by Kilo Code on 1/30/25.
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - Device Category

/// Represents the category of Apple device the app is running on.
/// Used to adapt UI behavior and layout for device-specific characteristics.
///
/// - phone: iPhone devices (compact UI, single-side display)
/// - pad: iPad devices (regular UI, multi-side display)
/// - mac: macOS devices (regular UI, multi-side display)
/// - watch: Apple Watch devices (compact UI, single-side display)
/// - vision: Apple Vision Pro devices (spatial UI, multi-side display)
enum DeviceCategory: String, Sendable, Equatable, Codable {
    case phone
    case pad
    case mac
    case watch
    case vision
    
    /// Whether this device category supports displaying multiple sides simultaneously.
    /// Compact devices (phone, watch) show one side at a time with a flip button.
    /// Regular devices (pad, mac, vision) can show front/back/both with a segmented picker.
    var supportsMultiSideView: Bool {
        switch self {
        case .phone, .watch:
            return false  // Single-side with flip button
        case .pad, .mac, .vision:
            return true   // Multi-side with picker
        }
    }
    
    /// User-facing display name for this device category
    var displayName: String {
        switch self {
        case .phone: return "iPhone"
        case .pad: return "iPad"
        case .mac: return "Mac"
        case .watch: return "Apple Watch"
        case .vision: return "Apple Vision Pro"
        }
    }
    
    /// Default margin width for this device category (in points)
    /// Smaller devices use tighter margins to maximize content area
    var defaultMargins: CGFloat {
        switch self {
        case .phone: return 16
        case .watch: return 12
        case .pad, .mac, .vision: return 40
        }
    }
}

// MARK: - Device Detection

/// Utility for detecting the current device category.
/// Uses platform-specific APIs to determine device type at runtime.
struct DeviceDetection {
    
    /// Detect the current device category based on the platform and device idiom.
    ///
    /// This function uses compile-time conditionals to check the OS platform,
    /// then uses runtime APIs to distinguish between device types within that platform.
    ///
    /// - Returns: The detected device category
    ///
    /// ## Platform Detection Logic
    ///
    /// ### iOS
    /// Uses `UIDevice.current.userInterfaceIdiom` to differentiate:
    /// - `.phone` → iPhone (compact display)
    /// - `.pad` → iPad (regular display)
    /// - Unknown idioms default to `.pad` for safety
    ///
    /// ### macOS
    /// Always returns `.mac` (no device variations)
    ///
    /// ### watchOS
    /// Always returns `.watch` (no device variations)
    ///
    /// ### visionOS
    /// Always returns `.vision` (no device variations)
    ///
    /// ### Other Platforms
    /// Defaults to `.pad` as a safe fallback with regular UI capabilities
    ///
    /// ## Edge Cases Handled
    /// - iPad in Split View: Still detected as `.pad` (not affected by size class)
    /// - iPad in Slide Over: Still detected as `.pad`
    /// - Unknown iOS devices: Default to `.pad` for safety
    /// - Future platforms: Default to `.pad` for maximum compatibility
    ///
    /// ## Performance
    /// This function is lightweight and can be called frequently.
    /// The result should be cached in @State for efficiency.
    ///
    /// ## Thread Safety
    /// Safe to call from any thread. UIDevice.current is thread-safe.
    static func currentDeviceCategory() -> DeviceCategory {
        #if DEBUG
        print("[DeviceDetection] Detecting device category...")
        #endif
        
        #if os(iOS)
        #if DEBUG
        print("[DeviceDetection] Platform: iOS")
        #endif
        // iOS: Distinguish between iPhone and iPad using user interface idiom
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            #if DEBUG
            print("[DeviceDetection] Detected device category: .phone")
            #endif
            return .phone
        case .pad:
            #if DEBUG
            print("[DeviceDetection] Detected device category: .pad")
            #endif
            return .pad
        default:
            // Unknown iOS device types (e.g., future devices)
            // Default to .pad for regular UI behavior
            #if DEBUG
            print("[DeviceDetection] Unknown iOS idiom, defaulting to: .pad")
            #endif
            return .pad
        }
        #elseif os(macOS)
        #if DEBUG
        print("[DeviceDetection] Platform: macOS")
        print("[DeviceDetection] Detected device category: .mac")
        #endif
        // macOS: Always return .mac
        return .mac
        #elseif os(watchOS)
        #if DEBUG
        print("[DeviceDetection] Platform: watchOS")
        print("[DeviceDetection] Detected device category: .watch")
        #endif
        // watchOS: Always return .watch
        return .watch
        #elseif os(visionOS)
        #if DEBUG
        print("[DeviceDetection] Platform: visionOS")
        print("[DeviceDetection] Detected device category: .vision")
        #endif
        // visionOS: Always return .vision
        return .vision
        #else
        #if DEBUG
        print("[DeviceDetection] Platform: Unknown")
        print("[DeviceDetection] Detected device category: .pad (fallback)")
        #endif
        // Unknown platform: Default to .pad for safe regular UI
        return .pad
        #endif
    }
}