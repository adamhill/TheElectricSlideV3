import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Utilities for testing ScaleFunction implementations
/// Provides systematic testing of transform/inverse transforms, known values, and boundary conditions
enum FunctionRoundTripTester {
    
    /// Test round-trip accuracy for a function with an array of values
    /// - Parameters:
    ///   - function: The ScaleFunction to test
    ///   - values: Test values to verify
    ///   - tolerance: Acceptable relative error (default: 0.01)
    ///   - useRelativeError: Whether to use relative error (default: true)
    static func testRoundTrip(
        _ function: any ScaleFunction,
        values: [Double],
        tolerance: Double = TestTolerance.standard,
        useRelativeError: Bool = true,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for value in values {
            let transformed = function.transform(value)
            let recovered = function.inverseTransform(transformed)
            
            let error: Double
            if useRelativeError {
                error = abs(recovered - value) / max(abs(value), 0.001)
            } else {
                error = abs(recovered - value)
            }
            
            #expect(
                error < tolerance,
                "\(type(of: function)) round-trip failed: \(value) → \(transformed) → \(recovered), error: \(error)",
                sourceLocation: sourceLocation
            )
        }
    }
    
    /// Test known value pairs (input → expected output)
    /// - Parameters:
    ///   - function: The ScaleFunction to test
    ///   - pairs: Array of (input, expectedOutput) tuples
    ///   - tolerance: Absolute error tolerance (default: 1e-4)
    static func testKnownValues(
        _ function: any ScaleFunction,
        pairs: [(input: Double, expected: Double)],
        tolerance: Double = 1e-4,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for (input, expected) in pairs {
            let result = function.transform(input)
            let error = abs(result - expected)
            
            #expect(
                error < tolerance,
                "\(type(of: function)) known value failed: f(\(input)) = \(result), expected \(expected), error: \(error)",
                sourceLocation: sourceLocation
            )
        }
    }
    
    /// Boundary expectation types for domain testing
    enum BoundaryExpectation: Sendable {
        case finite
        case negativeInfinity
        case positiveInfinity
        case nan
    }
    
    /// Test boundary conditions and domain restrictions
    /// - Parameters:
    ///   - function: The ScaleFunction to test
    ///   - cases: Array of (value, expectedBehavior) tuples
    static func testBoundaries(
        _ function: any ScaleFunction,
        cases: [(value: Double, expectation: BoundaryExpectation)],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for (value, expectation) in cases {
            let result = function.transform(value)
            
            switch expectation {
            case .finite:
                #expect(result.isFinite, "\(type(of: function))(\(value)) should be finite, got \(result)", sourceLocation: sourceLocation)
            case .negativeInfinity:
                #expect(result.isInfinite && result < 0, "\(type(of: function))(\(value)) should be -∞, got \(result)", sourceLocation: sourceLocation)
            case .positiveInfinity:
                #expect(result.isInfinite && result > 0, "\(type(of: function))(\(value)) should be +∞, got \(result)", sourceLocation: sourceLocation)
            case .nan:
                #expect(result.isNaN, "\(type(of: function))(\(value)) should be NaN, got \(result)", sourceLocation: sourceLocation)
            }
        }
    }
}
