//  TheElectricSlide
//
//  Visual test preview for Pickett N-16 ES THETA and ALPHA scales
//  Demonstrates split THETA scales (Θ₁ ^ Θ₂) and full-width ALPHA scale
//

import SwiftUI
import SlideRuleCoreV3

// MARK: - Pickett N-16 ES Scales Preview

/// Preview displaying Pickett N-16 ES phase angle scales (THETA and ALPHA)
/// Shows split THETA scales with ticks pointing UP and ALPHA scale with ticks pointing DOWN
struct PickettN16ESPreview: View {
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
    
    // MARK: - Scale Definitions
    
    /// Θ₁ (THETA SMALL) - Left half: 6.0° → 0.57°
    private var thetaSmall: GeneratedScale {
        let thetaDef = StandardScales.phaseAngleThetaSmallScale(length: scaleLength)
        return GeneratedScale(definition: thetaDef)
    }
    
    /// Θ₂ (THETA LARGE) - Right half: 0.01° → 5.71°
    private var thetaLarge: GeneratedScale {
        let thetaDef = StandardScales.phaseAngleThetaLargeScale(length: scaleLength)
        return GeneratedScale(definition: thetaDef)
    }
    
    /// α (ALPHA) - Full width: 84.29° → 5.71°
    private var alpha: GeneratedScale {
        let alphaDef = StandardScales.phaseAngleAlphaScale(length: scaleLength)
        return GeneratedScale(definition: alphaDef)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Title
                Text("Pickett N-16 ES Phase Angle Scales")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.bottom, 8)
                
                Text("THETA scales (Θ₁ ^ Θ₂) with split architecture and ALPHA scale with full-width layout")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                
                // THETA scales section (split)
                thetaScalesSection
                
                Divider()
                
                // ALPHA scale section (full width)
                alphaScaleSection
            }
            .padding()
        }
    }
    
    // MARK: - Section Views
    
    /// THETA scales section showing Θ₁ and Θ₂ as split scales
    private var thetaScalesSection: some View {
        SplitScaleTestComponent(
            leftScale: thetaSmall,
            rightScale: thetaLarge,
            title: "THETA Scales (Θ₁ ^ Θ₂) - Split Scale Architecture",
            segmentDescription: "Left: Θ₁ (6.0°→0.57°, small angles), Right: Θ₂ (0.01°→5.71°, large angles)",
            expectedDescription: "Expected: Both segments share same baseline with ticks pointing UP, split at center (50%)",
            expectedBoundaryPosition: 0.5,
            actualBoundaryPosition: thetaLarge.tickMarks.first?.normalizedPosition ?? 0.0,
            actualFirstTickValue: thetaLarge.tickMarks.first?.value ?? 0.0,
            scaleLength: scaleLength,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth
        )
    }
    
    /// ALPHA scale section showing full-width layout
    private var alphaScaleSection: some View {
        ScalePairTestComponent(
            scales: [alpha],
            title: "ALPHA Scale (α) - Full-Width Layout",
            description: "Phase angle scale: 84.29°→5.71° with ticks pointing DOWN (opposite of THETA)",
            scaleLength: scaleLength,
            scaleHeight: scaleHeight,
            leftMarginWidth: leftMarginWidth,
            rightMarginWidth: rightMarginWidth,
            stackSpacing: 4
        )
    }
}

// MARK: - SwiftUI Previews

#Preview("Default Configuration") {
    PickettN16ESPreview()
        .aspectRatio(0.5, contentMode: .fit)
        .preferredColorScheme(.light)
}

#Preview("Light Mode") {
    PickettN16ESPreview(
        scaleLength: 800
    )
    .aspectRatio(0.5, contentMode: .fit)
    .preferredColorScheme(.light)
}

#Preview("Compact (iPhone)") {
    PickettN16ESPreview(
        scaleLength: 600,
        scaleHeight: 35,
        leftMarginWidth: 50,
        rightMarginWidth: 60,
        nameFontSize: 12,
        formulaFontSize: 10
    )
    .aspectRatio(0.5, contentMode: .fit)
    .preferredColorScheme(.light)
}

#Preview("Large (iPad)") {
    PickettN16ESPreview(
        scaleLength: 1000,
        scaleHeight: 50,
        leftMarginWidth: 70,
        rightMarginWidth: 100,
        nameFontSize: 16,
        formulaFontSize: 14
    )
    .aspectRatio(0.5, contentMode: .fit)
    .preferredColorScheme(.light)
}

#Preview("High Precision") {
    PickettN16ESPreview(
        scaleLength: 1200,
        scaleHeight: 60
    )
    .aspectRatio(0.5, contentMode: .fit)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    PickettN16ESPreview(
        scaleLength: 800,
        scaleHeight: 40
    )
    .aspectRatio(0.5, contentMode: .fit)
    .preferredColorScheme(.dark)
}
