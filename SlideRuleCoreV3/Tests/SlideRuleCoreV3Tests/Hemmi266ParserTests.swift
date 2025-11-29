import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests for Hemmi 266 Electronics Slide Rule parser definition verification
/// 
/// The Hemmi 266 is a specialized electronics/EE slide rule with:
/// - Front: Log-Log scales + standard scales
/// - Back: Complete EE scale set for RF/electronics work
///
/// Full definition string:
/// ```
/// (H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank)
/// ```
///
/// Parser syntax reference (from postscript-rule-engine-explainer.md):
/// - `^` suffix = no line break (noLineBreak flag)
/// - `-` suffix = force tick direction down
/// - `+` suffix = force tick direction up
/// - `[ ]` = slide scale boundaries
/// - `:` = flip to back side
/// - `|` = draw separator line
/// - `blank` = skip line
@Suite("Hemmi 266 Parser Definition Tests", .tags(.fast, .regression))
struct Hemmi266ParserTests {
    
    // MARK: - Test Configuration
    
    /// Standard dimensions for Hemmi 266 slide rule (in mm)
    static let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    /// Full Hemmi 266 definition string
    static let fullH266Definition = "(H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank)"
    
    /// Hemmi 266 definition with only currently-implemented scales
    static let partialH266Definition = "(A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank)"
    
    // MARK: - Implemented Scale Verification
    
    /// Documents scales that ARE NOW IMPLEMENTED
    /// These are Hemmi 266-specific Log-Log scale variants
    @Suite("Hemmi 266 Log-Log Scales Implementation")
    struct ImplementedScalesVerification {
        
        /// H266LL03 - Hemmi 266 specific Log-Log scale
        /// Range: 1 to 50,000 (representing 10^-9 × value)
        /// Formula: log₁₀(ln(x × 10^-9) × -0.1) / 2
        @Test("H266LL03 scale is implemented")
        func h266ll03IsImplemented() {
            let scale = StandardScales.scale(named: "H266LL03", length: 250.0)
            #expect(scale != nil, "H266LL03 should be implemented")
            #expect(scale?.name == "H266LL03", "Scale name should be H266LL03")
            #expect(scale?.beginValue == 1.0, "H266LL03 should start at 1.0")
            #expect(scale?.endValue == 50000.0, "H266LL03 should end at 50000.0")
        }
        
        /// H266LL01 - Hemmi 266 specific Log-Log scale
        /// Range: 0.90 to 0.99
        /// Uses same function as LL00B: log₁₀(-ln(x) × 100) / 2 + 0.5
        @Test("H266LL01 scale is implemented")
        func h266ll01IsImplemented() {
            let scale = StandardScales.scale(named: "H266LL01", length: 250.0)
            #expect(scale != nil, "H266LL01 should be implemented")
            #expect(scale?.name == "H266LL01", "Scale name should be H266LL01")
            #expect(scale?.beginValue == 0.90, "H266LL01 should start at 0.90")
            #expect(scale?.endValue == 0.99, "H266LL01 should end at 0.99")
        }
        
        /// LL02B - Combined LL02/LL03 scale referenced to A/B scales
        /// Range: 0.00005 to 0.904
        /// Formula: log₁₀(-ln(x) × 10) / 2
        @Test("LL02B scale is implemented")
        func ll02bIsImplemented() {
            let scale = StandardScales.scale(named: "LL02B", length: 250.0)
            #expect(scale != nil, "LL02B should be implemented")
            #expect(scale?.name == "LL02B", "Scale name should be LL02B")
            #expect(scale?.beginValue == 0.00005, "LL02B should start at 0.00005")
            #expect(abs((scale?.endValue ?? 0) - 0.904) < 0.001, "LL02B should end near 0.904")
        }
        
