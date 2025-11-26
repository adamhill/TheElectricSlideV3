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
    
    // MARK: - C Scale Boundaries
    
    @Test("C scale: position 0.0 yields beginValue (1.0)")
    func cScaleStartBoundary() {
        let cScale = StandardScales.cScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: cScale)
        
        let error = abs(value - cScale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at position 0.0 should yield beginValue (\(cScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("C scale: position 1.0 yields endValue (10.0)")
    func cScaleEndBoundary() {
        let cScale = StandardScales.cScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: cScale)
        
        let error = abs(value - cScale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "C scale at position 1.0 should yield endValue (\(cScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - D Scale Boundaries
    
    @Test("D scale: position 0.0 yields beginValue (1.0)")
    func dScaleStartBoundary() {
        let dScale = StandardScales.dScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: dScale)
        
        let error = abs(value - dScale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "D scale at position 0.0 should yield beginValue (\(dScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("D scale: position 1.0 yields endValue (10.0)")
    func dScaleEndBoundary() {
        let dScale = StandardScales.dScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: dScale)
        
        let error = abs(value - dScale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "D scale at position 1.0 should yield endValue (\(dScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - CI Scale Boundaries (Inverted)
    
    @Test("CI scale: position 0.0 yields beginValue (10.0)")
    func ciScaleStartBoundary() {
        let ciScale = StandardScales.ciScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: ciScale)
        
        let error = abs(value - ciScale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "CI scale at position 0.0 should yield beginValue (\(ciScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("CI scale: position 1.0 yields endValue (1.0)")
    func ciScaleEndBoundary() {
        let ciScale = StandardScales.ciScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: ciScale)
        
        let error = abs(value - ciScale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "CI scale at position 1.0 should yield endValue (\(ciScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - A Scale Boundaries (Square Scale)
    
    @Test("A scale: position 0.0 yields beginValue (1.0)")
    func aScaleStartBoundary() {
        let aScale = StandardScales.aScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: aScale)
        
        let error = abs(value - aScale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "A scale at position 0.0 should yield beginValue (\(aScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("A scale: position 1.0 yields endValue (100.0)")
    func aScaleEndBoundary() {
        let aScale = StandardScales.aScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: aScale)
        
        let error = abs(value - aScale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "A scale at position 1.0 should yield endValue (\(aScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - B Scale Boundaries
    
    @Test("B scale: position 0.0 yields beginValue (1.0)")
    func bScaleStartBoundary() {
        let bScale = StandardScales.bScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: bScale)
        
        let error = abs(value - bScale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "B scale at position 0.0 should yield beginValue (\(bScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("B scale: position 1.0 yields endValue (100.0)")
    func bScaleEndBoundary() {
        let bScale = StandardScales.bScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: bScale)
        
        let error = abs(value - bScale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "B scale at position 1.0 should yield endValue (\(bScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - K Scale Boundaries (Cube Scale)
    
    @Test("K scale: position 0.0 yields beginValue (1.0)")
    func kScaleStartBoundary() {
        let kScale = StandardScales.kScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: kScale)
        
        let error = abs(value - kScale.beginValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "K scale at position 0.0 should yield beginValue (\(kScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("K scale: position 1.0 yields endValue (1000.0)")
    func kScaleEndBoundary() {
        let kScale = StandardScales.kScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: kScale)
        
        let error = abs(value - kScale.endValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "K scale at position 1.0 should yield endValue (\(kScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - L Scale Boundaries (Linear)
    
    @Test("L scale: position 0.0 yields beginValue (0.0)")
    func lScaleStartBoundary() {
        let lScale = StandardScales.lScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: lScale)
        
        let error = abs(value - lScale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "L scale at position 0.0 should yield beginValue (\(lScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("L scale: position 1.0 yields endValue (1.0)")
    func lScaleEndBoundary() {
        let lScale = StandardScales.lScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: lScale)
        
        let error = abs(value - lScale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "L scale at position 1.0 should yield endValue (\(lScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - CF Scale Boundaries (Folded at π)
    
    @Test("CF scale: position 0.0 yields beginValue (π)")
    func cfScaleStartBoundary() {
        let cfScale = StandardScales.cfScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: cfScale)
        
        let error = abs(value - cfScale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "CF scale at position 0.0 should yield beginValue (\(cfScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("CF scale: position 1.0 yields endValue (10π)")
    func cfScaleEndBoundary() {
        let cfScale = StandardScales.cfScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: cfScale)
        
        let error = abs(value - cfScale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "CF scale at position 1.0 should yield endValue (\(cfScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - S Scale Boundaries (Sine)
    
    @Test("S scale: position 0.0 yields beginValue (~5.7°)")
    func sScaleStartBoundary() {
        let sScale = StandardScales.sScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: sScale)
        
        let error = abs(value - sScale.beginValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "S scale at position 0.0 should yield beginValue (\(sScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("S scale: position 1.0 yields endValue (90°)")
    func sScaleEndBoundary() {
        let sScale = StandardScales.sScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: sScale)
        
        let error = abs(value - sScale.endValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "S scale at position 1.0 should yield endValue (\(sScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - T Scale Boundaries (Tangent)
    
    @Test("T scale: position 0.0 yields beginValue (~5.7°)")
    func tScaleStartBoundary() {
        let tScale = StandardScales.tScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: tScale)
        
        let error = abs(value - tScale.beginValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "T scale at position 0.0 should yield beginValue (\(tScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("T scale: position 1.0 yields endValue (45°)")
    func tScaleEndBoundary() {
        let tScale = StandardScales.tScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: tScale)
        
        let error = abs(value - tScale.endValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "T scale at position 1.0 should yield endValue (\(tScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - ST Scale Boundaries (Small Tangent)
    
    @Test("ST scale: position 0.0 yields beginValue (~0.57°)")
    func stScaleStartBoundary() {
        let stScale = StandardScales.stScale()
        
        let value = ScaleCalculator.value(at: 0.0, on: stScale)
        
        let error = abs(value - stScale.beginValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "ST scale at position 0.0 should yield beginValue (\(stScale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("ST scale: position 1.0 yields endValue (~5.7°)")
    func stScaleEndBoundary() {
        let stScale = StandardScales.stScale()
        
        let value = ScaleCalculator.value(at: 1.0, on: stScale)
        
        let error = abs(value - stScale.endValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "ST scale at position 1.0 should yield endValue (\(stScale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - R1/R2 Scale Boundaries (Square Root)
    
    @Test("R1 (Sq1) scale: position 0.0 yields beginValue (1.0)")
    func r1ScaleStartBoundary() {
        let r1Scale = StandardScales.r1Scale()
        
        let value = ScaleCalculator.value(at: 0.0, on: r1Scale)
        
        let error = abs(value - r1Scale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "R1 scale at position 0.0 should yield beginValue (\(r1Scale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("R1 (Sq1) scale: position 1.0 yields endValue (~3.16)")
    func r1ScaleEndBoundary() {
        let r1Scale = StandardScales.r1Scale()
        
        let value = ScaleCalculator.value(at: 1.0, on: r1Scale)
        
        let error = abs(value - r1Scale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "R1 scale at position 1.0 should yield endValue (\(r1Scale.endValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("R2 (Sq2) scale: position 0.0 yields beginValue (~3.1)")
    func r2ScaleStartBoundary() {
        let r2Scale = StandardScales.r2Scale()
        
        let value = ScaleCalculator.value(at: 0.0, on: r2Scale)
        
        let error = abs(value - r2Scale.beginValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "R2 scale at position 0.0 should yield beginValue (\(r2Scale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("R2 (Sq2) scale: position 1.0 yields endValue (10.0)")
    func r2ScaleEndBoundary() {
        let r2Scale = StandardScales.r2Scale()
        
        let value = ScaleCalculator.value(at: 1.0, on: r2Scale)
        
        let error = abs(value - r2Scale.endValue)
        #expect(
            error < CursorValuePrecision.standardTolerance,
            "R2 scale at position 1.0 should yield endValue (\(r2Scale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - Q1/Q2/Q3 Scale Boundaries (Cube Root)
    
    @Test("Q1 scale: position 0.0 yields beginValue (1.0)")
    func q1ScaleStartBoundary() {
        let q1Scale = StandardScales.q1Scale()
        
        let value = ScaleCalculator.value(at: 0.0, on: q1Scale)
        
        let error = abs(value - q1Scale.beginValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "Q1 scale at position 0.0 should yield beginValue (\(q1Scale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("Q1 scale: position 1.0 yields endValue (~2.16)")
    func q1ScaleEndBoundary() {
        let q1Scale = StandardScales.q1Scale()
        
        let value = ScaleCalculator.value(at: 1.0, on: q1Scale)
        
        let error = abs(value - q1Scale.endValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "Q1 scale at position 1.0 should yield endValue (\(q1Scale.endValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("Q2 scale: position 0.0 yields beginValue (~2.15)")
    func q2ScaleStartBoundary() {
        let q2Scale = StandardScales.q2Scale()
        
        let value = ScaleCalculator.value(at: 0.0, on: q2Scale)
        
        let error = abs(value - q2Scale.beginValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "Q2 scale at position 0.0 should yield beginValue (\(q2Scale.beginValue)): got \(value), error = \(error)"
        )
    }
    
    @Test("Q3 scale: position 1.0 yields endValue (10.0)")
    func q3ScaleEndBoundary() {
        let q3Scale = StandardScales.q3Scale()
        
        let value = ScaleCalculator.value(at: 1.0, on: q3Scale)
        
        let error = abs(value - q3Scale.endValue)
        #expect(
            error < CursorValuePrecision.transcendentalTolerance,
            "Q3 scale at position 1.0 should yield endValue (\(q3Scale.endValue)): got \(value), error = \(error)"
        )
    }
    
    // MARK: - LL Scale Boundaries (Log-Log)
    
    @Test("LL0 scale boundaries")
    func ll0ScaleBoundaries() {
        let ll0Scale = StandardScales.ll0Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        let valueAtStart = ScaleCalculator.value(at: 0.0, on: ll0Scale)
        let errorStart = abs(valueAtStart - ll0Scale.beginValue)
        #expect(
            errorStart < tolerance,
            "LL0 scale at position 0.0 should yield beginValue (\(ll0Scale.beginValue)): got \(valueAtStart), error = \(errorStart)"
        )
        
        let valueAtEnd = ScaleCalculator.value(at: 1.0, on: ll0Scale)
        let errorEnd = abs(valueAtEnd - ll0Scale.endValue)
        #expect(
            errorEnd < tolerance,
            "LL0 scale at position 1.0 should yield endValue (\(ll0Scale.endValue)): got \(valueAtEnd), error = \(errorEnd)"
        )
    }
    
    @Test("LL1 scale boundaries")
    func ll1ScaleBoundaries() {
        let ll1Scale = StandardScales.ll1Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        let valueAtStart = ScaleCalculator.value(at: 0.0, on: ll1Scale)
        let errorStart = abs(valueAtStart - ll1Scale.beginValue)
        #expect(
            errorStart < tolerance,
            "LL1 scale at position 0.0 should yield beginValue (\(ll1Scale.beginValue)): got \(valueAtStart), error = \(errorStart)"
        )
        
        let valueAtEnd = ScaleCalculator.value(at: 1.0, on: ll1Scale)
        let errorEnd = abs(valueAtEnd - ll1Scale.endValue)
        #expect(
            errorEnd < tolerance,
            "LL1 scale at position 1.0 should yield endValue (\(ll1Scale.endValue)): got \(valueAtEnd), error = \(errorEnd)"
        )
    }
    
    @Test("LL2 scale boundaries")
    func ll2ScaleBoundaries() {
        let ll2Scale = StandardScales.ll2Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        let valueAtStart = ScaleCalculator.value(at: 0.0, on: ll2Scale)
        let errorStart = abs(valueAtStart - ll2Scale.beginValue)
        #expect(
            errorStart < tolerance,
            "LL2 scale at position 0.0 should yield beginValue (\(ll2Scale.beginValue)): got \(valueAtStart), error = \(errorStart)"
        )
        
        let valueAtEnd = ScaleCalculator.value(at: 1.0, on: ll2Scale)
        let errorEnd = abs(valueAtEnd - ll2Scale.endValue)
        #expect(
            errorEnd < tolerance,
            "LL2 scale at position 1.0 should yield endValue (\(ll2Scale.endValue)): got \(valueAtEnd), error = \(errorEnd)"
        )
    }
    
    @Test("LL3 scale boundaries")
    func ll3ScaleBoundaries() {
        let ll3Scale = StandardScales.ll3Scale()
        let tolerance = CursorValuePrecision.nestedTranscendentalTolerance
        
        let valueAtStart = ScaleCalculator.value(at: 0.0, on: ll3Scale)
        let errorStart = abs(valueAtStart - ll3Scale.beginValue)
        #expect(
            errorStart < tolerance,
            "LL3 scale at position 0.0 should yield beginValue (\(ll3Scale.beginValue)): got \(valueAtStart), error = \(errorStart)"
        )
        
        let valueAtEnd = ScaleCalculator.value(at: 1.0, on: ll3Scale)
        let errorEnd = abs(valueAtEnd - ll3Scale.endValue)
        #expect(
            errorEnd < tolerance,
            "LL3 scale at position 1.0 should yield endValue (\(ll3Scale.endValue)): got \(valueAtEnd), error = \(errorEnd)"
        )
    }
    
    // MARK: - Generic Boundary Test Helper
    
    @Test("All standard scales have consistent boundaries")
    func allScalesBoundaryConsistency() {
        let scales: [(String, ScaleDefinition, Double)] = [
            ("C", StandardScales.cScale(), CursorValuePrecision.standardTolerance),
            ("D", StandardScales.dScale(), CursorValuePrecision.standardTolerance),
            ("CI", StandardScales.ciScale(), CursorValuePrecision.standardTolerance),
            ("DI", StandardScales.diScale(), CursorValuePrecision.standardTolerance),
            ("A", StandardScales.aScale(), CursorValuePrecision.standardTolerance),
            ("B", StandardScales.bScale(), CursorValuePrecision.standardTolerance),
            ("K", StandardScales.kScale(), CursorValuePrecision.transcendentalTolerance),
            ("L", StandardScales.lScale(), CursorValuePrecision.standardTolerance),
            ("CF", StandardScales.cfScale(), CursorValuePrecision.standardTolerance),
            ("DF", StandardScales.dfScale(), CursorValuePrecision.standardTolerance),
            ("CIF", StandardScales.cifScale(), CursorValuePrecision.standardTolerance),
            ("S", StandardScales.sScale(), CursorValuePrecision.transcendentalTolerance),
            ("T", StandardScales.tScale(), CursorValuePrecision.transcendentalTolerance),
            ("ST", StandardScales.stScale(), CursorValuePrecision.transcendentalTolerance),
            ("R1", StandardScales.r1Scale(), CursorValuePrecision.standardTolerance),
            ("R2", StandardScales.r2Scale(), CursorValuePrecision.standardTolerance),
            ("Q1", StandardScales.q1Scale(), CursorValuePrecision.transcendentalTolerance),
            ("Q2", StandardScales.q2Scale(), CursorValuePrecision.transcendentalTolerance),
            ("Q3", StandardScales.q3Scale(), CursorValuePrecision.transcendentalTolerance),
        ]
        
        for (name, scale, tolerance) in scales {
            let valueAtStart = ScaleCalculator.value(at: 0.0, on: scale)
            let valueAtEnd = ScaleCalculator.value(at: 1.0, on: scale)
            
            let errorStart = abs(valueAtStart - scale.beginValue)
            let errorEnd = abs(valueAtEnd - scale.endValue)
            
            #expect(
                errorStart < tolerance,
                "\(name) scale boundary error at start: \(errorStart)"
            )
            #expect(
                errorEnd < tolerance,
                "\(name) scale boundary error at end: \(errorEnd)"
            )
        }
    }
}