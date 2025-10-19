import Testing
import Foundation
@testable import SlideRuleCore

/// Priority 2: Comprehensive ScaleFunction Implementations Test Suite
/// Validates all scale function types and their transform/inverse behaviors
@Suite("ScaleFunction Implementations")
struct ScaleFunctionImplementationsSuite {
    
    @Suite("LogarithmicFunction Tests")
    struct LogarithmicFunctionTests {
        private let logFunc = LogarithmicFunction()
        
        @Test("Logarithmic function transforms value 1 to 0.0")
        func transformValue1() {
            let result = logFunc.transform(1.0)
            #expect(result == 0.0)
        }
        
        @Test("Logarithmic function transforms value 10 to 1.0")
        func transformValue10() {
            let result = logFunc.transform(10.0)
            #expect(result == 1.0)
        }
        
        @Test("Logarithmic function transforms value 100 to 2.0")
        func transformValue100() {
            let result = logFunc.transform(100.0)
            #expect(abs(result - 2.0) < 1e-10)
        }
        
        @Test("Logarithmic inverse transform of 0.0 returns 1.0")
        func inverseTransform0() {
            let result = logFunc.inverseTransform(0.0)
            #expect(abs(result - 1.0) < 1e-10)
        }
        
        @Test("Logarithmic inverse transform of 0.5 returns approximately 3.16")
        func inverseTransformHalf() {
            let result = logFunc.inverseTransform(0.5)
            let expected = sqrt(10.0)
            #expect(abs(result - expected) < 1e-6)
        }
        
        @Test("Logarithmic inverse transform of 1.0 returns 10.0")
        func inverseTransform1() {
            let result = logFunc.inverseTransform(1.0)
            #expect(abs(result - 10.0) < 1e-10)
        }
        
