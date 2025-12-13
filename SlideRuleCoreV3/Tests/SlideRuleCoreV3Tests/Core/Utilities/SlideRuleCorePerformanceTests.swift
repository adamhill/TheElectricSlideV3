// import XCTest
// @testable import SlideRuleCore

// final class SlideRuleCorePerformanceTests: XCTestCase {
    
//     // Keep dimensions shared and simple
//     private let dims = RuleDefinitionParser.Dimensions(
//         topStatorMM: 14,
//         slideMM: 13,
//         bottomStatorMM: 14
//     )
    
//     // MARK: - Generation performance
    
//     // Measures parsing/assembly of a few representative assemblies multiple times.
//     // Focus: end-to-end coverage of core generation paths (kept small to avoid CI timeouts).
//     func testGenerateAssembliesPerformance() {
//         let linearDefs = [
//             "(C [ D ] A)",
//             "(LL1 [ LL2 ] LL3)",
//             "(A K [ C ] D)"
//         ]
//         let circularDefs = [
//             "(C [ D ] A) circular:4inch",
//             "(LL1 [ LL2 ] LL3) circular:5inch"
//         ]
        
//         measure {
//             // Linear assemblies
//             for _ in 0..<25 {
//                 for def in linearDefs {
//                     let rule = try? RuleDefinitionParser.parse(def, dimensions: dims, scaleLength: 250.0)
//                     XCTAssertNotNil(rule)
//                 }
//             }
//             // Circular assemblies
//             for _ in 0..<15 {
//                 for def in circularDefs {
//                     let rule = try? RuleDefinitionParser.parseWithCircular(def, dimensions: dims, scaleLength: 250.0)
//                     XCTAssertNotNil(rule)
//                 }
//             }
//         }
//     }
    
//     // MARK: - Circular nearest-tick lookup performance
    
//     // Measures nearestTick(toAngle:) lookups with a fixed deterministic angle set.
//     // Keeps generation and precomputation outside measure; inside measure = pure lookups.
//     func testCircularNearestTickPerformance() {
//         // Build a circular C scale
//         let cLinear = StandardScales.cScale(length: 360.0)
//         let radius: Distance = 100.0
//         let cCircular = ScaleDefinition(
//             name: cLinear.name,
//             function: cLinear.function,
//             beginValue: cLinear.beginValue,
//             endValue: cLinear.endValue,
//             scaleLengthInPoints: cLinear.scaleLengthInPoints,
//             layout: .circular(diameter: radius * 2.0, radiusInPoints: radius),
//             tickDirection: cLinear.tickDirection,
//             subsections: cLinear.subsections,
//             defaultTickStyles: cLinear.defaultTickStyles,
//             labelFormatter: cLinear.labelFormatter,
//             labelColor: cLinear.labelColor,
//             constants: cLinear.constants
//         )
//         let generated = GeneratedScale(definition: cCircular)
        
//         // Deterministic angles (pseudo-random but reproducible)
//         let angles: [Double] = (0..<750).map { i in
//             // Simple LCG-ish progression modulo 360 + slight offset
//             let base = (i &* 73) % 360
//             return Double(base) + 0.123
//         }
        
//         measure {
//             var count = 0
//             for angle in angles {
//                 if let _ = generated.nearestTick(toAngle: angle) {
//                     count &+= 1
//                 }
//             }
//             // Prevent DCE
//             XCTAssertGreaterThan(count, 0)
//         }
//     }
    
//     // MARK: - Parser throughput performance
    
//     // Measures parser throughput across a small matrix of short definitions.
//     // Deterministic inputs; assert-some result to keep paths live.
//     func testParserThroughputPerformance() {
//         let defs: [String] = [
//             "(C D [ CI ])",
//             "(K A [ C T ] D L)",
//             "(LL1 LL2 [ LL3 ])",
//             "(A B [ C ] : D L)",
//             "(C [ D ] A : LL1 [ LL2 ] LL3)",
//             "(B [ AI ] BI)",
//             "(CF DF [ CIF ])"
//         ]
        
//         measure {
//             var total = 0
//             for _ in 0..<40 {
//                 for def in defs {
//                     let rule = try? RuleDefinitionParser.parse(def, dimensions: dims, scaleLength: 250.0)
//                     if rule != nil { total &+= 1 }
//                 }
//             }
//             XCTAssertGreaterThan(total, 0)
//         }
//     }
// }