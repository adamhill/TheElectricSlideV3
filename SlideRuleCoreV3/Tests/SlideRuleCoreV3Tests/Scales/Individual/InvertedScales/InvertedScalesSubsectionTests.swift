import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive tests for CI, DI, CIF, and DIF scales
/// Tests subsection coverage and tick generation for inverted scales
@Suite("Inverted Scales Subsection Tests", .tags(.ciScale, .diScale))
struct InvertedScalesSubsectionTests {
    
    // MARK: - CI Scale Subsection Tests
    
    @Suite("CI Scale Subsection Coverage")
    struct CIScaleSubsections {
        
        @Test("CI scale covers complete range 10 to 1")
        func ciScaleRangeCoverage() {
            let ci = StandardScales.ciScale(length: 250.0)
            
            #expect(ci.beginValue == 10.0, "CI should begin at 10")
            #expect(ci.endValue == 1.0, "CI should end at 1")
        }
        
        @Test("CI scale has subsections for all three ranges")
        func ciScaleSubsectionCount() {
            let ci = StandardScales.ciScale(length: 250.0)
            
            // CI scale should have 3 subsections mirroring C scale
            // Range 10→4, 4→2, 2→1
            #expect(ci.subsections.count == 3,
                   "CI should have 3 subsections, got \(ci.subsections.count)")
        }
        
