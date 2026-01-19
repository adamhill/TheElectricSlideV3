import Testing
@testable import SlideRuleCoreV3

/// Tests for scale displayName architecture
/// Ensures scales with explicit displayName via ScaleBuilder preserve their display names
/// through the parser, and that token-derived aliases work correctly.
///
/// Two-Name Architecture:
/// 1. `name` - Unique lookup token in StandardScales.scale(named:) registry
/// 2. `displayName` - What users see rendered on the slide rule (optional, falls back to name)
///
/// Parser Behavior:
/// - If scale has explicit displayName set → preserve it (don't override)
/// - If scale name differs from definition token → set displayName to token (alias behavior)
/// - If scale name matches token → displayName stays nil (name used for display)
@Suite("Scale Display Name Architecture Tests")
struct ScaleDisplayNameTests {
    
    // MARK: - Hemmi 266 Scale Names (Phase 1 Migration)
    
    @Suite("Hemmi 266 Display Names")
    struct Hemmi266DisplayNameTests {
        
        @Test("H266LL01 displays as L̅L̅1 (overbar notation)")
        func h266LL01DisplayName() throws {
            let scale = StandardScales.h266LL01Scale(length: 250.0)
            
            #expect(scale.name == "H266LL01", "Token name should be H266LL01")
            #expect(scale.displayName == "L̅L̅1", "Display name should be L̅L̅1 with overbar")
        }
        
        @Test("H266LL03 displays as L̅L̅3 (overbar notation)")
        func h266LL03DisplayName() throws {
            let scale = StandardScales.h266LL03Scale(length: 250.0)
            
            #expect(scale.name == "H266LL03", "Token name should be H266LL03")
            #expect(scale.displayName == "L̅L̅3", "Display name should be L̅L̅3 with overbar")
        }
        
        @Test("H266L displays as ㏈ L (dB symbol)")
        func h266LDisplayName() throws {
            let scale = StandardScales.h266LScale(length: 250.0)
            
            #expect(scale.name == "H266L", "Token name should be H266L")
            #expect(scale.displayName == "㏈ L", "Display name should be ㏈ L with dB symbol")
        }
        
        @Test("Hemmi 266 parsed rule preserves display names")
        func hemmi266ParsedDisplayNames() throws {
            // Hemmi 266 definition string (from SlideRuleLibrary) - front side only
            // Uses H266LL03, H266LL01, H266L (the scales with displayNames we set)
            let definition = "H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D H266L-"
            let dimensions = RuleDefinitionParser.Dimensions(
                topStatorMM: 15,
                slideMM: 15,
                bottomStatorMM: 15
            )
            
            let slideRule = try RuleDefinitionParser.parse(
                "(\(definition))",
                dimensions: dimensions,
                scaleLength: 1000.0
            )
            
            // Find H266LL01 in top stator (it's split with ^)
            let ll01Scale = slideRule.frontTopStator.scales.first { scale in
                scale.definition.name == "H266LL01"
            }
            #expect(ll01Scale != nil, "H266LL01 should be in top stator")
            #expect(ll01Scale?.definition.displayName == "L̅L̅1", "H266LL01 should display as L̅L̅1")
            
            // Find H266LL03 in top stator
            let ll03Scale = slideRule.frontTopStator.scales.first { scale in
                scale.definition.name == "H266LL03"
            }
            #expect(ll03Scale != nil, "H266LL03 should be in top stator")
            #expect(ll03Scale?.definition.displayName == "L̅L̅3", "H266LL03 should display as L̅L̅3")
            
            // Find H266L in bottom stator
            let lScale = slideRule.frontBottomStator.scales.first { scale in
                scale.definition.name == "H266L"
            }
            #expect(lScale != nil, "H266L should be in bottom stator")
            #expect(lScale?.definition.displayName == "㏈ L", "H266L should display as ㏈ L")
        }
    }
    
    // MARK: - Pickett N-16 ES Scale Names (Phase 2 Migration)
    
    @Suite("Pickett N-16 ES Display Names")
    struct PickettN16ESDisplayNameTests {
        
        @Test("N16L displays as C/L")
        func n16LDisplayName() throws {
            let scale = StandardScales.n16LScale(length: 250.0)
            
            #expect(scale.name == "N16L", "Token name should be N16L")
            #expect(scale.displayName == "C/L", "Display name should be C/L")
        }
        
        @Test("N16Cos displays as cos (lowercase)")
        func n16CosDisplayName() throws {
            let scale = StandardScales.n16CosScale(length: 250.0)
            
            #expect(scale.name == "N16Cos", "Token name should be N16Cos")
            #expect(scale.displayName == "cos", "Display name should be lowercase cos")
        }
        
        @Test("N16CosΘ displays as cos Θ (with space)")
        func n16CosThetaDisplayName() throws {
            let scale = StandardScales.n16CosThetaScale(length: 250.0)
            
            #expect(scale.name == "N16CosΘ", "Token name should be N16CosΘ")
            #expect(scale.displayName == "cos Θ", "Display name should be cos Θ with space")
        }
        
        @Test("DQ (pickettDQScale) displays as D/Q")
        func dqDisplayName() throws {
            let scale = StandardScales.pickettDQScale(length: 250.0)
            
            #expect(scale.name == "DQ", "Token name should be DQ")
            #expect(scale.displayName == "D/Q", "Display name should be D/Q")
        }
        
