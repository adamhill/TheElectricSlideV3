//  TheElectricSlide
//
//  Reusable SwiftUI preview component for testing split scale rendering
//  with enhanced visual debugging and validation features
//

import SwiftUI
import SlideRuleCoreV3

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
                // 6. TOP boundary tick mark
                topBoundaryTick
                
                // 7. Scale visualization
                scaleVisualization
                
                // 8. BOTTOM boundary tick mark
                bottomBoundaryTick
            }
            
            // 9. Dual-unit measurement ruler
            dualUnitRuler
        }
    }
    
    // MARK: - Component Views
    
    /// Debug card with selectable monospace text and pass/fail indicator
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🔍 Debug Info:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.purple)
            
            let debugText = """
Right segment domain: \(String(format: "%.3f", rightScale.definition.beginValue)) → \(String(format: "%.1f", rightScale.definition.endValue))
First tick value: \(String(format: "%.4f", actualFirstTickValue))
First tick position: \(String(format: "%.4f", actualBoundaryPosition)) (expected: \(String(format: "%.2f", expectedBoundaryPosition)))
Status: \(statusIndicator)
"""
            
            Text(debugText)
                .font(.system(size: 10, weight: .medium).monospaced())
                .foregroundColor(statusColor)
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.5))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.purple.opacity(0.15))
        .cornerRadius(8)
    }
    
    /// Segment labels showing left and right halves
    private var segmentLabels: some View {
        HStack(spacing: 0) {
            Text("← Left half (0-50%) →")
                .font(.system(size: 10))
                .foregroundColor(.green)
                .frame(width: scaleLength / 2)
            
            Text("← Right half (50-100%) →")
                .font(.system(size: 10))
                .foregroundColor(.orange)
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
    
    /// Main scale visualization with colored backgrounds
    private var scaleVisualization: some View {
        ZStack(alignment: .leading) {
            // Background colors with improved visibility
            HStack(spacing: 0) {
                Color.green.opacity(0.25)
                    .frame(width: scaleLength / 2, height: scaleHeight)
                Color.orange.opacity(0.25)
                    .frame(width: scaleLength / 2, height: scaleHeight)
            }
            .padding(.leading, leftMarginWidth)
            
            // Left segment
            ScaleView(
                generatedScale: leftScale,
                width: scaleLength,
                height: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: .system(size: 14, weight: .medium).monospacedDigit(),
                formulaFont: .system(size: 12).monospacedDigit()
            )
            
            // Right segment
            ScaleView(
                generatedScale: rightScale,
                width: scaleLength,
                height: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: .system(size: 14, weight: .medium).monospacedDigit(),
                formulaFont: .system(size: 12).monospacedDigit()
            )
        }
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
    let scaleLength: CGFloat = 800
    let scaleHeight: CGFloat = 40
    let leftMarginWidth: CGFloat = 60
    let rightMarginWidth: CGFloat = 80
    
    // Left half: C scale from 1 to √10
    let cScaleLeft: GeneratedScale = {
        let cBuilder = ScaleBuilder()
            .withName("C√10")
            .withFormula("x (left)")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 3.162)
            .withLength(scaleLength)
            .withTickDirection(.up)
            .withSplitSegment(.left(formulaOffset: 0.0))
        
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
            .withName("C√10-10")
            .withFormula("x (right)")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 3.162, end: 10.0)
            .withLength(scaleLength)
            .withTickDirection(.up)
            .withSplitSegment(.right(formulaOffset: 0.0))
        
        let standardC = StandardScales.cScale(length: scaleLength)
        let cDef = cBuilder
            .withSubsections(standardC.subsections)
            .withLabelFormatter(StandardLabelFormatter.cScaleFirstSubsection)
            .build()
        
        return GeneratedScale(definition: cDef)
    }()
    
    return SplitScaleTestComponent(
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
    .padding()
}
