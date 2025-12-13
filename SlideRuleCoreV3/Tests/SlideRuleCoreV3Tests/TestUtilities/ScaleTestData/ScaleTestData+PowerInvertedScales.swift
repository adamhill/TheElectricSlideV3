import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Power Inverted Scales

extension ScaleTestData {
    /// Power inverted scales (AI, BI)
    static let powerInvertedScales: [ScaleTestData] = [
        ScaleTestData(
            name: "AI",
            scaleFactory: { StandardScales.aiScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 4.0, 6.0, 8.0, 10.0]
        ),
        ScaleTestData(
            name: "BI",
            scaleFactory: { StandardScales.biScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 4.0, 6.0, 8.0, 10.0]
        )
    ]
}
