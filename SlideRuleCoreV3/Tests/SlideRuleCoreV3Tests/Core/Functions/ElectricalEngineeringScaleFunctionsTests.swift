import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive test suite for electrical engineering scale functions
/// Tests transform/inverse accuracy, multi-cycle behavior, inverted scales, and special constants
///
/// Uses parametric testing via FunctionTestCase for systematic coverage of:
/// - Multi-cycle logarithmic scales (XL, Xc, F, L, Cz)
/// - Impedance scales (Z)
/// - Inverted scales (Xc, Cf, Fo)
/// - Nonlinear scales (R, P)
@Suite("Electrical Engineering Scale Functions")
struct ElectricalEngineeringScaleFunctionsTests {
    
    // MARK: - Parametric Tests (All EE Functions)
    
    @Test("Round-trip accuracy", arguments: ScaleTestData.electricalEngineeringFunctions)
    func roundTrip(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testRoundTrip(
            testCase.function,
            values: testCase.testValues,
            tolerance: testCase.tolerance
        )
    }
    
    @Test("Known values", arguments: ScaleTestData.electricalEngineeringFunctions)
    func knownValues(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testKnownValues(
            testCase.function,
            pairs: testCase.knownPairs,
            tolerance: testCase.tolerance
        )
    }
    
    @Test("Boundary behavior", arguments: ScaleTestData.electricalEngineeringFunctions)
    func boundaries(testCase: FunctionTestCase) {
        FunctionRoundTripTester.testBoundaries(
            testCase.function,
            cases: testCase.boundaryTests
        )
    }
    
    // MARK: - Multi-Cycle Behavior Tests
    
    @Suite("Multi-Cycle Logarithmic Scales")
    struct MultiCycleTests {
        
        /// Test data for multi-cycle scales: (name, function, cycles)
        private static let multiCycleScales: [(String, any ScaleFunction, Int)] = [
            ("XL", InductiveReactanceFunction(cycles: 12), 12),
            ("Xc", CapacitiveReactanceFunction(cycles: 12), 12),
            ("F", FrequencyFunction(cycles: 12), 12),
            ("L", InductanceFunction(cycles: 12), 12),
            ("Z", ImpedanceFunction(cycles: 6), 6),
            ("Cz", CapacitanceImpedanceFunction(cycles: 12), 12)
        ]
        
        @Test("Multi-cycle scales maintain uniform decade spacing")
        func multiCycleLogarithmicSpacing() {
            for (name, function, cycles) in Self.multiCycleScales {
                let v1 = 1.0
                let v10 = 10.0
                let v100 = 100.0
                
                let r1 = function.transform(v1)
                let r10 = function.transform(v10)
                let r100 = function.transform(v100)
                
                let diff1 = abs(r10 - r1)
                let diff2 = abs(r100 - r10)
                let expectedDiff = 1.0 / Double(cycles)
                
                #expect(abs(diff1 - expectedDiff) < 1e-3, "\(name) decade spacing")
                #expect(abs(diff2 - expectedDiff) < 1e-3, "\(name) decade spacing")
            }
        }
        
        @Test("12-cycle scales span approximately 1.0 over 12 orders of magnitude")
        func twelveCycleSpan() {
            let functions: [(String, any ScaleFunction)] = [
                ("XL", InductiveReactanceFunction(cycles: 12)),
                ("F", FrequencyFunction(cycles: 12)),
                ("L", InductanceFunction(cycles: 12)),
                ("Cz", CapacitanceImpedanceFunction(cycles: 12))
            ]
            
            for (name, function) in functions {
                let lowValue = 1e-6
                let highValue = 1e6
                let span = function.transform(highValue) - function.transform(lowValue)
                #expect(abs(span - 1.0) < 0.1, "\(name) 12 cycles should span ~1.0")
            }
        }
        
        @Test("6-cycle scales span approximately 1.0 over 6 orders of magnitude")
        func sixCycleSpan() {
            let zFunc = ImpedanceFunction(cycles: 6)
            let foFunc = FrequencyWavelengthFunction(cycles: 6)
            
            let span1 = zFunc.transform(1e3) - zFunc.transform(1e-3)
            let span2 = abs(foFunc.transform(1e9) - foFunc.transform(1e3))
            
            #expect(abs(span1 - 1.0) < 0.01, "Z 6 cycles should span 1.0")
            #expect(abs(span2 - 1.0) < 0.01, "Fo 6 cycles should span 1.0")
        }
    }
    
    // MARK: - Inverted Scale Tests
    
    @Suite("Inverted Scales")
    struct InvertedScaleTests {
        
