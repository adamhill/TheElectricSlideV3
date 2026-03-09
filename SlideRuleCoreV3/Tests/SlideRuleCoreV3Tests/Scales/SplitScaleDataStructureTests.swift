import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests for split scale data structures (Phase 1)
///
/// This test suite validates the foundational data structures for split scale support:
/// - `SplitSegment` enum with physical ranges and computed properties
/// - `ScaleDefinition` integration with optional splitSegment property
/// - `ScaleBuilder` fluent API support for split scales
///
/// Phase 1 focuses solely on data structures; parser and rendering logic are future phases.
@Suite("Split Scale Data Structures", .tags(.fast, .dataStructures))
struct SplitScaleDataStructureTests {
    
    // MARK: - SplitSegment Physical Ranges
    
    @Suite("Physical Range Calculations")
    struct PhysicalRanges {
        
        @Test("Left segment physical range is 0.0...0.5")
        func leftSegmentPhysicalRange() {
            let leftSegment = SplitSegment.left(formulaOffset: 0.0)
            let range = leftSegment.physicalRange
            
            #expect(range.lowerBound == 0.0, "Left segment should start at 0.0")
            #expect(range.upperBound == 0.5, "Left segment should end at 0.5")
        }
        
        @Test("Right segment physical range is 0.5...1.0")
        func rightSegmentPhysicalRange() {
            let rightSegment = SplitSegment.right(formulaOffset: 0.5)
            let range = rightSegment.physicalRange
            
            #expect(range.lowerBound == 0.5, "Right segment should start at 0.5")
            #expect(range.upperBound == 1.0, "Right segment should end at 1.0")
        }
        
