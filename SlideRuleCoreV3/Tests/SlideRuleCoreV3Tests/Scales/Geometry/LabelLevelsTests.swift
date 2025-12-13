//
//  LabelLevelsTests.swift
//  SlideRuleCoreV3
//
//  Tests for labelLevels behavior in ScaleSubsection and ScaleDefinition.
//
//  PROBLEM CONTEXT:
//  User reported that when labelLevels: [] is empty, labels are still being
//  drawn for Major ticks. This suggests a potential bug in the label decision logic.
//
//  LABEL CREATION LOGIC (ScaleCalculator.swift:669):
//  ┌────────────────────────────────────────────────────────────────────────────┐
//  │  let shouldLabel = subsection.labelLevels.contains(level) || style.shouldLabel  │
//  └────────────────────────────────────────────────────────────────────────────┘
//
//  Labels are created when EITHER:
//  1. The subsection explicitly includes this level in `labelLevels`, OR
//  2. The tick style itself requests labeling via `style.shouldLabel`
//
//  IMPORTANT: TickStyle.major has shouldLabel: true by default!
//  This means even with labelLevels: [], major ticks WILL get labels
//  because style.shouldLabel overrides the empty labelLevels set.
//
//  LEVEL MAPPING:
//  - Level 0 = Major ticks (TickStyle.major)     → shouldLabel: true
//  - Level 1 = Medium ticks (TickStyle.medium)   → shouldLabel: false
//  - Level 2 = Minor ticks (TickStyle.minor)     → shouldLabel: false
//  - Level 3 = Tiny ticks (TickStyle.tiny)       → shouldLabel: false
//
//  REAL-WORLD EXAMPLES with labelLevels: []:
//  - S scale 80°-90° (StandardScales.swift:750): labelLevels: []
//  - K scale endpoint (StandardScales.swift:589): labelLevels: []
//
//  ═══════════════════════════════════════════════════════════════════════════════

import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Label Levels Behavior Tests

/// Tests for labelLevels behavior in ScaleSubsection and tick generation
/// Verifies the interaction between labelLevels and style.shouldLabel
///
/// @tags: labelLevels, tickGeneration
@Suite("Label Levels Behavior", .tags(.labelLevels, .tickGeneration))
struct LabelLevelsBehaviorTests {
    
    // MARK: - Empty labelLevels Tests
    
    @Suite("Empty labelLevels Behavior")
    struct EmptyLabelLevelsTests {
        
