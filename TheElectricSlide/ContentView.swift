//
//  ContentView.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/18/25.
//

import SwiftUI
import SlideRuleCoreV3

// NOTE:
// `onGeometryChange(for:)` requires the value type to be usable across isolation domains.
// A main-actor–isolated conformance to `Equatable` cannot satisfy a generic `Sendable` requirement.
// By making the type's conformances `nonisolated` and using `@unchecked Sendable` for this trivial
// value type (two `CGFloat`s), we assert it's safe to pass across tasks/actors.
// This avoids the compiler error: "Main actor-isolated conformance ... cannot satisfy conformance
// requirement for a 'Sendable' type parameter".
nonisolated struct Dimensions: Equatable, @unchecked Sendable {
    var width: CGFloat
    var scaleHeight: CGFloat
}

// MARK: - ScaleView Component

struct ScaleView: View {
    let generatedScale: GeneratedScale  // ✅ Use pre-computed GeneratedScale
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Scale name label on the left
            Text(generatedScale.definition.name)
                .font(.caption2)
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 20)
            
            // Scale view
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Tick marks and labels
                    Canvas { context, size in
                        // ✅ Use pre-computed tick marks from GeneratedScale
                        drawScale(
                            context: &context,
                            size: size,
                            tickMarks: generatedScale.tickMarks,
                            definition: generatedScale.definition
                        )
                    }
                }
            }
            .frame(width: width)
            .frame(minHeight: height * 0.8, idealHeight: height, maxHeight: height)
            
            // Formula label on the right
            Text(generatedScale.definition.formula)
                .font(.caption2)
                .tracking((generatedScale.definition.formulaTracking - 1.0) * 2.0)
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 40, alignment: .leading)
        }
    }
    
    /// Draw the scale with pre-computed tick marks
    private func drawScale(
        context: inout GraphicsContext,
        size: CGSize,
        tickMarks: [TickMark],
        definition: ScaleDefinition
    ) {
        // Draw baseline if enabled
        if definition.showBaseline {
            let baselinePath = Path { path in
                switch definition.tickDirection {
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
        
        // Draw tick marks
        for tick in tickMarks {
            // Calculate horizontal position
            let xPos = tick.normalizedPosition * size.width
            
            // Calculate tick height based on relativeLength
            let tickHeight = tick.style.relativeLength * (size.height * 0.6)
            
            // Calculate tick start and end positions based on direction
            let (tickStartY, tickEndY): (CGFloat, CGFloat)
            switch definition.tickDirection {
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
                    switch definition.tickDirection {
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
                    generatedScale: generatedScale,  // ✅ Pass entire GeneratedScale
                    width: width,
                    height: scaleHeight
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
                    generatedScale: generatedScale,  // ✅ Pass entire GeneratedScale
                    width: width,
                    height: scaleHeight
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
    // ✅ State for calculated dimensions - only updates when window size changes

    @State private var calculatedDimensions: Dimensions = .init(width: 800, scaleHeight: 25)
    
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
               // "( DF [ CF- CIF DI CI C ] D )",
               "(DF [ CF CIF CI C ] D ST )",
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
    private func calculateDimensions(availableWidth: CGFloat, availableHeight: CGFloat) -> Dimensions {
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
        
        return Dimensions(width: width, scaleHeight: scaleHeight)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Stator (Fixed) - only depends on calculatedDimensions
            StatorView(
                stator: slideRule.frontTopStator,
                width: calculatedDimensions.width,
                backgroundColor: .white,
                borderColor: .blue,
                scaleHeight: calculatedDimensions.scaleHeight
            )
            .id("topStator")  // ✅ Stable identity for performance
            
            // Slider (Movable) - depends on both calculatedDimensions and sliderOffset
            SlideView(
                slide: slideRule.frontSlide,
                width: calculatedDimensions.width,
                backgroundColor: .white,
                borderColor: .orange,
                scaleHeight: calculatedDimensions.scaleHeight
            )
            .offset(x: sliderOffset)
            .gesture(dragGesture)
            .animation(.interactiveSpring(), value: sliderOffset)
            
            // Bottom Stator (Fixed) - only depends on calculatedDimensions
            StatorView(
                stator: slideRule.frontBottomStator,
                width: calculatedDimensions.width,
                backgroundColor: .white,
                borderColor: .blue,
                scaleHeight: calculatedDimensions.scaleHeight
            )
            .id("bottomStator")  // ✅ Stable identity for performance
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(padding)
        // ✅ onGeometryChange - only updates calculatedDimensions when size actually changes
        .onGeometryChange(for: Dimensions.self) { proxy in
            // Extract ONLY the dimensions we need
            let size = proxy.size
            return calculateDimensions(
                availableWidth: size.width,
                availableHeight: size.height
            )
        } action: { newDimensions in
            // ONLY called when dimensions actually change (not on every geometry event)
            calculatedDimensions = newDimensions
        }
    }
    
    // ✅ Extract drag gesture for clarity
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                // Calculate new offset with bounds
                let newOffset = gesture.translation.width
                sliderOffset = min(max(newOffset, -calculatedDimensions.width), 
                                 calculatedDimensions.width)
            }
    }
}

#Preview {
    ContentView()
        .frame(width: 900)
}

