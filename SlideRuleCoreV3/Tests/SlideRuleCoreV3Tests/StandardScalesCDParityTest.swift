import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("C/D scales — parity and reciprocal variant", .tags(.fast, .regression, .cScale, .dScale))
struct StandardScalesCDTests {
    
    // MARK: - C/D Parity
    
    @Suite("C/D parity — same mapping, different tick direction")
    struct CDParity {
        
        @Test("D vs C — identical normalized positions across representative values")
        func dEqualsC() {
            let pair = ParityTestHelper.ScalePair(
                name1: "C", scale1Factory: { StandardScales.cScale(length: $0) },
                name2: "D", scale2Factory: { StandardScales.dScale(length: $0) },
                testValues: TestValues.logarithmic,
                tolerance: 1e-9
            )
            ParityTestHelper.testCompleteParity(pair)
        }
        
        @Test("Round-trip — position→value→position remains consistent on D scale",
              arguments: [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0])
        func roundTripOnD(value: Double) {
            let d = StandardScales.dScale(length: 250.0)
            RoundTripTester.testRoundTrip(value: value, on: d, tolerance: 1e-8)
        }
    }
    
    // MARK: - CI Scale Tests
    
    @Suite("CI scale — reciprocal logarithmic behavior", .tags(.ciScale))
    struct CIScaleTests {
        
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
            RoundTripTester.testRoundTrip(value: value, on: ci, tolerance: 1e-8)
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
        
        @Test("DI vs CI — reciprocal twins maintain non-empty ticks and parity")
        func diEqualsCI() {
            let pair = ParityTestHelper.ScalePair(
                name1: "CI", scale1Factory: { StandardScales.ciScale(length: $0) },
                name2: "DI", scale2Factory: { StandardScales.diScale(length: $0) },
                testValues: TestValues.inverted,
                tolerance: 1e-9
            )
            ParityTestHelper.testCompleteParity(pair)
        }
        
        @Test("Round-trip — position→value→position remains consistent on DI scale",
              arguments: [1.0, 2.0, 4.0, 5.0, 7.5, 10.0])
        func roundTripOnDI(value: Double) {
            let di = StandardScales.diScale(length: 250.0)
            RoundTripTester.testRoundTrip(value: value, on: di, tolerance: 1e-8)
        }
    }
}
