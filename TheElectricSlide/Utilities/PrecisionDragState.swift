//
//  PrecisionDragState.swift
//  TheElectricSlide
//
//  Shared state and constants for precision drag mode (long-press + drag)
//  Used by both cursor and slide gestures for DRY implementation
//

import SwiftUI

// MARK: - Precision Drag Constants

/// Shared constants for precision drag mode behavior
/// Centralized here for easy tweaking across all precision gestures
enum PrecisionDragConstants {
    /// Long press duration required to activate precision mode (seconds)
    static let longPressMinimumDuration: TimeInterval = 1.0
    
    /// Precision mode reduces drag sensitivity by this factor
    static let precisionFactor: CGFloat = 5.0
    
    /// Cooldown duration after precision mode ends (seconds)
    /// Prevents stale gesture events from normal drag from firing
    static let cooldownDuration: TimeInterval = 0.5
    
    /// Minimum normalized movement threshold to accept (prevents micro-jitter)
    /// This is a normalized value (0.0 to 1.0) representing fraction of movement range.
    ///
    /// **Conversion to pixels:** `pixels = threshold × widthInPixels`
    ///
    /// | Threshold | 400px | 800px | 1200px |
    /// |-----------|-------|-------|--------|
    /// | 0.0001    | 0.04  | 0.08  | 0.12   |
    /// | 0.0005    | 0.20  | 0.40  | 0.60   |
    /// | 0.001     | 0.40  | 0.80  | 1.20   |
    static let minimumMovementThreshold: CGFloat = 0.0005
}

// MARK: - Precision Drag State

/// Observable state for tracking precision drag mode
/// Can be shared or instantiated separately for each gesture target (cursor vs slide)
@Observable
final class PrecisionDragState {
    /// Whether precision sequence is active (from long press start to cooldown end)
    var isSequenceActive: Bool = false
    
    /// Session ID to invalidate stale gesture events
    var sessionID: UUID? = nil
    
    /// Last translation applied during precision drag (for use in onEnded)
    /// This prevents "finger lift jitter" where onEnded has different translation
    var lastAppliedTranslation: CGFloat = 0
    
    /// Reset all state for a new gesture session
    func beginSession() {
        sessionID = UUID()
        isSequenceActive = true
        lastAppliedTranslation = 0
    }
    
    /// End the precision session and start cooldown
    /// - Parameter cooldownDuration: How long to keep isSequenceActive true
    func endSession(cooldownDuration: TimeInterval = PrecisionDragConstants.cooldownDuration) {
        // Reset translation tracking
        lastAppliedTranslation = 0
        
        // Keep sequence active during cooldown to block normal gestures
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration) { [weak self] in
            self?.isSequenceActive = false
            self?.sessionID = nil
        }
    }
    
    /// Track translation during drag for use in onEnded
    func trackTranslation(_ translation: CGFloat) {
        lastAppliedTranslation = translation
    }
}
