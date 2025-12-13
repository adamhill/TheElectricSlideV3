import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData All Scales Extension

extension ScaleTestData {
    /// All standard scales for systematic testing
    static let allScales: [ScaleTestData] =
        standardScales +
        powerScales +
        foldedScales +
        logLogScales +
        trigScales +
        eeScales +
        hyperbolicScales +
        standardScalesExtended +
        negativeLogLogScales +
        hyperbolicScalesExtended +
        pickettN16ESScales +
        eeScalesExtended +
        powerInvertedScales +
        dfmVariantScales
}
