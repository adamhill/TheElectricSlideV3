import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Hyperbolic Scales Extended

extension ScaleTestData {
    /// Extended hyperbolic scales (Sh1, Sh2, L360, L180, PA)
    static let hyperbolicScalesExtended: [ScaleTestData] = [
        ScaleTestData(
            name: "Sh1",
            scaleFactory: { StandardScales.sh1Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.1, 0.2, 0.5, 1.0, 2.0, 3.0]
        ),
        ScaleTestData(
            name: "Sh2",
            scaleFactory: { StandardScales.sh2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 20.0, 30.0]
        ),
        ScaleTestData(
            name: "L360",
            scaleFactory: { StandardScales.l360Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.0, 90.0, 180.0, 270.0, 360.0]
        ),
        ScaleTestData(
            name: "L180",
            scaleFactory: { StandardScales.l180Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.0, 45.0, 90.0, 135.0, 180.0]
        ),
        ScaleTestData(
            name: "PA",
            scaleFactory: { StandardScales.paScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.0, 1.0, 5.0, 10.0, 50.0, 100.0]
        )
    ]
}