        @Test("Physical ranges are independent of formula offset",
              arguments: [0.0, 0.5, 0.25, 1.0])
        func physicalRangeIndependentOfOffset(offset: Double) {
            let leftSegment = SplitSegment.left(formulaOffset: offset)
            let rightSegment = SplitSegment.right(formulaOffset: offset)
            
            #expect(leftSegment.physicalRange == 0.0...0.5,
                   "Left segment range should always be 0.0...0.5")
            #expect(rightSegment.physicalRange == 0.5...1.0,
                   "Right segment range should always be 0.5...1.0")
        }
    }
    
    // MARK: - SplitSegment Index and Offset
    
    @Suite("Segment Index and Formula Offset")
    struct SegmentProperties {
        
        @Test("Left segment has index 0")
        func leftSegmentIndex() {
            let segment = SplitSegment.left(formulaOffset: 0.0)
            #expect(segment.segmentIndex == 0, "Left segment should have index 0")
        }
        
        @Test("Right segment has index 1")
        func rightSegmentIndex() {
            let segment = SplitSegment.right(formulaOffset: 0.5)
            #expect(segment.segmentIndex == 1, "Right segment should have index 1")
        }
        
        @Test("Formula offset is preserved for left segment",
              arguments: [0.0, 0.1, 0.25])
        func leftSegmentFormulaOffset(offset: Double) {
            let segment = SplitSegment.left(formulaOffset: offset)
            #expect(segment.formulaOffset == offset,
                   "Formula offset should be preserved: expected \(offset)")
        }
        
        @Test("Formula offset is preserved for right segment",
              arguments: [0.5, 0.6, 0.75])
        func rightSegmentFormulaOffset(offset: Double) {
            let segment = SplitSegment.right(formulaOffset: offset)
            #expect(segment.formulaOffset == offset,
                   "Formula offset should be preserved: expected \(offset)")
        }
    }
    
    // MARK: - SplitSegment Equality and Hashing
    
    @Suite("Equality and Hashing")
    struct SegmentEquality {
        
        @Test("Left segments with same offset are equal")
        func leftSegmentsEqual() {
            let left1 = SplitSegment.left(formulaOffset: 0.0)
            let left2 = SplitSegment.left(formulaOffset: 0.0)
            
            #expect(left1 == left2, "Left segments with same offset should be equal")
        }
        
        @Test("Right segments with same offset are equal")
        func rightSegmentsEqual() {
            let right1 = SplitSegment.right(formulaOffset: 0.5)
            let right2 = SplitSegment.right(formulaOffset: 0.5)
            
            #expect(right1 == right2, "Right segments with same offset should be equal")
        }
        
        @Test("Left and right segments are not equal")
        func leftAndRightNotEqual() {
            let left = SplitSegment.left(formulaOffset: 0.0)
            let right = SplitSegment.right(formulaOffset: 0.0)
            
            #expect(left != right, "Left and right segments should not be equal")
        }
        
        @Test("Segments with different offsets are not equal")
        func differentOffsetsNotEqual() {
            let left1 = SplitSegment.left(formulaOffset: 0.0)
            let left2 = SplitSegment.left(formulaOffset: 0.1)
            
            #expect(left1 != left2, "Segments with different offsets should not be equal")
        }
        
        @Test("Hashable conformance allows Set usage")
        func hashableConformance() {
            let segments: Set<SplitSegment> = [
                .left(formulaOffset: 0.0),
                .right(formulaOffset: 0.5),
                .left(formulaOffset: 0.0)  // Duplicate
            ]
            
            #expect(segments.count == 2, "Set should deduplicate equal segments")
        }
    }
    
    // MARK: - ScaleDefinition Integration
    
    @Suite("Scale Definition Split Segment Settings")
    struct ScaleDefinitionIntegration {
        
        @Test("ScaleDefinition accepts nil splitSegment (default)")
        func nilSplitSegmentDefault() {
            let definition = ScaleDefinition(
                name: "C",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            
            #expect(definition.splitSegment == nil,
                   "Default splitSegment should be nil for backward compatibility")
        }
        
        @Test("ScaleDefinition accepts left split segment")
        func leftSplitSegment() {
            let segment = SplitSegment.left(formulaOffset: 0.0)
            let definition = ScaleDefinition(
                name: "C_L",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                splitSegment: segment
            )
            
            #expect(definition.splitSegment == segment,
                   "ScaleDefinition should preserve left split segment")
        }
        
        @Test("ScaleDefinition accepts right split segment")
        func rightSplitSegment() {
            let segment = SplitSegment.right(formulaOffset: 0.5)
            let definition = ScaleDefinition(
                name: "C_R",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                splitSegment: segment
            )
            
            #expect(definition.splitSegment == segment,
                   "ScaleDefinition should preserve right split segment")
        }
    }
    
    // MARK: - ScaleBuilder Integration
    
    @Suite("Scale Builder Configuration")
    struct ScaleBuilderIntegration {
        
        @Test("ScaleBuilder withSplitSegment sets left segment")
        func builderWithLeftSegment() {
            let segment = SplitSegment.left(formulaOffset: 0.0)
            let scale = ScaleBuilder()
                .withName("D_L")
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: 10.0)
                .withLength(250.0)
                .withSplitSegment(segment)
                .build()
            
            #expect(scale.splitSegment == segment,
                   "Builder should set left split segment correctly")
        }
        
        @Test("ScaleBuilder withSplitSegment sets right segment")
        func builderWithRightSegment() {
            let segment = SplitSegment.right(formulaOffset: 0.5)
            let scale = ScaleBuilder()
                .withName("D_R")
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: 10.0)
                .withLength(250.0)
                .withSplitSegment(segment)
                .build()
            
            #expect(scale.splitSegment == segment,
                   "Builder should set right split segment correctly")
        }
        
        @Test("ScaleBuilder defaults to nil splitSegment")
        func builderDefaultsToNil() {
            let scale = ScaleBuilder()
                .withName("C")
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: 10.0)
                .withLength(250.0)
                .build()
            
            #expect(scale.splitSegment == nil,
                   "Builder should default splitSegment to nil")
        }
        
        @Test("ScaleBuilder can unset splitSegment with nil")
        func builderCanUnsetSegment() {
            let scale = ScaleBuilder()
                .withName("C")
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: 10.0)
                .withLength(250.0)
                .withSplitSegment(.left(formulaOffset: 0.0))
                .withSplitSegment(nil)  // Unset
                .build()
            
            #expect(scale.splitSegment == nil,
                   "Builder should allow unsetting splitSegment")
        }
        
        @Test("ScaleBuilder fluent chain preserves all properties")
        func builderPreservesAllProperties() {
            let segment = SplitSegment.left(formulaOffset: 0.0)
            let scale = ScaleBuilder()
                .withName("D_L")
                .withFormula("log₁₀(x)")
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: 10.0)
                .withLength(250.0)
                .withTickDirection(.down)
                .withSplitSegment(segment)
                .withBaseline(true)
                .build()
            
            #expect(scale.name == "D_L", "Name should be preserved")
            #expect(scale.formula == "log₁₀(x)", "Formula should be preserved")
            #expect(scale.beginValue == 1.0, "Begin value should be preserved")
            #expect(scale.endValue == 10.0, "End value should be preserved")
            #expect(scale.tickDirection == .down, "Tick direction should be preserved")
            #expect(scale.splitSegment == segment, "Split segment should be preserved")
            #expect(scale.showBaseline == true, "Baseline should be preserved")
        }
    }
    
    // MARK: - Backward Compatibility
    
    @Suite("Backward Compatibility")
    struct BackwardCompatibility {
        
        @Test("Existing code continues to work without splitSegment")
        func existingCodeWorks() {
            // This simulates how existing code creates scales without knowing about splitSegment
            let scale = ScaleDefinition(
                name: "C",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                tickDirection: .up
            )
            
            #expect(scale.splitSegment == nil,
                   "Existing code should get nil splitSegment")
            #expect(scale.name == "C", "Other properties should work normally")
        }
        
        @Test("All standard scales defaultize to full width")
        func standardScalesFullWidth() {
            // Test a few standard scales to ensure they default to nil
            let cScale = StandardScales.cScale(length: 250.0)
            let dScale = StandardScales.dScale(length: 250.0)
            let aScale = StandardScales.aScale(length: 250.0)
            
            #expect(cScale.splitSegment == nil, "C scale should be full width")
            #expect(dScale.splitSegment == nil, "D scale should be full width")
            #expect(aScale.splitSegment == nil, "A scale should be full width")
        }
    }
    
    // MARK: - Documentation Examples
    
    @Suite("Documentation Examples")
    struct DocumentationExamples {
        
        @Test("Split D scale example from documentation")
        func splitDScaleExample() {
            // Example: Split D scale with left (1-√10) and right (√10-10) segments
            let leftSegment = SplitSegment.left(formulaOffset: 0.0)
            let rightSegment = SplitSegment.right(formulaOffset: 0.5)
            
            // Left segment: displays 1-√10 on physical 0.0-0.5
            #expect(leftSegment.physicalRange == 0.0...0.5)
            #expect(leftSegment.formulaOffset == 0.0)
            
            // Right segment: displays √10-10 on physical 0.5-1.0
            #expect(rightSegment.physicalRange == 0.5...1.0)
            #expect(rightSegment.formulaOffset == 0.5)
        }
        
        @Test("Creating split scales with builder")
        func splitScaleWithBuilder() {
            // Create left segment of split scale
            let leftScale = ScaleBuilder()
                .withName("D_L")
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: sqrt(10.0))
                .withLength(250.0)
                .withSplitSegment(.left(formulaOffset: 0.0))
                .build()
            
            // Create right segment of split scale
            let rightScale = ScaleBuilder()
                .withName("D_R")
                .withFunction(LogarithmicFunction())
                .withRange(begin: sqrt(10.0), end: 10.0)
                .withLength(250.0)
                .withSplitSegment(.right(formulaOffset: 0.5))
                .build()
            
            #expect(leftScale.splitSegment?.segmentIndex == 0)
            #expect(rightScale.splitSegment?.segmentIndex == 1)
        }
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var dataStructures: Tag
}
