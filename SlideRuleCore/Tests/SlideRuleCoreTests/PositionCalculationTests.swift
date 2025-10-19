import Testing
import Foundation
@testable import SlideRuleCore

@Suite("Position Calculation Tests - Core scale position and value calculations")
struct PositionCalculationTests {
    
    // MARK: - Test Scale Definitions
    
    /// Standard C scale for logarithmic tests
    private let cScale = StandardScales.cScale(length: 250.0)
    
    /// A scale for squared logarithmic tests
    private let aScale = StandardScales.aScale(length: 250.0)
    
    /// K scale for cubed logarithmic tests
    private let kScale = StandardScales.kScale(length: 250.0)
    
    /// L scale for linear function tests
    private let lScale = StandardScales.lScale(length: 250.0)
    
    /// Circular C scale for angular position tests
    private let circularCScale = ScaleDefinition(
        name: "C-Circular",
        function: LogarithmicFunction(),
        beginValue: 1,
        endValue: 10,
        scaleLengthInPoints: 360.0,
        layout: .circular(diameter: 200, radiusInPoints: 100),
        subsections: []
    )
    
    // MARK: - Normalized Position Tests for Logarithmic Scales (C/D)
    
    @Test("C scale value 1.0 maps to normalized position 0.0")
    func cScaleValue1Position() {
        let position = ScaleCalculator.normalizedPosition(for: 1.0, on: cScale)
        #expect(abs(position - 0.0) < 1e-10)
    }
    
    @Test("C scale value 2.0 maps to normalized position log₁₀(2) ≈ 0.3010")
    func cScaleValue2Position() {
        let position = ScaleCalculator.normalizedPosition(for: 2.0, on: cScale)
        let expected = log10(2.0)
        #expect(abs(position - expected) < 1e-10)
    }
    
    @Test("C scale value 5.0 maps to normalized position log₁₀(5) ≈ 0.699")
    func cScaleValue5Position() {
        let position = ScaleCalculator.normalizedPosition(for: 5.0, on: cScale)
        let expected = log10(5.0)
        #expect(abs(position - expected) < 1e-10)
    }
    
    @Test("C scale value 10.0 maps to normalized position 1.0")
    func cScaleValue10Position() {
        let position = ScaleCalculator.normalizedPosition(for: 10.0, on: cScale)
        #expect(abs(position - 1.0) < 1e-10)
    }
    
    @Test("C scale value π gives normalized position log₁₀(π) ≈ 0.4971")
    func cScaleValuePiPosition() {
        let position = ScaleCalculator.normalizedPosition(for: .pi, on: cScale)
        let expected = log10(Double.pi)
        #expect(abs(position - expected) < 1e-10)
    }
    
    // MARK: - Normalized Position Tests for Squared Scales (A/B)
    
    @Test("A scale value 1.0 maps to normalized position 0.0")
    func aScaleValue1Position() {
        let position = ScaleCalculator.normalizedPosition(for: 1.0, on: aScale)
        #expect(abs(position - 0.0) < 1e-10)
    }
    
    @Test("A scale value 10.0 maps to normalized position log₁₀(10²)/2 = 0.5")
    func aScaleValue10Position() {
        let position = ScaleCalculator.normalizedPosition(for: 10.0, on: aScale)
        // A scale: 0.5 * log10(x), range 1 to 100
        // At x=10: 0.5 * log10(10) = 0.5 * 1 = 0.5
        // Normalized: (0.5 - 0) / (1 - 0) = 0.5
        let expected = 0.5
        #expect(abs(position - expected) < 1e-10)
    }
    
    @Test("A scale value 100.0 maps to normalized position 1.0")
    func aScaleValue100Position() {
        let position = ScaleCalculator.normalizedPosition(for: 100.0, on: aScale)
        #expect(abs(position - 1.0) < 1e-10)
    }
    
