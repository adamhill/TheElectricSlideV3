//
//  VisibleBoundaryValueTests.swift
//  SlideRuleCoreV3Tests
//
//  Tests for visibleEndValue and visibleBeginValue ghost gap functionality
//

import Foundation
import Testing
@testable import SlideRuleCoreV3

// MARK: - visibleEndValue Tests

@Suite("Visible End Value - Ghost End Gap")
struct VisibleEndValueTests {
    
    // MARK: - Ascending Scale Tests (begin < end)
    
    @Test("Ascending scale: ticks stop at visibleEndValue")
    func ascendingScaleTicksStopAtVisibleEndValue() throws {
        // Create a simple ascending scale (1 to 10) with visibleEndValue at 8
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05])
            ])
            .withVisibleEndValue(8.0)
            .build()
        
        let generated = GeneratedScale(definition: scale)
        
        // No tick should have a value > 8.0
        let maxTickValue = generated.tickMarks.map(\.value).max() ?? 0
        #expect(maxTickValue <= 8.0, "Max tick value \(maxTickValue) should be <= 8.0 (visibleEndValue)")
        
        // Scale positioning should still use endValue (10.0)
        #expect(scale.endValue == 10.0, "endValue should remain 10.0 for positioning")
        #expect(scale.visibleEndValue == 8.0, "visibleEndValue should be 8.0")
    }
    
    @Test("Ascending scale: scale positioning uses endValue not visibleEndValue")
    func ascendingScalePositioningUsesEndValue() throws {
        // Create scale with visibleEndValue
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05])
            ])
            .withVisibleEndValue(8.0)
            .build()
        
        // Verify positioning calculations use full range
        // Value 10 should map to position 1.0 (end of scale)
        let position = ScaleCalculator.normalizedPosition(for: 10.0, on: scale)
        #expect(abs(position - 1.0) < 0.001, "Position for value 10 should be 1.0 (full scale)")
    }
    
    // MARK: - Descending Scale Tests (begin > end)
    
    @Test("Descending scale: ticks stop at visibleEndValue")
    func descendingScaleTicksStopAtVisibleEndValue() throws {
        // Create a simple descending scale with custom function to test visibleEndValue
        // Use LinearFunction for simplicity (transform = identity)
        let scale = ScaleBuilder()
            .withName("DescTest")
            .withFunction(LinearFunction())
            .withRange(begin: 10.0, end: 0.0)  // Descending from 10 to 0
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1])
            ])
            .withVisibleEndValue(2.0)  // Stop ticks at 2.0
            .build()
        
        let generated = GeneratedScale(definition: scale)
        
        // For descending scale, no tick should have value < visibleEndValue (2.0)
        let minTickValue = generated.tickMarks.map(\.value).min() ?? 10.0
        #expect(minTickValue >= 1.9, "Min tick value \(minTickValue) should be >= ~2.0 (visibleEndValue)")
        
        // Scale positioning should still use endValue (0.0)
        #expect(scale.endValue == 0.0, "endValue should remain 0.0 for positioning")
    }
    
    @Test("Descending scale: scale positioning uses endValue not visibleEndValue")
    func descendingScalePositioningUsesEndValue() throws {
        // Create a simple descending scale with visibleEndValue
        let scale = ScaleBuilder()
            .withName("DescTest")
            .withFunction(LinearFunction())
            .withRange(begin: 10.0, end: 0.0)  // Descending
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1])
            ])
            .withVisibleEndValue(2.0)  // Ticks stop at 2.0, but positioning extends to 0.0
            .build()
        
        // Verify positioning calculations use full range
        // Value 0.0 (endValue) should map to position 1.0
        let position = ScaleCalculator.normalizedPosition(for: 0.0, on: scale)
        #expect(abs(position - 1.0) < 0.001, "Position for value 0.0 (endValue) should be 1.0")
    }
    
    // MARK: - Builder and Definition Tests
    
    @Test("visibleEndValue is nil by default")
    func visibleEndValueNilByDefault() {
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .build()
        
        #expect(scale.visibleEndValue == nil, "visibleEndValue should be nil by default")
    }
    
    @Test("ScaleBuilder init(from:) preserves visibleEndValue")
    func builderInitFromPreservesVisibleEndValue() {
        let original = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withVisibleEndValue(8.0)
            .build()
        
        let cloned = ScaleBuilder(from: original).build()
        
        #expect(cloned.visibleEndValue == 8.0, "Cloned scale should preserve visibleEndValue")
    }
    
    @Test("withVisibleEndValue can clear value with nil")
    func withVisibleEndValueCanClear() {
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withVisibleEndValue(8.0)
            .withVisibleEndValue(nil)  // Clear it
            .build()
        
        #expect(scale.visibleEndValue == nil, "visibleEndValue should be clearable with nil")
    }
    
    // MARK: - Ghost End Gap Calculation Tests
    
    @Test("Ghost end gap creates expected gap percentage")
    func ghostEndGapPercentage() throws {
        // Create scale where visibleEndValue creates a ~10% ghost gap
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())  // log10
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05])
            ])
            .withVisibleEndValue(8.0)  
            .build()
        
        let generated = GeneratedScale(definition: scale)
        
        // Find max tick position
        let maxTickPosition = generated.tickMarks.map(\.normalizedPosition).max() ?? 0
        
        // Position for value 8 on C scale (log10)
        // log10(8) / log10(10) = 0.903... 
        let expectedMaxPosition = log10(8.0) / log10(10.0)
        
        #expect(abs(maxTickPosition - expectedMaxPosition) < 0.01, 
                "Max tick position \(maxTickPosition) should be near \(expectedMaxPosition)")
    }
}

// MARK: - visibleBeginValue Tests

