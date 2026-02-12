//  TheElectricSlide
//
//  Reusable SwiftUI preview component for testing split scale rendering
//  with enhanced visual debugging and validation features
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - GeneratedScale Label Extension (DRY helper for preview labels)

extension GeneratedScale {
    /// Generates a formatted label string from scale properties
    /// Format: "Name – Formula: begin → end" or "Name: begin → end" if formula is empty
    /// - Parameter precision: Number of decimal places for range values (auto-detected if nil)
    func previewLabel(precision: Int? = nil) -> String {
        let name = definition.name.isEmpty ? "Scale" : definition.name
        let formula = definition.formula
        let begin = definition.beginValue
        let end = definition.endValue
        
        // Auto-detect precision based on value magnitude
        let effectivePrecision = precision ?? autoPrecision(for: begin, end: end)
        let beginStr = String(format: "%.\(effectivePrecision)f", begin)
        let endStr = String(format: "%.\(effectivePrecision)f", end)
        
        if formula.isEmpty {
            return "\(name): \(beginStr) → \(endStr)"
        } else {
            return "\(name) – \(formula): \(beginStr) → \(endStr)"
        }
    }
    
    /// Auto-detect appropriate decimal precision based on value magnitude
    private func autoPrecision(for begin: Double, end: Double) -> Int {
        let minAbsValue = min(abs(begin), abs(end))
        if minAbsValue < 0.0001 {
            return 6
        } else if minAbsValue < 0.01 {
            return 5
        } else if minAbsValue < 0.1 {
            return 4
        } else if minAbsValue < 1.0 {
            return 3
        } else if minAbsValue < 10.0 {
            return 2
        } else {
            return 1
        }
    }
}

/// A reusable component for visualizing and validating split scale rendering
/// with enhanced debug information, boundary markers, and measurement tools.
struct SplitScaleTestComponent: View {
    // MARK: - Properties
    
    // Scale definitions to test
    let leftScale: GeneratedScale
    let rightScale: GeneratedScale
    
    // Test case metadata
    let title: String
    let segmentDescription: String // e.g., "Left segment: 1→√10, Right segment: √10→10"
    let expectedDescription: String // e.g., "Both segments render side-by-side..."
    
    // Validation values
    let expectedBoundaryPosition: CGFloat // e.g., 0.5 for 50%
    let actualBoundaryPosition: CGFloat // actual first tick position
    let actualFirstTickValue: Double
    
    // Dimensions
    let scaleLength: CGFloat
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    
    // MARK: - Computed Properties
    
    /// Scale labels computed from scale properties (DRY)
    private var leftScaleLabel: String { leftScale.previewLabel() }
    private var rightScaleLabel: String { rightScale.previewLabel() }
    
    /// Calculate pass/fail status based on tolerance
    private var isValidationPassed: Bool {
        abs(actualBoundaryPosition - expectedBoundaryPosition) < 0.01
    }
    
    /// Status indicator string
    private var statusIndicator: String {
        isValidationPassed ? "✓ PASS" : "✗ FAIL"
    }
    
