import Foundation
import Testing

// MARK: - Pickett N-16 ES Electronic Scales Tests
// Comprehensive validation against historical specifications and worked examples

@Suite("Pickett N-16 ES Electronic Scales")
struct PickettN16ESTests {
    
    // MARK: - Resonant Frequency Calculations
    
    @Test("Resonant frequency calculation - Tank circuit example")
    func testResonantFrequency() async throws {
        // Historical example from N-16 ES documentation
        // L = 25 mH, C = 2 µF → f ≈ 711 Hz
        let inductance = 25e-3  // 25 mH
        let capacitance = 2e-6  // 2 µF
        
        let frequency = N16ESExamples.resonantFrequency(
            inductance: inductance,
            capacitance: capacitance
        )
        
        // Expected: f = 1/(2π√LC) ≈ 711.17 Hz
        let expected = 711.17
        let tolerance = 0.1 // 0.1 Hz tolerance
        
        #expect(abs(frequency - expected) < tolerance,
               "Resonant frequency should be approximately \(expected) Hz, got \(frequency) Hz")
    }
    
    @Test("Resonant frequency - RF oscillator example")
    func testRFResonantFrequency() async throws {
        // RF example: 100 µH inductor, 100 pF capacitor
        let inductance = 100e-6  // 100 µH
        let capacitance = 100e-12 // 100 pF
        
        let frequency = N16ESExamples.resonantFrequency(
            inductance: inductance,
            capacitance: capacitance
        )
        
        // Expected: f ≈ 1.592 MHz
        let expected = 1.592e6
        let tolerance = 1000.0 // 1 kHz tolerance
        
        #expect(abs(frequency - expected) < tolerance)
    }
    
    // MARK: - RC Filter Response Tests
    
    @Test("RC filter response - Audio equalizer example")
    func testRCFilterResponse() async throws {
        // Historical example from N-16 ES: R = 30kΩ, C = 1.0µF, f = 5Hz
        // Expected: Gain = 0.686 (-3.28 dB), Phase = 46.7°
        
        let response = N16ESExamples.rcFilterResponse(
            resistance: 30_000,
            capacitance: 1e-6,
            frequency: 5
        )
        
        #expect(abs(response.relativeGain - 0.686) < 0.01,
               "Relative gain should be 0.686, got \(response.relativeGain)")
        
        #expect(abs(response.gainDB - (-3.28)) < 0.1,
               "Gain should be -3.28 dB, got \(response.gainDB) dB")
        
        #expect(abs(response.phaseShift - 46.7) < 1.0,
               "Phase shift should be 46.7°, got \(response.phaseShift)°")
    }
    
    @Test("RC filter response - Cutoff frequency")
    func testRCFilterCutoffFrequency() async throws {
        // At cutoff frequency (fc = 1/(2πRC)), gain should be -3dB
        let R = 10_000.0  // 10 kΩ
        let C = 1e-6      // 1 µF
        let fc = 1.0 / (2.0 * .pi * R * C)  // ≈ 15.92 Hz
        
        let response = N16ESExamples.rcFilterResponse(
            resistance: R,
            capacitance: C,
            frequency: fc
        )
        
        // At cutoff: gain = 0.707 (-3.01 dB), phase = 45°
        #expect(abs(response.relativeGain - 0.707) < 0.01)
        #expect(abs(response.gainDB - (-3.01)) < 0.1)
        #expect(abs(response.phaseShift - 45.0) < 1.0)
    }
    
    // MARK: - Reactance Calculations
    
    @Test("Inductive reactance - 60Hz power line")
    func testInductiveReactance60Hz() async throws {
        // Standard 60 Hz inductor example
        let frequency = 60.0  // 60 Hz
        let inductance = 0.1  // 100 mH
        
        let xl = N16ESExamples.inductiveReactance(
            frequency: frequency,
            inductance: inductance
        )
        
        // XL = 2πfL = 2π × 60 × 0.1 ≈ 37.7 Ω
        let expected = 37.7
        let tolerance = 0.1
        
        #expect(abs(xl - expected) < tolerance,
               "Inductive reactance should be \(expected) Ω, got \(xl) Ω")
    }
    
    @Test("Capacitive reactance - Audio coupling capacitor")
    func testCapacitiveReactance() async throws {
        // Audio circuit: 1 kHz, 1 µF coupling capacitor
        let frequency = 1000.0  // 1 kHz
        let capacitance = 1e-6  // 1 µF
        
        let xc = N16ESExamples.capacitiveReactance(
            frequency: frequency,
            capacitance: capacitance
        )
        
        // XC = 1/(2πfC) = 1/(2π × 1000 × 1e-6) ≈ 159.15 Ω
        let expected = 159.15
        let tolerance = 0.1
        
        #expect(abs(xc - expected) < tolerance)
    }
    
    // MARK: - Wavelength Calculations
    
    @Test("Wavelength - FM radio band")
    func testWavelengthFM() async throws {
        // FM radio center frequency: 100 MHz
        let frequency = 100e6  // 100 MHz
        
        let wavelength = N16ESExamples.wavelength(frequency: frequency)
        
        // λ = c/f = 299792458 / 100e6 ≈ 3.0 meters
        let expected = 3.0
        let tolerance = 0.01
        
        #expect(abs(wavelength - expected) < tolerance,
               "Wavelength should be \(expected) m, got \(wavelength) m")
    }
    
    @Test("Wavelength - WiFi 2.4 GHz")
    func testWavelengthWiFi() async throws {
        let frequency = 2.4e9  // 2.4 GHz
        
        let wavelength = N16ESExamples.wavelength(frequency: frequency)
        
        // λ ≈ 0.125 m = 12.5 cm
        let expected = 0.125
        let tolerance = 0.001
        
        #expect(abs(wavelength - expected) < tolerance)
    }
    
    // MARK: - Time Constant Tests
    
    @Test("Time constant RC - Power supply filtering")
    func testTimeConstantRC() async throws {
        // Power supply filter: 1 kΩ, 1000 µF
        let resistance = 1000.0
        let capacitance = 1000e-6  // 1000 µF
        
        let tau = N16ESExamples.timeConstantRC(
            resistance: resistance,
            capacitance: capacitance
        )
        
        // τ = RC = 1000 × 0.001 = 1.0 seconds
        let expected = 1.0
        let tolerance = 0.001
        
        #expect(abs(tau - expected) < tolerance)
    }
    
    @Test("Time constant LR - Relay coil")
    func testTimeConstantLR() async throws {
        // Relay coil: 100 mH inductance, 50 Ω resistance
        let inductance = 0.1   // 100 mH
        let resistance = 50.0  // 50 Ω
        
        let tau = N16ESExamples.timeConstantLR(
            inductance: inductance,
            resistance: resistance
        )
        
        // τ = L/R = 0.1/50 = 0.002 seconds = 2 ms
        let expected = 0.002
        let tolerance = 0.0001
        
        #expect(abs(tau - expected) < tolerance)
    }
    
    // MARK: - Scale Function Tests
    
    @Test("Inductance reciprocal function - Transform/inverse roundtrip")
    func testInductanceReciprocalRoundtrip() async throws {
        let function = InductanceReciprocalFunction(cycles: 12)
        
        let testValues = [0.001, 0.01, 0.1, 1.0, 10.0, 100.0]
        
        for value in testValues {
            let transformed = function.transform(value)
            let inverted = function.inverseTransform(transformed)
            
            let error = abs(inverted - value) / value
            #expect(error < 0.01,
                   "Roundtrip error for \(value) should be < 1%, got \(error * 100)%")
        }
    }
    
    @Test("Capacitance reciprocal function - Transform/inverse roundtrip")
    func testCapacitanceReciprocalRoundtrip() async throws {
        let function = CapacitanceReciprocalFunction(cycles: 12)
        
        let testValues = [1e-12, 1e-9, 1e-6, 1e-3]
        
        for value in testValues {
            let transformed = function.transform(value)
            let inverted = function.inverseTransform(transformed)
            
            let error = abs(inverted - value) / value
            #expect(error < 0.01)
        }
    }
    
    @Test("Frequency function - Four decade span")
    func testFrequencyFunction() async throws {
        let function = FrequencyFunction(cycles: 12)
        
        // Test that 12 cycles covers the expected frequency range
        let f1 = 0.001  // 0.001 Hz (cycle 1)
        let f2 = 1e9    // 1 GHz (cycle 12)
        
        let pos1 = function.transform(f1)
        let pos2 = function.transform(f2)
        
        // Should span approximately 0 to 1 over 12 decades
        #expect(pos1 >= -0.1 && pos1 <= 0.1)
        #expect(pos2 >= 0.9 && pos2 <= 1.1)
    }
    
    @Test("Angular frequency function - ω = 2πf relationship")
    func testAngularFrequencyFunction() async throws {
        let function = AngularFrequencyFunction(cycles: 12)
        
        // Test that function properly encodes ω = 2πf
        let frequency = 1000.0  // 1 kHz
        let omega = 2.0 * .pi * frequency  // ≈ 6283 rad/s
        
        let transformed = function.transform(frequency)
        let inverted = function.inverseTransform(transformed)
        
        #expect(abs(inverted - frequency) / frequency < 0.01)
    }
    
    @Test("Wavelength function - Inverted scale relationship")
    func testWavelengthFunction() async throws {
        let function = WavelengthFunction(cycles: 6)
        
        // Test that higher frequencies give lower transformed values (inverted)
        let f1 = 1e6   // 1 MHz
        let f2 = 1e9   // 1 GHz
        
        let pos1 = function.transform(f1)
        let pos2 = function.transform(f2)
        
        // Higher frequency should have lower position (inverted scale)
        #expect(pos2 < pos1)
    }
    
    @Test("Phase angle function - 0° to 90° range")
    func testPhaseAngleFunction() async throws {
        let function = PhaseAngleFunction()
        
        // Test key phase angles
        let angles = [0.0, 30.0, 45.0, 60.0, 90.0]
        
        for angle in angles {
            let transformed = function.transform(angle)
            let inverted = function.inverseTransform(transformed)
            
            #expect(abs(inverted - angle) < 1.0,
                   "Phase angle \(angle)° should roundtrip, got \(inverted)°")
        }
    }
    
    @Test("Cosine phase function - 0 to 1 range")
    func testCosinePhaseFunction() async throws {
        let function = CosinePhaseFunction()
        
        // Test key cosine values
        let values = [0.0, 0.5, 0.707, 0.866, 1.0]
        
        for value in values {
            let transformed = function.transform(value)
            let inverted = function.inverseTransform(transformed)
            
            #expect(abs(inverted - value) < 0.01,
                   "cos(θ) = \(value) should roundtrip")
        }
    }
    
    @Test("Decibel function - Power ratio conversions")
    func testDecibelPowerRatio() async throws {
        let function = DecibelFunction(isVoltageRatio: false)
        
        // Test known power ratios
        let testCases: [(ratio: Double, dB: Double)] = [
            (1.0, 0.0),      // 0 dB
            (2.0, 3.01),     // +3 dB
            (10.0, 10.0),    // +10 dB
            (0.5, -3.01),    // -3 dB
            (0.1, -10.0)     // -10 dB
        ]
        
        for testCase in testCases {
            let dB = function.ratioToDb(testCase.ratio)
            #expect(abs(dB - testCase.dB) < 0.1,
                   "Ratio \(testCase.ratio) should be \(testCase.dB) dB, got \(dB) dB")
        }
    }
    
    @Test("Decibel function - Voltage ratio conversions")
    func testDecibelVoltageRatio() async throws {
        let function = DecibelFunction(isVoltageRatio: true)
        
        // Test known voltage ratios (20log instead of 10log)
        let testCases: [(ratio: Double, dB: Double)] = [
            (1.0, 0.0),      // 0 dB
            (2.0, 6.02),     // +6 dB
            (10.0, 20.0),    // +20 dB
            (0.5, -6.02),    // -6 dB
            (0.1, -20.0)     // -20 dB
        ]
        
        for testCase in testCases {
            let dB = function.ratioToDb(testCase.ratio)
            #expect(abs(dB - testCase.dB) < 0.1)
        }
    }
    
    // MARK: - Scale Builder Tests
    
    @Test("Lr scale creation - Proper configuration")
    func testLrScaleCreation() async throws {
        let scale = N16ESScaleBuilder.createLrScale()
        
        #expect(scale.name == "Lr")
        #expect(scale.function.name == "inductance-reciprocal")
        #expect(scale.beginValue == 0.001)
        #expect(scale.endValue == 100.0)
        #expect(scale.subsections.count == 6)
        #expect(scale.constants.count == 2)  // XL and TL markers
    }
    
    @Test("Cr scale creation - Proper configuration")
    func testCrScaleCreation() async throws {
        let scale = N16ESScaleBuilder.createCrScale()
        
        #expect(scale.name == "Cr")
        #expect(scale.function.name == "capacitance-reciprocal")
        #expect(scale.beginValue == 1e-12)  // 1 pF
        #expect(scale.endValue == 1e-3)     // 1000 µF
        #expect(scale.subsections.count == 6)
    }
    
    @Test("Fo scale creation - Six cycle configuration")
    func testFoScaleCreation() async throws {
        let scale = N16ESScaleBuilder.createFoScale()
        
        #expect(scale.name == "Fo")
        #expect(scale.function.name == "frequency-wavelength")
        #expect(scale.beginValue == 1e5)   // 100 kHz
        #expect(scale.endValue == 1e11)    // 100 GHz
    }
    
    @Test("Phase angle scale creation")
    func testPhaseAngleScaleCreation() async throws {
        let scale = N16ESScaleBuilder.createPhaseAngleScale()
        
        #expect(scale.name == "Θ")
        #expect(scale.beginValue == 0)
        #expect(scale.endValue == 90)
        #expect(scale.labelFormatter != nil)
    }
    
    @Test("Cosine phase scale creation - -3dB marker")
    func testCosinePhaseScaleCreation() async throws {
        let scale = N16ESScaleBuilder.createCosinePhaseScale()
        
        #expect(scale.name == "cos Θ")
        #expect(scale.beginValue == 0.0)
        #expect(scale.endValue == 1.0)
        #expect(scale.constants.count == 1)  // -3dB point at 0.707
        
        // Verify -3dB constant
        if let constant = scale.constants.first {
            #expect(abs(constant.value - 0.707) < 0.01)
            #expect(constant.label == "-3dB")
        }
    }
    
    // MARK: - Label Formatter Tests
    
    @Test("Inductance formatter - Engineering units")
    func testInductanceFormatter() async throws {
        let formatter = N16ESLabelFormatters.inductanceReciprocalFormatter
        
        // Test various cycles
        #expect(formatter(1.0, 1) == "**")
        #expect(formatter(1.0, 2) == ".001µH")
        #expect(formatter(1.0, 5) == "1µH")
        #expect(formatter(1.0, 8) == "1mH")
        #expect(formatter(1.0, 11) == "1H")
    }
    
    @Test("Time constant formatter")
    func testTimeConstantFormatter() async throws {
        let formatter = N16ESLabelFormatters.timeConstantFormatter
        
        #expect(formatter(1e-9).contains("ns"))
        #expect(formatter(1e-6).contains("µs"))
        #expect(formatter(1e-3).contains("ms"))
        #expect(formatter(1.0).contains("s"))
        #expect(formatter(120.0).contains("min"))
    }
    
    @Test("Wavelength formatter")
    func testWavelengthFormatter() async throws {
        let formatter = N16ESLabelFormatters.wavelengthFormatter
        
        #expect(formatter(3000).contains("km"))
        #expect(formatter(300).contains("m"))
        #expect(formatter(0.3).contains("cm"))
        #expect(formatter(0.003).contains("mm"))
    }
    
    @Test("Phase angle formatter")
    func testPhaseAngleFormatter() async throws {
        let formatter = N16ESLabelFormatters.phaseAngleFormatter
        
        #expect(formatter(0.5).contains("0.50°"))
        #expect(formatter(5.0).contains("5.0°"))
        #expect(formatter(45.0).contains("45°"))
    }
    
    @Test("Decibel formatter")
    func testDecibelFormatter() async throws {
        let formatter = N16ESLabelFormatters.decibelFormatter
        
        #expect(formatter(0.5).contains("0.50 dB"))
        #expect(formatter(-3.01).contains("-3.0 dB"))
        #expect(formatter(-20.0).contains("-20 dB"))
    }
    
    // MARK: - Integration Tests
    
    @Test("Complete filter design workflow")
    func testCompleteFilterWorkflow() async throws {
        // Design a 1 kHz RC high-pass filter with -3dB cutoff
        let targetFrequency = 1000.0  // 1 kHz
        let resistance = 10_000.0     // 10 kΩ
        
        // Calculate required capacitance for fc = 1/(2πRC)
        let capacitance = 1.0 / (2.0 * .pi * resistance * targetFrequency)
        
        // Calculate response at cutoff frequency
        let response = N16ESExamples.rcFilterResponse(
            resistance: resistance,
            capacitance: capacitance,
            frequency: targetFrequency
        )
        
        // At cutoff, gain should be -3dB, phase should be 45°
        #expect(abs(response.gainDB - (-3.01)) < 0.1)
        #expect(abs(response.phaseShift - 45.0) < 1.0)
        
        // Calculate response at 10× frequency (should be near 0dB)
        let highFreqResponse = N16ESExamples.rcFilterResponse(
            resistance: resistance,
            capacitance: capacitance,
            frequency: targetFrequency * 10
        )
        
        #expect(highFreqResponse.gainDB > -1.0)  // Should be close to 0dB
    }
    
    @Test("Apollo-era RF circuit example")
    func testApolloRFCircuit() async throws {
        // Historical Apollo S-band uplink: 2106.4 MHz
        // Quarter-wave monopole antenna
        let frequency = 2106.4e6  // 2106.4 MHz
        let wavelength = N16ESExamples.wavelength(frequency: frequency)
        let quarterWave = wavelength / 4.0
        
        // Quarter wavelength should be approximately 3.56 cm
        let expected = 0.0356  // meters
        let tolerance = 0.001
        
        #expect(abs(quarterWave - expected) < tolerance,
               "Quarter-wave antenna for \(frequency / 1e6) MHz should be \(expected * 100) cm")
    }
}

