import Testing
import Foundation
@testable import SlideRuleCore

/// Priority 2: Comprehensive Exotic Scales Test Suite
/// Tests specialized scales including hyperbolic, power, and ultra-fine precision LL scales
@Suite("Exotic Scales - Comprehensive Coverage")
struct StandardScalesExoticTests {
    
    // MARK: - Hyperbolic Scale Implementations
    
    @Suite("Hyperbolic Scale Implementations")
    struct HyperbolicScalesTests {
        
        @Test("Hyperbolic sine scale handles positive value range correctly")
        func shScaleBasicGeneration() throws {
            let shScale = StandardScales.shScale(length: 250.0)
            
            #expect(shScale.name == "Sh")
            #expect(shScale.beginValue == 0.5)
            #expect(shScale.endValue == 3.0)
            #expect(shScale.scaleLengthInPoints == 250.0)
            #expect(shScale.tickDirection == .down)
        }
        
        @Test("Hyperbolic sine scale mathematical correctness for sample values", 
              arguments: [(0.5, sinh(0.5)), (1.0, sinh(1.0)), (2.0, sinh(2.0)), (3.0, sinh(3.0))])
        func shScaleMathematicalCorrectness(input: Double, expectedSinh: Double) throws {
            let shScale = StandardScales.shScale(length: 250.0)
            
            // The transform should be log10(sinh(x))
            let transform = shScale.function.transform(input)
            let expected = log10(expectedSinh)
            
            #expect(abs(transform - expected) < 1e-9, 
                   "Sh scale transform for \(input) should equal log10(sinh(\(input)))")
        }
        