    @Test("A scale demonstrates log₁₀(x²) behavior")
    func aScaleSquaredBehavior() {
        // A scale transforms value x using 0.5 * log10(x)
        // This means it displays x² values on a standard log scale
        let value = 5.0
        let position = ScaleCalculator.normalizedPosition(for: value, on: aScale)
        
        // Expected: (0.5 * log10(5) - 0) / (0.5 * log10(100) - 0)
        // = 0.5 * log10(5) / 1.0 = log10(5) / 2
        let expected = log10(value) / 2.0
        #expect(abs(position - expected) < 1e-10)
    }
    
    // MARK: - Normalized Position Tests for Cubed Scales (K)
    
    @Test("K scale value 1.0 maps to normalized position 0.0")
    func kScaleValue1Position() {
        let position = ScaleCalculator.normalizedPosition(for: 1.0, on: kScale)
        #expect(abs(position - 0.0) < 1e-10)
    }
    
    @Test("K scale value 10.0 maps to normalized position log₁₀(10³)/3 ≈ 0.333")
    func kScaleValue10Position() {
        let position = ScaleCalculator.normalizedPosition(for: 10.0, on: kScale)
        // K scale: log10(x) / 3, range 1 to 1000
        // At x=10: log10(10) / 3 = 1/3
        // Normalized: (1/3 - 0) / (1 - 0) = 1/3
        let expected = 1.0 / 3.0
        #expect(abs(position - expected) < 1e-10)
    }
    
    @Test("K scale value 1000.0 maps to normalized position 1.0")
    func kScaleValue1000Position() {
        let position = ScaleCalculator.normalizedPosition(for: 1000.0, on: kScale)
        #expect(abs(position - 1.0) < 1e-10)
    }
    
    @Test("K scale demonstrates log₁₀(x³) behavior")
    func kScaleCubedBehavior() {
        let value = 5.0
        let position = ScaleCalculator.normalizedPosition(for: value, on: kScale)
        
        // Expected: (log10(5) / 3 - 0) / (log10(1000) / 3 - 0)
        // = log10(5) / 3 / 1 = log10(5) / 3
        let expected = log10(value) / 3.0
        #expect(abs(position - expected) < 1e-10)
    }
    
    // MARK: - Normalized Position Tests for Linear Scales (L)
    
    @Test("L scale value 0.0 maps to normalized position 0.0")
    func lScaleValue0Position() {
        let position = ScaleCalculator.normalizedPosition(for: 0.0, on: lScale)
        #expect(abs(position - 0.0) < 1e-10)
    }
    
    @Test("L scale value 0.5 maps to normalized position 0.5 (linear mapping)")
    func lScaleValue05Position() {
        let position = ScaleCalculator.normalizedPosition(for: 0.5, on: lScale)
        #expect(abs(position - 0.5) < 1e-10)
    }
    
    @Test("L scale value 1.0 maps to normalized position 1.0")
    func lScaleValue1PositionLinear() {
        let position = ScaleCalculator.normalizedPosition(for: 1.0, on: lScale)
        #expect(abs(position - 1.0) < 1e-10)
    }
    
    // MARK: - Absolute Position Tests
    
    @Test("Absolute position scales correctly with scale length in points")
    func absolutePositionScaling() {
        let value = 5.0
        let normalizedPos = ScaleCalculator.normalizedPosition(for: value, on: cScale)
        let absolutePos = ScaleCalculator.absolutePosition(for: value, on: cScale)
        
        let expected = normalizedPos * cScale.scaleLengthInPoints
        #expect(abs(absolutePos - expected) < 1e-10)
    }
    
    @Test("C scale value 2.0 absolute position is log₁₀(2) × 250 points")
    func cScaleValue2AbsolutePosition() {
        let absolutePos = ScaleCalculator.absolutePosition(for: 2.0, on: cScale)
        let expected = log10(2.0) * 250.0
        #expect(abs(absolutePos - expected) < 1e-10)
    }
    
