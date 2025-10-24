import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests for tick direction modifiers in rule definitions
/// Verifies that + and - modifiers correctly override default tick directions
@Suite("Tick Direction Modifier Tests")
struct TickDirectionModifierTests {
    
    let dimensions = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    @Test("DF scale defaults to tick direction up")
    func testDFDefaultDirection() throws {
        let rule = try RuleDefinitionParser.parse("(DF)", dimensions: dimensions)
        let df = rule.frontTopStator.scales[0].definition
        #expect(df.tickDirection == .up, "DF should default to .up")
    }
    
    @Test("DF- modifier overrides to tick direction down")
    func testDFMinusOverride() throws {
        let rule = try RuleDefinitionParser.parse("(DF-)", dimensions: dimensions)
        let dfMinus = rule.frontTopStator.scales[0].definition
        #expect(dfMinus.tickDirection == .down, "DF- should override to .down")
    }
    
    @Test("D scale defaults to tick direction down")
    func testDDefaultDirection() throws {
        let rule = try RuleDefinitionParser.parse("(D)", dimensions: dimensions)
        let d = rule.frontTopStator.scales[0].definition
        #expect(d.tickDirection == .down, "D should default to .down")
    }
    
    @Test("D+ modifier overrides to tick direction up")
    func testDPlusOverride() throws {
        let rule = try RuleDefinitionParser.parse("(D+)", dimensions: dimensions)
        let dPlus = rule.frontTopStator.scales[0].definition
        #expect(dPlus.tickDirection == .up, "D+ should override to .up")
    }
    
    @Test("C scale defaults to tick direction up")
    func testCDefaultDirection() throws {
        let rule = try RuleDefinitionParser.parse("(C)", dimensions: dimensions)
        let c = rule.frontTopStator.scales[0].definition
        #expect(c.tickDirection == .up, "C should default to .up")
    }
    
    @Test("C- modifier overrides to tick direction down")
    func testCMinusOverride() throws {
        let rule = try RuleDefinitionParser.parse("(C-)", dimensions: dimensions)
        let cMinus = rule.frontTopStator.scales[0].definition
        #expect(cMinus.tickDirection == .down, "C- should override to .down")
    }
    
    @Test("Multiple scales with mixed modifiers apply correctly")
    func testMultipleModifiers() throws {
        let rule = try RuleDefinitionParser.parse("(C+ [ D- ] DF-)", dimensions: dimensions)
        
        let c = rule.frontTopStator.scales[0].definition
        let d = rule.frontSlide.scales[0].definition
        let df = rule.frontBottomStator.scales[0].definition
        
        #expect(c.tickDirection == .up, "C+ should be .up")
        #expect(d.tickDirection == .down, "D- should be .down")
        #expect(df.tickDirection == .down, "DF- should be .down")
    }
    
    @Test("Modifier works in bracket sections")
    func testModifierInBrackets() throws {
        let rule = try RuleDefinitionParser.parse("(C [ D- CI+ ] A)", dimensions: dimensions)
        
        let c = rule.frontTopStator.scales[0].definition
        let d = rule.frontSlide.scales[0].definition
        let ci = rule.frontSlide.scales[1].definition
        let a = rule.frontBottomStator.scales[0].definition
        
        #expect(c.tickDirection == .up, "C should default to .up")
        #expect(d.tickDirection == .down, "D- should be .down")
        #expect(ci.tickDirection == .up, "CI+ should be .up")
        #expect(a.tickDirection == .up, "A should default to .up")
    }
    
    @Test("Complex rule with modifiers from postscript example")
    func testPostscriptExampleRule() throws {
        // From the H266-TG rule: (H266LL03 H266LL01^ LL02B LL2B- A [ B BI Sh1 Sh2 Th CI C ] D DI P L : ...)
        // Testing a simplified version with modifiers
        let rule = try RuleDefinitionParser.parse("(A [ B BI CI C ] D L-)", dimensions: dimensions)
        
        let a = rule.frontTopStator.scales[0].definition
        let d = rule.frontBottomStator.scales[0].definition
        let l = rule.frontBottomStator.scales[1].definition
        
        #expect(a.tickDirection == .up, "A should default to .up")
        #expect(d.tickDirection == .down, "D should default to .down")
        #expect(l.tickDirection == .down, "L- should be .down")
    }
    
    @Test("Plus modifier on down-default scale works")
    func testPlusOnDownDefaultScale() throws {
        let rule = try RuleDefinitionParser.parse("(L+)", dimensions: dimensions)
        let lPlus = rule.frontTopStator.scales[0].definition
        #expect(lPlus.tickDirection == .up, "L+ should override default to .up")
    }
    
    @Test("Minus modifier on up-default scale works")
    func testMinusOnUpDefaultScale() throws {
        let rule = try RuleDefinitionParser.parse("(CF-)", dimensions: dimensions)
        let cfMinus = rule.frontTopStator.scales[0].definition
        #expect(cfMinus.tickDirection == .down, "CF- should override default to .down")
    }
    
    @Test("Modifier is stripped from scale name")
    func testModifierStrippedFromName() throws {
        let rule = try RuleDefinitionParser.parse("(DF-)", dimensions: dimensions)
        let df = rule.frontTopStator.scales[0].definition
        #expect(df.name == "DF", "Scale name should be 'DF' without the modifier")
    }
    
    @Test("No-break modifier (^) does not affect tick direction")
    func testNoBreakModifierDoesNotAffectDirection() throws {
        let rule1 = try RuleDefinitionParser.parse("(C^)", dimensions: dimensions)
        let rule2 = try RuleDefinitionParser.parse("(C)", dimensions: dimensions)
        
        let cWithNoBreak = rule1.frontTopStator.scales[0].definition
        let cNormal = rule2.frontTopStator.scales[0].definition
        
        #expect(cWithNoBreak.tickDirection == cNormal.tickDirection, "^ modifier should not change tick direction")
    }
    
    @Test("Combined modifiers: no-break and direction")
    func testCombinedModifiers() throws {
        // ^ should be stripped, - should set direction
        let rule = try RuleDefinitionParser.parse("(C^-)", dimensions: dimensions)
        let c = rule.frontTopStator.scales[0].definition
        #expect(c.tickDirection == .down, "C^- should have direction .down")
    }
}
