//
//  ScaleContainerView.swift
//  TheElectricSlide
//
//  Generic view component for rendering scale containers (Slide or Stator)
//  Consolidates duplicate rendering logic between SlideView and StatorView
//
//  **Split Scale Support (December 2025):**
//  Detects consecutive scales with .left/.right splitSegment and renders
//  them in a ZStack sharing the same row height, rather than separate VStack rows.
//

import SwiftUI
import SlideRuleCoreV3

// Debug flag for split scale rendering
private let DEBUG_SPLIT_SCALES = true

// MARK: - Generic ScaleContainerView

struct ScaleContainerView<Container: ScaleContainer>: View, Equatable {
    let container: Container
    let width: CGFloat
    let backgroundColor: Color
    let borderColor: Color
    let scaleHeight: CGFloat
    let leftMarginWidth: CGFloat
    let rightMarginWidth: CGFloat
    let nameFont: Font
    let formulaFont: Font
    let ruleId: UUID?
    let scaleCount: Int  // Cached for Equatable comparison
    
    // Manufacturer colorway support
    let useManufacturerColors: Bool
    let colorScheme: SlideRuleColorScheme?
    
    // Precision mode support - intensifies scale colors when active
    var isPrecisionActive: Bool = false
    
    // Equatable conformance - only compare properties that affect rendering
    static func == (lhs: ScaleContainerView, rhs: ScaleContainerView) -> Bool {
        lhs.ruleId == rhs.ruleId &&
        lhs.width == rhs.width &&
        lhs.scaleHeight == rhs.scaleHeight &&
        lhs.leftMarginWidth == rhs.leftMarginWidth &&
        lhs.rightMarginWidth == rhs.rightMarginWidth &&
        lhs.scaleCount == rhs.scaleCount &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.borderColor == rhs.borderColor &&
        lhs.useManufacturerColors == rhs.useManufacturerColors &&
        lhs.isPrecisionActive == rhs.isPrecisionActive &&
        lhs.colorScheme?.primaryHighlight == rhs.colorScheme?.primaryHighlight &&
        lhs.colorScheme?.secondaryHighlight == rhs.colorScheme?.secondaryHighlight
    }
    
    // MARK: - Split Scale Grouping
    
    /// Groups scales for rendering, combining split scale pairs into single rows
    /// Returns an array of ScaleRenderGroup, where each group is either:
    /// - A single non-split scale
    /// - A pair of split scales (left + right) sharing one row
    private var scaleRenderGroups: [ScaleRenderGroup] {
        var groups: [ScaleRenderGroup] = []
        var index = 0
        let scales = container.scales
        
        while index < scales.count {
            let current = scales[index]
            
            // Check if this is the left half of a split scale pair
            if let segment = current.definition.splitSegment,
               case .left = segment,
               index + 1 < scales.count {
                let next = scales[index + 1]
                // Check if the next scale is the right half
                if let nextSegment = next.definition.splitSegment,
                   case .right = nextSegment {
                    // Found a split pair - group them together
                    groups.append(.splitPair(left: current, right: next))
                    index += 2  // Skip both scales
                    continue
                }
            }
            
            // Not a split pair - render as single scale
            groups.append(.single(current))
            index += 1
        }
        
        return groups
    }
    
    /// Calculate total max height based on number of render groups (not raw scale count)
    private var maxTotalHeight: CGFloat {
        scaleHeight * CGFloat(scaleRenderGroups.count)
    }
    
    /// Returns background gradient data for drawing directly in ScaleView's Canvas
    /// This eliminates VStack preference propagation from .background() modifiers
    ///
    /// **Optimization (December 2025):**
    /// Instead of using SwiftUI's .background() which creates preference nodes,
    /// gradient data is passed to ScaleView and drawn in its Canvas.
    /// This reduces ~3000 preference updates to near zero during drag gestures.
    private func scaleBackgroundGradientData(for scaleName: String) -> ScaleBackgroundGradient? {
        guard useManufacturerColors, let scheme = colorScheme else { return nil }
        
        // Use precision-intensity gradient when precision mode is active
        if isPrecisionActive {
            return scheme.precisionScaleBackgroundGradientData(for: scaleName)
        } else {
            return scheme.scaleBackgroundGradientData(for: scaleName)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(scaleRenderGroups.enumerated()), id: \.offset) { index, group in
                switch group {
                case .single(let generatedScale):
                    // Standard single-scale row
                    ScaleView(
                        generatedScale: generatedScale,
                        width: width,
                        height: scaleHeight,
                        leftMarginWidth: leftMarginWidth,
                        rightMarginWidth: rightMarginWidth,
                        nameFont: nameFont,
                        formulaFont: formulaFont,
                        backgroundGradient: scaleBackgroundGradientData(for: generatedScale.definition.name)
                    )
                    .equatable()
                    .accessibilityIdentifier("scale-row-\(generatedScale.definition.name)")
                    
                case .splitPair(let leftScale, let rightScale):
                    // Split scale pair - both rendered in ZStack sharing same row
                    // Use .bottomLeading alignment for scales with tick direction UP
                    // (ticks draw from bottom baseline upward)
                    let _ = DEBUG_SPLIT_SCALES ? print("🔀 [SPLIT PAIR] Rendering: \(leftScale.definition.name) + \(rightScale.definition.name)") : ()
                    let _ = DEBUG_SPLIT_SCALES ? print("   Left tickDir: \(leftScale.definition.tickDirection), Right tickDir: \(rightScale.definition.tickDirection)") : ()
                    let _ = DEBUG_SPLIT_SCALES ? print("   scaleHeight: \(scaleHeight), width: \(width)") : ()
                    ZStack(alignment: .bottomLeading) {
                        // Left segment
                        ScaleView(
                            generatedScale: leftScale,
                            width: width,
                            height: scaleHeight,
                            leftMarginWidth: leftMarginWidth,
                            rightMarginWidth: rightMarginWidth,
                            nameFont: nameFont,
                            formulaFont: formulaFont,
                            backgroundGradient: scaleBackgroundGradientData(for: leftScale.definition.name)
                        )
                        .equatable()
                        .frame(height: scaleHeight)  // Ensure consistent height in ZStack
                        
                        // Right segment (overlaid on same row)
                        ScaleView(
                            generatedScale: rightScale,
                            width: width,
                            height: scaleHeight,
                            leftMarginWidth: leftMarginWidth,
                            rightMarginWidth: rightMarginWidth,
                            nameFont: nameFont,
                            formulaFont: formulaFont,
                            backgroundGradient: scaleBackgroundGradientData(for: rightScale.definition.name)
                        )
                        .equatable()
                        .frame(height: scaleHeight)  // Ensure consistent height in ZStack
                    }
                    .frame(height: scaleHeight)
                    .accessibilityIdentifier("scale-row-split-\(leftScale.definition.name)-\(rightScale.definition.name)")
                }
            }
        }
        .accessibilityIdentifier("scale-container-vstack")
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .accessibilityIdentifier("scale-container-bg")
        )
        .overlay(
            Group {
                if container.showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 2)
                        .accessibilityIdentifier("scale-container-border")
                }
            }
        )
        .frame(width: width, height: maxTotalHeight)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("scale-container-root")
    }
}

// MARK: - Scale Render Group

/// Represents how scales should be rendered - either individually or as split pairs
private enum ScaleRenderGroup {
    /// A single non-split scale taking one full row
    case single(GeneratedScale)
    
    /// A pair of split scales (left + right) sharing one row in a ZStack
    case splitPair(left: GeneratedScale, right: GeneratedScale)
}