    @Test("Linear scale absolute position is proportional to value")
    func linearScaleAbsolutePosition() {
        let value = 0.3
        let absolutePos = ScaleCalculator.absolutePosition(for: value, on: lScale)
        // L scale: range 0 to 1, length 250, linear function
        // Position = value * length = 0.3 * 250 = 75
        let expected = value * lScale.scaleLengthInPoints
        #expect(abs(absolutePos - expected) < 1e-10)
    }
    
    // MARK: - Angular Position Tests for Circular Scales
    
    @Test("Circular C scale value 1.0 gives angular position 0°")
    func circularCScaleValue1Angle() {
        let angle = ScaleCalculator.angularPosition(for: 1.0, on: circularCScale)
        #expect(abs(angle - 0.0) < 0.01)
    }
    
    @Test("Circular C scale value 2.0 gives angular position log₁₀(2) × 360° ≈ 108.4°")
    func circularCScaleValue2Angle() {
        let angle = ScaleCalculator.angularPosition(for: 2.0, on: circularCScale)
        let expected = log10(2.0) * 360.0
        #expect(abs(angle - expected) < 0.01)
    }
    
    @Test("Circular C scale value π gives angular position ≈ 158.24°")
    func circularCScaleValuePiAngle() {
        let angle = ScaleCalculator.angularPosition(for: .pi, on: circularCScale)
        let expected = log10(Double.pi) * 360.0
        #expect(abs(angle - expected) < 0.01)
    }
    
    @Test("Circular C scale value 10.0 gives angular position 360°")
    func circularCScaleValue10Angle() {
        let angle = ScaleCalculator.angularPosition(for: 10.0, on: circularCScale)
        #expect(abs(angle - 360.0) < 0.01)
    }
    
    @Test("Circular scale value at quarter turn gives 90°")
    func circularScaleQuarterTurn() {
        // Find value that maps to 90° (normalized position 0.25)
        // log10(x) = 0.25, so x = 10^0.25 ≈ 1.778
        let value = pow(10, 0.25)
        let angle = ScaleCalculator.angularPosition(for: value, on: circularCScale)
        #expect(abs(angle - 90.0) < 0.01)
    }
    
    @Test("Circular scale value at half turn gives 180°")
    func circularScaleHalfTurn() {
        // Find value that maps to 180° (normalized position 0.5)
        // log10(x) = 0.5, so x = 10^0.5 ≈ 3.162
        let value = pow(10, 0.5)
        let angle = ScaleCalculator.angularPosition(for: value, on: circularCScale)
        #expect(abs(angle - 180.0) < 0.01)
    }
    
    @Test("Circular scale value at three-quarter turn gives 270°")
    func circularScaleThreeQuarterTurn() {
        // Find value that maps to 270° (normalized position 0.75)
        // log10(x) = 0.75, so x = 10^0.75 ≈ 5.623
        let value = pow(10, 0.75)
        let angle = ScaleCalculator.angularPosition(for: value, on: circularCScale)
        #expect(abs(angle - 270.0) < 0.01)
    }
    
    // MARK: - Inverse Position Lookup Tests (position → value)
    
    @Test("D scale position 0.0 corresponds to value 1.0")
    func dScalePosition0Value() {
        let dScale = StandardScales.dScale(length: 250.0)
        let value = ScaleCalculator.value(at: 0.0, on: dScale)
        #expect(abs(value - 1.0) < 1e-6)
    }
    
    @Test("D scale position 0.3010 corresponds to value 2.0")
    func dScalePosition0301Value() {
        let dScale = StandardScales.dScale(length: 250.0)
        let position = log10(2.0)  // ≈ 0.3010
        let value = ScaleCalculator.value(at: position, on: dScale)
        #expect(abs(value - 2.0) < 1e-6)
    }
    
    @Test("C scale position 0.5 corresponds to value √10 ≈ 3.162")
    func cScalePositionHalfValue() {
        let value = ScaleCalculator.value(at: 0.5, on: cScale)
        let expected = sqrt(10.0)
        #expect(abs(value - expected) < 1e-6)
    }
    