    /// Status color
    private var statusColor: Color {
        isValidationPassed ? .green : .red
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Title
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            
            // 2. Segment description
            Text(segmentDescription)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            // 3. Expected description
            Text(expectedDescription)
                .font(.system(size: 12))
                .italic()
                .foregroundColor(.blue)
            
            // 4. Debug card
            debugCard
            
            // 5. Segment labels
            segmentLabels
            
            // 6-8. Scale visualization with boundary tick marks
            VStack(spacing: 0) {
                // 6. Scale name labels (centered above each segment)
                scaleNameLabels
                
                // 7. TOP boundary tick mark
                topBoundaryTick
                
                // 8. Scale visualization
                scaleVisualization
                
                // 9. BOTTOM boundary tick mark
                bottomBoundaryTick
            }
            
            // 10. Dual-unit measurement ruler
            dualUnitRuler
        }
    }
    
    // MARK: - Component Views
    
    /// Debug card with selectable monospace text and pass/fail indicator for BOTH segments
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🔍 Debug Info:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.purple)
            
            // LEFT segment debug info
            let leftFirstTick = leftScale.tickMarks.first
            let leftLastTick = leftScale.tickMarks.last
            let leftDebugText = """
LEFT segment (\(leftScale.definition.name)):
  Domain: \(String(format: "%.3f", leftScale.definition.beginValue)) → \(String(format: "%.3f", leftScale.definition.endValue))
  First tick: value=\(String(format: "%.4f", leftFirstTick?.value ?? 0)), pos=\(String(format: "%.4f", leftFirstTick?.normalizedPosition ?? 0))
  Last tick: value=\(String(format: "%.4f", leftLastTick?.value ?? 0)), pos=\(String(format: "%.4f", leftLastTick?.normalizedPosition ?? 0))
  Expected: pos 0.00→0.50 (left half)
"""
            
            Text(leftDebugText)
                .font(.system(size: 10, weight: .medium).monospaced())
                .foregroundColor(Color(red: 0.0, green: 0.5, blue: 0.2))  // Darker vivid green for readability
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.0, green: 0.7, blue: 0.3).opacity(0.2))  // Tinted green background
                .cornerRadius(4)
            
            // RIGHT segment debug info
            let rightFirstTick = rightScale.tickMarks.first
            let rightLastTick = rightScale.tickMarks.last
            let rightDebugText = """
RIGHT segment (\(rightScale.definition.name)):
  Domain: \(String(format: "%.3f", rightScale.definition.beginValue)) → \(String(format: "%.3f", rightScale.definition.endValue))
  First tick: value=\(String(format: "%.4f", rightFirstTick?.value ?? 0)), pos=\(String(format: "%.4f", rightFirstTick?.normalizedPosition ?? 0))
  Last tick: value=\(String(format: "%.4f", rightLastTick?.value ?? 0)), pos=\(String(format: "%.4f", rightLastTick?.normalizedPosition ?? 0))
  Expected: pos 0.50→1.00 (right half)
"""
            
            Text(rightDebugText)
                .font(.system(size: 10, weight: .medium).monospaced())
                .foregroundColor(Color(red: 0.8, green: 0.35, blue: 0.0))  // Darker vivid orange for readability
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.2))  // Tinted orange background
                .cornerRadius(4)
            
            // Validation summary
            let leftPassed = (leftLastTick?.normalizedPosition ?? 0) <= 0.52 // tolerance for 0.50
            let rightPassed = (rightFirstTick?.normalizedPosition ?? 0) >= 0.48 // tolerance for 0.50
            let leftStatus = leftPassed ? "✓" : "✗"
            let rightStatus = rightPassed ? "✓" : "✗"
            let overallPassed = leftPassed && rightPassed
            
            Text("Validation: Left \(leftStatus), Right \(rightStatus) → \(overallPassed ? "✓ PASS" : "✗ FAIL")")
                .font(.system(size: 10, weight: .bold).monospaced())
                .foregroundColor(overallPassed ? .green : .red)
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color.purple.opacity(0.15))
        .cornerRadius(8)
    }
    
    /// Segment labels showing left and right halves
    private var segmentLabels: some View {
        HStack(spacing: 0) {
            Text("← Left half (0-50%) →")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.5, blue: 0.2))  // Darker vivid green
                .frame(width: scaleLength / 2)
            
            Text("← Right half (50-100%) →")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.0))  // Darker vivid orange
                .frame(width: scaleLength / 2)
        }
        .padding(.leading, leftMarginWidth)
    }
    
    /// Top boundary tick mark (red, touching top edge of scale area)
    private var topBoundaryTick: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: leftMarginWidth + (actualBoundaryPosition * scaleLength) - 0.5)
            Rectangle()
                .fill(Color.red)
                .frame(width: 1, height: 10)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Scale name labels centered above each segment (e.g., "C - x")
    private var scaleNameLabels: some View {
        HStack(spacing: 0) {
            Text(leftScaleLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
                .frame(width: scaleLength / 2)
            
            Text(rightScaleLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
                .frame(width: scaleLength / 2)
        }
        .padding(.leading, leftMarginWidth)
    }
    
    /// Main scale visualization with colored backgrounds
    private var scaleVisualization: some View {
        ZStack(alignment: .leading) {
            // Background colors with HIGH contrast visibility
            HStack(spacing: 0) {
                Color(red: 0.0, green: 0.7, blue: 0.3).opacity(0.45)  // Vivid green
                    .frame(width: scaleLength / 2, height: scaleHeight)
                Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.45)  // Vivid orange
                    .frame(width: scaleLength / 2, height: scaleHeight)
            }
            .padding(.leading, leftMarginWidth)
            
            // Left segment
            ScaleView(
                generatedScale: leftScale
            )
            
            // Right segment
            ScaleView(
                generatedScale: rightScale
            )
        }
        .environment(\.dimensions, Dimensions(
            width: scaleLength,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth,
            tier: .extraLarge
        ))
        .frame(height: scaleHeight)
    }
    
    /// Bottom boundary tick mark (blue, touching bottom edge of scale area)
    private var bottomBoundaryTick: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: leftMarginWidth + (actualBoundaryPosition * scaleLength) - 0.5)
            Rectangle()
                .fill(Color.blue)
                .frame(width: 1, height: 10)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Dual-unit measurement ruler (percentage + SwiftUI points)
    private var dualUnitRuler: some View {
        ZStack(alignment: .leading) {
            // Horizontal baseline
            Rectangle()
                .fill(Color.gray)
                .frame(width: scaleLength, height: 1)
                .offset(x: leftMarginWidth)
            
            // Tick marks every 5%
            ForEach(0..<21) { i in
                let percentage = Double(i) * 5.0
                let xPos = leftMarginWidth + (scaleLength * CGFloat(percentage / 100.0))
                let pointValue = scaleLength * CGFloat(percentage / 100.0)
                let tickHeight: CGFloat = (i % 2 == 0) ? 12 : 8
                
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1, height: tickHeight)
                    
                    // Show percentage at every 25%
                    if i % 5 == 0 {
                        Text("\(Int(percentage))%")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                        
                        Text("\(Int(pointValue))pt")
                            .font(.system(size: 7))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                .offset(x: xPos)
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Preview

#Preview("Simple C Scale 50/50 Split") {
    GeometryReader { geometry in
        let scaleLength: CGFloat = geometry.size.width  // Full width, edge-to-edge
        let scaleHeight: CGFloat = 40
        let leftMarginWidth: CGFloat = 0  // No left margin
        let rightMarginWidth: CGFloat = 0  // No right margin
        
        // Left half: C scale from 1 to √10
        let cScaleLeft: GeneratedScale = {
            let cBuilder = ScaleBuilder()
                .withName("C₁")  // Name for previewLabel()
                .withFormula("x")  // Formula for previewLabel()
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: 3.162)
                .withLength(scaleLength)
                .withTickDirection(.up)
                .withSplitSegment(.left(formulaOffset: 0.0))
                .suppressScaleName()  // Don't render name on scale (shown in preview label)
                .suppressFormula()    // Don't render formula on scale (shown in preview label)
            
            let standardC = StandardScales.cScale(length: scaleLength)
            let cDef = cBuilder
                .withSubsections(standardC.subsections)
                .withLabelFormatter(StandardLabelFormatter.cScaleFirstSubsection)
                .build()
            
            return GeneratedScale(definition: cDef)
        }()
        
        // Right half: C scale from √10 to 10
        let cScaleRight: GeneratedScale = {
            let cBuilder = ScaleBuilder()
                .withName("C₂")  // Name for previewLabel()
                .withFormula("x")  // Formula for previewLabel()
                .withFunction(LogarithmicFunction())
                .withRange(begin: 3.162, end: 10.0)
                .withLength(scaleLength)
                .withTickDirection(.up)
                .withSplitSegment(.right(formulaOffset: 0.0))
                .suppressScaleName()  // Don't render name on scale (shown in preview label)
                .suppressFormula()    // Don't render formula on scale (shown in preview label)
            
            let standardC = StandardScales.cScale(length: scaleLength)
            let cDef = cBuilder
                .withSubsections(standardC.subsections)
                .withLabelFormatter(StandardLabelFormatter.cScaleFirstSubsection)
                .build()
            
            return GeneratedScale(definition: cDef)
        }()
        
        SplitScaleTestComponent(
            leftScale: cScaleLeft,
            rightScale: cScaleRight,
            title: "Test Case 1: Simple C Scale 50/50 Split",
            segmentDescription: "Left segment: 1→√10 (left half), Right segment: √10→10 (right half)",
            expectedDescription: "Expected: Both segments render side-by-side in same physical space, each using 50% width",
            expectedBoundaryPosition: 0.5,
            actualBoundaryPosition: cScaleRight.tickMarks.first?.normalizedPosition ?? 0.0,
            actualFirstTickValue: cScaleRight.tickMarks.first?.value ?? 0.0,
            scaleLength: scaleLength,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth
        )
    }
}
