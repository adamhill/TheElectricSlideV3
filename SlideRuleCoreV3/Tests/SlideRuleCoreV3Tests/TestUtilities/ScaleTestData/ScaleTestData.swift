import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Scale Test Data Infrastructure

/// Test data structure for systematic scale testing
struct ScaleTestData: Sendable {
    let name: String
    let scaleFactory: @Sendable (Double) -> ScaleDefinition
    let tolerance: Double
    let testPositions: [Double]
    let testValues: [Double]
}
