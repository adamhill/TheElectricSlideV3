import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Property Preservation Tests

/// Tests to ensure ScaleDefinition properties are preserved when scales are
/// modified during parsing (e.g., height adjustment, tick direction override).
///
/// **Background**: When RuleDefinitionParser modifies a scale (to apply height,
/// tick direction, or displayName), it creates a new ScaleDefinition. If the
/// init call doesn't include all properties, they get lost silently.
///
/// **This test catches**: Missing parameters in ScaleDefinition init calls
/// throughout the codebase, particularly in SlideRuleAssembly.parseComponents.
@Suite("Scale Definition Settings Preservation")
struct ScaleDefinitionPropertyPreservationTests {
    
    // MARK: - Parser Integration Tests (Primary Regression Tests)
    
    @Test("Parser preserves visibleEndValue when modifying scale height")
    func parserPreservesVisibleEndValueOnHeightChange() throws {
        // This test verifies the bug that was fixed in SlideRuleAssembly.parseComponents
        // When the parser creates a new ScaleDefinition with modified height,
        // it must preserve visibleEndValue
        
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        
        // Verify the factory sets visibleEndValue
        #expect(scale.visibleEndValue != nil, "FC283N_LL02 should have visibleEndValue set")
        #expect(scale.visibleEndValue == 0.32, "FC283N_LL02 visibleEndValue should be 0.32")
        
        // Parse a rule that includes FC283N_LL02
        // The parser will modify the scale's height, which triggers the code path
        // that previously lost visibleEndValue
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        let rule = try RuleDefinitionParser.parse(
            "(FC283N_LL02)",  // Simple rule with just this scale
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        // Get the parsed scale
        let parsedScale = rule.frontTopStator.scales.first?.definition
        #expect(parsedScale != nil, "Should have parsed the scale")
        
        // THE KEY ASSERTION: visibleEndValue must be preserved after parsing
        #expect(parsedScale?.visibleEndValue == 0.32,
                "Parser must preserve visibleEndValue! Got \(String(describing: parsedScale?.visibleEndValue))")
    }
    
    @Test("Parser preserves visibleBeginValue when modifying scale height")
    func parserPreservesVisibleBeginValueOnHeightChange() throws {
        // Test that visibleBeginValue is preserved through parsing
        // FC283N_LL02 doesn't use visibleBeginValue (it uses subsection startValue for ghost start)
        // but we verify the property preservation mechanism works
        
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        let rule = try RuleDefinitionParser.parse(
            "(FC283N_LL02)",
            dimensions: dimensions,
            scaleLength: 250.0
        )
        
        let parsedScale = rule.frontTopStator.scales.first?.definition
        
        // Whatever value was set (nil for this scale) should be preserved
        #expect(parsedScale?.visibleBeginValue == scale.visibleBeginValue,
                "Parser must preserve visibleBeginValue! Original: \(String(describing: scale.visibleBeginValue)), Parsed: \(String(describing: parsedScale?.visibleBeginValue))")
    }
    
    // MARK: - ScaleBuilder Preservation Tests
    
    @Test("ScaleBuilder preserves visibleEndValue")
    func scaleBuilderPreservesVisibleEndValue() throws {
        // Use a real scale that has visibleEndValue set
        let original = StandardScales.FC283N_LL02(length: 250.0)
        
        // ScaleBuilder.init(from:) should preserve all properties
        let rebuilt = ScaleBuilder(from: original).build()
        
        #expect(rebuilt.visibleEndValue == original.visibleEndValue,
                "ScaleBuilder must preserve visibleEndValue: expected \(String(describing: original.visibleEndValue)), got \(String(describing: rebuilt.visibleEndValue))")
    }
    
    @Test("ScaleBuilder preserves visibleBeginValue")
    func scaleBuilderPreservesVisibleBeginValue() throws {
        // Use a real scale - even if visibleBeginValue is nil, we test preservation
        let original = StandardScales.FC283N_LL02(length: 250.0)
        
        let rebuilt = ScaleBuilder(from: original).build()
        
        #expect(rebuilt.visibleBeginValue == original.visibleBeginValue,
                "ScaleBuilder must preserve visibleBeginValue: expected \(String(describing: original.visibleBeginValue)), got \(String(describing: rebuilt.visibleBeginValue))")
    }
    
    // MARK: - Mirror-Based Property Count Test
    
    @Test("ScaleDefinition property count matches expected for change detection")
    func scaleDefinitionPropertyCountMatchesExpected() throws {
        // This test uses reflection to count properties.
        // If a new property is added to ScaleDefinition but not to this test,
        // it will fail, reminding developers to update the preservation code.
        
        // Use a real scale for mirror reflection
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let mirror = Mirror(reflecting: scale)
        
        // Count stored properties (excluding computed properties)
        let propertyCount = mirror.children.count
        
        // UPDATE THIS NUMBER when adding new properties to ScaleDefinition!
        // This forces developers to consider whether the new property needs
        // to be preserved in SlideRuleAssembly and other copy locations.
        let expectedPropertyCount = 34  // Updated for visibleBeginValue/visibleEndValue
        
        #expect(propertyCount == expectedPropertyCount,
                """
                ScaleDefinition property count changed!
                Expected: \(expectedPropertyCount), Found: \(propertyCount)
                
                If you added a new property to ScaleDefinition:
                1. Update expectedPropertyCount in this test
                2. Add the property to SlideRuleAssembly.parseComponents init call
                3. Add the property to ScaleBuilder.init(from:) if needed
                4. Add property preservation assertions to this test file
                """)
    }
}
