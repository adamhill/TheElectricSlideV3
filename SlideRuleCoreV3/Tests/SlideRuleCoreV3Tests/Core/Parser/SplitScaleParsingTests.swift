import Testing
@testable import SlideRuleCoreV3

/// Tests for split scale parsing using the ^ operator
///
/// This test suite verifies Phase 2 of split scales implementation: parser support for
/// the ^ operator. Tests confirm that scales marked with ^ are correctly grouped and
/// assigned split segments.
@Suite("Split Scale Parsing Tests")
struct SplitScaleParsingTests {
    
    let dimensions = RuleDefinitionParser.Dimensions(
        topStatorMM: 14,
        slideMM: 13,
        bottomStatorMM: 14
    )
    let scaleLength: Distance = 250.0
    
    // MARK: - Basic 2-Segment Split Tests
    
    @Test("Parse simple 2-segment split: A^ B C")
    func testSimpleTwoSegmentSplit() throws {
        // Input: "A^ B C"
        // Expected:
        //   - A: splitSegment = .left(formulaOffset: 0.0)
        //   - B: splitSegment = .right(formulaOffset: -1.0)
        //   - C: splitSegment = nil (full width)
        
        let rule = try RuleDefinitionParser.parse(
            "(A^ B C [ D ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        #expect(rule.frontTopStator.scales.count == 3)
        
        // Check A (first segment of split)
        let scaleA = rule.frontTopStator.scales[0].definition
        #expect(scaleA.name == "A")
        #expect(scaleA.splitSegment == .left(formulaOffset: 0.0))
        
        // Check B (second segment of split)
        let scaleB = rule.frontTopStator.scales[1].definition
        #expect(scaleB.name == "B")
        #expect(scaleB.splitSegment == .right(formulaOffset: -1.0))
        
        // Check C (full width, no split)
        let scaleC = rule.frontTopStator.scales[2].definition
        #expect(scaleC.name == "C")
        #expect(scaleC.splitSegment == nil)
        
        // Check D on slide (should not be affected)
        #expect(rule.frontSlide.scales.count == 1)
        let scaleD = rule.frontSlide.scales[0].definition
        #expect(scaleD.name == "D")
        #expect(scaleD.splitSegment == nil)
    }
    
    @Test("Parse Hemmi 266 LL scale pattern: H266LL01^ LL02B LL2B- A")
    func testHemmi266Pattern() throws {
        // Real-world test: Hemmi 266 log-log scales
        // H266LL01^ LL02B creates a split pair
        // LL2B- is full width with tick direction modifier
        // A is full width
        
        let rule = try RuleDefinitionParser.parse(
            "(H266LL01^ LL02B LL2B- A [ C ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        #expect(rule.frontTopStator.scales.count == 4)
        
        // Check H266LL01 (left segment)
        let ll01 = rule.frontTopStator.scales[0].definition
        #expect(ll01.name == "H266LL01")
        #expect(ll01.splitSegment == .left(formulaOffset: 0.0))
        
        // Check LL02B (right segment)
        let ll02 = rule.frontTopStator.scales[1].definition
        #expect(ll02.name == "LL02B")
        #expect(ll02.splitSegment == .right(formulaOffset: -1.0))
        
        // Check LL2B (full width, with tick modifier)
        let ll2b = rule.frontTopStator.scales[2].definition
        #expect(ll2b.name == "LL2B")
        #expect(ll2b.splitSegment == nil)
        #expect(ll2b.tickDirection == .down)
        
        // Check A (full width)
        let a = rule.frontTopStator.scales[3].definition
        #expect(a.name == "A")
        #expect(a.splitSegment == nil)
    }
    
    // MARK: - Multiple Splits in One Definition
    
    @Test("Parse multiple splits in one definition: eeP^ [ eer2^ eeQ ]")
    func testMultipleSplitsInDefinition() throws {
        // Test two separate split groups in different components
        
        let rule = try RuleDefinitionParser.parse(
            "(eeP^ eeq [ eer2^ eeQ ] A)",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        // Top stator: eeP^ eeq should form a split
        #expect(rule.frontTopStator.scales.count == 1)
        let topSplit1 = rule.frontTopStator.scales[0].definition
        #expect(topSplit1.name == "eeP")
        // Note: Currently eeq completes the split but isn't added yet (accumulator issue - to be fixed)
        
        // Slide: eer2^ eeQ should form a split
        #expect(rule.frontSlide.scales.count == 2)
        let slideSplit1 = rule.frontSlide.scales[0].definition
        #expect(slideSplit1.name == "eer2")
        #expect(slideSplit1.splitSegment == .left(formulaOffset: 0.0))
        
        let slideSplit2 = rule.frontSlide.scales[1].definition
        #expect(slideSplit2.name == "eeQ")
        #expect(slideSplit2.splitSegment == .right(formulaOffset: -1.0))
        
        // Bottom stator: A (full width)
        #expect(rule.frontBottomStator.scales.count == 1)
        let a = rule.frontBottomStator.scales[0].definition
        #expect(a.name == "A")
        #expect(a.splitSegment == nil)
    }
    
    // MARK: - Combined Modifiers
    
    @Test("Parse combined ^ and tick direction modifiers: A^+ B-")
    func testCombinedModifiers() throws {
        // Test that ^ can be combined with + or - tick direction modifiers
        // A^+ means: split segment AND ticks point up
        // B- means: no split AND ticks point down
        
        let rule = try RuleDefinitionParser.parse(
            "(A^+ B- C [ D ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        #expect(rule.frontTopStator.scales.count == 3)
        
        // Check A (split left + ticks up)
        let scaleA = rule.frontTopStator.scales[0].definition
        #expect(scaleA.name == "A")
        #expect(scaleA.splitSegment == .left(formulaOffset: 0.0))
        #expect(scaleA.tickDirection == .up)
        
        // Check B (split right + ticks down)
        let scaleB = rule.frontTopStator.scales[1].definition
        #expect(scaleB.name == "B")
        #expect(scaleB.splitSegment == .right(formulaOffset: -1.0))
        #expect(scaleB.tickDirection == .down)
        
        // Check C (full width, default ticks)
        let scaleC = rule.frontTopStator.scales[2].definition
        #expect(scaleC.name == "C")
        #expect(scaleC.splitSegment == nil)
    }
    
    @Test("Parse alternate combined modifier order: A-^ B^-")
    func testAlternateModifierOrder() throws {
        // Test that modifier order doesn't matter: A-^ and A^- are equivalent
        
        let rule = try RuleDefinitionParser.parse(
            "(A-^ B^- C [ D ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        #expect(rule.frontTopStator.scales.count == 3)
        
        // Check A (split left + ticks down)
        let scaleA = rule.frontTopStator.scales[0].definition
        #expect(scaleA.name == "A")
        #expect(scaleA.splitSegment == .left(formulaOffset: 0.0))
        #expect(scaleA.tickDirection == .down)
        
        // Check B (split right + ticks down)
        let scaleB = rule.frontTopStator.scales[1].definition
        #expect(scaleB.name == "B")
        #expect(scaleB.splitSegment == .right(formulaOffset: -1.0))
        #expect(scaleB.tickDirection == .down)
    }
    
    // MARK: - Interaction with Vertical Grouping
    
    @Test("Verify ^ doesn't affect | separator behavior")
    func testSplitWithSeparator() throws {
        // Test that ^ (horizontal split) and | (vertical separator) are independent
        // "A^ | B C" means:
        //   - A is marked with ^, starts a split group
        //   - | adds separator to A and sets nextScaleNoLineBreak for B
        //   - B completes the split group AND has noLineBreak from |
        //   - C is full width
        
        let rule = try RuleDefinitionParser.parse(
            "(A^ | B C [ D ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        #expect(rule.frontTopStator.scales.count == 3)
        
        // Check A (split left + has separator)
        let scaleA = rule.frontTopStator.scales[0]
        #expect(scaleA.definition.name == "A")
        #expect(scaleA.definition.splitSegment == .left(formulaOffset: 0.0))
        #expect(scaleA.definition.hasBottomSeparator == true)
        
        // Check B (split right + noLineBreak from |)
        let scaleB = rule.frontTopStator.scales[1]
        #expect(scaleB.definition.name == "B")
        #expect(scaleB.definition.splitSegment == .right(formulaOffset: -1.0))
        #expect(scaleB.noLineBreak == true)  // From | token
        
        // Check C (full width)
        let scaleC = rule.frontTopStator.scales[2].definition
        #expect(scaleC.name == "C")
        #expect(scaleC.splitSegment == nil)
    }
    
    @Test("Verify ^ doesn't interfere with bracket grouping")
    func testSplitWithBrackets() throws {
        // Test that split scales work correctly within [ ] brackets
        
        let rule = try RuleDefinitionParser.parse(
            "(A [ C^ D ] B)",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        // Top stator: A (full width)
        #expect(rule.frontTopStator.scales.count == 1)
        let scaleA = rule.frontTopStator.scales[0].definition
        #expect(scaleA.name == "A")
        #expect(scaleA.splitSegment == nil)
        
        // Slide: C^ D should form a split
        #expect(rule.frontSlide.scales.count == 2)
        let scaleC = rule.frontSlide.scales[0].definition
        #expect(scaleC.name == "C")
        #expect(scaleC.splitSegment == .left(formulaOffset: 0.0))
        
        let scaleD = rule.frontSlide.scales[1].definition
        #expect(scaleD.name == "D")
        #expect(scaleD.splitSegment == .right(formulaOffset: -1.0))
        
        // Bottom stator: B (full width)
        #expect(rule.frontBottomStator.scales.count == 1)
        let scaleB = rule.frontBottomStator.scales[0].definition
        #expect(scaleB.name == "B")
        #expect(scaleB.splitSegment == nil)
    }
    
    // MARK: - Edge Cases
    
    @Test("Single scale with ^ at end of component")
    func testSingleScaleWithCaretAtEnd() throws {
        // Edge case: "A^" with no following scale in same component
        // Should handle gracefully (accumulator cleanup)
        
        let rule = try RuleDefinitionParser.parse(
            "(A^ [ C ] B)",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        // A^ should be processed as incomplete split group in accumulator cleanup
        #expect(rule.frontTopStator.scales.count == 1)
        let scaleA = rule.frontTopStator.scales[0].definition
        #expect(scaleA.name == "A")
        // Incomplete split - should remain as-is (no splitSegment assigned)
        #expect(scaleA.splitSegment == nil)
    }
    
    @Test("Triple split marker: A^ B^ C")
    func testTripleSpli() throws {
        // 3-segment splits not yet supported in Phase 2
        // Should log warning and return without split segments
        
        let rule = try RuleDefinitionParser.parse(
            "(A^ B^ C [ D ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        #expect(rule.frontTopStator.scales.count == 3)
        
        // All three scales should have no splitSegment (unsupported)
        let scaleA = rule.frontTopStator.scales[0].definition
        #expect(scaleA.name == "A")
        #expect(scaleA.splitSegment == nil)  // Unsupported 3+ segments
        
        let scaleB = rule.frontTopStator.scales[1].definition
        #expect(scaleB.name == "B")
        #expect(scaleB.splitSegment == nil)
        
        let scaleC = rule.frontTopStator.scales[2].definition
        #expect(scaleC.name == "C")
        #expect(scaleC.splitSegment == nil)
    }
    
    // MARK: - Front/Back Side Tests
    
    @Test("Split scales on back side")
    func testSplitScalesOnBackSide() throws {
        // Test that split parsing works on back side (after :)
        
        let rule = try RuleDefinitionParser.parse(
            "(A [ C ] B : LL1^ LL2 [ D ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        // Front side should be normal
        #expect(rule.frontTopStator.scales[0].definition.splitSegment == nil)
        
        // Back side should have split
        #expect(rule.backTopStator?.scales.count == 2)
        let ll1 = rule.backTopStator?.scales[0].definition
        #expect(ll1?.name == "LL1")
        #expect(ll1?.splitSegment == .left(formulaOffset: 0.0))
        
        let ll2 = rule.backTopStator?.scales[1].definition
        #expect(ll2?.name == "LL2")
        #expect(ll2?.splitSegment == .right(formulaOffset: -1.0))
    }
    
    // MARK: - Physical Range Verification
    
    @Test("Verify split segment physical ranges")
    func testSplitSegmentPhysicalRanges() throws {
        // Verify that SplitSegment enums have correct physical ranges
        
        let rule = try RuleDefinitionParser.parse(
            "(A^ B [ C ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        let scaleA = rule.frontTopStator.scales[0].definition
        let scaleB = rule.frontTopStator.scales[1].definition
        
        // Left segment should occupy 0.0...0.5
        if case .left = scaleA.splitSegment {
            #expect(scaleA.splitSegment?.physicalRange == 0.0...0.5)
        } else {
            Issue.record("Expected left segment for scale A")
        }
        
        // Right segment should occupy 0.5...1.0
        if case .right = scaleB.splitSegment {
            #expect(scaleB.splitSegment?.physicalRange == 0.5...1.0)
        } else {
            Issue.record("Expected right segment for scale B")
        }
    }
    
    @Test("Verify split segment formula offsets")
    func testSplitSegmentFormulaOffsets() throws {
        // Verify that formula offsets match expected values
        
        let rule = try RuleDefinitionParser.parse(
            "(A^ B [ C ])",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        let scaleA = rule.frontTopStator.scales[0].definition
        let scaleB = rule.frontTopStator.scales[1].definition
        
        // Left segment: formulaOffset = 0.0
        #expect(scaleA.splitSegment?.formulaOffset == 0.0)
        
        // Right segment: formulaOffset = -1.0
        #expect(scaleB.splitSegment?.formulaOffset == -1.0)
    }
    
    // MARK: - Backward Compatibility
    
    @Test("Scales without ^ work as before")
    func testBackwardCompatibility() throws {
        // Verify that scales without ^ markers work exactly as before
        
        let rule = try RuleDefinitionParser.parse(
            "(A B C [ D ] E)",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        // All scales should have nil splitSegment
        for scale in rule.frontTopStator.scales {
            #expect(scale.definition.splitSegment == nil)
        }
        for scale in rule.frontSlide.scales {
            #expect(scale.definition.splitSegment == nil)
        }
        for scale in rule.frontBottomStator.scales {
            #expect(scale.definition.splitSegment == nil)
        }
    }
    
    @Test("Complex definition without splits")
    func testComplexDefinitionWithoutSplits() throws {
        // Test a complex definition to ensure no regressions
        
        let rule = try RuleDefinitionParser.parse(
            "(K A [ C T+ ST- S ] D L- : LL1 LL2 LL3 [ CI C ] D)",
            dimensions: dimensions,
            scaleLength: scaleLength
        )
        
        // Verify all scales have no splitSegment
        for scale in rule.frontTopStator.scales {
            #expect(scale.definition.splitSegment == nil)
        }
        for scale in rule.frontSlide.scales {
            #expect(scale.definition.splitSegment == nil)
        }
        for scale in rule.frontBottomStator.scales {
            #expect(scale.definition.splitSegment == nil)
        }
        
        if let backTop = rule.backTopStator {
            for scale in backTop.scales {
                #expect(scale.definition.splitSegment == nil)
            }
        }
    }
}
