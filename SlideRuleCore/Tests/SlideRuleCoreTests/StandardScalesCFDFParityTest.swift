import Testing
import Foundation
@testable import SlideRuleCore

@Suite("CF/DF scales — folded scale parity and reciprocal variant", .tags(.fast, .regression, .cfScale, .dfScale))
struct StandardScalesCFDFTests {
    
    // MARK: - CF/DF Parity
    
    @Suite("CF/DF parity — same mapping, different tick direction")
    struct CFDFParity {
        // Exercises: ScaleCalculator.normalizedPosition(for:on:) parity for CF vs DF
        
        @Test("DF vs CF — identical normalized positions across representative values",
              arguments: zip(
                [3.14159, 4.0, 5.0, 10.0, 15.0, 20.0, 31.4159],
                [3.14159, 4.0, 5.0, 10.0, 15.0, 20.0, 31.4159]
              ))
        func dfEqualsCF(valueCF: Double, valueDF: Double) {
            let cf = StandardScales.cfScale(length: 250.0)
            let df = StandardScales.dfScale(length: 250.0)
            
            let posCF = ScaleCalculator.normalizedPosition(for: valueCF, on: cf)
            let posDF = ScaleCalculator.normalizedPosition(for: valueDF, on: df)
            
            #expect(abs(posCF - posDF) < 1e-9,
                    "CF and DF should map identical values to identical normalized positions")
        }
        
        @Test("Round-trip — position→value→position remains consistent on DF scale",
              arguments: [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159])
        func roundTripOnDF(value: Double) {
            let df = StandardScales.dfScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: df)
            let recovered = ScaleCalculator.value(at: pos, on: df)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: df)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
        
        @Test("Tick counts — CF and DF generate the same tick distribution")
        func cfAndDFTickCountsMatch() {
            let cf = StandardScales.cfScale(length: 250.0)
            let df = StandardScales.dfScale(length: 250.0)
            let genCF = GeneratedScale(definition: cf)
            let genDF = GeneratedScale(definition: df)
            
            #expect(genCF.tickMarks.count == genDF.tickMarks.count,
                    "CF and DF should have identical tick counts")
            #expect(!genCF.tickMarks.isEmpty && !genDF.tickMarks.isEmpty,
                    "Generated ticks should be non-empty for CF/DF")
        }
    }
    
    // MARK: - CIF Scale Tests
    
    @Suite("CIF scale — folded reciprocal logarithmic behavior", .tags(.cifScale))
    struct CIFScaleTests {
        // Exercises: ScaleCalculator operations on CIF (folded reciprocal) scale
        
        @Test("CIF scale — non-empty tick generation")
        func cifGeneratesTicks() {
            let cif = StandardScales.cifScale(length: 250.0)
            let genCIF = GeneratedScale(definition: cif)
            
            #expect(!genCIF.tickMarks.isEmpty,
                    "CIF should generate non-empty ticks")
        }
        
        @Test("Round-trip — position→value→position remains consistent on CIF scale",
              arguments: [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159])
        func roundTripOnCIF(value: Double) {
            let cif = StandardScales.cifScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: cif)
            let recovered = ScaleCalculator.value(at: pos, on: cif)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: cif)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
        
        @Test("CIF reciprocal relationship — values decrease as position increases")
        func cifReciprocalBehavior() {
            let cif = StandardScales.cifScale(length: 250.0)
            
            // CIF range is 10π to π (descending), so smaller positions should have larger values
            let pos1 = 0.0
            let pos2 = 0.5
            let pos3 = 1.0
            
            let value1 = ScaleCalculator.value(at: pos1, on: cif)
            let value2 = ScaleCalculator.value(at: pos2, on: cif)
            let value3 = ScaleCalculator.value(at: pos3, on: cif)
            
            #expect(value1 > value2, "CIF values should decrease as position increases")
            #expect(value2 > value3, "CIF values should decrease as position increases")
        }
        
        @Test("CIF folded at π — start and end values match expected range")
        func cifFoldedRange() {
            let cif = StandardScales.cifScale(length: 250.0)
            
            // CIF goes from 10π to π (reverse/reciprocal)
            let startValue = ScaleCalculator.value(at: 0.0, on: cif)
            let endValue = ScaleCalculator.value(at: 1.0, on: cif)
            
            #expect(abs(startValue - 10.0 * .pi) < 1e-6, "CIF should start at 10π")
            #expect(abs(endValue - .pi) < 1e-6, "CIF should end at π")
        }
    }
    
    // MARK: - CIF/DIF Parity
    
    @Suite("CIF/DIF Parity", .tags(.cifScale, .difScale))
    struct CIFDIFParity {
        // Exercises: ScaleCalculator.normalizedPosition(for:on:) parity for CIF vs DIF
        
        @Test("DIF vs CIF — identical normalized positions across representative values",
              arguments: zip(
                [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159],
                [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159]
              ))
        func difEqualsCIF(valueCIF: Double, valueDIF: Double) {
            let cif = StandardScales.cifScale(length: 250.0)
            let dif = StandardScales.difScale(length: 250.0)
            
            let posCIF = ScaleCalculator.normalizedPosition(for: valueCIF, on: cif)
            let posDIF = ScaleCalculator.normalizedPosition(for: valueDIF, on: dif)
            
            #expect(abs(posCIF - posDIF) < 1e-9,
                    "CIF and DIF should map identical values to identical normalized positions")
        }
        
        @Test("Round-trip — position→value→position remains consistent on DIF scale",
              arguments: [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159])
        func roundTripOnDIF(value: Double) {
            let dif = StandardScales.difScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: dif)
            let recovered = ScaleCalculator.value(at: pos, on: dif)
            let posRecovered = ScaleCalculator.normalizedPosition(for: recovered, on: dif)
            
            #expect(abs(recovered - value) < 1e-8, "Recovered value should match original")
            #expect(abs(posRecovered - pos) < 1e-12, "Position should be stable after round-trip")
        }
        
        @Test("Tick counts — CIF and DIF generate the same tick distribution")
        func cifAndDIFTickCountsMatch() {
            let cif = StandardScales.cifScale(length: 250.0)
            let dif = StandardScales.difScale(length: 250.0)
            let genCIF = GeneratedScale(definition: cif)
            let genDIF = GeneratedScale(definition: dif)
            
            #expect(genCIF.tickMarks.count == genDIF.tickMarks.count,
                    "CIF and DIF should have identical tick counts")
            #expect(!genCIF.tickMarks.isEmpty && !genDIF.tickMarks.isEmpty,
                    "Generated ticks should be non-empty for CIF/DIF")
        }
    }
}