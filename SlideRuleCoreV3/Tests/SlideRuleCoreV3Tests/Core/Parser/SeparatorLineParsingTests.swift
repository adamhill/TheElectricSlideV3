import Testing
@testable import SlideRuleCoreV3

/// Tests for parsing separator line (`|`) symbol in slide rule definitions
@Suite("Separator Line Parsing Tests")
struct SeparatorLineParsingTests {
    
    // MARK: - Basic Separator Parsing
    
    @Test("Parse single separator between two scales")
    func parseSingleSeparator() throws {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 10,
            slideMM: 10,
            bottomStatorMM: 10
        )
        
        // Parse "S | T-" - should mark S with hasBottomSeparator
        let rule = try RuleDefinitionParser.parse(
            "(S | T-)",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        let topScales = rule.frontTopStator.scales
        #expect(topScales.count == 2, "Should have 2 scales")
        
        // First scale (S) should have hasBottomSeparator = true
        #expect(topScales[0].definition.name == "S")
        #expect(topScales[0].definition.hasBottomSeparator == true,
                "S scale should have bottom separator")
        
        // Second scale (T) should have noLineBreak = true
        #expect(topScales[1].definition.name == "T")
        #expect(topScales[1].noLineBreak == true,
                "T scale should have noLineBreak")
        #expect(topScales[1].definition.hasBottomSeparator == false,
                "T scale should NOT have bottom separator")
    }
    
    @Test("Parse multiple separators in definition")
    func parseMultipleSeparators() throws {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        // DSP-01 Duplex front side: "(P DFm+ K A [ B ST S | T- CI ] D DI L | Ln-)"
        let rule = try RuleDefinitionParser.parse(
            "(P DFm+ K A [ B ST S | T- CI ] D DI L | Ln-)",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        // Check slide scales for S | T separator
        let slideScales = rule.frontSlide.scales
        let sIndex = slideScales.firstIndex { $0.definition.name == "S" }
        let tIndex = slideScales.firstIndex { $0.definition.name == "T" }
        
        #expect(sIndex != nil, "S scale should exist in slide")
        #expect(tIndex != nil, "T scale should exist in slide")
        
        if let sIndex = sIndex {
            #expect(slideScales[sIndex].definition.hasBottomSeparator == true,
                    "S scale should have bottom separator")
        }
        
        if let tIndex = tIndex {
            #expect(slideScales[tIndex].noLineBreak == true,
                    "T scale should have noLineBreak")
        }
        
        // Check bottom stator for L | Ln separator
        let bottomScales = rule.frontBottomStator.scales
        let lIndex = bottomScales.firstIndex { $0.definition.name == "L" }
        let lnIndex = bottomScales.firstIndex { $0.definition.name == "Ln" }
        
        #expect(lIndex != nil, "L scale should exist in bottom stator")
        #expect(lnIndex != nil, "Ln scale should exist in bottom stator")
        
        if let lIndex = lIndex {
            #expect(bottomScales[lIndex].definition.hasBottomSeparator == true,
                    "L scale should have bottom separator")
        }
        
        if let lnIndex = lnIndex {
            #expect(bottomScales[lnIndex].noLineBreak == true,
                    "Ln scale should have noLineBreak")
        }
    }
    
    @Test("Separator at beginning of component (edge case)")
    func separatorAtBeginning() throws {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 10,
            slideMM: 10,
            bottomStatorMM: 10
        )
        
        // Edge case: separator at very beginning (should not crash or mark non-existent scale)
        let rule = try RuleDefinitionParser.parse(
            "(| C D)",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        let topScales = rule.frontTopStator.scales
        #expect(topScales.count == 2, "Should have 2 scales (C and D)")
        
        // First scale should not have separator (nothing before |)
        #expect(topScales[0].definition.name == "C")
        #expect(topScales[0].definition.hasBottomSeparator == false,
                "C scale should NOT have separator (| was at beginning)")
        #expect(topScales[0].noLineBreak == true,
                "C scale should have noLineBreak from |")
    }
    
    @Test("Separator with tick direction modifiers")
    func separatorWithModifiers() throws {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 10,
            slideMM: 10,
            bottomStatorMM: 10
        )
        
        // Parse "K+ | A-" - should handle both separator and tick direction modifiers
        let rule = try RuleDefinitionParser.parse(
            "(K+ | A-)",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        let topScales = rule.frontTopStator.scales
        #expect(topScales.count == 2)
        
        // K should have hasBottomSeparator and tickDirection up
        #expect(topScales[0].definition.name == "K")
        #expect(topScales[0].definition.hasBottomSeparator == true)
        #expect(topScales[0].definition.tickDirection == .up)
        
        // A should have noLineBreak and tickDirection down
        #expect(topScales[1].definition.name == "A")
        #expect(topScales[1].noLineBreak == true)
        #expect(topScales[1].definition.tickDirection == .down)
    }
    
    // MARK: - Circular Rule Separator Preservation
    
    @Test("Separator flag preserved in circular conversion")
    func separatorInCircularRule() throws {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 12,
            slideMM: 16,
            bottomStatorMM: 8
        )
        
        let rule = try RuleDefinitionParser.parseWithCircular(
            "(A [ C | CI ] D) circular:4inch",
            dimensions: dimensions
        )
        
        #expect(rule.isCircular, "Rule should be circular")
        
        let slideScales = rule.frontSlide.scales
        let cIndex = slideScales.firstIndex { $0.definition.name == "C" }
        let ciIndex = slideScales.firstIndex { $0.definition.name == "CI" }
        
        if let cIndex = cIndex {
            #expect(slideScales[cIndex].definition.hasBottomSeparator == true,
                    "C scale separator should be preserved in circular layout")
            #expect(slideScales[cIndex].definition.layout.isCircular,
                    "C scale should have circular layout")
        }
        
        if let ciIndex = ciIndex {
            #expect(slideScales[ciIndex].noLineBreak == true,
                    "CI scale noLineBreak should be preserved in circular layout")
        }
    }
}