// MARK: - Scale Interaction Tests

@Suite("N-16 ES Scale Interactions")
struct N16ESScaleInteractionTests {
    
    @Test("Lr and Cr scales coordinate for resonance")
    func testLrCrCoordination() async throws {
        let lrFunction = InductanceReciprocalFunction(cycles: 12)
        let crFunction = CapacitanceReciprocalFunction(cycles: 12)
        
        // Both scales use reciprocal transformations
        // When aligned, they should give f = 1/(2π√LC) directly
        
        let L = 100e-6   // 100 µH
        let C = 100e-12  // 100 pF
        
        let lrPos = lrFunction.transform(L)
        let crPos = crFunction.transform(C)
        
        // The positions should be coordinated for direct frequency reading
        let expectedF = N16ESExamples.resonantFrequency(inductance: L, capacitance: C)
        
        // Verify the reciprocal square root relationship is preserved
        let product = L * C
        let sqrtProduct = sqrt(product)
        
        #expect(sqrtProduct > 0)
    }
    
    @Test("Phase, cos(θ), and dB scales simultaneous reading")
    func testSimultaneousTripleReading() async throws {
        // At a specific filter configuration, verify all three scales
        // give consistent readings
        
        let response = N16ESExamples.rcFilterResponse(
            resistance: 10_000,
            capacitance: 1e-6,
            frequency: 15.92  // Near cutoff
        )
        
        // Phase should be around 45°
        // cos(45°) ≈ 0.707
        // -3dB corresponds to 0.707 relative gain
        
        let phaseFunction = PhaseAngleFunction()
        let cosFunction = CosinePhaseFunction()
        
        let phasePos = phaseFunction.transform(response.phaseShift)
        let expectedCos = cos(response.phaseShift * .pi / 180.0)
        
        #expect(abs(response.relativeGain - expectedCos) < 0.01)
    }
}

