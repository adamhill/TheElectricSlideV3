import SlideRuleCoreV3

// Test if Pickett N3 Powerlog definition can be parsed
let dims = RuleDefinitionParser.Dimensions(
    topStatorMM: 15,
    slideMM: 30,
    bottomStatorMM: 15
)

let definition = "(K A [ B ST S T1 T2 CI C ] D DI : LL00 LL00- LL01 LL1- DF [ CF CIF Ln L CI C ] D LL02 LL2- LL03 LL3-)"

do {
    let rule = try RuleDefinitionParser.parse(
        definition,
        dimensions: dims,
        scaleLength: 250.0
    )
    
    print("✓ Pickett N3 Powerlog parsed successfully!")
    print("\nFront side:")
    print("  Top: \(rule.frontTopStator.scales.map { $0.definition.name }.joined(separator: ", "))")
    print("  Slide: \(rule.frontSlide.scales.map { $0.definition.name }.joined(separator: ", "))")
    print("  Bottom: \(rule.frontBottomStator.scales.map { $0.definition.name }.joined(separator: ", "))")
    
    if let backTop = rule.backTopStator {
        print("\nBack side:")
        print("  Top: \(backTop.scales.map { $0.definition.name }.joined(separator: ", "))")
        print("  Slide: \(rule.backSlide!.scales.map { $0.definition.name }.joined(separator: ", "))")
        print("  Bottom: \(rule.backBottomStator!.scales.map { $0.definition.name }.joined(separator: ", "))")
    }
    
    print("\nTotal scales: \(rule.frontTopStator.scales.count + rule.frontSlide.scales.count + rule.frontBottomStator.scales.count + (rule.backTopStator?.scales.count ?? 0) + (rule.backSlide?.scales.count ?? 0) + (rule.backBottomStator?.scales.count ?? 0))")
    
} catch {
    print("✗ Parse error: \(error)")
}