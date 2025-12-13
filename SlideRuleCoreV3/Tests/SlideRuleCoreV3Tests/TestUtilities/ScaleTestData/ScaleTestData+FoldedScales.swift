import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Folded Scales Extension

extension ScaleTestData {
    /// Folded scales (CF, DF, CIF, DIF)
    static let foldedScales: [ScaleTestData] = [
        ScaleTestData(
            name: "CF",
            scaleFactory: { StandardScales.cfScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.folded
        ),
        ScaleTestData(
            name: "DF",
            scaleFactory: { StandardScales.dfScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.folded
        ),
        ScaleTestData(
            name: "CIF",
            scaleFactory: { StandardScales.cifScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.folded
        ),
        ScaleTestData(
            name: "DIF",
            scaleFactory: { StandardScales.difScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.folded
        )
    ]
}
