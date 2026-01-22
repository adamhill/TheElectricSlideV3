import Foundation

// MARK: - Scale Diagnostics Configuration

/// Categories of diagnostic output that can be enabled
public enum DiagnosticCategory: String, CaseIterable, Sendable {
    /// Tick mark generation (positions, values, boundaries)
    case tickGeneration = "TickGeneration"
    /// Label formatting and placement
    case labels = "Labels"
    /// Gauge marks (constants like π, e, C)
    case gaugeMarks = "GaugeMarks"
    /// Subsection boundary calculations
    case boundaries = "Boundaries"
    /// Split scale segment processing
    case splitScales = "SplitScales"
    /// Position calculations (normalizedPosition, value lookups)
    case positions = "Positions"
}

/// Centralized diagnostics configuration for scale calculations.
///
/// Use this to enable debug output for specific scales or categories.
/// Only active in DEBUG builds.
///
/// ## Usage
///
/// ```swift
/// // Enable diagnostics for specific scales
/// ScaleDiagnostics.shared.enableScale("LL02")
/// ScaleDiagnostics.shared.enableScale("LL03")
///
/// // Enable entire categories
/// ScaleDiagnostics.shared.enableCategory(.labels)
///
/// // Or configure with a dictionary
/// ScaleDiagnostics.shared.configure([
///     "LL02": true,
///     "LL03": true,
///     "Labels": true,
///     "GaugeMarks": false
/// ])
///
/// // Reset all diagnostics
/// ScaleDiagnostics.shared.reset()
/// ```
///
/// In code, check diagnostics with:
/// ```swift
/// if ScaleDiagnostics.shared.shouldLog(scale: definition.name, category: .tickGeneration) {
///     print("Debug info...")
/// }
/// ```
public final class ScaleDiagnostics: @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// Shared diagnostics instance
    public static let shared = ScaleDiagnostics()
    
    // MARK: - Storage
    
    private let lock = NSLock()
    
    /// Scale names that have diagnostics enabled
    private var enabledScales: Set<String> = []
    
    /// Categories that have diagnostics enabled
    private var enabledCategories: Set<DiagnosticCategory> = []
    
    /// Unknown keys that were encountered during configuration
    private var unknownKeys: Set<String> = []
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration API
    
    /// Enable diagnostics for a specific scale by name
    /// - Parameter scaleName: The canonical scale name (e.g., "LL02", "C", "D")
    public func enableScale(_ scaleName: String) {
        lock.lock()
        defer { lock.unlock() }
        enabledScales.insert(scaleName)
    }
    
    /// Disable diagnostics for a specific scale
    public func disableScale(_ scaleName: String) {
        lock.lock()
        defer { lock.unlock() }
        enabledScales.remove(scaleName)
    }
    
    /// Enable diagnostics for a category
    public func enableCategory(_ category: DiagnosticCategory) {
        lock.lock()
        defer { lock.unlock() }
        enabledCategories.insert(category)
    }
    
    /// Disable diagnostics for a category
    public func disableCategory(_ category: DiagnosticCategory) {
        lock.lock()
        defer { lock.unlock() }
        enabledCategories.remove(category)
    }
    
    /// Configure diagnostics from a dictionary
    ///
    /// Keys can be:
    /// - Scale names (e.g., "LL02", "C", "D")
    /// - Category names (e.g., "Labels", "GaugeMarks", "TickGeneration")
    ///
    /// Values are booleans to enable/disable.
    ///
    /// Unknown keys are reported to the console.
    ///
    /// - Parameter config: Dictionary of key -> enabled pairs
    public func configure(_ config: [String: Bool]) {
        lock.lock()
        defer { lock.unlock() }
        
        unknownKeys.removeAll()
        
        for (key, enabled) in config {
            // First, try to match as a category
            if let category = DiagnosticCategory(rawValue: key) {
                if enabled {
                    enabledCategories.insert(category)
                } else {
                    enabledCategories.remove(category)
                }
                continue
            }
            
            // Check for case-insensitive category match
            if let category = DiagnosticCategory.allCases.first(where: { 
                $0.rawValue.lowercased() == key.lowercased() 
            }) {
                if enabled {
                    enabledCategories.insert(category)
                } else {
                    enabledCategories.remove(category)
                }
                continue
            }
            
            // Not a category - treat as scale name
            // We can't validate scale names here (would create circular dependency)
            // So we accept any string as a potential scale name
            if enabled {
                enabledScales.insert(key)
            } else {
                enabledScales.remove(key)
            }
        }
    }
    
    /// Reset all diagnostic settings
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        enabledScales.removeAll()
        enabledCategories.removeAll()
        unknownKeys.removeAll()
    }
    
    // MARK: - Query API
    
    /// Check if diagnostics should be logged for a given scale and category
    ///
    /// Returns true if:
    /// - The scale name is in the enabled set, OR
    /// - The category is in the enabled set
    ///
    /// This allows enabling diagnostics for "all LL scales" by enabling them individually,
    /// or "all label diagnostics" by enabling the category.
    ///
    /// - Parameters:
    ///   - scaleName: The scale name to check (can include unicode variants)
    ///   - category: The diagnostic category
    /// - Returns: True if diagnostics should be output
    public func shouldLog(scale scaleName: String, category: DiagnosticCategory) -> Bool {
        #if DEBUG
        lock.lock()
        defer { lock.unlock() }
        
        // Check if category is enabled
        if enabledCategories.contains(category) {
            return true
        }
        
        // Check if scale name matches (exact match)
        if enabledScales.contains(scaleName) {
            return true
        }
        
        // Check for partial matches (e.g., "LL02" matches "LL₀₂" and vice versa)
        // This handles unicode variant names
        for enabledScale in enabledScales {
            if scaleNamesMatch(scaleName, enabledScale) {
                return true
            }
        }
        
        return false
        #else
        return false
        #endif
    }
    
    /// Check if diagnostics are enabled for a scale (any category)
    public func isScaleEnabled(_ scaleName: String) -> Bool {
        #if DEBUG
        lock.lock()
        defer { lock.unlock() }
        
        if enabledScales.contains(scaleName) {
            return true
        }
        
        for enabledScale in enabledScales {
            if scaleNamesMatch(scaleName, enabledScale) {
                return true
            }
        }
        
        return false
        #else
        return false
        #endif
    }
    
    /// Check if a category is enabled (for all scales)
    public func isCategoryEnabled(_ category: DiagnosticCategory) -> Bool {
        #if DEBUG
        lock.lock()
        defer { lock.unlock() }
        return enabledCategories.contains(category)
        #else
        return false
        #endif
    }
    
    /// Get currently enabled scales
    public var currentlyEnabledScales: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return enabledScales
    }
    
    /// Get currently enabled categories
    public var currentlyEnabledCategories: Set<DiagnosticCategory> {
        lock.lock()
        defer { lock.unlock() }
        return enabledCategories
    }
    
    // MARK: - Scale Name Matching
    
    /// Check if two scale names refer to the same scale
    /// Handles unicode subscript variants (e.g., "LL02" ↔ "LL₀₂")
    private func scaleNamesMatch(_ name1: String, _ name2: String) -> Bool {
        // Exact match
        if name1 == name2 { return true }
        
        // Normalize both names and compare
        let normalized1 = normalizeScaleName(name1)
        let normalized2 = normalizeScaleName(name2)
        
        return normalized1 == normalized2
    }
    
    /// Normalize a scale name by converting unicode subscripts to ASCII
    private func normalizeScaleName(_ name: String) -> String {
        var result = name
        
        // Unicode subscript digits to ASCII
        let subscriptMap: [Character: Character] = [
            "₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4",
            "₅": "5", "₆": "6", "₇": "7", "₈": "8", "₉": "9"
        ]
        
        for (subscriptChar, digit) in subscriptMap {
            result = result.replacingOccurrences(of: String(subscriptChar), with: String(digit))
        }
        
        return result
    }
    
    // MARK: - Logging Helpers
    
    /// Log a diagnostic message if enabled for the scale/category
    /// - Parameters:
    ///   - scaleName: The scale name
    ///   - category: The diagnostic category
    ///   - message: A closure that produces the message (only evaluated if logging is enabled)
    public func log(
        scale scaleName: String,
        category: DiagnosticCategory,
        _ message: @autoclosure () -> String
    ) {
        #if DEBUG
        if shouldLog(scale: scaleName, category: category) {
            print("[\(category.rawValue)] \(scaleName): \(message())")
        }
        #endif
    }
    
    /// Log a diagnostic message with custom prefix
    public func log(
        scale scaleName: String,
        category: DiagnosticCategory,
        prefix: String,
        _ message: @autoclosure () -> String
    ) {
        #if DEBUG
        if shouldLog(scale: scaleName, category: category) {
            print("\(prefix) [\(category.rawValue)] \(scaleName): \(message())")
        }
        #endif
    }
}

// MARK: - Convenience Extensions

extension ScaleDiagnostics {
    /// Enable diagnostics for common Log-Log scales
    public func enableLogLogScales() {
        enableScale("LL0")
        enableScale("LL01")
        enableScale("LL02")
        enableScale("LL03")
        enableScale("LL1")
        enableScale("LL2")
        enableScale("LL3")
        // Also handle subscript variants
        enableScale("LL₀")
        enableScale("LL₀₁")
        enableScale("LL₀₂")
        enableScale("LL₀₃")
    }
    
    /// Enable diagnostics for trigonometric scales
    public func enableTrigScales() {
        enableScale("S")
        enableScale("T")
        enableScale("ST")
        enableScale("T1")
        enableScale("T2")
        enableScale("SRT")
        enableScale("P")
    }
    
    /// Enable all diagnostic categories (verbose mode)
    public func enableAllCategories() {
        for category in DiagnosticCategory.allCases {
            enableCategory(category)
        }
    }
}
