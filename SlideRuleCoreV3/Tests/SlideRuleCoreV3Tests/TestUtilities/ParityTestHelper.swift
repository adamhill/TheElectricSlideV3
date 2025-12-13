import Testing
import Foundation
@testable import SlideRuleCoreV3

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
