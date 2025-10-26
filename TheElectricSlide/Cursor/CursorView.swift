//
//  CursorView.swift
//  TheElectricSlide
//
//  Visual component for glass cursor
//

import SwiftUI

struct CursorView: View {
    // MARK: - Properties
    
    /// Height of the cursor (spans full vertical space)
    let height: CGFloat
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // DIAGNOSTIC: Ugly opaque rectangle for testing
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red)  // Fully opaque red
                    .frame(width: 108, height: 40)
                    .overlay(
                        Text("DRAG ME")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
                
                Spacer()
            }
            
            // Simple transparent rectangle WITH BORDER
            Rectangle()
                .fill(.clear)
                .frame(width: 108, height: height)  // 1.5 inches = 108pt at 72 DPI
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(white: 0.3), lineWidth: 1)
                )
            
            // 1pt hairline down center - solid black
            Rectangle()
                .fill(.black)  // No opacity - solid black
                .frame(width: 1, height: height)  // 1pt wide, not 1.5pt
        }
    }
}

// MARK: - Preview

#Preview {
    CursorView(height: 200)
        .frame(width: 100, height: 200)
        .background(Color.gray.opacity(0.2))
}