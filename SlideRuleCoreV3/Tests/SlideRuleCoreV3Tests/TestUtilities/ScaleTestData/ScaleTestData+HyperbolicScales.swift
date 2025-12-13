import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Hyperbolic Scales Extension

extension ScaleTestData {
    /// Hyperbolic scales (Ch, Th, Sh, H1, H2, P)
    static let hyperbolicScales: [ScaleTestData] = [
        ScaleTestData(
            name: "Ch",
            scaleFactory: { StandardScales.chScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.0, 0.5, 1.0, 2.0, 3.0]
        ),
        ScaleTestData(
            name: "Th",
            scaleFactory: { StandardScales.thScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.1, 0.5, 1.0, 2.0, 3.0]
        ),
        ScaleTestData(
            name: "Sh",
            scaleFactory: { StandardScales.shScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.1, 0.5, 1.0, 2.0, 3.0]
        ),
        ScaleTestData(
            name: "H1",
            scaleFactory: { StandardScales.h1Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.005, 1.1, 1.2, 1.3, 1.415]
        ),
        ScaleTestData(
            name: "H2",
            scaleFactory: { StandardScales.h2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.42, 2.0, 5.0, 8.0, 10.0]
        ),
        ScaleTestData(
            name: "P",
            scaleFactory: { StandardScales.pScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.0, 0.5, 0.9, 0.99, 0.995]
        )
    ]
}
