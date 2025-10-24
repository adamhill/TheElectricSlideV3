import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Test to check if modulo algorithm works with L scale
@Suite("L Scale Modulo Algorithm Test")
struct LScaleModuloAlgorithmTest {
    
    @Test("Compare legacy vs modulo algorithm for L scale")
    func testLegacyVsModulo() {
        let lScale = StandardScales.lScale(length: 800.0)
        
        print("\n=== L SCALE ALGORITHM COMPARISON ===")
        
        // Test with legacy algorithm
        let legacyTicks = ScaleCalculator.generateTickMarks(
            for: lScale,
            algorithm: .legacy
        )
        
        print("Legacy algorithm: \(legacyTicks.count) ticks")
        if legacyTicks.isEmpty {
            print("  ERROR: Legacy generated NO ticks!")
        } else {
            print("  First 5 ticks:")
            for tick in legacyTicks.prefix(5) {
                print("    value=\(tick.value), pos=\(tick.normalizedPosition)")
            }
        }
        
        // Test with modulo algorithm (what the app uses!)
        let moduloTicks = ScaleCalculator.generateTickMarks(
            for: lScale,
            algorithm: .modulo(config: ModuloTickConfig.default)
        )
        
        print("\nModulo algorithm: \(moduloTicks.count) ticks")
        if moduloTicks.isEmpty {
            print("  ERROR: Modulo generated NO ticks! THIS IS THE BUG!")
        } else {
            print("  First 5 ticks:")
            for tick in moduloTicks.prefix(5) {
                print("    value=\(tick.value), pos=\(tick.normalizedPosition)")
            }
        }
        
        print("\nDifference: \(legacyTicks.count - moduloTicks.count) ticks")
        print("=== END COMPARISON ===\n")
        
        #expect(moduloTicks.count > 0, "Modulo algorithm should generate ticks for L scale")
    }
}