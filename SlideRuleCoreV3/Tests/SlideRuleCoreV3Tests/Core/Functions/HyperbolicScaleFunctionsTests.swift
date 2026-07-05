import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive test suite for hyperbolic and related scale functions
/// Tests transform/inverse accuracy, boundary conditions, and domain restrictions
///
/// Uses parametric testing via FunctionTestCase for systematic coverage of:
/// - Hyperbolic functions (sinh, cosh, tanh)
/// - Pythagorean functions (H, P)
/// - Angular/percentage functions (PA)
/// - Linear degree functions (L360, L180)
@Suite("Hyperbolic Scale Functions")
struct HyperbolicScaleFunctionsTests {
    
    // MARK: - Parametric Tests (All Functions)
    
    @Test("Round-trip accuracy", arguments: ScaleTestData.hyperbolicAndRelatedFunctions)
    func roundTrip(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testRoundTrip(
            testCase.function,
            values: testCase.testValues,
            tolerance: testCase.tolerance
        )
    }
    
    @Test("Known values", arguments: ScaleTestData.hyperbolicAndRelatedFunctions)
    func knownValues(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testKnownValues(
            testCase.function,
            pairs: testCase.knownPairs,
            tolerance: testCase.tolerance
        )
    }
    
    @Test("Boundary behavior", arguments: ScaleTestData.hyperbolicAndRelatedFunctions)
    func boundaries(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testBoundaries(
            testCase.function,
            cases: testCase.boundaryTests
        )
    }
    
    // MARK: - Specialized Tests: Mathematical Properties
    
    /// Tests for mathematical properties that can't be expressed as simple known values
    @Suite("Mathematical Properties")
    struct MathematicalPropertiesTests {
        
        @Test("Hyperbolic cosine is symmetric (even function)")
        func coshSymmetry() {
            let coshFunc = HyperbolicCosineFunction()
            let value = 2.0
            let posResult = coshFunc.transform(value)
            let negResult = coshFunc.transform(-value)
            #expect(abs(posResult - negResult) < 1e-4, "cosh(x) = cosh(-x)")
        }
        
        @Test("Hyperbolic tangent approaches ±1 asymptotically")
        func tanhAsymptotes() {
            let tanhFunc = HyperbolicTangentFunction(multiplier: 10.0)
            let largePos = tanhFunc.transform(10.0)
            // tanh(large) ≈ 1, log₁₀(10 × 1) ≈ 1.0
            #expect(abs(largePos - 1.0) < 0.01, "tanh approaches +1")
        }
        
        @Test("Pythagorean P complement relationship (3-4-5 triangle)")
        func pythagoreanTriple() {
            let pFunc = PythagoreanPFunction(multiplier: 10.0)
            // For 3-4-5 triangle: if x=3/5=0.6, then √(1-x²) = 4/5=0.8
            let result = pFunc.transform(0.6)
            let expected = log10(0.8 * 10.0)
            #expect(abs(result - expected) < 1e-3)
        }
        
        @Test("Linear degree function is truly linear (additive)")
        func linearDegreeLinearity() {
            let l360 = LinearDegreeFunction(maxDegrees: 360.0)
            let a = 90.0, b = 90.0
            let fa = l360.transform(a)
            let fb = l360.transform(b)
            let fab = l360.transform(a + b)
            #expect(abs(fab - (fa + fb)) < 1e-4, "Linear function should be additive")
        }
        
        @Test("Percentage Angular produces monotonically decreasing output")
        func paMonotonic() {
            let paFunc = PercentageAngularFunction()
            let values = [10.0, 30.0, 50.0, 70.0, 90.0]
            var previousTransformed: Double? = nil
            
            for value in values {
                let transformed = paFunc.transform(value)
                if let prev = previousTransformed {
                    #expect(transformed < prev, "PA should decrease with increasing percentage")
                }
                previousTransformed = transformed
            }
        }
    }
    
    // MARK: - Specialized Tests: Multiplier/Parameter Variations
    
    /// Tests for functions with configurable parameters
    @Suite("Offset and Range Variations")
    struct ParameterVariationTests {
        
        @Test("Hyperbolic tangent multiplier affects log scale offset")
        func tanhMultiplierRelationship() {
            let tanh1 = HyperbolicTangentFunction(multiplier: 1.0)
            let tanh100 = HyperbolicTangentFunction(multiplier: 100.0)
            let value = 1.0
            let result1 = tanh1.transform(value)
            let result100 = tanh100.transform(value)
            // log₁₀(100 × tanh) vs log₁₀(1 × tanh) should differ by 2
            #expect(abs((result100 - result1) - 2.0) < 1e-4)
        }
        
        @Test("Pythagorean H multiplier affects log scale offset")
        func hMultiplierRelationship() {
            let h1 = PythagoreanHFunction(multiplier: 1.0)
            let h10 = PythagoreanHFunction(multiplier: 10.0)
            let value = 2.0
            let result1 = h1.transform(value)
            let result10 = h10.transform(value)
            // log₁₀(10 × √3) vs log₁₀(√3) should differ by 1
            #expect(abs((result10 - result1) - 1.0) < 1e-4)
        }
        
        @Test("Hyperbolic sine with offset shifts the function")
        func sinhWithOffset() {
            let sinhOffset = HyperbolicSineFunction(multiplier: 10.0, offset: 1.0)
            let value = 2.0
            let withOffset = sinhOffset.transform(value)
            // sinh(2-1) = sinh(1)
            let expectedOffset = log10(sinh(value - 1.0) * 10.0)
            #expect(abs(withOffset - expectedOffset) < 1e-4)
        }
        
        @Test("Hyperbolic sine round-trip with offset=1.0")
        func sinhRoundTripWithOffset() {
            let sinhOffset = HyperbolicSineFunction(multiplier: 10.0, offset: 1.0)
            let testValues = [1.5, 2.0, 3.0, 5.0]
            
            for value in testValues {
                let transformed = sinhOffset.transform(value)
                let recovered = sinhOffset.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value) with offset")
            }
        }
    }
}

// MARK: - Helper Functions

private func sinh(_ x: Double) -> Double {
    (exp(x) - exp(-x)) / 2.0
}
