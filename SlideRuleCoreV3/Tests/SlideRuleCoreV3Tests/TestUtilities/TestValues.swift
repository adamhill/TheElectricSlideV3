import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Common Test Value Sets

/// Standard test value collections used across multiple test suites
enum TestValues {
    /// Standard logarithmic scale test values (1-10 range)
    static let logarithmic = [1.0, 2.0, 3.14159, 5.0, 7.5, 10.0]
    
    /// Extended logarithmic test values (1-100 range)
    static let logarithmicExtended = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
    
    /// Square scale test values
    static let squared = [1.0, 3.1622776601683795, 10.0, 25.0, 64.0, 100.0]
    
    /// Folded scale test values  
    static let folded = [3.14159, 5.0, 10.0, 15.0, 20.0, 31.4159]
    
    /// Standard inverted scale test values
    static let inverted = [1.0, 2.0, 4.0, 5.0, 7.5, 10.0]
    
    /// Standard test positions across normalized range [0, 1]
    static let positions = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
}
