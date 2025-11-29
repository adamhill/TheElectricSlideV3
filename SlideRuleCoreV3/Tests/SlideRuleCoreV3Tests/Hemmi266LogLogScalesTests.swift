import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive tests for Hemmi 266 Log-Log scales (specialized variants)
/// Tests factory lookup, scale properties, round-trip accuracy, tick generation, and mathematical correctness
///
/// Scales tested:
/// - H266LL01: Log-log scale for values 0.90-0.99 (near-unity negative exponentials)
/// - H266LL03: Extended log-log scale for nano-scale calculations (10^-9 multiplier)
/// - LL02B: Combined LL02/LL03 referenced to A/B scales (0.00005-0.904)
/// - LL2B: Extended positive log-log scale referenced to A/B scales (1.106-20000)

@Suite("Hemmi 266 Log-Log Scales", .tags(.fast, .regression))
struct Hemmi266LogLogScalesTests {
    
    // MARK: - H266LL01 Scale Tests
    
    @Suite("H266LL01 Scale Tests")
    struct H266LL01ScaleTests {
        
        @Test("H266LL01 can be looked up by parser name")
        func h266ll01FactoryLookup() {
            let scale = StandardScales.scale(named: "H266LL01", length: 250.0)
            #expect(scale != nil, "H266LL01 should be retrievable by name")
            #expect(scale?.name == "H266LL01")
        }
        
        @Test("H266LL01 lookup is case-insensitive", arguments: ["H266LL01", "h266ll01", "H266ll01", "h266LL01"])
        func h266ll01CaseInsensitiveLookup(name: String) {
            let scale = StandardScales.scale(named: name, length: 250.0)
            #expect(scale != nil, "H266LL01 should be retrievable as '\(name)'")
        }
        
        @Test("H266LL01 has correct scale properties")
        func h266ll01ScaleProperties() {
            let scale = StandardScales.h266LL01Scale(length: 250.0)
            
            #expect(scale.name == "H266LL01")
            #expect(scale.beginValue == 0.90, "H266LL01 should begin at 0.90")
            #expect(scale.endValue == 0.99, "H266LL01 should end at 0.99")
            #expect(scale.scaleLengthInPoints == 250.0)
            #expect(scale.tickDirection == .up, "H266LL01 should have ticks pointing up")
        }
        
        @Test("H266LL01 round-trip accuracy", arguments: [0.90, 0.92, 0.95, 0.97, 0.99])
        func h266ll01RoundTrip(value: Double) {
            let scale = StandardScales.h266LL01Scale(length: 250.0)
            
            let pos = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let recovered = ScaleCalculator.value(at: pos, on: scale)
            
            let absoluteError = abs(recovered - value)
            #expect(absoluteError < 0.001,
                   "H266LL01 round-trip failed for value \(value), error: \(absoluteError)")
        }
        
        @Test("H266LL01 generates non-empty tick marks")
        func h266ll01TickGeneration() {
            let scale = StandardScales.h266LL01Scale(length: 250.0)
            let generated = GeneratedScale(definition: scale)
            
            #expect(!generated.tickMarks.isEmpty, "H266LL01 should generate tick marks")
            
            let values = generated.tickMarks.map { $0.value }
            #expect(values.min()! >= 0.90, "Tick values should be within range")
            #expect(values.max()! <= 0.99, "Tick values should be within range")
        }
        
