import Foundation
import Testing
@testable import SlideRuleCoreV3

// MARK: - ω and τ Scale Alignment Tests
// Based on REAL Pickett N16-ES measurements: τ = 1/ω at every position

@Suite("ω and τ Scale Alignment - Real Pickett N16-ES", .tags(.pickettN16ES))
struct OmegaTauAlignmentTests {
    
    /// Get the actual ω scale definition
    var omegaScale: ScaleDefinition {
        StandardScales.angularFrequencyOmegaScale(length: 250.0)
    }
    
    /// Get the actual τ scale definition
    var tauScale: ScaleDefinition {
        StandardScales.timeConstantTauScale(length: 250.0)
    }
    
    // MARK: - Required Alignments from REAL Pickett N16-ES
    // These alignments are NON-NEGOTIABLE - they were measured from a real slide rule
    
    @Test("ω=1 must align with τ=1")
    func testOmega1AlignsTau1() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        let omegaPos = ScaleCalculator.normalizedPosition(for: 1.0, on: omega)
        let tauPos = ScaleCalculator.normalizedPosition(for: 1.0, on: tau)
        
        print("ω=1 position: \(omegaPos)")
        print("τ=1 position: \(tauPos)")
        print("Difference: \(abs(omegaPos - tauPos))")
        
