import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Round-Trip Testing Utilities

/// Utilities for testing position↔value round-trip accuracy
enum RoundTripTester {
    
    /// Test round-trip accuracy for a single value on a scale
    /// - Parameters:
    ///   - value: The value to test
    ///   - scale: The scale definition
    ///   - tolerance: Relative error tolerance (default: 0.01)
    ///   - sourceLocation: Source location for error reporting
    static func testRoundTrip(
        value: Double,
        on scale: ScaleDefinition,
        tolerance: Double = TestTolerance.standard,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / max(abs(value), 0.001)
        
        #expect(
            relativeError < tolerance,
            "\(scale.name) scale: Value \(value) round-trip error \(relativeError) exceeds tolerance \(tolerance)",
            sourceLocation: sourceLocation
        )
    }
    
    /// Test round-trip accuracy for multiple values on a scale
    /// - Parameters:
    ///   - values: Array of values to test
    ///   - scale: The scale definition
    ///   - tolerance: Relative error tolerance (default: 0.01)
    static func testRoundTrips(
        values: [Double],
        on scale: ScaleDefinition,
        tolerance: Double = TestTolerance.standard,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for value in values {
            testRoundTrip(value: value, on: scale, tolerance: tolerance, sourceLocation: sourceLocation)
        }
    }
    
    /// Test position→value→position round-trip accuracy
    /// - Parameters:
    ///   - positions: Array of normalized positions to test
    ///   - scale: The scale definition
    ///   - tolerance: Position tolerance (default: varies by scale)
    static func testPositionRoundTrips(
        positions: [Double],
        on scale: ScaleDefinition,
        tolerance: Double = 0.0001,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for position in positions {
            let value = ScaleCalculator.value(at: position, on: scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let error = abs(computedPosition - position)
            
            #expect(
                error < tolerance,
                "\(scale.name) scale position round-trip failed at \(position): error = \(error)",
                sourceLocation: sourceLocation
            )
        }
    }
}
