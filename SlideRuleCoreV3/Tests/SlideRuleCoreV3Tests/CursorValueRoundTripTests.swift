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
    
    // MARK: - Standard Logarithmic Scales (C, D)
    
    @Test("C scale round-trip: position → value → position")
    func cScaleRoundTrip() {
        let cScale = StandardScales.cScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: cScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: cScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "C scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("D scale round-trip: position → value → position")
    func dScaleRoundTrip() {
        let dScale = StandardScales.dScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: dScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: dScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "D scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Inverted Scales (CI, DI)
    
    @Test("CI scale round-trip: position → value → position")
    func ciScaleRoundTrip() {
        let ciScale = StandardScales.ciScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: ciScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: ciScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "CI scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("DI scale round-trip: position → value → position")
    func diScaleRoundTrip() {
        let diScale = StandardScales.diScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: diScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: diScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "DI scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Square Scales (A, B)
    
    @Test("A scale round-trip: position → value → position")
    func aScaleRoundTrip() {
        let aScale = StandardScales.aScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: aScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: aScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "A scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("B scale round-trip: position → value → position")
    func bScaleRoundTrip() {
        let bScale = StandardScales.bScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: bScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: bScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "B scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Cube Scale (K)
    
    @Test("K scale round-trip: position → value → position")
    func kScaleRoundTrip() {
        let kScale = StandardScales.kScale()
        let tolerance = CursorValuePrecision.transcendentalTolerance  // K uses 1/3 power
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: kScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: kScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "K scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Folded Scales (CF, DF, CIF, DIF)
    
    @Test("CF scale round-trip: position → value → position")
    func cfScaleRoundTrip() {
        let cfScale = StandardScales.cfScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: cfScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: cfScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "CF scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("DF scale round-trip: position → value → position")
    func dfScaleRoundTrip() {
        let dfScale = StandardScales.dfScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: dfScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: dfScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "DF scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("CIF scale round-trip: position → value → position")
    func cifScaleRoundTrip() {
        let cifScale = StandardScales.cifScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: cifScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: cifScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "CIF scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    @Test("DIF scale round-trip: position → value → position")
    @Test("DIF scale round-trip: position → value → position")
    func difScaleRoundTrip() {
        let difScale = StandardScales.difScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: difScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: difScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "DIF scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    
    // MARK: - Linear Scale (L)
    
    @Test("L scale round-trip: position → value → position")
    func lScaleRoundTrip() {
        let lScale = StandardScales.lScale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: lScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: lScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "L scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Trigonometric Scales (S, T, ST)
    
    @Test("S scale round-trip: position → value → position")
    func sScaleRoundTrip() {
        let sScale = StandardScales.sScale()
        let tolerance = CursorValuePrecision.transcendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: sScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: sScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "S scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("T scale round-trip: position → value → position")
    func tScaleRoundTrip() {
        let tScale = StandardScales.tScale()
        let tolerance = CursorValuePrecision.transcendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: tScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: tScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "T scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("ST scale round-trip: position → value → position")
    func stScaleRoundTrip() {
        let stScale = StandardScales.stScale()
        let tolerance = CursorValuePrecision.transcendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: stScale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: stScale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "ST scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Square Root Scales (R1, R2)
    
    @Test("R1 (Sq1) scale round-trip: position → value → position")
    func r1ScaleRoundTrip() {
        let r1Scale = StandardScales.r1Scale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: r1Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: r1Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "R1 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("R2 (Sq2) scale round-trip: position → value → position")
    func r2ScaleRoundTrip() {
        let r2Scale = StandardScales.r2Scale()
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: r2Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: r2Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < CursorValuePrecision.roundTripPositionTolerance,
                "R2 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Cube Root Scales (Q1, Q2, Q3)
    
    @Test("Q1 scale round-trip: position → value → position")
    func q1ScaleRoundTrip() {
        let q1Scale = StandardScales.q1Scale()
        let tolerance = CursorValuePrecision.transcendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: q1Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: q1Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "Q1 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("Q2 scale round-trip: position → value → position")
    func q2ScaleRoundTrip() {
        let q2Scale = StandardScales.q2Scale()
        let tolerance = CursorValuePrecision.transcendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: q2Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: q2Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "Q2 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("Q3 scale round-trip: position → value → position")
    func q3ScaleRoundTrip() {
        let q3Scale = StandardScales.q3Scale()
        let tolerance = CursorValuePrecision.transcendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: q3Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: q3Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "Q3 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Log-Log Scales (LL0, LL1, LL2, LL3)
    
    @Test("LL0 scale round-trip: position → value → position")
    func ll0ScaleRoundTrip() {
        let ll0Scale = StandardScales.ll0Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: ll0Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: ll0Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "LL0 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("LL1 scale round-trip: position → value → position")
    func ll1ScaleRoundTrip() {
        let ll1Scale = StandardScales.ll1Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: ll1Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: ll1Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "LL1 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("LL2 scale round-trip: position → value → position")
    func ll2ScaleRoundTrip() {
        let ll2Scale = StandardScales.ll2Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: ll2Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: ll2Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "LL2 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    @Test("LL3 scale round-trip: position → value → position")
    func ll3ScaleRoundTrip() {
        let ll3Scale = StandardScales.ll3Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        for position in CursorValuePrecision.standardTestPositions {
            let value = ScaleCalculator.value(at: position, on: ll3Scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: ll3Scale)
            
            let error = abs(computedPosition - position)
            #expect(
                error < tolerance,
                "LL3 scale round-trip failed at position \(position): error = \(error)"
            )
        }
    }
    
    // MARK: - Specific Position Tests for Mathematical Significance
    
    @Test("C scale round-trip at log10(2) position yields 2.0")
    func cScaleLog10_2RoundTrip() {
        let cScale = StandardScales.cScale()
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
        let cScale = StandardScales.cScale()
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
        let cScale = StandardScales.cScale()
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