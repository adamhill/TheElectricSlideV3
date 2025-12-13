import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Log-Log Scales Extension

extension ScaleTestData {
    /// Log-Log scales (LL0, LL1, LL2, LL3, etc.)
    static let logLogScales: [ScaleTestData] = [
        ScaleTestData(
            name: "LL0",
            scaleFactory: { StandardScales.ll0Scale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [1.001, 1.005, 1.01, 1.02, 1.05, 1.10]
        ),
        ScaleTestData(
            name: "LL1",
            scaleFactory: { StandardScales.ll1Scale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [1.10, 1.2, 1.35, 2.0, 2.5, 2.718]
        ),
        ScaleTestData(
            name: "LL2",
            scaleFactory: { StandardScales.ll2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [2.8, 5.0, 10.0, 15.0, 20.0]
        ),
        ScaleTestData(
            name: "LL3",
            scaleFactory: { StandardScales.ll3Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [22.0, 100.0, 500.0, 1000.0, 20000.0]
        )
    ]
}
