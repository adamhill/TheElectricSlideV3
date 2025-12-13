import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Power Scales Extension

extension ScaleTestData {
    /// Power scales (A, B, K)
    static let powerScales: [ScaleTestData] = [
        ScaleTestData(
            name: "A",
            scaleFactory: { StandardScales.aScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.squared
        ),
        ScaleTestData(
            name: "B",
            scaleFactory: { StandardScales.bScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.squared
        ),
        ScaleTestData(
            name: "K",
            scaleFactory: { StandardScales.kScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 100.0, 1000.0]
        )
    ]
}
