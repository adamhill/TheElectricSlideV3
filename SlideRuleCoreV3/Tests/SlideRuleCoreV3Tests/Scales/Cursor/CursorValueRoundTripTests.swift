import Testing
@testable import SlideRuleCoreV3

/// Round-trip precision tests for cursor value calculations.
///
/// These tests verify that `position → value → position` returns the original
/// position within acceptable tolerance. This validates the mathematical
/// consistency of forward and inverse transformations in `ScaleCalculator`.
///
/// # Implementation Reference
/// - Forward: `ScaleCalculator.value(at:on:)` at line ~174
/// - Inverse: `ScaleCalculator.normalizedPosition(for:on:)` at line ~116
struct CursorValueRoundTripTests {
    
    // MARK: - Scale Test Data
    
    /// Scale configurations for parametric round-trip testing
    private static let scaleConfigurations: [(name: String, scale: ScaleDefinition, tolerance: Double)] = [
        // Standard Logarithmic Scales
        ("C", CommonScales.c(), CursorValuePrecision.roundTripPositionTolerance),
        ("D", CommonScales.d(), CursorValuePrecision.roundTripPositionTolerance),
        
        // Inverted Scales
        ("CI", CommonScales.ci(), CursorValuePrecision.roundTripPositionTolerance),
        ("DI", CommonScales.di(), CursorValuePrecision.roundTripPositionTolerance),
        
        // Square Scales
        ("A", CommonScales.a(), CursorValuePrecision.roundTripPositionTolerance),
        ("B", CommonScales.b(), CursorValuePrecision.roundTripPositionTolerance),
        
        // Cube Scale (uses transcendental tolerance due to 1/3 power)
        ("K", CommonScales.k(), CursorValuePrecision.transcendentalTolerance),
        
        // Folded Scales
        ("CF", CommonScales.cf(), CursorValuePrecision.roundTripPositionTolerance),
        ("DF", CommonScales.df(), CursorValuePrecision.roundTripPositionTolerance),
        ("CIF", CommonScales.cif(), CursorValuePrecision.roundTripPositionTolerance),
        ("DIF", CommonScales.dif(), CursorValuePrecision.roundTripPositionTolerance),
        
        // Linear Scale
        ("L", CommonScales.l(), CursorValuePrecision.roundTripPositionTolerance),
        
        // Trigonometric Scales (use transcendental tolerance)
        ("S", CommonScales.s(), CursorValuePrecision.transcendentalTolerance),
        ("T", CommonScales.t(), CursorValuePrecision.transcendentalTolerance),
        ("ST", CommonScales.st(), CursorValuePrecision.transcendentalTolerance),
        
        // Square Root Scales
        ("R1", StandardScales.r1Scale(), CursorValuePrecision.roundTripPositionTolerance),
        ("R2", StandardScales.r2Scale(), CursorValuePrecision.roundTripPositionTolerance),
        
        // Cube Root Scales (use transcendental tolerance)
        ("Q1", StandardScales.q1Scale(), CursorValuePrecision.transcendentalTolerance),
        ("Q2", StandardScales.q2Scale(), CursorValuePrecision.transcendentalTolerance),
        ("Q3", StandardScales.q3Scale(), CursorValuePrecision.transcendentalTolerance),
        
        // Log-Log Scales (use nested transcendental tolerance)
        ("LL0", StandardScales.ll0Scale(), CursorValuePrecision.nestedTranscendentalTolerance),
        ("LL1", StandardScales.ll1Scale(), CursorValuePrecision.nestedTranscendentalTolerance),
        ("LL2", StandardScales.ll2Scale(), CursorValuePrecision.nestedTranscendentalTolerance),
        ("LL3", StandardScales.ll3Scale(), CursorValuePrecision.nestedTranscendentalTolerance),
    ]
    
    // MARK: - Parametric Round-Trip Tests
    
    @Test("All scales: position → value → position round-trip",
          arguments: scaleConfigurations)
    func scaleRoundTrip(name: String, scale: ScaleDefinition, tolerance: Double) {
        RoundTripTester.testPositionRoundTrips(
            positions: CursorValuePrecision.standardTestPositions,
            on: scale,
            tolerance: tolerance
        )
    }
    
    // MARK: - Specific Position Tests for Mathematical Significance
    
    @Test("C scale round-trip at log10(2) position yields 2.0")
    func cScaleLog10_2RoundTrip() {
        let cScale = CommonScales.c()
        let position = CursorValuePrecision.KnownValues.log10_2
        
        // Forward: position → value
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        // Verify value is 2.0 within tolerance
        #expect(
            abs(value - 2.0) < CursorValuePrecision.standardTolerance,
            "Value at log10(2) should be 2.0, got \(value)"
        )
        
        // Inverse: value → position
        let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: cScale)
        
        // Verify round-trip
        #expect(
            abs(computedPosition - position) < CursorValuePrecision.roundTripPositionTolerance,
            "Round-trip position error: \(abs(computedPosition - position))"
        )
    }
    
    @Test("C scale round-trip at log10(π) position yields π")
    func cScaleLog10PiRoundTrip() {
        let cScale = CommonScales.c()
        let position = CursorValuePrecision.KnownValues.log10_pi
        
        // Forward: position → value
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        // Verify value is π within tolerance
        #expect(
            abs(value - Double.pi) < CursorValuePrecision.standardTolerance,
            "Value at log10(π) should be π, got \(value)"
        )
        
        // Inverse: value → position
        let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: cScale)
        
        // Verify round-trip
        #expect(
            abs(computedPosition - position) < CursorValuePrecision.roundTripPositionTolerance,
            "Round-trip position error: \(abs(computedPosition - position))"
        )
    }
    
    @Test("C scale round-trip at log10(e) position yields e")
    func cScaleLog10ERoundTrip() {
        let cScale = CommonScales.c()
        let position = CursorValuePrecision.KnownValues.log10_e
        
        // Forward: position → value
        let value = ScaleCalculator.value(at: position, on: cScale)
        
        // Verify value is e within tolerance
        #expect(
            abs(value - CursorValuePrecision.KnownValues.e) < CursorValuePrecision.standardTolerance,
            "Value at log10(e) should be e, got \(value)"
        )
        
        // Inverse: value → position  
        let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: cScale)
        
        // Verify round-trip
        #expect(
            abs(computedPosition - position) < CursorValuePrecision.roundTripPositionTolerance,
            "Round-trip position error: \(abs(computedPosition - position))"
        )
    }
}
