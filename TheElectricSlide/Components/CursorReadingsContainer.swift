//
//  CursorReadingsContainer.swift
//  TheElectricSlide
//
//  Extracted from DynamicSlideRuleContent.swift to eliminate code duplication
//  Consolidates cursor readings display logic into a single reusable component
//
//  Architecture: swift-docs/cursor-readings-consolidation-architecture.md
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Cursor Readings Container

/// Reusable component for displaying cursor readings with tap-to-cycle functionality
/// Encapsulates all reading display determination logic and rendering
struct CursorReadingsContainer: View {
    // MARK: - State Dependencies
    
    /// Current view mode (front, back, or both)
    let viewMode: ViewMode
    
    /// Binding to cursor reading cycle mode for tap-to-cycle functionality
    @Binding var cursorReadingCycleMode: CursorReadingCycleMode
    
    /// Current cursor readings (contains front and back readings)
    let currentReadings: CursorReadings?
    
    /// Whether the slide rule has a back side
    let hasBackSide: Bool
    
    // MARK: - Body
    
    var body: some View {
        let frontReadings = currentReadings?.frontReadings ?? []
        let backReadings = currentReadings?.backReadings ?? []
        
        #if DEBUG
        let _ = print("📊 CursorReadingsContainer: frontReadings=\(frontReadings.count), backReadings=\(backReadings.count), currentReadings=\(currentReadings != nil ? "present" : "nil")")
        #endif
        
        // Determine which readings to show based on cycle mode and current view mode
        // Cycle mode controls display for all view modes, allowing selective reading visibility
        let (shouldShowFront, shouldShowBack): (Bool, Bool) = {
            switch viewMode {
            case .both:
                // In "both" view mode, respect cycle mode for selective display
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)  // Show front only
                case .oppositeSide:
                    return (false, hasBackSide)  // Show back only (if exists)
                case .both:
                    return (true, hasBackSide)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            case .front:
                // Currently viewing front side
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (true, false)  // Show front only
                case .oppositeSide:
                    return (false, hasBackSide)  // Show back only (if exists)
                case .both:
                    return (true, hasBackSide)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            case .back:
                // Currently viewing back side
                switch cursorReadingCycleMode {
                case .currentSide:
                    return (false, true)  // Show back only
                case .oppositeSide:
                    return (true, false)  // Show front only
                case .both:
                    return (true, true)  // Show both
                case .none:
                    return (false, false)  // Show nothing
                }
            }
        }()
        
        // Stacked layout with tap gesture - negative spacing for tight rows
        VStack(spacing: -4) {
            if shouldShowFront && !frontReadings.isEmpty {
                CursorReadingsDisplayView(
                    readings: frontReadings,
                    side: .front
                )
                // NOTE: .equatable() removed during debugging - was potentially blocking updates
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
            }
            
            if shouldShowBack && !backReadings.isEmpty {
                CursorReadingsDisplayView(
                    readings: backReadings,
                    side: .back
                )
                // NOTE: .equatable() removed during debugging - was potentially blocking updates
                .frame(maxWidth: .infinity)
                .padding(.vertical, 0)
            }
            
            // Show placeholder when in "none" mode to maintain tap target
            if cursorReadingCycleMode == .none {
                Color.clear
                    .frame(height: 12)  // Minimal height for tap target
            }
        }
        .frame(minHeight: 50)  // CRITICAL: Maintain consistent minimum height across all cycle modes
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap to cycle through all display states, regardless of view mode
            withAnimation(.easeInOut(duration: 0.2)) {
                cursorReadingCycleMode = cursorReadingCycleMode.next()
            }
        }
        .accessibilityLabel("Cycle cursor reading mode")
        .accessibilityHint("Tap to cycle reading display modes")
        .accessibilityIdentifier("cursorReadingCycleToggle")
        // Subtle opacity feedback
        .opacity(0.95)
    }
}

// MARK: - Preview

#Preview("Current Side - Front View") {
    @Previewable @State var cycleMode: CursorReadingCycleMode = .currentSide
    
    let mockReadings = CursorReadings(
        cursorPosition: 0.5,
        timestamp: Date(),
        frontReadings: [
            ScaleReading(
                scaleName: "C",
                formula: "x",
                value: 3.16,
                displayValue: "3.16",
                side: .front,
                component: .statorTop,
                scaleDefinition: StandardScales.cScale(),
                componentPosition: 0
            ),
            ScaleReading(
                scaleName: "D",
                formula: "x",
                value: 3.16,
                displayValue: "3.16",
                side: .front,
                component: .statorBottom,
                scaleDefinition: StandardScales.dScale(),
                componentPosition: 0
            )
        ],
        backReadings: [
            ScaleReading(
                scaleName: "S",
                formula: "sin⁻¹(x/100)",
                value: 45.0,
                displayValue: "45°",
                side: .back,
                component: .statorTop,
                scaleDefinition: StandardScales.sScale(),
                componentPosition: 0
            )
        ]
    )
    
    VStack(spacing: 20) {
        Text("Tap to cycle through modes")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        CursorReadingsContainer(
            viewMode: .front,
            cursorReadingCycleMode: $cycleMode,
            currentReadings: mockReadings,
            hasBackSide: true
        )
        .frame(maxWidth: 600)
        .padding(.horizontal, 8)
        
        Text("Current mode: \(cycleMode.rawValue)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("Both Sides View") {
    @Previewable @State var cycleMode: CursorReadingCycleMode = .both
    
    let mockReadings = CursorReadings(
        cursorPosition: 0.5,
        timestamp: Date(),
        frontReadings: [
            ScaleReading(
                scaleName: "C",
                formula: "x",
                value: 3.16,
                displayValue: "3.16",
                side: .front,
                component: .statorTop,
                scaleDefinition: StandardScales.cScale(),
                componentPosition: 0
            ),
            ScaleReading(
                scaleName: "D",
                formula: "x",
                value: 3.16,
                displayValue: "3.16",
                side: .front,
                component: .statorBottom,
                scaleDefinition: StandardScales.dScale(),
                componentPosition: 0
            )
        ],
        backReadings: [
            ScaleReading(
                scaleName: "S",
                formula: "sin⁻¹(x/100)",
                value: 45.0,
                displayValue: "45°",
                side: .back,
                component: .statorTop,
                scaleDefinition: StandardScales.sScale(),
                componentPosition: 0
            )
        ]
    )
    
    VStack(spacing: 20) {
        Text("Showing both front and back readings")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        CursorReadingsContainer(
            viewMode: .both,
            cursorReadingCycleMode: $cycleMode,
            currentReadings: mockReadings,
            hasBackSide: true
        )
        .frame(maxWidth: 600)
        .padding(.horizontal, 8)
    }
    .padding()
}

#Preview("None Mode") {
    @Previewable @State var cycleMode: CursorReadingCycleMode = .none
    
    let mockReadings = CursorReadings(
        cursorPosition: 0.5,
        timestamp: Date(),
        frontReadings: [
            ScaleReading(
                scaleName: "C",
                formula: "x",
                value: 3.16,
                displayValue: "3.16",
                side: .front,
                component: .statorTop,
                scaleDefinition: StandardScales.cScale(),
                componentPosition: 0
            )
        ],
        backReadings: []
    )
    
    VStack(spacing: 20) {
        Text("None mode - shows minimal placeholder")
            .font(.caption)
            .foregroundStyle(.secondary)
        
        CursorReadingsContainer(
            viewMode: .front,
            cursorReadingCycleMode: $cycleMode,
            currentReadings: mockReadings,
            hasBackSide: false
        )
        .frame(maxWidth: 600)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.1))
    }
    .padding()
}
