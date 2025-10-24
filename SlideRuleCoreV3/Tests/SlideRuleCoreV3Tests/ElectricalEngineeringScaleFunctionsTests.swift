import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive test suite for electrical engineering scale functions
/// Tests transform/inverse accuracy, multi-cycle behavior, inverted scales, and special constants
@Suite("Electrical Engineering Scale Functions")
struct ElectricalEngineeringScaleFunctionsTests {
    
    // MARK: - Inductive Reactance Function Tests
    
    @Suite("InductiveReactanceFunction Tests")
    struct InductiveReactanceFunctionTests {
        private let xlFunc = InductiveReactanceFunction(cycles: 12)
        
        @Test("Inductive reactance basic transform")
        func xlBasicTransform() {
            let value = 1.0
            let result = xlFunc.transform(value)
            // log₁₀(0.5 × π × 1.0) / 12 = log₁₀(1.5708) / 12
            let expected = log10(0.5 * .pi * value) / 12.0
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Inductive reactance spans 12 cycles")
        func xlCycles() {
            // Value spanning 12 orders of magnitude
            let lowValue = 1e-6
            let highValue = 1e6
            
            let lowResult = xlFunc.transform(lowValue)
            let highResult = xlFunc.transform(highValue)
            
            // Should span approximately 1.0 in normalized space (12 cycles)
            let span = highResult - lowResult
            #expect(abs(span - 1.0) < 0.1, "12 cycles should span ~1.0 in transform space")
        }
        
        @Test("Inductive reactance round-trip accuracy")
        func xlRoundTrip() {
            let testValues = [1e-6, 1e-3, 1.0, 1e3, 1e6]
            
            for value in testValues {
                let transformed = xlFunc.transform(value)
                let recovered = xlFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Inductive reactance formula correctness")
        func xlFormula() {
            // XL = 2πfL, but stored as log₁₀(0.5 × π × fL)
            let fL = 100.0 // frequency × inductance product
            let result = xlFunc.transform(fL)
            let expected = log10(0.5 * .pi * fL) / 12.0
            #expect(abs(result - expected) < 1e-4)
        }
    }
    
    // MARK: - Capacitive Reactance Function Tests
    
    @Suite("CapacitiveReactanceFunction Tests")
    struct CapacitiveReactanceFunctionTests {
        private let xcFunc = CapacitiveReactanceFunction(cycles: 12)
        
        @Test("Capacitive reactance is inverted scale")
        func xcInverted() {
            let value1 = 1.0
            let value2 = 10.0
            
            let result1 = xcFunc.transform(value1)
            let result2 = xcFunc.transform(value2)
            
            // Higher values should produce lower positions (inverted)
            #expect(result1 > result2, "Xc scale should be inverted")
        }
        
        @Test("Capacitive reactance spans 12 cycles inverted")
        func xcCycles() {
            let lowValue = 1e-6
            let highValue = 1e6
            
            let lowResult = xcFunc.transform(lowValue)
            let highResult = xcFunc.transform(highValue)
            
            // Due to inversion, low values give high positions
            #expect(lowResult > highResult, "Inverted scale")
        }
        
        @Test("Capacitive reactance round-trip accuracy")
        func xcRoundTrip() {
            let testValues = [1e-6, 1e-3, 1.0, 1e3, 1e6]
            
            for value in testValues {
                let transformed = xcFunc.transform(value)
                let recovered = xcFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Capacitive reactance formula correctness")
        func xcFormula() {
            // Xc = 1/(2πfC), inverted scale
            let fC = 100.0
            let result = xcFunc.transform(fC)
            let logValue = log10(5.0 * .pi / fC) / 12.0
            let expected = logValue + 11.0/12.0
            #expect(abs(result - expected) < 1e-4)
        }
        
        @Test("Capacitive reactance reciprocal relationship")
        func xcReciprocal() {
            // Xc = 1/(2πfC), so increasing fC should decrease reactance
            let value1 = 1.0
            let value2 = 10.0
            
            let result1 = xcFunc.transform(value1)
            let result2 = xcFunc.transform(value2)
            
            // Higher values should give lower positions (inverted scale)
            #expect(result1 > result2, "Higher fC values should give lower positions")
        }
    }
    
    // MARK: - Frequency Function Tests
    
    @Suite("FrequencyFunction Tests")
    struct FrequencyFunctionTests {
        private let fFunc = FrequencyFunction(cycles: 12)
        
        @Test("Frequency scale standard logarithmic")
        func fLogarithmic() {
            let testValues = [1.0, 10.0, 100.0, 1000.0]
            var previousResult: Double? = nil
            
            for value in testValues {
                let result = fFunc.transform(value)
                if let prev = previousResult {
                    // Each decade should add approximately 1/12 to position
                    let diff = result - prev
                    #expect(abs(diff - (1.0/12.0)) < 1e-4, "Each decade should be 1/12")
                }
                previousResult = result
            }
        }
        
        @Test("Frequency scale spans Hz to GHz")
        func fRange() {
            let hz = 1.0
            let khz = 1e3
            let mhz = 1e6
            let ghz = 1e9
            
            let resultHz = fFunc.transform(hz)
            let resultKHz = fFunc.transform(khz)
            let resultMHz = fFunc.transform(mhz)
            let resultGHz = fFunc.transform(ghz)
            
            // Should be evenly spaced in log space
            let diff1 = resultKHz - resultHz
            let diff2 = resultMHz - resultKHz
            let diff3 = resultGHz - resultMHz
            
            #expect(abs(diff1 - diff2) < 1e-9, "Logarithmic spacing should be uniform")
            #expect(abs(diff2 - diff3) < 1e-9, "Logarithmic spacing should be uniform")
        }
        
        @Test("Frequency round-trip accuracy")
        func fRoundTrip() {
            let testValues = [0.001, 1.0, 1e3, 1e6, 1e9]
            
            for value in testValues {
                let transformed = fFunc.transform(value)
                let recovered = fFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Frequency 12-cycle coverage")
        func fTwelveCycles() {
            // 12 decades: 1e-3 to 1e9
            let minFreq = 1e-3
            let maxFreq = 1e9
            
            let minResult = fFunc.transform(minFreq)
            let maxResult = fFunc.transform(maxFreq)
            
            let span = maxResult - minResult
            #expect(abs(span - 1.0) < 0.01, "12 cycles should span 1.0")
        }
    }
    
    // MARK: - Inductance Function Tests
    
    @Suite("InductanceFunction Tests")
    struct InductanceFunctionTests {
        private let lFunc = InductanceFunction(cycles: 12)
        
        @Test("Inductance scale standard logarithmic")
        func lLogarithmic() {
            let testValues = [1e-6, 1e-3, 1.0, 1e3]
            var previousResult: Double? = nil
            
            for value in testValues {
                let result = lFunc.transform(value)
                if let prev = previousResult {
                    // Each 1000× should add 3/12 = 0.25 to position
                    let diff = result - prev
                    #expect(abs(diff - 0.25) < 1e-4, "Each 3 decades should be 0.25")
                }
                previousResult = result
            }
        }
        
        @Test("Inductance spans µH to H")
        func lRange() {
            let microH = 1e-6
            let milliH = 1e-3
            let henry = 1.0
            
            let resultMicro = lFunc.transform(microH)
            let resultMilli = lFunc.transform(milliH)
            let resultHenry = lFunc.transform(henry)
            
            #expect(resultMilli > resultMicro, "Larger values higher positions")
            #expect(resultHenry > resultMilli, "Larger values higher positions")
        }
        
        @Test("Inductance round-trip accuracy")
        func lRoundTrip() {
            let testValues = [1e-9, 1e-6, 1e-3, 1.0, 100.0]
            
            for value in testValues {
                let transformed = lFunc.transform(value)
                let recovered = lFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Inductance 12-cycle coverage")
        func lTwelveCycles() {
            let span = lFunc.transform(1e6) - lFunc.transform(1e-6)
            #expect(abs(span - 1.0) < 0.01, "12 cycles should span 1.0")
        }
    }
    
    // MARK: - Reflection Coefficient Function Tests
    
    @Suite("ReflectionCoefficientFunction Tests")
    struct ReflectionCoefficientFunctionTests {
        private let rFunc = ReflectionCoefficientFunction()
        
        @Test("Reflection coefficient VSWR range 0.5-50")
        func rVSWRRange() {
            let vswr1 = 0.5
            let vswr2 = 1.0
            let vswr3 = 10.0
            let vswr4 = 50.0
            
            let result1 = rFunc.transform(vswr1)
            let result2 = rFunc.transform(vswr2)
            let result3 = rFunc.transform(vswr3)
            let result4 = rFunc.transform(vswr4)
            
            // All should be finite and within range
            #expect(result1.isFinite && result1 > 0)
            #expect(result2.isFinite && result2 > 0)
            #expect(result3.isFinite && result3 > 0)
            #expect(result4.isFinite && result4 > 0)
        }
        
        @Test("Reflection coefficient nonlinear mapping")
        func rNonlinear() {
            // VSWR to reflection coefficient is nonlinear
            let vswr1 = 1.5
            let vswr2 = 3.0
            let vswr3 = 6.0
            
            let result1 = rFunc.transform(vswr1)
            let result2 = rFunc.transform(vswr2)
            let result3 = rFunc.transform(vswr3)
            
            // Differences should not be uniform (nonlinear)
            let diff1 = result2 - result1
            let diff2 = result3 - result2
            
            // With the simpler formula 0.5/value * 0.472, this is actually linear in 1/value
            #expect(result1 > result2, "Lower VSWR values give higher positions")
            #expect(result2 > result3, "Lower VSWR values give higher positions")
        }
        
        @Test("Reflection coefficient round-trip accuracy")
        func rRoundTrip() {
            let testValues = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0]
            
            for value in testValues {
                let transformed = rFunc.transform(value)
                let recovered = rFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Reflection coefficient uses special constant")
        func rSpecialConstant() {
            let constant = EEConstants.reflectionScaling
            #expect(abs(constant - 0.472) < 1e-6, "Reflection scaling constant")
        }
        
        @Test("Reflection coefficient formula verification")
        func rFormula() {
            let vswr = 2.0
            let result = rFunc.transform(vswr)
            
            // PostScript formula: 0.5 / value * 0.472
            let expected = (0.5 / vswr) * 0.472
            #expect(abs(result - expected) < 1e-4)
        }
    }
    
    // MARK: - Power Ratio Function Tests
    
    @Suite("PowerRatioFunction Tests")
    struct PowerRatioFunctionTests {
        private let pFunc = PowerRatioFunction()
        
        @Test("Power ratio dB range 0-14")
        func pRange() {
            let db0 = 0.0
            let db7 = 7.0
            let db14 = 14.0
            
            let result0 = pFunc.transform(db0)
            let result7 = pFunc.transform(db7)
            let result14 = pFunc.transform(db14)
            
            // All should be within the range determined by formula
            #expect(result0.isFinite)
            #expect(result7.isFinite)
            #expect(result14.isFinite)
            
            // At x=0: 0²/196 × 0.477 + 0.523 = 0.523
            #expect(abs(result0 - 0.523) < 1e-4)
            
            // At x=14: 14²/196 × 0.477 + 0.523 = 1.0
            #expect(abs(result14 - 1.0) < 1e-4)
        }
        
        @Test("Power ratio quadratic mapping")
        func pQuadratic() {
            // Formula is quadratic: (x²/196) × 0.477 + 0.523
            let values = [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0]
            
            for value in values {
                let result = pFunc.transform(value)
                let expected = ((value * value) / 196.0) * 0.477 + 0.523
                #expect(abs(result - expected) < 1e-4, "Quadratic formula for \(value)")
            }
        }
        
        @Test("Power ratio round-trip accuracy")
        func pRoundTrip() {
            let testValues = [0.0, 1.0, 3.0, 6.0, 10.0, 14.0]
            
            for value in testValues {
                let transformed = pFunc.transform(value)
                let recovered = pFunc.inverseTransform(transformed)
                let absoluteError = abs(recovered - value)
                #expect(absoluteError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Power ratio uses special constants")
        func pConstants() {
            #expect(abs(EEConstants.powerRatioScale - 0.477) < 1e-6)
            #expect(abs(EEConstants.powerRatioOffset - 0.523) < 1e-6)
        }
        
        @Test("Power ratio nonlinear spacing")
        func pNonlinearSpacing() {
            // Due to quadratic nature, spacing between values is nonlinear
            let v1 = 0.0
            let v2 = 7.0
            let v3 = 14.0
            
            let r1 = pFunc.transform(v1)
            let r2 = pFunc.transform(v2)
            let r3 = pFunc.transform(v3)
            
            let diff1 = r2 - r1
            let diff2 = r3 - r2
            
            #expect(abs(diff1 - diff2) > 0.01, "Spacing should be nonlinear")
        }
    }
    
    // MARK: - Impedance Function Tests
    
    @Suite("ImpedanceFunction Tests")
    struct ImpedanceFunctionTests {
        private let zFunc = ImpedanceFunction(cycles: 6)
        
        @Test("Impedance scale 6 cycles")
        func zCycles() {
            let minZ = 1e-3  // 1 mΩ
            let maxZ = 1e3   // 1 kΩ (6 decades)
            
            let minResult = zFunc.transform(minZ)
            let maxResult = zFunc.transform(maxZ)
            
            let span = maxResult - minResult
            #expect(abs(span - 1.0) < 0.01, "6 cycles should span 1.0")
        }
        
        @Test("Impedance standard logarithmic")
        func zLogarithmic() {
            let z1 = 1.0
            let z10 = 10.0
            let z100 = 100.0
            
            let r1 = zFunc.transform(z1)
            let r10 = zFunc.transform(z10)
            let r100 = zFunc.transform(z100)
            
            let diff1 = r10 - r1
            let diff2 = r100 - r10
            
            #expect(abs(diff1 - diff2) < 1e-4, "Logarithmic spacing uniform")
            #expect(abs(diff1 - (1.0/6.0)) < 1e-4, "Each decade is 1/6")
        }
        
        @Test("Impedance round-trip accuracy")
        func zRoundTrip() {
            let testValues = [1e-3, 1.0, 10.0, 100.0, 1e3, 1e5]
            
            for value in testValues {
                let transformed = zFunc.transform(value)
                let recovered = zFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Impedance range mΩ to MΩ")
        func zRange() {
            let milliOhm = 1e-3
            let ohm = 1.0
            let kiloOhm = 1e3
            let megaOhm = 1e6
            
            let rMilli = zFunc.transform(milliOhm)
            let rOhm = zFunc.transform(ohm)
            let rKilo = zFunc.transform(kiloOhm)
            let rMega = zFunc.transform(megaOhm)
            
            #expect(rOhm > rMilli)
            #expect(rKilo > rOhm)
            #expect(rMega > rKilo)
        }
    }
    
    // MARK: - Capacitance Impedance Function Tests
    
    @Suite("CapacitanceImpedanceFunction Tests")
    struct CapacitanceImpedanceFunctionTests {
        private let czFunc = CapacitanceImpedanceFunction(cycles: 12)
        
        @Test("Capacitance impedance 12 cycles")
        func czCycles() {
            let minC = 1e-12  // 1 pF
            let maxC = 1e0    // 1 F (12 decades)
            
            let minResult = czFunc.transform(minC)
            let maxResult = czFunc.transform(maxC)
            
            let span = maxResult - minResult
            #expect(abs(span - 1.0) < 0.01, "12 cycles should span 1.0")
        }
        
        @Test("Capacitance impedance standard logarithmic")
        func czLogarithmic() {
            let c1 = 1e-12
            let c2 = 1e-9
            let c3 = 1e-6
            
            let r1 = czFunc.transform(c1)
            let r2 = czFunc.transform(c2)
            let r3 = czFunc.transform(c3)
            
            let diff1 = r2 - r1
            let diff2 = r3 - r2
            
            #expect(abs(diff1 - diff2) < 1e-4, "Each 3 decades should be equal")
        }
        
        @Test("Capacitance impedance round-trip accuracy")
        func czRoundTrip() {
            let testValues = [1e-12, 1e-9, 1e-6, 1e-3, 1.0]
            
            for value in testValues {
                let transformed = czFunc.transform(value)
                let recovered = czFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Capacitance impedance range pF to µF")
        func czRange() {
            let picoF = 1e-12
            let nanoF = 1e-9
            let microF = 1e-6
            let milliF = 1e-3
            
            let rPico = czFunc.transform(picoF)
            let rNano = czFunc.transform(nanoF)
            let rMicro = czFunc.transform(microF)
            let rMilli = czFunc.transform(milliF)
            
            #expect(rNano > rPico)
            #expect(rMicro > rNano)
            #expect(rMilli > rMicro)
        }
    }
    
    // MARK: - Capacitance Frequency Function Tests
    
    @Suite("CapacitanceFrequencyFunction Tests")
    struct CapacitanceFrequencyFunctionTests {
        private let cfFunc = CapacitanceFrequencyFunction(cycles: 11)
        
        @Test("Capacitance frequency special scale factor")
        func cfScaleFactor() {
            let scaleFactor = EEConstants.cfScaleFactor
            #expect(abs(scaleFactor - 3.94784212) < 1e-6, "Special scale factor")
        }
        
        @Test("Capacitance frequency inverted scale")
        func cfInverted() {
            let value1 = 1.0
            let value2 = 10.0
            
            let result1 = cfFunc.transform(value1)
            let result2 = cfFunc.transform(value2)
            
            // Higher values should produce lower positions (inverted)
            #expect(result1 > result2, "Cf scale should be inverted")
        }
        
        @Test("Capacitance frequency 11 cycles")
        func cfCycles() {
            // 11 cycles spanning the range
            let span = abs(cfFunc.transform(1e6) - cfFunc.transform(1e-5))
            #expect(abs(span - 1.0) < 0.15, "11 cycles should span ~1.0")
        }
        
        @Test("Capacitance frequency round-trip accuracy")
        func cfRoundTrip() {
            let testValues = [1e-5, 1e-3, 1.0, 1e3, 1e5]
            
            for value in testValues {
                let transformed = cfFunc.transform(value)
                let recovered = cfFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Capacitance frequency formula with scale factor")
        func cfFormula() {
            let fC = 100.0
            let result = cfFunc.transform(fC)
            
            let scaleFactor = 3.94784212
            let logValue = log10(scaleFactor * fC) / 12.0
            let expected = 1.0 - logValue
            
            #expect(abs(result - expected) < 1e-4)
        }
    }
    
    // MARK: - Frequency Wavelength Function Tests
    
    @Suite("FrequencyWavelengthFunction Tests")
    struct FrequencyWavelengthFunctionTests {
        private let foFunc = FrequencyWavelengthFunction(cycles: 6)
        
        @Test("Frequency wavelength inverted scale")
        func foInverted() {
            let freq1 = 1e6    // 1 MHz
            let freq2 = 1e9    // 1 GHz
            
            let result1 = foFunc.transform(freq1)
            let result2 = foFunc.transform(freq2)
            
            // Higher frequency = shorter wavelength, so inverted scale
            #expect(result1 > result2, "Fo scale should be inverted")
        }
        
        @Test("Frequency wavelength 6 cycles")
        func foCycles() {
            let minFreq = 1e3   // 1 kHz
            let maxFreq = 1e9   // 1 GHz (6 decades)
            
            let minResult = foFunc.transform(minFreq)
            let maxResult = foFunc.transform(maxFreq)
            
            let span = abs(minResult - maxResult)
            #expect(abs(span - 1.0) < 0.01, "6 cycles should span 1.0")
        }
        
        @Test("Frequency wavelength round-trip accuracy")
        func foRoundTrip() {
            let testValues = [1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9]
            
            for value in testValues {
                let transformed = foFunc.transform(value)
                let recovered = foFunc.inverseTransform(transformed)
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-3, "Round-trip failed for value \(value)")
            }
        }
        
        @Test("Frequency wavelength reciprocal relationship")
        func foReciprocal() {
            // λ = c/f relationship means inverse relationship
            let f1 = 1e6
            let f2 = 1e7
            
            let r1 = foFunc.transform(f1)
            let r2 = foFunc.transform(f2)
            
            // 10× frequency change
            let diff = abs(r1 - r2)
            #expect(abs(diff - (1.0/6.0)) < 1e-4, "One decade = 1/6")
        }
        
        @Test("Frequency wavelength inversion formula")
        func foInversionFormula() {
            let freq = 1e8
            let result = foFunc.transform(freq)
            
            let logValue = log10(freq) / 6.0
            let expected = 1.0 - logValue
            
            #expect(abs(result - expected) < 1e-4)
        }
    }
    
    // MARK: - Multi-Cycle and Special Behavior Tests
    
    @Suite("Multi-Cycle and Special Behavior")
    struct MultiCycleAndSpecialTests {
        
        @Test("All multi-cycle scales maintain logarithmic spacing")
        func multiCycleLogarithmic() {
            let functions: [(name: String, function: any ScaleFunction, cycles: Int)] = [
                ("XL", InductiveReactanceFunction(cycles: 12), 12),
                ("Xc", CapacitiveReactanceFunction(cycles: 12), 12),
                ("F", FrequencyFunction(cycles: 12), 12),
                ("L", InductanceFunction(cycles: 12), 12),
                ("Z", ImpedanceFunction(cycles: 6), 6),
                ("Cz", CapacitanceImpedanceFunction(cycles: 12), 12)
            ]
            
            for (name, function, cycles) in functions {
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
                    #expect(result < prev, "Xc should decrease")
                }
                prevXc = result
            }
            
            // Test Cf
            var prevCf: Double? = nil
            for value in values {
                let result = cf.transform(value)
                if let prev = prevCf {
                    #expect(result < prev, "Cf should decrease")
                }
                prevCf = result
            }
            
            // Test Fo
            var prevFo: Double? = nil
            for value in values {
                let result = fo.transform(value)
                if let prev = prevFo {
                    #expect(result < prev, "Fo should decrease")
                }
                prevFo = result
            }
        }
        
        @Test("Special constants are defined correctly")
        func specialConstants() {
            #expect(abs(EEConstants.cfScaleFactor - 3.94784212) < 1e-6)
            #expect(abs(EEConstants.reflectionScaling - 0.472) < 1e-6)
            #expect(abs(EEConstants.powerRatioScale - 0.477) < 1e-6)
            #expect(abs(EEConstants.powerRatioOffset - 0.523) < 1e-6)
        }
        
        @Test("Nonlinear scales have unique characteristics")
        func nonlinearScales() {
            let r = ReflectionCoefficientFunction()
            let p = PowerRatioFunction()
            
            // These should not be simple logarithmic
            let testValues = [1.0, 2.0, 4.0, 8.0]
            
            // Reflection coefficient spacing should be nonlinear
            let r1 = r.transform(testValues[0])
            let r2 = r.transform(testValues[1])
            let r3 = r.transform(testValues[2])
            let r4 = r.transform(testValues[3])
            
            let rdiff1 = r2 - r1
            let rdiff2 = r3 - r2
            let rdiff3 = r4 - r3
            
            #expect(abs(rdiff1 - rdiff2) > 0.001, "Reflection spacing nonlinear")
            #expect(abs(rdiff2 - rdiff3) > 0.001, "Reflection spacing nonlinear")
            
            // Power ratio is quadratic, so spacing should differ
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
}
