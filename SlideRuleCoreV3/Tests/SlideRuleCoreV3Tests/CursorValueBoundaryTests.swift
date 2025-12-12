import Testing
@testable import SlideRuleCoreV3

/// Boundary value precision tests for cursor value calculations.
///
/// These tests verify that exact boundary values (start and end of scales)
/// are computed correctly. Boundary conditions are critical for ensuring
/// scales render accurately and cursor readings are reliable at extremes.
///
/// # Boundary Conditions Tested
/// - Position 0.0 → scale.beginValue
/// - Position 1.0 → scale.endValue
/// - Subsection boundaries within scales
struct CursorValueBoundaryTests {
    
    // MARK: - Scale Test Data
    
    /// Scale configurations for parametric boundary testing
    private static let scaleConfigurations: [(name: String, scale: ScaleDefinition, tolerance: Double)] = [
        // Standard Logarithmic Scales
        ("C", CommonScales.c(), TestTolerance.standard),
        ("D", CommonScales.d(), TestTolerance.standard),
        
        // Inverted Scales
        ("CI", CommonScales.ci(), TestTolerance.standard),
        ("DI", CommonScales.di(), TestTolerance.standard),
        
        // Square Scales
        ("A", CommonScales.a(), TestTolerance.standard),
        ("B", CommonScales.b(), TestTolerance.standard),
        
        // Cube Scale (uses transcendental tolerance)
        ("K", CommonScales.k(), TestTolerance.relaxed),
        
        // Folded Scales
        ("CF", CommonScales.cf(), TestTolerance.standard),
        ("DF", CommonScales.df(), TestTolerance.standard),
        ("CIF", CommonScales.cif(), TestTolerance.standard),
        ("DIF", CommonScales.dif(), TestTolerance.standard),
        
        // Linear Scale
        ("L", CommonScales.l(), TestTolerance.standard),
        
        // Trigonometric Scales
        ("S", CommonScales.s(), TestTolerance.relaxed),
        ("T", CommonScales.t(), TestTolerance.relaxed),
        ("ST", CommonScales.st(), TestTolerance.relaxed),
        
        // Square Root Scales
        ("R1", StandardScales.r1Scale(), TestTolerance.standard),
        ("R2", StandardScales.r2Scale(), TestTolerance.standard),
        
        // Cube Root Scales
        ("Q1", StandardScales.q1Scale(), TestTolerance.relaxed),
        ("Q2", StandardScales.q2Scale(), TestTolerance.relaxed),
        ("Q3", StandardScales.q3Scale(), TestTolerance.relaxed),
        
        // Log-Log Scales (use veryRelaxed due to nested transcendental)
        ("LL0", StandardScales.ll0Scale(), TestTolerance.veryRelaxed),
        ("LL1", StandardScales.ll1Scale(), TestTolerance.veryRelaxed),
        ("LL2", StandardScales.ll2Scale(), TestTolerance.veryRelaxed),
        ("LL3", StandardScales.ll3Scale(), TestTolerance.veryRelaxed),
    ]
    
    // MARK: - Parametric Boundary Tests
    
    @Test("All scales: position 0.0 yields beginValue",
          arguments: scaleConfigurations)
    func scaleBoundaryStart(name: String, scale: ScaleDefinition, tolerance: Double) {
        let value = ScaleCalculator.value(at: 0.0, on: scale)
        let error = abs(value - scale.beginValue)
        #expect(
            error < tolerance,
            "\(name) scale at position 0.0 should yield beginValue (\(scale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("All scales: position 1.0 yields endValue",
          arguments: scaleConfigurations)
    func scaleBoundaryEnd(name: String, scale: ScaleDefinition, tolerance: Double) {
        let value = ScaleCalculator.value(at: 1.0, on: scale)
        let error = abs(value - scale.endValue)
        #expect(
            error < tolerance,
            "\(name) scale at position 1.0 should yield endValue (\(scale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - Comprehensive Boundary Tests Using Utilities
    
    @Test("All scales: complete boundary validation using BoundaryTester",
          arguments: scaleConfigurations)
    func scaleCompleteBoundaries(name: String, scale: ScaleDefinition, tolerance: Double) {
        // Test that beginValue maps to position ~0 and endValue maps to position ~1
        BoundaryTester.expectCorrectBoundaries(scale, tolerance: tolerance)
        
        // Test that position 0 yields beginValue and position 1 yields endValue
        BoundaryTester.expectCorrectBoundaryValues(scale, tolerance: tolerance)
    }
}
