//
//  ContentView.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/18/25.
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - ScaleView Component

struct ScaleView: View {
    let scaleDefinition: ScaleDefinition
    let width: CGFloat
    let height: CGFloat
    let scaleName: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Scale name label on the left
            Text(scaleDefinition.name)
                .font(.caption2)
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 20)
            
            // Scale view
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Tick marks and labels
                    Canvas { context, size in
                        let tickMarks = ScaleCalculator.generateTickMarks(
                            for: scaleDefinition,
                            algorithm: .modulo(config: ModuloTickConfig.default) )
                        
                        // Draw baseline if enabled
                        if scaleDefinition.showBaseline {
                            let baselinePath = Path { path in
                                switch scaleDefinition.tickDirection {
                                case .down:
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: size.width, y: 0))
                                case .up:
                                    path.move(to: CGPoint(x: 0, y: size.height))
                                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                                }
                            }
                            
                            context.stroke(
                                baselinePath,
                                with: .color(.black),
                                lineWidth: 2.0
                            )
                        }
                        
                        for tick in tickMarks {
                            // Calculate horizontal position
                            let xPos = tick.normalizedPosition * size.width
                            
                            // Calculate tick height based on relativeLength
                            let tickHeight = tick.style.relativeLength * (size.height * 0.6)
                            
                            // Calculate tick start and end positions based on direction
                            let (tickStartY, tickEndY): (CGFloat, CGFloat)
                            switch scaleDefinition.tickDirection {
                            case .down:
                                tickStartY = 0
                                tickEndY = tickHeight
                            case .up:
                                tickStartY = size.height
                                tickEndY = size.height - tickHeight
                            }
                            
                            // Draw tick mark (vertical line) with anti-aliasing disabled
                            let tickPath = Path { path in
                                path.move(to: CGPoint(x: xPos, y: tickStartY))
                                path.addLine(to: CGPoint(x: xPos, y: tickEndY))
                            }
                            
                            context.withCGContext { cgContext in
                                cgContext.setShouldAntialias(false)
                                context.stroke(
                                    tickPath,
                                    with: .color(.black),
                                    lineWidth: tick.style.lineWidth / 1.5
                                )
                            }
                            
                            // Draw label if present
                            if let labelText = tick.label {
                                let fontSize = fontSizeForTick(tick.style.relativeLength)
                                
                                if fontSize > 0 {
                                    let text = Text(labelText)
                                        .font(.system(size: fontSize))
                                        .foregroundColor(.black)
                                    
                                    let resolvedText = context.resolve(text)
                                    let textSize = resolvedText.measure(in: CGSize(width: 100, height: 100))
                                    
                                    // Position label based on tick direction
                                    let labelY: CGFloat
                                    switch scaleDefinition.tickDirection {
                                    case .down:
                                        // Labels below tick mark
                                        labelY = tickHeight + 2
                                    case .up:
                                        // Labels above tick mark
                                        labelY = size.height - tickHeight - textSize.height - 2
                                    }
                                    let labelX = xPos - textSize.width / 2
                                    
                                    context.draw(
                                        resolvedText,
                                        at: CGPoint(x: labelX + textSize.width / 2, y: labelY + textSize.height / 2)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: width)
            .frame(minHeight: height * 0.8, idealHeight: height, maxHeight: height)
            
            // Formula label on the right
            Text(scaleDefinition.formula)
                .font(.caption2)
                .tracking((scaleDefinition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 40, alignment: .leading)
        }
    }
    
    /// Determine font size based on tick relativeLength
    private func fontSizeForTick(_ relativeLength: Double) -> CGFloat {
        if relativeLength >= 0.9 {
            return 6.0  // Major ticks
        } else if relativeLength >= 0.7 {
            return 4.5  // Medium ticks
        } else if relativeLength >= 0.4 {
            return 3.0  // Minor ticks
        } else {
            return 0.0  // Tiny ticks - no label
        }
    }
}

// MARK: - StatorView Component (renders multiple scales)

struct StatorView: View {
    let stator: Stator
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    
    // Calculate total max height based on number of scales
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(stator.scales.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stator.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    scaleDefinition: generatedScale.definition,
                    width: width,
                    height: scaleHeight,
                    scaleName: String(generatedScale.definition.name.characters)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            Group {
                if stator.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - SlideView Component (renders multiple scales)

struct SlideView: View {
    let slide: Slide
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat // Configurable height per scale
    
    // Calculate total max height based on number of scales
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(slide.scales.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(slide.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    scaleDefinition: generatedScale.definition,
                    width: width,
                    height: scaleHeight,
                    scaleName: String(generatedScale.definition.name.characters)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            Group {
                if slide.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var sliderOffset: CGFloat = 0
    
    // Scale height configuration
    private let minScaleHeight: CGFloat = 20   // Minimum height for a scale
    private let idealScaleHeight: CGFloat = 25 // Ideal height per scale
    private let maxScaleHeight: CGFloat = 30   // Maximum height per scale
    
    // Target aspect ratio (width:height) for slide rule
    // Slide rules are typically very wide and relatively short (10:1 to 8:1)
    private let targetAspectRatio: CGFloat = 10.0
    
    // Padding around the slide rule
    private let padding: CGFloat = 40
    
    // Parse the slide rule definition using RuleDefinitionParser
    private var slideRule: SlideRule {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        // Parse the rule definition: Multiple scales per component
        // Top stator: L, DF scales
        // Slide: CF-, CIF, DI, CI, C scales
        // Bottom stator: D, A scales
        // Note: scaleLength is a reference value; actual rendering width is responsive
        do {
            return try RuleDefinitionParser.parse(
               // "( L DF [ CF- CIF DI CI C ] D A)",
               "(A [ B L K C ] D LL3 LL2 LL1)",
                dimensions: dimensions,
                scaleLength: 1000  // Reference length for scale calculations
            )
        } catch {
            // Fallback to a basic rule if parsing fails
            fatalError("Failed to parse slide rule definition: \(error)")
        }
    }
    
    // Calculate total number of scales
    private var totalScaleCount: Int {
        slideRule.frontTopStator.scales.count +
        slideRule.frontSlide.scales.count +
        slideRule.frontBottomStator.scales.count
    }
    
    // Helper function to calculate responsive dimensions
    private func calculateDimensions(availableWidth: CGFloat, availableHeight: CGFloat) -> (width: CGFloat, scaleHeight: CGFloat) {
        let maxWidth = availableWidth - (padding * 2)
        let maxHeight = availableHeight - (padding * 2)
        
        // Calculate scale height based on available height
        let calculatedScaleHeight = min(
            maxHeight / CGFloat(totalScaleCount),
            maxScaleHeight
        )
        let scaleHeight = max(calculatedScaleHeight, minScaleHeight)
        
        // Calculate total height needed for all scales
        let totalHeight = scaleHeight * CGFloat(totalScaleCount)
        
        // Calculate width based on aspect ratio
        let widthFromAspectRatio = totalHeight * targetAspectRatio
        
        // Use the smaller of the two to ensure it fits within window
        let width = min(maxWidth, widthFromAspectRatio)
        
        return (width, scaleHeight)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let dimensions = calculateDimensions(
                availableWidth: geometry.size.width,
                availableHeight: geometry.size.height
            )
            let width = dimensions.width
            let scaleHeight = dimensions.scaleHeight
            
            VStack(spacing: 0) {
                // Top Stator (Fixed) - with multiple scales
                StatorView(
                    stator: slideRule.frontTopStator,
                    width: width,
                    backgroundColor: .white,
                    borderColor: .blue,
                    scaleHeight: scaleHeight
                )
                
                // Slider (Movable) - with multiple scales
                SlideView(
                    slide: slideRule.frontSlide,
                    width: width,
                    backgroundColor: .white,
                    borderColor: .orange,
                    scaleHeight: scaleHeight
                )
                .offset(x: sliderOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            // Calculate new offset with bounds
                            let newOffset = gesture.translation.width
                            sliderOffset = min(max(newOffset, -width), width)
                        }
                )
                .animation(.interactiveSpring(), value: sliderOffset)
                
                // Bottom Stator (Fixed) - with multiple scales
                StatorView(
                    stator: slideRule.frontBottomStator,
                    width: width,
                    backgroundColor: .white,
                    borderColor: .blue,
                    scaleHeight: scaleHeight
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // No clipping - allow slider to extend beyond stators like a physical slide rule
        }
        .padding(padding)
    }
}

#Preview {
    ContentView()
        .frame(width: 900)
}