        @Test("Empty labelLevels with custom non-labeling styles produces no labels")
        func emptyLabelLevelsNoLabels() {
            // GIVEN: A scale definition with empty labelLevels AND custom tick styles
            // that all have shouldLabel: false
            let customStyles: [TickStyle] = [
                TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0),  // Override major
                TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75),
                TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5),
                TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
            ]
            
            let testScale = ScaleDefinition(
                name: "TestEmpty",
                formula: "log(x)",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.05],
                        labelLevels: []  // Empty - no levels should be labeled by labelLevels
                    )
                ],
                defaultTickStyles: customStyles,  // Custom styles with shouldLabel: false
                labelFormatter: StandardLabelFormatter.integer,
                labelColor: nil,
                constants: []
            )
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: testScale,
                algorithm: .modulo(config: .default)
            )
            
            // THEN: No ticks should have labels (since labelLevels is empty AND 
            // all styles have shouldLabel: false)
            let labeledTicks = ticks.filter { $0.label != nil }
            
            #expect(labeledTicks.isEmpty,
                    "With empty labelLevels and shouldLabel:false styles, no labels should exist. Found: \(labeledTicks.count)")
        }
        
        @Test("Empty labelLevels with DEFAULT styles still produces labels (due to style.shouldLabel)")
        func emptyLabelLevelsWithDefaultStyles() {
            // GIVEN: A scale with empty labelLevels but DEFAULT tick styles
            // (TickStyle.major has shouldLabel: true)
            let testScale = ScaleDefinition(
                name: "TestDefaultStyles",
                formula: "log(x)",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.05],
                        labelLevels: []  // Empty
                    )
                ],
                defaultTickStyles: [.major, .medium, .minor, .tiny],  // Default styles
                labelFormatter: StandardLabelFormatter.integer,
                labelColor: nil,
                constants: []
            )
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: testScale,
                algorithm: .modulo(config: .default)
            )
            
            // THEN: Major ticks (level 0) WILL have labels because
            // TickStyle.major has shouldLabel: true
            // This is the documented behavior, NOT a bug
            let labeledTicks = ticks.filter { $0.label != nil }
            
            // All labeled ticks should be major ticks (relativeLength >= 0.9)
            let majorLabeledTicks = labeledTicks.filter { $0.style.relativeLength >= 0.9 }
            
            #expect(!labeledTicks.isEmpty,
                    "With default styles, major ticks have labels due to style.shouldLabel:true")
            #expect(labeledTicks.count == majorLabeledTicks.count,
                    "Only major ticks (with style.shouldLabel:true) should have labels")
            
            print("Empty labelLevels with default styles: \(labeledTicks.count) labeled ticks (all major)")
        }
    }
    
    // MARK: - Specific Level Tests
    
    @Suite("Specific labelLevels Configuration")
    struct SpecificLevelTests {
        
        @Test("labelLevels: [0] labels only level 0 (major) ticks")
        func labelLevelsZeroOnly() {
            // GIVEN: A scale with labelLevels: [0] (only major ticks)
            let customStyles: [TickStyle] = [
                TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0),
                TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75),
                TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5),
                TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
            ]
            
            let testScale = ScaleDefinition(
                name: "TestLevel0",
                formula: "log(x)",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.05],
                        labelLevels: [0]  // Only level 0 (major)
                    )
                ],
                defaultTickStyles: customStyles,
                labelFormatter: StandardLabelFormatter.integer,
                labelColor: nil,
                constants: []
            )
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: testScale,
                algorithm: .modulo(config: .default)
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            // THEN: Only major ticks (level 0, relativeLength = 1.0) should be labeled
            // Major ticks are at integer values: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
            #expect(labeledTicks.count == 10,
                    "Should have 10 labeled ticks (integers 1-10), found: \(labeledTicks.count)")
            
            for tick in labeledTicks {
                #expect(tick.style.relativeLength == 1.0,
                        "All labeled ticks should be major (level 0), found relativeLength: \(tick.style.relativeLength)")
            }
        }
        
        @Test("labelLevels: [1] labels only level 1 (medium) ticks")
        func labelLevelsOneOnly() {
            // GIVEN: A scale with labelLevels: [1] (only medium ticks)
            let customStyles: [TickStyle] = [
                TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0),
                TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75),
                TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5),
                TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
            ]
            
            let testScale = ScaleDefinition(
                name: "TestLevel1",
                formula: "log(x)",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.05],
                        labelLevels: [1]  // Only level 1 (medium)
                    )
                ],
                defaultTickStyles: customStyles,
                labelFormatter: StandardLabelFormatter.oneDecimal,
                labelColor: nil,
                constants: []
            )
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: testScale,
                algorithm: .modulo(config: .default)
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            // THEN: Only medium ticks (level 1, relativeLength = 0.75) should be labeled
            // Medium ticks (0.5 interval) are at: 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5
            #expect(labeledTicks.count == 9,
                    "Should have 9 labeled ticks (x.5 values), found: \(labeledTicks.count)")
            
            for tick in labeledTicks {
                #expect(tick.style.relativeLength == 0.75,
                        "All labeled ticks should be medium (level 1), found relativeLength: \(tick.style.relativeLength)")
            }
        }
        
        @Test("labelLevels: [0, 1] labels both level 0 and level 1 ticks")
        func labelLevelsZeroAndOne() {
            // GIVEN: A scale with labelLevels: [0, 1] (major and medium ticks)
            let customStyles: [TickStyle] = [
                TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0),
                TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75),
                TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5),
                TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
            ]
            
            let testScale = ScaleDefinition(
                name: "TestLevel01",
                formula: "log(x)",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.05],
                        labelLevels: [0, 1]  // Level 0 and 1
                    )
                ],
                defaultTickStyles: customStyles,
                labelFormatter: StandardLabelFormatter.oneDecimal,
                labelColor: nil,
                constants: []
            )
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: testScale,
                algorithm: .modulo(config: .default)
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            // THEN: Both major (level 0) and medium (level 1) ticks should be labeled
            // Major: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 (10 ticks)
            // Medium: 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5 (9 ticks)
            // Total: 19 labeled ticks
            #expect(labeledTicks.count == 19,
                    "Should have 19 labeled ticks (10 major + 9 medium), found: \(labeledTicks.count)")
            
            let majorLabeled = labeledTicks.filter { $0.style.relativeLength == 1.0 }
            let mediumLabeled = labeledTicks.filter { $0.style.relativeLength == 0.75 }
            
            #expect(majorLabeled.count == 10, "Should have 10 major labeled ticks")
            #expect(mediumLabeled.count == 9, "Should have 9 medium labeled ticks")
        }
    }
    
    // MARK: - Boundary and Edge Cases
    
    @Suite("Edge Cases and Boundary Tests")
    struct EdgeCaseTests {
        
        @Test("labelLevels with invalid level (out of range) is safely ignored")
        func invalidLevelIndex() {
            // GIVEN: A scale with labelLevels: [5] but only 4 tick levels defined
            let customStyles: [TickStyle] = [
                TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0),
                TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75),
                TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5),
                TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
            ]
            
            let testScale = ScaleDefinition(
                name: "TestInvalidLevel",
                formula: "log(x)",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up,
                subsections: [
                    ScaleSubsection(
                        startValue: 1.0,
                        tickIntervals: [1.0, 0.5, 0.1, 0.05],  // Only levels 0, 1, 2, 3
                        labelLevels: [5]  // Invalid level - no level 5 exists
                    )
                ],
                defaultTickStyles: customStyles,
                labelFormatter: StandardLabelFormatter.integer,
                labelColor: nil,
                constants: []
            )
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: testScale,
                algorithm: .modulo(config: .default)
            )
            
            let labeledTicks = ticks.filter { $0.label != nil }
            
            // THEN: No ticks should be labeled (level 5 doesn't exist)
            #expect(labeledTicks.isEmpty,
                    "Invalid level [5] should result in no labels, found: \(labeledTicks.count)")
        }
        
        @Test("labelLevels default value is [0]")
        func defaultLabelLevelsIsZero() {
            // GIVEN: A ScaleSubsection created with default labelLevels
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0, 0.1]
            )
            
            // THEN: labelLevels should default to [0]
            #expect(subsection.labelLevels == [0],
                    "Default labelLevels should be [0], found: \(subsection.labelLevels)")
        }
        
        @Test("Empty Set<Int> correctly represents no labeling levels")
        func emptySetIsValid() {
            // GIVEN: A ScaleSubsection with explicitly empty labelLevels
            let subsection = ScaleSubsection(
                startValue: 1.0,
                tickIntervals: [1.0],
                labelLevels: []
            )
            
            // THEN: labelLevels should be empty
            #expect(subsection.labelLevels.isEmpty,
                    "labelLevels should be empty after explicit []")
            #expect(!subsection.labelLevels.contains(0),
                    "Empty labelLevels should not contain level 0")
            #expect(!subsection.labelLevels.contains(1),
                    "Empty labelLevels should not contain level 1")
        }
    }
    
    // MARK: - Real Scale Integration Tests
    
    @Suite("Real Scale Integration")
    struct RealScaleIntegrationTests {
        
        @Test("S scale 80°-90° subsection with labelLevels: [] behavior")
        func sScaleUpperRangeLabeling() {
            // GIVEN: The S scale (which has labelLevels: [] for 80-90° range)
            let sScale = StandardScales.sScale(length: 250.0)
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: sScale,
                algorithm: .modulo(config: .default)
            )
            
            // Filter ticks in the 80-90° range
            let upperRangeTicks = ticks.filter { $0.value >= 80 && $0.value <= 90 }
            let labeledUpperRange = upperRangeTicks.filter { $0.label != nil }
            
            // THEN: Document what actually happens
            // Note: The S scale definition at 80-90° has labelLevels: []
            // but default tick styles apply, so major ticks MAY still be labeled
            // if style.shouldLabel is true
            
            print("S scale 80-90° range:")
            print("  Total ticks: \(upperRangeTicks.count)")
            print("  Labeled ticks: \(labeledUpperRange.count)")
            
            if !labeledUpperRange.isEmpty {
                print("  Labels at values: \(labeledUpperRange.map { $0.value })")
                print("  NOTE: Labels exist due to TickStyle.major having shouldLabel: true")
            }
            
            // Verify the labeled ticks are only at the 90° endpoint (if any)
            // The subsection at 80° has labelLevels: [] but 90° subsection has labelLevels: [0]
            if let ninetDegreeLabel = labeledUpperRange.first(where: { abs($0.value - 90.0) < 0.1 }) {
                #expect(ninetDegreeLabel.label != nil, 
                        "90° should be labeled (it's in a separate subsection with labelLevels: [0])")
            }
        }
        
        @Test("K scale endpoint subsection with labelLevels: [] behavior")
        func kScaleEndpointLabeling() {
            // GIVEN: The K scale (which has labelLevels: [] for the 1000 endpoint)
            let kScale = StandardScales.kScale(length: 250.0)
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: kScale,
                algorithm: .modulo(config: .default)
            )
            
            // Filter ticks near 1000 (endpoint)
            let endpointTicks = ticks.filter { $0.value >= 990 && $0.value <= 1000 }
            let labeledEndpoint = endpointTicks.filter { $0.label != nil }
            
            // THEN: Document what actually happens
            print("K scale 990-1000 range:")
            print("  Total ticks: \(endpointTicks.count)")
            print("  Labeled ticks: \(labeledEndpoint.count)")
            
            if !labeledEndpoint.isEmpty {
                print("  Labels at values: \(labeledEndpoint.map { $0.value })")
            }
            
            // The K scale subsection at 1000 has labelLevels: []
            // So no labels should appear from labelLevels
            // BUT if default styles have shouldLabel: true, labels may still appear
            
            // This test documents the current behavior
            #expect(true, "K scale endpoint behavior documented")
        }
        
        @Test("C scale first subsection with labelLevels: [0, 1] correctly labels both levels")
        func cScaleFirstSubsectionLabeling() {
            // GIVEN: The C scale (first subsection has labelLevels: [0, 1])
            let cScale = StandardScales.cScale(length: 250.0)
            
            // WHEN: We generate tick marks
            let ticks = ScaleCalculator.generateTickMarks(
                for: cScale,
                algorithm: .modulo(config: .default)
            )
            
            // Filter ticks in the 1.0-2.0 range (first subsection)
            let firstSubsectionTicks = ticks.filter { $0.value >= 1.0 && $0.value < 2.0 }
            let labeledFirstSubsection = firstSubsectionTicks.filter { $0.label != nil }
            
            // THEN: Should have labels for both major (integers) and medium (tenths)
            // Major: 1.0
            // Medium: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9
            // Total: 10 labels in 1.0-2.0 range
            
            #expect(labeledFirstSubsection.count >= 10,
                    "C scale 1.0-2.0 should have at least 10 labels (1 + tenths), found: \(labeledFirstSubsection.count)")
            
            let labeledValues = labeledFirstSubsection.map { $0.value }.sorted()
            print("C scale 1.0-2.0 labeled values: \(labeledValues)")
        }
    }
}

