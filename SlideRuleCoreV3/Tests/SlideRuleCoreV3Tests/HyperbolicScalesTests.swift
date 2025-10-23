import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests for Hyperbolic Scale Definitions (factory methods)
/// Verifies scale configuration, ranges, functions, and properties
@Suite("Hyperbolic Scale Definitions", .tags(.fast, .regression))
struct HyperbolicScalesTests {
    
    // MARK: - Ch Scale Tests
    
    @Suite("Ch Scale - Hyperbolic Cosine")
    struct ChScaleTests {
        
        @Test("Ch scale has correct basic properties")
        func chScaleBasicProperties() {
            let ch = StandardScales.chScale(length: 250.0)
            
            #expect(ch.name == "Ch")
            #expect(ch.beginValue == 0.0)
            #expect(ch.endValue == 3.0)
            #expect(ch.scaleLengthInPoints == 250.0)
            #expect(ch.tickDirection == .up)
        }
        
        @Test("Ch scale uses HyperbolicCosineFunction")
        func chScaleFunctionType() {
            let ch = StandardScales.chScale(length: 250.0)
            #expect(ch.function is HyperbolicCosineFunction)
        }
        
        @Test("Ch scale has appropriate subsections")
        func chScaleSubsections() {
            let ch = StandardScales.chScale(length: 250.0)
            #expect(ch.subsections.count >= 5)
            #expect(ch.subsections[0].startValue == 0.0)
        }
        
        @Test("Ch scale position calculations work correctly",
              arguments: [0.0, 0.5, 1.0, 2.0, 3.0])
        func chScalePositionCalculations(value: Double) {
            let ch = StandardScales.chScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: ch)
            #expect(pos >= 0.0 && pos <= 1.0, "Position should be normalized")
            
            let recovered = ScaleCalculator.value(at: pos, on: ch)
            let relativeError = abs(recovered - value) / max(value, 0.001)
            #expect(relativeError < 0.01, "Round-trip should maintain accuracy")
        }
        
