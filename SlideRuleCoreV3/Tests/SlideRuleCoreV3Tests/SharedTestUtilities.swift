import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Shared test utilities and helper functions for SlideRuleCoreV3 test suite.
/// Consolidates common patterns to reduce duplication across test files.

// MARK: - Test Tolerance Constants

/// Standard tolerance constants used across test suites
enum TestTolerance {
    /// Standard tolerance for most scale calculations (0.01 = 1%)
    static let standard = 0.01
    
    /// Relaxed tolerance for complex calculations (0.05 = 5%)
    static let relaxed = 0.05
    
    /// Strict tolerance for high-precision requirements (0.001 = 0.1%)
    static let strict = 0.001
    
    /// Tolerance for EE scales which may have lower precision
    static let eeScale = 0.05
    
    /// Very relaxed tolerance for sampling/approximate values (0.1 = 10%)
    static let veryRelaxed = 0.1
}

// MARK: - Common Test Value Sets

/// Standard test value collections used across multiple test suites
enum TestValues {
    /// Standard logarithmic scale test values (1-10 range)
    static let logarithmic = [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0]
    
    /// Extended logarithmic test values (1-100 range)
    static let logarithmicExtended = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
    
    /// Square scale test values
    static let squared = [1.0, 3.1622776601683795, 10.0, 25.0, 64.0, 100.0]
    
    /// Folded scale test values  
    static let folded = [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159]
    
    /// Standard inverted scale test values
    static let inverted = [1.0, 2.0, 4.0, 5.0, 7.5, 10.0]
    
    /// Standard test positions across normalized range [0, 1]
    static let positions = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
}

// MARK: - Scale Factory Helper

/// Helper to retrieve scale definitions by name with type safety
struct TestScaleFactory {
    
    /// Get a scale by name, wrapping StandardScales.scale(named:length:)
    /// - Parameters:
    ///   - name: Scale name (case-insensitive)
    ///   - length: Scale length in points (default: 250.0)
    /// - Returns: Scale definition if found, nil otherwise
    static func getScale(named name: String, length: Double = 250.0) -> ScaleDefinition? {
        return StandardScales.scale(named: name, length: length)
    }
    
    /// Get a scale by name with expectations for test assertions
    /// - Parameters:
    ///   - name: Scale name (case-insensitive)
    ///   - length: Scale length in points (default: 250.0)
    /// - Returns: Scale definition, recording Issue if not found
    static func getScaleOrFail(named name: String, length: Double = 250.0, sourceLocation: SourceLocation = #_sourceLocation) -> ScaleDefinition? {
        guard let scale = StandardScales.scale(named: name, length: length) else {
            Issue.record("Could not find scale named '\(name)'", sourceLocation: sourceLocation)
            return nil
        }
        return scale
    }
}

// MARK: - Round-Trip Testing Utilities

/// Utilities for testing position↔value round-trip accuracy
enum RoundTripTester {
    
    /// Test round-trip accuracy for a single value on a scale
    /// - Parameters:
    ///   - value: The value to test
    ///   - scale: The scale definition
    ///   - tolerance: Relative error tolerance (default: 0.01)
    ///   - sourceLocation: Source location for error reporting
    static func testRoundTrip(
        value: Double,
        on scale: ScaleDefinition,
        tolerance: Double = TestTolerance.standard,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
        let recovered = ScaleCalculator.value(at: position, on: scale)
        let relativeError = abs(recovered - value) / max(abs(value), 0.001)
        
        #expect(
            relativeError < tolerance,
            "\(scale.name) scale: Value \(value) round-trip error \(relativeError) exceeds tolerance \(tolerance)",
            sourceLocation: sourceLocation
        )
    }
    
    /// Test round-trip accuracy for multiple values on a scale
    /// - Parameters:
    ///   - values: Array of values to test
    ///   - scale: The scale definition
    ///   - tolerance: Relative error tolerance (default: 0.01)
    static func testRoundTrips(
        values: [Double],
        on scale: ScaleDefinition,
        tolerance: Double = TestTolerance.standard,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for value in values {
            testRoundTrip(value: value, on: scale, tolerance: tolerance, sourceLocation: sourceLocation)
        }
    }
    
    /// Test position→value→position round-trip accuracy
    /// - Parameters:
    ///   - positions: Array of normalized positions to test
    ///   - scale: The scale definition
    ///   - tolerance: Position tolerance (default: varies by scale)
    static func testPositionRoundTrips(
        positions: [Double],
        on scale: ScaleDefinition,
        tolerance: Double = 0.0001,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for position in positions {
            let value = ScaleCalculator.value(at: position, on: scale)
            let computedPosition = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let error = abs(computedPosition - position)
            
            #expect(
                error < tolerance,
                "\(scale.name) scale position round-trip failed at \(position): error = \(error)",
                sourceLocation: sourceLocation
            )
        }
    }
}

