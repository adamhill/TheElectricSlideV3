import Testing
import Foundation
@testable import SlideRuleCoreV3

@Suite("FC283N LL02 Scale Tests")
struct FC283N_LL02Tests {
    
    // MARK: - Ghost Start Calculation Helper
    
    /// LL02 function: log₁₀(-ln(x) × 10)
    private func ll02Transform(_ value: Double) -> Double {
        return log10(-log(value) * 10.0)
    }
    
    /// LL02 inverse function
    private func ll02InverseTransform(_ transformed: Double) -> Double {
        return exp(-pow(10, transformed) / 10.0)
    }
    
    @Test("Calculate virtual end value for ghost end")
    func calculateVirtualEnd() throws {
        // After 0.35, there are 15 more ticks before the scale ends visually
        // Last visible tick is at 0.32
        // We want this last tick to appear at ~99% position (1% gap at end)
        
        let visibleEnd = 0.32         // Last visible tick
        let beginValue = 0.912272537119513  // Virtual begin for 1.1% gap
        let gapFraction = 0.03        // 3% gap at end
        
        // LL02 transform: f(x) = log₁₀(-ln(x) × 10)
        func ll02Transform(_ value: Double) -> Double {
            return log10(-log(value) * 10.0)
        }
        
        func ll02InverseTransform(_ transformed: Double) -> Double {
            return exp(-pow(10, transformed) / 10.0)
        }
        
        let fBegin = ll02Transform(beginValue)
        let fVisibleEnd = ll02Transform(visibleEnd)
        
        // For virtual end calculation:
        // gapFraction = (f(virtualEnd) - f(visibleEnd)) / (f(virtualEnd) - f(begin))
        // Solving for f(virtualEnd):
        // V = (fVisibleEnd - gapFraction * fBegin) / (1 - gapFraction)
        let virtualTransformed = (fVisibleEnd - gapFraction * fBegin) / (1 - gapFraction)
        let virtualEnd = ll02InverseTransform(virtualTransformed)
        
        print("Ghost end calculation:")
        print("  Begin transforms to: \(fBegin)")
        print("  Visible end (0.32) transforms to: \(fVisibleEnd)")
        print("  Virtual end transforms to: \(virtualTransformed)")
        print("  Virtual end value: \(virtualEnd)")
        
        // Verify
        let testRange = ll02Transform(virtualEnd) - ll02Transform(beginValue)
        let testPos32 = (ll02Transform(0.32) - ll02Transform(beginValue)) / testRange
        print("  Verification: 0.32 at normalized position: \(testPos32)")
        
        // The virtual end should be slightly smaller than 0.32 (since scale runs high→low)
        #expect(virtualEnd < 0.32, "Virtual end should be < 0.32 for gap")
        #expect(virtualEnd > 0.30, "Virtual end should be reasonable (> 0.30)")
        #expect(abs(testPos32 - (1.0 - gapFraction)) < 0.001, "0.32 should be at position \(1.0 - gapFraction)")
    }
    
    @Test("Calculate virtual begin value for ghost start")
    func calculateVirtualBegin() throws {
        // Current values
        let visibleStart = 0.91  // First visible tick/label
        let endValue = 0.35      // End of scale
        let gapFraction = 0.011   // 1.1% gap at start
        
        let fVisibleStart = ll02Transform(visibleStart)
        let fEnd = ll02Transform(endValue)
        
        // For virtual begin calculation:
        // gapFraction = (f(visibleStart) - f(virtualBegin)) / (f(end) - f(virtualBegin))
        // Solving for f(virtualBegin):
        // V = (fVisibleStart - gapFraction * fEnd) / (1 - gapFraction)
        let virtualTransformed = (fVisibleStart - gapFraction * fEnd) / (1 - gapFraction)
        let virtualBegin = ll02InverseTransform(virtualTransformed)
        
        print("Ghost start calculation:")
        print("  Visible start (0.91) transforms to: \(fVisibleStart)")
        print("  End (0.35) transforms to: \(fEnd)")
        print("  Virtual begin transforms to: \(virtualTransformed)")
        print("  Virtual begin value: \(virtualBegin)")
        
        // Verify
        let testRange = ll02Transform(endValue) - ll02Transform(virtualBegin)
        let testPos91 = (ll02Transform(0.91) - ll02Transform(virtualBegin)) / testRange
        print("  Verification: 0.91 at normalized position: \(testPos91)")
        
        // The virtual begin should be slightly larger than 0.91 (since scale is reversed)
        #expect(virtualBegin > 0.91, "Virtual begin should be > 0.91 for reversed scale")
        #expect(virtualBegin < 0.95, "Virtual begin should be reasonable (< 0.95)")
        #expect(abs(testPos91 - gapFraction) < 0.001, "0.91 should be at position \(gapFraction)")
    }
    
    @Test("FC283N_LL02 scale has correct tick count between 0.91 and 0.90")
    func tickCountBetween91And90() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        // Filter ticks between 0.90 and 0.91 (exclusive of endpoints)
        let ticksBetween = generated.tickMarks.filter { tick in
            tick.value > 0.90 && tick.value < 0.91
        }
        
