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
        lhs.readings.elementsEqual(rhs.readings) { $0.displayValue == $1.displayValue }
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
            Text("  ")
                .font(.system(size: 12).monospaced())
                .foregroundStyle(.secondary)
                .frame(height: 24)
        } else {
            // Horizontal flow of readings
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(readings) { reading in
                        readingView(for: reading)
                    }
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 4)
            }
            .frame(height: 56)
            .background(backgroundColor.opacity(0.5))
            .cornerRadius(4)
        }
    }
    
    /// Returns fixed cell width optimized for each scale's name + typical value length
    /// - Width is FIXED for a given scale (no jumping)
    /// - Different scales have different widths based on their value range
    private func cellWidth(for scaleName: String) -> CGFloat {
        // Character width estimate: ~7pt per monospace char at size 11-12
        // Plus 12pt padding (6pt each side)
        let charWidth: CGFloat = 7
        let padding: CGFloat = 12
        
        switch scaleName {
        // Tighter 1-char names: C, D, S, T (values stay compact)
        case "C", "D", "S", "T":
            // 1 char name + space + 5 chars value = 6 chars
            return charWidth * 7 + padding  // ~61pt
            
        // Simple 1-char names with small values (1-10 range: "X.XX" = 4 chars)
        case "A", "B", "K":
            // 1 char name + space + 5 chars value = 6 chars
            // K goes to 1000 but formatted as "999.9" = 5 chars
            return charWidth * 7 + padding  // ~61pt
            
        // L scale needs extra width to prevent wrapping
        case "L":
            // 1 char name + space + 5 chars value = 6 chars, but needs +2 extra for visual spacing
            return charWidth * 9 + padding  // ~75pt
            
        // Tighter 2-char names: CI
        case "CI":
            // 2 char name + space + 5 chars value = 7 chars
            return charWidth * 8 + padding  // ~68pt
            
        // ST scale needs extra width (+2 multiplier from CI)
        case "ST":
            // 2 char name + space + 5 chars value = 7 chars + extra for visual spacing
            return charWidth * 10 + padding  // ~82pt
            
        // 2-char names with small values
        case "DI", "CF", "DF", "BI":
            // 2 char name + space + 5 chars value = 7 chars
            return charWidth * 8 + padding  // ~68pt
            
        // 3-char names
        case "CIF":
            // 3 char name + space + 5 chars value = 8 chars
            return charWidth * 9 + padding  // ~75pt
            
        // LL scales (3-4 char names with longer values)
        case "LL1", "LL3":
            // 3 char name + space + 7 chars value = 10 chars
            return charWidth * 11 + padding  // ~89pt
            
        // LL2 needs extra width to prevent clipping on K&E 4081
        case "LL2":
            // 3 char name + space + 7 chars value = 10 chars + extra to prevent overlap with FlipButton
            return charWidth * 14 + padding  // ~110pt
            
        case "LL01", "LL02", "LL03", "LL00":
            // 4 char name + space + 7 chars value = 11 chars
            return charWidth * 12 + padding  // ~96pt
            
        default:
            // Fallback for unknown scales
            return charWidth * 10 + padding  // ~82pt
        }
    }
    
    /// Creates a single reading display element with per-scale fixed width
    /// - Parameter reading: The scale reading to display
    /// - Returns: View showing label and value with pill-styled background
    private func readingView(for reading: ScaleReading) -> some View {
        HStack(spacing: 2) {
            Text(reading.scaleName)
                .font(.system(size: 11, weight: .medium, design: .monospaced).smallCaps())
                .foregroundStyle(.secondary)
            
            Text(reading.displayValue)
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.accentColor.opacity(0.85))
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.2), value: reading.displayValue)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(width: cellWidth(for: reading.scaleName), alignment: .leading)  // PER-SCALE FIXED WIDTH, left-aligned
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(0.08))
        )
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
