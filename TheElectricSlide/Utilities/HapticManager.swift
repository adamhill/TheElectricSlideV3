//
//  HapticManager.swift
//  TheElectricSlide
//
//  Centralized haptic feedback management for slide rule interactions
//  Issue #61: Navigation gestures and tick haptics
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Centralized manager for haptic feedback throughout the app
/// Provides tiered haptic intensities and throttling to prevent hardware saturation
enum HapticManager {
    
    // MARK: - Throttle State
    
    /// Shared throttle state for tick haptics
    private static var lastTickHapticTime: Date = .distantPast
    
    /// Minimum interval between tick haptics (50ms)
    private static let tickHapticThrottleInterval: TimeInterval = 0.05
    
    // MARK: - Generators (Cached for Performance)
    
    #if os(iOS)
    /// Pre-prepared generators for better responsiveness
    private static let heavyGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        return generator
    }()
    
    private static let mediumGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    
    private static let lightGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    private static let rigidGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        return generator
    }()
    #endif
    
    // MARK: - Feedback Types
    
    /// Long haptic buzz for entering precision mode (long press)
    /// Used as placeholder for slow-move dial feature
    static func longBuzz() {
        #if os(iOS)
        rigidGenerator.impactOccurred(intensity: 1.0)
        // Schedule a second pulse for "long" feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            rigidGenerator.impactOccurred(intensity: 0.8)
        }
        rigidGenerator.prepare()
        #endif
    }
    
    /// Level 1 - Strong pop for major tick marks (relativeLength >= 0.9)
    static func strongPop() {
        #if os(iOS)
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
        #endif
    }
    
    /// Level 2 - Normal pop for medium tick marks (relativeLength >= 0.65)
    static func normalPop() {
        #if os(iOS)
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
        #endif
    }
    
    /// Level 3 - Short/light pop for minor tick marks
    static func shortPop() {
        #if os(iOS)
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
        #endif
    }
    
    /// Light feedback for side flip gesture
    static func flipFeedback() {
        #if os(iOS)
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
        #endif
    }
    
    // MARK: - Tick Haptic with Throttling
    
    /// Trigger haptic for tick mark crossing with 50ms throttle
    /// - Parameter tickLevel: The tick's relativeLength (1.0 = major, 0.75 = medium, 0.5 = minor)
    /// - Returns: True if haptic was triggered, false if throttled
    @discardableResult
    static func tickHaptic(forLevel tickLevel: Double) -> Bool {
        let now = Date()
        
        // Check throttle - skip if less than 50ms since last haptic
        guard now.timeIntervalSince(lastTickHapticTime) >= tickHapticThrottleInterval else {
            return false
        }
        
        // Update timestamp
        lastTickHapticTime = now
        
        // Trigger appropriate haptic based on tick level
        if tickLevel >= 0.9 {
            strongPop()  // Level 1 - Major ticks
        } else if tickLevel >= 0.65 {
            normalPop()  // Level 2 - Medium ticks
        } else if tickLevel >= 0.4 {
            shortPop()   // Level 3 - Minor ticks
        }
        // Tiny ticks (< 0.4) get no haptic to avoid overwhelming user
        
        return true
    }
    
    // MARK: - Preparation
    
    /// Prepare all generators for immediate response
    /// Call this when entering an interaction-heavy mode
    static func prepareAll() {
        #if os(iOS)
        heavyGenerator.prepare()
        mediumGenerator.prepare()
        lightGenerator.prepare()
        rigidGenerator.prepare()
        #endif
    }
}
