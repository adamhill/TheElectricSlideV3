//
//  CursorReadingsDisplayView.swift
//  TheElectricSlide
//
//  Displays scale readings in a horizontal block format
//

import SwiftUI
import SlideRuleCoreV3

/// Displays cursor readings for one side of the slide rule in a horizontal block format
struct CursorReadingsDisplayView: View, Equatable {
    /// Array of readings to display
    let readings: [ScaleReading]
    
    /// Which side this display is for (for styling/labeling if needed)
    let side: RuleSide
    
    // MARK: - Equatable Conformance
    
    /// Compare views based on side and display values only
    /// This prevents unnecessary redraws when display strings haven't changed
    static func == (lhs: CursorReadingsDisplayView, rhs: CursorReadingsDisplayView) -> Bool {
        lhs.side == rhs.side &&
        lhs.readings.map(\.displayValue) == rhs.readings.map(\.displayValue)
    }
    
    /// Cross-platform background color for the readings container
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(nsColor: NSColor.controlBackgroundColor)
        #else
        return Color(uiColor: UIColor.secondarySystemBackground)
        #endif
    }
    
    var body: some View {
        if readings.isEmpty {
            // Gracefully handle empty readings - show minimal placeholder
            Text("No readings")
                .font(.system(size: 22).monospaced())
                .foregroundStyle(.secondary)
                .frame(height: 48)
        } else {
            // Horizontal flow of readings
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(readings) { reading in
                        readingView(for: reading)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(height: 56)
            .background(backgroundColor.opacity(0.5))
            .cornerRadius(4)
        }
    }
    
    /// Creates a single reading display element
    /// - Parameter reading: The scale reading to display
    /// - Returns: View showing "scalename: value" with italicized value
    private func readingView(for reading: ScaleReading) -> some View {
        HStack(spacing: 2) {
            // Scale name in regular font
            Text(reading.scaleName)
                .font(.system(size: 18, weight: .bold).monospaced())
                .foregroundStyle(.primary)
            
            // Separator
            Text(":")
                .font(.system(size: 18, weight: .bold).monospaced())
                .foregroundStyle(.secondary)
            
            // Value with adaptive tracking to compress long decimals
            // Prevents ellipsis truncation while maintaining readability
            Text(reading.displayValue)
                .font(.system(size: 18, weight: .regular).monospaced())
                .italic()
                .tracking(trackingAmount(for: reading.displayValue))
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.primary)
        }
    }
    
    /// Calculates adaptive font tracking based on value length
    /// - Parameter value: The display value string
    /// - Returns: Negative tracking amount for compression (0 to -1.5)
    ///
    /// Longer values get more compression to fit without truncation:
    /// - 5 chars or less: No compression (0)
    /// - 6-7 chars: Slight compression (-0.5)
    /// - 8-9 chars: More compression (-1.0)
    /// - 10+ chars: Maximum compression (-1.5)
    private func trackingAmount(for value: String) -> CGFloat {
        let length = value.count
        if length <= 5 {
            return 0 // Normal spacing
        } else if length <= 7 {
            return -0.5 // Slight compression
        } else if length <= 9 {
            return -1.0 // More compression
        } else {
            return -1.5 // Maximum compression for very long values
        }
    }
}

// MARK: - Preview

#Preview("With Readings") {
    VStack(spacing: 16) {
        // Example front readings
        CursorReadingsDisplayView(
            readings: [
                ScaleReading(
                    scaleName: "C",
                    formula: "x",
                    value: 3.16,
                    displayValue: "3.16",
                    side: .front,
                    component: .statorTop,
                    scaleDefinition: StandardScales.cScale(),
                    componentPosition: 0,
                    overallPosition: 0
                ),
                ScaleReading(
                    scaleName: "D",
                    formula: "x",
                    value: 3.16,
                    displayValue: "3.16",
                    side: .front,
                    component: .statorBottom,
                    scaleDefinition: StandardScales.dScale(),
                    componentPosition: 0,
                    overallPosition: 1
                ),
                ScaleReading(
                    scaleName: "CI",
                    formula: "1/x",
                    value: 0.316,
                    displayValue: "0.32",
                    side: .front,
                    component: .slide,
                    scaleDefinition: StandardScales.ciScale(),
                    componentPosition: 0,
                    overallPosition: 2
                ),
                ScaleReading(
                    scaleName: "A",
                    formula: "x²",
                    value: 10.0,
                    displayValue: "10.0",
                    side: .front,
                    component: .statorTop,
                    scaleDefinition: StandardScales.aScale(),
                    componentPosition: 1,
                    overallPosition: 3
                ),
                ScaleReading(
                    scaleName: "K",
                    formula: "x³",
                    value: 2.154,
                    displayValue: "2.15",
                    side: .front,
                    component: .statorTop,
                    scaleDefinition: StandardScales.kScale(),
                    componentPosition: 2,
                    overallPosition: 4
                )
            ],
            side: .front
        )
        .frame(maxWidth: 600)
        
        // Example back readings
        CursorReadingsDisplayView(
            readings: [
                ScaleReading(
                    scaleName: "S",
                    formula: "sin⁻¹(x/100)",
                    value: 45.0,
                    displayValue: "45°",
                    side: .back,
                    component: .statorTop,
                    scaleDefinition: StandardScales.sScale(),
                    componentPosition: 0,
                    overallPosition: 0
                ),
                ScaleReading(
                    scaleName: "T",
                    formula: "tan⁻¹(x/100)",
                    value: 30.0,
                    displayValue: "30°",
                    side: .back,
                    component: .statorBottom,
                    scaleDefinition: StandardScales.tScale(),
                    componentPosition: 0,
                    overallPosition: 1
                )
            ],
            side: .back
        )
        .frame(maxWidth: 600)
    }
    .padding()
}

#Preview("Empty Readings") {
    CursorReadingsDisplayView(
        readings: [],
        side: .front
    )
    .frame(maxWidth: 600)
    .padding()
}