        @Test("Ch scale works with different lengths",
              arguments: [100.0, 250.0, 500.0])
        func chScaleDifferentLengths(length: Double) {
            let ch = StandardScales.chScale(length: length)
            #expect(ch.scaleLengthInPoints == length)
        }
    }
    
    // MARK: - Th Scale Tests
    
    @Suite("Th Scale - Hyperbolic Tangent")
    struct ThScaleTests {
        
        @Test("Th scale has correct basic properties")
        func thScaleBasicProperties() {
            let th = StandardScales.thScale(length: 250.0)
            
            #expect(th.name == "Th")
            #expect(th.beginValue == 0.1)
            #expect(th.endValue == 3.0)
            #expect(th.scaleLengthInPoints == 250.0)
            #expect(th.tickDirection == .up)
        }
        
        @Test("Th scale uses HyperbolicTangentFunction with multiplier 10")
        func thScaleFunctionType() {
            let th = StandardScales.thScale(length: 250.0)
            #expect(th.function is HyperbolicTangentFunction)
            
            // Verify multiplier by checking transform behavior
            let testValue = 1.0
            let transform = th.function.transform(testValue)
            let expected = log10(10.0 * tanh(testValue))
            #expect(abs(transform - expected) < 1e-9)
        }
        
        @Test("Th scale has multiple subsections for range coverage")
        func thScaleSubsections() {
            let th = StandardScales.thScale(length: 250.0)
            #expect(th.subsections.count >= 6)
            #expect(th.subsections[0].startValue == 0.1)
        }
        
        @Test("Th scale position calculations work correctly",
              arguments: [0.1, 0.5, 1.0, 2.0, 3.0])
        func thScalePositionCalculations(value: Double) {
            let th = StandardScales.thScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: th)
            #expect(pos >= 0.0 && pos <= 1.0)
            
            let recovered = ScaleCalculator.value(at: pos, on: th)
            let relativeError = abs(recovered - value) / value
            #expect(relativeError < 0.01)
        }
    }
    
    // MARK: - Sh Scale Tests
    
    @Suite("Sh Scale - Hyperbolic Sine")
    struct ShScaleTests {
        
        @Test("Sh scale has correct basic properties")
        func shScaleBasicProperties() {
            let sh = StandardScales.shScale(length: 250.0)
            
            #expect(sh.name == "Sh")
            #expect(sh.beginValue == 0.1)
            #expect(sh.endValue == 3.0)
            #expect(sh.scaleLengthInPoints == 250.0)
            #expect(sh.tickDirection == .up)
        }
        
        @Test("Sh scale uses HyperbolicSineFunction with multiplier 10")
        func shScaleFunctionType() {
            let sh = StandardScales.shScale(length: 250.0)
            #expect(sh.function is HyperbolicSineFunction)
            
            // Verify multiplier
            let testValue = 1.0
            let transform = sh.function.transform(testValue)
            let expected = log10(10.0 * sinh(testValue))
            #expect(abs(transform - expected) < 1e-9)
        }
        
        @Test("Sh scale position calculations work correctly",
              arguments: [0.1, 0.5, 1.0, 2.0, 3.0])
        func shScalePositionCalculations(value: Double) {
            let sh = StandardScales.shScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: sh)
            #expect(pos >= 0.0 && pos <= 1.0)
            
            let recovered = ScaleCalculator.value(at: pos, on: sh)
            let relativeError = abs(recovered - value) / value
            #expect(relativeError < 0.01)
        }
    }
    
    // MARK: - Split Sh Scales (Sh1/Sh2)
    
    @Suite("Sh1/Sh2 Scales - Split Hyperbolic Sine")
    struct SplitShScalesTests {
        
        @Test("Sh1 scale has correct range (first part)")
        func sh1ScaleRange() {
            let sh1 = StandardScales.sh1Scale(length: 250.0)
            
            #expect(sh1.name == "Sh1")
            #expect(sh1.beginValue == 0.1)
            #expect(sh1.endValue == 0.90)
            #expect(sh1.tickDirection == .up)
        }
        
        @Test("Sh2 scale has correct range (second part with offset)")
        func sh2ScaleRange() {
            let sh2 = StandardScales.sh2Scale(length: 250.0)
            
            #expect(sh2.name == "Sh2")
            #expect(sh2.beginValue == 0.88)
            #expect(sh2.endValue == 3.0)
            #expect(sh2.tickDirection == .up)
        }
        
        @Test("Sh1 and Sh2 ranges overlap at 0.88-0.90")
        func splitScalesOverlap() {
            let sh1 = StandardScales.sh1Scale(length: 250.0)
            let sh2 = StandardScales.sh2Scale(length: 250.0)
            
            // Verify overlap region
            #expect(sh2.beginValue < sh1.endValue)
            #expect(sh2.beginValue >= 0.88 && sh2.beginValue <= 0.90)
        }
        
        @Test("Sh2 scale uses offset in function")
        func sh2ScaleHasOffset() {
            let sh2 = StandardScales.sh2Scale(length: 250.0)
            
            // Verify that Sh2 has offset by checking transform behavior
            // For Sh2 with offset 1.0: transform(x) = log10(10*sinh(x-1))
            let testValue = 2.0
            let transform = sh2.function.transform(testValue)
            let expected = log10(10.0 * sinh(testValue - 1.0))
            #expect(abs(transform - expected) < 1e-9)
        }
    }
    
    // MARK: - H Scales (Pythagorean)
    
    @Suite("H1/H2 Scales - Pythagorean H Function")
    struct HScalesTests {
        
        @Test("H1 scale has correct range and properties")
        func h1ScaleProperties() {
            let h1 = StandardScales.h1Scale(length: 250.0)
            
            #expect(h1.name == "H1")
            #expect(h1.beginValue == 1.005)
            #expect(h1.endValue == 1.415)
            #expect(h1.scaleLengthInPoints == 250.0)
            #expect(h1.tickDirection == .up)
        }
        
        @Test("H1 scale uses PythagoreanHFunction with multiplier 10")
        func h1ScaleFunctionType() {
            let h1 = StandardScales.h1Scale(length: 250.0)
            #expect(h1.function is PythagoreanHFunction)
            
            // Verify multiplier
            let testValue = 1.1
            let transform = h1.function.transform(testValue)
            let expected = log10(10.0 * sqrt(testValue * testValue - 1.0))
            #expect(abs(transform - expected) < 1e-9)
        }
        
        @Test("H1 scale has fine-grained subsections for precision")
        func h1ScalePrecisionSubsections() {
            let h1 = StandardScales.h1Scale(length: 250.0)
            #expect(h1.subsections.count >= 5)
            
            // Check for ultra-fine intervals in first subsection
            if let firstSubsection = h1.subsections.first {
                let hasFineIntervals = firstSubsection.tickIntervals.contains { $0 <= 0.001 }
                #expect(hasFineIntervals, "H1 should have ultra-fine intervals")
            }
        }
        
        @Test("H2 scale has correct range and properties")
        func h2ScaleProperties() {
            let h2 = StandardScales.h2Scale(length: 250.0)
            
            #expect(h2.name == "H2")
            #expect(h2.beginValue == 1.42)
            #expect(h2.endValue == 10.0)
            #expect(h2.scaleLengthInPoints == 250.0)
            #expect(h2.tickDirection == .up)
        }
        
        @Test("H2 scale uses PythagoreanHFunction with multiplier 1")
        func h2ScaleFunctionType() {
            let h2 = StandardScales.h2Scale(length: 250.0)
            #expect(h2.function is PythagoreanHFunction)
            
            // Verify multiplier = 1.0
            let testValue = 2.0
            let transform = h2.function.transform(testValue)
            let expected = log10(sqrt(testValue * testValue - 1.0))
            #expect(abs(transform - expected) < 1e-9)
        }
        
        @Test("H1 and H2 ranges are adjacent")
        func hScalesAdjacent() {
            let h1 = StandardScales.h1Scale(length: 250.0)
            let h2 = StandardScales.h2Scale(length: 250.0)
            
            // H2 should start near where H1 ends
            #expect(abs(h2.beginValue - h1.endValue) < 0.01)
        }
    }
    
    // MARK: - P Scale Tests
    
    @Suite("P Scale - Pythagorean Complement")
    struct PScaleTests {
        
        @Test("P scale has correct basic properties")
        func pScaleBasicProperties() {
            let p = StandardScales.pScale(length: 250.0)
            
            #expect(p.name == "P")
            #expect(p.beginValue == 0.0)
            #expect(p.endValue == 0.995)
            #expect(p.scaleLengthInPoints == 250.0)
            #expect(p.tickDirection == .up)
        }
        
        @Test("P scale uses PythagoreanPFunction")
        func pScaleFunctionType() {
            let p = StandardScales.pScale(length: 250.0)
            #expect(p.function is PythagoreanPFunction)
        }
        
        @Test("P scale has red label color")
        func pScaleRedLabels() {
            let p = StandardScales.pScale(length: 250.0)
            
            // Verify red label color (RGB: 1.0, 0.0, 0.0)
            if let labelColor = p.labelColor {
                #expect(labelColor.red == 1.0)
                #expect(labelColor.green == 0.0)
                #expect(labelColor.blue == 0.0)
            } else {
                Issue.record("P scale should have label color")
            }
        }
        
        @Test("P scale has many subsections for fine precision")
        func pScaleSubsections() {
            let p = StandardScales.pScale(length: 250.0)
            #expect(p.subsections.count >= 8)
        }
        
        @Test("P scale position calculations near boundaries",
              arguments: [0.0, 0.5, 0.9, 0.99, 0.995])
        func pScalePositionCalculations(value: Double) {
            let p = StandardScales.pScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: p)
            #expect(pos >= 0.0 && pos <= 1.0)
            
            let recovered = ScaleCalculator.value(at: pos, on: p)
            let absoluteError = abs(recovered - value)
            #expect(absoluteError < 0.01)
        }
    }
    
    // MARK: - Linear Degree Scales
    
    @Suite("L360/L180 Scales - Linear Degree Scales")
    struct LinearDegreeScalesTests {
        
        @Test("L360 scale has correct properties")
        func l360ScaleProperties() {
            let l360 = StandardScales.l360Scale(length: 250.0)
            
            #expect(l360.name == "L360")
            #expect(l360.beginValue == 0.0)
            #expect(l360.endValue == 360.0)
            #expect(l360.scaleLengthInPoints == 250.0)
            #expect(l360.tickDirection == .up)
        }
        
        @Test("L360 scale uses LinearDegreeFunction")
        func l360ScaleFunctionType() {
            let l360 = StandardScales.l360Scale(length: 250.0)
            #expect(l360.function is LinearDegreeFunction)
        }
        
        @Test("L360 scale position calculations at key angles",
              arguments: [0.0, 90.0, 180.0, 270.0, 360.0])
        func l360ScaleAngles(angle: Double) {
            let l360 = StandardScales.l360Scale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: angle, on: l360)
            
            let expectedPos = angle / 360.0
            #expect(abs(pos - expectedPos) < 0.01, "Linear scale should map linearly")
        }
        
        @Test("L180 scale has correct properties")
        func l180ScaleProperties() {
            let l180 = StandardScales.l180Scale(length: 250.0)
            
            #expect(l180.name == "L180")
            #expect(l180.beginValue == 0.0)
            #expect(l180.endValue == 360.0)
            #expect(l180.scaleLengthInPoints == 250.0)
            #expect(l180.tickDirection == .down)
        }
        
        @Test("L180 scale has dual labeling subsections")
        func l180ScaleDualLabeling() {
            let l180 = StandardScales.l180Scale(length: 250.0)
            
            // Should have at least 2 subsections for dual labeling
            #expect(l180.subsections.count >= 2)
            
            // Second subsection should have dual labels
            if l180.subsections.count >= 2 {
                let secondSubsection = l180.subsections[1]
                #expect(secondSubsection.startValue == 190.0)
            }
        }
        
        @Test("L180 and L360 use same function")
        func l180AndL360SameFunction() {
            let l180 = StandardScales.l180Scale(length: 250.0)
            let l360 = StandardScales.l360Scale(length: 250.0)
            
            #expect(l180.function is LinearDegreeFunction)
            #expect(l360.function is LinearDegreeFunction)
            
            // Both should have same range
            #expect(l180.endValue == l360.endValue)
        }
    }
    
    // MARK: - PA Scale Tests
    
    @Suite("PA Scale - Percentage Angular")
    struct PAScaleTests {
        
        @Test("PA scale has correct basic properties")
        func paScaleBasicProperties() {
            let pa = StandardScales.paScale(length: 250.0)
            
            #expect(pa.name == "PA")
            #expect(pa.beginValue == 9.0)
            #expect(pa.endValue == 91.0)
            #expect(pa.scaleLengthInPoints == 250.0)
            #expect(pa.tickDirection == .down)
        }
        
        @Test("PA scale uses PercentageAngularFunction")
        func paScaleFunctionType() {
            let pa = StandardScales.paScale(length: 250.0)
            #expect(pa.function is PercentageAngularFunction)
        }
        
        @Test("PA scale position calculations work correctly",
              arguments: [10.0, 25.0, 50.0, 75.0, 90.0])
        func paScalePositionCalculations(value: Double) {
            let pa = StandardScales.paScale(length: 250.0)
            
            // Only test values within range
            if value >= pa.beginValue && value <= pa.endValue {
                let pos = ScaleCalculator.normalizedPosition(for: value, on: pa)
                #expect(pos >= 0.0 && pos <= 1.0)
                
                let recovered = ScaleCalculator.value(at: pos, on: pa)
                let absoluteError = abs(recovered - value)
                #expect(absoluteError < 1.0)
            }
        }
        
        @Test("PA scale generates ticks without errors")
        func paScaleTickGeneration() {
            let pa = StandardScales.paScale(length: 250.0)
            let generated = GeneratedScale(definition: pa)
            
            #expect(!generated.tickMarks.isEmpty, "PA scale should generate ticks")
        }
    }
    
    // MARK: - Scale Instantiation Tests
    
    @Suite("Hyperbolic Scales - Instantiation")
    struct HyperbolicScalesInstantiationTests {
        
        @Test("All hyperbolic scales can be instantiated without errors")
        func allScalesInstantiate() {
            let scales = [
                StandardScales.chScale(),
                StandardScales.thScale(),
                StandardScales.shScale(),
                StandardScales.sh1Scale(),
                StandardScales.sh2Scale(),
                StandardScales.h1Scale(),
                StandardScales.h2Scale(),
                StandardScales.pScale(),
                StandardScales.l360Scale(),
                StandardScales.l180Scale(),
                StandardScales.paScale()
            ]
            
            for scale in scales {
                #expect(scale.scaleLengthInPoints > 0)
                #expect(scale.name.count > 0)
                #expect(!scale.subsections.isEmpty)
            }
        }
        
        @Test("All hyperbolic scales work with custom lengths",
              arguments: [100.0, 250.0, 500.0])
        func allScalesCustomLengths(length: Double) {
            let scales = [
                StandardScales.chScale(length: length),
                StandardScales.thScale(length: length),
                StandardScales.shScale(length: length),
                StandardScales.h1Scale(length: length),
                StandardScales.h2Scale(length: length),
                StandardScales.pScale(length: length)
            ]
            
            for scale in scales {
                #expect(scale.scaleLengthInPoints == length)
            }
        }
        
        @Test("All hyperbolic scales generate ticks successfully")
        func allScalesGenerateTicks() {
            let scales = [
                StandardScales.chScale(),
                StandardScales.thScale(),
                StandardScales.shScale(),
                StandardScales.sh1Scale(),
                StandardScales.sh2Scale(),
                StandardScales.h1Scale(),
                StandardScales.h2Scale(),
                StandardScales.pScale(),
                StandardScales.l360Scale(),
                StandardScales.l180Scale(),
                StandardScales.paScale()
            ]
            
            for scale in scales {
                let generated = GeneratedScale(definition: scale)
                #expect(!generated.tickMarks.isEmpty,
                       "\(scale.name) should generate non-empty ticks")
            }
        }
    }
}
