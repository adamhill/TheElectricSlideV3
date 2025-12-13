import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests to verify K scale label density matches PostScript reference implementation
///
/// PROBLEM: The K scale was displaying labels on EVERY major tick mark, creating
/// excessive density especially in the upper ranges (100-1000). This violates the
/// PostScript reference which shows selective labeling.
///
/// POSTSCRIPT REFERENCE (lines 710-727):
/// - Uses different label formatters (plabel1, plabel10, plabel100, plabel1000)
/// - Each formatter is applied to specific subsections
/// - NOT every major tick gets a label
///
/// EXPECTED LABELS (from PostScript):
/// - 1-10 range: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
/// - 10-100 range: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
/// - 100-1000 range: 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000
///
/// TOTAL: ~28 labels maximum for full range
///
/// @tags: kscale, density, postscript-fidelity, ux
@Suite("K Scale Label Density Verification", .tags(.kscale, .density))
struct KScaleLabelDensityTests {
    
    @Test("K scale shows correct number of labels for standard 250pt scale")
    func kScaleStandardLabelCount() {
        // GIVEN: A K scale at standard 250pt length
        let kScale = StandardScales.kScale(length: 250.0)
        
        // WHEN: We generate tick marks
        let ticks = ScaleCalculator.generateTickMarks(
            for: kScale,
            algorithm: .modulo(config: .default)
        )
        
        let labeledTicks = ticks.filter { $0.label != nil }
        
        // THEN: Should have approximately 28 labels (PostScript reference)
        // Allow some variance due to subsection boundaries
        #expect(labeledTicks.count <= 30, 
                "K scale should have ≤30 labels (PostScript shows ~28), found: \(labeledTicks.count)")
        
        #expect(labeledTicks.count >= 20,
                "K scale should have ≥20 labels for usability, found: \(labeledTicks.count)")
        
        print("K scale label count: \(labeledTicks.count)")
    }
    
    @Test("K scale labels appear at expected integer values")
    func kScaleExpectedLabelValues() {
        // GIVEN: A K scale at standard length
        let kScale = StandardScales.kScale(length: 250.0)
        
        // WHEN: We generate tick marks
        let ticks = ScaleCalculator.generateTickMarks(
            for: kScale,
            algorithm: .modulo(config: .default)
        )
        
        let labeledValues = ticks.compactMap { tick -> Int? in
            guard tick.label != nil else { return nil }
            return Int(tick.value.rounded())
        }
        
        // THEN: Should include key integer labels
        let expectedLabels = [1, 2, 3, 4, 5, 10, 20, 30, 100, 200, 300, 1000]
        
        for expected in expectedLabels {
            #expect(labeledValues.contains(expected),
                    "K scale should have label at \(expected)")
        }
        
        print("K scale labeled values: \(labeledValues)")
    }
    
    @Test("K scale does NOT label every major tick mark")
    func kScaleSelectiveLabeling() {
        // GIVEN: A K scale
        let kScale = StandardScales.kScale(length: 250.0)
        
        // WHEN: We count major ticks vs labeled ticks
        let ticks = ScaleCalculator.generateTickMarks(
            for: kScale,
            algorithm: .modulo(config: .default)
        )
        
        let majorTicks = ticks.filter { $0.style.relativeLength >= 0.9 }
        let labeledTicks = ticks.filter { $0.label != nil }
        
        // THEN: Not all major ticks should have labels
        // PostScript shows selective labeling, not 1:1 major tick to label
        #expect(labeledTicks.count < majorTicks.count,
                "K scale should NOT label every major tick. Major: \(majorTicks.count), Labeled: \(labeledTicks.count)")
        
        // Ratio should be roughly 30-50% labels to major ticks
        let ratio = Double(labeledTicks.count) / Double(majorTicks.count)
        #expect(ratio < 0.7,
                "Label to major tick ratio should be <70%, found: \(String(format: "%.1f%%", ratio * 100))")
        
        print("K scale major ticks: \(majorTicks.count), labeled: \(labeledTicks.count), ratio: \(String(format: "%.1f%%", ratio * 100))")
    }
    
    @Test("K scale upper range (100-1000) has appropriate spacing")
    func kScaleUpperRangeSpacing() {
        // GIVEN: A K scale at standard length
        let kScale = StandardScales.kScale(length: 250.0)
        
        // WHEN: We look at labels in 100-1000 range
        let ticks = ScaleCalculator.generateTickMarks(
            for: kScale,
            algorithm: .modulo(config: .default)
        )
        
        let upperRangeLabels = ticks.filter { tick in
            tick.label != nil && tick.value >= 100 && tick.value <= 1000
        }
        
        // THEN: Should not be overcrowded in upper range
        // PostScript shows: 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000 (10 labels)
        #expect(upperRangeLabels.count <= 12,
                "Upper range (100-1000) should have ≤12 labels, found: \(upperRangeLabels.count)")
        
        // Verify minimum spacing between consecutive labels in this range
        let sortedLabels = upperRangeLabels.sorted { $0.normalizedPosition < $1.normalizedPosition }
        for i in 1..<sortedLabels.count {
            let spacing = abs(sortedLabels[i].normalizedPosition - sortedLabels[i-1].normalizedPosition) * 250.0
            #expect(spacing >= 8.0,
                    "Upper range labels should be ≥8pt apart, found: \(String(format: "%.1f", spacing))pt between \(Int(sortedLabels[i-1].value)) and \(Int(sortedLabels[i].value))")
        }
        
        let labelValues = sortedLabels.map { Int($0.value.rounded()) }
        print("K scale upper range labels: \(labelValues)")
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var kscale: Self
    @Tag static var density: Self
}
