import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Boundary Testing Utilities

/// Utilities for testing scale boundary conditions
enum BoundaryTester {
    
    /// Test that scale begin/end values map to positions 0 and 1
    /// - Parameters:
    ///   - scale: Scale definition to test
    ///   - tolerance: Position tolerance
    static func expectCorrectBoundaries(
        _ scale: ScaleDefinition,
        tolerance: Double = 0.01,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let posBegin = ScaleCalculator.normalizedPosition(for: scale.beginValue, on: scale)
        let posEnd = ScaleCalculator.normalizedPosition(for: scale.endValue, on: scale)
        
        #expect(
            abs(posBegin) < tolerance,
            "\(scale.name) beginValue (\(scale.beginValue)) should map to position ~0, got \(posBegin)",
            sourceLocation: sourceLocation
        )
        
        #expect(
            abs(posEnd - 1.0) < tolerance,
            "\(scale.name) endValue (\(scale.endValue)) should map to position ~1, got \(posEnd)",
            sourceLocation: sourceLocation
        )
    }
    
    /// Test that position 0 yields beginValue and position 1 yields endValue
    /// - Parameters:
    ///   - scale: Scale definition to test
    ///   - tolerance: Value tolerance
    static func expectCorrectBoundaryValues(
        _ scale: ScaleDefinition,
        tolerance: Double = 0.01,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let valueAtStart = ScaleCalculator.value(at: 0.0, on: scale)
        let valueAtEnd = ScaleCalculator.value(at: 1.0, on: scale)
        
        let errorStart = abs(valueAtStart - scale.beginValue)
        let errorEnd = abs(valueAtEnd - scale.endValue)
        
        #expect(
            errorStart < tolerance,
            "\(scale.name) at position 0.0 should yield beginValue (\(scale.beginValue)): got \(valueAtStart), error = \(errorStart)",
            sourceLocation: sourceLocation
        )
        
        #expect(
            errorEnd < tolerance,
            "\(scale.name) at position 1.0 should yield endValue (\(scale.endValue)): got \(valueAtEnd), error = \(errorEnd)",
            sourceLocation: sourceLocation
        )
    }
}
