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
    let backgroundColor: Color
    let borderColor: Color
    let scaleName: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
                
                // Border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(borderColor, lineWidth: 2)
                
                // Tick marks and labels
                Canvas { context, size in
                    let tickMarks = ScaleCalculator.generateTickMarks(
                        for: scaleDefinition,
                        algorithm: .modulo(config: ModuloTickConfig.default) )
                    
                    for tick in tickMarks {
                        // Calculate horizontal position
                        let xPos = tick.normalizedPosition * size.width
                        
                        // Calculate tick height based on relativeLength
                        let tickHeight = tick.style.relativeLength * (size.height * 0.6)
                        
                        // Draw tick mark (vertical line)
                        let tickPath = Path { path in
                            path.move(to: CGPoint(x: xPos, y: 0))
                            path.addLine(to: CGPoint(x: xPos, y: tickHeight))
                        }
                        
                        context.stroke(
                            tickPath,
                            with: .color(.black),
                            lineWidth: tick.style.lineWidth / 2
                        )
                        
                        // Draw label if present
                        if let labelText = tick.label {
                            let fontSize = fontSizeForTick(tick.style.relativeLength)
                            
                            if fontSize > 0 {
                                let text = Text(labelText)
                                    .font(.system(size: fontSize))
                                    .foregroundColor(.black)
                                
                                let resolvedText = context.resolve(text)
                                let textSize = resolvedText.measure(in: CGSize(width: 100, height: 100))
                                
                                // Position label below tick mark
                                let labelY = tickHeight + 2
                                let labelX = xPos - textSize.width / 2
                                
                                context.draw(
                                    resolvedText,
                                    at: CGPoint(x: labelX + textSize.width / 2, y: labelY + textSize.height / 2)
                                )
                            }
                        }
                    }
                }
                
                // Scale name label
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(scaleName)
                            .font(.caption2)
                            .foregroundColor(borderColor.opacity(0.7))
                            .padding(4)
                        Spacer()
                    }
                }
            }
        }
        .frame(width: width, height: height)
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

// MARK: - ContentView

struct ContentView: View {
    @State private var sliderOffset: CGFloat = 0
    
    // Constants for sizing
    // Constants for sizing
    private let statorWidth: CGFloat = 800  // Width of fixed stators
    private let sliderWidth: CGFloat = 800  // Slider is same length as stators
    private let ruleHeight: CGFloat = 60
    
    // Maximum offset - allow slider to slide along the full length of the stators
    // With equal lengths, slider can move the full width in either direction
    private var maxOffset: CGFloat {
        statorWidth
    }
    var body: some View {
        VStack(spacing: 0) {
            // Top Stator (Fixed) - acts as a window with A scale
            ScaleView(
                scaleDefinition: StandardScales.aScale(length: statorWidth),
                width: statorWidth,
                height: ruleHeight,
                backgroundColor: .white,
                borderColor: .blue,
                scaleName: "A"
            )
            .frame(width: statorWidth, height: ruleHeight)
            
            // Slider (Movable) - wider than stators with C scale
            ScaleView(
                scaleDefinition: StandardScales.cScale(length: sliderWidth),
                width: sliderWidth,
                height: ruleHeight,
                backgroundColor: .white,
                borderColor: .orange,
                scaleName: "C"
            )
            .frame(width: sliderWidth, height: ruleHeight)
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
            
            // Bottom Stator (Fixed) - acts as a window with D scale
            ScaleView(
                scaleDefinition: StandardScales.dScale(length: statorWidth),
                width: statorWidth,
                height: ruleHeight,
                backgroundColor: .white,
                borderColor: .blue,
                scaleName: "D"
            )
            .frame(width: statorWidth, height: ruleHeight)
        }
        .padding()
        // No clipping - allow slider to extend beyond stators like a physical slide rule
    }
}

#Preview {
    ContentView()
        .frame(width: 900)
}
