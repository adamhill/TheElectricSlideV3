import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("B scale — parity with A and reciprocal variants", .tags(.fast, .regression, .bScale))
struct StandardScalesABParityTest {
    
    // MARK: - A/B Parity
    
    @Suite("A/B parity — same mapping, different tick direction")
    struct ABParity {
        
        @Test("B vs A — identical normalized positions across representative values")
        func bEqualsA() {
            let pair = ParityTestHelper.ScalePair(
                name1: "A", scale1Factory: { StandardScales.aScale(length: $0) },
                name2: "B", scale2Factory: { StandardScales.bScale(length: $0) },
                testValues: TestValues.squared,
                tolerance: 1e-9
            )
            ParityTestHelper.testCompleteParity(pair)
        }
        
        @Test("Round-trip — position→value→position remains consistent on B scale",
              arguments: [1.0, 3.1622776601683795, 10.0, 25.0, 64.0, 100.0])
        func roundTripOnB(value: Double) {
            let b = StandardScales.bScale(length: 250.0)
            RoundTripTester.testRoundTrip(value: value, on: b, tolerance: 1e-8)
        }
    }
    
    // MARK: - AI/BI Parity
    
    @Suite("AI/BI parity — reciprocal twins with mirrored tick direction")
    struct AIBIParity {
        
        @Test("BI vs AI — reciprocal twins maintain non-empty ticks and parity")
        func biEqualsAi() {
            let pair = ParityTestHelper.ScalePair(
                name1: "AI", scale1Factory: { StandardScales.aiScale(length: $0) },
                name2: "BI", scale2Factory: { StandardScales.biScale(length: $0) },
                testValues: TestValues.squared,
                tolerance: 1e-9
            )
            ParityTestHelper.testCompleteParity(pair)
        }
        
        @Test("Round-trip — position→value→position remains consistent on BI scale",
              arguments: [1.0, 2.0, 5.0, 10.0, 50.0, 100.0])
        func roundTripOnBI(value: Double) {
            let bi = StandardScales.biScale(length: 250.0)
            RoundTripTester.testRoundTrip(value: value, on: bi, tolerance: 1e-8)
        }
    }
}