// MARK: - Scale Comparison Utilities

/// Utilities for comparing related scales (parity testing)
enum ScaleComparator {
    
    /// Verify two scales produce identical positions for the same values
    /// - Parameters:
    ///   - scale1: First scale to compare
    ///   - scale2: Second scale to compare
    ///   - values: Values to test at
    ///   - tolerance: Position difference tolerance
    static func expectIdenticalPositions(
        _ scale1: ScaleDefinition,
        _ scale2: ScaleDefinition,
        at values: [Double],
        tolerance: Double = 0.0001,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for value in values {
            let pos1 = ScaleCalculator.normalizedPosition(for: value, on: scale1)
            let pos2 = ScaleCalculator.normalizedPosition(for: value, on: scale2)
            let difference = abs(pos1 - pos2)
            
            #expect(
                difference < tolerance,
                "\(scale1.name) and \(scale2.name) positions differ at value \(value): \(pos1) vs \(pos2)",
                sourceLocation: sourceLocation
            )
        }
    }
    
    /// Verify two scales have matching precision at corresponding positions
    /// - Parameters:
    ///   - scale1: First scale to compare
    ///   - scale2: Second scale to compare
    ///   - values: Values to test at
    static func expectMatchingPrecision(
        _ scale1: ScaleDefinition,
        _ scale2: ScaleDefinition,
        at values: [Double],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for value in values {
            let pos1 = ScaleCalculator.normalizedPosition(for: value, on: scale1)
            let pos2 = ScaleCalculator.normalizedPosition(for: value, on: scale2)
            
            let decimals1 = scale1.cursorDecimalPlaces(at: pos1)
            let decimals2 = scale2.cursorDecimalPlaces(at: pos2)
            
            #expect(
                decimals1 == decimals2,
                "\(scale1.name) and \(scale2.name) precision should match at value \(value)",
                sourceLocation: sourceLocation
            )
        }
    }
    
    /// Verify scale tick counts match (for parity tests)
    /// - Parameters:
    ///   - scale1: First scale
    ///   - scale2: Second scale
    ///   - allowedDifference: Maximum allowed difference in tick count
    static func expectSimilarTickCounts(
        _ scale1: ScaleDefinition,
        _ scale2: ScaleDefinition,
        allowedDifference: Int = 5,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let gen1 = GeneratedScale(definition: scale1)
        let gen2 = GeneratedScale(definition: scale2)
        
        let difference = abs(gen1.tickMarks.count - gen2.tickMarks.count)
        
        #expect(
            difference <= allowedDifference,
            "\(scale1.name) and \(scale2.name) tick counts differ by \(difference): \(gen1.tickMarks.count) vs \(gen2.tickMarks.count)",
            sourceLocation: sourceLocation
        )
    }
}

// MARK: - Boundary Testing Utilities

/// Utilities for testing scale boundary conditions
enum BoundaryTester {
    
    /// Test that scale begin/end values map to positions 0 and 1
    /// - Parameters:
    ///   - scale: Scale definition to test
    ///   - tolerance: Position tolerance
    static func expectCorrectBoundaries(
        _ scale: ScaleDefinition,
        tolerance: Double = 0.01,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let posBegin = ScaleCalculator.normalizedPosition(for: scale.beginValue, on: scale)
        let posEnd = ScaleCalculator.normalizedPosition(for: scale.endValue, on: scale)
        
        #expect(
            abs(posBegin) < tolerance,
            "\(scale.name) beginValue (\(scale.beginValue)) should map to position ~0, got \(posBegin)",
            sourceLocation: sourceLocation
        )
        
