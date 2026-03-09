import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Priority 2: Comprehensive ScaleFunction Implementations Test Suite
/// Validates all scale function types and their transform/inverse behaviors
@Suite("Scale Mathematical Functions")
struct ScaleFunctionImplementationsTests {
    
    // MARK: - Parametric Round-Trip Tests
    
    @Test("Round-trip accuracy", arguments: ScaleTestData.allFunctions)
    func roundTripAccuracy(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testRoundTrip(
            testCase.function,
            values: testCase.testValues
        )
    }
    
    @Test("Known value pairs", arguments: ScaleTestData.allFunctions)
    func knownValuePairs(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testKnownValues(
            testCase.function,
            pairs: testCase.knownPairs,
            tolerance: testCase.tolerance
        )
    }
    
    @Test("Boundary behavior", arguments: ScaleTestData.allFunctions)
    func boundaryBehavior(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testBoundaries(
            testCase.function,
            cases: testCase.boundaryTests
        )
    }
    
    // MARK: - Specialized Function Tests
    
    @Suite("LinearFunction Identity Tests")
    struct LinearFunctionTests {
        private let linearFunc = LinearFunction()
        
        @Test("Linear function is identity transform")
        func identityTransform() {
            let testValues = [0.0, 0.5, 1.0, 5.0, 10.0, 100.0]
            
            for value in testValues {
                let result = linearFunc.transform(value)
                #expect(result == value, "Linear transform should be identity")
            }
        }
        
        @Test("Linear inverse is also identity")
        func identityInverse() {
            let testValues = [0.0, 0.5, 1.0, 5.0, 10.0, 100.0]
            
            for value in testValues {
                let result = linearFunc.inverseTransform(value)
                #expect(result == value, "Linear inverse should be identity")
            }
        }
        
        @Test("Linear function handles negative values")
        func negativeValues() {
            let result = linearFunc.transform(-5.0)
            #expect(result == -5.0)
        }
    }
    
    @Suite("SineFunction Multiplier Tests")
    struct SineFunctionTests {
        
        @Test("Sine function with different multipliers produces different transforms")
        func differentMultipliers() {
            let sine10 = SineFunction(multiplier: 10.0)
            let sine100 = SineFunction(multiplier: 100.0)
            
            let angle = 30.0
            let result10 = sine10.transform(angle)
            let result100 = sine100.transform(angle)
            
            // sin(30°) = 0.5
            // log₁₀(10 × 0.5) vs log₁₀(100 × 0.5) should differ by 1
            #expect(abs((result100 - result10) - 1.0) < 1e-10)
        }
        
        @Test("Sine of 30° equals 0.5 before multiplier")
        func sine30Degrees() {
            let sineFunc = SineFunction(multiplier: 1.0)
            // With multiplier 1: log₁₀(sin(30°)) = log₁₀(0.5)
            let result = sineFunc.transform(30.0)
            let expected = log10(0.5)
            #expect(abs(result - expected) < 1e-10)
        }
    }
    
    @Suite("TangentFunction Edge Cases")
    struct TangentFunctionTests {
        
        @Test("Tangent function handles steep angles near 90°")
        func steepAngles() {
            let tanFunc = TangentFunction(multiplier: 10.0)
            let angle = 89.0
            let result = tanFunc.transform(angle)
            
            // tan(89°) is very large, so result should be positive and > 1
            #expect(result > 1.0, "Steep angle should produce large transform value")
        }
        
        @Test("Tangent of 45° equals 1.0 before multiplier")
        func tangent45Degrees() {
            let tanFunc = TangentFunction(multiplier: 1.0)
            // With multiplier 1: log₁₀(tan(45°)) = log₁₀(1.0) = 0
            let result = tanFunc.transform(45.0)
            #expect(abs(result - 0.0) < 1e-10)
        }
    }
    
    @Suite("CustomFunction Tests")
    struct CustomFunctionTests {
        
        @Test("Custom function executes provided closures correctly")
        func executesClosures() {
            let customFunc = CustomFunction(
                name: "square",
                transform: { x in x * x },
                inverseTransform: { x in sqrt(x) }
            )
            
            let value = 5.0
            let transformed = customFunc.transform(value)
            #expect(transformed == 25.0)
            
            let recovered = customFunc.inverseTransform(transformed)
            #expect(abs(recovered - value) < 1e-10)
        }
        
        @Test("Custom function supports arbitrary mathematical operations")
        func arbitraryOperations() {
            // Cube function
            let cubeFunc = CustomFunction(
                name: "cube",
                transform: { x in pow(x, 3.0) },
                inverseTransform: { x in pow(x, 1.0/3.0) }
            )
            
            let value = 2.0
            let transformed = cubeFunc.transform(value)
            #expect(abs(transformed - 8.0) < 1e-10)
            
            let recovered = cubeFunc.inverseTransform(transformed)
            #expect(abs(recovered - value) < 1e-10)
        }
        
        @Test("Custom function can implement reciprocal scales")
        func reciprocalScale() {
            let reciprocalFunc = CustomFunction(
                name: "reciprocal",
                transform: { x in -log10(x) },
                inverseTransform: { x in pow(10.0, -x) }
            )
            
            let value = 2.0
            let transformed = reciprocalFunc.transform(value)
            let expected = -log10(2.0)
            #expect(abs(transformed - expected) < 1e-10)
            
            let recovered = reciprocalFunc.inverseTransform(transformed)
            #expect(abs(recovered - value) < 1e-10)
        }
    }
    
    @Suite("Special Mathematical Values")
    struct SpecialMathematicalValues {
        
        @Test("Logarithmic function with value π")
        func logarithmicWithPi() {
            let logFunc = LogarithmicFunction()
            let result = logFunc.transform(.pi)
            let expected = log10(Double.pi)
            #expect(abs(result - expected) < 1e-10)
        }
        
        @Test("Natural log function with value e²")
        func naturalLogWithESquared() {
            let lnFunc = NaturalLogFunction()
            let eSquared = Double.e * Double.e
            let result = lnFunc.transform(eSquared)
            #expect(abs(result - 2.0) < 1e-10, "ln(e²) should equal 2")
        }
    }
}
