import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive fuzz testing for SlideRule assembly definitions
/// Tests hundreds of valid scale combinations including exotic scales
/// Following Swift Testing Playbook with storytelling test names
@Suite("SlideRule Assembly Fuzz Testing")
struct SlideRuleAssemblyFuzzTests {
    
    // MARK: - Test Dimensions
    
    static let standardDimensions = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    static let circularDimensions = RuleDefinitionParser.Dimensions(
        topStatorMM: 12,
        slideMM: 16,
        bottomStatorMM: 8
    )
    
    // MARK: - Two-Scale Combinations
    
    @Suite("Standard Two-Scale Combinations Fuzz Tests")
    struct TwoScaleCombinations {
        
        @Test("Two-scale combinations parse successfully for all standard scale pairs",
              arguments: generateTwoScaleCombinations())
        func twoScaleCombinationsParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parse(definition, dimensions: standardDimensions)
            
            // Verify rule has expected structure
            let totalScales = rule.frontTopStator.scales.count + 
                            rule.frontSlide.scales.count + 
                            rule.frontBottomStator.scales.count
            #expect(totalScales == 2, "Expected 2 scales, got \(totalScales)")
            
            // Verify all scales have tick marks
            for scale in rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(scale.definition.name) has no tick marks")
            }
        }
        
        static func generateTwoScaleCombinations() -> [String] {
            let scales = ["C", "D", "CI", "A", "K", "S", "T", "L", "LL1", "LL2", "LL3"]
            var combinations: [String] = []
            
            // Generate all pairwise combinations
            for i in 0..<scales.count {
                for j in i+1..<scales.count {
                    combinations.append("(\(scales[i]) [ \(scales[j]) ])")
                }
            }
            
            return combinations
        }
    }
    
    // MARK: - Three-Scale Combinations
    
    @Suite("Three-Scale Combinations Fuzz Tests")
    struct ThreeScaleCombinations {
        
        @Test("Three-scale combinations parse successfully with diverse scale arrangements",
              arguments: generateThreeScaleCombinations())
        func threeScaleCombinationsParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parse(definition, dimensions: standardDimensions)
            
            let totalScales = rule.frontTopStator.scales.count + 
                            rule.frontSlide.scales.count + 
                            rule.frontBottomStator.scales.count
            #expect(totalScales == 3, "Expected 3 scales, got \(totalScales)")
            
            // Verify all scales are valid
            for scale in rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(scale.definition.name) has no tick marks")
            }
        }
        
        static func generateThreeScaleCombinations() -> [String] {
            [
                "(C D [ CI ])",
                "(A K [ C ])",
                "(C [ D ] A)",
                "(K [ A ] B)",
                "(LL1 [ LL2 ] LL3)",
                "(S T [ ST ])",
                "(C CI [ CF ])",
                "(D DF [ CIF ])",
                "(A [ B ] K)",
                "(L [ C ] D)",
                "(LL1 LL2 [ LL3 ])",
                "(S [ T ] ST)",
                "(C [ CI ] D)",
                "(A B [ K ])",
                "(CF [ CIF ] CI)",
                "(LL1 [ LL3 ] LL2)",
                "(T [ S ] ST)",
                "(D [ C ] CI)",
                "(K [ B ] A)",
                "(DF [ CF ] D)",
                "(LL2 [ LL1 ] LL3)",
                "(ST [ S ] T)",
                "(CI [ C ] CF)",
                "(B [ A ] K)",
                "(CIF [ DF ] CF)",
                "(LL3 [ LL2 ] LL1)",
                "(S T [ L ])",
                "(C D [ L ])",
                "(A K [ LN ])",
                "(LL1 LL2 [ C ])"
            ]
        }
    }
    
    // MARK: - Four-Scale Combinations
    
    @Suite("Four-Scale Combinations Fuzz Tests")
    struct FourScaleCombinations {
        
        @Test("Four-scale parser — canonical combos produce exactly four scales",
              arguments: generateFourScaleCombinations())
        func fourScaleCombinationsParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parse(definition, dimensions: standardDimensions)
            
            let totalScales = rule.frontTopStator.scales.count + 
                            rule.frontSlide.scales.count + 
                            rule.frontBottomStator.scales.count
            #expect(totalScales == 4, "Expected 4 scales, got \(totalScales)")
            
            // Verify balanced layout
            #expect(rule.frontSlide.scales.count >= 1, "Slide should have at least one scale")
            
            for scale in rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(scale.definition.name) has no tick marks")
            }
        }
        
        static func generateFourScaleCombinations() -> [String] {
            let canonicalCandidates: [String] = [
                "(C [ D CI ] A)",          // 1 + 2 + 1 = 4  (replaced E with CI)
                "(C D [ CI ] A)",          // 2 + 1 + 1 = 4  (replaced E with CI)
                "(A B [ CI ] D)",         // 2 + 1 + 1 = 4
                "(C [ CI ] A B)",         // 1 + 1 + 2 = 4
                "(A [ B C ] D)",          // 1 + 2 + 1 = 4
                "(LL1 LL2 [ C ] D)",      // 2 + 1 + 1 = 4
                "(LL1 [ LL2 ] C D)",      // 1 + 1 + 2 = 4
                "(K [ A ] B C)",          // 1 + 1 + 2 = 4
                "(S [ T ST ] L)",         // 1 + 2 + 1 = 4
                "(C [ LL1 ] LL2 LL3)",    // 1 + 1 + 2 = 4
                "(LL1 LL2 [ LL3 ] C)",    // 2 + 1 + 1 = 4
                "(CF [ CI ] D K)"         // 1 + 1 + 2 = 4
            ]
            
            // Enforce exactly-four by construction via lightweight segment counting (no production parser)
            let filtered = canonicalCandidates.filter { def in
                let counts = countSegments(def)
                return (counts.top + counts.slide + counts.bottom) == 4 && counts.slide >= 1
            }
            
            // Deduplicate while preserving order
            var seen = Set<String>()
            return filtered.filter { seen.insert($0).inserted }
        }
        
        // Count tokens in TOP / SLIDE / BOTTOM without invoking the production parser.
        // Canonical structure assumed: \"( TOP … [ SLIDE … ] BOTTOM … )\"
        private static func countSegments(_ definition: String) -> (top: Int, slide: Int, bottom: Int) {
            // Consider only the front side (ignore anything after ':')
            let front = definition.split(separator: ":").first.map(String.init) ?? definition
            // Strip parentheses and trim
            let trimmed = front
                .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let open = trimmed.firstIndex(of: "["), let close = trimmed.firstIndex(of: "]"), open < close else {
                // No brackets: everything counts as top
                let t = countTokens(in: trimmed)
                return (t, 0, 0)
            }
            
            let topSegment = String(trimmed[..<open])
            let slideSegment = String(trimmed[trimmed.index(after: open)..<close])
            let bottomSegment = String(trimmed[trimmed.index(after: close)...])
            
            return (
                countTokens(in: topSegment),
                countTokens(in: slideSegment),
                countTokens(in: bottomSegment)
            )
        }
        
        private static func countTokens(in segment: String) -> Int {
            segment.split(whereSeparator: { $0.isWhitespace }).count
        }
    }
    
    // MARK: - Exotic Scale Combinations
    
    @Suite("Exotic Scale Combinations Fuzz Tests")
    struct ExoticScaleCombinations {
        
        @Test("Exotic scale combinations including hyperbolic and power scales parse correctly",
              arguments: generateExoticCombinations())
        func exoticScaleCombinationsParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parse(definition, dimensions: standardDimensions)
            
            // Verify rule parsed successfully
            let totalScales = rule.frontTopStator.scales.count + 
                            rule.frontSlide.scales.count + 
                            rule.frontBottomStator.scales.count
            #expect(totalScales > 0, "Rule should have at least one scale")
            
            // Verify all scales are valid
            for scale in rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(scale.definition.name) has no tick marks")
            }
        }
        
        static func generateExoticCombinations() -> [String] {
            [
                // LL scale progressions
                "(LL1 LL2 [ LL3 ])",
                "(LL1 [ LL2 ] LL3)",
                "([ LL1 LL2 LL3 ])",
                "(C [ LL1 ] D)",
                "(LL1 [ C ] LL2)",
                "(LL2 LL3 [ C ])",
                "(LL1 [ LL3 ] C)",
                
                // Hyperbolic combinations
                "(Sh Ch [ Th ])",
                "(Sh [ Ch ] Th)",
                "([ Sh Ch ])",
                "(C [ Sh ] D)",
                "(Sh [ C ] Ch)",
                "(Ch [ Th ] C)",
                "(Sh Th [ C ])",
                
                // PA scale variations
                "(PA [ C ] D)",
                "(C [ PA ] D)",
                "(PA C [ D ])",
                "([ PA C ])",
                "(A [ PA ] B)",
                "(PA [ A ] K)",
                
                // P scale with squares
                "(P [ A ] B)",
                "(A [ P ] B)",
                "(P A [ B ])",
                "([ P A ])",
                "(P [ B ] K)",
                
                // Mixed trig
                "(S T [ ST ])",
                "(ST [ S ] T)",
                "(S [ ST ] T)",
                
                // Extended trig (KE variants)
                "(KE-S [ KE-T ] SRT)",
                "(KE-S KE-T [ SRT ])",
                "([ KE-S KE-T ])",
                "(C [ KE-S ] D)",
                "(KE-T [ SRT ] C)",
                "(SRT [ C ] D)",
                
                // Combined sine/cosine
                "(CR3S [ C ] D)",
                "(C [ CR3S ] D)",
                "(CR3S C [ D ])",
                
                // Square root scales
                "(R1 [ R2 ] C)",
                "(R1 R2 [ C ])",
                "([ R1 R2 ])",
                "(C [ R1 ] D)",
                "(R2 [ C ] D)",
                
                // Cube root scales
                "(Q1 [ Q2 ] Q3)",
                "(Q1 Q2 [ Q3 ])",
                "([ Q1 Q2 Q3 ])",
                "(C [ Q1 ] D)",
                "(Q2 [ C ] Q3)",
                
                // B, BI, AI scales
                "(B [ BI ] AI)",
                "(AI [ B ] BI)",
                "(B BI [ AI ])",
                "([ B AI ])",
                "(A [ AI ] B)",
                "(B [ A ] AI)",
                
                // Time scales
                "(TIME [ C ] D)",
                "(C [ TIME ] D)",
                "(TIME TIME2 [ C ])",
                "([ TIME TIME2 ])",
                
                // Aviation scales
                "(CAS [ C ] D)",
                "(C [ CAS ] D)",
                "(CAS C [ D ])",
                
                // Extended range scales
                "(C10-100 [ D10-100 ] C)",
                "(C100-1000 [ C ] D)",
                
                // Complex exotic combinations
                "(LL1 Sh [ PA ] C)",
                "(P KE-S [ Q1 ] D)",
                "(Sh Ch [ PA P ])",
                "(LL1 LL2 [ Sh Ch ])",
                "(KE-S KE-T [ Sh ])",
                "(R1 R2 [ PA ])",
                "(Q1 Q2 [ LL1 ])",
                "(B AI [ Sh ])",
                "(TIME [ CAS ] D)",
                "(CR3S [ PA ] P)"
            ]
        }
    }
    
    // MARK: - Circular Rule Fuzz Tests
    
    @Suite("Circular Rule Fuzz Tests")
    struct CircularRuleCombinations {
        
        @Test("Circular rule combinations parse successfully and create proper circular layouts",
              arguments: generateCircularCombinations())
        func circularRuleCombinationsParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parseWithCircular(
                definition, 
                dimensions: circularDimensions
            )
            
            // Verify circular properties
            #expect(rule.isCircular, "Rule should be circular")
            #expect(rule.diameter != nil, "Circular rule should have diameter")
            #expect(rule.diameter! > 0, "Diameter should be positive")
            
            // Verify all scales are circular
            for scale in rule.frontTopStator.scales {
                #expect(scale.definition.isCircular, "Scale \(scale.definition.name) should be circular")
                #expect(!scale.tickMarks.isEmpty, "Circular scale \(scale.definition.name) has no tick marks")
            }
            for scale in rule.frontSlide.scales {
                #expect(scale.definition.isCircular, "Scale \(scale.definition.name) should be circular")
                #expect(!scale.tickMarks.isEmpty, "Circular scale \(scale.definition.name) has no tick marks")
            }
            for scale in rule.frontBottomStator.scales {
                #expect(scale.definition.isCircular, "Scale \(scale.definition.name) should be circular")
                #expect(!scale.tickMarks.isEmpty, "Circular scale \(scale.definition.name) has no tick marks")
            }
        }
        
        static func generateCircularCombinations() -> [String] {
            [
                // Basic circular rules
                "(A [ C ] CI) circular:4inch",
                "(C [ D ] CI) circular:4inch",
                "(K [ A ] B) circular:5inch",
                "(C D [ CI ]) circular:144",
                
                // LL scales on circular rules
                "(LL1 [ LL2 ] LL3) circular:4inch",
                "(LL1 LL2 [ LL3 ]) circular:5inch",
                "(C [ LL1 ] LL2) circular:4inch",
                "(LL1 [ C ] D) circular:288",
                
                // Different diameter specifications
                "(C [ D ] A) circular:3inch",
                "(C [ D ] A) circular:6inch",
                "(C [ D ] A) circular:100mm",
                "(C [ D ] A) circular:200mm",
                "(C [ D ] A) circular:10cm",
                "(C [ D ] A) circular:20cm",
                "(C [ D ] A) circular:144",
                "(C [ D ] A) circular:288",
                "(C [ D ] A) circular:432",
                
                // Exotic scales on circular rules
                "(Sh [ Ch ] Th) circular:4inch",
                "(PA [ C ] D) circular:4inch",
                "(P [ A ] B) circular:5inch",
                "(KE-S [ KE-T ] SRT) circular:4inch",
                "(CR3S [ C ] D) circular:4inch",
                "(R1 [ R2 ] C) circular:4inch",
                "(Q1 [ Q2 ] Q3) circular:5inch",
                "(B [ AI ] BI) circular:4inch",
                "(TIME [ C ] D) circular:4inch",
                "(CAS [ C ] D) circular:4inch"
            ]
        }
    }
    
    // MARK: - Back-Sided Rule Combinations
    
    @Suite("Back-Sided Rule Fuzz Tests")
    struct BackSidedCombinations {
        
        @Test("Back-sided rules parse successfully with independent front and back configurations",
              arguments: generateBackSidedCombinations())
        func backSidedRulesParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parse(definition, dimensions: standardDimensions)
            
            // Verify front side exists
            let frontTotal = rule.frontTopStator.scales.count + 
                           rule.frontSlide.scales.count + 
                           rule.frontBottomStator.scales.count
            #expect(frontTotal > 0, "Front side should have scales")
            
            // Verify back side exists
            #expect(rule.backTopStator != nil, "Back top stator should exist")
            #expect(rule.backSlide != nil, "Back slide should exist")
            #expect(rule.backBottomStator != nil, "Back bottom stator should exist")
            
            let backTotal = (rule.backTopStator?.scales.count ?? 0) + 
                          (rule.backSlide?.scales.count ?? 0) + 
                          (rule.backBottomStator?.scales.count ?? 0)
            #expect(backTotal > 0, "Back side should have scales")
            
            // Verify all scales are valid - break up into separate collections
            let frontScales = rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales
            let backScales = (rule.backTopStator?.scales ?? []) + 
                           (rule.backSlide?.scales ?? []) + 
                           (rule.backBottomStator?.scales ?? [])
            
            for scale in frontScales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(String(scale.definition.name)) has no tick marks")
            }
            
            for scale in backScales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(String(scale.definition.name)) has no tick marks")
            }
        }
        
        static func generateBackSidedCombinations() -> [String] {
            [
                // Simple back-sided rules
                "(C [ D ] A : LL1 [ LL2 ] LL3)",
                "(K A [ C ] D : S [ T ] ST)",
                "(C D [ CI ] CF : DF [ CIF ] L)",
                "(A B [ C ] D : K [ CI ] CF)",
                "(C [ CI ] D : LL1 [ LL2 ] LL3)",
                
                // Complex back-sided rules
                "(K A B [ C CI CF CIF ] D DF L : LL1 LL2 LL3 [ S T ST ] CI)",
                "(C D CF [ CI CIF DF ] A K : LL1 LL2 [ LL3 S ] T)",
                "(A B K [ C D ] CI CF : LL1 [ LL2 LL3 ] S T)",
                
                // Exotic scales on back
                "(C [ D ] A : Sh [ Ch ] Th)",
                "(C [ D ] A : PA [ P ] C)",
                "(C [ D ] A : KE-S [ KE-T ] SRT)",
                "(C [ D ] A : R1 [ R2 ] C)",
                "(C [ D ] A : Q1 [ Q2 ] Q3)",
                "(C [ D ] A : B [ AI ] BI)",
                "(C [ D ] A : TIME [ TIME2 ] C)"
            ]
        }
    }
    
    // MARK: - Mixed Circular/Linear Combinations
    
    @Suite("Mixed Circular and Linear Rule Fuzz Tests")
    struct MixedCircularLinearCombinations {
        
        @Test("Circular rules with back-sided linear scales combine both layout modes successfully",
              arguments: generateMixedCircularLinearCombinations())
        func mixedCircularLinearRulesParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parseWithCircular(
                definition,
                dimensions: circularDimensions
            )
            
            // Verify circular front
            #expect(rule.isCircular, "Rule should be circular")
            #expect(rule.diameter != nil, "Should have diameter")
            
            // Front scales should be circular
            for scale in rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales {
                #expect(scale.definition.isCircular, "Front scale \(scale.definition.name) should be circular")
                #expect(!scale.tickMarks.isEmpty, "Scale has no tick marks")
            }
            
            // Back scales should also be circular (when circular spec is used)
            if let backScales = rule.backTopStator?.scales {
                for scale in backScales {
                    #expect(scale.definition.isCircular, "Back scale should be circular")
                    #expect(!scale.tickMarks.isEmpty, "Scale has no tick marks")
                }
            }
        }
        
        static func generateMixedCircularLinearCombinations() -> [String] {
            [
                "(C [ D ] A : LL1 [ LL2 ] LL3) circular:4inch",
                "(K [ A ] B : S [ T ] ST) circular:4inch",
                "(C D [ CI ] : LL1 LL2 [ LL3 ]) circular:5inch",
                "(A [ C ] CI : Sh [ Ch ] Th) circular:4inch",
                "(C [ D ] A : PA [ P ] C) circular:4inch"
            ]
        }
    }
    
    // MARK: - Comprehensive Combination Tests
    
    @Suite("Comprehensive Scale Combination Matrix")
    struct ComprehensiveScaleCombinations {
        
        @Test("Comprehensive matrix of standard scales with exotic scales validates parser robustness",
              arguments: generateComprehensiveCombinations())
        func comprehensiveCombinationsParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parse(definition, dimensions: standardDimensions)
            
            let totalScales = rule.frontTopStator.scales.count + 
                            rule.frontSlide.scales.count + 
                            rule.frontBottomStator.scales.count
            #expect(totalScales > 0, "Rule should have at least one scale")
            
            // Verify all scales have valid tick marks
            for scale in rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(scale.definition.name) has no tick marks")
                #expect(scale.definition.beginValue != scale.definition.endValue, 
                       "Scale \(scale.definition.name) has invalid range")
            }
        }
        
        static func generateComprehensiveCombinations() -> [String] {
            // Generate combinations of standard scales with one exotic scale
            let standard = ["C", "D", "CI", "A", "K"]
            let exotic = ["Sh", "PA", "LL1", "KE-S", "R1", "Q1", "B", "TIME", "CR3S", "P"]
            
            var combinations: [String] = []
            
            // Standard + Exotic in slide
            for std in standard {
                for ex in exotic {
                    combinations.append("(\(std) [ \(ex) ] \(std))")
                }
            }
            
            // Exotic + Standard in slide
            for ex in exotic {
                for std in standard {
                    combinations.append("(\(ex) [ \(std) ] \(ex))")
                }
            }
            
            // Two exotic scales
            for i in 0..<exotic.count {
                for j in i+1..<exotic.count {
                    combinations.append("([ \(exotic[i]) \(exotic[j]) ])")
                }
            }
            
            return combinations
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Suite("Edge Case and Boundary Condition Fuzz Tests")
    struct EdgeCaseCombinations {
        
        @Test("Edge cases including single scales and maximum complexity parse correctly",
              arguments: generateEdgeCaseCombinations())
        func edgeCaseCombinationsParseCorrectly(definition: String) throws {
            let rule = try RuleDefinitionParser.parse(definition, dimensions: standardDimensions)
            
            // Just verify it parses successfully
            let totalScales = rule.frontTopStator.scales.count + 
                            rule.frontSlide.scales.count + 
                            rule.frontBottomStator.scales.count
            #expect(totalScales >= 0, "Rule should parse")
            
            // Verify all scales that exist are valid
            for scale in rule.frontTopStator.scales + rule.frontSlide.scales + rule.frontBottomStator.scales {
                #expect(!scale.tickMarks.isEmpty, "Scale \(scale.definition.name) has no tick marks")
            }
        }
        
        static func generateEdgeCaseCombinations() -> [String] {
            [
                // Single scale
                "(C)",
                "(LL1)",
                "(Sh)",
                "(PA)",
                
                // All in slide
                "([ C D CI ])",
                "([ LL1 LL2 LL3 ])",
                "([ Sh Ch Th ])",
                
                // Maximum complexity
                "(K A B [ C CI CF CIF ] D DF L)",
                "(LL1 LL2 LL3 [ S T ST KE-S ] CI C D)",
                "(Sh Ch Th [ PA P R1 R2 ] Q1 Q2 Q3)",
                
                // All exotic scales
                "(Sh Ch [ Th PA ] P)",
                "(LL1 LL2 [ LL3 KE-S ] KE-T)",
                "(R1 R2 [ Q1 Q2 ] Q3)",
                "(B AI [ BI Sh ] Ch)",
                
                // Mixed directions
                "(C+ [ D- ] A+)",
                "(C- D+ [ CI- ])",
                
                // With modifiers
                "(C^ [ D^ ] A^)",
                "(C+ D- [ CI^ ])"
            ]
        }
    }
}
