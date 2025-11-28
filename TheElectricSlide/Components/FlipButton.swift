//
//  FlipButton.swift
//  TheElectricSlide
//
//  Created by Kilo Code on 1/30/25.
//  Phase 3: iPhone flip button component for device-specific breakpoints
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

/// A compact, circular button component that toggles between front and back views of the slide rule.
///
/// This component is designed specifically for compact devices (iPhone, Apple Watch) where
/// only one side of the slide rule can be displayed at a time. It provides an intuitive
/// flip mechanism with haptic feedback.
///
/// ## Features
/// - Icon-only design with SF Symbol (`arrow.triangle.2.circlepath`)
/// - Small, circular button following HIG guidelines
/// - Haptic feedback on iOS for tactile confirmation
/// - Full accessibility support with VoiceOver
/// - Subtle `.bordered` button style
/// - Proper touch target sizing (40x40 points as per Apple HIG)
///
/// ## Usage Example
/// ```swift
/// @State private var viewMode: ViewMode = .front
///
/// FlipButton(viewMode: $viewMode)
///     .disabled(!hasBackSide)  // Disable if slide rule has no back side
/// ```
///
/// ## Design Notes
/// - Uses `.bordered` style for subtle, non-prominent appearance
/// - Circular shape via `.clipShape(Circle())`
/// - Fixed 40x40pt size for consistent appearance
/// - Icon-only design keeps UI clean and compact
struct FlipButton: View {
    /// Binding to the current view mode. The button will toggle between `.front` and `.back`.
    @Binding var viewMode: ViewMode
    
    // MARK: - Computed Properties
    
    /// Accessibility label for VoiceOver users.
    /// Provides clear description of the button's purpose.
    private var accessibilityLabel: String {
        "Flip slide rule"
    }
    
    /// Accessibility hint providing additional context for VoiceOver users.
    /// Explains the result of tapping the button.
    private var accessibilityHint: String {
        let targetSide = viewMode == .front ? "back" : "front"
        return "Toggles to the \(targetSide) side of the slide rule"
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: toggleSide) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                )
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier("flipButton")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue("Currently showing \(viewMode.rawValue) side")
    }
    
    // MARK: - Actions
    
    /// Toggles between front and back view modes with haptic feedback.
    ///
    /// This method:
    /// 1. Triggers haptic feedback on iOS devices for tactile confirmation
    /// 2. Animates the view mode transition using a spring animation
    /// 3. Updates the bound viewMode state
    ///
    /// The spring animation provides a natural, physics-based transition that feels
    /// responsive and polished. The haptic feedback (light impact) provides tactile
    /// confirmation of the action without being overwhelming.
    private func toggleSide() {
        #if DEBUG
        let fromSide = viewMode.rawValue
        let toSide = (viewMode == .front) ? ViewMode.back.rawValue : ViewMode.front.rawValue
        print("[FlipButton] Flipping: \(fromSide) → \(toSide)")
        #endif
        
        // Provide haptic feedback on iOS for tactile confirmation
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        
        // Animate the view mode transition with a spring animation
        // Response: 0.3 seconds (feels snappy and responsive)
        // Damping: 0.8 (slight bounce for natural feel)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            // Toggle between front and back modes
            viewMode = (viewMode == .front) ? .back : .front
        }
    }
}

// MARK: - Preview

#Preview("Front Side") {
    @Previewable @State var viewMode: ViewMode = .front
    
    VStack(spacing: 20) {
        Text("Current Mode: \(viewMode.rawValue)")
            .font(.headline)
        
        FlipButton(viewMode: $viewMode)
        
        Text("Tap to flip to back side")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Back Side") {
    @Previewable @State var viewMode: ViewMode = .back
    
    VStack(spacing: 20) {
        Text("Current Mode: \(viewMode.rawValue)")
            .font(.headline)
        
        FlipButton(viewMode: $viewMode)
        
        Text("Tap to flip to front side")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Disabled State") {
    @Previewable @State var viewMode: ViewMode = .front
    
    VStack(spacing: 20) {
        Text("Disabled (No Back Side)")
            .font(.headline)
        
        FlipButton(viewMode: $viewMode)
            .disabled(true)
        
        Text("Button is disabled when slide rule has no back side")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding()
}