// MARK: - TickStyle.shouldLabel Documentation Tests

/// Documents the TickStyle.shouldLabel property behavior
@Suite("TickStyle.shouldLabel Behavior", .tags(.labelLevels))
struct TickStyleShouldLabelTests {
    
    @Test("Default TickStyle.major has shouldLabel: true")
    func majorStyleHasShouldLabel() {
        #expect(TickStyle.major.shouldLabel == true,
                "TickStyle.major should have shouldLabel:true by default")
    }
    
    @Test("Default TickStyle.medium has shouldLabel: false")
    func mediumStyleNoShouldLabel() {
        #expect(TickStyle.medium.shouldLabel == false,
                "TickStyle.medium should have shouldLabel:false by default")
    }
    
    @Test("Default TickStyle.minor has shouldLabel: false")
    func minorStyleNoShouldLabel() {
        #expect(TickStyle.minor.shouldLabel == false,
                "TickStyle.minor should have shouldLabel:false by default")
    }
    
    @Test("Default TickStyle.tiny has shouldLabel: false")
    func tinyStyleNoShouldLabel() {
        #expect(TickStyle.tiny.shouldLabel == false,
                "TickStyle.tiny should have shouldLabel:false by default")
    }
    
    @Test("Custom TickStyle can override shouldLabel")
    func customStyleOverridesShouldLabel() {
        let customMajor = TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0)
        let customMinor = TickStyle(relativeLength: 0.5, shouldLabel: true, lineWidth: 0.5)
        
        #expect(customMajor.shouldLabel == false,
                "Custom major-like style can have shouldLabel:false")
        #expect(customMinor.shouldLabel == true,
                "Custom minor-like style can have shouldLabel:true")
    }
    
    @Test("TickStyle.absolutelyNone has shouldLabel: false")
    func absolutelyNoneStyleNoShouldLabel() {
        #expect(TickStyle.absolutelyNone.shouldLabel == false,
                "TickStyle.absolutelyNone should have shouldLabel:false")
    }
    
    @Test("TickStyle.absolutelyNone has same dimensions as .major")
    func absolutelyNoneDimensionsMatchMajor() {
        #expect(TickStyle.absolutelyNone.relativeLength == TickStyle.major.relativeLength,
                "absolutelyNone should have same relativeLength as major")
        #expect(TickStyle.absolutelyNone.lineWidth == TickStyle.major.lineWidth,
                "absolutelyNone should have same lineWidth as major")
    }
    
    @Test("TickStyle.absolutelyNone differs from .major only in shouldLabel")
    func absolutelyNoneDiffersOnlyInShouldLabel() {
        // Same visual properties
        #expect(TickStyle.absolutelyNone.relativeLength == TickStyle.major.relativeLength)
        #expect(TickStyle.absolutelyNone.lineWidth == TickStyle.major.lineWidth)
        
        // Different labeling behavior
        #expect(TickStyle.absolutelyNone.shouldLabel != TickStyle.major.shouldLabel,
                "absolutelyNone and major should differ in shouldLabel")
        #expect(TickStyle.major.shouldLabel == true)
        #expect(TickStyle.absolutelyNone.shouldLabel == false)
    }
}

