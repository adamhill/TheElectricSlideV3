import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Priority 1: Comprehensive Scale Position Calculations Test Suite
/// Validates position calculations across different scale types and layouts
@Suite("Scale Position Calculations")
struct ScalePositionCalculationsTests {
    
    @Suite("Logarithmic Scale Normalized Positions")
    struct LogarithmicNormalizedPositions {
        private let cScale = StandardScales.cScale(length: 250.0)
        private let dScale = StandardScales.dScale(length: 250.0)
        
        @Test("C scale position at value 1.0 is exactly 0.0")
        func cScaleAtBeginValue() {
            let position = ScaleCalculator.normalizedPosition(for: 1.0, on: cScale)
            #expect(position == 0.0)
        }
        
        @Test("C scale position at value 2.0 matches logarithmic formula")
        func cScaleAtValue2() {
            let position = ScaleCalculator.normalizedPosition(for: 2.0, on: cScale)
            let expected = log10(2.0)
            #expect(abs(position - expected) < 1e-10)
        }
        
        @Test("C scale position at value 5.0 matches logarithmic formula")
        func cScaleAtValue5() {
            let position = ScaleCalculator.normalizedPosition(for: 5.0, on: cScale)
            let expected = log10(5.0)
            #expect(abs(position - expected) < 1e-10)
        }
        
        @Test("C scale position at value 10.0 is exactly 1.0")
        func cScaleAtEndValue() {
            let position = ScaleCalculator.normalizedPosition(for: 10.0, on: cScale)
            #expect(position == 1.0)
        }
        
        @Test("D scale produces identical positions to C scale")
        func dScaleMatchesCScale() {
            let testValues = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0]
            
