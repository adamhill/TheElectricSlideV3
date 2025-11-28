import Foundation
import Testing
@testable import SlideRuleCoreV3

/// Known-value precision tests for cursor value calculations.
///
/// These tests verify that specific mathematical values are computed correctly
/// at their corresponding positions. This validates the accuracy of the
/// transformation functions, not just their consistency.
///
/// # Mathematical Foundation
/// For a C/D scale (logarithmic, range 1-10):
/// - Position 0 → value 1
/// - Position log₁₀(2) → value 2
/// - Position log₁₀(π) → value π
/// - Position log₁₀(e) → value e
/// - Position 1 → value 10
struct CursorValueKnownValueTests {
    
    // MARK: - C Scale Known Values
    
    @Test("C scale: position log10(2) yields exactly 2.0")
    func cScaleValue2() {
        let cScale = StandardScales.cScale()
        let position = CursorValuePrecision.KnownValues.log10_2
        
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        let error = abs(value - 2.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at log10(2) should yield 2.0: got \(value), error = \(error)"
        )
    }
    
    @Test("C scale: position log10(π) yields exactly π")
    func cScaleValuePi() {
        let cScale = StandardScales.cScale()
        let position = CursorValuePrecision.KnownValues.log10_pi
        
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        let error = abs(value - Double.pi)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at log10(π) should yield π: got \(value), error = \(error)"
        )
    }
    
    @Test("C scale: position log10(e) yields exactly e")
    func cScaleValueE() {
        let cScale = StandardScales.cScale()
        let position = CursorValuePrecision.KnownValues.log10_e
        
        let value = ScaleCalculator.value(at: position, on: cScale)
        let expectedE = CursorValuePrecision.KnownValues.e
        
        let error = abs(value - expectedE)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at log10(e) should yield e: got \(value), error = \(error)"
        )
    }
    
    @Test("C scale: position log10(√2) yields exactly √2")
    func cScaleValueSqrt2() {
        let cScale = StandardScales.cScale()
        let position = CursorValuePrecision.KnownValues.log10_sqrt2
        let expectedSqrt2 = CursorValuePrecision.KnownValues.sqrt2
        
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        let error = abs(value - expectedSqrt2)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at log10(√2) should yield √2: got \(value), error = \(error)"
        )
    }
    
    @Test("C scale: position log10(3) yields exactly 3")
    func cScaleValue3() {
        let cScale = StandardScales.cScale()
        let position = CursorValuePrecision.KnownValues.log10_3
        
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        let error = abs(value - 3.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at log10(3) should yield 3.0: got \(value), error = \(error)"
        )
    }
    
    @Test("C scale: position log10(5) yields exactly 5")
    func cScaleValue5() {
        let cScale = StandardScales.cScale()
        let position = CursorValuePrecision.KnownValues.log10_5
        
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        let error = abs(value - 5.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at log10(5) should yield 5.0: got \(value), error = \(error)"
        )
    }
    
    @Test("C scale: position log10(7) yields exactly 7")
    func cScaleValue7() {
        let cScale = StandardScales.cScale()
        let position = CursorValuePrecision.KnownValues.log10_7
        
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        let error = abs(value - 7.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at log10(7) should yield 7.0: got \(value), error = \(error)"
        )
    }
    
    // MARK: - D Scale Known Values (Same as C)
    
    @Test("D scale: position log10(2) yields exactly 2.0")
    func dScaleValue2() {
        let dScale = StandardScales.dScale()
        let position = CursorValuePrecision.KnownValues.log10_2
        
        let value = ScaleCalculator.value(at: position, on: dScale)
        
        let error = abs(value - 2.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "D scale at log10(2) should yield 2.0: got \(value), error = \(error)"
        )
    }
    
    @Test("D scale: position log10(π) yields exactly π")
    func dScaleValuePi() {
        let dScale = StandardScales.dScale()
        let position = CursorValuePrecision.KnownValues.log10_pi
        
        let value = ScaleCalculator.value(at: position, on: dScale)
        
        let error = abs(value - Double.pi)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "D scale at log10(π) should yield π: got \(value), error = \(error)"
        )
    }
    
    // MARK: - A Scale Known Values (Square Scale)
    
    @Test("A scale: position 0.5 yields value 10 (sqrt(100))")
    func aScaleMidpoint() {
        let aScale = StandardScales.aScale()
        // A scale: log10(x)/2, so position 0.5 → x = 10^(2*0.5) = 10
        
        let value = ScaleCalculator.value(at: 0.5, on: aScale)
        
        let error = abs(value - 10.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "A scale at position 0.5 should yield 10.0: got \(value), error = \(error)"
        )
    }
    
    @Test("A scale: position log10(4)/2 yields value 4")
    func aScaleValue4() {
        let aScale = StandardScales.aScale()
        // A scale: log10(x)/2, so for x=4, position = log10(4)/2 ≈ 0.301
        let expectedPosition = log10(4.0) / 2.0
        
        let value = ScaleCalculator.value(at: expectedPosition, on: aScale)
        
        let error = abs(value - 4.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "A scale at log10(4)/2 should yield 4.0: got \(value), error = \(error)"
        )
    }
    
    @Test("A scale: position log10(25)/2 yields value 25")
    func aScaleValue25() {
        let aScale = StandardScales.aScale()
        let expectedPosition = log10(25.0) / 2.0
        
        let value = ScaleCalculator.value(at: expectedPosition, on: aScale)
        
        let error = abs(value - 25.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "A scale at log10(25)/2 should yield 25.0: got \(value), error = \(error)"
        )
    }
    
    // MARK: - K Scale Known Values (Cube Scale)
    
    @Test("K scale: position 1/3 yields value 10 (cube root of 1000)")
    func kScaleOneThird() {
        let kScale = StandardScales.kScale()
        // K scale: log10(x)/3, so position 1/3 → x = 10^(3*(1/3)) = 10
        
        let value = ScaleCalculator.value(at: 1.0/3.0, on: kScale)
        
        let error = abs(value - 10.0)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "K scale at position 1/3 should yield 10.0: got \(value), error = \(error)"
        )
    }
    
    @Test("K scale: position 2/3 yields value 100")
    func kScaleTwoThirds() {
        let kScale = StandardScales.kScale()
        // K scale: log10(x)/3, so position 2/3 → x = 10^(3*(2/3)) = 100
        
        let value = ScaleCalculator.value(at: 2.0/3.0, on: kScale)
        
        let error = abs(value - 100.0)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "K scale at position 2/3 should yield 100.0: got \(value), error = \(error)"
        )
    }
    
    @Test("K scale: position log10(8)/3 yields value 8")
    func kScaleValue8() {
        let kScale = StandardScales.kScale()
        // For x=8: position = log10(8)/3
        let expectedPosition = log10(8.0) / 3.0
        
        let value = ScaleCalculator.value(at: expectedPosition, on: kScale)
        
        let error = abs(value - 8.0)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "K scale at log10(8)/3 should yield 8.0: got \(value), error = \(error)"
        )
    }
    
    // MARK: - L Scale Known Values (Linear)
    
    @Test("L scale: position 0.5 yields exactly 0.5")
    func lScaleMidpoint() {
        let lScale = StandardScales.lScale()
        
        let value = ScaleCalculator.value(at: 0.5, on: lScale)
        
        let error = abs(value - 0.5)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "L scale at position 0.5 should yield 0.5: got \(value), error = \(error)"
        )
    }
    
    @Test("L scale: position 0.30103 yields exactly 0.30103 (log10(2))")
    func lScaleLog10Of2() {
        let lScale = StandardScales.lScale()
        let position = CursorValuePrecision.KnownValues.log10_2
        
        let value = ScaleCalculator.value(at: position, on: lScale)
        
        let error = abs(value - position)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "L scale at position log10(2) should yield log10(2): got \(value), error = \(error)"
        )
    }
    
    // MARK: - CI Scale Known Values (Reciprocal)
    
    @Test("CI scale: position log10(5) yields value 2 (10/5)")
    func ciScaleValue2() {
        let ciScale = StandardScales.ciScale()
        // CI scale: -log10(x), range 10→1
        // At position p, value = 10^(-p) * 10 = 10^(1-p)
        // But we need to account for the actual range transformation
        // For value 2, which is at 10/5: position = 1 - log10(2)
        let position = 1.0 - CursorValuePrecision.KnownValues.log10_2
        
        let value = ScaleCalculator.value(at: position, on: ciScale)
        
        // The CI scale shows reciprocals, so at this position we should get 2
        // CI is inverted: position 0 → 10, position 1 → 1
        let error = abs(value - 2.0)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "CI scale at position (1-log10(2)) should yield 2.0: got \(value), error = \(error)"
        )
    }
    
    // MARK: - S Scale Known Values (Sine)
    
    @Test("S scale: sin(30°) = 0.5 verifiable")
    func sScaleValue30Degrees() {
        let sScale = StandardScales.sScale()
        // For S scale: transform = log10(sin(x°) * 10)
        // At 30°: sin(30°) = 0.5, so transform = log10(0.5 * 10) = log10(5) ≈ 0.699
        
        // Calculate expected position for 30°
        let expectedTransform = log10(sin(30.0 * .pi / 180.0) * 10.0)
        let fL = log10(sin(5.7 * .pi / 180.0) * 10.0)  // begin value transform
        let fR = log10(sin(90.0 * .pi / 180.0) * 10.0) // end value transform
        let expectedPosition = (expectedTransform - fL) / (fR - fL)
        
        let value = ScaleCalculator.value(at: expectedPosition, on: sScale)
        
        let error = abs(value - 30.0)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "S scale: position for sin(30°) should yield 30°: got \(value), error = \(error)"
        )
    }
    
    @Test("S scale: sin(90°) = 1.0 at end position")
    func sScaleValue90Degrees() {
        let sScale = StandardScales.sScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: sScale)
        
        let error = abs(value - 90.0)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "S scale at position 1.0 should yield 90°: got \(value), error = \(error)"
        )
    }
    
    // MARK: - T Scale Known Values (Tangent)
    
    @Test("T scale: tan(45°) = 1.0 at end position")
    func tScaleValue45Degrees() {
        let tScale = StandardScales.tScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: tScale)
        
        let error = abs(value - 45.0)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "T scale at position 1.0 should yield 45°: got \(value), error = \(error)"
        )
    }
    
    // MARK: - Inverse Position Lookup Tests
    
    @Test("C scale: value 2 maps to position log10(2)")
    func cScalePositionFor2() {
        let cScale = StandardScales.cScale()
        
        let position = ScaleCalculator.normalizedPosition(for: 2.0, on: cScale)
        let expectedPosition = CursorValuePrecision.KnownValues.log10_2
        
        let error = abs(position - expectedPosition)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "Position for value 2 should be log10(2): got \(position), error = \(error)"
        )
    }
    
    @Test("C scale: value π maps to position log10(π)")
    func cScalePositionForPi() {
        let cScale = StandardScales.cScale()
        
        let position = ScaleCalculator.normalizedPosition(for: Double.pi, on: cScale)
        let expectedPosition = CursorValuePrecision.KnownValues.log10_pi
        
        let error = abs(position - expectedPosition)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "Position for value π should be log10(π): got \(position), error = \(error)"
        )
    }
    
    @Test("C scale: value e maps to position log10(e)")
    func cScalePositionForE() {
        let cScale = StandardScales.cScale()
        let e = CursorValuePrecision.KnownValues.e
        
        let position = ScaleCalculator.normalizedPosition(for: e, on: cScale)
        let expectedPosition = CursorValuePrecision.KnownValues.log10_e
        
        let error = abs(position - expectedPosition)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "Position for value e should be log10(e): got \(position), error = \(error)"
        )
    }
    
    // MARK: - CF Scale Known Values (Folded at π)
    
    @Test("CF scale: position 0 yields π")
    func cfScaleAtStart() {
        let cfScale = StandardScales.cfScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: cfScale)
        
        let error = abs(value - Double.pi)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "CF scale at position 0 should yield π: got \(value), error = \(error)"
        )
    }
    
    @Test("CF scale: position 1 yields 10π")
    func cfScaleAtEnd() {
        let cfScale = StandardScales.cfScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: cfScale)
        let expected = 10.0 * Double.pi
        
        let error = abs(value - expected)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "CF scale at position 1 should yield 10π: got \(value), error = \(error)"
        )
    }
}