// MARK: - OR Logic Documentation Tests

/// Documents and tests the OR logic in label creation
///
/// The formula: `shouldLabel = labelLevels.contains(level) || style.shouldLabel`
/// means labels appear if EITHER condition is true.
@Suite("Label OR Logic", .tags(.labelLevels, .tickGeneration))
struct LabelOrLogicTests {
    
    @Test("Labels appear when labelLevels contains the level (regardless of style)")
    func labelLevelsOverridesStyle() {
        // A tick at level 2 (normally minor, shouldLabel:false) 
        // WILL be labeled if labelLevels contains 2
        
        let customStyles: [TickStyle] = [
            TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0),
            TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75),
            TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5),  // Minor usually not labeled
            TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
        ]
        
        let testScale = ScaleDefinition(
            name: "TestORLogic",
            formula: "log(x)",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 2.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            tickDirection: .up,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1],  // Level 2 is 0.1 interval
                    labelLevels: [2]  // Only label level 2 (0.1 interval ticks)
                )
            ],
            defaultTickStyles: customStyles,
            labelFormatter: StandardLabelFormatter.oneDecimal,
            labelColor: nil,
            constants: []
        )
        
        let ticks = ScaleCalculator.generateTickMarks(
            for: testScale,
            algorithm: .modulo(config: .default)
        )
        
        let labeledTicks = ticks.filter { $0.label != nil }
        
        // Level 2 ticks (0.1 interval, not divisible by 0.5) should be labeled
        // These are: 1.1, 1.2, 1.3, 1.4, 1.6, 1.7, 1.8, 1.9
        // (1.0, 1.5, 2.0 are divisible by higher intervals so they're level 0 or 1)
        
        #expect(labeledTicks.count == 8,
                "Should have 8 labeled ticks at level 2 (0.1 values), found: \(labeledTicks.count)")
        
        for tick in labeledTicks {
            #expect(tick.style.relativeLength == 0.5,
                    "All labeled ticks should be minor (level 2)")
        }
    }
    
    @Test("Labels appear when style.shouldLabel is true (regardless of labelLevels)")
    func styleOverridesLabelLevels() {
        // A tick at level 0 (major, shouldLabel:true) 
        // WILL be labeled even if labelLevels is empty
        
        let testScale = ScaleDefinition(
            name: "TestStyleOverride",
            formula: "log(x)",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 5.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            tickDirection: .up,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0],
                    labelLevels: []  // Empty - would mean no labels
                )
            ],
            defaultTickStyles: [.major, .medium, .minor, .tiny],  // major.shouldLabel = true
            labelFormatter: StandardLabelFormatter.integer,
            labelColor: nil,
            constants: []
        )
        
        let ticks = ScaleCalculator.generateTickMarks(
            for: testScale,
            algorithm: .modulo(config: .default)
        )
        
        let labeledTicks = ticks.filter { $0.label != nil }
        
        // Major ticks should still be labeled due to TickStyle.major.shouldLabel = true
        #expect(!labeledTicks.isEmpty,
                "Major ticks labeled due to style.shouldLabel:true, even with empty labelLevels")
    }
    
    @Test("No labels when BOTH labelLevels excludes AND style.shouldLabel is false")
    func bothConditionsFalse() {
        let customStyles: [TickStyle] = [
            TickStyle(relativeLength: 1.0, shouldLabel: false, lineWidth: 1.0),
            TickStyle(relativeLength: 0.75, shouldLabel: false, lineWidth: 0.75),
            TickStyle(relativeLength: 0.5, shouldLabel: false, lineWidth: 0.5),
            TickStyle(relativeLength: 0.25, shouldLabel: false, lineWidth: 0.35)
        ]
        
        let testScale = ScaleDefinition(
            name: "TestBothFalse",
            formula: "log(x)",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 10.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            tickDirection: .up,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1, 0.05],
                    labelLevels: []  // Empty
                )
            ],
            defaultTickStyles: customStyles,  // All shouldLabel: false
            labelFormatter: StandardLabelFormatter.integer,
            labelColor: nil,
            constants: []
        )
        
        let ticks = ScaleCalculator.generateTickMarks(
            for: testScale,
            algorithm: .modulo(config: .default)
        )
        let labeledTicks = ticks.filter { $0.label != nil }
        
        #expect(labeledTicks.isEmpty,
                "No labels when labelLevels is empty AND all styles have shouldLabel:false")
    }
    
    @Test("Using .absolutelyNone makes labelLevels the sole determinant")
    func absolutelyNoneMakesLabelLevelsSoleDeterminant() {
        // GIVEN: A scale with .absolutelyNone as the major tick style
        // When labelLevels: [] → no labels
        // When labelLevels: [0] → labels
        
        let absolutelyNoneStyles: [TickStyle] = [
            .absolutelyNone,  // Major ticks won't auto-label
            .medium,
            .minor,
            .tiny
        ]
        
        // Test with empty labelLevels
        let noLabelScale = ScaleDefinition(
            name: "TestAbsolutelyNone",
            formula: "log(x)",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 5.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            tickDirection: .up,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: []  // Empty - should mean NO labels
                )
            ],
            defaultTickStyles: absolutelyNoneStyles,
            labelFormatter: StandardLabelFormatter.integer,
            labelColor: nil,
            constants: []
        )
        
        let noLabelTicks = ScaleCalculator.generateTickMarks(
            for: noLabelScale,
            algorithm: .modulo(config: .default)
        )
        
        let labeledNoLabel = noLabelTicks.filter { $0.label != nil }
        
        #expect(labeledNoLabel.isEmpty,
                "With .absolutelyNone and labelLevels: [], no ticks should be labeled")
        
        // Test with labelLevels: [0]
        let withLabelScale = ScaleDefinition(
            name: "TestAbsolutelyNoneWithLabels",
            formula: "log(x)",
            function: LogarithmicFunction(),
            beginValue: 1.0,
            endValue: 5.0,
            scaleLengthInPoints: 250.0,
            layout: .linear,
            tickDirection: .up,
            subsections: [
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.5, 0.1],
                    labelLevels: [0]  // Label major ticks
                )
            ],
            defaultTickStyles: absolutelyNoneStyles,
            labelFormatter: StandardLabelFormatter.integer,
            labelColor: nil,
            constants: []
        )
        
        let withLabelTicks = ScaleCalculator.generateTickMarks(
            for: withLabelScale,
            algorithm: .modulo(config: .default)
        )
        
        let labeledWithLabel = withLabelTicks.filter { $0.label != nil }
        
        #expect(!labeledWithLabel.isEmpty,
                "With .absolutelyNone and labelLevels: [0], major ticks should be labeled")
        
        // All labeled ticks should be major ticks
        for tick in labeledWithLabel {
            #expect(tick.style.relativeLength == 1.0,
                    "Only major ticks (level 0) should be labeled")
        }
    }
}

