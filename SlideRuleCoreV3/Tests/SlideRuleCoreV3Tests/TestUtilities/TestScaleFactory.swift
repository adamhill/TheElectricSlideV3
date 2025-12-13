import Testing
import Foundation
@testable import SlideRuleCoreV3

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