        @Test("CI scale first subsection covers 10 to 4 range")
        func ciScaleFirstSubsection() {
            let ci = StandardScales.ciScale(length: 250.0)
            
            guard ci.subsections.count >= 1 else {
                Issue.record("CI scale missing subsections")
                return
            }
            
            let firstSub = ci.subsections[0]
            #expect(firstSub.startValue == 10.0,
                   "First subsection should start at 10, got \(firstSub.startValue)")
        }
        
        @Test("CI scale second subsection covers 4 to 2 range")
        func ciScaleSecondSubsection() {
            let ci = StandardScales.ciScale(length: 250.0)
            
            guard ci.subsections.count >= 2 else {
                Issue.record("CI scale missing second subsection")
                return
            }
            
            let secondSub = ci.subsections[1]
            #expect(secondSub.startValue == 4.0,
                   "Second subsection should start at 4, got \(secondSub.startValue)")
        }
        
        @Test("CI scale third subsection covers 2 to 1 range")
        func ciScaleThirdSubsection() {
            let ci = StandardScales.ciScale(length: 250.0)
            
            guard ci.subsections.count >= 3 else {
                Issue.record("CI scale missing third subsection")
                return
            }
            
            let thirdSub = ci.subsections[2]
            #expect(thirdSub.startValue == 2.0,
                   "Third subsection should start at 2, got \(thirdSub.startValue)")
        }
        
        @Test("CI scale generates ticks in 10-4 range")
        func ciScaleTicksIn10to4Range() {
            let ci = StandardScales.ciScale(length: 250.0)
            let generated = GeneratedScale(definition: ci)
            
            // Check for ticks in the 10→4 range
            let ticksIn10to4 = generated.tickMarks.filter { tick in
                tick.value <= 10.0 && tick.value >= 4.0
            }
            
            #expect(!ticksIn10to4.isEmpty,
                   "CI scale should generate ticks in 10-4 range, found \(ticksIn10to4.count) ticks")
            
            // Should have multiple ticks in this range
            #expect(ticksIn10to4.count > 10,
                   "Expected many ticks in 10-4 range, got \(ticksIn10to4.count)")
        }
        
        @Test("CI scale generates ticks in 4-2 range")
        func ciScaleTicksIn4to2Range() {
            let ci = StandardScales.ciScale(length: 250.0)
            let generated = GeneratedScale(definition: ci)
            
            let ticksIn4to2 = generated.tickMarks.filter { tick in
                tick.value < 4.0 && tick.value >= 2.0
            }
            
            #expect(!ticksIn4to2.isEmpty,
                   "CI scale should generate ticks in 4-2 range")
        }
        
        @Test("CI scale generates ticks in 2-1 range")
        func ciScaleTicksIn2to1Range() {
            let ci = StandardScales.ciScale(length: 250.0)
            let generated = GeneratedScale(definition: ci)
            
            let ticksIn2to1 = generated.tickMarks.filter { tick in
                tick.value < 2.0 && tick.value >= 1.0
            }
            
            #expect(!ticksIn2to1.isEmpty,
                   "CI scale should generate ticks in 2-1 range")
        }
        
        @Test("CI scale at 2 aligns with C scale at 5")
        func ciScaleAlignmentWithCScale() {
            let ci = StandardScales.ciScale(length: 250.0)
            let c = StandardScales.cScale(length: 250.0)
            
            // CI(2) should align with C(5) because 1/2 * 10 = 5
            let ciPos2 = ScaleCalculator.normalizedPosition(for: 2.0, on: ci)
            let cPos5 = ScaleCalculator.normalizedPosition(for: 5.0, on: c)
            
            #expect(abs(ciPos2 - cPos5) < 1e-9,
                   "CI at 2 should align with C at 5. CI(2)=\(ciPos2), C(5)=\(cPos5), diff=\(abs(ciPos2 - cPos5))")
        }
    }
    
    // MARK: - DI Scale Tests
    
    @Suite("DI Scale Subsection Coverage")
    struct DIScaleSubsections {
        
        @Test("DI scale has same subsections as CI")
        func diScaleSubsectionCount() {
            let di = StandardScales.diScale(length: 250.0)
            let ci = StandardScales.ciScale(length: 250.0)
            
            #expect(di.subsections.count == ci.subsections.count,
                   "DI should have same subsection count as CI")
        }
        
        @Test("DI scale generates ticks in all ranges")
        func diScaleTickGeneration() {
            let di = StandardScales.diScale(length: 250.0)
            let generated = GeneratedScale(definition: di)
            
            let ticks10to4 = generated.tickMarks.filter { $0.value <= 10.0 && $0.value >= 4.0 }
            let ticks4to2 = generated.tickMarks.filter { $0.value < 4.0 && $0.value >= 2.0 }
            let ticks2to1 = generated.tickMarks.filter { $0.value < 2.0 && $0.value >= 1.0 }
            
            #expect(!ticks10to4.isEmpty, "DI should have ticks in 10-4 range")
            #expect(!ticks4to2.isEmpty, "DI should have ticks in 4-2 range")
            #expect(!ticks2to1.isEmpty, "DI should have ticks in 2-1 range")
        }
        
        @Test("DI scale has opposite tick direction from CI")
        func diScaleTickDirection() {
            let di = StandardScales.diScale(length: 250.0)
            let ci = StandardScales.ciScale(length: 250.0)
            
            #expect(di.tickDirection != ci.tickDirection,
                   "DI and CI should have opposite tick directions")
            #expect(di.tickDirection == .down, "DI ticks should point down")
            #expect(ci.tickDirection == .up, "CI ticks should point up")
        }
    }
    
    // MARK: - CIF Scale Tests
    
    @Suite("CIF Scale Subsection Coverage")
    struct CIFScaleSubsections {
        
        @Test("CIF scale covers folded range 10π to π")
        func cifScaleRangeCoverage() {
            let cif = StandardScales.cifScale(length: 250.0)
            
            #expect(cif.beginValue == 10.0 * .pi, "CIF should begin at 10π")
            #expect(cif.endValue == .pi, "CIF should end at π")
        }
        
        @Test("CIF scale has multiple subsections")
        func cifScaleSubsectionCount() {
            let cif = StandardScales.cifScale(length: 250.0)
            
            #expect(cif.subsections.count >= 3,
                   "CIF should have multiple subsections, got \(cif.subsections.count)")
        }
        
        @Test("CIF scale generates ticks throughout range")
        func cifScaleTickGeneration() {
            let cif = StandardScales.cifScale(length: 250.0)
            let generated = GeneratedScale(definition: cif)
            
            #expect(!generated.tickMarks.isEmpty,
                   "CIF should generate ticks")
            
            // Check ticks exist in different parts of the range
            let ticksNearStart = generated.tickMarks.filter { $0.value > 20.0 }
            let ticksNearMiddle = generated.tickMarks.filter { $0.value > 5.0 && $0.value <= 20.0 }
            let ticksNearEnd = generated.tickMarks.filter { $0.value <= 5.0 }
            
            #expect(!ticksNearStart.isEmpty, "CIF should have ticks near 10π")
            #expect(!ticksNearMiddle.isEmpty, "CIF should have ticks in middle range")
            #expect(!ticksNearEnd.isEmpty, "CIF should have ticks near π")
        }
    }
    
    // MARK: - DIF Scale Tests
    
    @Suite("DIF Scale Subsection Coverage")
    struct DIFScaleSubsections {
        
        @Test("DIF scale matches CIF range")
        func difScaleRangeCoverage() {
            let dif = StandardScales.difScale(length: 250.0)
            let cif = StandardScales.cifScale(length: 250.0)
            
            #expect(dif.beginValue == cif.beginValue, "DIF and CIF should have same begin value")
            #expect(dif.endValue == cif.endValue, "DIF and CIF should have same end value")
        }
        
        @Test("DIF scale has opposite tick direction from CIF")
        func difScaleTickDirection() {
            let dif = StandardScales.difScale(length: 250.0)
            let cif = StandardScales.cifScale(length: 250.0)
            
            #expect(dif.tickDirection != cif.tickDirection,
                   "DIF and CIF should have opposite tick directions")
        }
        
        @Test("DIF scale generates ticks")
        func difScaleTickGeneration() {
            let dif = StandardScales.difScale(length: 250.0)
            let generated = GeneratedScale(definition: dif)
            
            #expect(!generated.tickMarks.isEmpty,
                   "DIF should generate ticks")
        }
    }
    
    // MARK: - Comparison Tests
    
    @Suite("CI/DI Parity Tests")
    struct CIDIParity {
        
        @Test("CI and DI generate same tick positions")
        func ciDiTickPositionParity() {
            let ci = StandardScales.ciScale(length: 250.0)
            let di = StandardScales.diScale(length: 250.0)
            
            let genCI = GeneratedScale(definition: ci)
            let genDI = GeneratedScale(definition: di)
            
            #expect(genCI.tickMarks.count == genDI.tickMarks.count,
                   "CI and DI should have same tick count")
            
            // Check positions match
            for (ciTick, diTick) in zip(genCI.tickMarks, genDI.tickMarks) {
                #expect(abs(ciTick.normalizedPosition - diTick.normalizedPosition) < 1e-9,
                       "Tick positions should match: CI=\(ciTick.normalizedPosition), DI=\(diTick.normalizedPosition)")
            }
        }
    }
}