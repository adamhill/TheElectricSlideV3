import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("CF/DF scales — folded scale parity and reciprocal variant", .tags(.fast, .regression, .cfScale, .dfScale))
struct StandardScalesCFDFTests {
    
    // MARK: - CF/DF Parity
    
    @Suite("CF/DF parity — same mapping, different tick direction")
    struct CFDFParity {
        
        @Test("DF vs CF — identical normalized positions across representative values")
        func dfEqualsCF() {
            let pair = ParityTestHelper.ScalePair(
                name1: "CF", scale1Factory: { StandardScales.cfScale(length: $0) },
                name2: "DF", scale2Factory: { StandardScales.dfScale(length: $0) },
                testValues: TestValues.folded,
                tolerance: 1e-9
            )
            ParityTestHelper.testCompleteParity(pair)
        }
        
        @Test("Round-trip — position→value→position remains consistent on DF scale",
              arguments: [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159])
        func roundTripOnDF(value: Double) {
            let df = StandardScales.dfScale(length: 250.0)
            RoundTripTester.testRoundTrip(value: value, on: df, tolerance: 1e-8)
        }
    }
    
    // MARK: - CIF Scale Tests
    
    @Suite("CIF scale — folded reciprocal logarithmic behavior", .tags(.cifScale))
    struct CIFScaleTests {
        
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
            RoundTripTester.testRoundTrip(value: value, on: cif, tolerance: 1e-8)
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
        
        @Test("DIF vs CIF — identical normalized positions across representative values")
        func difEqualsCIF() {
            let pair = ParityTestHelper.ScalePair(
                name1: "CIF", scale1Factory: { StandardScales.cifScale(length: $0) },
                name2: "DIF", scale2Factory: { StandardScales.difScale(length: $0) },
                testValues: TestValues.folded,
                tolerance: 1e-9
            )
            ParityTestHelper.testCompleteParity(pair)
        }
        
        @Test("Round-trip — position→value→position remains consistent on DIF scale",
              arguments: [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159])
        func roundTripOnDIF(value: Double) {
            let dif = StandardScales.difScale(length: 250.0)
            RoundTripTester.testRoundTrip(value: value, on: dif, tolerance: 1e-8)
        }
    }
}