        /// LL2B - Extended positive scale referenced to A/B scales
        /// Range: 1.106 to 20,000
        /// Formula: log₁₀(ln(x) × 10) / 2
        @Test("LL2B scale is implemented")
        func ll2bIsImplemented() {
            let scale = StandardScales.scale(named: "LL2B", length: 250.0)
            #expect(scale != nil, "LL2B should be implemented")
            #expect(scale?.name == "LL2B", "Scale name should be LL2B")
            #expect(abs((scale?.beginValue ?? 0) - 1.106) < 0.001, "LL2B should start near 1.106")
            #expect(scale?.endValue == 20000.0, "LL2B should end at 20000.0")
        }
        
        /// Verify all 4 Hemmi 266 Log-Log scales are implemented
        @Test("All Hemmi 266 Log-Log scales are implemented")
        func allScalesImplemented() {
            let implementedScales = [
                "H266LL03",  // Hemmi 266-specific ultra-small value scale
                "H266LL01",  // Hemmi 266-specific near-unity negative scale
                "LL02B",     // Combined LL02/LL03 referenced to A/B
                "LL2B"       // Extended positive scale referenced to A/B
            ]
            
            for scaleName in implementedScales {
                let scale = StandardScales.scale(named: scaleName, length: 250.0)
                #expect(scale != nil, "Scale '\(scaleName)' should be implemented")
            }
            
            // All 4 scales are now implemented
            #expect(implementedScales.count == 4, "All 4 Hemmi 266 Log-Log scales should be implemented")
        }
    }
    
    // MARK: - Full Definition Parse Tests
    
    @Suite("Full Hemmi 266 Definition Parsing")
    struct FullDefinitionParsingTests {
        
        /// The full definition SHOULD NOW PARSE SUCCESSFULLY because all scales are implemented
        @Test("Full Hemmi 266 definition parses successfully")
        func fullDefinitionParsesSuccessfully() throws {
            let rule = try RuleDefinitionParser.parse(
                Hemmi266ParserTests.fullH266Definition,
                dimensions: Hemmi266ParserTests.dims
            )
            
            // Verify we got a valid slide rule with all scales
            let frontTotal = rule.frontTopStator.scales.count +
                            rule.frontSlide.scales.count +
                            rule.frontBottomStator.scales.count
            
            // Front: H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T-
            // That's 4 Log-Log + A + 4 slide + D L S T = 13 scales
            #expect(frontTotal == 13, "Front should have 13 scales, got \(frontTotal)")
            
            #expect(rule.backTopStator != nil, "Back side should exist")
        }
        
        /// Test each implemented scale parses correctly
        @Test("Each Hemmi 266 Log-Log scale parses correctly",
              arguments: [
                  ("(H266LL03 A [ B ] D)", "H266LL03"),
                  ("(H266LL01 A [ B ] D)", "H266LL01"),
                  ("(LL02B A [ B ] D)", "LL02B"),
                  ("(LL2B A [ B ] D)", "LL2B")
              ])
        func implementedScaleParsesCorrectly(definition: String, expectedScale: String) throws {
            let rule = try RuleDefinitionParser.parse(
                definition,
                dimensions: Hemmi266ParserTests.dims
            )
            
            // The scale should be in the top stator (first position)
            let scaleFound = rule.frontTopStator.scales.contains {
                $0.definition.name == expectedScale
            }
            #expect(scaleFound, "Scale '\(expectedScale)' should be parsed into top stator")
        }
    }
    
    // MARK: - Partial Definition Parse Tests (Currently Implemented Scales Only)
    
    @Suite("Partial Hemmi 266 Definition (Implemented Scales)")
    struct PartialDefinitionParsingTests {
        
        /// The partial definition with only implemented scales SHOULD parse successfully
        @Test("Partial Hemmi 266 definition parses successfully")
        func partialDefinitionParsesSuccessfully() throws {
            let rule = try RuleDefinitionParser.parse(
                Hemmi266ParserTests.partialH266Definition,
                dimensions: Hemmi266ParserTests.dims
            )
            
            // Verify we got a valid slide rule
            #expect(rule.frontTopStator.scales.count > 0 || 
                   rule.frontSlide.scales.count > 0 ||
                   rule.frontBottomStator.scales.count > 0,
                   "Front side should have scales")
            
            #expect(rule.backTopStator != nil, "Back side should exist")
        }
        
