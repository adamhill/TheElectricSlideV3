//
//  PrecisionDragCoordinator.swift
//  TheElectricSlide
//
//  Unified precision mode state management for all draggable components (slide and cursor).
//  Replaces the duplicated precision state in CursorOverlay and SideView with a single
//  coordinator that can track which target is active and provide consistent behavior.
//
//  Uses SwiftUI Environment for injection (no prop drilling).
//

import SwiftUI

// MARK: - Drag Target Identification

/// Identifies which draggable component is currently in precision mode
enum PrecisionDragTarget: Equatable {
    case slide(RuleSide)
    case cursor
    case none
}

// MARK: - Precision Drag Coordinator

/// Unified precision mode state management for all draggable components.
/// Provides consistent precision mode behavior across slide and cursor gestures.
///
/// **Key Features:**
/// - Tracks which target is in precision mode (only one at a time)
/// - Provides translation tracking to prevent finger-lift jitter
/// - Manages cooldown period to prevent gesture interference
/// - Uses `@ObservationIgnored` for hot state (no unnecessary view updates)
///
/// **Usage:**
/// ```swift
/// // In view, get from environment
/// @Environment(\.precisionCoordinator) private var precision
///
/// // Activate for slide
/// precision.activate(for: .slide)
///
/// // Track translation during drag
/// precision.recordTranslation(gesture.translation)
///
/// // Get delta from last recorded translation
/// let delta = precision.deltaFrom(newTranslation: gesture.translation)
///
/// // Deactivate when gesture ends
/// precision.deactivate()
/// ```
@Observable
final class PrecisionDragCoordinator {
    
    // MARK: - Observable State (triggers view updates when needed)
    
    /// Which target is currently in precision mode
    var activeTarget: PrecisionDragTarget = .none
    
    /// Whether precision mode is currently active
    var isPrecisionActive: Bool {
        activeTarget != .none
    }
    
    // MARK: - Hot State (not observed - internal tracking only)
    
    /// Session ID to invalidate stale gesture events
    @ObservationIgnored private var sessionID: UUID?
    
    /// Last translation applied during precision drag
    /// Prevents "finger lift jitter" where onEnded has different translation than last onChanged
    @ObservationIgnored private var lastAppliedTranslation: CGSize = .zero
    
    /// Position before precision mode started (for validation)
    @ObservationIgnored private var positionAtStart: CGFloat?
    
    /// Cooldown timer reference
    @ObservationIgnored private var cooldownWorkItem: DispatchWorkItem?
    
    // MARK: - Configuration
    
    /// Sensitivity reduction factor (drag distance divided by this)
    let precisionFactor: CGFloat
    
    /// Duration for long press to activate precision mode
    let activationDuration: TimeInterval
    
    /// Duration to block normal gestures after precision ends
    let cooldownDuration: TimeInterval
    
    /// Minimum normalized movement to accept (prevents micro-jitter)
    let minimumMovementThreshold: CGFloat
    
    // MARK: - Initialization
    
    init(
        precisionFactor: CGFloat = PrecisionDragConstants.precisionFactor,
        activationDuration: TimeInterval = PrecisionDragConstants.longPressMinimumDuration,
        cooldownDuration: TimeInterval = PrecisionDragConstants.cooldownDuration,
        minimumMovementThreshold: CGFloat = PrecisionDragConstants.minimumMovementThreshold
    ) {
        self.precisionFactor = precisionFactor
        self.activationDuration = activationDuration
        self.cooldownDuration = cooldownDuration
        self.minimumMovementThreshold = minimumMovementThreshold
    }
    
    // MARK: - Session Management
    
    /// Activate precision mode for a specific target
    /// - Parameters:
    ///   - target: Which component (.slide or .cursor)
    ///   - startPosition: Optional position snapshot for validation
    func activate(for target: PrecisionDragTarget, startPosition: CGFloat? = nil) {
        // Cancel any pending cooldown
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
        
        // Start new session
        sessionID = UUID()
        activeTarget = target
        lastAppliedTranslation = .zero
        positionAtStart = startPosition
        
        #if DEBUG
        print("🎯 [PrecisionCoordinator] ACTIVATED for \(target) - session=\(sessionID?.uuidString.prefix(8) ?? "nil")")
        #endif
    }
    
