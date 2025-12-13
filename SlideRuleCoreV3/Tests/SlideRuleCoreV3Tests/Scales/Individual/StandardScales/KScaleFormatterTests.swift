//
//  KScaleFormatterTests.swift
//  SlideRuleCoreV3
//
//  Tests for K scale label formatter (compact decade display)
//  Verifies power-of-10 boundaries display correctly using Range-based interval logic
//

import Testing
@testable import SlideRuleCoreV3

@Suite("K Scale Label Formatter")
struct KScaleFormatterTests {
    
    @Suite("Power-of-10 Boundaries")
    struct PowerOfTenTests {
        
        @Test("Critical boundaries show actual values", arguments: [
            (10.0, "10"),
            (100.0, "100"),
            (1000.0, "1000")
        ])
        func powerOfTenBoundaries(value: Double, expected: String) {
            let result = StandardLabelFormatter.kScale(value)
            #expect(result == expected)
        }
    }
    
    @Suite("Compact Display (10-100 range)")
    struct TensRangeTests {
        
        @Test("Values in 10-100 range divide by 10", arguments: [
            (10.0, "10"),   // Boundary - shows full value
            (20.0, "2"),
            (30.0, "3"),
            (50.0, "5"),
            (70.0, "7"),
            (90.0, "9"),
            (100.0, "100")  // Boundary - shows full value
        ])
        func tensRange(value: Double, expected: String) {
            let result = StandardLabelFormatter.kScale(value)
            #expect(result == expected)
        }
    }
    
    @Suite("Compact Display (100-1000 range)")
    struct HundredsRangeTests {
        
        @Test("Values in 100-1000 range divide by 100", arguments: [
            (100.0, "100"), // Boundary - shows full value
            (200.0, "2"),
            (300.0, "3"),
            (500.0, "5"),
            (700.0, "7"),
            (900.0, "9"),
            (1000.0, "1000") // Boundary - shows full value
        ])
        func hundredsRange(value: Double, expected: String) {
            let result = StandardLabelFormatter.kScale(value)
            #expect(result == expected)
        }
    }
    
    @Suite("Full K Scale Integration")
    struct FullScaleIntegrationTests {
        
        @Test("K scale decade pattern: 1-10 repeats three times")
        func decadePattern() {
            // First decade (1-10): show as 1, 2, 3, ..., 10
            #expect(StandardLabelFormatter.integer(1.0) == "1")
            #expect(StandardLabelFormatter.kScale(10.0) == "10")
            
            // Second decade (10-100): show as 10, 2, 3, ..., 9, 100
            #expect(StandardLabelFormatter.kScale(10.0) == "10")
            #expect(StandardLabelFormatter.kScale(20.0) == "2")
            #expect(StandardLabelFormatter.kScale(100.0) == "100")
            
            // Third decade (100-1000): show as 100, 2, 3, ..., 9, 1000
            #expect(StandardLabelFormatter.kScale(100.0) == "100")
            #expect(StandardLabelFormatter.kScale(200.0) == "2")
            #expect(StandardLabelFormatter.kScale(1000.0) == "1000")
        }
    }
    
    @Suite("Range-Based Interval Logic Validation")
    struct IntervalLogicTests {
        
        @Test("ClosedRange.contains() properly detects boundaries")
        func closedRangeBoundaryDetection() {
            let tenBoundary: ClosedRange<Double> = 9.5...10.5
            let hundredBoundary: ClosedRange<Double> = 99.5...100.5
            let thousandBoundary: ClosedRange<Double> = 995.0...1005.0
            
            // Ten boundary
            #expect(tenBoundary.contains(10.0))
            #expect(tenBoundary.contains(9.9))
            #expect(tenBoundary.contains(10.1))
            
            // Hundred boundary
            #expect(hundredBoundary.contains(100.0))
            #expect(hundredBoundary.contains(99.9))
            #expect(hundredBoundary.contains(100.1))
            
            // Thousand boundary (wider tolerance)
            #expect(thousandBoundary.contains(1000.0))
            #expect(thousandBoundary.contains(997.0))
            #expect(thousandBoundary.contains(1003.0))
        }
    }
}
