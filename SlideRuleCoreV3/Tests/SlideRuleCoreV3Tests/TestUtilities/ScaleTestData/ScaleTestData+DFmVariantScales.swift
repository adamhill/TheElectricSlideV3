import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - ScaleTestData DFm Variant Scales

extension ScaleTestData {
    /// DFm PostScript variant scale
    static let dfmVariantScales: [ScaleTestData] = [
        ScaleTestData(
            name: "DFmPostScript",
            scaleFactory: { StandardScales.dfmPostScriptScale(length: $0) },
            tolerance: TestTolerance.standard,
            testPositions: TestValues.positions,
            testValues: TestValues.folded
        )
    ]
}
