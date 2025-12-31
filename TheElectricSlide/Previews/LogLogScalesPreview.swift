//
//  LogLogScalesPreview.swift
//  TheElectricSlide
//
//  Preview of paired Log-Log scales using ScalePairTestComponent
//  Shows LL00 + C and LL0 + C scale pairs with boundary markers and debug info
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Faber-Castell 62/83 N Log-Log Scales Preview

/// Preview displaying LL scale pairs: LL00+C and LL0+C
struct LogLogScalesPreview: View {
    // MARK: - Properties
    
    let scaleLength: CGFloat
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    
    // MARK: - Initialization
    
    init(
        scaleLength: CGFloat = 800,
        scaleHeight: CGFloat = 40,
        leftMarginWidth: CGFloat = 60,
        rightMarginWidth: CGFloat = 80
    ) {
        self.scaleLength = scaleLength
        self.scaleHeight = scaleHeight
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
    }
    
    // MARK: - Generated Scales
    
    // LL00: RED reciprocal scale (e^-0.01 to e^-0.001)
    private var ll00: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll00Scale(length: scaleLength))
    }
    
    // LL0: BLACK positive scale (e^0.001 to e^0.01)
    private var ll0: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll0Scale(length: scaleLength))
    }
    
    // C scale with downward ticks for reference
    private var cWithDownTicks: GeneratedScale {
        let cDef = ScaleBuilder(from: StandardScales.cScale(length: scaleLength))
            .withTickDirection(.down)
            .build()
        return GeneratedScale(definition: cDef)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                // Title
                Text("Log-Log Scale Pairs Preview")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 12)
                
                // Pair 1: LL00 + C
                ScalePairTestComponent(
                    scales: [ll00, cWithDownTicks],
                    title: "Pair 1: LL00 + C",
                    description: "LL00 (upward ticks) paired with C scale (downward ticks)",
                    scaleLength: scaleLength,
                    scaleHeight: scaleHeight,
                    leftMarginWidth: leftMarginWidth,
                    rightMarginWidth: rightMarginWidth
                )
                
                // Pair 2: LL0 + C
                ScalePairTestComponent(
                    scales: [ll0, cWithDownTicks],
                    title: "Pair 2: LL0 + C",
                    description: "LL0 (upward ticks) paired with C scale (downward ticks)",
                    scaleLength: scaleLength,
                    scaleHeight: scaleHeight,
                    leftMarginWidth: leftMarginWidth,
                    rightMarginWidth: rightMarginWidth
                )
            }
            .padding()
        }
    }
}

// MARK: - SwiftUI Previews (All Six Variants Maintained)

#Preview("Default Configuration") {
    LogLogScalesPreview()
}

#Preview("Light Mode") {
    LogLogScalesPreview(
        scaleLength: 800
    )
    .preferredColorScheme(.light)
}

#Preview("Compact (iPhone)") {
    LogLogScalesPreview(
        scaleLength: 600,
        scaleHeight: 35,
        leftMarginWidth: 50,
        rightMarginWidth: 60
    )
    .preferredColorScheme(.light)
}

#Preview("Large (iPad)") {
    LogLogScalesPreview(
        scaleLength: 1000,
        scaleHeight: 50,
        leftMarginWidth: 70,
        rightMarginWidth: 100
    )
    .preferredColorScheme(.light)
}

#Preview("High Precision") {
    LogLogScalesPreview(
        scaleLength: 1200,
        scaleHeight: 60
    )
    .preferredColorScheme(.light)
}