        #expect(
            abs(posEnd - 1.0) < tolerance,
            "\(scale.name) endValue (\(scale.endValue)) should map to position ~1, got \(posEnd)",
            sourceLocation: sourceLocation
        )
    }
    
    /// Test that position 0 yields beginValue and position 1 yields endValue
    /// - Parameters:
    ///   - scale: Scale definition to test
    ///   - tolerance: Value tolerance
    static func expectCorrectBoundaryValues(
        _ scale: ScaleDefinition,
        tolerance: Double = 0.01,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let valueAtStart = ScaleCalculator.value(at: 0.0, on: scale)
        let valueAtEnd = ScaleCalculator.value(at: 1.0, on: scale)
        
        let errorStart = abs(valueAtStart - scale.beginValue)
        let errorEnd = abs(valueAtEnd - scale.endValue)
        
        #expect(
            errorStart < tolerance,
            "\(scale.name) at position 0.0 should yield beginValue (\(scale.beginValue)): got \(valueAtStart), error = \(errorStart)",
            sourceLocation: sourceLocation
        )
        
        #expect(
            errorEnd < tolerance,
            "\(scale.name) at position 1.0 should yield endValue (\(scale.endValue)): got \(valueAtEnd), error = \(errorEnd)",
            sourceLocation: sourceLocation
        )
    }
}

// MARK: - Scale Instantiation Helpers

/// Quick access to commonly-used scale definitions for testing
enum CommonScales {
    
    // MARK: Basic Scales
    
    static func c(length:Double = 250.0) -> ScaleDefinition {
        StandardScales.cScale(length: length)
    }
    
    static func d(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.dScale(length: length)
    }
    
    static func ci(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ciScale(length: length)
    }
    
    static func di(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.diScale(length: length)
    }
    
    // MARK: Power Scales
    
    static func a(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.aScale(length: length)
    }
    
    static func b(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.bScale(length: length)
    }
    
    static func k(length: Double = 250.0) -> ScaleDefinition {
       StandardScales.kScale(length: length)
    }
    
    // MARK: Folded Scales
    
    static func cf(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.cfScale(length: length)
    }
    
    static func df(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.dfScale(length: length)
    }
    
    static func cif(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.cifScale(length: length)
    }
    
    static func dif(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.difScale(length: length)
    }
    
    // MARK: Trigonometric Scales
    
    static func s(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.sScale(length: length)
    }
    
    static func t(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.tScale(length: length)
    }
    
    static func st(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.stScale(length: length)
    }
    
    // MARK: Linear Scale
    
    static func l(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.lScale(length: length)
    }
}

// MARK: - Scale Test Data Infrastructure

/// Test data structure for systematic scale testing
struct ScaleTestData: Sendable {
    let name: String
    let scaleFactory: @Sendable (Double) -> ScaleDefinition
    let tolerance: Double
    let testPositions: [Double]
    let testValues: [Double]
    
    /// All standard scales for systematic testing
    static let allScales: [ScaleTestData] = standardScales + powerScales + foldedScales + logLogScales + trigScales + eeScales + hyperbolicScales
    
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
    
