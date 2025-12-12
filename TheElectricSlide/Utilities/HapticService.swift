//
//  HapticService.swift
//  TheElectricSlide
//
//  Centralized haptic feedback service using functional programming patterns.
//  Provides declarative enums + environment injection for testability.
//
//  Phase 1 of haptic centralization - replaces HapticManager over time.
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Haptic Event Types

/// Represents all possible haptic feedback events in the app
enum HapticEvent: Equatable {
    // Discrete events
    case flip
    case precisionModeEntered
    case precisionModeExited
    case buttonTap(style: HapticStyle)
    
    // Tick-based events with context
    case tickCrossed(level: TickLevel)
    
    // Compound events
    case longBuzz
    
    // Gesture boundary events
    case boundaryHit(edge: BoundaryEdge)
    case zoomSnap
    case momentumStop
    
    enum TickLevel: Equatable {
        case major      // relativeLength >= 0.9
        case secondary  // relativeLength >= 0.65
        case tertiary   // relativeLength >= 0.4
        case ignored    // below threshold
        
        init(relativeLength: Double) {
            switch relativeLength {
            case 0.9...: self = .major
            case 0.65...: self = .secondary
            case 0.4...: self = .tertiary
            default: self = .ignored
            }
        }
    }
    
    enum HapticStyle: Equatable {
        case light, medium, heavy, rigid, soft
    }
}

// MARK: - Haptic Service Protocol

/// Protocol for haptic feedback service - enables dependency injection and testing
protocol HapticService {
    func fire(_ event: HapticEvent)
    func prepare()
}

// MARK: - Default Implementation

/// Production implementation that triggers actual device haptics
final class DefaultHapticService: HapticService {
    #if os(iOS)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    #endif
    
    func fire(_ event: HapticEvent) {
        #if os(iOS)
        switch event {
        case .flip:
            lightGenerator.impactOccurred()
            
        case .precisionModeEntered:
            // Double-tap pattern for entering precision mode
            rigidGenerator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                rigidGenerator.impactOccurred(intensity: 0.8)
            }
            
        case .precisionModeExited:
            softGenerator.impactOccurred()
            
        case .longBuzz:
            // Strong double-tap pattern
            rigidGenerator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                rigidGenerator.impactOccurred(intensity: 0.8)
            }
            
        case .tickCrossed(let level):
            switch level {
            case .major:
                heavyGenerator.impactOccurred()
            case .secondary:
                mediumGenerator.impactOccurred()
            case .tertiary:
                lightGenerator.impactOccurred()
            case .ignored:
                break // No haptic for ignored levels
            }
            
        case .buttonTap(let style):
            generator(for: style).impactOccurred()
            
        case .boundaryHit:
            // Rigid feedback when hitting gesture boundaries
            rigidGenerator.impactOccurred(intensity: 0.8)
            
        case .zoomSnap:
            // Soft feedback when zoom snaps to default
            softGenerator.impactOccurred()
            
        case .momentumStop:
            // Light feedback when momentum animation completes
            lightGenerator.impactOccurred(intensity: 0.5)
        }
        #endif
    }
    
    func prepare() {
        #if os(iOS)
        heavyGenerator.prepare()
        mediumGenerator.prepare()
        lightGenerator.prepare()
        rigidGenerator.prepare()
        softGenerator.prepare()
        #endif
    }
    
    #if os(iOS)
    private func generator(for style: HapticEvent.HapticStyle) -> UIImpactFeedbackGenerator {
        switch style {
        case .heavy: return heavyGenerator
        case .medium: return mediumGenerator
        case .light: return lightGenerator
        case .rigid: return rigidGenerator
        case .soft: return softGenerator
        }
    }
    #endif
}

// MARK: - Mock for Testing

/// Mock implementation for unit tests and SwiftUI previews
final class MockHapticService: HapticService {
    private(set) var firedEvents: [HapticEvent] = []
    private(set) var prepareCallCount = 0
    
    func fire(_ event: HapticEvent) {
        firedEvents.append(event)
    }
    
    func prepare() {
        prepareCallCount += 1
    }
    
    func reset() {
        firedEvents.removeAll()
        prepareCallCount = 0
    }
}

// MARK: - SwiftUI Environment Integration

struct HapticServiceKey: EnvironmentKey {
    static let defaultValue: HapticService = DefaultHapticService()
}

extension EnvironmentValues {
    var hapticService: HapticService {
        get { self[HapticServiceKey.self] }
        set { self[HapticServiceKey.self] = newValue }
    }
}