            for value in testValues {
                let cPos = ScaleCalculator.normalizedPosition(for: value, on: cScale)
                let dPos = ScaleCalculator.normalizedPosition(for: value, on: dScale)
                #expect(abs(cPos - dPos) < 1e-10, "C and D scales should have identical positions at value \(value)")
            }
        }
    }
    
    @Suite("Absolute Position Calculations")
    struct AbsolutePositionCalculations {
        private let cScale = StandardScales.cScale(length: 250.0)
        
        @Test("Absolute position accounts for scale length correctly")
        func absolutePositionScalesWithLength() {
            let value = 5.0
            let normalized = ScaleCalculator.normalizedPosition(for: value, on: cScale)
            let absolute = ScaleCalculator.absolutePosition(for: value, on: cScale)
            
            let expected = normalized * cScale.scaleLengthInPoints
            #expect(abs(absolute - expected) < 1e-10)
        }
        
        @Test("Absolute position at value 1.0 is 0.0 points")
        func absoluteAtBeginValue() {
            let absolute = ScaleCalculator.absolutePosition(for: 1.0, on: cScale)
            #expect(absolute == 0.0)
        }
        
        @Test("Absolute position at value 10.0 equals scale length")
        func absoluteAtEndValue() {
            let absolute = ScaleCalculator.absolutePosition(for: 10.0, on: cScale)
            #expect(abs(absolute - cScale.scaleLengthInPoints) < 1e-10)
        }
        
        @Test("Absolute position at value 2.0 is log₁₀(2) × scale length")
        func absoluteAtValue2() {
            let absolute = ScaleCalculator.absolutePosition(for: 2.0, on: cScale)
            let expected = log10(2.0) * cScale.scaleLengthInPoints
            #expect(abs(absolute - expected) < 1e-10)
        }
    }
    
    @Suite("Angular Position Calculations for Circular Scales")
    struct AngularPositionCalculations {
        private let circularC = ScaleDefinition(
            name: "C-Circular",
            function: LogarithmicFunction(),
            beginValue: 1,
            endValue: 10,
            scaleLengthInPoints: 360.0,
            layout: .circular(diameter: 200, radiusInPoints: 100),
            subsections: []
        )
        
        @Test("Angular position for circular C scale at value 1.0 is 0°")
        func angularAt1() {
            let angle = ScaleCalculator.angularPosition(for: 1.0, on: circularC)
            #expect(angle == 0.0)
        }
        
        @Test("Angular position for circular C scale at value 10.0 is 360°")
        func angularAt10() {
            let angle = ScaleCalculator.angularPosition(for: 10.0, on: circularC)
            #expect(abs(angle - 360.0) < 0.01)
        }
        
        @Test("Angular position for circular C scale at π is approximately 179°")
        func angularAtPi() {
            let angle = ScaleCalculator.angularPosition(for: .pi, on: circularC)
            let expected = log10(Double.pi) * 360.0
            #expect(abs(angle - expected) < 0.1)
        }
        
        @Test("Angular position at quarter circle is 90°")
        func angularAtQuarterCircle() {
            // Value at normalized position 0.25: 10^0.25 ≈ 1.778
            let value = pow(10, 0.25)
            let angle = ScaleCalculator.angularPosition(for: value, on: circularC)
            #expect(abs(angle - 90.0) < 0.1)
        }
        
        @Test("Angular position at half circle is 180°")
        func angularAtHalfCircle() {
            // Value at normalized position 0.5: 10^0.5 ≈ 3.162
            let value = pow(10, 0.5)
            let angle = ScaleCalculator.angularPosition(for: value, on: circularC)
            #expect(abs(angle - 180.0) < 0.1)
        }
        
        @Test("Angular position at three-quarter circle is 270°")
        func angularAtThreeQuarterCircle() {
            // Value at normalized position 0.75: 10^0.75 ≈ 5.623
            let value = pow(10, 0.75)
            let angle = ScaleCalculator.angularPosition(for: value, on: circularC)
            #expect(abs(angle - 270.0) < 0.1)
        }
    }
    
    @Suite("Inverse Calculations - Position to Value")
    struct InverseCalculations {
        private let cScale = StandardScales.cScale(length: 250.0)
        private let lScale = StandardScales.lScale(length: 250.0)
        
        @Test("Position to value round-trip maintains accuracy within tolerance")
        func roundTripAccuracy() {
            let testValues = [1.0, 1.5, 2.0, 3.14159, 5.0, 7.5, 10.0]
            
            for originalValue in testValues {
                let position = ScaleCalculator.normalizedPosition(for: originalValue, on: cScale)
                let recoveredValue = ScaleCalculator.value(at: position, on: cScale)
                
                let relativeError = abs(recoveredValue - originalValue) / originalValue
                #expect(relativeError < 1e-6, "Round-trip failed for \(originalValue)")
            }
        }
        
        @Test("Value at position 0.0 on C scale is 1.0")
        func valueAtPosition0() {
            let value = ScaleCalculator.value(at: 0.0, on: cScale)
            #expect(abs(value - 1.0) < 1e-6)
        }
        
        @Test("Value at position 0.5 on C scale is √10")
        func valueAtPositionHalf() {
            let value = ScaleCalculator.value(at: 0.5, on: cScale)
            let expected = sqrt(10.0)
            #expect(abs(value - expected) < 1e-6)
        }
        
        @Test("Value at position 1.0 on C scale is 10.0")
        func valueAtPosition1() {
            let value = ScaleCalculator.value(at: 1.0, on: cScale)
            #expect(abs(value - 10.0) < 1e-6)
        }
        
        @Test("Normalized position 0.5 on linear scale gives midpoint value")
        func linearScaleMidpoint() {
            let value = ScaleCalculator.value(at: 0.5, on: lScale)
            #expect(abs(value - 0.5) < 1e-10, "Linear scale midpoint should be 0.5")
        }
    }
    
    @Suite("Edge Cases - Begin, End, and Midpoint Values")
    struct EdgeCaseValues {
        private let cScale = StandardScales.cScale(length: 250.0)
        private let aScale = StandardScales.aScale(length: 250.0)
        private let kScale = StandardScales.kScale(length: 250.0)
        
        @Test("Scale begin values always map to position 0.0")
        func beginValuesMapToZero() {
            #expect(ScaleCalculator.normalizedPosition(for: cScale.beginValue, on: cScale) == 0.0)
            #expect(ScaleCalculator.normalizedPosition(for: aScale.beginValue, on: aScale) == 0.0)
            #expect(ScaleCalculator.normalizedPosition(for: kScale.beginValue, on: kScale) == 0.0)
        }
        
        @Test("Scale end values always map to position 1.0")
        func endValuesMapToOne() {
            #expect(ScaleCalculator.normalizedPosition(for: cScale.endValue, on: cScale) == 1.0)
            #expect(ScaleCalculator.normalizedPosition(for: aScale.endValue, on: aScale) == 1.0)
            #expect(ScaleCalculator.normalizedPosition(for: kScale.endValue, on: kScale) == 1.0)
        }
        
        @Test("Midpoint calculation is accurate for logarithmic scales")
        func logarithmicMidpoint() {
            let midValue = ScaleCalculator.value(at: 0.5, on: cScale)
            // For C scale (1 to 10), midpoint is geometric mean: √(1 × 10) = √10
            let expected = sqrt(10.0)
            #expect(abs(midValue - expected) < 1e-6)
        }
        
        @Test("Near-boundary values produce stable positions")
        func nearBoundaryStability() {
            let nearBegin = 1.0001
            let nearEnd = 9.9999
            
            let posNearBegin = ScaleCalculator.normalizedPosition(for: nearBegin, on: cScale)
            let posNearEnd = ScaleCalculator.normalizedPosition(for: nearEnd, on: cScale)
            
            #expect(posNearBegin > 0.0 && posNearBegin < 0.01, "Near-begin position should be close to 0")
            #expect(posNearEnd > 0.99 && posNearEnd < 1.0, "Near-end position should be close to 1")
        }
    }
    
    @Suite("Different Scale Functions Produce Different Distributions")
    struct ScaleFunctionDistributions {
        private let cScale = StandardScales.cScale(length: 250.0)
        private let aScale = StandardScales.aScale(length: 250.0)
        private let kScale = StandardScales.kScale(length: 250.0)
        private let lScale = StandardScales.lScale(length: 250.0)
        
        @Test("Logarithmic scale compresses high values")
        func logarithmicCompression() {
            // On C scale, distance from 1→2 should be greater than 9→10
            let pos1to2 = ScaleCalculator.normalizedPosition(for: 2.0, on: cScale) - ScaleCalculator.normalizedPosition(for: 1.0, on: cScale)
            let pos9to10 = ScaleCalculator.normalizedPosition(for: 10.0, on: cScale) - ScaleCalculator.normalizedPosition(for: 9.0, on: cScale)
            
            #expect(pos1to2 > pos9to10, "Logarithmic scale should compress high values")
        }
        
        @Test("A scale compresses values more than C scale")
        func aScaleCompressionVsCScale() {
            let value = 50.0
            let cPos = ScaleCalculator.normalizedPosition(for: value, on: cScale)
            let aPos = ScaleCalculator.normalizedPosition(for: value, on: aScale)
            
            // A scale (squared) should be at lower position than C scale for same value > 10
            #expect(aPos < cPos, "A scale should compress more than C scale for value \(value)")
        }
        
        @Test("K scale compresses values more than A scale")
        func kScaleCompressionVsAScale() {
            let value = 100.0
            let aPos = ScaleCalculator.normalizedPosition(for: value, on: aScale)
            let kPos = ScaleCalculator.normalizedPosition(for: value, on: kScale)
            
            // K scale (cubed) should be at lower position than A scale for same value > 10
            #expect(kPos < aPos, "K scale should compress more than A scale for value \(value)")
        }
        
        @Test("Linear scale has uniform distribution")
        func linearUniformDistribution() {
            let values = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
            
            for value in values {
                let position = ScaleCalculator.normalizedPosition(for: value, on: lScale)
                #expect(abs(position - value) < 1e-10, "Linear scale position should equal value")
            }
        }
    }
    
    @Suite("Circular vs Linear Layout Consistency")
    struct CircularVsLinearConsistency {
        private let linearC = StandardScales.cScale(length: 250.0)
        private let circularC = ScaleDefinition(
            name: "C-Circular",
            function: LogarithmicFunction(),
            beginValue: 1,
            endValue: 10,
            scaleLengthInPoints: 360.0,
            layout: .circular(diameter: 200, radiusInPoints: 100),
            subsections: []
        )
        
        @Test("Normalized positions are identical between linear and circular layouts")
        func normalizedPositionsMatch() {
            let testValues = [1.0, 2.0, 5.0, 10.0]
            
            for value in testValues {
                let linearPos = ScaleCalculator.normalizedPosition(for: value, on: linearC)
                let circularPos = ScaleCalculator.normalizedPosition(for: value, on: circularC)
                
                #expect(abs(linearPos - circularPos) < 1e-10, "Normalized positions should match for value \(value)")
            }
        }
        
        @Test("Angular position equals normalized position × 360°")
        func angularRelationship() {
            let value = 5.0
            let normalized = ScaleCalculator.normalizedPosition(for: value, on: circularC)
            let angular = ScaleCalculator.angularPosition(for: value, on: circularC)
            
            let expected = normalized * 360.0
            #expect(abs(angular - expected) < 0.01)
        }
        
        @Test("Circular layout begin and end values differ from linear at 360°")
        func circularEndBehavior() {
            // For a full circle (1 to 10), end value overlaps with begin
            let angleAt1 = ScaleCalculator.angularPosition(for: 1.0, on: circularC)
            let angleAt10 = ScaleCalculator.angularPosition(for: 10.0, on: circularC)
            
            #expect(angleAt1 == 0.0)
            #expect(abs(angleAt10 - 360.0) < 0.01)
        }
    }
    
    @Suite("Squared and Cubed Scale Position Calculations")
    struct PowerScalePositions {
        private let aScale = StandardScales.aScale(length: 250.0)
        private let kScale = StandardScales.kScale(length: 250.0)
        
        @Test("A scale value 1.0 maps to position 0.0")
        func aScaleAtBegin() {
            let position = ScaleCalculator.normalizedPosition(for: 1.0, on: aScale)
            #expect(position == 0.0)
        }
        
        @Test("A scale value 10.0 maps to position 0.5 (midpoint of 1 to 100)")
        func aScaleAtMidpoint() {
            let position = ScaleCalculator.normalizedPosition(for: 10.0, on: aScale)
            #expect(abs(position - 0.5) < 1e-10)
        }
        
        @Test("A scale value 100.0 maps to position 1.0")
        func aScaleAtEnd() {
            let position = ScaleCalculator.normalizedPosition(for: 100.0, on: aScale)
            #expect(position == 1.0)
        }
        
        @Test("K scale value 1.0 maps to position 0.0")
        func kScaleAtBegin() {
            let position = ScaleCalculator.normalizedPosition(for: 1.0, on: kScale)
            #expect(position == 0.0)
        }
        
        @Test("K scale value 10.0 maps to position ⅓ (first third of 1 to 1000)")
        func kScaleAtOneThird() {
            let position = ScaleCalculator.normalizedPosition(for: 10.0, on: kScale)
            let expected = 1.0 / 3.0
            #expect(abs(position - expected) < 1e-10)
        }
        
        @Test("K scale value 100.0 maps to position ⅔ (two thirds of 1 to 1000)")
        func kScaleAtTwoThirds() {
            let position = ScaleCalculator.normalizedPosition(for: 100.0, on: kScale)
            let expected = 2.0 / 3.0
            #expect(abs(position - expected) < 1e-10)
        }
        
        @Test("K scale value 1000.0 maps to position 1.0")
        func kScaleAtEnd() {
            let position = ScaleCalculator.normalizedPosition(for: 1000.0, on: kScale)
            #expect(position == 1.0)
        }
    }
    
    @Suite("Scale Length Independence")
    struct ScaleLengthIndependence {
        
        @Test("Normalized positions are independent of scale length")
        func normalizedIndependentOfLength() {
            let shortC = StandardScales.cScale(length: 100.0)
            let longC = StandardScales.cScale(length: 500.0)
            let value = 5.0
            
            let shortPos = ScaleCalculator.normalizedPosition(for: value, on: shortC)
            let longPos = ScaleCalculator.normalizedPosition(for: value, on: longC)
            
            #expect(abs(shortPos - longPos) < 1e-10, "Normalized positions should be scale-length independent")
        }
        
        @Test("Absolute positions scale proportionally with length")
        func absoluteScalesProportionally() {
            let shortC = StandardScales.cScale(length: 100.0)
            let longC = StandardScales.cScale(length: 500.0)
            let value = 5.0
            
            let shortAbs = ScaleCalculator.absolutePosition(for: value, on: shortC)
            let longAbs = ScaleCalculator.absolutePosition(for: value, on: longC)
            
            let ratio = longAbs / shortAbs
            #expect(abs(ratio - 5.0) < 1e-6, "Absolute positions should scale 5:1")
        }
    }
    
    @Suite("Special Values and Mathematical Constants")
    struct SpecialValues {
        private let cScale = StandardScales.cScale(length: 250.0)
        private let circularC = ScaleDefinition(
            name: "C-Circular",
            function: LogarithmicFunction(),
            beginValue: 1,
            endValue: 10,
            scaleLengthInPoints: 360.0,
            layout: .circular(diameter: 200, radiusInPoints: 100),
            subsections: []
        )
        
        @Test("Value e (2.71828...) positions correctly on C scale")
        func eulerConstant() {
            let position = ScaleCalculator.normalizedPosition(for: Double.e, on: cScale)
            let expected = log10(Double.e)
            #expect(abs(position - expected) < 1e-10)
        }
        
        @Test("Value π (3.14159...) positions correctly on C scale")
        func piConstant() {
            let position = ScaleCalculator.normalizedPosition(for: .pi, on: cScale)
            let expected = log10(Double.pi)
            #expect(abs(position - expected) < 1e-10)
        }
        
        @Test("Golden ratio positions correctly on C scale")
        func goldenRatio() {
            let phi = (1.0 + sqrt(5.0)) / 2.0
            let position = ScaleCalculator.normalizedPosition(for: phi, on: cScale)
            let expected = log10(phi)
            #expect(abs(position - expected) < 1e-10)
        }
        
        @Test("Value e on circular scale positions at expected angle")
        func eulerOnCircular() {
            let angle = ScaleCalculator.angularPosition(for: Double.e, on: circularC)
            let expected = log10(Double.e) * 360.0
            #expect(abs(angle - expected) < 0.1)
        }
    }
    
    @Suite("Precision and Numerical Stability")
    struct PrecisionAndStability {
        private let cScale = StandardScales.cScale(length: 250.0)
        
        @Test("Calculations maintain precision for very close values")
        func precisionForCloseValues() {
            let value1 = 5.0
            let value2 = 5.0001
            
            let pos1 = ScaleCalculator.normalizedPosition(for: value1, on: cScale)
            let pos2 = ScaleCalculator.normalizedPosition(for: value2, on: cScale)
            
            // Positions should be different but very close
            #expect(pos1 != pos2, "Different values should have different positions")
            #expect(abs(pos2 - pos1) < 1e-4, "Close values should have close positions")
        }
        
        @Test("Multiple round-trips maintain accuracy")
        func multipleRoundTrips() {
            var value = 5.0
            
            // Do 10 round trips: value → position → value → position → ...
            for _ in 0..<10 {
                let position = ScaleCalculator.normalizedPosition(for: value, on: cScale)
                value = ScaleCalculator.value(at: position, on: cScale)
            }
            
            let finalError = abs(value - 5.0) / 5.0
            #expect(finalError < 1e-6, "Multiple round-trips should maintain accuracy")
        }
    }
}
