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
            Text(scaleName)
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
                        
                        // Draw baseline based on tick direction
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
            .frame(width: width, height: height)
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
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stator.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    scaleDefinition: generatedScale.definition,
                    width: width,
                    height: stator.heightInPoints / CGFloat(stator.scales.count),
                    scaleName: generatedScale.definition.name
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 2)
        )
        .frame(width: width, height: stator.heightInPoints)
    }
}

// MARK: - SlideView Component (renders multiple scales)

struct SlideView: View {
    let slide: Slide
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(slide.scales.enumerated()), id: \.offset) { index, generatedScale in
                ScaleView(
                    scaleDefinition: generatedScale.definition,
                    width: width,
                    height: slide.heightInPoints / CGFloat(slide.scales.count),
                    scaleName: generatedScale.definition.name
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 2)
        )
        .frame(width: width, height: slide.heightInPoints)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var sliderOffset: CGFloat = 0
    
    // Constants for sizing
    private let statorWidth: CGFloat = 800  // Width of fixed stators
    private let sliderWidth: CGFloat = 800  // Slider is same length as stators
    
    // Maximum offset - allow slider to slide along the full length of the stators
    // With equal lengths, slider can move the full width in either direction
    private var maxOffset: CGFloat {
        statorWidth
    }
    
    // Parse the slide rule definition using RuleDefinitionParser
    private var slideRule: SlideRule {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        // Parse the rule definition: Multiple scales per component
        // Top stator: K and A scales
        // Slide: B, BI, CI, C scales  
        // Bottom stator: D and L scales
        do {
            return try RuleDefinitionParser.parse(
                "(K A [ B BI CI C ] D L)",
                dimensions: dimensions,
                scaleLength: statorWidth
            )
        } catch {
            // Fallback to a basic rule if parsing fails
            fatalError("Failed to parse slide rule definition: \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Stator (Fixed) - with multiple scales
            StatorView(
                stator: slideRule.frontTopStator,
                width: statorWidth,
                backgroundColor: .white,
                borderColor: .blue
            )
            
            // Slider (Movable) - with multiple scales
            SlideView(
                slide: slideRule.frontSlide,
                width: sliderWidth,
                backgroundColor: .white,
                borderColor: .orange
            )
            .offset(x: sliderOffset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Calculate new offset with bounds
                        let newOffset = gesture.translation.width
                        sliderOffset = min(max(newOffset, -maxOffset), maxOffset)
                    }
            )
            .animation(.interactiveSpring(), value: sliderOffset)
            
            // Bottom Stator (Fixed) - with multiple scales
            StatorView(
                stator: slideRule.frontBottomStator,
                width: statorWidth,
                backgroundColor: .white,
                borderColor: .blue
            )
        }
        .padding()
        // No clipping - allow slider to extend beyond stators like a physical slide rule
    }
}

#Preview {
    ContentView()
        .frame(width: 900)
}
