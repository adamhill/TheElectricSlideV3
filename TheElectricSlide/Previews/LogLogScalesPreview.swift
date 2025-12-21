//
//  LogLogScalesPreview.swift
//  TheElectricSlide
//
//  MINIMAL TEST CONFIGURATION for troubleshooting preview rendering issues
//  Shows only TWO scales: LL00 (reciprocal) and LL0 (positive) with C reference scales
//  This configuration isolates potential build/linking issues by reducing complexity
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Faber-Castell 62/83 N Log-Log Scales Preview (Minimal)

/// Preview displaying minimal LL scale configuration for troubleshooting
/// Layout from top to bottom: LL00 (RED reciprocal), C, LL0 (BLACK positive), C
struct LogLogScalesPreview: View {
    // MARK: - Properties
    
    let scaleLength: CGFloat
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFontSize: CGFloat
    let formulaFontSize: CGFloat
    
    // MARK: - Initialization
    
    init(
        scaleLength: CGFloat = 800,
        scaleHeight: CGFloat = 40,
        leftMarginWidth: CGFloat = 60,
        rightMarginWidth: CGFloat = 80,
        nameFontSize: CGFloat = 14,
        formulaFontSize: CGFloat = 12
    ) {
        self.scaleLength = scaleLength
        self.scaleHeight = scaleHeight
        self.leftMarginWidth = leftMarginWidth
        self.rightMarginWidth = rightMarginWidth
        self.nameFontSize = nameFontSize
        self.formulaFontSize = formulaFontSize
    }
    
    // MARK: - Generated Scales (Minimal Configuration)
    
    /* COMMENTED OUT FOR MINIMAL TEST - LL03 Reciprocal Scale
    private var ll03: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll03Scale(length: scaleLength))
    }
    */
    
    /* COMMENTED OUT FOR MINIMAL TEST - LL02 Reciprocal Scale
    private var ll02: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll02Scale(length: scaleLength))
    }
    */
    
    /* COMMENTED OUT FOR MINIMAL TEST - LL01 Reciprocal Scale
    private var ll01: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll01Scale(length: scaleLength))
    }
    */
    
    // LL00: RED reciprocal scale (e^-0.01 to e^-0.001)
    private var ll00: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll00Scale(length: scaleLength))
    }
    
    // LL0: BLACK positive scale (e^0.001 to e^0.01)
    private var ll0: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll0Scale(length: scaleLength))
    }
    
    /* COMMENTED OUT FOR MINIMAL TEST - LL1 Positive Scale
    private var ll1: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll1Scale(length: scaleLength))
    }
    */
    
    /* COMMENTED OUT FOR MINIMAL TEST - LL2 Positive Scale
    private var ll2: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll2Scale(length: scaleLength))
    }
    */
    
    /* COMMENTED OUT FOR MINIMAL TEST - LL3 Positive Scale
    private var ll3: GeneratedScale {
        GeneratedScale(definition: StandardScales.ll3Scale(length: scaleLength))
    }
    */
    
    // C scale with downward ticks for reference
    private var cWithDownTicks: GeneratedScale {
        let cBuilder = ScaleBuilder()
            .withName("C")
            .withFormula("x")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(scaleLength)
            .withTickDirection(.down)
        
        // Copy subsections from standard C scale
        let standardC = StandardScales.cScale(length: scaleLength)
        let cDef = cBuilder
            .withSubsections(standardC.subsections)
            .withLabelFormatter(StandardLabelFormatter.cScaleFirstSubsection)
            .build()
        
        return GeneratedScale(definition: cDef)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                // Title
                Text("Minimal Log-Log Preview: LL00 + LL0")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 24)
                
                // Minimal scale layout: LL00, C, LL0, C (4 scales total with 1pt spacing)
                VStack(spacing: 1) {
                    // LL00 (RED reciprocal)
                    ScaleView(
                        generatedScale: ll00,
                        width: scaleLength,
                        height: scaleHeight,
                        leftMarginWidth: leftMarginWidth,
                        rightMarginWidth: rightMarginWidth,
                        nameFont: .system(size: nameFontSize, weight: .medium).monospacedDigit(),
                        formulaFont: .system(size: formulaFontSize).monospacedDigit()
                    )
                    .frame(height: scaleHeight)
                    
                    // C reference (downward ticks)
                    ScaleView(
                        generatedScale: cWithDownTicks,
                        width: scaleLength,
                        height: scaleHeight,
                        leftMarginWidth: leftMarginWidth,
                        rightMarginWidth: rightMarginWidth,  // Hide formula
                        nameFont: .system(size: nameFontSize, weight: .medium).monospacedDigit(),
                        formulaFont: .system(size: formulaFontSize).monospacedDigit()
                    )
                    .frame(height: scaleHeight)
                    
                    // LL0 (BLACK positive)
                    ScaleView(
                        generatedScale: ll0,
                        width: scaleLength,
                        height: scaleHeight,
                        leftMarginWidth: leftMarginWidth,
                        rightMarginWidth: rightMarginWidth,
                        nameFont: .system(size: nameFontSize, weight: .medium).monospacedDigit(),
                        formulaFont: .system(size: formulaFontSize).monospacedDigit()
                    )
                    .frame(height: scaleHeight)
                    
                    // C reference (downward ticks)
                    ScaleView(
                        generatedScale: cWithDownTicks,
                        width: scaleLength,
                        height: scaleHeight,
                        leftMarginWidth: leftMarginWidth,
                        rightMarginWidth: rightMarginWidth,  // Hide formula
                        nameFont: .system(size: nameFontSize, weight: .medium).monospacedDigit(),
                        formulaFont: .system(size: formulaFontSize).monospacedDigit()
                    )
                    .frame(height: scaleHeight)
                    
                    /* COMMENTED OUT FOR MINIMAL TEST - Additional LL Scales
                    
                    // LL01, C pair
                    ScaleView(...)
                    ScaleView(...)
                    
                    // LL02, C pair
                    ScaleView(...)
                    ScaleView(...)
                    
                    // LL03, C pair
                    ScaleView(...)
                    ScaleView(...)
                    
                    // LL1, C pair
                    ScaleView(...)
                    ScaleView(...)
                    
                    // LL2, C pair
                    ScaleView(...)
                    ScaleView(...)
                    
                    // LL3, C pair
                    ScaleView(...)
                    ScaleView(...)
                    
                    */
                }
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
        rightMarginWidth: 60,
        nameFontSize: 12,
        formulaFontSize: 10
    )
    .preferredColorScheme(.light)
}

#Preview("Large (iPad)") {
    LogLogScalesPreview(
        scaleLength: 1000,
        scaleHeight: 50,
        leftMarginWidth: 70,
        rightMarginWidth: 100,
        nameFontSize: 16,
        formulaFontSize: 14
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
