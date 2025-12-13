import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Scale Function Test Data Infrastructure

/// Test data structure for systematic scale function testing
struct FunctionTestCase: Sendable {
    let name: String
    let function: any ScaleFunction
    let testValues: [Double]
    let knownPairs: [(input: Double, expected: Double)]
    let boundaryTests: [(value: Double, expectation: FunctionRoundTripTester.BoundaryExpectation)]
    let tolerance: Double
}

// MARK: - Scale Function Test Data

extension ScaleTestData {
    
    /// Collection of all function test cases
    static let allFunctions: [FunctionTestCase] = [
        logarithmicFunction,
        invertedLogarithmicFunction,
        halfLogFunction,
        thirdLogFunction,
        logLogFunction,
        sineFunction,
        tangentFunction,
        smallTanFunction,
        hyperbolicSineFunction,
        hyperbolicCosineFunction,
        hyperbolicTangentFunction,
        inductanceReciprocalFunction,
        capacitanceReciprocalFunction,
        angularFrequencyOmegaFunction,
        timeConstantFunction
    ]
    
    // MARK: - Logarithmic Functions
    
    /// Standard logarithmic function (C/D scales)
    /// Formula: log₁₀(x)
    static let logarithmicFunction = FunctionTestCase(
        name: "Logarithmic (log₁₀)",
        function: LogarithmicFunction(),
        testValues: [1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 15.0, 25.0, 50.0, 100.0],
        knownPairs: [
            (input: 1.0, expected: 0.0),
            (input: 10.0, expected: 1.0),
            (input: 100.0, expected: 2.0),
            (input: 2.0, expected: 0.30103),
            (input: 5.0, expected: 0.69897)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: -1.0, expectation: .nan),
            (value: 1.0, expectation: .finite),
            (value: Double.infinity, expectation: .positiveInfinity)
        ],
        tolerance: TestTolerance.strict
    )
    
    /// Inverted logarithmic function (CI/DI scales)
    /// Formula: -log₁₀(x)
    static let invertedLogarithmicFunction = FunctionTestCase(
        name: "Inverted Logarithmic (-log₁₀)",
        function: ReciprocalLogFunction(),
        testValues: [1.0, 2.0, 3.0, 5.0, 7.0, 10.0],
        knownPairs: [
            (input: 1.0, expected: 0.0),
            (input: 10.0, expected: -1.0),
            (input: 100.0, expected: -2.0),
            (input: 2.0, expected: -0.30103),
            (input: 0.1, expected: 1.0)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .positiveInfinity),
            (value: -1.0, expectation: .nan),
            (value: 1.0, expectation: .finite)
        ],
        tolerance: TestTolerance.strict
    )
    
    // MARK: - Power Functions
    
    /// Half-log function (A/B scales - squares)
    /// Formula: log₁₀(x) / 2
    static let halfLogFunction = FunctionTestCase(
        name: "Half-Log (A/B scales)",
        function: HalfLogFunction(),
        testValues: [1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0, 100.0],
        knownPairs: [
            (input: 1.0, expected: 0.0),
            (input: 100.0, expected: 1.0),
            (input: 10.0, expected: 0.5),
            (input: 4.0, expected: 0.30103),
            (input: 25.0, expected: 0.69897)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 1.0, expectation: .finite),
            (value: 100.0, expectation: .finite)
        ],
        tolerance: TestTolerance.strict
    )
    
    /// Third-log function (K scale - cubes)
    /// Formula: log₁₀(x) / 3
    static let thirdLogFunction = FunctionTestCase(
        name: "Third-Log (K scale)",
        function: ThirdLogFunction(),
        testValues: [1.0, 8.0, 27.0, 64.0, 125.0, 216.0, 343.0, 512.0, 729.0, 1000.0],
        knownPairs: [
            (input: 1.0, expected: 0.0),
            (input: 1000.0, expected: 1.0),
            (input: 10.0, expected: 0.33333),
            (input: 100.0, expected: 0.66667),
            (input: 8.0, expected: 0.30103)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 1.0, expectation: .finite),
            (value: 1000.0, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    // MARK: - Log-Log Functions
    
    /// Log-log function (LL scales)
    /// Formula: log₁₀(ln(x))
    static let logLogFunction = FunctionTestCase(
        name: "Log-Log (LL scales)",
        function: LogLogFunction(),
        testValues: [1.01, 1.1, 1.5, 2.0, 2.718, 5.0, 10.0, 20.0, 100.0],
        knownPairs: [
            (input: 2.718281828, expected: 0.0),  // e¹
            (input: 7.389056099, expected: 0.30103),  // e²
            (input: 20.08553692, expected: 0.47712),  // e³
            (input: 2.0, expected: -0.15949)
        ],
        boundaryTests: [
            (value: 1.0, expectation: .negativeInfinity),
            (value: 0.5, expectation: .nan),
            (value: 2.718, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    // MARK: - Trigonometric Functions
    
    /// Sine function (S scale)
    /// Formula: log₁₀(sin(x°) × 10)
    static let sineFunction = FunctionTestCase(
        name: "Sine (S scale)",
        function: SineFunction(multiplier: 10.0),
        testValues: [5.74, 10.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0],
        knownPairs: [
            (input: 30.0, expected: -0.30103),  // sin(30°) = 0.5
            (input: 45.0, expected: -0.15051),  // sin(45°) ≈ 0.707
            (input: 60.0, expected: -0.06279),  // sin(60°) ≈ 0.866
            (input: 90.0, expected: 0.0)  // sin(90°) = 1.0
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 90.0, expectation: .finite),
            (value: 45.0, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    /// Tangent function (T scale)
    /// Formula: log₁₀(tan(x°) × 10)
    static let tangentFunction = FunctionTestCase(
        name: "Tangent (T scale)",
        function: TangentFunction(multiplier: 10.0),
        testValues: [5.71, 10.0, 20.0, 30.0, 40.0, 45.0],
        knownPairs: [
            (input: 45.0, expected: 0.0),  // tan(45°) = 1.0
            (input: 30.0, expected: -0.23856),  // tan(30°) ≈ 0.577
            (input: 60.0, expected: 0.23856)  // tan(60°) ≈ 1.732
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 45.0, expectation: .finite),
            (value: 89.0, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    /// Small tangent function (ST scale)
    /// Formula: log₁₀(x × π/180 × 100)
    static let smallTanFunction = FunctionTestCase(
        name: "Small Tangent (ST scale)",
        function: SmallTanFunction(),
        testValues: [0.57, 1.0, 2.0, 3.0, 4.0, 5.0],
        knownPairs: [
            (input: 1.0, expected: -1.75587),  // log₁₀(π/180 × 100)
            (input: 5.0, expected: -0.85672),
            (input: 10.0, expected: -0.75587)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 1.0, expectation: .finite),
            (value: 5.0, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    // MARK: - Hyperbolic Functions
    
    /// Hyperbolic sine function (Sh scales)
    /// Formula: log₁₀(sinh(x) × 10)
    static let hyperbolicSineFunction = FunctionTestCase(
        name: "Hyperbolic Sine (Sh scale)",
        function: HyperbolicSineFunction(multiplier: 10.0, offset: 0.0),
        testValues: [0.1, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0],
        knownPairs: [
            (input: 0.88137, expected: 0.0),  // sinh(0.88137) ≈ 1.0
            (input: 1.44364, expected: 0.30103),  // sinh(1.44364) ≈ 2.0
            (input: 1.81845, expected: 0.47712)  // sinh(1.81845) ≈ 3.0
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 0.88137, expectation: .finite),
            (value: 2.0, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    /// Hyperbolic cosine function (Ch scale)
    /// Formula: log₁₀(cosh(x))
    static let hyperbolicCosineFunction = FunctionTestCase(
        name: "Hyperbolic Cosine (Ch scale)",
        function: HyperbolicCosineFunction(),
        testValues: [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0],
        knownPairs: [
            (input: 0.0, expected: 0.0),  // cosh(0) = 1.0
            (input: 1.3169, expected: 0.30103),  // cosh(1.3169) ≈ 2.0
            (input: 1.7627, expected: 0.47712)  // cosh(1.7627) ≈ 3.0
        ],
        boundaryTests: [
            (value: 0.0, expectation: .finite),
            (value: 1.0, expectation: .finite),
            (value: 2.0, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    /// Hyperbolic tangent function (Th scale)
    /// Formula: log₁₀(tanh(x) × 10)
    static let hyperbolicTangentFunction = FunctionTestCase(
        name: "Hyperbolic Tangent (Th scale)",
        function: HyperbolicTangentFunction(multiplier: 10.0),
        testValues: [0.1, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0],
        knownPairs: [
            (input: 0.54931, expected: -0.30103),  // tanh(0.54931) ≈ 0.5
            (input: 1.09861, expected: -0.09691),  // tanh(1.09861) ≈ 0.8
            (input: 2.29756, expected: -0.00868)  // tanh(2.29756) ≈ 0.98
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 1.0, expectation: .finite),
            (value: 3.0, expectation: .finite)
        ],
        tolerance: TestTolerance.standard
    )
    
    // MARK: - EE Functions
    
    /// Inductance reciprocal function (Lr scale)
    /// Formula: 1 - log₁₀(x) / 12
    static let inductanceReciprocalFunction = FunctionTestCase(
        name: "Inductance Reciprocal (Lr scale)",
        function: InductanceReciprocalFunction(cycles: 12),
        testValues: [0.001, 0.01, 0.1, 1.0, 10.0, 100.0, 1000.0],
        knownPairs: [
            (input: 1.0, expected: 1.0),
            (input: 10.0, expected: 0.91667),
            (input: 100.0, expected: 0.83333),
            (input: 0.1, expected: 1.08333)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .positiveInfinity),
            (value: 1.0, expectation: .finite),
            (value: 100.0, expectation: .finite)
        ],
        tolerance: TestTolerance.eeScale
    )
    
    /// Capacitance reciprocal function (Cr scale - inverted)
    /// Formula: 1 - (log₁₀(x) + 2) / 4
    static let capacitanceReciprocalFunction = FunctionTestCase(
        name: "Capacitance Reciprocal (Cr scale)",
        function: CapacitanceReciprocalFunction(cycles: 4),
        testValues: [0.01, 0.1, 1.0, 10.0, 100.0],
        knownPairs: [
            (input: 100.0, expected: 0.0),  // Left end (inverted)
            (input: 10.0, expected: 0.25),
            (input: 1.0, expected: 0.5),
            (input: 0.1, expected: 0.75),
            (input: 0.01, expected: 1.0)  // Right end (inverted)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 1.0, expectation: .finite),
            (value: 100.0, expectation: .finite)
        ],
        tolerance: TestTolerance.eeScale
    )
    
    /// Angular frequency omega function (ω scale)
    /// Formula: log₁₀(ω) / 12
    static let angularFrequencyOmegaFunction = FunctionTestCase(
        name: "Angular Frequency (ω scale)",
        function: AngularFrequencyOmegaFunction(cycles: 12),
        testValues: [0.01, 0.1, 1.0, 10.0, 100.0],
        knownPairs: [
            (input: 1.0, expected: 0.0),
            (input: 10.0, expected: 0.08333),
            (input: 100.0, expected: 0.16667),
            (input: 0.1, expected: -0.08333)
        ],
        boundaryTests: [
            (value: 0.0, expectation: .negativeInfinity),
            (value: 1.0, expectation: .finite),
            (value: 100.0, expectation: .finite)
        ],
        tolerance: TestTolerance.eeScale
    )
    
    /// Time constant function (τ scale - inverted)
    /// Formula: -log₁₀(τ) / 12
    static let timeConstantFunction = FunctionTestCase(
        name: "Time Constant (τ scale)",
        function: TimeConstantFunction(cycles: 12),
        testValues: [0.01, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0],
        knownPairs: [
            (input: 1.0, expected: 0.0),  // τ=1 aligns with ω=1
            (input: 0.5, expected: 0.02510),  // τ=0.5 aligns with ω=2
            (input: 0.1, expected: 0.08333),  // τ=0.1 aligns with ω=10
            (input: 10.0, expected: -0.08333)  // τ=10 aligns with ω=0.1
        ],
        boundaryTests: [
            (value: 0.0, expectation: .positiveInfinity),
            (value: 1.0, expectation: .finite),
            (value: 10.0, expectation: .finite)
        ],
        tolerance: TestTolerance.eeScale
    )
}
