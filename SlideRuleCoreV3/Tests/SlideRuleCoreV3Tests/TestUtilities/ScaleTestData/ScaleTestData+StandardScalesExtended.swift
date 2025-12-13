import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData Standard Scales Extended

extension ScaleTestData {
    /// Extended standard scales including DFm, trig variants, range-extended, and specialized scales
    static let standardScalesExtended: [ScaleTestData] = [
        // MARK: DFm Variant
        ScaleTestData(
            name: "DFm",
            scaleFactory: { StandardScales.dfmScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.folded
        ),
        
        // MARK: Extended Trig Scales
        ScaleTestData(
            name: "T1",
            scaleFactory: { StandardScales.t1Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [5.73, 10.0, 20.0, 30.0, 40.0, 45.0]
        ),
        ScaleTestData(
            name: "T2",
            scaleFactory: { StandardScales.t2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [45.0, 50.0, 60.0, 70.0, 80.0, 84.29]
        ),
        ScaleTestData(
            name: "KE-S",
            scaleFactory: { StandardScales.keSScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.573, 1.0, 2.0, 3.0, 4.0, 5.0]
        ),
        ScaleTestData(
            name: "KE-T",
            scaleFactory: { StandardScales.keTScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [5.73, 10.0, 20.0, 30.0, 40.0, 45.0]
        ),
        ScaleTestData(
            name: "KE-ST",
            scaleFactory: { StandardScales.keSTScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.1, 0.2, 0.5, 1.0, 2.0, 5.0]
        ),
        
        // MARK: Linear Scales
        ScaleTestData(
            name: "Ln",
            scaleFactory: { StandardScales.lnScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [0.1, 0.5, 1.0, 2.0, 3.0, 5.0]
        ),
        
        // MARK: Extended Range Scales
        ScaleTestData(
            name: "C10-100",
            scaleFactory: { StandardScales.c10to100Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [10.0, 20.0, 30.0, 50.0, 75.0, 100.0]
        ),
        ScaleTestData(
            name: "C100-1000",
            scaleFactory: { StandardScales.c100to1000Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [100.0, 200.0, 500.0, 750.0, 1000.0]
        ),
        ScaleTestData(
            name: "D10-100",
            scaleFactory: { StandardScales.d10to100Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [10.0, 20.0, 30.0, 50.0, 75.0, 100.0]
        ),
        
        // MARK: Specialized Scales
        ScaleTestData(
            name: "CAS",
            scaleFactory: { StandardScales.casScale(length: $0) },
            tolerance: TestTolerance.relaxed,
            testPositions: TestValues.positions,
            testValues: [100.0, 150.0, 200.0, 300.0, 500.0]
        ),
        ScaleTestData(
            name: "TIME",
            scaleFactory: { StandardScales.timeScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 5.0, 10.0, 30.0, 60.0]
        ),
        ScaleTestData(
            name: "TIME2",
            scaleFactory: { StandardScales.time2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [60.0, 120.0, 360.0, 720.0, 1440.0]
        ),
        ScaleTestData(
            name: "CR3S",
            scaleFactory: { StandardScales.cr3sScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 20.0, 100.0]
        ),
        
        // MARK: Root Scales
        ScaleTestData(
            name: "R1",
            scaleFactory: { StandardScales.r1Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 20.0, 100.0]
        ),
        ScaleTestData(
            name: "R2",
            scaleFactory: { StandardScales.r2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [10.0, 20.0, 50.0, 100.0, 200.0, 1000.0]
        ),
        
        // MARK: Cube Root Offset Scales
        ScaleTestData(
            name: "Q1",
            scaleFactory: { StandardScales.q1Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 20.0, 100.0]
        ),
        ScaleTestData(
            name: "Q2",
            scaleFactory: { StandardScales.q2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [10.0, 20.0, 50.0, 100.0, 200.0, 1000.0]
        ),
        ScaleTestData(
            name: "Q3",
            scaleFactory: { StandardScales.q3Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [100.0, 200.0, 500.0, 1000.0, 2000.0, 10000.0]
        )
    ]
}
