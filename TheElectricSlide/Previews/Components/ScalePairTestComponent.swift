//  TheElectricSlide
//
//  Reusable SwiftUI preview component for testing paired scale rendering
//  Displays vertically stacked scales with debug information and boundary markers
//

import SwiftUI
import SlideRuleCoreV3

/// A reusable component for visualizing and validating paired scale rendering
/// with boundary markers at start (0%) and end (100%) of each scale.
struct ScalePairTestComponent: View {
    // MARK: - Properties
    
    // Scale definitions to display (can be 1 or more)
    let scales: [GeneratedScale]
    
    // Test case metadata
    let title: String
    let description: String
    
    // Dimensions
    let scaleLength: CGFloat
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let stackSpacing: CGFloat // Spacing between scales (default 4pt)
    
    // MARK: - Initialization
    
    init(
        scales: [GeneratedScale],
        title: String,
        description: String,
        scaleLength: CGFloat,
        scaleHeight: CGFloat,
        leftMarginWidth: CGFloat,
        rightMarginWidth: CGFloat,
        stackSpacing: CGFloat = 4
    ) {
        self.scales = scales
        self.title = title
        self.description = description
        self.scaleLength = scaleLength
        self.scaleHeight = scaleHeight
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
        self.stackSpacing = stackSpacing
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Title
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            
            // 2. Description
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            // 3. Debug card
            debugCard
            
            // 4. Scale stack with boundary markers
            VStack(spacing: stackSpacing) {
                ForEach(Array(scales.enumerated()), id: \.offset) { index, scale in
                    scaleWithBoundaries(scale: scale, isLast: index == scales.count - 1)
                }
            }
            
            // 5. Dual-unit measurement ruler (only shown once at bottom)
            dualUnitRuler
        }
    }
    
    // MARK: - Component Views
    
    /// Debug card with scale information
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🔍 Debug Info:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.purple)
            
            let debugText = scales.enumerated().map { index, scale in
                let direction = scale.definition.tickDirection == .up ? "upward" : "downward"
                return "Scale \(index + 1): \(scale.definition.name) (\(direction) ticks) - Range: \(String(format: "%.4f", scale.definition.beginValue)) → \(String(format: "%.4f", scale.definition.endValue))"
            }.joined(separator: "\n")
            
            Text(debugText)
                .font(.system(size: 10, weight: .medium).monospaced())
                .foregroundColor(.primary)
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
    
    /// Individual scale with boundary markers at 0% (red) and 100% (blue)
    private func scaleWithBoundaries(scale: GeneratedScale, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            // Top boundary tick mark (red at 0%)
            boundaryTick(at: 0.0, color: .red)
            
            // Scale visualization
            ScaleView(
                generatedScale: scale,
                width: scaleLength,
                height: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                nameFont: .system(size: 14, weight: .medium).monospacedDigit(),
                formulaFont: .system(size: 12).monospacedDigit()
            )
            .frame(height: scaleHeight)
            
            // Bottom boundary tick mark (blue at 100%)
            boundaryTick(at: 1.0, color: .blue)
        }
    }
    
    /// Boundary tick mark at specified position (0.0 = start, 1.0 = end)
    private func boundaryTick(at position: CGFloat, color: Color) -> some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: leftMarginWidth + (position * scaleLength) - 0.5)
            Rectangle()
                .fill(color)
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

#Preview("LL00 + C Scale Pair") {
    let scaleLength: CGFloat = 800
    let scaleHeight: CGFloat = 40
    let leftMarginWidth: CGFloat = 60
    let rightMarginWidth: CGFloat = 80
    
    // LL00 scale with upward ticks
    let ll00Scale = GeneratedScale(
        definition: StandardScales.ll00Scale(length: scaleLength)
    )
    
    // C scale with downward ticks
    let cScale: GeneratedScale = {
        let cBuilder = ScaleBuilder()
            .withName("C")
            .withFormula("x")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(scaleLength)
            .withTickDirection(.down)
        
        let standardC = StandardScales.cScale(length: scaleLength)
        let cDef = cBuilder
            .withSubsections(standardC.subsections)
            .withLabelFormatter(StandardLabelFormatter.cScaleFirstSubsection)
            .build()
        
        return GeneratedScale(definition: cDef)
    }()
    
    return ScalePairTestComponent(
        scales: [ll00Scale, cScale],
        title: "Scale Pair: LL00 + C",
        description: "LL00 (upward ticks) paired with C scale (downward ticks)",
        scaleLength: scaleLength,
        scaleHeight: scaleHeight,
        leftMarginWidth: leftMarginWidth,
        rightMarginWidth: rightMarginWidth
    )
    .padding()
}
