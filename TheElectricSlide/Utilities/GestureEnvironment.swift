//
//  GestureEnvironment.swift
//  TheElectricSlide
//
//  SwiftUI Environment integration for gesture-related services.
//  Follows same pattern as HapticService environment keys.
//
//  Phase 4: Added SlideRuleViewModel and TickHapticCoordinator environment keys
//  to eliminate callback prop drilling through the view hierarchy.
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - GestureService Environment Key

private struct GestureServiceKey: EnvironmentKey {
    static let defaultValue: GestureService = DefaultGestureService()
}

extension EnvironmentValues {
    /// The gesture service for processing gesture inputs with boundary detection and haptic feedback.
    var gestureService: GestureService {
        get { self[GestureServiceKey.self] }
        set { self[GestureServiceKey.self] = newValue }
    }
}

// MARK: - SlideRuleViewModel Environment Key

private struct SlideRuleViewModelKey: EnvironmentKey {
    static let defaultValue: SlideRuleViewModel? = nil
}

extension EnvironmentValues {
    /// The view model for slide rule interaction state (slider, zoom, pan).
    /// Views access this to update state directly without callback prop drilling.
    var slideRuleViewModel: SlideRuleViewModel? {
        get { self[SlideRuleViewModelKey.self] }
        set { self[SlideRuleViewModelKey.self] = newValue }
    }
}

// MARK: - TickHapticCoordinator Environment Key

private struct TickHapticCoordinatorKey: EnvironmentKey {
    static let defaultValue: TickHapticCoordinator? = nil
}

extension EnvironmentValues {
    /// The tick haptic coordinator for triggering haptics when crossing scale tick marks.
    var tickHapticCoordinator: TickHapticCoordinator? {
        get { self[TickHapticCoordinatorKey.self] }
        set { self[TickHapticCoordinatorKey.self] = newValue }
    }
}

// MARK: - CursorState Environment Key

private struct CursorStateKey: EnvironmentKey {
    static let defaultValue: CursorState = CursorState()
}

extension EnvironmentValues {
    /// The cursor state for tracking cursor position and readings.
    /// Views access this to trigger sticky readings without prop drilling.
    var cursorState: CursorState {
        get { self[CursorStateKey.self] }
        set { self[CursorStateKey.self] = newValue }
    }
}

// MARK: - SlideRuleContext (combines slideRule, viewMode, dimensions)

/// Observable context for slide rule specific data that views need.
/// This replaces passing these values through callbacks or multiple bindings.
@Observable
final class SlideRuleContext {
    /// The current slide rule model
    var slideRule: SlideRule
    
    /// Current view mode (front, back, both)
    var viewMode: ViewMode
    
    /// Calculated dimensions for rendering
    var dimensions: Dimensions
    
    /// Cursor state for interaction tracking
    var cursorState: CursorState
    
    init(
        slideRule: SlideRule = SlideRule.logLogDuplexDecitrig(scaleLength: 1000),
        viewMode: ViewMode = .both,
        dimensions: Dimensions = .default,
        cursorState: CursorState = CursorState()
    ) {
        self.slideRule = slideRule
        self.viewMode = viewMode
        self.dimensions = dimensions
        self.cursorState = cursorState
    }
}

private struct SlideRuleContextKey: EnvironmentKey {
    static let defaultValue: SlideRuleContext? = nil
}

extension EnvironmentValues {
    /// Context for slide rule data (slideRule, viewMode, dimensions, cursorState).
    var slideRuleContext: SlideRuleContext? {
        get { self[SlideRuleContextKey.self] }
        set { self[SlideRuleContextKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Injection

extension View {
    /// Injects a custom GestureService into the environment.
    /// Useful for testing or providing custom gesture behavior.
    func gestureService(_ service: GestureService) -> some View {
        environment(\.gestureService, service)
    }
    
    /// Injects the SlideRuleViewModel into the environment.
    /// Child views can access this to update slider/zoom/pan state directly.
    func slideRuleViewModel(_ viewModel: SlideRuleViewModel) -> some View {
        environment(\.slideRuleViewModel, viewModel)
    }
    
    /// Injects the TickHapticCoordinator into the environment.
    /// Child views can trigger tick haptics during gestures.
    func tickHapticCoordinator(_ coordinator: TickHapticCoordinator) -> some View {
        environment(\.tickHapticCoordinator, coordinator)
    }
    
    /// Injects the SlideRuleContext into the environment.
    /// Provides slideRule, viewMode, dimensions, and cursorState to child views.
    func slideRuleContext(_ context: SlideRuleContext) -> some View {
        environment(\.slideRuleContext, context)
    }
    
    /// Injects the CursorState into the environment.
    /// Child views can access this to trigger sticky readings.
    func cursorState(_ state: CursorState) -> some View {
        environment(\.cursorState, state)
    }
}

// MARK: - Preview Support

/// Preview helper for SwiftUI previews that need gesture service
struct GestureServicePreviewModifier: ViewModifier {
    let service: GestureService
    
    func body(content: Content) -> some View {
        content
            .environment(\.gestureService, service)
    }
}

extension View {
    /// Provides a gesture service for SwiftUI previews.
    /// Uses a default service that doesn't fire haptics on macOS.
    func withPreviewGestureService() -> some View {
        modifier(GestureServicePreviewModifier(service: DefaultGestureService()))
    }
}
