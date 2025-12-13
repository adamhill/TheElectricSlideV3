import Testing
import Foundation
@testable import SlideRuleCoreV3

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