    /// Deactivate precision mode and start cooldown
    /// During cooldown, `isInCooldown` returns true to block normal gestures
    func deactivate() {
        guard activeTarget != .none else { return }
        
        let endingTarget = activeTarget
        
        #if DEBUG
        print("🎯 [PrecisionCoordinator] DEACTIVATING \(endingTarget) - starting cooldown")
        #endif
        
        // Reset translation but keep activeTarget during cooldown
        lastAppliedTranslation = .zero
        positionAtStart = nil
        
        // Schedule session end after cooldown
        let workItem = DispatchWorkItem { [weak self] in
            self?.activeTarget = .none
            self?.sessionID = nil
            #if DEBUG
            print("🎯 [PrecisionCoordinator] COOLDOWN ENDED - ready for normal gestures")
            #endif
        }
        cooldownWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration, execute: workItem)
    }
    
    /// Force immediate deactivation without cooldown (use sparingly)
    func forceDeactivate() {
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
        activeTarget = .none
        sessionID = nil
        lastAppliedTranslation = .zero
        positionAtStart = nil
    }
    
    // MARK: - Translation Tracking
    
    /// Record the current translation during precision drag
    /// - Parameter translation: The gesture's translation value
    func recordTranslation(_ translation: CGSize) {
        lastAppliedTranslation = translation
    }
    
    /// Record translation width only (convenience for horizontal-only gestures)
    /// - Parameter width: The horizontal translation in points
    func recordTranslationWidth(_ width: CGFloat) {
        lastAppliedTranslation = CGSize(width: width, height: lastAppliedTranslation.height)
    }
    
    /// Get the last recorded translation (for use in onEnded)
    var lastTranslation: CGSize {
        lastAppliedTranslation
    }
    
    /// Get just the width of last translation
    var lastTranslationWidth: CGFloat {
        lastAppliedTranslation.width
    }
    
    /// Calculate delta from last recorded translation to new translation
    /// - Parameter newTranslation: The gesture's current translation
    /// - Returns: The difference from the last recorded translation
    func deltaFrom(newTranslation: CGSize) -> CGSize {
        CGSize(
            width: newTranslation.width - lastAppliedTranslation.width,
            height: newTranslation.height - lastAppliedTranslation.height
        )
    }
    
    // MARK: - State Queries
    
    /// Check if a specific target is in precision mode
    /// - Parameter target: The target to check
    /// - Returns: True if that target is in precision mode
    func isActive(for target: PrecisionDragTarget) -> Bool {
        activeTarget == target
    }
    
    /// Check if precision mode should block normal gestures for a target
    /// Returns true if precision mode is active for that target OR during cooldown
    /// - Parameter target: The target to check
    /// - Returns: True if normal gestures should be blocked
    func shouldBlockNormalGestures(for target: PrecisionDragTarget) -> Bool {
        activeTarget == target
    }
    
    /// Check if a movement is above the minimum threshold
    /// - Parameters:
    ///   - normalizedDelta: Movement as fraction of available range (0.0-1.0)
    /// - Returns: True if movement should be processed
    func isAboveThreshold(_ normalizedDelta: CGFloat) -> Bool {
        abs(normalizedDelta) >= minimumMovementThreshold
    }
    
    /// Apply precision factor to a translation value
    /// - Parameter translation: Raw translation from gesture
    /// - Returns: Translation divided by precision factor
    func applyPrecision(to translation: CGFloat) -> CGFloat {
        translation / precisionFactor
    }
    
    /// Apply precision factor to a size
    /// - Parameter translation: Raw translation size from gesture
    /// - Returns: Translation divided by precision factor (both dimensions)
    func applyPrecision(to translation: CGSize) -> CGSize {
        CGSize(
            width: translation.width / precisionFactor,
            height: translation.height / precisionFactor
        )
    }
}

// MARK: - Environment Key

private struct PrecisionCoordinatorKey: EnvironmentKey {
    static let defaultValue: PrecisionDragCoordinator = PrecisionDragCoordinator()
}

extension EnvironmentValues {
    /// The precision drag coordinator for managing precision mode across components.
    var precisionCoordinator: PrecisionDragCoordinator {
        get { self[PrecisionCoordinatorKey.self] }
        set { self[PrecisionCoordinatorKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Injection

extension View {
    /// Injects a custom PrecisionDragCoordinator into the environment.
    /// Useful for testing or providing custom precision behavior.
    ///
    /// Example:
    /// ```swift
    /// ContentView()
    ///     .precisionCoordinator(myCustomCoordinator)
    /// ```
    func precisionCoordinator(_ coordinator: PrecisionDragCoordinator) -> some View {
        environment(\.precisionCoordinator, coordinator)
    }
}