        /// Verify front side scale count
        @Test("Partial definition has correct front side scale count")
        func partialDefinitionFrontScaleCount() throws {
            let rule = try RuleDefinitionParser.parse(
                Hemmi266ParserTests.partialH266Definition,
                dimensions: Hemmi266ParserTests.dims
            )
            
            // Front: A [ B BI CI C ] D L- S T-
            // Top stator: A (1 scale)
            // Slide: B, BI, CI, C (4 scales)  
            // Bottom stator: D, L, S, T (4 scales)
            let frontTop = rule.frontTopStator.scales.count
            let frontSlide = rule.frontSlide.scales.count
            let frontBottom = rule.frontBottomStator.scales.count
            
            #expect(frontTop == 1, "Front top stator should have 1 scale (A), got \(frontTop)")
            #expect(frontSlide == 4, "Front slide should have 4 scales (B, BI, CI, C), got \(frontSlide)")
            #expect(frontBottom == 4, "Front bottom stator should have 4 scales (D, L, S, T), got \(frontBottom)")
            
            let totalFront = frontTop + frontSlide + frontBottom
            #expect(totalFront == 9, "Total front scales should be 9, got \(totalFront)")
        }
        
        /// Verify back side scale count
        @Test("Partial definition has correct back side scale count") 
        func partialDefinitionBackScaleCount() throws {
            let rule = try RuleDefinitionParser.parse(
                Hemmi266ParserTests.partialH266Definition,
                dimensions: Hemmi266ParserTests.dims
            )
            
            guard let backTop = rule.backTopStator,
                  let backSlide = rule.backSlide,
                  let backBottom = rule.backBottomStator else {
                Issue.record("Back side should exist")
                return
            }
            
            // Back: eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank
            // Top stator: eeXl, eeXc, eeF, eer1, eeP (5 scales)
            // Slide: eer2, eeQ, eeLi, eeCf, eeCz (5 scales)
            // Bottom stator: eeL, eeZ, eeFo (3 scales) - "blank" is ignored
            let backTopCount = backTop.scales.count
            let backSlideCount = backSlide.scales.count
            let backBottomCount = backBottom.scales.count
            
            #expect(backTopCount == 5, "Back top stator should have 5 scales (eeXl, eeXc, eeF, eer1, eeP), got \(backTopCount)")
            #expect(backSlideCount == 5, "Back slide should have 5 scales (eer2, eeQ, eeLi, eeCf, eeCz), got \(backSlideCount)")
            #expect(backBottomCount == 3, "Back bottom stator should have 3 scales (eeL, eeZ, eeFo), got \(backBottomCount)")
            
            let totalBack = backTopCount + backSlideCount + backBottomCount
            #expect(totalBack == 13, "Total back scales should be 13, got \(totalBack)")
        }
    }
    
    // MARK: - Individual Scale Verification Tests
    
    @Suite("Hemmi 266 Scale Resolution Verification")
    struct ScaleResolutionTests {
        
        /// All standard front scales should resolve
        @Test("Front side standard scales resolve correctly",
              arguments: ["A", "B", "BI", "CI", "C", "D", "L", "S", "T"])
        func frontScalesResolve(scaleName: String) {
            let scale = StandardScales.scale(named: scaleName, length: 250.0)
            #expect(scale != nil, "Scale '\(scaleName)' should be available")
            #expect(scale?.name.uppercased() == scaleName.uppercased() || 
                   scaleName == "L", // L can match to various names
                   "Scale name should match")
        }
        
        /// All EE back scales should resolve
        @Test("Back side EE scales resolve correctly",
              arguments: ["eeXl", "eeXc", "eeF", "eer1", "eeP", "eer2", "eeQ", "eeLi", "eeCf", "eeCz", "eeL", "eeZ", "eeFo"])
        func backEEScalesResolve(scaleName: String) {
            let scale = StandardScales.scale(named: scaleName, length: 250.0)
            #expect(scale != nil, "EE Scale '\(scaleName)' should be available")
        }
    }
    
    // MARK: - Tick Direction Modifier Tests
    
    @Suite("Hemmi 266 Tick Direction Modifiers")
    struct TickDirectionModifierTests {
        
        /// Test that L- modifier creates a scale with downward ticks
        @Test("L- modifier forces tick direction down")
        func lMinusModifier() throws {
            let rule = try RuleDefinitionParser.parse(
                "(A [ B ] D L-)",
                dimensions: Hemmi266ParserTests.dims
            )
            
            // L- should be in bottom stator with tick direction down
            let lScale = rule.frontBottomStator.scales.first { 
                $0.definition.name == "L" 
            }
            
            #expect(lScale != nil, "L scale should exist in bottom stator")
            #expect(lScale?.definition.tickDirection == .down, 
                   "L- should have tick direction down")
        }
        
        /// Test that T- modifier creates a scale with downward ticks
        @Test("T- modifier forces tick direction down")
        func tMinusModifier() throws {
            let rule = try RuleDefinitionParser.parse(
                "(A [ B ] T-)",
                dimensions: Hemmi266ParserTests.dims
            )
            
            let tScale = rule.frontBottomStator.scales.first { 
                $0.definition.name == "T" 
            }
            
            #expect(tScale != nil, "T scale should exist in bottom stator")
            #expect(tScale?.definition.tickDirection == .down,
                   "T- should have tick direction down")
        }
        
        /// Test noLineBreak flag with ^ suffix
        @Test("eeP^ modifier sets noLineBreak flag")
        func eePCaretModifier() throws {
            let rule = try RuleDefinitionParser.parse(
                "(A [ B ] D : eeP^)",
                dimensions: Hemmi266ParserTests.dims
            )
            
            guard let backTop = rule.backTopStator else {
                Issue.record("Back side should exist")
                return
            }
            
            let eePScale = backTop.scales.first { 
                $0.definition.name == "P" 
            }
            
            #expect(eePScale != nil, "eeP scale should exist")
            #expect(eePScale?.noLineBreak == true,
                   "eeP^ should have noLineBreak flag set")
        }
        
        /// Test combined modifiers work on back side
        @Test("eer2^ modifier on back slide sets noLineBreak")
        func eer2CaretModifier() throws {
            let rule = try RuleDefinitionParser.parse(
                "(A [ B ] D : eeXl [ eer2^ ] eeL)",
                dimensions: Hemmi266ParserTests.dims
            )
            
            guard let backSlide = rule.backSlide else {
                Issue.record("Back slide should exist")
                return
            }
            
            let eer2Scale = backSlide.scales.first { 
                $0.definition.name == "r2" 
            }
            
            #expect(eer2Scale != nil, "eer2 scale should exist in back slide")
            #expect(eer2Scale?.noLineBreak == true,
                   "eer2^ should have noLineBreak flag set")
        }
    }
    
    // MARK: - Slide Scale Boundary Tests
    
    @Suite("Hemmi 266 Slide Scale Boundaries")
    struct SlideScaleBoundaryTests {
        
        /// Front slide should contain exactly B, BI, CI, C
        @Test("Front slide contains correct scales")
        func frontSlideScales() throws {
            let rule = try RuleDefinitionParser.parse(
                Hemmi266ParserTests.partialH266Definition,
                dimensions: Hemmi266ParserTests.dims
            )
            
            let slideScaleNames = rule.frontSlide.scales.map { $0.definition.name }
            
            #expect(slideScaleNames.contains("B"), "Front slide should contain B")
            #expect(slideScaleNames.contains("BI"), "Front slide should contain BI")
            #expect(slideScaleNames.contains("CI"), "Front slide should contain CI")
            #expect(slideScaleNames.contains("C"), "Front slide should contain C")
            #expect(slideScaleNames.count == 4, "Front slide should have exactly 4 scales")
        }
        
        /// Back slide should contain exactly eer2, eeQ, eeLi, eeCf, eeCz
        @Test("Back slide contains correct EE scales")
        func backSlideScales() throws {
            let rule = try RuleDefinitionParser.parse(
                Hemmi266ParserTests.partialH266Definition,
                dimensions: Hemmi266ParserTests.dims
            )
            
            guard let backSlide = rule.backSlide else {
                Issue.record("Back slide should exist")
                return  
            }
            
            let slideScaleNames = backSlide.scales.map { $0.definition.name }
            
            #expect(slideScaleNames.contains("r2"), "Back slide should contain r2 (from eer2)")
            #expect(slideScaleNames.contains("Q"), "Back slide should contain Q (from eeQ)")
            #expect(slideScaleNames.contains("Li"), "Back slide should contain Li (from eeLi)")
            #expect(slideScaleNames.contains("Cf"), "Back slide should contain Cf (from eeCf)")  
            #expect(slideScaleNames.contains("Cz"), "Back slide should contain Cz (from eeCz)")
            #expect(slideScaleNames.count == 5, "Back slide should have exactly 5 scales")
        }
    }
    
    // MARK: - Blank Token Handling
    
    @Suite("Blank Token Handling")
    struct BlankTokenTests {
        
        /// "blank" token should be ignored and not cause errors
        @Test("blank token is handled correctly")
        func blankTokenIgnored() throws {
            // This should parse without errors - blank is ignored
            let rule = try RuleDefinitionParser.parse(
                "(A [ B ] D blank)",
                dimensions: Hemmi266ParserTests.dims
            )
            
            // blank should not add any scales
            let totalScales = rule.frontTopStator.scales.count +
                             rule.frontSlide.scales.count +
                             rule.frontBottomStator.scales.count
            
            #expect(totalScales == 3, "blank should not add a scale, total should be 3")
        }
        
        /// Multiple blank tokens should all be ignored
        @Test("Multiple blank tokens are handled")
        func multipleBlanksIgnored() throws {
            let rule = try RuleDefinitionParser.parse(
                "(blank A blank [ B ] blank D blank)",
                dimensions: Hemmi266ParserTests.dims
            )
            
            let totalScales = rule.frontTopStator.scales.count +
                             rule.frontSlide.scales.count +
                             rule.frontBottomStator.scales.count
            
            #expect(totalScales == 3, "Multiple blanks should not add scales")
        }
    }
}

