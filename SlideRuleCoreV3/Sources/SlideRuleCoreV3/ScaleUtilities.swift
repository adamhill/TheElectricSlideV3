import Foundation

// MARK: - Async Scale Generation

/// Actor-based scale generator for concurrent scale generation with Swift 6 concurrency
@available(macOS 13.0, iOS 16.0, *)
public actor ConcurrentScaleGenerator: Sendable {
    
    /// Public initializer
    public init() {}
    
    /// Generate multiple scales concurrently
    /// - Parameter definitions: Array of scale definitions to generate
    /// - Returns: Array of generated scales in the same order as definitions
    public func generateScales(_ definitions: [ScaleDefinition]) async -> [GeneratedScale] {
        await withTaskGroup(of: (Int, GeneratedScale).self) { group in
            // Submit all scale generation tasks
            for (index, definition) in definitions.enumerated() {
                group.addTask {
                    let generated = GeneratedScale(definition: definition)
                    return (index, generated)
                }
            }
            
            // Collect results maintaining original order
            var results: [(Int, GeneratedScale)] = []
            for await result in group {
                results.append(result)
            }
            
            // Sort by original index and extract scales
            return results
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }
    
    /// Generate a complete slide rule concurrently
    /// - Parameter definition: Rule definition string
    /// - Parameter dimensions: Component dimensions
    /// - Parameter scaleLength: Length of scales
    /// - Returns: Fully generated slide rule
    public func generateRule(
        _ definition: String,
        dimensions: RuleDefinitionParser.Dimensions,
        scaleLength: Distance = 250.0
    ) async throws -> SlideRule {
        try RuleDefinitionParser.parse(
            definition,
            dimensions: dimensions,
            scaleLength: scaleLength
        )
    }
}

// MARK: - Scale Interpolation

/// Utilities for interpolating between tick marks
public enum ScaleInterpolation {
    
    /// Find the value at a given normalized position using interpolation
    /// - Parameters:
    ///   - position: Normalized position (0.0 to 1.0)
    ///   - scale: The generated scale
    /// - Returns: Interpolated value
    public static func interpolateValue(
        at position: NormalizedPosition,
        in scale: GeneratedScale
    ) -> ScaleValue {
        ScaleCalculator.value(at: position, on: scale.definition)
    }
    
    /// Find the nearest labeled tick to a position
    /// - Parameters:
    ///   - position: Normalized position
    ///   - scale: The generated scale
    /// - Returns: Nearest tick mark with a label
    public static func nearestLabeledTick(
        to position: NormalizedPosition,
        in scale: GeneratedScale
    ) -> TickMark? {
        scale.tickMarks
            .filter { $0.label != nil }
            .min { tick1, tick2 in
                abs(tick1.normalizedPosition - position) < abs(tick2.normalizedPosition - position)
            }
    }
    
    /// Find all major divisions in a scale
    /// - Parameter scale: The generated scale
    /// - Returns: Array of major tick marks
    public static func majorDivisions(in scale: GeneratedScale) -> [TickMark] {
        scale.tickMarks.filter { $0.style.relativeLength >= 0.9 }
    }
}

// MARK: - Scale Validation

/// Validates scale definitions for mathematical correctness
public enum ScaleValidator {
    
    public enum ValidationError: Error, CustomStringConvertible {
        case invalidRange(String)
        case invalidFunction(String)
        case emptySubsections
        case overlappingSubsections
        
        public var description: String {
            switch self {
            case .invalidRange(let msg): return "Invalid range: \(msg)"
            case .invalidFunction(let msg): return "Invalid function: \(msg)"
            case .emptySubsections: return "Scale must have at least one subsection"
            case .overlappingSubsections: return "Subsections have overlapping ranges"
            }
        }
    }
    
    /// Validate a scale definition
    /// - Parameter definition: The scale definition to validate
    /// - Throws: ValidationError if the definition is invalid
    public static func validate(_ definition: ScaleDefinition) throws {
        // Check range validity
        guard definition.beginValue.isFinite && definition.endValue.isFinite else {
            throw ValidationError.invalidRange("Begin and end values must be finite")
        }
        
        guard definition.beginValue != definition.endValue else {
            throw ValidationError.invalidRange("Begin and end values cannot be equal")
        }
        
        // Check function validity for the range
        let testValues = [definition.beginValue, definition.endValue]
        for value in testValues {
            let transformed = definition.function.transform(value)
            guard transformed.isFinite else {
                throw ValidationError.invalidFunction("Function produces non-finite values for range")
            }
            
            let inverted = definition.function.inverseTransform(transformed)
            let error = abs(inverted - value) / value
            guard error < 0.01 else {
                throw ValidationError.invalidFunction("Function and inverse don't round-trip correctly")
            }
        }
        
        // Check subsections
        if definition.subsections.isEmpty {
            throw ValidationError.emptySubsections
        }
        
        // Check for overlapping subsections (basic check)
        let sortedStarts = definition.subsections.map { $0.startValue }.sorted()
        for i in 0..<(sortedStarts.count - 1) {
            if sortedStarts[i] == sortedStarts[i + 1] {
                throw ValidationError.overlappingSubsections
            }
        }
    }
    
    /// Validate all scales in a slide rule
    /// - Parameter rule: The slide rule to validate
    /// - Returns: Array of validation errors (empty if all valid)
    public static func validateRule(_ rule: SlideRule) -> [(String, ValidationError)] {
        var errors: [(String, ValidationError)] = []
        
        func validateScales(_ scales: [GeneratedScale], prefix: String) {
            for (index, scale) in scales.enumerated() {
                do {
                    try validate(scale.definition)
                } catch let error as ValidationError {
                    errors.append(("\(prefix) scale \(index) (\(scale.definition.name))", error))
                } catch {
                    // Unexpected error type
                }
            }
        }
        
        validateScales(rule.frontTopStator.scales, prefix: "Front top")
        validateScales(rule.frontSlide.scales, prefix: "Front slide")
        validateScales(rule.frontBottomStator.scales, prefix: "Front bottom")
        
        if let backTop = rule.backTopStator {
            validateScales(backTop.scales, prefix: "Back top")
        }
        if let backSlide = rule.backSlide {
            validateScales(backSlide.scales, prefix: "Back slide")
        }
        if let backBottom = rule.backBottomStator {
            validateScales(backBottom.scales, prefix: "Back bottom")
        }
        
        return errors
    }
}

// MARK: - Scale Analysis

/// Provides analytical information about scales
public enum ScaleAnalysis {
    
    /// Statistical information about a scale
    public struct ScaleStatistics: Sendable {
        public let totalTicks: Int
        public let majorTicks: Int
        public let mediumTicks: Int
        public let minorTicks: Int
        public let tinyTicks: Int
        public let labeledTicks: Int
        public let valueRange: (min: ScaleValue, max: ScaleValue)
        public let averageTickSpacing: NormalizedPosition
        
        public init(scale: GeneratedScale) {
            self.totalTicks = scale.tickMarks.count
            self.majorTicks = scale.tickMarks.filter { $0.style.relativeLength >= 0.9 }.count
            self.mediumTicks = scale.tickMarks.filter { $0.style.relativeLength >= 0.7 && $0.style.relativeLength < 0.9 }.count
            self.minorTicks = scale.tickMarks.filter { $0.style.relativeLength >= 0.4 && $0.style.relativeLength < 0.7 }.count
            self.tinyTicks = scale.tickMarks.filter { $0.style.relativeLength < 0.4 }.count
            self.labeledTicks = scale.tickMarks.filter { $0.label != nil }.count
            
            let values = scale.tickMarks.map { $0.value }
            self.valueRange = (min: values.min() ?? 0, max: values.max() ?? 0)
            
            if scale.tickMarks.count > 1 {
                let positions = scale.tickMarks.map { $0.normalizedPosition }.sorted()
                var totalSpacing = 0.0
                for i in 0..<(positions.count - 1) {
                    totalSpacing += positions[i + 1] - positions[i]
                }
                self.averageTickSpacing = totalSpacing / Double(positions.count - 1)
            } else {
                self.averageTickSpacing = 0
            }
        }
    }
    
    /// Compute density of tick marks in different regions of the scale
    /// - Parameters:
    ///   - scale: The generated scale
    ///   - regions: Number of regions to divide the scale into
    /// - Returns: Array of tick densities (ticks per normalized unit) for each region
    public static func tickDensity(
        in scale: GeneratedScale,
        regions: Int = 10
    ) -> [Double] {
        let regionSize = 1.0 / Double(regions)
        var densities: [Double] = Array(repeating: 0, count: regions)
        
        for tick in scale.tickMarks {
            let region = min(Int(tick.normalizedPosition / regionSize), regions - 1)
            densities[region] += 1
        }
        
        // Normalize by region size
        return densities.map { $0 / regionSize }
    }
    
    /// Find the region with the highest tick density
    /// - Parameter scale: The generated scale
    /// - Returns: (region start position, region end position, density)
    public static func highestDensityRegion(
        in scale: GeneratedScale,
        regionCount: Int = 10
    ) -> (start: NormalizedPosition, end: NormalizedPosition, density: Double)? {
        let densities = tickDensity(in: scale, regions: regionCount)
        guard let maxDensity = densities.max(),
              let maxIndex = densities.firstIndex(of: maxDensity) else {
            return nil
        }
        
        let regionSize = 1.0 / Double(regionCount)
        return (
            start: Double(maxIndex) * regionSize,
            end: Double(maxIndex + 1) * regionSize,
            density: maxDensity
        )
    }
}

// MARK: - Export Utilities

/// Utilities for exporting scale data in various formats
public enum ScaleExporter {
    
    /// Export tick marks as CSV
    /// - Parameter scale: The generated scale
    /// - Returns: CSV string with columns: value, position, tickLength, label
    public static func toCSV(_ scale: GeneratedScale) -> String {
        var csv = "value,normalizedPosition,absolutePosition,tickLength,label\n"
        
        for tick in scale.tickMarks {
            let absolutePos = tick.normalizedPosition * scale.definition.scaleLengthInPoints
            let label = tick.label?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(tick.value),\(tick.normalizedPosition),\(absolutePos),\(tick.style.relativeLength),\(label)\n"
        }
        
        return csv
    }
    
    /// Export scale definition as JSON
    /// - Parameter scale: The generated scale
    /// - Returns: JSON string representation
    public static func toJSON(_ scale: GeneratedScale) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let exportData = ScaleExportData(scale: scale)
        let jsonData = try encoder.encode(exportData)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
    
    private struct ScaleExportData: Codable {
        let name: String
        let functionName: String
        let beginValue: Double
        let endValue: Double
        let scaleLengthInPoints: Double
        let tickDirection: String
        let tickMarks: [TickMarkData]
        
        struct TickMarkData: Codable {
            let value: Double
            let normalizedPosition: Double
            let absolutePosition: Double
            let tickLength: Double
            let label: String?
        }
        
        init(scale: GeneratedScale) {
            self.name = String(scale.definition.name.characters)
            self.functionName = String(scale.definition.function.name)
            self.beginValue = scale.definition.beginValue
            self.endValue = scale.definition.endValue
            self.scaleLengthInPoints = scale.definition.scaleLengthInPoints
            self.tickDirection = scale.definition.tickDirection == .up ? "up" : "down"
            self.tickMarks = scale.tickMarks.map { tick in
                TickMarkData(
                    value: tick.value,
                    normalizedPosition: tick.normalizedPosition,
                    absolutePosition: tick.normalizedPosition * scale.definition.scaleLengthInPoints,
                    tickLength: tick.style.relativeLength,
                    label: tick.label
                )
            }
        }
    }
}
