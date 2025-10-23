//
//  ContentView.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/18/25.
//

import SwiftUI
import SlideRuleCoreV3

struct ContentView: View {
    @State private var sliderOffset: CGFloat = 0
    
    // Constants for sizing
    private let statorWidth: CGFloat = 400  // Width of fixed stators
    private let sliderWidth: CGFloat = 600  // Slider is wider and extends past stators
    private let ruleHeight: CGFloat = 60
    
    // Maximum offset - allow slider to move so its edges extend past stator edges
    // The slider is (sliderWidth - statorWidth) / 2 longer on each side (100px each side)
    // Allow it to move up to that amount so it can extend beyond the stators
    private var maxOffset: CGFloat {
        (sliderWidth - statorWidth) / 2
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Stator (Fixed) - acts as a window
            StatorView(label: "Top Stator")
                .frame(width: statorWidth, height: ruleHeight)
            
            // Slider (Movable) - wider than stators, extends beyond their edges
            SliderView()
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
            
            // Bottom Stator (Fixed) - acts as a window
            StatorView(label: "Bottom Stator")
                .frame(width: statorWidth, height: ruleHeight)
        }
        .padding()
        // No clipping - allow slider to extend beyond stators like a physical slide rule
    }
}

struct StatorView: View {
    let label: String
    
    var body: some View {
        ZStack {
            // Background fill
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.25)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Border
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue, lineWidth: 2)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.blue.opacity(0.8))
        }
    }
}

struct SliderView: View {
    var body: some View {
        ZStack {
            // Background fill with gradient
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.4)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Thicker border to distinguish from stators
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.orange, lineWidth: 3)
            
            // Label
            Text("Slider")
                .font(.caption)
                .foregroundColor(.orange.opacity(0.9))
        }
    }
}

#Preview {
    ContentView()
}