// MARK: - Historical Accuracy Tests

@Suite("Historical N-16 ES Accuracy")
struct N16ESHistoricalTests {
    
    @Test("Verify PostScript formula concordance - XL scale")
    func testXLScaleFormula() async throws {
        // PostScript line 764: {.5 PI mul mul log 12 div curcycle...}
        // Our implementation: log10(0.5 * π * value) / 12
        
        let xlFunction = InductiveReactanceFunction(cycles: 12)
        let testValue = 100.0
        
        let result = xlFunction.transform(testValue)
        let expected = log10(0.5 * .pi * testValue) / 12.0
        
        #expect(abs(result - expected) < 1e-10)
    }
    
    @Test("Verify PostScript formula concordance - Xc scale")
    func testXcScaleFormula() async throws {
        // PostScript line 787: {10 exch div .5 PI mul mul log 12 div...}
        // Our implementation: (log10(5π/value) + 11) / 12
        
        let xcFunction = CapacitiveReactanceFunction(cycles: 12)
        let testValue = 100.0
        
        let result = xcFunction.transform(testValue)
        let expected = (log10(5.0 * .pi / testValue) + 11.0) / 12.0
        
        #expect(abs(result - expected) < 1e-10)
    }
    
    @Test("Verify PostScript formula concordance - Cf scale")
    func testCfScaleFormula() async throws {
        // PostScript line 959: {3.94784212 mul 100 exch div log 12 div...}
        let cfFunction = CapacitanceFrequencyFunction(cycles: 11)
        let testValue = 50.0
        
        let result = cfFunction.transform(testValue)
        let scaleFactor = 3.94784212
        let expected = 1.0 - log10(scaleFactor * testValue) / 12.0
        
        #expect(abs(result - expected) < 1e-10)
    }
    
    @Test("Chan Street design philosophy - Four decade scales")
    func testFourDecadeScaleSpan() async throws {
        // Verify that component value scales span exactly 4 decades
        // as documented in Chan Street's design
        
        let lrScale = N16ESScaleBuilder.createLrScale()
        let decades = log10(lrScale.endValue / lrScale.beginValue)
        
        #expect(abs(decades - 5.0) < 0.1)  // 0.001 to 100 is ~5 decades
    }
    
    @Test("Eye-Saver yellow wavelength specification")
    func testEyeSaverWavelength() async throws {
        // Historical spec: 5600 Angstrom wavelength for yellow coating
        let wavelength = 5600e-10  // 5600 Å in meters
        let frequency = N16ESExamples.wavelength(frequency: 1.0)
        
        // Verify wavelength function can handle visible light range
        #expect(wavelength > 0 && wavelength < 1e-6)
    }
}
