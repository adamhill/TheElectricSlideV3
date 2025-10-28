//
//  CursorView.swift
//  TheElectricSlide
//
//  Visual component for glass cursor
//

import SwiftUI

struct CursorView: View {
    // MARK: - Properties
    
    /// Height of the cursor (spans full vertical space of slide rule)
    let height: CGFloat
    
    // MARK: - Constants
    
    /// Width of the cursor frame
    static let cursorWidth: CGFloat = 108
    
    /// Height of the drag handle (positioned ABOVE the slide rule)
    static let handleHeight: CGFloat = 32
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Gray handle at the very top - OUTSIDE the slide rule area
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.5).opacity(0.7))
                .frame(width: Self.cursorWidth, height: Self.handleHeight)
                .overlay(
                    // Visual indicator for dragging
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 2)
                            .cornerRadius(1)
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 2)
                            .cornerRadius(1)
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 2)
                            .cornerRadius(1)
                    }
                )
            
            // Cursor glass area - extends full height of slide rule
            ZStack(alignment: .topLeading) {
                // Clear glass area with gray frame border
                Rectangle()
                    .fill(.clear)
                    .frame(width: Self.cursorWidth, height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(white: 0.4), lineWidth: 2)
                    )
                
                // 1pt hairline down center - solid black
                Rectangle()
                    .fill(.black)
                    .frame(width: 1, height: height)
                    .offset(x: Self.cursorWidth / 2)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CursorView(height: 200)
        .frame(width: 100, height: 200)
        .background(Color.gray.opacity(0.2))
}