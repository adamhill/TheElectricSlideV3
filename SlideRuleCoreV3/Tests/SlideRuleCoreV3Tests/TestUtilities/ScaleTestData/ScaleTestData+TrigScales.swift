import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Trigonometric Scales Extension

extension ScaleTestData {
    /// Trigonometric scales (S, T, ST)
    static let trigScales: [ScaleTestData] = [
        ScaleTestData(
            name: "S",
            scaleFactory: { StandardScales.sScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [5.7, 10.0, 30.0, 45.0, 60.0, 90.0]
        ),
        ScaleTestData(
            name: "T",
            scaleFactory: { StandardScales.tScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [5.7, 10.0, 20.0, 30.0, 40.0, 45.0]
        ),
        ScaleTestData(
            name: "ST",
            scaleFactory: { StandardScales.stScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.57, 1.0, 2.0, 3.0, 4.0, 5.7]
        )
    ]
}
