import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Pickett N16-ES Scales

extension ScaleTestData {
    /// Pickett N16-ES electronic slide rule scales
    static let pickettN16ESScales: [ScaleTestData] = [
        ScaleTestData(
            name: "InductanceReciprocal",
            scaleFactory: { StandardScales.inductanceReciprocalScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.1, 0.5, 1.0, 5.0, 10.0, 100.0]
        ),
        ScaleTestData(
            name: "CapacitanceReciprocal",
            scaleFactory: { StandardScales.capacitanceReciprocalScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.001, 0.01, 0.1, 1.0, 10.0, 100.0]
        ),
        ScaleTestData(
            name: "PickettL",
            scaleFactory: { StandardScales.pickettLScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.1, 1.0, 10.0, 100.0, 1000.0]
        ),
        ScaleTestData(
            name: "PickettDQ",
            scaleFactory: { StandardScales.pickettDQScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.001, 0.01, 0.1, 1.0, 10.0]
        ),
        ScaleTestData(
            name: "PickettF",
            scaleFactory: { StandardScales.pickettFScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.1, 1.0, 10.0, 100.0, 1000.0]
        ),
        ScaleTestData(
            name: "WavelengthLambda",
            scaleFactory: { StandardScales.wavelengthLambdaScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [0.3, 1.0, 3.0, 10.0, 30.0, 300.0]
        ),
        ScaleTestData(
            name: "PhaseAngleTheta",
            scaleFactory: { StandardScales.phaseAngleThetaSmallScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0]
        ),
        ScaleTestData(
            name: "CosinePowerFactor",
            scaleFactory: { StandardScales.cosinePowerFactorScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.0, 0.2, 0.5, 0.707, 0.866, 1.0]
        ),
        ScaleTestData(
            name: "DecibelPower",
            scaleFactory: { StandardScales.decibelPowerScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 20.0, 100.0]
        ),
        ScaleTestData(
            name: "DecibelVoltage",
            scaleFactory: { StandardScales.decibelVoltageScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 20.0, 100.0]
        )
    ]
}