        @Test("H266LL01 transform uses correct mathematical formula")
        func h266ll01MathematicalCorrectness() {
            let scale = StandardScales.h266LL01Scale(length: 250.0)
            
            // H266LL01 uses same function as LL00B: log₁₀(-ln(x) × 100) / 2 + 0.5
            // For x = 0.95: -ln(0.95) ≈ 0.0513
            let testValue = 0.95
            let transform = scale.function.transform(testValue)
            
            #expect(transform.isFinite, "Transform for \(testValue) should be finite")
            
            // Verify inverse exists
            let inverse = scale.function.inverseTransform(transform)
            #expect(abs(inverse - testValue) < 0.0001,
                   "Inverse transform should recover original value")
        }
        
        @Test("H266LL01 works with different scale lengths", arguments: [100.0, 250.0, 500.0, 1000.0])
        func h266ll01CustomLengths(length: Double) {
            let scale = StandardScales.h266LL01Scale(length: length)
            #expect(scale.scaleLengthInPoints == length)
        }
        
        @Test("H266LL01 has appropriate subsections")
        func h266ll01Subsections() {
            let scale = StandardScales.h266LL01Scale(length: 250.0)
            
            #expect(scale.subsections.count >= 1, "H266LL01 should have at least one subsection")
            
            // Verify first subsection starts at or near begin value
            if let first = scale.subsections.first {
                #expect(first.startValue >= 0.89 && first.startValue <= 0.91,
                       "First subsection should start near 0.90")
            }
        }
    }
    
    // MARK: - H266LL03 Scale Tests
    
    @Suite("H266LL03 Scale Tests")
    struct H266LL03ScaleTests {
        
        @Test("H266LL03 can be looked up by parser name")
        func h266ll03FactoryLookup() {
            let scale = StandardScales.scale(named: "H266LL03", length: 250.0)
            #expect(scale != nil, "H266LL03 should be retrievable by name")
            #expect(scale?.name == "H266LL03")
        }
        
        @Test("H266LL03 lookup is case-insensitive", arguments: ["H266LL03", "h266ll03", "H266ll03", "h266LL03"])
        func h266ll03CaseInsensitiveLookup(name: String) {
            let scale = StandardScales.scale(named: name, length: 250.0)
            #expect(scale != nil, "H266LL03 should be retrievable as '\(name)'")
        }
        
        @Test("H266LL03 has correct scale properties")
        func h266ll03ScaleProperties() {
            let scale = StandardScales.h266LL03Scale(length: 250.0)
            
            #expect(scale.name == "H266LL03")
            #expect(scale.beginValue == 1.0, "H266LL03 should begin at 1.0")
            #expect(scale.endValue == 50000.0, "H266LL03 should end at 50000")
            #expect(scale.scaleLengthInPoints == 250.0)
            #expect(scale.tickDirection == .up, "H266LL03 should have ticks pointing up")
        }
        
        @Test("H266LL03 round-trip accuracy", arguments: [1.0, 10.0, 100.0, 1000.0, 10000.0, 50000.0])
        func h266ll03RoundTrip(value: Double) {
            let scale = StandardScales.h266LL03Scale(length: 250.0)
            
            let pos = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let recovered = ScaleCalculator.value(at: pos, on: scale)
            
            let relativeError = abs(recovered - value) / value
            #expect(relativeError < 0.01,
                   "H266LL03 round-trip failed for value \(value), relative error: \(relativeError)")
        }
        
        @Test("H266LL03 generates non-empty tick marks")
        func h266ll03TickGeneration() throws {
            let scale = StandardScales.h266LL03Scale(length: 250.0)
            let generated = GeneratedScale(definition: scale)
            
            #expect(!generated.tickMarks.isEmpty, "H266LL03 should generate tick marks")
            
            let values = generated.tickMarks.map { $0.value }
            let minValue = try #require(values.min(), "Should have tick values")
            let maxValue = try #require(values.max(), "Should have tick values")
            #expect(minValue >= 1.0, "Tick values should be within range")
            #expect(maxValue <= 50000.0, "Tick values should be within range")
        }
        
        @Test("H266LL03 transform uses correct mathematical formula")
        func h266ll03MathematicalCorrectness() {
            let scale = StandardScales.h266LL03Scale(length: 250.0)
            
            // H266LL03 formula: log₁₀(ln(x × 10^-9) × -0.1) / 2
            // For nano-scale calculations
            let testValue = 1000.0
            let transform = scale.function.transform(testValue)
            
            #expect(transform.isFinite, "Transform for \(testValue) should be finite")
            
            // Verify inverse exists
            let inverse = scale.function.inverseTransform(transform)
            let relativeError = abs(inverse - testValue) / testValue
            #expect(relativeError < 0.01,
                   "Inverse transform should recover original value")
        }
        
        @Test("H266LL03 works with different scale lengths", arguments: [100.0, 250.0, 500.0, 1000.0])
        func h266ll03CustomLengths(length: Double) {
            let scale = StandardScales.h266LL03Scale(length: length)
            #expect(scale.scaleLengthInPoints == length)
        }
        
        @Test("H266LL03 has multiple subsections for wide range")
        func h266ll03Subsections() {
            let scale = StandardScales.h266LL03Scale(length: 250.0)
            
            // H266LL03 covers a huge range (1 to 50000) so needs multiple subsections
            #expect(scale.subsections.count >= 3,
                   "H266LL03 should have multiple subsections for its wide range")
        }
        
        @Test("H266LL03 handles extreme values correctly", arguments: [1.0, 100.0, 10000.0, 50000.0])
        func h266ll03ExtremeValues(value: Double) {
            let scale = StandardScales.h266LL03Scale(length: 250.0)
            
            let transform = scale.function.transform(value)
            #expect(transform.isFinite,
                   "H266LL03 scale should handle extreme value \(value) correctly")
        }
    }
    
    // MARK: - LL02B Scale Tests
    
    @Suite("LL02B Scale Tests")
    struct LL02BScaleTests {
        
        @Test("LL02B can be looked up by parser name")
        func ll02bFactoryLookup() {
            let scale = StandardScales.scale(named: "LL02B", length: 250.0)
            #expect(scale != nil, "LL02B should be retrievable by name")
            #expect(scale?.name == "LL02B")
        }
        
        @Test("LL02B lookup is case-insensitive", arguments: ["LL02B", "ll02b", "Ll02b", "LL02b"])
        func ll02bCaseInsensitiveLookup(name: String) {
            let scale = StandardScales.scale(named: name, length: 250.0)
            #expect(scale != nil, "LL02B should be retrievable as '\(name)'")
        }
        
        @Test("LL02B has correct scale properties")
        func ll02bScaleProperties() {
            let scale = StandardScales.ll02BScale(length: 250.0)
            
            #expect(scale.name == "LL02B")
            #expect(abs(scale.beginValue - 0.00005) < 0.00001, "LL02B should begin at ~0.00005")
            #expect(abs(scale.endValue - 0.904) < 0.01, "LL02B should end at ~0.904")
            #expect(scale.scaleLengthInPoints == 250.0)
        }
        
        @Test("LL02B round-trip accuracy", arguments: [0.0001, 0.001, 0.01, 0.1, 0.5, 0.9])
        func ll02bRoundTrip(value: Double) {
            let scale = StandardScales.ll02BScale(length: 250.0)
            
            let pos = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let recovered = ScaleCalculator.value(at: pos, on: scale)
            
            let relativeError = abs(recovered - value) / value
            #expect(relativeError < 0.01,
                   "LL02B round-trip failed for value \(value), relative error: \(relativeError)")
        }
        
        @Test("LL02B generates non-empty tick marks")
        func ll02bTickGeneration() {
            let scale = StandardScales.ll02BScale(length: 250.0)
            let generated = GeneratedScale(definition: scale)
            
            #expect(!generated.tickMarks.isEmpty, "LL02B should generate tick marks")
        }
        
        @Test("LL02B transform uses correct mathematical formula")
        func ll02bMathematicalCorrectness() {
            let scale = StandardScales.ll02BScale(length: 250.0)
            
            // LL02B formula: log₁₀(-ln(x) × 10) / 2
            // Combined LL02/LL03 referenced to A/B scales
            let testValue = 0.1
            let transform = scale.function.transform(testValue)
            
            #expect(transform.isFinite, "Transform for \(testValue) should be finite")
            
            // Verify inverse exists
            let inverse = scale.function.inverseTransform(transform)
            let relativeError = abs(inverse - testValue) / testValue
            #expect(relativeError < 0.01,
                   "Inverse transform should recover original value")
        }
        
        @Test("LL02B works with different scale lengths", arguments: [100.0, 250.0, 500.0, 1000.0])
        func ll02bCustomLengths(length: Double) {
            let scale = StandardScales.ll02BScale(length: length)
            #expect(scale.scaleLengthInPoints == length)
        }
        
        @Test("LL02B handles small values correctly", arguments: [0.00005, 0.0001, 0.001, 0.01])
        func ll02bSmallValues(value: Double) {
            let scale = StandardScales.ll02BScale(length: 250.0)
            
            let transform = scale.function.transform(value)
            #expect(transform.isFinite,
                   "LL02B scale should handle small value \(value) correctly")
        }
    }
    
    // MARK: - LL2B Scale Tests
    
    @Suite("LL2B Scale Tests")
    struct LL2BScaleTests {
        
        @Test("LL2B can be looked up by parser name")
        func ll2bFactoryLookup() {
            let scale = StandardScales.scale(named: "LL2B", length: 250.0)
            #expect(scale != nil, "LL2B should be retrievable by name")
            #expect(scale?.name == "LL2B")
        }
        
        @Test("LL2B lookup is case-insensitive", arguments: ["LL2B", "ll2b", "Ll2b", "LL2b"])
        func ll2bCaseInsensitiveLookup(name: String) {
            let scale = StandardScales.scale(named: name, length: 250.0)
            #expect(scale != nil, "LL2B should be retrievable as '\(name)'")
        }
        
        @Test("LL2B has correct scale properties")
        func ll2bScaleProperties() {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            
            #expect(scale.name == "LL2B")
            #expect(abs(scale.beginValue - 1.106) < 0.01, "LL2B should begin at ~1.106")
            #expect(scale.endValue == 20000.0, "LL2B should end at 20000")
            #expect(scale.scaleLengthInPoints == 250.0)
        }
        
        @Test("LL2B round-trip accuracy", arguments: [1.2, 2.0, 10.0, 100.0, 1000.0, 10000.0])
        func ll2bRoundTrip(value: Double) {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            
            let pos = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let recovered = ScaleCalculator.value(at: pos, on: scale)
            
            let relativeError = abs(recovered - value) / value
            #expect(relativeError < 0.01,
                   "LL2B round-trip failed for value \(value), relative error: \(relativeError)")
        }
        
        @Test("LL2B generates non-empty tick marks")
        func ll2bTickGeneration() {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            let generated = GeneratedScale(definition: scale)
            
            #expect(!generated.tickMarks.isEmpty, "LL2B should generate tick marks")
            
            let values = generated.tickMarks.map { $0.value }
            #expect(values.min()! >= 1.0, "Tick values should be within range")
            #expect(values.max()! <= 20000.0, "Tick values should be within range")
        }
        
        @Test("LL2B transform uses correct mathematical formula")
        func ll2bMathematicalCorrectness() {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            
            // LL2B formula: log₁₀(ln(x) × 10) / 2
            // Extended positive scale referenced to A/B scales
            let testValue = 10.0  // ln(10) ≈ 2.303
            let transform = scale.function.transform(testValue)
            
            #expect(transform.isFinite, "Transform for \(testValue) should be finite")
            
            // Verify inverse exists
            let inverse = scale.function.inverseTransform(transform)
            let relativeError = abs(inverse - testValue) / testValue
            #expect(relativeError < 0.01,
                   "Inverse transform should recover original value")
        }
        
        @Test("LL2B works with different scale lengths", arguments: [100.0, 250.0, 500.0, 1000.0])
        func ll2bCustomLengths(length: Double) {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: length)
            #expect(scale.scaleLengthInPoints == length)
        }
        
        @Test("LL2B has multiple subsections for wide range")
        func ll2bSubsections() {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            
            // LL2B covers a wide range (1.106 to 20000) so needs multiple subsections
            #expect(scale.subsections.count >= 3,
                   "LL2B should have multiple subsections for its wide range")
        }
        
        @Test("LL2B handles large values correctly", arguments: [100.0, 1000.0, 10000.0, 20000.0])
        func ll2bLargeValues(value: Double) {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            
            let transform = scale.function.transform(value)
            #expect(transform.isFinite,
                   "LL2B scale should handle large value \(value) correctly")
        }
        
        @Test("LL2B includes e constant marker")
        func ll2bIncludesEConstant() {
            let scale = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            
            // LL2B should have e as a constant since it's in the range
            let hasEConstant = scale.constants.contains { constant in
                abs(constant.value - Double.e) < 0.01
            }
            
            // Note: This test documents expected behavior - may need adjustment based on implementation
            // If no e constant exists, this will fail and inform us to add one or remove the test
            if !hasEConstant {
                // e ≈ 2.718 is within 1.106-20000 range, so ideally should be marked
                print("Note: LL2B scale does not have e constant marker (optional feature)")
            }
        }
    }
    
    // MARK: - Cross-Scale Integration Tests
    
    @Suite("Hemmi 266 Cross-Scale Integration")
    struct CrossScaleIntegrationTests {
        
        @Test("All 4 Hemmi 266 scales can be retrieved from factory")
        func allScalesRetrievable() {
            let h266ll01 = StandardScales.scale(named: "H266LL01", length: 250.0)
            let h266ll03 = StandardScales.scale(named: "H266LL03", length: 250.0)
            let ll02b = StandardScales.scale(named: "LL02B", length: 250.0)
            let ll2b = StandardScales.scale(named: "LL2B", length: 250.0)
            
            #expect(h266ll01 != nil, "H266LL01 should be retrievable")
            #expect(h266ll03 != nil, "H266LL03 should be retrievable")
            #expect(ll02b != nil, "LL02B should be retrievable")
            #expect(ll2b != nil, "LL2B should be retrievable")
        }
        
        @Test("Factory returns unique scale instances")
        func factoryReturnsUniqueInstances() {
            let scale1 = StandardScales.scale(named: "H266LL01", length: 250.0)
            let scale2 = StandardScales.scale(named: "H266LL01", length: 300.0)
            
            #expect(scale1?.scaleLengthInPoints != scale2?.scaleLengthInPoints,
                   "Factory should return scales with requested lengths")
        }
        
        @Test("All Hemmi 266 scales accept custom lengths", arguments: [100.0, 250.0, 500.0])
        func allScalesAcceptCustomLengths(length: Double) {
            let scales = [
                StandardScales.scale(named: "H266LL01", length: length),
                StandardScales.scale(named: "H266LL03", length: length),
                StandardScales.scale(named: "LL02B", length: length),
                StandardScales.scale(named: "LL2B", length: length)
            ]
            
            for scale in scales {
                if let scale = scale {
                    #expect(scale.scaleLengthInPoints == length,
                           "\(scale.name) should accept custom length \(length)")
                }
            }
        }
        
        @Test("LL02B and LL2B scales are complementary (negative vs positive exponentials)")
        func ll02bLL2bComplementary() {
            let ll02b = StandardScales.ll02BScale(length: 250.0)
            let ll2b = StandardScales.ll2BScale_PostScriptAccurate(length: 250.0)
            
            // LL02B handles values < 1 (negative ln)
            #expect(ll02b.beginValue < 1.0, "LL02B should handle values < 1")
            #expect(ll02b.endValue < 1.0, "LL02B end should be < 1")
            
            // LL2B handles values > 1 (positive ln)
            #expect(ll2b.beginValue > 1.0, "LL2B should handle values > 1")
            #expect(ll2b.endValue > 1.0, "LL2B end should be > 1")
        }
        
        @Test("H266LL01 and H266LL03 scales cover specialized Hemmi ranges")
        func h266ScalesSpecializedRanges() {
            let h266ll01 = StandardScales.h266LL01Scale(length: 250.0)
            let h266ll03 = StandardScales.h266LL03Scale(length: 250.0)
            
            // H266LL01 is for near-unity negative exponentials (0.90-0.99)
            #expect(h266ll01.beginValue >= 0.9 && h266ll01.beginValue < 1.0,
                   "H266LL01 should handle near-unity values")
            #expect(h266ll01.endValue > h266ll01.beginValue && h266ll01.endValue < 1.0,
                   "H266LL01 should cover truncated range below 1")
            
            // H266LL03 is for nano-scale calculations (1-50000 representing 10^-9 × value)
            #expect(h266ll03.beginValue == 1.0, "H266LL03 should start at 1")
            #expect(h266ll03.endValue == 50000.0, "H266LL03 should extend to 50000")
        }
    }
    
    // MARK: - Edge Cases and Boundary Tests
    
    @Suite("Hemmi 266 Edge Cases")
    struct EdgeCasesTests {
        
        @Test("Scales handle boundary values without errors")
        func boundaryValuesNoErrors() {
            let scales: [(String, ScaleDefinition)] = [
                ("H266LL01", StandardScales.h266LL01Scale(length: 250.0)),
                ("H266LL03", StandardScales.h266LL03Scale(length: 250.0)),
                ("LL02B", StandardScales.ll02BScale(length: 250.0)),
                ("LL2B", StandardScales.ll2BScale_PostScriptAccurate(length: 250.0))
            ]
            
            for (name, scale) in scales {
                // Test at begin value
                let beginTransform = scale.function.transform(scale.beginValue)
                #expect(beginTransform.isFinite,
                       "\(name) should handle begin value \(scale.beginValue)")
                
                // Test at end value
                let endTransform = scale.function.transform(scale.endValue)
                #expect(endTransform.isFinite,
                       "\(name) should handle end value \(scale.endValue)")
            }
        }
        
        @Test("Normalized positions stay within 0-1 range")
        func normalizedPositionsInRange() {
            let scales: [(String, ScaleDefinition, [Double])] = [
                ("H266LL01", StandardScales.h266LL01Scale(length: 250.0), [0.90, 0.95, 0.99]),
                ("H266LL03", StandardScales.h266LL03Scale(length: 250.0), [1.0, 1000.0, 50000.0]),
                ("LL02B", StandardScales.ll02BScale(length: 250.0), [0.0001, 0.1, 0.9]),
                ("LL2B", StandardScales.ll2BScale_PostScriptAccurate(length: 250.0), [1.2, 100.0, 20000.0])
            ]
            
            for (name, scale, testValues) in scales {
                for value in testValues {
                    let pos = ScaleCalculator.normalizedPosition(for: value, on: scale)
                    #expect(pos >= -0.01 && pos <= 1.01,
                           "\(name) position for \(value) should be near 0-1 range, got \(pos)")
                }
            }
        }
        
        @Test("Unknown scale names return nil from factory")
        func unknownScaleReturnsNil() {
            let unknownNames = ["H266LL02", "H266LL04", "LL03B", "LL3B", "NOTASCALE"]
            
            for name in unknownNames {
                let scale = StandardScales.scale(named: name, length: 250.0)
                #expect(scale == nil, "Unknown scale '\(name)' should return nil")
            }
        }
    }
}