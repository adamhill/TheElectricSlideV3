//
//  ScaleTickSafetyTests.swift
//  SlideRuleCoreV3Tests
//
//  Comprehensive safety tests to ensure no scale definition causes runaway tick generation.
//  These tests prevent memory exhaustion and crashes from misconfigured scales.
//

import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Scale Safety Test Configuration

/// Maximum acceptable ticks per scale - prevents runaway generation
/// This should be well below the ScaleCalculator.maxTickIterations guard (100,000)
/// but high enough to allow legitimate complex scales
private let maxAcceptableTicks = 10_000

/// Maximum acceptable time for tick generation (in seconds)
private let maxTickGenerationTime: TimeInterval = 1.0

// MARK: - All Scales Tick Safety Tests

@Suite("Scale Tick Safety Tests", .tags(.safety))
struct ScaleTickSafetyTests {
    
    // MARK: - Standard Scales Safety
    
    @Test("All standard scales generate reasonable tick counts")
    func allStandardScalesTickCounts() throws {
        let standardScales: [(String, ScaleDefinition)] = [
            ("C", StandardScales.cScale()),
            ("D", StandardScales.dScale()),
            ("CI", StandardScales.ciScale()),
            ("DI", StandardScales.diScale()),
            ("CF", StandardScales.cfScale()),
            ("DF", StandardScales.dfScale()),
            ("DFm", StandardScales.dfmScale()),
            ("CIF", StandardScales.cifScale()),
            ("DIF", StandardScales.difScale()),
            ("A", StandardScales.aScale()),
            ("B", StandardScales.bScale()),
            ("AI", StandardScales.aiScale()),
            ("BI", StandardScales.biScale()),
            ("K", StandardScales.kScale()),
            ("S", StandardScales.sScale()),
            ("T", StandardScales.tScale()),
            ("T1", StandardScales.t1Scale()),
            ("T2", StandardScales.t2Scale()),
            ("ST", StandardScales.stScale()),
            ("L", StandardScales.lScale()),
            ("Ln", StandardScales.lnScale()),
            ("KE-S", StandardScales.keSScale()),
            ("KE-T", StandardScales.keTScale()),
            ("KE-ST/SRT", StandardScales.keSTScale()),
            ("C10-100", StandardScales.c10to100Scale()),
            ("C100-1000", StandardScales.c100to1000Scale()),
            ("D10-100", StandardScales.d10to100Scale()),
            ("CAS", StandardScales.casScale()),
            ("TIME", StandardScales.timeScale()),
            ("TIME2", StandardScales.time2Scale()),
            ("CR3S/S/C", StandardScales.cr3sScale()),
            ("R1/Sq1", StandardScales.r1Scale()),
            ("R2/Sq2", StandardScales.r2Scale()),
            ("Q1", StandardScales.q1Scale()),
            ("Q2", StandardScales.q2Scale()),
            ("Q3", StandardScales.q3Scale())
        ]
        
        for (name, scale) in standardScales {
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            #expect(
                ticks.count > 0 && ticks.count <= maxAcceptableTicks,
                "Standard scale '\(name)' generated \(ticks.count) ticks (should be 1-\(maxAcceptableTicks))"
            )
        }
    }
    
    // MARK: - Hyperbolic Scales Safety
    
    @Test("All hyperbolic scales generate reasonable tick counts")
    func allHyperbolicScalesTickCounts() throws {
        let hyperbolicScales: [(String, ScaleDefinition)] = [
            ("Ch", StandardScales.chScale()),
            ("Th", StandardScales.thScale()),
            ("Sh", StandardScales.shScale()),
            ("Sh1", StandardScales.sh1Scale()),
            ("Sh2", StandardScales.sh2Scale()),
            ("H1", StandardScales.h1Scale()),
            ("H2", StandardScales.h2Scale()),
            ("P", StandardScales.pScale()),
            ("PA", StandardScales.paScale()),
            ("L360", StandardScales.l360Scale()),
            ("L180", StandardScales.l180Scale())
        ]
        
        for (name, scale) in hyperbolicScales {
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            #expect(
                ticks.count > 0 && ticks.count <= maxAcceptableTicks,
                "Hyperbolic scale '\(name)' generated \(ticks.count) ticks (should be 1-\(maxAcceptableTicks))"
            )
        }
    }
    
    // MARK: - Log-Log Scales Safety
    
    @Test("All log-log scales generate reasonable tick counts")
    func allLogLogScalesTickCounts() throws {
        let logLogScales: [(String, ScaleDefinition)] = [
            ("LL0", StandardScales.ll0Scale()),
            ("LL1", StandardScales.ll1Scale()),
            ("LL2", StandardScales.ll2Scale()),
            ("LL3", StandardScales.ll3Scale()),
            ("LL00", StandardScales.ll00Scale()),
            ("LL01", StandardScales.ll01Scale()),
            ("LL02", StandardScales.ll02Scale()),
            ("LL03", StandardScales.ll03Scale()),
            ("H266LL01", StandardScales.h266LL01Scale()),
            ("H266LL03", StandardScales.h266LL03Scale()),
            ("LL02B", StandardScales.ll02BScale()),
            ("LL2B", StandardScales.ll2BScale_PostScriptAccurate())
        ]
        
        for (name, scale) in logLogScales {
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            #expect(
                ticks.count > 0 && ticks.count <= maxAcceptableTicks,
                "Log-Log scale '\(name)' generated \(ticks.count) ticks (should be 1-\(maxAcceptableTicks))"
            )
        }
    }
    
    // MARK: - Electrical Engineering Scales Safety
    
    @Test("All EE scales generate reasonable tick counts")
    func allEEScalesTickCounts() throws {
        let eeScales: [(String, ScaleDefinition)] = [
            ("XL", StandardScales.xlScale()),
            ("Xc", StandardScales.xcScale()),
            ("F", StandardScales.fScale()),
            ("L (EE)", StandardScales.eeInductanceScale()),
            ("Li", StandardScales.eeInductanceInvertedScale()),
            ("Cf (EE)", StandardScales.eeCapacitanceFrequencyScale()),
            ("Cz", StandardScales.czScale()),
            ("Z", StandardScales.zScale()),
            ("Fo", StandardScales.foScale()),
            ("r1 (EE)", StandardScales.eeReflectionCoefficientScale()),
            ("r2 (EE)", StandardScales.eeReflectionCoefficient2Scale()),
            ("P (EE)", StandardScales.eePowerRatioScale()),
            ("Q (EE)", StandardScales.eePowerRatioInvertedScale())
        ]
        
        for (name, scale) in eeScales {
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            #expect(
                ticks.count > 0 && ticks.count <= maxAcceptableTicks,
                "EE scale '\(name)' generated \(ticks.count) ticks (should be 1-\(maxAcceptableTicks))"
            )
        }
    }
    
    // MARK: - Pickett N-16 ES Scales Safety
    
    @Test("All Pickett N-16 ES scales generate reasonable tick counts")
    func allPickettN16ESScalesTickCounts() throws {
        let n16esScales: [(String, ScaleDefinition)] = [
            ("Lr", StandardScales.n16esLrScale()),
            ("Cr", StandardScales.n16esCrScale()),
            ("C/L", StandardScales.n16esClScale()),
            ("F (N16)", StandardScales.n16esFrequencyScale()),
            ("ω (omega)", StandardScales.n16esOmegaScale()),
            ("λ (lambda)", StandardScales.n16esWavelengthScale()),
            ("Θ (theta)", StandardScales.n16esThetaScale()),
            ("cos Θ", StandardScales.n16esCosThetaScale()),
            ("dB Power", StandardScales.n16esDecibelPowerScale()),
            ("dB Voltage", StandardScales.n16esDecibelVoltageScale()),
            ("D/Q", StandardScales.n16esDecimalKeeperScale()),
            ("Q Factor", StandardScales.n16esQFactorScale()),
            ("τ (tau)", StandardScales.n16esTimeConstantScale())
        ]
        
        for (name, scale) in n16esScales {
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            #expect(
                ticks.count > 0 && ticks.count <= maxAcceptableTicks,
                "Pickett N-16 ES scale '\(name)' generated \(ticks.count) ticks (should be 1-\(maxAcceptableTicks))"
            )
        }
    }
    
    // MARK: - Tick Generation Time Safety
    
    @Test("All scales generate ticks within time limit")
    func allScalesGenerateTicksWithinTimeLimit() throws {
        // Collect all scale factory methods
        let allScales = collectAllScaleDefinitions()
        
        for (name, scale) in allScales {
            let startTime = Date()
            let _ = ScaleCalculator.generateTickMarks(for: scale)
            let elapsed = Date().timeIntervalSince(startTime)
            
            #expect(
                elapsed < maxTickGenerationTime,
                "Scale '\(name)' took \(String(format: "%.2f", elapsed))s to generate ticks (limit: \(maxTickGenerationTime)s)"
            )
        }
    }
    
    // MARK: - Scale Range Validation
    
    @Test("All scales have valid range configuration")
    func allScalesHaveValidRangeConfiguration() throws {
        let allScales = collectAllScaleDefinitions()
        
        for (name, scale) in allScales {
            // Range should not be inverted in a way that causes issues
            let rangeSpan = abs(scale.endValue - scale.beginValue)
            #expect(
                rangeSpan > 0,
                "Scale '\(name)' has zero or negative range span"
            )
            
            // Range should be finite
            #expect(
                rangeSpan.isFinite,
                "Scale '\(name)' has infinite range span"
            )
            
            // Range should not be astronomically large (indicator of runaway potential)
            let reasonableMaxRange: Double = 1_000_000
            #expect(
                rangeSpan < reasonableMaxRange,
                "Scale '\(name)' has range span \(rangeSpan) which may cause performance issues"
            )
        }
    }
    
    // MARK: - Subsection Configuration Validation
    
    @Test("All scales have valid subsection tick intervals")
    func allScalesHaveValidSubsectionIntervals() throws {
        let allScales = collectAllScaleDefinitions()
        
        for (name, scale) in allScales {
            for (index, subsection) in scale.subsections.enumerated() {
                // All tick intervals should be positive
                for interval in subsection.tickIntervals {
                    #expect(
                        interval >= 0,
                        "Scale '\(name)' subsection \(index) has negative tick interval: \(interval)"
                    )
                }
                
                // At least one interval should be non-zero
                let hasNonZeroInterval = subsection.tickIntervals.contains { $0 > 0 }
                #expect(
                    hasNonZeroInterval,
                    "Scale '\(name)' subsection \(index) has all zero tick intervals"
                )
                
                // Note: Primary interval can be 0 for skip zones (valid configuration)
                // This is used in scales like Ch and P to skip tick generation in certain regions
            }
        }
    }
    
    // MARK: - Multi-Cycle Scale Safety
    
    @Test("Multi-cycle scales have appropriate range-to-cycle ratios")
    func multiCycleScalesHaveAppropriateRanges() throws {
        // These scales use multi-cycle functions (6-12 cycles)
        // They should NOT have ranges spanning multiple decades internally
        
        let multiCycleScales: [(String, ScaleDefinition, Int)] = [
            ("XL (12 cycles)", StandardScales.xlScale(), 12),
            ("Xc (12 cycles)", StandardScales.xcScale(), 12),
            ("F (12 cycles)", StandardScales.fScale(), 12),
            ("Lr (12 cycles)", StandardScales.n16esLrScale(), 12),
            ("Cr (12 cycles)", StandardScales.n16esCrScale(), 12),
            ("ω (12 cycles)", StandardScales.n16esOmegaScale(), 12),
            ("τ (12 cycles)", StandardScales.n16esTimeConstantScale(), 12),
            ("Z (6 cycles)", StandardScales.zScale(), 6),
            ("λ (6 cycles)", StandardScales.n16esWavelengthScale(), 6)
        ]
        
        for (name, scale, _) in multiCycleScales {
            // Calculate internal range span
            let rangeSpan = abs(scale.endValue - scale.beginValue)
            
            // Multi-cycle scales should have internal range of 1-2 decades max
            // This prevents the omega scale bug where 12-decade range with
            // single-decade subsections caused billions of ticks
            let maxDecadeSpan: Double = 1000 // 3 decades at most
            #expect(
                rangeSpan <= maxDecadeSpan,
                "Multi-cycle scale '\(name)' has excessive range span \(rangeSpan) - should use function cycles for domain coverage"
            )
        }
    }
    
    // MARK: - Stress Tests
    
    @Test("Scales at extreme lengths still generate reasonable ticks")
    func scalesAtExtremeLengthsGenerateReasonableTicks() throws {
        // Test with very large scale length (simulating large displays)
        let largeLength: Double = 2000.0
        
        // Sample of scales to test
        let sampleScales: [(String, (Double) -> ScaleDefinition)] = [
            ("C", StandardScales.cScale),
            ("K", StandardScales.kScale),
            ("LL3", StandardScales.ll3Scale),
            ("XL", StandardScales.xlScale),
            ("Lr", StandardScales.n16esLrScale)
        ]
        
        for (name, factory) in sampleScales {
            let scale = factory(largeLength)
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            
            #expect(
                ticks.count <= maxAcceptableTicks,
                "Scale '\(name)' at length \(largeLength) generated \(ticks.count) ticks"
            )
        }
    }
    
    @Test("Scales at minimum lengths generate ticks")
    func scalesAtMinimumLengthGenerateTicks() throws {
        // Test with very small scale length
        let smallLength: Double = 50.0
        
        let sampleScales: [(String, (Double) -> ScaleDefinition)] = [
            ("C", StandardScales.cScale),
            ("D", StandardScales.dScale),
            ("A", StandardScales.aScale)
        ]
        
        for (name, factory) in sampleScales {
            let scale = factory(smallLength)
            let ticks = ScaleCalculator.generateTickMarks(for: scale)
            
            #expect(
                ticks.count > 0,
                "Scale '\(name)' at minimum length \(smallLength) should still generate ticks"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Collects all available scale definitions for comprehensive testing
    private func collectAllScaleDefinitions() -> [(String, ScaleDefinition)] {
        var scales: [(String, ScaleDefinition)] = []
        
        // Standard scales
        scales.append(("C", StandardScales.cScale()))
        scales.append(("D", StandardScales.dScale()))
        scales.append(("CI", StandardScales.ciScale()))
        scales.append(("DI", StandardScales.diScale()))
        scales.append(("CF", StandardScales.cfScale()))
        scales.append(("DF", StandardScales.dfScale()))
        scales.append(("DFm", StandardScales.dfmScale()))
        scales.append(("CIF", StandardScales.cifScale()))
        scales.append(("DIF", StandardScales.difScale()))
        scales.append(("A", StandardScales.aScale()))
        scales.append(("B", StandardScales.bScale()))
        scales.append(("AI", StandardScales.aiScale()))
        scales.append(("BI", StandardScales.biScale()))
        scales.append(("K", StandardScales.kScale()))
        scales.append(("S", StandardScales.sScale()))
        scales.append(("T", StandardScales.tScale()))
        scales.append(("T1", StandardScales.t1Scale()))
        scales.append(("T2", StandardScales.t2Scale()))
        scales.append(("ST", StandardScales.stScale()))
        scales.append(("L", StandardScales.lScale()))
        scales.append(("Ln", StandardScales.lnScale()))
        scales.append(("KE-S", StandardScales.keSScale()))
        scales.append(("KE-T", StandardScales.keTScale()))
        scales.append(("KE-ST", StandardScales.keSTScale()))
        
        // Extended C/D scales
        scales.append(("C10-100", StandardScales.c10to100Scale()))
        scales.append(("C100-1000", StandardScales.c100to1000Scale()))
        scales.append(("D10-100", StandardScales.d10to100Scale()))
        
        // Aviation and time scales
        scales.append(("CAS", StandardScales.casScale()))
        scales.append(("TIME", StandardScales.timeScale()))
        scales.append(("TIME2", StandardScales.time2Scale()))
        scales.append(("CR3S", StandardScales.cr3sScale()))
        
        // Root scales
        scales.append(("R1", StandardScales.r1Scale()))
        scales.append(("R2", StandardScales.r2Scale()))
        scales.append(("Q1", StandardScales.q1Scale()))
        scales.append(("Q2", StandardScales.q2Scale()))
        scales.append(("Q3", StandardScales.q3Scale()))
        
        // Hyperbolic scales
        scales.append(("Ch", StandardScales.chScale()))
        scales.append(("Th", StandardScales.thScale()))
        scales.append(("Sh", StandardScales.shScale()))
        scales.append(("Sh1", StandardScales.sh1Scale()))
        scales.append(("Sh2", StandardScales.sh2Scale()))
        scales.append(("H1", StandardScales.h1Scale()))
        scales.append(("H2", StandardScales.h2Scale()))
        scales.append(("P", StandardScales.pScale()))
        scales.append(("PA", StandardScales.paScale()))
        scales.append(("L360", StandardScales.l360Scale()))
        scales.append(("L180", StandardScales.l180Scale()))
        
        // Log-Log scales
        scales.append(("LL0", StandardScales.ll0Scale()))
        scales.append(("LL1", StandardScales.ll1Scale()))
        scales.append(("LL2", StandardScales.ll2Scale()))
        scales.append(("LL3", StandardScales.ll3Scale()))
        scales.append(("LL00", StandardScales.ll00Scale()))
        scales.append(("LL01", StandardScales.ll01Scale()))
        scales.append(("LL02", StandardScales.ll02Scale()))
        scales.append(("LL03", StandardScales.ll03Scale()))
        scales.append(("H266LL01", StandardScales.h266LL01Scale()))
        scales.append(("H266LL03", StandardScales.h266LL03Scale()))
        scales.append(("LL02B", StandardScales.ll02BScale()))
        scales.append(("LL2B", StandardScales.ll2BScale_PostScriptAccurate()))
        
        // Electrical Engineering scales
        scales.append(("XL", StandardScales.xlScale()))
        scales.append(("Xc", StandardScales.xcScale()))
        scales.append(("F (EE)", StandardScales.fScale()))
        scales.append(("L (EE)", StandardScales.eeInductanceScale()))
        scales.append(("Li", StandardScales.eeInductanceInvertedScale()))
        scales.append(("Cf", StandardScales.eeCapacitanceFrequencyScale()))
        scales.append(("Cz", StandardScales.czScale()))
        scales.append(("Z", StandardScales.zScale()))
        scales.append(("Fo", StandardScales.foScale()))
        scales.append(("r1 (EE)", StandardScales.eeReflectionCoefficientScale()))
        scales.append(("r2 (EE)", StandardScales.eeReflectionCoefficient2Scale()))
        scales.append(("P (EE)", StandardScales.eePowerRatioScale()))
        scales.append(("Q (EE)", StandardScales.eePowerRatioInvertedScale()))
        
        // Pickett N-16 ES scales
        scales.append(("Lr", StandardScales.n16esLrScale()))
        scales.append(("Cr", StandardScales.n16esCrScale()))
        scales.append(("C/L", StandardScales.n16esClScale()))
        scales.append(("F (N16)", StandardScales.n16esFrequencyScale()))
        scales.append(("ω", StandardScales.n16esOmegaScale()))
        scales.append(("λ", StandardScales.n16esWavelengthScale()))
        scales.append(("Θ", StandardScales.n16esThetaScale()))
        scales.append(("cos Θ", StandardScales.n16esCosThetaScale()))
        scales.append(("dB Power", StandardScales.n16esDecibelPowerScale()))
        scales.append(("dB Voltage", StandardScales.n16esDecibelVoltageScale()))
        scales.append(("D/Q", StandardScales.n16esDecimalKeeperScale()))
        scales.append(("Q Factor", StandardScales.n16esQFactorScale()))
        scales.append(("τ", StandardScales.n16esTimeConstantScale()))
        
        return scales
    }
}

// MARK: - Regression Tests for Omega/Tau Bug

@Suite("Omega/Tau Regression Tests", .tags(.regression))
struct OmegaTauRegressionTests {
    
    @Test("Omega scale range is properly bounded (regression test for billion-tick bug)")
    func omegaScaleRangeBounded() throws {
        let omega = StandardScales.n16esOmegaScale()
        
        // The fix: range should be 1.0 to 100.0 (2 decades), NOT 0.001 to 1e9 (12 decades)
        let rangeSpan = abs(omega.endValue - omega.beginValue)
        
        // Range should be ~99 (100 - 1), not ~1e9
        #expect(rangeSpan < 1000, "Omega scale range should be bounded to prevent runaway tick generation")
        
        // Verify actual values
        #expect(omega.beginValue >= 1.0, "Omega scale should start at 1.0 or higher")
        #expect(omega.endValue <= 100.0, "Omega scale should end at 100.0 or lower")
    }
    
    @Test("Tau scale range is properly bounded (regression test for billion-tick bug)")
    func tauScaleRangeBounded() throws {
        let tau = StandardScales.n16esTimeConstantScale()
        
        // The fix: range should be 1.0 to 100.0 (2 decades), NOT 1e-9 to 1e3 (12 decades)
        let rangeSpan = abs(tau.endValue - tau.beginValue)
        
        // Range should be ~99 (100 - 1), not ~1e12
        #expect(rangeSpan < 1000, "Tau scale range should be bounded to prevent runaway tick generation")
        
        // Verify actual values
        #expect(tau.beginValue >= 1.0, "Tau scale should start at 1.0 or higher")
        #expect(tau.endValue <= 100.0, "Tau scale should end at 100.0 or lower")
    }
    
    @Test("ScaleCalculator defensive guard exists")
    func scaleCalculatorHasDefensiveGuard() throws {
        // This test verifies the defensive guard in ScaleCalculator exists
        // and would prevent runaway tick generation even if a scale is misconfigured
        
        // Create a purposely misconfigured scale to test the guard
        let badScale = ScaleBuilder()
            .withName("BadScale")
            .withFormula("test")
            .withFunction(LogarithmicFunction())
            .withRange(begin: 1.0, end: 1_000_000.0) // 6 decades, could generate many ticks
            .withLength(250.0)
            .withTickDirection(.up)
            .withSubsections([
                ScaleSubsection(
                    startValue: 1.0,
                    tickIntervals: [1.0, 0.1], // Very fine intervals over large range
                    labelLevels: [0]
                )
            ])
            .build()
        
        // This should not crash due to the defensive guard
        let ticks = ScaleCalculator.generateTickMarks(for: badScale)
        
        // Should either return empty (guard triggered) or reasonable count
        #expect(ticks.count < 100_000, "ScaleCalculator should guard against excessive tick generation")
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var safety: Self
    // Note: regression tag is already defined in TestTags+Local.swift
}