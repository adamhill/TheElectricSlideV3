import Testing
@testable import SlideRuleCoreV3

/// Tests for W scale label display (Faber-Castell 62/83N aliases)
/// Verifies that alias scales preserve their original names from the definition string
@Suite("W Scale Label Display Tests")
struct WScaleLabelTests {
    
    @Test("W2 scale displays as W2 not Sq2")
    func w2ScaleDisplayName() throws {
        // Parse Faber-Castell 62/83N definition with W2 alias
        let definition = "LL03 LL02 LL01 LL00 W2 [ W2' CI L C W1' ] W1 D^ LL0 LL1 LL2 LL3"
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let slideRule = try RuleDefinitionParser.parse(
            "(\(definition))",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        // W2 should be in top stator
        let w2Scale = slideRule.frontTopStator.scales.first { scale in
            (scale.definition.displayName ?? scale.definition.name) == "W2"
        }
        
        #expect(w2Scale != nil, "W2 scale should be found in top stator")
        #expect(w2Scale?.definition.displayName == "W2", "W2 should have displayName set to W2")
        #expect(w2Scale?.definition.name == "Sq2", "W2 should use Sq2 canonical implementation")
    }
    
    @Test("W2' scale displays as W2' not Sq2")
    func w2PrimeScaleDisplayName() throws {
        let definition = "LL03 LL02 LL01 LL00 W2 [ W2' CI L C W1' ] W1 D^ LL0 LL1 LL2 LL3"
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let slideRule = try RuleDefinitionParser.parse(
            "(\(definition))",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        // W2' should be in slide
        let w2PrimeScale = slideRule.frontSlide.scales.first { scale in
            (scale.definition.displayName ?? scale.definition.name) == "W2'"
        }
        
        #expect(w2PrimeScale != nil, "W2' scale should be found in slide")
        #expect(w2PrimeScale?.definition.displayName == "W2'", "W2' should have displayName set to W2'")
        #expect(w2PrimeScale?.definition.name == "Sq2", "W2' should use Sq2 canonical implementation")
    }
    
    @Test("W1' scale displays as W1' not Sq1")
    func w1PrimeScaleDisplayName() throws {
        let definition = "LL03 LL02 LL01 LL00 W2 [ W2' CI L C W1' ] W1 D^ LL0 LL1 LL2 LL3"
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let slideRule = try RuleDefinitionParser.parse(
            "(\(definition))",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        // W1' should be in slide
        let w1PrimeScale = slideRule.frontSlide.scales.first { scale in
            (scale.definition.displayName ?? scale.definition.name) == "W1'"
        }
        
        #expect(w1PrimeScale != nil, "W1' scale should be found in slide")
        #expect(w1PrimeScale?.definition.displayName == "W1'", "W1' should have displayName set to W1'")
        #expect(w1PrimeScale?.definition.name == "Sq1", "W1' should use Sq1 canonical implementation")
    }
    
    @Test("W1 scale displays as W1 not Sq1")
    func w1ScaleDisplayName() throws {
        let definition = "LL03 LL02 LL01 LL00 W2 [ W2' CI L C W1' ] W1 D^ LL0 LL1 LL2 LL3"
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let slideRule = try RuleDefinitionParser.parse(
            "(\(definition))",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        // W1 should be in bottom stator
        let w1Scale = slideRule.frontBottomStator.scales.first { scale in
            (scale.definition.displayName ?? scale.definition.name) == "W1"
        }
        
        #expect(w1Scale != nil, "W1 scale should be found in bottom stator")
        #expect(w1Scale?.definition.displayName == "W1", "W1 should have displayName set to W1")
        #expect(w1Scale?.definition.name == "Sq1", "W1 should use Sq1 canonical implementation")
    }
    
    @Test("Non-aliased scales have nil displayName")
    func nonAliasedScalesNoDisplayName() throws {
        let definition = "C D [ CI ] A"
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let slideRule = try RuleDefinitionParser.parse(
            "(\(definition))",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        // Check all scales have nil displayName (they're not aliases)
        for scale in slideRule.frontTopStator.scales {
            #expect(scale.definition.displayName == nil, 
                   "Non-aliased scale \(scale.definition.name) should have nil displayName")
        }
        
        for scale in slideRule.frontSlide.scales {
            #expect(scale.definition.displayName == nil,
                   "Non-aliased scale \(scale.definition.name) should have nil displayName")
        }
        
        for scale in slideRule.frontBottomStator.scales {
            #expect(scale.definition.displayName == nil,
                   "Non-aliased scale \(scale.definition.name) should have nil displayName")
        }
    }
    
    @Test("W1P variant (alternate W1' notation) displays correctly")
    func w1pVariantDisplayName() throws {
        // Test W1P notation (another way to write W1')
        let definition = "W1P"
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15
        )
        
        let slideRule = try RuleDefinitionParser.parse(
            "(\(definition))",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        let scale = slideRule.frontTopStator.scales.first
        #expect(scale != nil, "W1P scale should be parsed")
        #expect(scale?.definition.displayName == "W1P", "W1P should have displayName set")
        #expect(scale?.definition.name == "Sq1", "W1P should use Sq1 implementation")
    }
}