    @Test("C scale position 1.0 corresponds to value 10.0")
    func cScalePosition1Value() {
        let value = ScaleCalculator.value(at: 1.0, on: cScale)
        #expect(abs(value - 10.0) < 1e-6)
    }
    
    @Test("Linear scale position 0.25 corresponds to value 0.25")
    func linearScalePositionQuarterValue() {
        let value = ScaleCalculator.value(at: 0.25, on: lScale)
        #expect(abs(value - 0.25) < 1e-6)
    }
    
    // MARK: - Circular Scale Inverse Lookups (angle → value)
    
    @Test("Circular C scale at 0° corresponds to value 1.0")
    func circularCScale0DegreeValue() {
        let value = ScaleCalculator.value(atAngle: 0.0, on: circularCScale)
        #expect(abs(value - 1.0) < 1e-6)
    }
    
    @Test("Circular C scale at 90° corresponds to value 10^0.25 ≈ 1.778")
    func circularCScale90DegreeValue() {
        let value = ScaleCalculator.value(atAngle: 90.0, on: circularCScale)
        let expected = pow(10, 0.25)
        #expect(abs(value - expected) < 1e-6)
    }
    
    @Test("Circular C scale at 180° corresponds to value √10 ≈ 3.162")
    func circularCScale180DegreeValue() {
        let value = ScaleCalculator.value(atAngle: 180.0, on: circularCScale)
        let expected = sqrt(10.0)
        #expect(abs(value - expected) < 1e-6)
    }
    
    @Test("Circular C scale at 270° corresponds to value 10^0.75 ≈ 5.623")
    func circularCScale270DegreeValue() {
        let value = ScaleCalculator.value(atAngle: 270.0, on: circularCScale)
        let expected = pow(10, 0.75)
        #expect(abs(value - expected) < 1e-6)
    }
    
    @Test("Circular C scale at 360° corresponds to value 10.0")
    func circularCScale360DegreeValue() {
        let value = ScaleCalculator.value(atAngle: 360.0, on: circularCScale)
        #expect(abs(value - 10.0) < 1e-6)
    }
    
    // MARK: - Round-Trip Accuracy Tests
    
    @Test("Position to value round-trip maintains accuracy within 1ppm for C scale")
    func cScaleRoundTripAccuracy() {
        let testValues: [Double] = [1.0, 1.5, 2.0, 3.14159, 5.0, 7.5, 10.0]
        
        for originalValue in testValues {
            let position = ScaleCalculator.normalizedPosition(for: originalValue, on: cScale)
            let recoveredValue = ScaleCalculator.value(at: position, on: cScale)
            
            let relativeError = abs(recoveredValue - originalValue) / originalValue
            #expect(relativeError < 1e-6, "Round-trip error for \(originalValue): \(relativeError)")
        }
    }
    
