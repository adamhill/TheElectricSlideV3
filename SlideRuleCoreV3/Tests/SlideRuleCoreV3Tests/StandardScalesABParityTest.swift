import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("B scale — parity with A and reciprocal variants", .tags(.fast, .regression, .bScale))
struct StandardScalesABParityTest {
    
    // MARK: - A/B Parity
    
    @Suite("A/B parity — same mapping, different tick direction")
    struct ABParity {
        // Exercises: ScaleCalculator.normalizedPosition(for:on:) parity for A vs B
        
        @Test("B vs A — identical normalized positions across representative values",
              arguments: zip(
                [1.0, 2.0, 4.0, 10.0, 25.0, 50.0, 100.0],
                [1.0, 2.0, 4.0, 10.0, 25.0, 50.0, 100.0]
              ))
        func bEqualsA(valueA: Double, valueB: Double) {
            let a = StandardScales.aScale(length: 250.0)
            let b = StandardScales.bScale(length: 250.0)
            
            let posA = ScaleCalculator.normalizedPosition(for: valueA, on: a)
            let posB = ScaleCalculator.normalizedPosition(for: valueB, on: b)
            
            #expect(abs(posA - posB) < 1e-9,
                    "A and B should map identical values to identical normalized positions")
        }
        
        @Test("Round-trip — position→value→position remains consistent on B scale",
              arguments: [1.0, 3.1622776601683795, 10.0, 25.0, 64.0, 100.0])
        func roundTripOnB(value: Double) {
            let b = StandardScales.bScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: b)
            let recovered = ScaleCalculator.value(at: pos, on: b)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: b)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
        
        @Test("Tick counts — A and B generate the same tick distribution")
        func aAndBTickCountsMatch() {
            let a = StandardScales.aScale(length: 250.0)
            let b = StandardScales.bScale(length: 250.0)
            let genA = GeneratedScale(definition: a)
            let genB = GeneratedScale(definition: b)
            
            #expect(genA.tickMarks.count == genB.tickMarks.count,
                    "A and B should have identical tick counts")
            #expect(!genA.tickMarks.isEmpty && !genB.tickMarks.isEmpty,
                    "Generated ticks should be non-empty for A/B")
        }
    }
    
    // MARK: - AI/BI Parity
    
    @Suite("AI/BI parity — reciprocal twins with mirrored tick direction")
    struct AIBIParity {
        // Exercises: ScaleCalculator.normalizedPosition(for:on:) parity for AI vs BI
        
        @Test("BI vs AI — reciprocal twins maintain non-empty ticks and parity",
              arguments: zip(
                [1.0, 2.0, 4.0, 10.0, 25.0, 50.0, 100.0],
                [1.0, 2.0, 4.0, 10.0, 25.0, 50.0, 100.0]
              ))
        func biEqualsAi(value1: Double, value2: Double) {
            let ai = StandardScales.aiScale(length: 250.0)
            let bi = StandardScales.biScale(length: 250.0)
            
            let genAI = GeneratedScale(definition: ai)
            let genBI = GeneratedScale(definition: bi)
            
            #expect(!genAI.tickMarks.isEmpty && !genBI.tickMarks.isEmpty,
                    "AI and BI should generate non-empty ticks")
            #expect(genAI.tickMarks.count == genBI.tickMarks.count,
                    "AI and BI should produce equal tick counts")
            
            let posAI = ScaleCalculator.normalizedPosition(for: value1, on: ai)
            let posBI = ScaleCalculator.normalizedPosition(for: value2, on: bi)
            #expect(abs(posAI - posBI) < 1e-9,
                    "AI and BI should map identical values to identical positions")
        }
        
        @Test("Round-trip — position→value→position remains consistent on BI scale",
              arguments: [1.0, 2.0, 5.0, 10.0, 50.0, 100.0])
        func roundTripOnBI(value: Double) {
            let bi = StandardScales.biScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: bi)
            let recovered = ScaleCalculator.value(at: pos, on: bi)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: bi)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
    }
}