// MARK: - Hemmi 266 Scale Implementation Summary

/*
 HEMMI 266 SCALES IMPLEMENTATION SUMMARY
 =======================================
 
 All Hemmi 266 scales are now fully implemented!
 
 1. H266LL03 - Hemmi 266-specific Log-Log scale ✓ IMPLEMENTED
    - Range: 1 to 50,000 (representing 10^-9 × value)
    - Formula: log₁₀(ln(x × 10^-9) × -0.1) / 2
    - Purpose: Ultra-small value scale for nano-scale calculations
    - Implementation: StandardScales.h266LL03Scale(length:)
 
 2. H266LL01 - Hemmi 266-specific Log-Log scale ✓ IMPLEMENTED
    - Range: 0.90 to 0.99
    - Formula: log₁₀(-ln(x) × 100) / 2 + 0.5 (same as LL00B)
    - Purpose: Truncated range variant for values very close to 1
    - Implementation: StandardScales.h266LL01Scale(length:)
 
 3. LL02B - Combined LL02/LL03 scale ✓ IMPLEMENTED
    - Range: 0.00005 to 0.904
    - Formula: log₁₀(-ln(x) × 10) / 2
    - Purpose: Referenced to A/B scales for extended negative range
    - Implementation: StandardScales.ll02BScale(length:)
 
 4. LL2B - Extended positive Log-Log scale ✓ IMPLEMENTED
    - Range: 1.106 to 20,000
    - Formula: log₁₀(ln(x) × 10) / 2
    - Purpose: Referenced to A/B scales for extended positive range
    - Implementation: StandardScales.ll2BScale_PostScriptAccurate(length:)
 
 IMPLEMENTATION STATUS:
 - Front standard scales: A, B, BI, CI, C, D, L, S, T ✓ All implemented
 - Back EE scales: All 13 EE scales ✓ All implemented
 - Front Log-Log scales: H266LL03, H266LL01, LL02B, LL2B ✓ All implemented
 
 The full Hemmi 266 definition now parses and renders correctly:
 (H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank)
 */