        @Test("PF (pickettFScale) displays as F")
        func pfDisplayName() throws {
            let scale = StandardScales.pickettFScale(length: 250.0)
            
            #expect(scale.name == "PF", "Token name should be PF")
            #expect(scale.displayName == "F", "Display name should be F")
        }
        
        @Test("Pickett N-16 ES parsed rule preserves display names")
        func pickettN16ESParsedDisplayNames() throws {
            // Simplified Pickett N-16 ES definition focusing on our migrated scales
            let definition = "DF [ CF N16L S N16Cos ST T CI C ] D LL3 LL2 LL1 Ln : db DQ XL Xc [ N16L PF λ ω τ Cr ] Lr db N16CosΘ"
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
            
            // Front slide: N16L should display as C/L
            let frontN16L = slideRule.frontSlide.scales.first { scale in
                scale.definition.name == "N16L"
            }
            #expect(frontN16L != nil, "N16L should be in front slide")
            #expect(frontN16L?.definition.displayName == "C/L", "N16L should display as C/L")
            
            // Front slide: N16Cos should display as cos
            let n16Cos = slideRule.frontSlide.scales.first { scale in
                scale.definition.name == "N16Cos"
            }
            #expect(n16Cos != nil, "N16Cos should be in front slide")
            #expect(n16Cos?.definition.displayName == "cos", "N16Cos should display as cos")
            
            // Back slide: N16L should also display as C/L
            let backN16L = slideRule.backSlide?.scales.first { scale in
                scale.definition.name == "N16L"
            }
            #expect(backN16L != nil, "N16L should be in back slide")
            #expect(backN16L?.definition.displayName == "C/L", "Back N16L should display as C/L")
            
            // Back slide: PF should display as F
            let pfScale = slideRule.backSlide?.scales.first { scale in
                scale.definition.name == "PF"
            }
            #expect(pfScale != nil, "PF should be in back slide")
            #expect(pfScale?.definition.displayName == "F", "PF should display as F")
            
            // Back bottom stator: DQ should display as D/Q
            let dqScale = slideRule.backTopStator?.scales.first { scale in
                scale.definition.name == "DQ"
            }
            #expect(dqScale != nil, "DQ should be in back top stator")
            #expect(dqScale?.definition.displayName == "D/Q", "DQ should display as D/Q")
            
            // Back bottom stator: N16CosΘ should display as cos Θ
            let n16CosTheta = slideRule.backBottomStator?.scales.first { scale in
                scale.definition.name == "N16CosΘ"
            }
            #expect(n16CosTheta != nil, "N16CosΘ should be in back bottom stator")
            #expect(n16CosTheta?.definition.displayName == "cos Θ", "N16CosΘ should display as cos Θ")
        }
    }
    
    // MARK: - Faber-Castell 62/83N (Existing Pattern)
    
    @Suite("Faber-Castell 283N Display Names")
    struct FaberCastell283NDisplayNameTests {
        
        @Test("FC283N LL scales have explicit displayName")
        func fc283nLLScalesDisplayNames() throws {
            let ll00 = StandardScales.FC283N_LL00(length: 250.0)
            let ll01 = StandardScales.FC283N_LL01(length: 250.0)
            let ll02 = StandardScales.FC283N_LL02(length: 250.0)
            let ll03 = StandardScales.FC283N_LL03(length: 250.0)
            
            #expect(ll00.displayName == "LL00", "FC283NLL00 should display as LL00")
            #expect(ll01.displayName == "LL01", "FC283NLL01 should display as LL01")
            #expect(ll02.displayName == "LL02", "FC283NLL02 should display as LL02")
            #expect(ll03.displayName == "LL03", "FC283NLL03 should display as LL03")
        }
    }
    
    // MARK: - Parser displayName Preservation
    
    @Suite("Parser Display Name Handling")
    struct ParserDisplayNameTests {
        
        @Test("Parser preserves explicit displayName through parsing")
        func parserPreservesExplicitDisplayName() throws {
            // Use a scale with explicit displayName (N16L → C/L)
            let definition = "[ N16L ]"
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
            
            let scale = slideRule.frontSlide.scales.first
            #expect(scale != nil, "Scale should be parsed")
            #expect(scale?.definition.name == "N16L", "Name should be N16L")
            #expect(scale?.definition.displayName == "C/L", "DisplayName should be preserved as C/L")
        }
        
        @Test("Parser sets displayName from token when name differs and no explicit displayName")
        func parserSetsDisplayNameFromToken() throws {
            // W2 is an alias for Sq2 - parser should set displayName = "W2"
            let definition = "[ W2 ]"
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
            
            let scale = slideRule.frontSlide.scales.first
            #expect(scale != nil, "Scale should be parsed")
            #expect(scale?.definition.name == "Sq2", "Canonical name should be Sq2")
            #expect(scale?.definition.displayName == "W2", "DisplayName should be set to W2 from token")
        }
        
        @Test("Parser leaves displayName nil when token matches name")
        func parserLeavesDisplayNameNilWhenMatching() throws {
            // C scale: token "C" matches scale name "C" - no displayName needed
            let definition = "[ C ]"
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
            
            let scale = slideRule.frontSlide.scales.first
            #expect(scale != nil, "Scale should be parsed")
            #expect(scale?.definition.name == "C", "Name should be C")
            #expect(scale?.definition.displayName == nil, "DisplayName should be nil when token matches name")
        }
    }
}