@Suite("Visible Begin Value - Ghost Start Gap")
struct VisibleBeginValueTests {
    
    // MARK: - Ascending Scale Tests (begin < end)
    
    @Test("Ascending scale: ticks start at visibleBeginValue")
    func ascendingScaleTicksStartAtVisibleBeginValue() throws {
        // Create a simple ascending scale (1 to 10) with visibleBeginValue at 2
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05])
            ])
            .withVisibleBeginValue(2.0)
            .build()
        
        let generated = GeneratedScale(definition: scale)
        
        // No tick should have a value < 2.0
        let minTickValue = generated.tickMarks.map(\.value).min() ?? 10.0
        #expect(minTickValue >= 2.0, "Min tick value \(minTickValue) should be >= 2.0 (visibleBeginValue)")
        
        // Scale positioning should still use beginValue (1.0)
        #expect(scale.beginValue == 1.0, "beginValue should remain 1.0 for positioning")
        #expect(scale.visibleBeginValue == 2.0, "visibleBeginValue should be 2.0")
    }
    
    @Test("Ascending scale: scale positioning uses beginValue not visibleBeginValue")
    func ascendingScalePositioningUsesBeginValue() throws {
        // Create scale with visibleBeginValue
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05])
            ])
            .withVisibleBeginValue(2.0)
            .build()
        
        // Verify positioning calculations use full range
        // Value 1 should map to position 0.0 (beginning of scale)
        let position = ScaleCalculator.normalizedPosition(for: 1.0, on: scale)
        #expect(abs(position - 0.0) < 0.001, "Position for value 1 should be 0.0 (start of scale)")
    }
    
    // MARK: - Descending Scale Tests (begin > end)
    
    @Test("Descending scale: ticks start at visibleBeginValue")
    func descendingScaleTicksStartAtVisibleBeginValue() throws {
        // Create a simple descending scale from 10 to 0
        let scale = ScaleBuilder()
            .withName("DescTest")
            .withFunction(LinearFunction())
            .withRange(begin: 10.0, end: 0.0)  // Descending from 10 to 0
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1])
            ])
            .withVisibleBeginValue(8.0)  // Start ticks at 8.0 (ghost area 8-10)
            .build()
        
        let generated = GeneratedScale(definition: scale)
        
        // For descending scale, no tick should have value > visibleBeginValue (8.0)
        let maxTickValue = generated.tickMarks.map(\.value).max() ?? 0.0
        #expect(maxTickValue <= 8.0, "Max tick value \(maxTickValue) should be <= 8.0 (visibleBeginValue)")
        
        // Scale positioning should still use beginValue (10.0)
        #expect(scale.beginValue == 10.0, "beginValue should remain 10.0 for positioning")
    }
    
    @Test("Descending scale: scale positioning uses beginValue not visibleBeginValue")
    func descendingScalePositioningUsesBeginValue() throws {
        // Create a simple descending scale with visibleBeginValue
        let scale = ScaleBuilder()
            .withName("DescTest")
            .withFunction(LinearFunction())
            .withRange(begin: 10.0, end: 0.0)  // Descending
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 10.0, tickIntervals: [1.0, 0.5, 0.1])
            ])
            .withVisibleBeginValue(8.0)  // Ticks start at 8.0, but positioning extends to 10.0
            .build()
        
        // Verify positioning calculations use full range
        // Value 10.0 (beginValue) should map to position 0.0
        let position = ScaleCalculator.normalizedPosition(for: 10.0, on: scale)
        #expect(abs(position - 0.0) < 0.001, "Position for value 10.0 (beginValue) should be 0.0")
    }
    
    // MARK: - Builder and Definition Tests
    
    @Test("visibleBeginValue is nil by default")
    func visibleBeginValueNilByDefault() {
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .build()
        
        #expect(scale.visibleBeginValue == nil, "visibleBeginValue should be nil by default")
    }
    
    @Test("ScaleBuilder init(from:) preserves visibleBeginValue")
    func builderInitFromPreservesVisibleBeginValue() {
        let original = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withVisibleBeginValue(2.0)
            .build()
        
        let cloned = ScaleBuilder(from: original).build()
        
        #expect(cloned.visibleBeginValue == 2.0, "Cloned scale should preserve visibleBeginValue")
    }
    
    @Test("withVisibleBeginValue can clear value with nil")
    func withVisibleBeginValueCanClear() {
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withVisibleBeginValue(2.0)
            .withVisibleBeginValue(nil)  // Clear it
            .build()
        
        #expect(scale.visibleBeginValue == nil, "visibleBeginValue should be clearable with nil")
    }
    
    // MARK: - Ghost Start Gap Calculation Tests
    
    @Test("Ghost start gap creates expected gap percentage")
    func ghostStartGapPercentage() throws {
        // Create scale where visibleBeginValue creates a ghost gap at the start
        let scale = ScaleBuilder()
            .withName("TestScale")
            .withFunction(LogarithmicFunction())  // log10
            .withRange(begin: 1.0, end: 10.0)
            .withLength(250.0)
            .withSubsections([
                ScaleSubsection(startValue: 1.0, tickIntervals: [1.0, 0.5, 0.1, 0.05])
            ])
            .withVisibleBeginValue(2.0)  
            .build()
        
        let generated = GeneratedScale(definition: scale)
        
        // Find min tick position
        let minTickPosition = generated.tickMarks.map(\.normalizedPosition).min() ?? 1.0
        
        // Position for value 2 on C scale (log10)
        // log10(2) / log10(10) = 0.301... 
        let expectedMinPosition = log10(2.0) / log10(10.0)
        
        #expect(abs(minTickPosition - expectedMinPosition) < 0.01, 
                "Min tick position \(minTickPosition) should be near \(expectedMinPosition)")
    }
}
