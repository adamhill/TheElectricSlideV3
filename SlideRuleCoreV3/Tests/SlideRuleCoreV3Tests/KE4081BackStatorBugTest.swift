import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Test to diagnose K&E 4081-3 back bottom stator scale bug
/// Bug report: Back bottom stator shows Lr, db, cos θ instead of D, LL3-, LL2-
@Suite("K&E 4081-3 Back Stator Bug Investigation")
struct KE4081BackStatorBugTest {
    
    static let dims = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    
    @Test("K&E 4081-3 definition parses with correct back bottom stator")
    func ke4081BackBottomStatorIsCorrect() throws {
        let ke4081Definition = "(LL01 K A [ B | T ST S ] D L- LL1- : LL02 LL03 DF [ CF CIF | CI C ] D LL3- LL2-)"
        
        let rule = try RuleDefinitionParser.parse(
            ke4081Definition,
            dimensions: Self.dims,
            scaleLength: 1000.0
        )
        
        // Verify back side exists
        #expect(rule.backBottomStator != nil, "K&E 4081-3 should have a back bottom stator")
        
        guard let backBottom = rule.backBottomStator else { return }
        
        // Verify scale count
        #expect(backBottom.scales.count == 3, "Back bottom stator should have 3 scales (D, LL3-, LL2-), got \(backBottom.scales.count)")
        
        // Verify exact scale names
        let scaleNames = backBottom.scales.map { $0.definition.name }
        
        print("K&E 4081-3 back bottom stator scales: \(scaleNames.joined(separator: ", "))")
        
        #expect(scaleNames.count == 3, "Should have exactly 3 scales")
        #expect(scaleNames[0] == "D", "First scale should be D, got \(scaleNames[0])")
        #expect(scaleNames[1] == "LL3", "Second scale should be LL3, got \(scaleNames[1])")
        #expect(scaleNames[2] == "LL2", "Third scale should be LL2, got \(scaleNames[2])")
        
        // NOT Lr, db, CosΘ
        #expect(!scaleNames.contains("Lr"), "Should NOT contain Lr (Pickett N16ES scale)")
        #expect(!scaleNames.contains("db"), "Should NOT contain db (Pickett N16ES scale)")
        #expect(!scaleNames.contains("CosΘ"), "Should NOT contain CosΘ (Pickett N16ES scale)")
    }
    
    @Test("Pickett N16ES definition parses with correct back bottom stator")
    func pickettN16ESBackBottomStatorIsCorrect() throws {
        let pickettDefinition = "(SH1 SH2- TH DF [ CF L S Cos ST T CI C ] D LL3 LL2 LL1 Ln : Θ db D XL Xc [ L F λ ω τ Cr ] Lr db CosΘ)"
        
        let rule = try RuleDefinitionParser.parse(
            pickettDefinition,
            dimensions: Self.dims,
            scaleLength: 1000.0
        )
        
        // Verify back side exists
        #expect(rule.backBottomStator != nil, "Pickett N16ES should have a back bottom stator")
        
        guard let backBottom = rule.backBottomStator else { return }
        
        // Verify exact scale names
        let scaleNames = backBottom.scales.map { $0.definition.name }
        
        print("Pickett N16ES back bottom stator scales: \(scaleNames.joined(separator: ", "))")
        
        #expect(scaleNames.count == 3, "Should have exactly 3 scales (Lr, db, CosΘ)")
        #expect(scaleNames[0] == "Lr", "First scale should be Lr")
        #expect(scaleNames[1] == "db", "Second scale should be db")  
        #expect(scaleNames[2] == "CosΘ", "Third scale should be CosΘ")
    }
    
    @Test("K&E 4081-3 and Pickett N16ES have different back bottom stators")
    func differentBackBottomStators() throws {
        let ke4081Def = "(LL01 K A [ B | T ST S ] D L- LL1- : LL02 LL03 DF [ CF CIF | CI C ] D LL3- LL2-)"
        let pickettDef = "(SH1 SH2- TH DF [ CF L S Cos ST T CI C ] D LL3 LL2 LL1 Ln : Θ db D XL Xc [ L F λ ω τ Cr ] Lr db CosΘ)"
        
        let ke4081Rule = try RuleDefinitionParser.parse(ke4081Def, dimensions: Self.dims, scaleLength: 1000.0)
        let pickettRule = try RuleDefinitionParser.parse(pickettDef, dimensions: Self.dims, scaleLength: 1000.0)
        
        let ke4081Scales = ke4081Rule.backBottomStator?.scales.map { $0.definition.name } ?? []
        let pickettScales = pickettRule.backBottomStator?.scales.map { $0.definition.name } ?? []
        
        print("\nComparison:")
        print("  K&E 4081-3 back bottom: \(ke4081Scales.joined(separator: ", "))")
        print("  Pickett N16ES back bottom: \(pickettScales.joined(separator: ", "))")
        
        #expect(ke4081Scales != pickettScales, "K&E and Pickett should have different back bottom stator scales")
    }
}