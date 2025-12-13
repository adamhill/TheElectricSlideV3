import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Electrical Engineering Scales Extension

extension ScaleTestData {
    /// Electrical Engineering scales (basic set)
    static let eeScales: [ScaleTestData] = [
        ScaleTestData(
            name: "ω",
            scaleFactory: { StandardScales.angularFrequencyOmegaScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 5.0, 10.0, 50.0, 100.0]
        ),
        ScaleTestData(
            name: "τ",
            scaleFactory: { StandardScales.timeConstantTauScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 5.0, 10.0, 50.0, 100.0]
        )
    ]
}