        @Test("Inverted scales consistently decrease with increasing values")
        func invertedScalesMonotonic() {
            let xc = CapacitiveReactanceFunction()
            let cf = CapacitanceFrequencyFunction()
            let fo = FrequencyWavelengthFunction()
            
            let values = [1.0, 10.0, 100.0, 1000.0]
            
            // Test Xc
            var prevXc: Double? = nil
            for value in values {
                let result = xc.transform(value)
                if let prev = prevXc {
                    #expect(result < prev, "Xc should decrease with increasing value")
                }
                prevXc = result
            }
            
            // Test Cf
            var prevCf: Double? = nil
            for value in values {
                let result = cf.transform(value)
                if let prev = prevCf {
                    #expect(result < prev, "Cf should decrease with increasing value")
                }
                prevCf = result
            }
            
            // Test Fo
            var prevFo: Double? = nil
            for value in values {
                let result = fo.transform(value)
                if let prev = prevFo {
                    #expect(result < prev, "Fo should decrease with increasing value")
                }
                prevFo = result
            }
        }
        
        @Test("Capacitive reactance is reciprocal of inductive reactance pattern")
        func xcReciprocalRelationship() {
            let xc = CapacitiveReactanceFunction()
            // Higher fC = lower reactance = lower position on inverted scale
            let value1 = 1.0
            let value10 = 10.0
            
            let r1 = xc.transform(value1)
            let r10 = xc.transform(value10)
            
            #expect(r1 > r10, "Higher fC should give lower position")
        }
    }
    
    // MARK: - Nonlinear Scale Tests
    
    @Suite("Nonlinear Scales")
    struct NonlinearScaleTests {
        
        @Test("Reflection coefficient has nonlinear (1/x) characteristic")
        func reflectionNonlinear() {
            let r = ReflectionCoefficientFunction()
            let testValues = [1.0, 2.0, 4.0, 8.0]
            
            let r1 = r.transform(testValues[0])
            let r2 = r.transform(testValues[1])
            let r3 = r.transform(testValues[2])
            let r4 = r.transform(testValues[3])
            
            let rdiff1 = r2 - r1
            let rdiff2 = r3 - r2
            let rdiff3 = r4 - r3
            
            // 1/x spacing is nonlinear
            #expect(abs(rdiff1 - rdiff2) > 0.001, "Reflection spacing nonlinear")
            #expect(abs(rdiff2 - rdiff3) > 0.001, "Reflection spacing nonlinear")
        }
        
        @Test("Power ratio has quadratic (x²) characteristic")
        func powerRatioQuadratic() {
            let p = PowerRatioFunction()
            
            // Test quadratic formula: (x²/196) × 0.477 + 0.523
            let values = [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0]
            
            for value in values {
                let result = p.transform(value)
                let expected = ((value * value) / 196.0) * 0.477 + 0.523
                #expect(abs(result - expected) < 1e-4, "Quadratic formula for \(value)")
            }
        }
        
        @Test("Power ratio has nonlinear spacing")
        func powerRatioNonlinearSpacing() {
            let p = PowerRatioFunction()
            
            let p1 = p.transform(2.0)
            let p2 = p.transform(4.0)
            let p3 = p.transform(6.0)
            let p4 = p.transform(8.0)
            
            let pdiff1 = p2 - p1
            let pdiff2 = p3 - p2
            let pdiff3 = p4 - p3
            
            #expect(abs(pdiff1 - pdiff2) > 0.001, "Power ratio spacing nonlinear")
            #expect(abs(pdiff2 - pdiff3) > 0.001, "Power ratio spacing nonlinear")
        }
    }
    
    // MARK: - Special Constants Tests
    
    @Suite("Special Constants")
    struct SpecialConstantsTests {
        
        @Test("EE constants are defined correctly")
        func specialConstants() {
            #expect(abs(EEConstants.cfScaleFactor - 3.94784212) < 1e-6, "Cf scale factor")
            #expect(abs(EEConstants.reflectionScaling - 0.472) < 1e-6, "Reflection scaling")
            #expect(abs(EEConstants.powerRatioScale - 0.477) < 1e-6, "Power ratio scale")
            #expect(abs(EEConstants.powerRatioOffset - 0.523) < 1e-6, "Power ratio offset")
        }
        
        @Test("Capacitance frequency scale factor is applied correctly")
        func cfScaleFactorApplied() {
            let cf = CapacitanceFrequencyFunction(cycles: 11)
            let fC = 100.0
            let result = cf.transform(fC)
            
            let scaleFactor = 3.94784212
            let logValue = log10(scaleFactor * fC) / 12.0
            let expected = 1.0 - logValue
            
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Reflection coefficient uses scaling constant correctly")
        func reflectionScalingApplied() {
            let r = ReflectionCoefficientFunction()
            let vswr = 2.0
            let result = r.transform(vswr)
            let expected = (0.5 / vswr) * 0.472
            
            #expect(abs(result - expected) < 1e-4)
        }
    }
}