        // Expected: 19 ticks between 0.91 and 0.90 labels
        print("Ticks between 0.90 and 0.91: \(ticksBetween.count)")
        #expect(ticksBetween.count == 19, "Expected 19 ticks between 0.91 and 0.90, got \(ticksBetween.count)")
    }
    
    @Test("FC283N_LL02 scale has correct tick count between 0.90 and 0.85")
    func tickCountBetween90And85() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        // Filter ticks between 0.85 and 0.90 (exclusive of endpoints)
        let ticksBetween = generated.tickMarks.filter { tick in
            tick.value > 0.85 && tick.value < 0.90
        }
        
        // Expected: 49 ticks between 0.90 and 0.85 labels
        print("Ticks between 0.85 and 0.90: \(ticksBetween.count)")
        #expect(ticksBetween.count == 49, "Expected 49 ticks between 0.90 and 0.85, got \(ticksBetween.count)")
    }
    
    @Test("FC283N_LL02 scale has correct tick count between 0.85 and 0.80")
    func tickCountBetween85And80() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        // Filter ticks between 0.80 and 0.85 (exclusive of endpoints)
        let ticksBetween = generated.tickMarks.filter { tick in
            tick.value > 0.80 && tick.value < 0.85
        }
        
        // Expected: 49 ticks between 0.85 and 0.80 labels
        print("Ticks between 0.80 and 0.85: \(ticksBetween.count)")
        #expect(ticksBetween.count == 49, "Expected 49 ticks between 0.85 and 0.80, got \(ticksBetween.count)")
    }
    
    @Test("FC283N_LL02 scale has correct tick count between 0.80 and 0.75")
    func tickCountBetween80And75() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        let ticksBetween = generated.tickMarks.filter { tick in
            tick.value > 0.75 && tick.value < 0.80
        }
        
        // Expected: 24 ticks between 0.80 and 0.75 labels
        print("Ticks between 0.75 and 0.80: \(ticksBetween.count)")
        #expect(ticksBetween.count == 24, "Expected 24 ticks between 0.80 and 0.75, got \(ticksBetween.count)")
    }
    
    @Test("FC283N_LL02 scale has correct tick count between 0.40 and 0.35")
    func tickCountBetween40And35() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        let ticksBetween = generated.tickMarks.filter { tick in
            tick.value > 0.35 && tick.value < 0.40
        }
        
        // Expected: 24 ticks between 0.40 and 0.35 labels
        print("Ticks between 0.35 and 0.40: \(ticksBetween.count)")
        #expect(ticksBetween.count == 24, "Expected 24 ticks between 0.40 and 0.35, got \(ticksBetween.count)")
    }
    
    @Test("FC283N_LL02 scale has 15 ticks past 0.35 (ghost end)")
    func tickCountPast35() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        let ticksPast35 = generated.tickMarks.filter { tick in
            tick.value < 0.35
        }
        
        // Expected: 15 ticks past 0.35 to end
        print("Ticks past 0.35: \(ticksPast35.count)")
        #expect(ticksPast35.count == 15, "Expected 15 ticks past 0.35, got \(ticksPast35.count)")
    }
    
    @Test("FC283N_LL02 scale has 0.91 as first labeled value")
    func firstLabelIs91() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        // Find all labeled ticks
        let labeledTicks = generated.tickMarks.filter { !$0.labels.isEmpty && $0.labels.first?.text.isEmpty == false }
        
        // Sort by position (left to right)
        let sortedLabeled = labeledTicks.sorted { $0.normalizedPosition < $1.normalizedPosition }
        
        if let firstLabeled = sortedLabeled.first {
            print("First labeled value: \(firstLabeled.value), label: \(firstLabeled.labels.first?.text ?? "nil")")
            #expect(abs(firstLabeled.value - 0.91) < 0.001, "First label should be at 0.91")
        } else {
            Issue.record("No labeled ticks found")
        }
    }
    
    @Test("FC283N_LL02 first tick (0.91) appears at ~1% position (ghost start)")
    func firstTickAtGhostStartPosition() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        // Find the first tick (should be at 0.91)
        let sortedTicks = generated.tickMarks.sorted { $0.normalizedPosition < $1.normalizedPosition }
        
        guard let firstTick = sortedTicks.first else {
            Issue.record("No ticks generated")
            return
        }
        
        print("First tick value: \(firstTick.value), position: \(firstTick.normalizedPosition)")
        
        // First tick should be at 0.91 (not at the virtual begin value)
        #expect(abs(firstTick.value - 0.91) < 0.001, "First tick should be at 0.91, got \(firstTick.value)")
        
        // Position should be ~1% from left edge
        #expect(firstTick.normalizedPosition > 0.005, "First tick should have gap from left edge")
        #expect(firstTick.normalizedPosition < 0.015, "First tick should be near 1% position, got \(firstTick.normalizedPosition)")
    }
    
    @Test("FC283N_LL02 scale starts at virtual begin value for ghost start")
    func scaleStartsAtVirtualBegin() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let virtualBegin = 0.912272537119513  // For 1.1% gap
        
        #expect(abs(scale.beginValue - virtualBegin) < 0.0001, "Scale should begin at virtual value \(virtualBegin), got \(scale.beginValue)")
    }
    
    @Test("FC283N_LL02 scale ends at virtual end value for ghost end")
    func scaleEndsAtVirtualEnd() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let virtualEnd = 0.29178597781571775  // For 3% gap at end
        
        #expect(abs(scale.endValue - virtualEnd) < 0.0001, "Scale should end at virtual value \(virtualEnd), got \(scale.endValue)")
    }
    }
    
    @Test("FC283N_LL02 has 1/e gauge mark")
    func hasOneOverEGaugeMark() throws {
        let scale = StandardScales.FC283N_LL02(length: 250.0)
        let generated = GeneratedScale(definition: scale)
        
        // Look for 1/e constant (≈ 0.368)
        let oneOverE = 1.0 / Double.e  // ≈ 0.36788
        
        let oneOverETick = generated.tickMarks.first { tick in
            abs(tick.value - oneOverE) < 0.001 && tick.labels.first?.text == "1/e"
        }
        
        #expect(oneOverETick != nil, "Expected 1/e gauge mark at ≈0.368")
    }
}
