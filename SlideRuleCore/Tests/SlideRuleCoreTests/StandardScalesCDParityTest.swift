import Testing
import Foundation
@testable import SlideRuleCore

@Suite("C/D scales — parity and reciprocal variant", .tags(.fast, .regression, .cScale, .dScale))
struct StandardScalesCDTests {
    
    // MARK: - C/D Parity
    
    @Suite("C/D parity — same mapping, different tick direction")
    struct CDParity {
        // Exercises: ScaleCalculator.normalizedPosition(for:on:) parity for C vs D
        
        @Test("D vs C — identical normalized positions across representative values",
              arguments: zip(
                [1.0, 2.0, 3.14159, 4.0, 5.0, 7.5, 10.0],
                [1.0, 2.0, 3.14159, 4.0, 5.0, 7.5, 10.0]
              ))
        func dEqualsC(valueC: Double, valueD: Double) {
            let c = StandardScales.cScale(length: 250.0)
            let d = StandardScales.dScale(length: 250.0)
            
            let posC = ScaleCalculator.normalizedPosition(for: valueC, on: c)
            let posD = ScaleCalculator.normalizedPosition(for: valueD, on: d)
            
            #expect(abs(posC - posD) < 1e-9,
                    "C and D should map identical values to identical normalized positions")
        }
        
        @Test("Round-trip — position→value→position remains consistent on D scale",
              arguments: [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0])
        func roundTripOnD(value: Double) {
            let d = StandardScales.dScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: d)
            let recovered = ScaleCalculator.value(at: pos, on: d)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: d)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
        
        @Test("Tick counts — C and D generate the same tick distribution")
        func cAndDTickCountsMatch() {
            let c = StandardScales.cScale(length: 250.0)
            let d = StandardScales.dScale(length: 250.0)
            let genC = GeneratedScale(definition: c)
            let genD = GeneratedScale(definition: d)
            
            #expect(genC.tickMarks.count == genD.tickMarks.count,
                    "C and D should have identical tick counts")
            #expect(!genC.tickMarks.isEmpty && !genD.tickMarks.isEmpty,
                    "Generated ticks should be non-empty for C/D")
        }
    }
    
    // MARK: - CI Scale Tests
    
    @Suite("CI scale — reciprocal logarithmic behavior", .tags(.ciScale))
    struct CIScaleTests {
        // Exercises: ScaleCalculator operations on CI (reciprocal) scale
        
        @Test("CI scale — non-empty tick generation")
        func ciGeneratesTicks() {
            let ci = StandardScales.ciScale(length: 250.0)
            let genCI = GeneratedScale(definition: ci)
            
            #expect(!genCI.tickMarks.isEmpty,
                    "CI should generate non-empty ticks")
        }
        
        @Test("Round-trip — position→value→position remains consistent on CI scale",
              arguments: [1.0, 2.0, 4.0, 5.0, 7.5, 10.0])
        func roundTripOnCI(value: Double) {
            let ci = StandardScales.ciScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: ci)
            let recovered = ScaleCalculator.value(at: pos, on: ci)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: ci)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
        
        @Test("CI reciprocal relationship — values decrease as position increases")
        func ciReciprocalBehavior() {
            let ci = StandardScales.ciScale(length: 250.0)
            
            // CI range is 10 to 1 (descending), so smaller positions should have larger values
            let pos1 = 0.0
            let pos2 = 0.5
            let pos3 = 1.0
            
            let value1 = ScaleCalculator.value(at: pos1, on: ci)
            let value2 = ScaleCalculator.value(at: pos2, on: ci)
            let value3 = ScaleCalculator.value(at: pos3, on: ci)
            
            #expect(value1 > value2, "CI values should decrease as position increases")
            #expect(value2 > value3, "CI values should decrease as position increases")
        }
    }
    
    // MARK: - CI/DI Parity
    
    @Suite("CI/DI parity — reciprocal twins with mirrored tick direction", .tags(.diScale))
    struct CIDIParity {
        // Exercises: ScaleCalculator.normalizedPosition(for:on:) parity for CI vs DI
        
        @Test("DI vs CI — reciprocal twins maintain non-empty ticks and parity",
              arguments: zip(
                [1.0, 2.0, 4.0, 5.0, 7.5, 10.0],
                [1.0, 2.0, 4.0, 5.0, 7.5, 10.0]
              ))
        func diEqualsCI(value1: Double, value2: Double) {
            let ci = StandardScales.ciScale(length: 250.0)
            let di = StandardScales.diScale(length: 250.0)
            
            let genCI = GeneratedScale(definition: ci)
            let genDI = GeneratedScale(definition: di)
            
            #expect(!genCI.tickMarks.isEmpty && !genDI.tickMarks.isEmpty,
                    "CI and DI should generate non-empty ticks")
            #expect(genCI.tickMarks.count == genDI.tickMarks.count,
                    "CI and DI should produce equal tick counts")
            
            let posCI = ScaleCalculator.normalizedPosition(for: value1, on: ci)
            let posDI = ScaleCalculator.normalizedPosition(for: value2, on: di)
            #expect(abs(posCI - posDI) < 1e-9,
                    "CI and DI should map identical values to identical positions")
        }
        
        @Test("Round-trip — position→value→position remains consistent on DI scale",
              arguments: [1.0, 2.0, 4.0, 5.0, 7.5, 10.0])
        func roundTripOnDI(value: Double) {
            let di = StandardScales.diScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: di)
            let recovered = ScaleCalculator.value(at: pos, on: di)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: di)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
        
        @Test("Tick counts — CI and DI generate the same tick distribution")
        func ciAndDITickCountsMatch() {
            let ci = StandardScales.ciScale(length: 250.0)
            let di = StandardScales.diScale(length: 250.0)
            let genCI = GeneratedScale(definition: ci)
            let genDI = GeneratedScale(definition: di)
            
            #expect(genCI.tickMarks.count == genDI.tickMarks.count,
                    "CI and DI should have identical tick counts")
            #expect(!genCI.tickMarks.isEmpty && !genDI.tickMarks.isEmpty,
                    "Generated ticks should be non-empty for CI/DI")
        }
    }
}