        @Test("Logarithmic round-trip accuracy for various values")
        func roundTripAccuracy() {
            let testValues = [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0]
            
            for value in testValues {
                let transformed = logFunc.transform(value)
                let recovered = logFunc.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-10, "Round-trip failed for value \(value)")
            }
        }
    }
    
    @Suite("LogLogFunction Tests")
    struct LogLogFunctionTests {
        private let llFunc = LogLogFunction()
        
        @Test("LogLog function handles value e correctly")
        func transformValueE() {
            // log(log(e)) = log(1) = 0
            let result = llFunc.transform(Double.e)
            #expect(abs(result - 0.0) < 1e-10)
        }
        
        @Test("LogLog function handles small values near e correctly")
        func transformNearE() {
            let value = 2.8
            let result = llFunc.transform(value)
            let expected = log10(log(value))
            #expect(abs(result - expected) < 1e-10)
        }
        
        @Test("LogLog inverse transform maintains accuracy")
        func inverseAccuracy() {
            let testTransformed = [-0.5, 0.0, 0.5, 1.0]
            
            for t in testTransformed {
                let value = llFunc.inverseTransform(t)
                let recovered = llFunc.transform(value)
                
                #expect(abs(recovered - t) < 1e-6, "Inverse failed for transformed value \(t)")
            }
        }
        
        @Test("LogLog round-trip for values > e")
        func roundTripForValidDomain() {
            let testValues = [2.8, 3.0, 5.0, 10.0, 100.0]
            
            for value in testValues {
                let transformed = llFunc.transform(value)
                let recovered = llFunc.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-6, "Round-trip failed for value \(value)")
            }
        }
    }
    
    @Suite("NaturalLogFunction Tests")
    struct NaturalLogFunctionTests {
        private let lnFunc = NaturalLogFunction()
        
        @Test("Natural log function transforms value 1 to 0.0")
        func transformValue1() {
            let result = lnFunc.transform(1.0)
            #expect(result == 0.0)
        }
        
        @Test("Natural log function transforms value e to 1.0")
        func transformValueE() {
            let result = lnFunc.transform(Double.e)
            #expect(abs(result - 1.0) < 1e-10)
        }
        
        @Test("Natural log inverse transform uses exp(x)")
        func inverseUsesExp() {
            let result = lnFunc.inverseTransform(1.0)
            #expect(abs(result - Double.e) < 1e-10)
        }
        
        @Test("Natural log round-trip maintains accuracy")
        func roundTripAccuracy() {
            let testValues = [1.0, 2.0, Double.e, 5.0, 10.0]
            
            for value in testValues {
                let transformed = lnFunc.transform(value)
                let recovered = lnFunc.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-10, "Round-trip failed for value \(value)")
            }
        }
    }
    
    @Suite("LinearFunction Tests")
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
        
        @Test("Linear function perfect round-trip accuracy")
        func perfectRoundTrip() {
            let testValues = [0.0, 0.1, 0.5, 1.0, 10.0]
            
            for value in testValues {
                let transformed = linearFunc.transform(value)
                let recovered = linearFunc.inverseTransform(transformed)
                #expect(recovered == value, "Linear round-trip should be perfect")
            }
        }
    }
    
    @Suite("SineFunction Tests")
    struct SineFunctionTests {
        
        @Test("Sine function with multiplier 10 transforms 30° correctly")
        func sineWithMultiplier10() {
            let sineFunc = SineFunction(multiplier: 10.0)
            // sin(30°) = 0.5, so log₁₀(10 × 0.5) = log₁₀(5)
            let result = sineFunc.transform(30.0)
            let expected = log10(5.0)
            #expect(abs(result - expected) < 1e-6)
        }
        
        @Test("Sine function with multiplier 10 transforms 90° to log₁₀(10) = 1.0")
        func sineAt90Degrees() {
            let sineFunc = SineFunction(multiplier: 10.0)
            // sin(90°) = 1.0, so log₁₀(10 × 1.0) = 1.0
            let result = sineFunc.transform(90.0)
            #expect(abs(result - 1.0) < 1e-10)
        }
        
        @Test("Sine function round-trip maintains angle accuracy")
        func sineRoundTrip() {
            let sineFunc = SineFunction(multiplier: 10.0)
            let testAngles = [5.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0]
            
            for angle in testAngles {
                let transformed = sineFunc.transform(angle)
                let recovered = sineFunc.inverseTransform(transformed)
                
                #expect(abs(recovered - angle) < 0.01, "Round-trip failed for angle \(angle)°")
            }
        }
        
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
    }
    
    @Suite("TangentFunction Tests")
    struct TangentFunctionTests {
        
        @Test("Tangent function with multiplier 10 transforms 45° to 1.0")
        func tangentAt45Degrees() {
            let tanFunc = TangentFunction(multiplier: 10.0)
            // tan(45°) = 1.0, so log₁₀(10 × 1.0) = 1.0
            let result = tanFunc.transform(45.0)
            #expect(abs(result - 1.0) < 1e-10)
        }
        
        @Test("Tangent function with multiplier 10 transforms small angles correctly")
        func tangentSmallAngle() {
            let tanFunc = TangentFunction(multiplier: 10.0)
            // tan(5.71°) ≈ 0.1, so log₁₀(10 × 0.1) = log₁₀(1) = 0
            let angle = atan(0.1) * 180.0 / .pi
            let result = tanFunc.transform(angle)
            #expect(abs(result - 0.0) < 1e-6)
        }
        
        @Test("Tangent function round-trip maintains angle accuracy")
        func tangentRoundTrip() {
            let tanFunc = TangentFunction(multiplier: 10.0)
            let testAngles = [5.0, 10.0, 20.0, 30.0, 45.0, 60.0, 75.0, 84.0]
            
            for angle in testAngles {
                let transformed = tanFunc.transform(angle)
                let recovered = tanFunc.inverseTransform(transformed)
                
                #expect(abs(recovered - angle) < 0.1, "Round-trip failed for angle \(angle)°")
            }
        }
        
        @Test("Tangent function handles steep angles near 90°")
        func steepAngles() {
            let tanFunc = TangentFunction(multiplier: 10.0)
            let angle = 89.0
            let result = tanFunc.transform(angle)
            
            // tan(89°) is very large, so result should be positive and > 1
            #expect(result > 1.0, "Steep angle should produce large transform value")
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
    
    @Suite("Function Round-Trip Accuracy")
    struct RoundTripAccuracy {
        
        @Test("All standard functions maintain round-trip accuracy")
        func allFunctionsRoundTrip() {
            let functions: [(name: String, function: any ScaleFunction, testValue: Double)] = [
                ("Logarithmic", LogarithmicFunction(), 5.0),
                ("LogLog", LogLogFunction(), 5.0),
                ("NaturalLog", NaturalLogFunction(), 5.0),
                ("Linear", LinearFunction(), 5.0),
                ("Sine(10)", SineFunction(multiplier: 10.0), 30.0),
                ("Tangent(10)", TangentFunction(multiplier: 10.0), 30.0)
            ]
            
            for (name, function, value) in functions {
                let transformed = function.transform(value)
                let recovered = function.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-4, "\(name) round-trip failed for value \(value)")
            }
        }
    }
    
    @Suite("Domain Restrictions and Special Values")
    struct DomainRestrictions {
        
        @Test("Logarithmic function domain excludes zero and negative values")
        func logarithmicDomain() {
            let logFunc = LogarithmicFunction()
            
            // Positive values should work
            let positive = logFunc.transform(5.0)
            #expect(positive.isFinite)
            
            // Zero should produce -infinity
            let zero = logFunc.transform(0.0)
            #expect(zero.isInfinite && zero < 0)
            
            // Negative values should produce NaN
            let negative = logFunc.transform(-5.0)
            #expect(negative.isNaN)
        }
        
        @Test("LogLog function requires values greater than 1")
        func logLogDomain() {
            let llFunc = LogLogFunction()
            
            // Value > e should work
            let valid = llFunc.transform(5.0)
            #expect(valid.isFinite)
            
            // Value = e should give 0
            let atE = llFunc.transform(Double.e)
            #expect(abs(atE - 0.0) < 1e-10)
            
            // Value between 1 and e should give negative result
            let between = llFunc.transform(2.0)
            #expect(between < 0.0 && between.isFinite)
        }
        
        @Test("Sine function domain is 0° to 90°")
        func sineDomain() {
            let sineFunc = SineFunction(multiplier: 10.0)
            
            // 0° should give -infinity (sin(0°) = 0, log₁₀(0) = -∞)
            let at0 = sineFunc.transform(0.0)
            #expect(at0.isInfinite && at0 < 0)
            
            // 90° should give finite value
            let at90 = sineFunc.transform(90.0)
            #expect(at90.isFinite)
            
            // Small positive angle should work
            let small = sineFunc.transform(5.0)
            #expect(small.isFinite, "Small positive angle should produce finite value")
        }
        
        @Test("Tangent function handles full quadrant range")
        func tangentDomain() {
            let tanFunc = TangentFunction(multiplier: 10.0)
            
            // Small angle
            let small = tanFunc.transform(1.0)
            #expect(small.isFinite)
            
            // 45°
            let at45 = tanFunc.transform(45.0)
            #expect(abs(at45 - 1.0) < 1e-10)
            
            // Near 90° (but not exactly, to avoid infinity)
            let near90 = tanFunc.transform(89.0)
            #expect(near90.isFinite && near90 > 1.0)
        }
    }
    
    @Suite("Function Behavior with Special Mathematical Values")
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
        
        @Test("Linear function handles negative values")
        func linearWithNegative() {
            let linearFunc = LinearFunction()
            let result = linearFunc.transform(-5.0)
            #expect(result == -5.0)
        }
        
        @Test("Sine of 30° equals 0.5 before multiplier")
        func sine30Degrees() {
            let sineFunc = SineFunction(multiplier: 1.0)
            // With multiplier 1: log₁₀(sin(30°)) = log₁₀(0.5)
            let result = sineFunc.transform(30.0)
            let expected = log10(0.5)
            #expect(abs(result - expected) < 1e-10)
        }
        
        @Test("Tangent of 45° equals 1.0 before multiplier")
        func tangent45Degrees() {
            let tanFunc = TangentFunction(multiplier: 1.0)
            // With multiplier 1: log₁₀(tan(45°)) = log₁₀(1.0) = 0
            let result = tanFunc.transform(45.0)
            #expect(abs(result - 0.0) < 1e-10)
        }
    }
}