import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("Parser — scale-count across bracket placements")
struct SlideRuleAssemblyParserCountTests {
    
    // Shared dimensions for all tests
    static let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    // Helper to count total scales on the front side
    private func totalFrontScales(for rule: SlideRule) -> Int {
        rule.frontTopStator.scales.count +
        rule.frontSlide.scales.count +
        rule.frontBottomStator.scales.count
    }
    
    @Test("Four-scale parser — bracketed dual-slide group increases count to four",
          arguments: zip(
            [
                "(C [ D ] A)",          // 1 + 1 + 1 = 3
                "(C [ D CI ] A)"        // 1 + 2 + 1 = 4
            ],
            [3, 4]
          ))
    func bracketedDualSlideIncreases(definition: String, expectedCount: Int) throws {
        let rule = try RuleDefinitionParser.parse(definition, dimensions: Self.dims)
        let totalScales = totalFrontScales(for: rule)
        #expect(totalScales == expectedCount)
    }
    
    @Test("Four-scale parser — two top scales with single slide yields four",
          arguments: zip(
            [
                "(C D [ CI ] A)",       // 2 + 1 + 1 = 4
                "(LL1 LL2 [ C ] D)"     // 2 + 1 + 1 = 4
            ],
            [4, 4]
          ))
    func twoTopSingleSlideYieldsFour(definition: String, expectedCount: Int) throws {
        let rule = try RuleDefinitionParser.parse(definition, dimensions: Self.dims)
        let totalScales = totalFrontScales(for: rule)
        #expect(totalScales == expectedCount)
    }
    
    @Test("Four-scale parser — two bottom scales with single slide yields four",
          arguments: zip(
            [
                "(C [ D ] A B)"         // 1 + 1 + 2 = 4
            ],
            [4]
          ))
    func twoBottomSingleSlideYieldsFour(definition: String, expectedCount: Int) throws {
        let rule = try RuleDefinitionParser.parse(definition, dimensions: Self.dims)
        let totalScales = totalFrontScales(for: rule)
        #expect(totalScales == expectedCount)
    }
    
    @Test("Four-scale parser — bracketed dual-slide group yields four with LL placement",
          arguments: zip(
            [
                "(LL1 [ LL2 LL3 ] D)"   // 1 + 2 + 1 = 4
            ],
            [4]
          ))
    func dualSlideWithLLPlacementYieldsFour(definition: String, expectedCount: Int) throws {
        let rule = try RuleDefinitionParser.parse(definition, dimensions: Self.dims)
        let totalScales = totalFrontScales(for: rule)
        #expect(totalScales == expectedCount)
    }
    
    @Test("Parser count — dual slide plus two tops yields five (expected)",
          arguments: zip(
            [
                "(LL1 LL2 [ LL3 C ] D)" // 2 + 2 + 1 = 5
            ],
            [5]
          ))
    func fiveScaleCaseExpected(definition: String, expectedCount: Int) throws {
        let rule = try RuleDefinitionParser.parse(definition, dimensions: Self.dims)
        let totalScales = totalFrontScales(for: rule)
        #expect(totalScales == expectedCount)
    }
}