        let tolerance = 0.001  // 0.1% tolerance (very tight for labeled tick marks)
        #expect(abs(omegaPos - tauPos) < tolerance,
               "ω=1 must align with τ=1 (REAL Pickett N16-ES requirement)")
    }
    
    @Test("ω=2 must align with τ=0.5")
    func testOmega2AlignsTau05() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        let omegaPos = ScaleCalculator.normalizedPosition(for: 2.0, on: omega)
        let tauPos = ScaleCalculator.normalizedPosition(for: 0.5, on: tau)
        
        print("ω=2 position: \(omegaPos)")
        print("τ=0.5 position: \(tauPos)")
        print("Difference: \(abs(omegaPos - tauPos))")
        
        let tolerance = 0.001
        #expect(abs(omegaPos - tauPos) < tolerance,
               "ω=2 must align with τ=0.5 (REAL Pickett N16-ES requirement)")
    }
    
    @Test("ω=5 must align with τ=0.2")
    func testOmega5AlignsTau02() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        let omegaPos = ScaleCalculator.normalizedPosition(for: 5.0, on: omega)
        let tauPos = ScaleCalculator.normalizedPosition(for: 0.2, on: tau)
        
        print("ω=5 position: \(omegaPos)")
        print("τ=0.2 position: \(tauPos)")
        print("Difference: \(abs(omegaPos - tauPos))")
        
        let tolerance = 0.001
        #expect(abs(omegaPos - tauPos) < tolerance,
               "ω=5 must align with τ=0.2 (REAL Pickett N16-ES requirement)")
    }
    
    @Test("ω=10 must align with τ=0.1")
    func testOmega10AlignsTau01() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        let omegaPos = ScaleCalculator.normalizedPosition(for: 10.0, on: omega)
        let tauPos = ScaleCalculator.normalizedPosition(for: 0.1, on: tau)
        
        print("ω=10 position: \(omegaPos)")
        print("τ=0.1 position: \(tauPos)")
        print("Difference: \(abs(omegaPos - tauPos))")
        
        let tolerance = 0.001
        #expect(abs(omegaPos - tauPos) < tolerance,
               "ω=10 must align with τ=0.1 (REAL Pickett N16-ES requirement)")
    }
    
    @Test("ω=20 must align with τ=0.05")
    func testOmega20AlignsTau005() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        let omegaPos = ScaleCalculator.normalizedPosition(for: 20.0, on: omega)
        let tauPos = ScaleCalculator.normalizedPosition(for: 0.05, on: tau)
        
        print("ω=20 position: \(omegaPos)")
        print("τ=0.05 position: \(tauPos)")
        print("Difference: \(abs(omegaPos - tauPos))")
        
        let tolerance = 0.001
        #expect(abs(omegaPos - tauPos) < tolerance,
               "ω=20 must align with τ=0.05 (REAL Pickett N16-ES requirement)")
    }
    
    @Test("ω=50 must align with τ=0.02")
    func testOmega50AlignsTau002() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        let omegaPos = ScaleCalculator.normalizedPosition(for: 50.0, on: omega)
        let tauPos = ScaleCalculator.normalizedPosition(for: 0.02, on: tau)
        
        print("ω=50 position: \(omegaPos)")
        print("τ=0.02 position: \(tauPos)")
        print("Difference: \(abs(omegaPos - tauPos))")
        
        let tolerance = 0.001
        #expect(abs(omegaPos - tauPos) < tolerance,
               "ω=50 must align with τ=0.02 (REAL Pickett N16-ES requirement)")
    }
    
    // MARK: - All Required Alignments in One Test
    
    @Test("ALL ω×τ=1 alignments must hold (MASTER TEST)")
    func testAllOmegaTauAlignments() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        // All required alignments from REAL Pickett N16-ES
        let requiredAlignments: [(omega: Double, tau: Double)] = [
            (1.0, 1.0),
            (2.0, 0.5),
            (5.0, 0.2),
            (10.0, 0.1),
            (20.0, 0.05),
            (50.0, 0.02)
        ]
        
        let tolerance = 0.001  // 0.1% tolerance for labeled tick marks
        var failures: [(omega: Double, tau: Double, omegaPos: Double, tauPos: Double, diff: Double)] = []
        
        print("\n" + String(repeating: "=", count: 70))
        print("ω and τ ALIGNMENT VERIFICATION (REAL Pickett N16-ES)")
        print(String(repeating: "=", count: 70))
        
        for (omegaVal, tauVal) in requiredAlignments {
            let omegaPos = ScaleCalculator.normalizedPosition(for: omegaVal, on: omega)
            let tauPos = ScaleCalculator.normalizedPosition(for: tauVal, on: tau)
            let diff = abs(omegaPos - tauPos)
            
            let status = diff < tolerance ? "✓" : "✗"
            print("\(status) ω=\(String(format: "%4.0f", omegaVal)) @ pos \(String(format: "%.4f", omegaPos)) | τ=\(String(format: "%.2f", tauVal)) @ pos \(String(format: "%.4f", tauPos)) | diff=\(String(format: "%.6f", diff))")
            
            if diff >= tolerance {
                failures.append((omegaVal, tauVal, omegaPos, tauPos, diff))
            }
        }
        
        print(String(repeating: "=", count: 70))
        
        if !failures.isEmpty {
            print("\nFAILURES:")
            for failure in failures {
                print("  ω=\(failure.omega) should align with τ=\(failure.tau)")
                print("    ω position: \(failure.omegaPos)")
                print("    τ position: \(failure.tauPos)")
                print("    difference: \(failure.diff) (tolerance: \(tolerance))")
            }
        }
        
        #expect(failures.isEmpty, "All ω×τ=1 alignments must hold")
    }
    
    // MARK: - Mathematical Relationship Verification
    
    @Test("τ = 1/ω relationship holds across entire scale")
    func testReciprocalRelationshipAcrossScale() async throws {
        let omega = omegaScale
        let tau = tauScale
        
        // Test at many positions across the scale
        let testPositions = stride(from: 0.05, through: 0.95, by: 0.05)
        let tolerance = 0.01  // 1% tolerance for intermediate positions
        
        print("\n" + String(repeating: "=", count: 80))
        print("τ = 1/ω RELATIONSHIP ACROSS SCALE")
        print(String(repeating: "=", count: 80))
        
        var maxError: Double = 0
        
        for pos in testPositions {
            let omegaVal = ScaleCalculator.value(at: pos, on: omega)
            let tauVal = ScaleCalculator.value(at: pos, on: tau)
            
            // At the same position, ω × τ should equal 1
            let product = omegaVal * tauVal
            let error = abs(product - 1.0)
            maxError = max(maxError, error)
            
            let status = error < tolerance ? "✓" : "✗"
            print("\(status) pos=\(String(format: "%.2f", pos)): ω=\(String(format: "%8.4f", omegaVal)), τ=\(String(format: "%8.4f", tauVal)), ω×τ=\(String(format: "%.6f", product))")
        }
        
        print(String(repeating: "=", count: 80))
        print("Max error from ω×τ=1: \(maxError)")
        
        #expect(maxError < tolerance, "ω × τ should equal 1 at every position")
    }
    
    // MARK: - Current State Diagnostic Tests
    
    @Test("DIAGNOSTIC: Current ω scale positions")
    func testCurrentOmegaPositions() async throws {
        let omega = omegaScale
        
        print("\n" + String(repeating: "=", count: 50))
        print("CURRENT ω SCALE POSITIONS")
        print(String(repeating: "=", count: 50))
        print("Scale range: begin=\(omega.beginValue), end=\(omega.endValue)")
        print("Transform function: \(omega.function.name)")
        
        let testValues: [Double] = [0.5, 0.7, 0.8, 0.9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 60]
        
        for val in testValues {
            let pos = ScaleCalculator.normalizedPosition(for: val, on: omega)
            print("ω=\(String(format: "%5.1f", val)) → position \(String(format: "%.4f", pos))")
        }
        print(String(repeating: "=", count: 50))
    }
    
    @Test("DIAGNOSTIC: Current τ scale positions")
    func testCurrentTauPositions() async throws {
        let tau = tauScale
        
        print("\n" + String(repeating: "=", count: 50))
        print("CURRENT τ SCALE POSITIONS")
        print(String(repeating: "=", count: 50))
        print("Scale range: begin=\(tau.beginValue), end=\(tau.endValue)")
        print("Transform function: \(tau.function.name)")
        
        // Values corresponding to ω values via τ = 1/ω
        let testValues: [Double] = [2.0, 1.4, 1.25, 1.1, 1, 0.5, 0.33, 0.25, 0.2, 0.167, 0.143, 0.125, 0.111, 0.1, 0.05, 0.033, 0.025, 0.02, 0.0167]
        
        for val in testValues {
            let pos = ScaleCalculator.normalizedPosition(for: val, on: tau)
            print("τ=\(String(format: "%6.4f", val)) → position \(String(format: "%.4f", pos))")
        }
        print(String(repeating: "=", count: 50))
    }
    
    // MARK: - Transform Function Tests
    
    @Test("TimeConstantFunction transform roundtrip")
    func testTimeConstantTransformRoundtrip() async throws {
        let function = TimeConstantFunction(cycles: 12)
        
        let testValues = [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0]
        
        for value in testValues {
            let transformed = function.transform(value)
            let inverted = function.inverseTransform(transformed)
            
            let error = abs(inverted - value) / value
            #expect(error < 0.0001,
                   "Roundtrip error for τ=\(value) should be < 0.01%, got \(error * 100)%")
        }
    }
    
    @Test("TimeConstantFunction reciprocal relationship with AngularFrequencyOmegaFunction")
    func testReciprocalTransformRelationship() async throws {
        let omegaFunc = AngularFrequencyOmegaFunction(cycles: 12)
        let tauFunc = TimeConstantFunction(cycles: 12)
        
        // For τ = 1/ω relationship:
        // transform_omega(ω) should equal transform_tau(1/ω)
        // Or equivalently: transform_omega(ω) + transform_tau(τ) = 0 when ω×τ = 1
        
        let testPairs: [(omega: Double, tau: Double)] = [
            (1.0, 1.0),
            (2.0, 0.5),
            (5.0, 0.2),
            (10.0, 0.1),
            (20.0, 0.05),
            (50.0, 0.02)
        ]
        
        print("\n" + String(repeating: "=", count: 70))
        print("TRANSFORM FUNCTION RELATIONSHIP: τ = 1/ω")
        print(String(repeating: "=", count: 70))
        
        for (omegaVal, tauVal) in testPairs {
            let omegaTrans = omegaFunc.transform(omegaVal)
            let tauTrans = tauFunc.transform(tauVal)
            
            // For reciprocal relationship: log(ω)/12 should equal -log(τ)/12
            // So omegaTrans + tauTrans should equal 0
            let sum = omegaTrans + tauTrans
            
            print("ω=\(String(format: "%4.0f", omegaVal)): transform=\(String(format: "%+.6f", omegaTrans))")
            print("τ=\(String(format: "%4.2f", tauVal)): transform=\(String(format: "%+.6f", tauTrans))")
            print("Sum (should be 0): \(String(format: "%+.10f", sum))")
            print("")
            
            #expect(abs(sum) < 1e-10,
                   "transform_ω(\(omegaVal)) + transform_τ(\(tauVal)) should equal 0")
        }
    }
}