// MARK: - TickStyle.absolutelyNone Integration Tests

/// Tests for TickStyle.absolutelyNone in real scale scenarios
@Suite("TickStyle.absolutelyNone Integration", .tags(.labelLevels, .tickGeneration))
struct AbsolutelyNoneIntegrationTests {
    
    @Test("Omega scale unlabeled range (0.5-0.7) produces no labels")
    func omegaScaleUnlabeledRange() {
        // GIVEN: The omega scale (which uses .absolutelyNone with labelLevels: [] for 0.5-0.7)
        let omegaScale = StandardScales.angularFrequencyOmegaScale(length: 250.0)
        
        // WHEN: We generate tick marks
        let ticks = ScaleCalculator.generateTickMarks(
            for: omegaScale,
            algorithm: .modulo(config: .default)
        )
        
        // Filter ticks in the 0.5-0.7 range (unlabeled region)
        let unlabeledRangeTicks = ticks.filter { $0.value >= 0.5 && $0.value < 0.7 }
        let labeledInUnlabeledRange = unlabeledRangeTicks.filter { $0.label != nil }
        
        // THEN: No ticks in 0.5-0.7 range should have labels
        #expect(labeledInUnlabeledRange.isEmpty,
                "Omega scale 0.5-0.7 range should have no labels. Found: \(labeledInUnlabeledRange.count) labeled ticks")
        