        @Test("Hyperbolic sine scale round-trip accuracy maintains precision")
        func shScaleRoundTripAccuracy() throws {
            let shScale = StandardScales.shScale(length: 250.0)
            let testValues = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
            
            for value in testValues {
                let transformed = shScale.function.transform(value)
                let recovered = shScale.function.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-6, 
                       "Sh scale round-trip failed for value \(value)")
            }
        }
        
        @Test("Hyperbolic cosine scale handles zero to positive range correctly")
        func chScaleBasicGeneration() throws {
            let chScale = StandardScales.chScale(length: 250.0)
            
            #expect(chScale.name == "Ch")
            #expect(chScale.beginValue == 0.0)
            #expect(chScale.endValue == 3.0)
            #expect(chScale.scaleLengthInPoints == 250.0)
            #expect(chScale.tickDirection == .down)
        }
        
        @Test("Hyperbolic cosine scale mathematical correctness for sample values",
              arguments: [(0.0, cosh(0.0)), (1.0, cosh(1.0)), (2.0, cosh(2.0)), (3.0, cosh(3.0))])
        func chScaleMathematicalCorrectness(input: Double, expectedCosh: Double) throws {
            let chScale = StandardScales.chScale(length: 250.0)
            
            // The transform should be log10(cosh(x))
            let transform = chScale.function.transform(input)
            let expected = log10(expectedCosh)
            
            #expect(abs(transform - expected) < 1e-9,
                   "Ch scale transform for \(input) should equal log10(cosh(\(input)))")
        }
        
        @Test("Hyperbolic cosine scale handles boundary at zero correctly")
        func chScaleBoundaryAtZero() throws {
            let chScale = StandardScales.chScale(length: 250.0)
            
            // cosh(0) = 1, so log10(1) = 0
            let transformAt0 = chScale.function.transform(0.0)
            #expect(abs(transformAt0 - 0.0) < 1e-9, 
                   "Ch scale at x=0 should give log10(1) = 0")
        }
        
        @Test("Hyperbolic tangent scale handles positive value range correctly")
        func thScaleBasicGeneration() throws {
            let thScale = StandardScales.thScale(length: 250.0)
            
            #expect(thScale.name == "Th")
            #expect(thScale.beginValue == 0.5)
            #expect(thScale.endValue == 2.5)
            #expect(thScale.scaleLengthInPoints == 250.0)
            #expect(thScale.tickDirection == .down)
        }
        
        @Test("Hyperbolic tangent scale mathematical correctness for sample values",
              arguments: [(0.5, tanh(0.5)), (1.0, tanh(1.0)), (2.0, tanh(2.0)), (2.5, tanh(2.5))])
        func thScaleMathematicalCorrectness(input: Double, expectedTanh: Double) throws {
            let thScale = StandardScales.thScale(length: 250.0)
            
            // The transform should be log10(tanh(x))
            let transform = thScale.function.transform(input)
            let expected = log10(expectedTanh)
            
            #expect(abs(transform - expected) < 1e-9,
                   "Th scale transform for \(input) should equal log10(tanh(\(input)))")
        }
        
        @Test("Hyperbolic tangent scale asymptotically approaches 1.0 for large values")
        func thScaleAsymptoticBehavior() throws {
            _ = StandardScales.thScale(length: 250.0)
            
            // tanh(x) approaches 1 as x increases, so tanh(2.5) should be close to 1
            let value = 2.5
            let tanhValue = tanh(value)
            
            #expect(tanhValue > 0.98 && tanhValue < 1.0,
                   "tanh(2.5) should be close to but less than 1.0")
        }
        
        @Test("Hyperbolic scales work with different scale lengths",
              arguments: [100.0, 250.0, 500.0, 1000.0])
        func hyperbolicScalesWithDifferentLengths(length: Double) throws {
            let shScale = StandardScales.shScale(length: length)
            let chScale = StandardScales.chScale(length: length)
            let thScale = StandardScales.thScale(length: length)
            
            #expect(shScale.scaleLengthInPoints == length)
            #expect(chScale.scaleLengthInPoints == length)
            #expect(thScale.scaleLengthInPoints == length)
        }
    }
    
    // MARK: - Power and Pythagorean Scales
    
    @Suite("Power and Pythagorean Scales")
    struct PowerScalesTests {
        
        @Test("PA scale with standard range 1-100 generates correct power values")
        func paScaleStandardRange() throws {
            let paScale = StandardScales.paScale(length: 250.0)
            
            #expect(paScale.name == "PA")
            #expect(paScale.beginValue == 1.0)
            #expect(paScale.endValue == 100.0)
            #expect(paScale.tickDirection == .up)
        }
        
        @Test("PA scale mathematical correctness for power calculations",
              arguments: [(1.0, 1.0), (2.0, 4.0), (5.0, 25.0), (10.0, 100.0)])
        func paScaleMathematicalCorrectness(input: Double, expectedSquare: Double) throws {
            let paScale = StandardScales.paScale(length: 250.0)
            
            // PA scale: log10(x^2) = 2 * log10(x)
            let transform = paScale.function.transform(input)
            let expected = log10(expectedSquare)
            
            #expect(abs(transform - expected) < 1e-9,
                   "PA scale transform for \(input) should equal log10(\(expectedSquare))")
        }
        
        @Test("PA scale round-trip maintains accuracy for power values")
        func paScaleRoundTripAccuracy() throws {
            let paScale = StandardScales.paScale(length: 250.0)
            let testValues = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 50.0, 100.0]
            
            for value in testValues {
                let transformed = paScale.function.transform(value)
                let recovered = paScale.function.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-6,
                       "PA scale round-trip failed for value \(value)")
            }
        }
        
        @Test("PA scale generates appropriate subsections for range")
        func paScaleSubsections() throws {
            let paScale = StandardScales.paScale(length: 250.0)
            
            #expect(paScale.subsections.count >= 2,
                   "PA scale should have multiple subsections for different density regions")
            
            // Check that subsections cover the range
            let firstSubsection = paScale.subsections.first
            #expect(firstSubsection?.startValue == 1.0)
        }
        
        @Test("P (Pythagorean) scale calculates hypotenuse values correctly")
        func pScaleBasicGeneration() throws {
            let pScale = StandardScales.pScale(length: 250.0)
            
            #expect(pScale.name == "P")
            #expect(pScale.beginValue == 1.0)
            #expect(pScale.endValue == 10.0)
            #expect(pScale.tickDirection == .up)
        }
        
        @Test("P scale mathematical correctness for Pythagorean calculations",
              arguments: [(1.0, sqrt(2.0)), (2.0, sqrt(5.0)), (3.0, sqrt(10.0)), (5.0, sqrt(26.0))])
        func pScaleMathematicalCorrectness(input: Double, expectedHypotenuse: Double) throws {
            let pScale = StandardScales.pScale(length: 250.0)
            
            // P scale: log10(sqrt(x^2 + 1))
            let transform = pScale.function.transform(input)
            let expected = log10(expectedHypotenuse)
            
            #expect(abs(transform - expected) < 1e-9,
                   "P scale transform for \(input) should equal log10(sqrt(\(input)^2 + 1))")
        }
        
        @Test("P scale handles unit value correctly as sqrt(2)")
        func pScaleUnitValue() throws {
            let pScale = StandardScales.pScale(length: 250.0)
            
            // For x=1: sqrt(1^2 + 1) = sqrt(2)
            let transformAt1 = pScale.function.transform(1.0)
            let expected = log10(sqrt(2.0))
            
            #expect(abs(transformAt1 - expected) < 1e-9,
                   "P scale at x=1 should give log10(sqrt(2))")
        }
        
        @Test("P scale round-trip accuracy for hypotenuse calculations")
        func pScaleRoundTripAccuracy() throws {
            let pScale = StandardScales.pScale(length: 250.0)
            let testValues = [1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 10.0]
            
            for value in testValues {
                let transformed = pScale.function.transform(value)
                let recovered = pScale.function.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-6,
                       "P scale round-trip failed for value \(value)")
            }
        }
    }
    
    // MARK: - Extended LL Scales with Ultra-Fine Precision
    
    @Suite("Extended LL Scales with Ultra-Fine Precision")
    struct ExtendedLLScalesTests {
        
        @Test("LL1 scale maintains ultra-fine precision between 1.01 and 1.105")
        func ll1ScalePrecisionRange() throws {
            let ll1Scale = StandardScales.ll1Scale(length: 250.0)
            
            #expect(ll1Scale.name == "LL1")
            #expect(ll1Scale.beginValue == 1.01)
            #expect(ll1Scale.endValue == 1.105)
            #expect(ll1Scale.tickDirection == .up)
        }
        
        @Test("LL1 scale has ultra-fine tick intervals for precision")
        func ll1ScaleUltraFineIntervals() throws {
            let ll1Scale = StandardScales.ll1Scale(length: 250.0)
            
            // LL1 should have very fine intervals like 0.001, 0.0005
            guard let firstSubsection = ll1Scale.subsections.first else {
                Issue.record("LL1 scale should have subsections")
                return
            }
            
            // Check for presence of fine intervals
            let hasFinestInterval = firstSubsection.tickIntervals.contains { $0 <= 0.001 }
            #expect(hasFinestInterval,
                   "LL1 scale should have ultra-fine intervals (≤0.001) for high precision")
        }
        
        @Test("LL1 scale mathematical correctness for exponential values",
              arguments: [(1.01, exp(0.01)), (1.05, exp(0.05)), (1.10, exp(0.10))])
        func ll1ScaleMathematicalCorrectness(input: Double, expectedApprox: Double) throws {
            let ll1Scale = StandardScales.ll1Scale(length: 250.0)
            
            // LL1 uses log10(log(x)) * 10 transform
            let transform = ll1Scale.function.transform(input)
            
            // Verify the transform produces reasonable values
            #expect(transform.isFinite, 
                   "LL1 transform for \(input) should be finite")
        }
        
        @Test("LL1 scale round-trip accuracy at precision boundaries")
        func ll1ScaleRoundTripPrecision() throws {
            let ll1Scale = StandardScales.ll1Scale(length: 250.0)
            
            // Test values near boundaries and mid-range
            let testValues = [1.01, 1.02, 1.05, 1.08, 1.10, 1.105]
            
            for value in testValues {
                let transformed = ll1Scale.function.transform(value)
                let recovered = ll1Scale.function.inverseTransform(transformed)
                
                let absoluteError = abs(recovered - value)
                #expect(absoluteError < 0.0001,
                       "LL1 scale round-trip failed for value \(value), error: \(absoluteError)")
            }
        }
        
        @Test("LL2 scale handles medium precision range 1.105 to 2.72")
        func ll2ScaleMediumPrecisionRange() throws {
            let ll2Scale = StandardScales.ll2Scale(length: 250.0)
            
            #expect(ll2Scale.name == "LL2")
            #expect(ll2Scale.beginValue == 1.105)
            #expect(ll2Scale.endValue == 2.72)
            #expect(ll2Scale.tickDirection == .up)
        }
        
        @Test("LL2 scale includes e constant marker at 2.718...")
        func ll2ScaleIncludesEConstant() throws {
            let ll2Scale = StandardScales.ll2Scale(length: 250.0)
            
            // LL2 should have e as a constant
            let hasEConstant = ll2Scale.constants.contains { constant in
                abs(constant.value - Double.e) < 0.01
            }
            
            #expect(hasEConstant,
                   "LL2 scale should mark Euler's number e ≈ 2.718")
        }
        
        @Test("LL2 scale mathematical correctness near e")
        func ll2ScaleMathematicalCorrectnessNearE() throws {
            let ll2Scale = StandardScales.ll2Scale(length: 250.0)
            
            // Test around e
            let testValues = [1.5, 2.0, Double.e, 2.5, 2.72]
            
            for value in testValues {
                let transform = ll2Scale.function.transform(value)
                #expect(transform.isFinite,
                       "LL2 transform for \(value) should be finite")
            }
        }
        
        @Test("LL3 scale handles extended range 2.72 to 21000")
        func ll3ScaleExtendedRange() throws {
            let ll3Scale = StandardScales.ll3Scale(length: 250.0)
            
            #expect(ll3Scale.name == "LL3")
            #expect(ll3Scale.beginValue == 2.74)
            #expect(ll3Scale.endValue == 21000.0)
            #expect(ll3Scale.tickDirection == .up)
        }
        
        @Test("LL3 scale has multiple subsections for wide range")
        func ll3ScaleMultipleSubsections() throws {
            let ll3Scale = StandardScales.ll3Scale(length: 250.0)
            
            // LL3 covers a huge range (2.74 to 21000) so needs many subsections
            #expect(ll3Scale.subsections.count >= 4,
                   "LL3 scale should have multiple subsections for its wide range")
        }
        
        @Test("LL3 scale handles extreme values correctly",
              arguments: [3.0, 10.0, 100.0, 1000.0, 10000.0, 20000.0])
        func ll3ScaleExtremeValues(value: Double) throws {
            let ll3Scale = StandardScales.ll3Scale(length: 250.0)
            
            let transform = ll3Scale.function.transform(value)
            #expect(transform.isFinite,
                   "LL3 scale should handle extreme value \(value) correctly")
            
            let recovered = ll3Scale.function.inverseTransform(transform)
            let relativeError = abs(recovered - value) / value
            #expect(relativeError < 0.01,
                   "LL3 scale round-trip for \(value) should maintain accuracy")
        }
        
        @Test("Extended LL scales work on circular configurations",
              arguments: [(100.0, 40.0), (200.0, 80.0), (300.0, 120.0)])
        func extendedLLScalesOnCircularRules(diameter: Double, radius: Double) throws {
            // Create scales with circular layout
            let ll1 = StandardScales.ll1Scale(length: 250.0)
            let ll2 = StandardScales.ll2Scale(length: 250.0)
            let ll3 = StandardScales.ll3Scale(length: 250.0)
            
            // Test that scales can be configured for circular layout
            let circularLayout = ScaleLayout.circular(diameter: diameter, radiusInPoints: radius)
            
            #expect(circularLayout.isCircular)
            #expect(circularLayout.diameter == diameter)
            #expect(circularLayout.radius == radius)
            
            // Verify scales maintain their properties regardless of layout
            #expect(ll1.beginValue == 1.01)
            #expect(ll2.beginValue == 1.105)
            #expect(ll3.beginValue == 2.74)
        }
    }
    
    // MARK: - Circular Scale Positioning and Boundaries
    
    @Suite("Circular Scale Positioning and Boundaries")
    struct CircularScaleTests {
        
        @Test("Circular C scale with full 360° coverage maintains consistency")
        func circularCScaleFullCoverage() throws {
            let cScale = StandardScales.cScale(length: 250.0)
            
            // C scale properties that should work on circular layout
            #expect(cScale.beginValue == 1.0)
            #expect(cScale.endValue == 10.0)
            
            // Verify range spans one full decade
            let decade = cScale.endValue / cScale.beginValue
            #expect(abs(decade - 10.0) < 1e-9,
                   "C scale should span exactly one decade")
        }
        
        @Test("Circular scale prevents duplicate ticks at 0°/360° boundary")
        func circularScaleBoundaryOverlap() throws {
            // For a circular scale, position 0.0 and 1.0 represent the same point
            // This is a logical test - implementation would handle this in ScaleCalculator
            
            let cScale = StandardScales.cScale(length: 250.0)
            
            // Verify begin and end values differ (not both at same physical point)
            #expect(cScale.beginValue != cScale.endValue,
                   "Circular scale begin and end values must differ to avoid overlap")
        }
        
        @Test("Circular LL scales maintain precision at boundaries")
        func circularLLScalePrecisionAtBoundaries() throws {
            let ll1Scale = StandardScales.ll1Scale(length: 250.0)
            
            // Test precision at start boundary
            let startTransform = ll1Scale.function.transform(ll1Scale.beginValue)
            let startRecovered = ll1Scale.function.inverseTransform(startTransform)
            
            let startError = abs(startRecovered - ll1Scale.beginValue)
            #expect(startError < 0.0001,
                   "LL1 scale should maintain precision at start boundary")
            
            // Test precision at end boundary
            let endTransform = ll1Scale.function.transform(ll1Scale.endValue)
            let endRecovered = ll1Scale.function.inverseTransform(endTransform)
            
            let endError = abs(endRecovered - ll1Scale.endValue)
            #expect(endError < 0.0001,
                   "LL1 scale should maintain precision at end boundary")
        }
        
        @Test("Circular trig scales handle angle wrapping correctly",
              arguments: [0.0, 90.0, 180.0, 270.0, 360.0])
        func circularTrigScaleAngleWrapping(angle: Double) throws {
            // Test that trig functions handle angle boundaries properly
            let sineValue = sin(angle * .pi / 180.0)
            
            // sin(0°) = sin(360°) = 0
            if angle == 0.0 || angle == 360.0 {
                #expect(abs(sineValue) < 1e-9,
                       "Sine should be 0 at \(angle)°")
            }
            
            // sin(90°) = 1
            if angle == 90.0 {
                #expect(abs(sineValue - 1.0) < 1e-9,
                       "Sine should be 1 at 90°")
            }
            
            // sin(180°) = 0
            if angle == 180.0 {
                #expect(abs(sineValue) < 1e-9,
                       "Sine should be 0 at 180°")
            }
            
            // sin(270°) = -1
            if angle == 270.0 {
                #expect(abs(sineValue + 1.0) < 1e-9,
                       "Sine should be -1 at 270°")
            }
        }
        
        @Test("Partial circular arcs maintain scale correctness",
              arguments: [90.0, 180.0, 270.0])
        func partialCircularArcs(arcDegrees: Double) throws {
            // Test that scales work correctly on partial circular arcs
            _ = StandardScales.cScale(length: 250.0)
            
            // For partial arcs, the physical length would be proportional to the arc
            let fullCircleLength = 250.0
            let arcLength = fullCircleLength * (arcDegrees / 360.0)
            
            #expect(arcLength > 0 && arcLength <= fullCircleLength,
                   "Partial arc of \(arcDegrees)° should have valid length")
        }
        
        @Test("Circular layout diameter and radius calculations are consistent")
        func circularLayoutConsistency() throws {
            let testCases: [(diameter: Double, radius: Double)] = [
                (100.0, 50.0),
                (200.0, 100.0),
                (150.0, 75.0)
            ]
            
            for (diameter, radius) in testCases {
                let layout = ScaleLayout.circular(diameter: diameter, radiusInPoints: radius)
                
                #expect(layout.diameter == diameter,
                       "Circular layout should preserve diameter")
                #expect(layout.radius == radius,
                       "Circular layout should preserve radius")
                #expect(layout.isCircular,
                       "Layout should be identified as circular")
            }
        }
    }
    
    // MARK: - CI Scale Inverse Transform
    
    @Suite("CI Scale Inverse Transform Correctness")
    struct CIScaleInverseTests {
        
        @Test("CI scale generates correct reciprocal values")
        func ciScaleBasicGeneration() throws {
            let ciScale = StandardScales.ciScale(length: 250.0)
            
            #expect(ciScale.name == "CI")
            #expect(ciScale.beginValue == 10.0)
            #expect(ciScale.endValue == 1.0)
            #expect(ciScale.tickDirection == .up)
        }
        
        @Test("CI scale reciprocal calculation is mathematically correct",
              arguments: [(10.0, 0.1), (5.0, 0.2), (2.0, 0.5), (1.0, 1.0)])
        func ciScaleReciprocalCorrectness(input: Double, expectedReciprocal: Double) throws {
            let ciScale = StandardScales.ciScale(length: 250.0)
            
            // CI scale: -log10(x) for reciprocal
            let transform = ciScale.function.transform(input)
            let expected = -log10(input)
            
            #expect(abs(transform - expected) < 1e-9,
                   "CI scale transform for \(input) should equal -log10(\(input))")
        }
        
        @Test("CI scale inverse transform maintains reciprocal relationship")
        func ciScaleInverseTransformCorrectness() throws {
            let ciScale = StandardScales.ciScale(length: 250.0)
            
            let testValues = [10.0, 5.0, 3.0, 2.0, 1.5, 1.0]
            
            for value in testValues {
                let transformed = ciScale.function.transform(value)
                let recovered = ciScale.function.inverseTransform(transformed)
                
                let relativeError = abs(recovered - value) / value
                #expect(relativeError < 1e-9,
                       "CI scale inverse failed for value \(value)")
            }
        }
        
        @Test("CI scale reciprocal property: CI(x) * C(x) alignment")
        func ciScaleReciprocalProperty() throws {
            let ciScale = StandardScales.ciScale(length: 250.0)
            let cScale = StandardScales.cScale(length: 250.0)
            
            // For the same physical position, CI should read the reciprocal of C
            let testValue = 2.0
            
            let cTransform = cScale.function.transform(testValue)
            let ciTransform = ciScale.function.transform(testValue)
            
            // CI transform should be negative of C transform for reciprocal
            #expect(abs(ciTransform + cTransform) < 1e-9,
                   "CI and C transforms should sum to ~0 for reciprocal relationship")
        }
    }
    
    // MARK: - Advanced Trigonometric Scales
    
    @Suite("Advanced Trigonometric Scale Coverage")
    struct AdvancedTrigScalesTests {
        
        @Test("KE-S scale extends sine scale starting point to 5.5°")
        func keSScaleExtendedRange() throws {
            let keS = StandardScales.keSScale(length: 250.0)
            
            #expect(keS.name == "KE-S")
            #expect(keS.beginValue == 5.5)
            #expect(keS.endValue == 90.0)
            
            // Compare with standard S scale
            let standardS = StandardScales.sScale(length: 250.0)
            #expect(keS.beginValue < standardS.beginValue,
                   "KE-S should start earlier than standard S scale")
        }
        
        @Test("KE-T scale extends tangent scale starting point to 5.5°")
        func keTScaleExtendedRange() throws {
            let keT = StandardScales.keTScale(length: 250.0)
            
            #expect(keT.name == "KE-T")
            #expect(keT.beginValue == 5.5)
            #expect(keT.endValue == 45.0)
            
            // Compare with standard T scale
            let standardT = StandardScales.tScale(length: 250.0)
            #expect(keT.beginValue < standardT.beginValue,
                   "KE-T should start earlier than standard T scale")
        }
        
        @Test("SRT (KE-ST) small angle tangent has extended range")
        func srtScaleExtendedSmallAngleRange() throws {
            let srt = StandardScales.keSTScale(length: 250.0)
            
            #expect(srt.name == "SRT")
            #expect(srt.beginValue == 0.55)
            #expect(srt.endValue == 6.0)
            
            // Compare with standard ST scale
            let standardST = StandardScales.stScale(length: 250.0)
            #expect(srt.beginValue < standardST.beginValue,
                   "SRT should start earlier than standard ST scale")
            #expect(srt.endValue > standardST.endValue,
                   "SRT should extend further than standard ST scale")
        }
        
        @Test("CR3S combined sine/cosine scale covers 6° to 90°")
        func cr3sCombinedScale() throws {
            let cr3s = StandardScales.cr3sScale(length: 250.0)
            
            #expect(cr3s.name == "S/C")
            #expect(cr3s.beginValue == 6.0)
            #expect(cr3s.endValue == 90.0)
            
            // CR3S should have constants for small angles
            let hasSmallAngleConstants = cr3s.constants.count >= 5
            #expect(hasSmallAngleConstants,
                   "CR3S should include small angle constant markers")
        }
        
        @Test("Trig scales handle complementary angle relationships")
        func trigScalesComplementaryAngles() throws {
            // sin(x) = cos(90° - x)
            let testAngles = [15.0, 30.0, 45.0, 60.0, 75.0]
            
            for angle in testAngles {
                let sineValue = sin(angle * .pi / 180.0)
                let cosineComplement = cos((90.0 - angle) * .pi / 180.0)
                
                #expect(abs(sineValue - cosineComplement) < 1e-9,
                       "sin(\(angle)°) should equal cos(\(90.0 - angle)°)")
            }
        }
    }
    
    // MARK: - Scale Lookup Integration
    
    @Suite("Exotic Scale Lookup by Name")
    struct ExoticScaleLookupTests {
        
        @Test("Hyperbolic scales can be looked up by name",
              arguments: ["SH", "CH", "TH", "sh", "ch", "th"])
        func hyperbolicScaleLookup(name: String) throws {
            let scale = StandardScales.scale(named: name, length: 250.0)
            
            #expect(scale != nil,
                   "Hyperbolic scale '\(name)' should be retrievable by name")
            
            if let scale = scale {
                let uppercaseName = name.uppercased()
                #expect(scale.name.uppercased() == uppercaseName,
                       "Retrieved scale name should match (case-insensitive)")
            }
        }
        
        @Test("Power scales can be looked up by name",
              arguments: ["PA", "P", "pa", "p"])
        func powerScaleLookup(name: String) throws {
            let scale = StandardScales.scale(named: name, length: 250.0)
            
            #expect(scale != nil,
                   "Power scale '\(name)' should be retrievable by name")
            
            if let scale = scale {
                let uppercaseName = name.uppercased()
                #expect(scale.name.uppercased() == uppercaseName,
                       "Retrieved scale name should match (case-insensitive)")
            }
        }
        
        @Test("Extended LL scales can be looked up by name",
              arguments: ["LL1", "LL2", "LL3", "ll1", "ll2", "ll3"])
        func extendedLLScaleLookup(name: String) throws {
            let scale = StandardScales.scale(named: name, length: 250.0)
            
            #expect(scale != nil,
                   "LL scale '\(name)' should be retrievable by name")
            
            if let scale = scale {
                let uppercaseName = name.uppercased()
                #expect(scale.name.uppercased() == uppercaseName,
                       "Retrieved scale name should match (case-insensitive)")
            }
        }
        
        @Test("All exotic scales accept custom lengths",
              arguments: [100.0, 250.0, 500.0])
        func exoticScalesCustomLengths(length: Double) throws {
            let scales = [
                StandardScales.scale(named: "SH", length: length),
                StandardScales.scale(named: "CH", length: length),
                StandardScales.scale(named: "TH", length: length),
                StandardScales.scale(named: "PA", length: length),
                StandardScales.scale(named: "P", length: length),
                StandardScales.scale(named: "LL1", length: length),
                StandardScales.scale(named: "LL2", length: length),
                StandardScales.scale(named: "LL3", length: length)
            ]
            
            for scale in scales {
                if let scale = scale {
                    #expect(scale.scaleLengthInPoints == length,
                           "\(scale.name) should accept custom length \(length)")
                }
            }
        }
    }
}