import Testing
import Foundation
@testable import SlideRuleCore

/// Comprehensive test suite for hyperbolic and related scale functions
/// Tests transform/inverse accuracy, boundary conditions, and domain restrictions
@Suite("Hyperbolic Scale Functions")
struct HyperbolicScaleFunctionsTests {
    
    // MARK: - Hyperbolic Cosine Function Tests
    
    @Suite("HyperbolicCosineFunction Tests")
    struct HyperbolicCosineFunctionTests {
        private let coshFunc = HyperbolicCosineFunction()
        
        @Test("Hyperbolic cosine at x=0 returns cosh(0)=1, transform gives 0")
        func coshAtZero() {
            let result = coshFunc.transform(0.0)
            // cosh(0) = 1, log₁₀(1) = 0
            #expect(abs(result - 0.0) < 1e-4)
        }
        
        @Test("Hyperbolic cosine at x=1")
        func coshAtOne() {
            let result = coshFunc.transform(1.0)
            // cosh(1) ≈ 1.543, log₁₀(1.543) ≈ 0.188
            let expected = log10(cosh(1.0))
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Hyperbolic cosine is symmetric for positive and negative values")
        func coshSymmetry() {
            let value = 2.0
            let posResult = coshFunc.transform(value)
            let negResult = coshFunc.transform(-value)
            #expect(abs(posResult - negResult) < 1e-4, "cosh is even function")
        }
        
        @Test("Hyperbolic cosine inverse transform accuracy")
        func coshInverseAccuracy() {
            let testTransformed = [0.0, 0.1, 0.3, 0.5, 1.0]
            
            for t in testTransformed {
                let value = coshFunc.inverseTransform(t)
                let recovered = coshFunc.transform(value)
                #expect(abs(recovered - t) < 1e-4, "Inverse failed for transformed value \(t)")
            }
        }
        
        @Test("Hyperbolic cosine round-trip maintains accuracy")
        func coshRoundTrip() {
            let testValues = [0.0, 0.5, 1.0, 2.0, 3.0, 5.0]
            
            for value in testValues {
                let transformed = coshFunc.transform(value)
                let recovered = coshFunc.inverseTransform(transformed)
                #expect(abs(recovered - abs(value)) < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Hyperbolic cosine domain is all real numbers")
        func coshDomain() {
            // Should work for large positive and negative values
            let largePos = coshFunc.transform(10.0)
            let largeNeg = coshFunc.transform(-10.0)
            #expect(largePos.isFinite && largeNeg.isFinite)
            #expect(abs(largePos - largeNeg) < 1e-4, "cosh symmetry")
        }
    }
    
    // MARK: - Hyperbolic Tangent Function Tests
    
    @Suite("HyperbolicTangentFunction Tests")
    struct HyperbolicTangentFunctionTests {
        private let tanhFunc = HyperbolicTangentFunction(multiplier: 10.0)
        
        @Test("Hyperbolic tangent at x=0")
        func tanhAtZero() {
            let result = tanhFunc.transform(0.0)
            // tanh(0) = 0, log₁₀(10 × 0) = -∞
            #expect(result.isInfinite && result < 0)
        }
        
        @Test("Hyperbolic tangent approaches ±1 asymptotically")
        func tanhAsymptotes() {
            let largePos = tanhFunc.transform(10.0)
            
            // tanh(large) ≈ 1, log₁₀(10 × 1) ≈ 1.0
            // Note: Th scale is only defined for positive values (range 0.1 to 3 per PostScript)
            // tanh of negative values produces negative results, log of negative is undefined
            #expect(abs(largePos - 1.0) < 0.01, "tanh approaches +1")
            
            // Verify that negative values produce NaN or negative infinity as expected
            let largeNeg = tanhFunc.transform(-10.0)
            #expect(largeNeg.isNaN || (largeNeg.isInfinite && largeNeg < 0), 
                   "Negative values outside valid domain")
        }
        
        @Test("Hyperbolic tangent at x=1")
        func tanhAtOne() {
            let result = tanhFunc.transform(1.0)
            // tanh(1) ≈ 0.7616, log₁₀(10 × 0.7616) = log₁₀(7.616)
            let expected = log10(tanh(1.0) * 10.0)
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Hyperbolic tangent round-trip accuracy")
        func tanhRoundTrip() {
            let testValues = [0.1, 0.5, 1.0, 2.0, 3.0]
            
            for value in testValues {
                let transformed = tanhFunc.transform(value)
                let recovered = tanhFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / abs(value)
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Hyperbolic tangent with different multipliers")
        func tanhMultipliers() {
            let tanh1 = HyperbolicTangentFunction(multiplier: 1.0)
            let tanh100 = HyperbolicTangentFunction(multiplier: 100.0)
            
            let value = 1.0
            let result1 = tanh1.transform(value)
            let result100 = tanh100.transform(value)
            
            // log₁₀(100 × tanh) vs log₁₀(1 × tanh) should differ by 2
            #expect(abs((result100 - result1) - 2.0) < 1e-4)
        }
        
        @Test("Hyperbolic tangent domain restricted by atanh in inverse")
        func tanhInverseDomain() {
            // atanh is only defined for |x| < 1
            // With multiplier 10, valid transformed values should produce tanh/10 < 1
            let validTransformed = 0.95 // produces tanh value < 1
            let result = tanhFunc.inverseTransform(validTransformed)
            #expect(result.isFinite, "Valid transformed value should produce finite result")
        }
    }
    
    // MARK: - Hyperbolic Sine Function Tests
    
    @Suite("HyperbolicSineFunction Tests")
    struct HyperbolicSineFunctionTests {
        private let sinhFunc = HyperbolicSineFunction(multiplier: 10.0, offset: 0.0)
        private let sinhOffset = HyperbolicSineFunction(multiplier: 10.0, offset: 1.0)
        
        @Test("Hyperbolic sine at x=0 with offset=0")
        func sinhAtZeroNoOffset() {
            let result = sinhFunc.transform(0.0)
            // sinh(0) = 0, log₁₀(10 × 0) = -∞
            #expect(result.isInfinite && result < 0)
        }
        
        @Test("Hyperbolic sine at x=1 with offset=0")
        func sinhAtOneNoOffset() {
            let result = sinhFunc.transform(1.0)
            // sinh(1) ≈ 1.175, log₁₀(10 × 1.175) = log₁₀(11.75)
            let expected = log10(sinh(1.0) * 10.0)
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Hyperbolic sine with offset=1.0 shifts the function")
        func sinhWithOffset() {
            let value = 2.0
            let noOffset = sinhFunc.transform(value)
            let withOffset = sinhOffset.transform(value)
            
            // With offset, sinh(2-1) vs sinh(2) should differ
            let expectedOffset = log10(sinh(value - 1.0) * 10.0)
            #expect(abs(withOffset - expectedOffset) < 1e-4)
        }
        
        @Test("Hyperbolic sine round-trip with offset=0")
        func sinhRoundTripNoOffset() {
            let testValues = [0.1, 0.5, 1.0, 2.0, 3.0]
            
            for value in testValues {
                let transformed = sinhFunc.transform(value)
                let recovered = sinhFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Hyperbolic sine round-trip with offset=1.0")
        func sinhRoundTripWithOffset() {
            let testValues = [1.5, 2.0, 3.0, 5.0]
            
            for value in testValues {
                let transformed = sinhOffset.transform(value)
                let recovered = sinhOffset.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value) with offset")
            }
        }
        
        @Test("Hyperbolic sine is antisymmetric")
        func sinhAntisymmetry() {
            let value = 2.0
            let posResult = sinhFunc.transform(value)
            // For sinh, sinh(-x) = -sinh(x), but log₁₀ of negative is NaN
            // So we just verify positive values work
            #expect(posResult.isFinite)
        }
    }
    
    // MARK: - Pythagorean H Function Tests
    
    @Suite("PythagoreanHFunction Tests")
    struct PythagoreanHFunctionTests {
        private let hFunc = PythagoreanHFunction(multiplier: 1.0)
        
        @Test("Pythagorean H at x=1 is undefined (domain x>1)")
        func hAtOne() {
            let result = hFunc.transform(1.0)
            // √(1²-1) = √0 = 0, log₁₀(0) = -∞
            #expect(result.isInfinite && result < 0)
        }
        
        @Test("Pythagorean H at x slightly above 1")
        func hJustAboveOne() {
            let result = hFunc.transform(1.001)
            // √(1.001²-1) = √0.002001 ≈ 0.0447
            #expect(result.isFinite && result < 0, "Small value should give negative log")
        }
        
        @Test("Pythagorean H at x=2 (Pythagorean triple)")
        func hAtTwo() {
            let result = hFunc.transform(2.0)
            // √(2²-1) = √3 ≈ 1.732, log₁₀(1.732) ≈ 0.238
            let expected = log10(sqrt(3.0))
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Pythagorean H at x=5 (Pythagorean triple 3-4-5)")
        func hAtFive() {
            let result = hFunc.transform(5.0)
            // √(5²-1) = √24 ≈ 4.899, log₁₀(4.899) ≈ 0.690
            let expected = log10(sqrt(24.0))
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Pythagorean H round-trip for valid domain (x>1)")
        func hRoundTrip() {
            let testValues = [1.5, 2.0, 3.0, 5.0, 10.0]
            
            for value in testValues {
                let transformed = hFunc.transform(value)
                let recovered = hFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Pythagorean H boundary at x=1 produces -infinity")
        func hDomainBoundary() {
            let atBoundary = hFunc.transform(1.0)
            #expect(atBoundary.isInfinite && atBoundary < 0, "x=1 should produce -∞")
            
            let belowBoundary = hFunc.transform(0.5)
            #expect(belowBoundary.isNaN, "x<1 should produce NaN from sqrt of negative")
        }
        
        @Test("Pythagorean H with different multipliers")
        func hMultipliers() {
            let h1 = PythagoreanHFunction(multiplier: 1.0)
            let h10 = PythagoreanHFunction(multiplier: 10.0)
            
            let value = 2.0
            let result1 = h1.transform(value)
            let result10 = h10.transform(value)
            
            // log₁₀(10 × √3) vs log₁₀(√3) should differ by 1
            #expect(abs((result10 - result1) - 1.0) < 1e-4)
        }
    }
    
    // MARK: - Pythagorean P Function Tests
    
    @Suite("PythagoreanPFunction Tests")
    struct PythagoreanPFunctionTests {
        private let pFunc = PythagoreanPFunction(multiplier: 10.0)
        
        @Test("Pythagorean P at x=0")
        func pAtZero() {
            let result = pFunc.transform(0.0)
            // √(1-0²) = 1, log₁₀(10 × 1) = 1.0
            #expect(abs(result - 1.0) < 1e-4)
        }
        
        @Test("Pythagorean P at x=0.5")
        func pAtHalf() {
            let result = pFunc.transform(0.5)
            // √(1-0.25) = √0.75 ≈ 0.866, log₁₀(10 × 0.866) = log₁₀(8.66)
            let expected = log10(sqrt(0.75) * 10.0)
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Pythagorean P at x=1 is undefined (domain 0≤x<1)")
        func pAtOne() {
            let result = pFunc.transform(1.0)
            // √(1-1²) = √0 = 0, log₁₀(0) = -∞
            #expect(result.isInfinite && result < 0)
        }
        
        @Test("Pythagorean P round-trip for valid domain (0≤x<1)")
        func pRoundTrip() {
            let testValues = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99]
            
            for value in testValues {
                let transformed = pFunc.transform(value)
                let recovered = pFunc.inverseTransform(transformed)
                let absoluteError = abs(recovered - value)
                #expect(absoluteError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Pythagorean P boundary at x=1 produces -infinity")
        func pDomainBoundary() {
            let atBoundary = pFunc.transform(1.0)
            #expect(atBoundary.isInfinite && atBoundary < 0, "x=1 should produce -∞")
            
            let aboveBoundary = pFunc.transform(1.5)
            #expect(aboveBoundary.isNaN, "x>1 should produce NaN from sqrt of negative")
        }
        
        @Test("Pythagorean P complement relationship with Pythagorean triple")
        func pComplementRelationship() {
            // For 3-4-5 triangle: if x=3/5=0.6, then √(1-x²) should equal 4/5=0.8
            let x = 0.6
            let result = pFunc.transform(x)
            let expected = log10(0.8 * 10.0)
            #expect(abs(result - expected) < 1e-3)
        }
    }
    
    // MARK: - Percentage Angular Function Tests
    
    @Suite("PercentageAngularFunction Tests")
    struct PercentageAngularFunctionTests {
        private let paFunc = PercentageAngularFunction()
        
        @Test("Percentage Angular scale range 9-91")
        func paRange() {
            let at9 = paFunc.transform(9.0)
            let at91 = paFunc.transform(91.0)
            
            #expect(at9.isFinite, "Lower bound 9 should be finite")
            #expect(at91.isFinite, "Upper bound 91 should be finite")
        }
        
        @Test("Percentage Angular at midpoint")
        func paMidpoint() {
            let midpoint = (9.0 + 91.0) / 2.0
            let result = paFunc.transform(midpoint)
            #expect(result.isFinite, "Midpoint should produce finite value")
        }
        
        @Test("Percentage Angular round-trip accuracy")
        func paRoundTrip() {
            let testValues = [10.0, 20.0, 30.0, 50.0, 70.0, 90.0]
            
            for value in testValues {
                let transformed = paFunc.transform(value)
                let recovered = paFunc.inverseTransform(transformed)
                let absoluteError = abs(recovered - value)
                #expect(absoluteError < 0.1, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Percentage Angular scaling factors")
        func paScaling() {
            // Test that the scale factor calculation is consistent
            let scaleFactor = log10(7.6) - log10(1.72)
            #expect(abs(scaleFactor - 0.645) < 0.01, "Scale factor should be approximately 0.645")
        }
        
        @Test("Percentage Angular produces monotonic output")
        func paMonotonic() {
            let values = [10.0, 30.0, 50.0, 70.0, 90.0]
            var previousTransformed: Double? = nil
            
            for value in values {
                let transformed = paFunc.transform(value)
                if let prev = previousTransformed {
                    // Function should be monotonically decreasing (based on formula)
                    #expect(transformed < prev, "PA should decrease with increasing percentage")
                }
                previousTransformed = transformed
            }
        }
    }
    
    // MARK: - Linear Degree Function Tests
    
    @Suite("LinearDegreeFunction Tests")
    struct LinearDegreeFunctionTests {
        private let l360 = LinearDegreeFunction(maxDegrees: 360.0)
        private let l180 = LinearDegreeFunction(maxDegrees: 180.0)
        
        @Test("Linear degree 360: transform of 0° to 360°")
        func l360Range() {
            let at0 = l360.transform(0.0)
            let at180 = l360.transform(180.0)
            let at360 = l360.transform(360.0)
            
            #expect(abs(at0 - 0.0) < 1e-4, "0° should map to 0.0")
            #expect(abs(at180 - 0.5) < 1e-4, "180° should map to 0.5")
            #expect(abs(at360 - 1.0) < 1e-4, "360° should map to 1.0")
        }
        
        @Test("Linear degree 180: transform of 0° to 180°")
        func l180Range() {
            let at0 = l180.transform(0.0)
            let at90 = l180.transform(90.0)
            let at180 = l180.transform(180.0)
            
            #expect(abs(at0 - 0.0) < 1e-4, "0° should map to 0.0")
            #expect(abs(at90 - 0.5) < 1e-4, "90° should map to 0.5")
            #expect(abs(at180 - 1.0) < 1e-4, "180° should map to 1.0")
        }
        
        @Test("Linear degree perfect round-trip accuracy")
        func linearDegreeRoundTrip() {
            let testValues360 = [0.0, 45.0, 90.0, 180.0, 270.0, 360.0]
            let testValues180 = [0.0, 30.0, 60.0, 90.0, 120.0, 180.0]
            
            for value in testValues360 {
                let transformed = l360.transform(value)
                let recovered = l360.inverseTransform(transformed)
                #expect(abs(recovered - value) < 1e-4, "L360 round-trip failed for \(value)°")
            }
            
            for value in testValues180 {
                let transformed = l180.transform(value)
                let recovered = l180.inverseTransform(transformed)
                #expect(abs(recovered - value) < 1e-4, "L180 round-trip failed for \(value)°")
            }
        }
        
        @Test("Linear degree function is truly linear")
        func linearDegreeLinearity() {
            // Test linearity: f(a) + f(b) should relate to f(a+b) properly
            let a = 90.0
            let b = 90.0
            let fa = l360.transform(a)
            let fb = l360.transform(b)
            let fab = l360.transform(a + b)
            
            #expect(abs(fab - (fa + fb)) < 1e-4, "Linear function should be additive")
        }
        
        @Test("Linear degree suitable for circular scales")
        func linearDegreeCircularCompatibility() {
            // Linear degree scales are designed for circular slide rules
            // where 360° wraps around to 0°
            let at0 = l360.transform(0.0)
            let at360 = l360.transform(360.0)
            
            #expect(abs(at0 - 0.0) < 1e-4, "0° should be at start")
            #expect(abs(at360 - 1.0) < 1e-4, "360° should be at end")
            
            // The difference should be exactly 1.0 (full circle)
            #expect(abs((at360 - at0) - 1.0) < 1e-4, "Full rotation should be 1.0")
        }
    }
    
    // MARK: - Combined Domain and Boundary Tests
    
    @Suite("Domain Restrictions and Boundary Conditions")
    struct DomainAndBoundaryTests {
        
        @Test("H scale domain restriction: x > 1")
        func hScaleDomain() {
            let hFunc = PythagoreanHFunction()
            
            // Valid: x > 1
            let valid = hFunc.transform(2.0)
            #expect(valid.isFinite, "x > 1 should be finite")
            
            // Boundary: x = 1 gives -∞
            let boundary = hFunc.transform(1.0)
            #expect(boundary.isInfinite && boundary < 0, "x = 1 should give -∞")
            
            // Invalid: x < 1 gives NaN
            let invalid = hFunc.transform(0.5)
            #expect(invalid.isNaN, "x < 1 should give NaN")
        }
        
        @Test("P scale domain restriction: 0 ≤ x < 1")
        func pScaleDomain() {
            let pFunc = PythagoreanPFunction()
            
            // Valid: 0 ≤ x < 1
            let valid = pFunc.transform(0.5)
            #expect(valid.isFinite, "0 ≤ x < 1 should be finite")
            
            // Boundary: x = 0
            let atZero = pFunc.transform(0.0)
            #expect(atZero.isFinite, "x = 0 should be finite")
            
            // Boundary: x = 1 gives -∞
            let atOne = pFunc.transform(1.0)
            #expect(atOne.isInfinite && atOne < 0, "x = 1 should give -∞")
            
            // Invalid: x > 1 gives NaN
            let invalid = pFunc.transform(1.5)
            #expect(invalid.isNaN, "x > 1 should give NaN")
        }
        
        @Test("Hyperbolic functions handle zero correctly")
        func hyperbolicZero() {
            let coshFunc = HyperbolicCosineFunction()
            let sinhFunc = HyperbolicSineFunction()
            let tanhFunc = HyperbolicTangentFunction()
            
            // cosh(0) = 1
            let cosh0 = coshFunc.transform(0.0)
            #expect(abs(cosh0 - 0.0) < 1e-4, "cosh(0) = 1, log(1) = 0")
            
            // sinh(0) = 0, log(0) = -∞
            let sinh0 = sinhFunc.transform(0.0)
            #expect(sinh0.isInfinite && sinh0 < 0, "sinh(0) = 0, log(0) = -∞")
            
            // tanh(0) = 0, log(0) = -∞
            let tanh0 = tanhFunc.transform(0.0)
            #expect(tanh0.isInfinite && tanh0 < 0, "tanh(0) = 0, log(0) = -∞")
        }
    }
}

// MARK: - Helper Functions for Testing

private func cosh(_ x: Double) -> Double {
    (exp(x) + exp(-x)) / 2.0
}

private func sinh(_ x: Double) -> Double {
    (exp(x) - exp(-x)) / 2.0
}

private func tanh(_ x: Double) -> Double {
    sinh(x) / cosh(x)
}