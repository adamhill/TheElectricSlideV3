//
//  CursorReadingsDisplayView.swift
//  TheElectricSlide
//
//  Displays scale readings in a horizontal block format
//

import SwiftUI
import SlideRuleCoreV3

// Enable detailed cursor debugging (disabled by default to reduce log noise)
// Uncomment this line to enable verbose cursor reading logs during development
// #define DEBUG_CURSOR_READINGS

/// Displays cursor readings for one side of the slide rule in a horizontal block format
struct CursorReadingsDisplayView: View, Equatable {
    /// Array of readings to display
    let readings: [ScaleReading]
    
    /// Which side this display is for (for styling/labeling if needed)
    let side: RuleSide
    
    // MARK: - Equatable Conformance
    
    /// Compare views based on side, scale names, and display values
    /// This prevents unnecessary redraws when display content hasn't changed
    /// while ensuring updates when scales or values change
    static func == (lhs: CursorReadingsDisplayView, rhs: CursorReadingsDisplayView) -> Bool {
        guard lhs.side == rhs.side else { return false }
        guard lhs.readings.count == rhs.readings.count else { return false }
        
        return lhs.readings.elementsEqual(rhs.readings) {
            $0.scaleName == $1.scaleName && $0.displayValue == $1.displayValue
        }
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
        #if DEBUG && DEBUG_CURSOR_READINGS
        let _ = print("📊 CursorReadingsDisplayView[\(side.rawValue)]: \(readings.count) readings, first scaleName: \(readings.first?.scaleName ?? "none"), first displayValue: \(readings.first?.displayValue ?? "none")")
        #endif
        
        // Use Color.clear as the size-defining element, with content as overlay
        // This prevents the readings HStack from expanding the parent layout
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(backgroundColor.opacity(0.5))
            .overlay(alignment: .leading) {
                // Content overlaid - clips to container bounds
                HStack(spacing: 8) {
                    // F/B indicator
                    Text(side == .front ? "F" : "B")
                        .font(.system(size: 14, weight: .bold).monospaced())
                        .foregroundStyle(side == .front ? .blue : .green)
                        .frame(width: 16)
                    
                    // Readings in plain HStack - will be clipped if too wide
                    HStack(spacing: 4) {
                        ForEach(readings) { reading in
                            readingView(for: reading)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    /// Returns fixed cell width optimized for each scale's name + typical value length
    /// - Width is FIXED for a given scale (no jumping)
    /// - Different scales have different widths based on their value range
    private func cellWidth(for scaleName: String) -> CGFloat {
        // Character width estimate: ~7pt per monospace char at size 11-13
        // Plus 8pt padding (4pt each side)
        let charWidth: CGFloat = 7
        let padding: CGFloat = 8
        
        switch scaleName {
        // Compact 1-char names with typical values
        case "C", "D", "S", "T", "ω", "τ":
            return charWidth * 7 + padding  // 57pt
            
        // 1-char names needing slightly more room
        case "A", "B", "K", "CosΘ":
            return charWidth * 8 + padding  // 64pt
            
        // Scales needing extra width for visual spacing
        case "L", "λ", "D/Q", "SH2":
            return charWidth * 9 + padding  // 71pt
            
        // Compact 2-char names
        case "Xc", "XL":
            return charWidth * 7 + padding  // 57pt
            
        // ST scale
        case "ST":
            return charWidth * 8 + padding  // 64pt
            
        // Standard 2-char names
        case "DI", "CI", "CF", "DF", "BI", "db", "PF":
            return charWidth * 8 + padding  // 64pt
            
        // 3-char names
        case "CIF", "DIF":
            return charWidth * 9 + padding  // 71pt
            
        // LL scales with longer values
        case "LL1", "LL3":
            return charWidth * 11 + padding  // 85pt
            
        // LL2 needs extra width to prevent clipping
        case "LL2":
            return charWidth * 13 + padding  // 99pt
            
        // 4-char LL scales
        case "LL01", "LL02", "LL03", "LL00":
            return charWidth * 12 + padding  // 92pt
            
        default:
            return charWidth * 10 + padding  // 78pt
        }
    }
    
    /// Creates a single reading display element with per-scale fixed width
    /// - Parameter reading: The scale reading to display
    /// - Returns: View showing label and value with pill-styled background
    private func readingView(for reading: ScaleReading) -> some View {
        HStack(spacing: 1) {
            Text(reading.scaleName)
                .font(.system(size: 11, weight: .medium, design: .monospaced).smallCaps())
                .foregroundStyle(.secondary)
            
            Text(reading.displayValue)
                .font(.system(size: 12.5, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 3)
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
                ),
                ScaleReading(
                    scaleName: "CI",
                    formula: "1/x",
                    value: 0.316,
                    displayValue: "0.32",
                    side: .front,
                    component: .slide,
                    scaleDefinition: StandardScales.ciScale(),
                    componentPosition: 0
                ),
                ScaleReading(
                    scaleName: "A",
                    formula: "x²",
                    value: 10.0,
                    displayValue: "10.0",
                    side: .front,
                    component: .statorTop,
                    scaleDefinition: StandardScales.aScale(),
                    componentPosition: 1
                ),
                ScaleReading(
                    scaleName: "K",
                    formula: "x³",
                    value: 2.154,
                    displayValue: "2.15",
                    side: .front,
                    component: .statorTop,
                    scaleDefinition: StandardScales.kScale(),
                    componentPosition: 2
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
                    componentPosition: 0
                ),
                ScaleReading(
                    scaleName: "T",
                    formula: "tan⁻¹(x/100)",
                    value: 30.0,
                    displayValue: "30°",
                    side: .back,
                    component: .statorBottom,
                    scaleDefinition: StandardScales.tScale(),
                    componentPosition: 0
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
