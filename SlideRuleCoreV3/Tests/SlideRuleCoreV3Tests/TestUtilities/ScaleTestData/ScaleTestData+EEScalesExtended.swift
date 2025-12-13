import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData EE Scales Extended

extension ScaleTestData {
    /// Extended electrical engineering scales
    static let eeScalesExtended: [ScaleTestData] = [
        ScaleTestData(
            name: "XL",
            scaleFactory: { StandardScales.xlScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 10.0, 100.0, 1000.0, 10000.0]
        ),
        ScaleTestData(
            name: "XC",
            scaleFactory: { StandardScales.xcScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 10.0, 100.0, 1000.0, 10000.0]
        ),
        ScaleTestData(
            name: "EE-F",
            scaleFactory: { StandardScales.eefScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.1, 1.0, 10.0, 100.0, 1000.0]
        ),
        ScaleTestData(
            name: "EE-Fo",
            scaleFactory: { StandardScales.eefoScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.1, 1.0, 10.0, 100.0, 1000.0]
        ),
        ScaleTestData(
            name: "EEInductance",
            scaleFactory: { StandardScales.eeInductanceScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.001, 0.01, 0.1, 1.0, 10.0, 100.0]
        ),
        ScaleTestData(
            name: "EEInductanceInverted",
            scaleFactory: { StandardScales.eeInductanceInvertedScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.001, 0.01, 0.1, 1.0, 10.0, 100.0]
        ),
        ScaleTestData(
            name: "CZ",
            scaleFactory: { StandardScales.czScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 10.0, 100.0, 1000.0, 10000.0]
        ),
        ScaleTestData(
            name: "EECapacitanceFrequency",
            scaleFactory: { StandardScales.eeCapacitanceFrequencyScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.001, 0.01, 0.1, 1.0, 10.0]
        ),
        ScaleTestData(
            name: "Z",
            scaleFactory: { StandardScales.zScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 10.0, 100.0, 1000.0]
        ),
        ScaleTestData(
            name: "EEReflectionCoefficient",
            scaleFactory: { StandardScales.eeReflectionCoefficientScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 1.5, 2.0, 3.0, 5.0, 10.0]
        ),
        ScaleTestData(
            name: "EEReflectionCoefficient2",
            scaleFactory: { StandardScales.eeReflectionCoefficient2Scale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 1.5, 2.0, 3.0, 5.0, 10.0]
        ),
        ScaleTestData(
            name: "EEPowerRatio",
            scaleFactory: { StandardScales.eePowerRatioScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 100.0]
        ),
        ScaleTestData(
            name: "EEPowerRatioInverted",
            scaleFactory: { StandardScales.eePowerRatioInvertedScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 100.0]
        )
    ]
}
