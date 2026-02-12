//  TheElectricSlide
//
//  Visual test preview for split scale rendering (Phase 4)
//  Tests split segment functionality with real scales showing fractional physical ranges
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Split Scales Visual Test Preview

/// Preview displaying split scale rendering tests for Phase 4 implementation
/// Shows multiple test cases demonstrating split segment functionality with real scale data
struct SplitScalesPreview: View {
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
    
    // MARK: - Test Case 1: Simple C Scale 50/50 Split
    
    // Left half: C scale from 1 to √10
    private var cScaleLeft: GeneratedScale {
        let cBuilder = ScaleBuilder()
            .withName("C₁")  // Name for previewLabel()
            .withFormula("x")  // Formula for previewLabel()
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 3.162)  // √10 ≈ 3.162
            .withLength(scaleLength)
            .withTickDirection(.up)
            .withSuppressScaleNameLabel()
            .withSuppressFormulaLabel()
            .withSplitSegment(.left(formulaOffset: 0.0))
        
        let standardC = StandardScales.cScale(length: scaleLength)
        let cDef = cBuilder
            .withSubsections(standardC.subsections)
            .withLabelFormatter(StandardLabelFormatter.cScaleFirstSubsection)
            .build()
        
        return GeneratedScale(definition: cDef)
    }
    
    // Right half: C scale from √10 to 10 (NO formula offset needed)
    private var cScaleRight: GeneratedScale {
        let cBuilder = ScaleBuilder()
            .withName("C₂")  // Name for previewLabel()
            .withFormula("x")  // Formula for previewLabel()
            .withSuppressScaleNameLabel()
            .withSuppressFormulaLabel()
            .withFunction(LogarithmicFunction())
            .withRange(begin: 3.162, end: 10.0)  // √10 to 10
            .withLength(scaleLength)
            .withTickDirection(.up)
            .withSplitSegment(.right(formulaOffset: 0.0))  // FIX: Changed from -1.0 to 0.0
        
        let standardC = StandardScales.cScale(length: scaleLength)
        let cDef = cBuilder
            .withSubsections(standardC.subsections)
            .withLabelFormatter(StandardLabelFormatter.cScaleFirstSubsection)
            .build()
        
        return GeneratedScale(definition: cDef)
    }
    
    // MARK: - Test Case 2: Hemmi 266 LL01^ LL02B Pattern
    
    // H266LL01: domain 0.90→0.99, left half (reciprocal log-log)
    private var hemmi266LL01: GeneratedScale {
        let h266LL01Def = StandardScales.h266LL01Scale(length: scaleLength)
        
        // Apply left split segment
        let modifiedDef = ScaleDefinition(
            name: h266LL01Def.name,
            formula: h266LL01Def.formula,
            function: h266LL01Def.function,
            beginValue: h266LL01Def.beginValue,
            endValue: h266LL01Def.endValue,
            scaleLengthInPoints: h266LL01Def.scaleLengthInPoints,
            layout: h266LL01Def.layout,
            tickDirection: h266LL01Def.tickDirection,
            subsections: h266LL01Def.subsections,
            defaultTickStyles: h266LL01Def.defaultTickStyles,
            labelFormatter: h266LL01Def.labelFormatter,
            labelColor: h266LL01Def.labelColor,
            constants: h266LL01Def.constants,
            splitSegment: .left(formulaOffset: 0.0)
        )
        
        return GeneratedScale(definition: modifiedDef)
    }
    
    // LL02B: domain 0.00005→0.904, right half (reciprocal log-log)
    private var ll02B: GeneratedScale {
        let ll02BDef = StandardScales.ll02BScale(length: scaleLength)
        
        // Apply right split segment
        let modifiedDef = ScaleDefinition(
            name: ll02BDef.name,
            formula: ll02BDef.formula,
            function: ll02BDef.function,
            beginValue: ll02BDef.beginValue,
            endValue: ll02BDef.endValue,
            scaleLengthInPoints: ll02BDef.scaleLengthInPoints,
            layout: ll02BDef.layout,
            tickDirection: ll02BDef.tickDirection,
            subsections: ll02BDef.subsections,
            defaultTickStyles: ll02BDef.defaultTickStyles,
            labelFormatter: ll02BDef.labelFormatter,
            labelColor: ll02BDef.labelColor,
            constants: ll02BDef.constants,
            splitSegment: .right(formulaOffset: 0.0)
        )
        
        return GeneratedScale(definition: modifiedDef)
    }
    
    // MARK: - Test Case 3: Hyperbolic Sh1/Sh2 Pattern
    
    // Sh1: sinh(x)×10, domain 0.1→0.90, left half
    private var sh1Left: GeneratedScale {
        let sh1Def = StandardScales.sh1Scale(length: scaleLength)
        
        // Apply left split segment
        let modifiedDef = ScaleDefinition(
            name: sh1Def.name,
            formula: sh1Def.formula,
            function: sh1Def.function,
            beginValue: sh1Def.beginValue,
            endValue: sh1Def.endValue,
            scaleLengthInPoints: sh1Def.scaleLengthInPoints,
            layout: sh1Def.layout,
            tickDirection: sh1Def.tickDirection,
            subsections: sh1Def.subsections,
            defaultTickStyles: sh1Def.defaultTickStyles,
            labelFormatter: sh1Def.labelFormatter,
            labelColor: sh1Def.labelColor,
            constants: sh1Def.constants,
            splitSegment: .left(formulaOffset: 0.0)
        )
        
        return GeneratedScale(definition: modifiedDef)
    }
    
    // Sh2: sinh(x)×10, domain 0.88→3, right half
    // NOTE: Sh2 function already has offset=1.0 built-in (sinh(x-1))
    // So NO additional formula offset needed in splitSegment
    private var sh2Right: GeneratedScale {
        let sh2Def = StandardScales.sh2Scale(length: scaleLength)
        
        // Apply right split segment WITHOUT formula offset
        let modifiedDef = ScaleDefinition(
            name: sh2Def.name,
            formula: sh2Def.formula,
            function: sh2Def.function,
            beginValue: sh2Def.beginValue,
            endValue: sh2Def.endValue,
            scaleLengthInPoints: sh2Def.scaleLengthInPoints,
            layout: sh2Def.layout,
            tickDirection: sh2Def.tickDirection,
            subsections: sh2Def.subsections,
            defaultTickStyles: sh2Def.defaultTickStyles,
            labelFormatter: sh2Def.labelFormatter,
            labelColor: sh2Def.labelColor,
            constants: sh2Def.constants,
            splitSegment: .right(formulaOffset: 0.0)  // FIX: Changed from -1.0 to 0.0
        )
        
        return GeneratedScale(definition: modifiedDef)
    }
    
    // MARK: - Test Case 4: Parser Integration Test
    
    // Parse definition string with split scales
    private var parserTestScales: [GeneratedScale] {
        // Simple test: A^ B C
        // A^: Left split segment (^ means split)
        // B: Full scale
        // C: Full scale
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        do {
            let rule = try RuleDefinitionParser.parse(
                "A^ B C",
                dimensions: dimensions,
                scaleLength: scaleLength
            )
            return rule.frontTopStator.scales
        } catch {
            // Return empty array on error
            return []
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Title
                Text("Split Scales Visual Test Preview")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.bottom, 8)
                
                Text("Phase 4: Visual verification of split scale rendering with fractional physical ranges")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                
                // Test Case 1: Simple C Scale Split
                testCase1Section
                
                Divider()
                
                // Test Case 2: Hemmi 266 Pattern
                testCase2Section
                
                Divider()
                
                // Test Case 3: Hyperbolic Sh1/Sh2 Pattern
                testCase3Section
                
                Divider()
                
                // Test Case 4: Parser Integration
                testCase4Section
            }
            .padding()
        }
    }
    
    // MARK: - Test Case Sections
    
    private var testCase1Section: some View {
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
    
    private var testCase2Section: some View {
        SplitScaleTestComponent(
            leftScale: hemmi266LL01,
            rightScale: ll02B,
            title: "Test Case 2: Hemmi 266 LL01^ LL02B Pattern",
            segmentDescription: "H266LL01^: 0.90→0.99 (left), LL02B: 0.00005→0.904 (right)",
            expectedDescription: "Expected: Reciprocal log-log scales split across same row, red labels",
            expectedBoundaryPosition: 0.5,
            actualBoundaryPosition: ll02B.tickMarks.first?.normalizedPosition ?? 0.0,
            actualFirstTickValue: ll02B.tickMarks.first?.value ?? 0.0,
            scaleLength: scaleLength,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth
        )
    }
    
    private var testCase3Section: some View {
        SplitScaleTestComponent(
            leftScale: sh1Left,
            rightScale: sh2Right,
            title: "Test Case 3: Hyperbolic Sh1/Sh2 Pattern",
            segmentDescription: "Sh1: 0.1→0.90 (left), Sh2: 0.88→3 (right with offset)",
            expectedDescription: "Expected: Natural overlap at 0.88-0.90 boundary, smooth transition",
            expectedBoundaryPosition: 0.5,
            actualBoundaryPosition: sh2Right.tickMarks.first?.normalizedPosition ?? 0.0,
            actualFirstTickValue: sh2Right.tickMarks.first?.value ?? 0.0,
            scaleLength: scaleLength,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth
        )
    }
    
    private var testCase4Section: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Test Case 4: Parser Integration Test")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Definition: \"A^ B C\" (A with ^ operator, plus two full scales)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Expected: Parser recognizes ^ operator, applies split segment, renders three scales")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(.blue)
            }
            
            // Debug info card
            VStack(alignment: .leading, spacing: 8) {
                Text("Parser Output:")
                    .font(.system(size: 12, weight: .semibold))
                
                ForEach(Array(parserTestScales.enumerated()), id: \.offset) { index, scale in
                    HStack(spacing: 8) {
                        Text("Scale \(index + 1):")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(scale.definition.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if let split = scale.definition.splitSegment {
                            switch split {
                            case .left:
                                Text("(LEFT SPLIT)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                            case .right:
                                Text("(RIGHT SPLIT)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        } else {
                            Text("(FULL)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("• Range: \(String(format: "%.3f", scale.definition.beginValue))→\(String(format: "%.3f", scale.definition.endValue))")
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
            
            // Render parsed scales
            VStack(spacing: 1) {
                ForEach(Array(parserTestScales.enumerated()), id: \.offset) { index, scale in
                    ScaleView(
                        generatedScale: scale
                    )
                    .frame(height: scaleHeight)
                }
            }
            .environment(\.dimensions, Dimensions(
                width: scaleLength,
                scaleHeight: scaleHeight,
                leftMarginWidth: leftMarginWidth,
                rightMarginWidth: rightMarginWidth,
                tier: .extraLarge
            ))
        }
    }
}

// MARK: - SwiftUI Previews

#Preview("Default Configuration") {
    SplitScalesPreview()
        .frame(height: 1000)
        .preferredColorScheme(.light)
}

#Preview("Light Mode") {
    SplitScalesPreview(
        scaleLength: 800
    )
    .frame(height: 1000)
    .preferredColorScheme(.light)
}

#Preview("Compact (iPhone)") {
    SplitScalesPreview(
        scaleLength: 600,
        scaleHeight: 35,
        leftMarginWidth: 50,
        rightMarginWidth: 60,
        nameFontSize: 12,
        formulaFontSize: 10
    )
    .frame(height: 1000)
    .preferredColorScheme(.light)
}

#Preview("Large (iPad)") {
    SplitScalesPreview(
        scaleLength: 1000,
        scaleHeight: 50,
        leftMarginWidth: 70,
        rightMarginWidth: 100,
        nameFontSize: 16,
        formulaFontSize: 14
    )
    .frame(height: 1000)
    .preferredColorScheme(.light)
}

#Preview("High Precision") {
    SplitScalesPreview(
        scaleLength: 1200,
        scaleHeight: 60
    )
    .frame(height: 1000)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SplitScalesPreview(
        scaleLength: 800,
        scaleHeight: 40
    )
    .frame(height: 1000)
    .preferredColorScheme(.dark)
}

