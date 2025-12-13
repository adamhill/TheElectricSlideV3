import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Negative Log-Log Scales

extension ScaleTestData {
    /// Negative log-log scales (LL00, LL01, LL02, LL03 and their B variants)
    static let negativeLogLogScales: [ScaleTestData] = [
        ScaleTestData(
            name: "LL00",
            scaleFactory: { StandardScales.ll00Scale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [0.9999, 0.999, 0.995, 0.99, 0.98, 0.95]
        ),
        ScaleTestData(
            name: "LL01",
            scaleFactory: { StandardScales.ll01Scale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [0.95, 0.90, 0.85, 0.75, 0.60, 0.50]
        ),
        ScaleTestData(
            name: "LL02",
            scaleFactory: { StandardScales.ll02Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.50, 0.40, 0.30, 0.20, 0.15, 0.10]
        ),
        ScaleTestData(
            name: "LL03",
            scaleFactory: { StandardScales.ll03Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.10, 0.05, 0.01, 0.005, 0.001, 0.0001]
        ),
        ScaleTestData(
            name: "LL00B",
            scaleFactory: { StandardScales.ll00BScale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [0.9999, 0.999, 0.995, 0.99, 0.98, 0.95]
        ),
        ScaleTestData(
            name: "LL02B",
            scaleFactory: { StandardScales.ll02BScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.50, 0.40, 0.30, 0.20, 0.15, 0.10]
        ),
        ScaleTestData(
            name: "H266LL01",
            scaleFactory: { StandardScales.h266LL01Scale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [0.95, 0.90, 0.85, 0.75, 0.60, 0.50]
        ),
        ScaleTestData(
            name: "H266LL03",
            scaleFactory: { StandardScales.h266LL03Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.10, 0.05, 0.01, 0.005, 0.001, 0.0001]
        )
    ]
}