    /// Power scales (A, B, K)
    static let powerScales: [ScaleTestData] = [
        ScaleTestData(
            name: "A",
            scaleFactory: { StandardScales.aScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.squared
        ),
        ScaleTestData(
            name: "B",
            scaleFactory: { StandardScales.bScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.squared
        ),
        ScaleTestData(
            name: "K",
            scaleFactory: { StandardScales.kScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [1.0, 2.0, 5.0, 10.0, 100.0, 1000.0]
        )
    ]
    
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
    
    /// Log-Log scales (LL0, LL1, LL2, LL3, etc.)
    static let logLogScales: [ScaleTestData] = [
        ScaleTestData(
            name: "LL0",
            scaleFactory: { StandardScales.ll0Scale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [1.001, 1.005, 1.01, 1.02, 1.05, 1.10]
        ),
        ScaleTestData(
            name: "LL1",
            scaleFactory: { StandardScales.ll1Scale(length: $0) },
            tolerance: TestTolerance.strict,
            testPositions: TestValues.positions,
            testValues: [1.10, 1.2, 1.35, 2.0, 2.5, 2.718]
        ),
        ScaleTestData(
            name: "LL2",
            scaleFactory: { StandardScales.ll2Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [2.8, 5.0, 10.0, 15.0, 20.0]
        ),
        ScaleTestData(
            name: "LL3",
            scaleFactory: { StandardScales.ll3Scale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: [22.0, 100.0, 500.0, 1000.0, 20000.0]
        )
    ]
    
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
    
    /// Electrical Engineering scales (basic set)
    static let eeScales: [ScaleTestData] = [
        ScaleTestData(
            name: "ω",
            scaleFactory: { StandardScales.angularFrequencyOmegaScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 5.0, 10.0, 50.0, 100.0]
        ),
        ScaleTestData(
            name: "τ",
            scaleFactory: { StandardScales.timeConstantTauScale(length: $0) },
            tolerance: TestTolerance.eeScale,
            testPositions: TestValues.positions,
            testValues: [1.0, 5.0, 10.0, 50.0, 100.0]
        )
    ]
    
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

// MARK: - Parity Testing Infrastructure

/// Helper infrastructure for testing scale parity relationships
enum ParityTestHelper {
    
    /// Data structure representing a pair of scales that should have identical positioning
    struct ScalePair: Sendable {
        let name1: String
        let scale1Factory: @Sendable (Double) -> ScaleDefinition
        let name2: String
        let scale2Factory: @Sendable (Double) -> ScaleDefinition
        let testValues: [Double]
        let tolerance: Double
        
        /// Create scales with default length
        func createScales(length: Double = 250.0) -> (ScaleDefinition, ScaleDefinition) {
            (scale1Factory(length), scale2Factory(length))
        }
    }
    
    /// Predefined parity pairs for common scale relationships
    static let parityPairs: [ScalePair] = [
        // Standard scale pairs
        ScalePair(
            name1: "C", scale1Factory: { StandardScales.cScale(length: $0) },
            name2: "D", scale2Factory: { StandardScales.dScale(length: $0) },
            testValues: TestValues.logarithmic,
            tolerance: 1e-9
        ),
        ScalePair(
            name1: "CI", scale1Factory: { StandardScales.ciScale(length: $0) },
            name2: "DI", scale2Factory: { StandardScales.diScale(length: $0) },
            testValues: TestValues.inverted,
            tolerance: 1e-9
        ),
        // Power scale pairs
        ScalePair(
            name1: "A", scale1Factory: { StandardScales.aScale(length: $0) },
            name2: "B", scale2Factory: { StandardScales.bScale(length: $0) },
            testValues: TestValues.squared,
            tolerance: 1e-9
        ),
        ScalePair(
            name1: "AI", scale1Factory: { StandardScales.aiScale(length: $0) },
            name2: "BI", scale2Factory: { StandardScales.biScale(length: $0) },
            testValues: TestValues.squared,
            tolerance: 1e-9
        ),
        // Folded scale pairs
        ScalePair(
            name1: "CF", scale1Factory: { StandardScales.cfScale(length: $0) },
            name2: "DF", scale2Factory: { StandardScales.dfScale(length: $0) },
            testValues: TestValues.folded,
            tolerance: 1e-9
        ),
        ScalePair(
            name1: "CIF", scale1Factory: { StandardScales.cifScale(length: $0) },
            name2: "DIF", scale2Factory: { StandardScales.difScale(length: $0) },
            testValues: TestValues.folded,
            tolerance: 1e-9
        )
    ]
    
    /// Test complete parity between two scales
    /// - Parameter pair: The scale pair to test
    /// - Parameter length: Scale length to use (default: 250.0)
    static func testCompleteParity(
        _ pair: ScalePair,
        length: Double = 250.0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let (scale1, scale2) = pair.createScales(length: length)
        
        // Test position parity
        ScaleComparator.expectIdenticalPositions(
            scale1, scale2,
            at: pair.testValues,
            tolerance: pair.tolerance,
            sourceLocation: sourceLocation
        )
        
        // Test tick count parity
        ScaleComparator.expectSimilarTickCounts(
            scale1, scale2,
            allowedDifference: 0,  // Parity scales should have identical tick counts
            sourceLocation: sourceLocation
        )
    }
    
    /// Test all predefined parity pairs
    static func testAllParityPairs(
        length: Double = 250.0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for pair in parityPairs {
            testCompleteParity(pair, length: length, sourceLocation: sourceLocation)
        }
    }
}
