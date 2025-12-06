//
//  ScrollWheelZoomModifier.swift
//  TheElectricSlide
//
//  Provides scroll wheel and trackpad zoom support for macOS.
//  Uses NSEvent local monitor to capture scroll wheel events.
//

import SwiftUI

#if os(macOS)
import AppKit

// MARK: - Scroll Zoom Speed Conversion

/// Converts a 1-20 speed value to internal sensitivity
/// - Parameter speed: Integer from 1 (very slow) to 20 (very fast). Default is 10.
/// - Returns: Internal sensitivity value for scroll-to-zoom conversion
private func sensitivityFromSpeed(_ speed: Int) -> CGFloat {
    let clamped = min(max(speed, 1), 20)
    // Exponential curve for more natural feel
    // Speed 1 = 0.001 (very slow, fine control)
    // Speed 10 = 0.01 (default, balanced)
    // Speed 20 = 0.1 (very fast)
    let normalized = CGFloat(clamped - 1) / 19.0  // 0.0 to 1.0
    let minSensitivity: CGFloat = 0.001
    let maxSensitivity: CGFloat = 0.1
    // Exponential interpolation for natural feel
    return minSensitivity * pow(maxSensitivity / minSensitivity, normalized)
}

// MARK: - Scroll Wheel Zoom Modifier

/// A view modifier that adds scroll wheel zoom support for macOS
/// Captures scroll wheel events and converts them to zoom gestures
struct ScrollWheelZoomModifier: ViewModifier {
    let speed: Int
    let onZoomChanged: @Sendable (CGFloat) -> Void
    let onZoomEnded: @Sendable (CGFloat) -> Void
    
    @State private var scrollMonitor = ScrollWheelMonitor()
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                scrollMonitor.sensitivity = sensitivityFromSpeed(speed)
                scrollMonitor.onZoomChanged = onZoomChanged
                scrollMonitor.onZoomEnded = onZoomEnded
                scrollMonitor.startMonitoring()
            }
            .onDisappear {
                scrollMonitor.stopMonitoring()
            }
            .onChange(of: speed) { _, newValue in
                scrollMonitor.sensitivity = sensitivityFromSpeed(newValue)
            }
    }
}

// MARK: - Scroll Wheel Monitor

/// Monitors scroll wheel events using NSEvent local monitor
@MainActor
final class ScrollWheelMonitor {
    var onZoomChanged: (@Sendable (CGFloat) -> Void)?
    var onZoomEnded: (@Sendable (CGFloat) -> Void)?
    
    /// Internal sensitivity factor
    var sensitivity: CGFloat = 0.01  // Default = speed 10
    
    private var eventMonitor: Any?
    private var accumulatedDelta: CGFloat = 0
    private var isScrolling: Bool = false
    private var scrollEndWorkItem: DispatchWorkItem?
    
    func startMonitoring() {
        guard eventMonitor == nil else { return }
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            Task { @MainActor in
                self?.handleScrollEvent(event)
            }
            return event  // Pass event through
        }
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        scrollEndWorkItem?.cancel()
    }
    
    private func handleScrollEvent(_ event: NSEvent) {
        // Use scrollingDeltaY for trackpad/mouse wheel
        // Positive = scroll up = zoom in
        let delta = event.scrollingDeltaY
        
        // Ignore very small deltas
        guard abs(delta) > 0.1 else { return }
        
        if !isScrolling {
            // Start of new scroll gesture
            isScrolling = true
            accumulatedDelta = 0
        }
        
        // Accumulate delta and calculate new scale
        accumulatedDelta += delta * sensitivity
        let newScale = max(0.25, 1.0 + accumulatedDelta)
        
        onZoomChanged?(newScale)
        
        // Cancel previous end timer and start new one
        scrollEndWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isScrolling = false
            let finalScale = max(0.25, 1.0 + self.accumulatedDelta)
            self.onZoomEnded?(finalScale)
            self.accumulatedDelta = 0
        }
        scrollEndWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }
}

// MARK: - View Extension

extension View {
    /// Adds scroll wheel zoom support on macOS
    /// - Parameters:
    ///   - speed: Zoom speed from 1 (very slow) to 20 (very fast). Default is 10.
    ///   - onZoomChanged: Called during scroll with the current scale factor
    ///   - onZoomEnded: Called when scroll gesture ends with the final scale factor
    /// - Returns: Modified view with scroll wheel zoom support
    func onScrollWheelZoom(
        speed: Int = 10,
        onZoomChanged: @escaping @Sendable (CGFloat) -> Void,
        onZoomEnded: @escaping @Sendable (CGFloat) -> Void
    ) -> some View {
        self.modifier(ScrollWheelZoomModifier(
            speed: speed,
            onZoomChanged: onZoomChanged,
            onZoomEnded: onZoomEnded
        ))
    }
}

#else

// MARK: - iOS Stub

extension View {
    /// No-op on iOS - scroll wheel zoom is macOS only
    func onScrollWheelZoom(
        speed: Int = 10,
        onZoomChanged: @escaping @Sendable (CGFloat) -> Void,
        onZoomEnded: @escaping @Sendable (CGFloat) -> Void
    ) -> some View {
        self
    }
}

#endif
