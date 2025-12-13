import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Test Tolerance Constants

/// Standard tolerance constants used across test suites
enum TestTolerance {
    /// Standard tolerance for most scale calculations (0.01 = 1%)
    static let standard = 0.01
    
    /// Relaxed tolerance for complex calculations (0.05 = 5%)
    static let relaxed = 0.05
    
    /// Strict tolerance for high-precision requirements (0.001 = 0.1%)
    static let strict = 0.001
    
    /// Tolerance for EE scales which may have lower precision
    static let eeScale = 0.05
    
    /// Very relaxed tolerance for sampling/approximate values (0.1 = 10%)
    static let veryRelaxed = 0.1
}
