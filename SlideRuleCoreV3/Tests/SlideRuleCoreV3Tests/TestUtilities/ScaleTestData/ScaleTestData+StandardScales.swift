import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Standard Scales Extension

extension ScaleTestData {
    /// Basic logarithmic scales (C, D, CI, DI)
    static let standardScales: [ScaleTestData] = [
        ScaleTestData(
            name: "C",
            scaleFactory: { StandardScales.cScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.logarithmic
        ),
        ScaleTestData(
            name: "D",
            scaleFactory: { StandardScales.dScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.logarithmic
        ),
        ScaleTestData(
            name: "CI",
            scaleFactory: { StandardScales.ciScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.inverted
        ),
        ScaleTestData(
            name: "DI",
            scaleFactory: { StandardScales.diScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.inverted
        )
    ]
}