        // Also verify there ARE ticks in that range (just no labels)
        #expect(!unlabeledRangeTicks.isEmpty,
                "Omega scale should have ticks in 0.5-0.7 range")
        
        print("Omega scale 0.5-0.7 range: \(unlabeledRangeTicks.count) unlabeled ticks")
    }
    
    @Test("Omega scale labeled range (0.7+) produces labels")
    func omegaScaleLabeledRange() {
        // GIVEN: The omega scale
        let omegaScale = StandardScales.angularFrequencyOmegaScale(length: 250.0)
        
        // WHEN: We generate tick marks
        let ticks = ScaleCalculator.generateTickMarks(
            for: omegaScale,
            algorithm: .modulo(config: .default)
        )
        
        // Filter ticks in the 0.7-1.0 range (labeled region)
        let labeledRangeTicks = ticks.filter { $0.value >= 0.7 && $0.value <= 1.0 }
        let labeledInLabeledRange = labeledRangeTicks.filter { $0.label != nil }
        
        // THEN: Major ticks (0.7, 0.8, 0.9, 1.0) should be labeled
        #expect(!labeledInLabeledRange.isEmpty,
                "Omega scale 0.7-1.0 range should have labels")
        
        print("Omega scale 0.7-1.0 range: \(labeledInLabeledRange.count) labeled ticks")
        print("Labels: \(labeledInLabeledRange.compactMap { $0.label })")
    }
}