    @Test("Value to position round-trip maintains accuracy for logarithmic scales")
    func logarithmicScaleRoundTrip() {
        let testPositions: [Double] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
        
        for originalPosition in testPositions {
            let value = ScaleCalculator.value(at: originalPosition, on: cScale)
            let recoveredPosition = ScaleCalculator.normalizedPosition(for: value, on: cScale)
            
            #expect(abs(recoveredPosition - originalPosition) < 1e-6,
                    "Round-trip error for position \(originalPosition): \(abs(recoveredPosition - originalPosition))")
        }
    }
    
    @Test("Circular scale angle to value round-trip maintains accuracy")
    func circularScaleRoundTripAccuracy() {
        let testAngles: [Double] = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0, 360.0]
        
        for originalAngle in testAngles {
            let value = ScaleCalculator.value(atAngle: originalAngle, on: circularCScale)
            let recoveredAngle = ScaleCalculator.angularPosition(for: value, on: circularCScale)
            
            #expect(abs(recoveredAngle - originalAngle) < 0.01,
                    "Round-trip error for angle \(originalAngle)°: \(abs(recoveredAngle - originalAngle))°")
        }
    }
    
    @Test("A scale round-trip accuracy for squared values")
    func aScaleRoundTripAccuracy() {
        let testValues: [Double] = [1.0, 4.0, 10.0, 25.0, 50.0, 100.0]
        
        for originalValue in testValues {
            let position = ScaleCalculator.normalizedPosition(for: originalValue, on: aScale)
            let recoveredValue = ScaleCalculator.value(at: position, on: aScale)
            
            let relativeError = abs(recoveredValue - originalValue) / originalValue
            #expect(relativeError < 1e-6, "A scale round-trip error for \(originalValue): \(relativeError)")
        }
    }
    
    @Test("K scale round-trip accuracy for cubed values")
    func kScaleRoundTripAccuracy() {
        let testValues: [Double] = [1.0, 8.0, 27.0, 64.0, 125.0, 1000.0]
        
        for originalValue in testValues {
            let position = ScaleCalculator.normalizedPosition(for: originalValue, on: kScale)
            let recoveredValue = ScaleCalculator.value(at: position, on: kScale)
            
            let relativeError = abs(recoveredValue - originalValue) / originalValue
            #expect(relativeError < 1e-6, "K scale round-trip error for \(originalValue): \(relativeError)")
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Scale boundary values map to positions 0.0 and 1.0")
    func scaleBoundaryValues() {
        // Test begin value
        let beginPosition = ScaleCalculator.normalizedPosition(for: cScale.beginValue, on: cScale)
        #expect(abs(beginPosition - 0.0) < 1e-10)
        
        // Test end value
        let endPosition = ScaleCalculator.normalizedPosition(for: cScale.endValue, on: cScale)
        #expect(abs(endPosition - 1.0) < 1e-10)
    }
    
    @Test("Midpoint value calculation is accurate")
    func midpointValueCalculation() {
        let midpointValue = ScaleCalculator.value(at: 0.5, on: cScale)
        // For log scale from 1 to 10, midpoint is sqrt(10) ≈ 3.162
        let expected = sqrt(10.0)
        #expect(abs(midpointValue - expected) < 1e-6)
    }
    
    @Test("Near-boundary position calculations are stable")
    func nearBoundaryPositions() {
        let nearBegin = 1.0001
        let nearEnd = 9.9999
        
        let posNearBegin = ScaleCalculator.normalizedPosition(for: nearBegin, on: cScale)
        let posNearEnd = ScaleCalculator.normalizedPosition(for: nearEnd, on: cScale)
        
        #expect(posNearBegin > 0.0 && posNearBegin < 0.01)
        #expect(posNearEnd > 0.99 && posNearEnd < 1.0)
    }
    
    @Test("Position calculations handle scale length variations")
    func scaleLengthVariations() {
        let shortScale = StandardScales.cScale(length: 100.0)
        let longScale = StandardScales.cScale(length: 500.0)
        
        let value = 5.0
        
        // Normalized positions should be identical regardless of scale length
        let shortPos = ScaleCalculator.normalizedPosition(for: value, on: shortScale)
        let longPos = ScaleCalculator.normalizedPosition(for: value, on: longScale)
        #expect(abs(shortPos - longPos) < 1e-10)
        
        // Absolute positions should scale proportionally
        let shortAbs = ScaleCalculator.absolutePosition(for: value, on: shortScale)
        let longAbs = ScaleCalculator.absolutePosition(for: value, on: longScale)
        let ratio = longAbs / shortAbs
        #expect(abs(ratio - 5.0) < 1e-6, "Absolute positions should scale with length ratio")
    }
    
    @Test("Linear scale demonstrates simple proportional mapping")
    func linearScaleProportionalMapping() {
        let testValues = [0.0, 0.1, 0.2, 0.5, 0.8, 1.0]
        
        for value in testValues {
            let position = ScaleCalculator.normalizedPosition(for: value, on: lScale)
            #expect(abs(position - value) < 1e-10, "Linear scale position should equal value")
        }
    }
}