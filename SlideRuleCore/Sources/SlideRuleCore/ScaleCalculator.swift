import Foundation

// MARK: - Scale Calculator

/// Calculates positions and generates tick marks for slide rule scales
/// Based on the mathematical principle: d(x) = m * (f(x) - f(x_L)) / (f(x_R) - f(x_L))
///
/// where m is scale length, f is the scale function, x_L is left value, x_R is right value
/// 
/// For linear scales: d(x) is distance in points
/// For circular scales: d(x) is angular position (normalized × 360°)
/// 
/// The same formula works for both! The difference is only in how we interpret the result.

public struct ScaleCalculator: Sendable {
    
    // MARK: - Position Calculation
    
    /// Calculate the normalized position (0.0 to 1.0) for a value on a scale
    /// - Parameters:
    ///   - value: The value to locate on the scale
    ///   - definition: The scale definition
    /// - Returns: Normalized position from 0.0 (left/start) to 1.0 (right/end)
    public static func normalizedPosition(
        for value: ScaleValue,
        on definition: ScaleDefinition
    ) -> NormalizedPosition {
        let function = definition.function
        let xL = definition.beginValue
        let xR = definition.endValue
        
        // Handle the case where the function values are reversed
        let fL = function.transform(xL)
        let fR = function.transform(xR)
        let fx = function.transform(value)
        
        // Normalized position formula from mathematical foundations
        // This works for BOTH linear and circular scales!
        let normalizedPosition = (fx - fL) / (fR - fL)
        
        return normalizedPosition
    }
    
    /// Calculate the absolute distance in points for a value on a linear scale
    /// - Parameters:
    ///   - value: The value to locate on the scale
    ///   - definition: The scale definition
    /// - Returns: Distance in points from the start of the scale
    public static func absolutePosition(
        for value: ScaleValue,
        on definition: ScaleDefinition
    ) -> Distance {
        let normalized = normalizedPosition(for: value, on: definition)
        return normalized * definition.scaleLengthInPoints
    }
    
    /// Calculate the angular position in degrees for a value on a circular scale
    /// - Parameters:
    ///   - value: The value to locate on the scale
    ///   - definition: The scale definition (must be circular)
    /// - Returns: Angular position from 0° to 360°
    public static func angularPosition(
        for value: ScaleValue,
        on definition: ScaleDefinition
    ) -> AngularPosition {
        guard definition.isCircular else {
            fatalError("angularPosition called on non-circular scale")
        }
        
        let normalized = normalizedPosition(for: value, on: definition)
        // Convert normalized 0-1 to angular 0-360°
        // Note: In PostScript engine, it uses (360 - angle) for rotation
        // but for position calculation we use angle directly
        return normalized * 360.0
    }
    
    /// Calculate the value at a given normalized position
    /// - Parameters:
    ///   - position: Normalized position (0.0 to 1.0)
    ///   - definition: The scale definition
    /// - Returns: The value at that position
    public static func value(
        at position: NormalizedPosition,
        on definition: ScaleDefinition
    ) -> ScaleValue {
        let function = definition.function
        let xL = definition.beginValue
        let xR = definition.endValue
        
        let fL = function.transform(xL)
        let fR = function.transform(xR)
        
        // Inverse calculation: fx = fL + position * (fR - fL)
        let fx = fL + position * (fR - fL)
        
        return function.inverseTransform(fx)
    }
    
    /// Calculate the value at a given angular position on a circular scale
    /// - Parameters:
    ///   - angle: Angular position (0° to 360°)
    ///   - definition: The scale definition (must be circular)
    /// - Returns: The value at that angle
    public static func value(
        atAngle angle: AngularPosition,
        on definition: ScaleDefinition
    ) -> ScaleValue {
        guard definition.isCircular else {
            fatalError("value(atAngle:) called on non-circular scale")
        }
        
        // Convert angle to normalized position
        let normalized = angle / 360.0
        return value(at: normalized, on: definition)
    }
    
    // MARK: - Tick Mark Generation
    
    /// Generate all tick marks for a scale definition
    /// - Parameter definition: The scale definition
    /// - Returns: Array of all tick marks sorted by position
    public static func generateTickMarks(
        for definition: ScaleDefinition
    ) -> [TickMark] {
        var allTicks: [TickMark] = []
        
        // Generate ticks for each subsection
        for subsection in definition.subsections {
            let ticks = generateTickMarks(
                for: subsection,
                on: definition
            )
            allTicks.append(contentsOf: ticks)
        }
        
        // Add constant markers
        for constant in definition.constants {
            let position = normalizedPosition(for: constant.value, on: definition)
            let angularPos = definition.isCircular ? position * 360.0 : nil
            
            let tick = TickMark(
                value: constant.value,
                normalizedPosition: position,
                angularPosition: angularPos,
                style: constant.style,
                label: constant.label
            )
            allTicks.append(tick)
        }
        
        // Sort by position and remove duplicates
        allTicks.sort { $0.normalizedPosition < $1.normalizedPosition }
        allTicks = removeDuplicates(from: allTicks, isCircular: definition.isCircular)
        
        return allTicks
    }
    
    /// Generate tick marks for a specific subsection
    private static func generateTickMarks(
        for subsection: ScaleSubsection,
        on definition: ScaleDefinition
    ) -> [TickMark] {
        var ticks: [TickMark] = []
        let endValue = definition.endValue
        let beginValue = definition.beginValue
        
        // Process each level of tick intervals
        for (level, interval) in subsection.tickIntervals.enumerated() {
            guard interval > 0 else { continue }
            
            // Determine which style to use for this level
            let styleIndex = min(level, definition.defaultTickStyles.count - 1)
            let style = definition.defaultTickStyles[styleIndex]
            
            // Should this level have labels?
            let shouldLabel = subsection.labelLevels.contains(level) || style.shouldLabel
            
            // Generate ticks at this interval
            var currentValue = subsection.startValue
            
            while currentValue <= endValue {
                // Check if this value is within the scale range
                if currentValue >= beginValue && currentValue <= endValue {
                    
                    // For circular scales, skip the last tick if it overlaps with the first
                    // This prevents duplicate tick at 0°/360°
                    if definition.isCircular {
                        let isLastTick = abs(currentValue - endValue) < interval * 0.01
                        let coversFullCircle = definition.function.transform(beginValue) - 
                                              definition.function.transform(endValue) >= 0.999
                        
                        if isLastTick && coversFullCircle {
                            // Skip this tick - it would overlap with 0°
                            currentValue += interval
                            continue
                        }
                    }
                    
                    let position = normalizedPosition(for: currentValue, on: definition)
                    let angularPos = definition.isCircular ? position * 360.0 : nil
                    
                    // Format the label
                    let label: String? = if shouldLabel {
                        formatLabel(
                            value: currentValue,
                            subsectionFormatter: subsection.labelFormatter,
                            scaleFormatter: definition.labelFormatter
                        )
                    } else {
                        nil
                    }
                    
                    let tick = TickMark(
                        value: currentValue,
                        normalizedPosition: position,
                        angularPosition: angularPos,
                        style: style,
                        label: label
                    )
                    
                    ticks.append(tick)
                }
                
                currentValue += interval
                
                // Safety check to prevent infinite loops
                if interval < 1e-10 {
                    break
                }
            }
        }
        
        return ticks
    }
    
    // MARK: - Label Formatting
    
    /// Format a label using the appropriate formatter
    private static func formatLabel(
        value: ScaleValue,
        subsectionFormatter: (@Sendable (ScaleValue) -> String)?,
        scaleFormatter: (@Sendable (ScaleValue) -> String)?
    ) -> String {
        // Prefer subsection formatter, fall back to scale formatter, then default
        if let formatter = subsectionFormatter {
            return formatter(value)
        } else if let formatter = scaleFormatter {
            return formatter(value)
        } else {
            return defaultLabelFormat(value)
        }
    }
    
    /// Default label formatting
    private static func defaultLabelFormat(_ value: ScaleValue) -> String {
        // Smart formatting based on magnitude
        if abs(value) < 0.01 {
            return String(format: "%.4f", value)
        } else if abs(value) < 1 {
            return String(format: "%.3f", value)
        } else if abs(value) < 10 {
            return String(format: "%.2f", value)
        } else if abs(value) < 100 {
            return String(format: "%.1f", value)
        } else if abs(value - value.rounded()) < 0.01 {
            return String(Int(value.rounded()))
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Remove duplicate tick marks that are too close together
    private static func removeDuplicates(from ticks: [TickMark], isCircular: Bool) -> [TickMark] {
        var result: [TickMark] = []
        let minSeparation = 0.001 // Minimum normalized distance between ticks
        
        for tick in ticks {
            // Check if this tick is too close to the last one
            if let lastTick = result.last {
                let distance = abs(tick.normalizedPosition - lastTick.normalizedPosition)
                
                if distance < minSeparation {
                    // Keep the one with the larger tick (more important)
                    if tick.style.relativeLength > lastTick.style.relativeLength {
                        result.removeLast()
                        result.append(tick)
                    }
                    continue
                }
            }
            
            result.append(tick)
        }
        
        // For circular scales, check if the first and last ticks are too close
        // (wrapping around the circle)
        if isCircular && result.count > 1 {
            if let firstTick = result.first, let lastTick = result.last {
                // Calculate wrap-around distance
                let wrapDistance = 1.0 - lastTick.normalizedPosition + firstTick.normalizedPosition
                
                if wrapDistance < minSeparation * 2 {
                    // Remove the less important one
                    if lastTick.style.relativeLength > firstTick.style.relativeLength {
                        result.removeFirst()
                    } else {
                        result.removeLast()
                    }
                }
            }
        }
        
        return result
    }
    
    /// Check if a value is within the scale's domain
    public static func isInDomain(
        _ value: ScaleValue,
        for definition: ScaleDefinition
    ) -> Bool {
        let min = min(definition.beginValue, definition.endValue)
        let max = max(definition.beginValue, definition.endValue)
        return value >= min && value <= max
    }
    
    /// Get all values that would have major tick marks
    public static func majorTickValues(
        for definition: ScaleDefinition
    ) -> [ScaleValue] {
        let allTicks = generateTickMarks(for: definition)
        return allTicks
            .filter { $0.style.relativeLength >= 0.9 } // Major ticks
            .map { $0.value }
    }
    
    // MARK: - Circular Scale Helpers
    
    /// Calculate the arc length for a circular scale
    /// - Parameter definition: The scale definition (must be circular)
    /// - Returns: Arc length in points (circumference at the scale's radius)
    public static func arcLength(for definition: ScaleDefinition) -> Distance {
        guard let radius = definition.layout.radius else {
            fatalError("arcLength called on non-circular scale")
        }
        
        // Circumference = 2πr
        return 2.0 * .pi * radius
    }
    
    /// Calculate the linear distance along the arc for a value on a circular scale
    /// - Parameters:
    ///   - value: The value to locate
    ///   - definition: The scale definition (must be circular)
    /// - Returns: Arc distance in points from 0°
    public static func arcDistance(
        for value: ScaleValue,
        on definition: ScaleDefinition
    ) -> Distance {
        let angle = angularPosition(for: value, on: definition)
        guard let radius = definition.layout.radius else {
            fatalError("arcDistance called on non-circular scale")
        }
        
        // Arc length = radius × angle (in radians)
        let angleRadians = angle * .pi / 180.0
        return radius * angleRadians
    }
}

// MARK: - Scale Generator Result

/// Contains all calculated data needed to draw a scale
public struct GeneratedScale: Sendable {
    /// The original scale definition
    public let definition: ScaleDefinition
    
    /// All calculated tick marks
    public let tickMarks: [TickMark]
    
    /// Quick lookup: value -> normalized position
    public let valuePositionMap: [ScaleValue: NormalizedPosition]
    
    public init(definition: ScaleDefinition) {
        self.definition = definition
        self.tickMarks = ScaleCalculator.generateTickMarks(for: definition)
        
        // Build position map for quick lookups
        var map: [ScaleValue: NormalizedPosition] = [:]
        for tick in tickMarks where tick.style.shouldLabel {
            map[tick.value] = tick.normalizedPosition
        }
        self.valuePositionMap = map
    }
    
    /// Find the tick mark closest to a given position
    /// - Parameter position: Normalized position (0.0 to 1.0)
    /// - Returns: The closest tick mark
    public func nearestTick(to position: NormalizedPosition) -> TickMark? {
        // For circular scales, consider wrap-around
        if definition.isCircular {
            return tickMarks.min { tick1, tick2 in
                let dist1 = circularDistance(from: position, to: tick1.normalizedPosition)
                let dist2 = circularDistance(from: position, to: tick2.normalizedPosition)
                return dist1 < dist2
            }
        } else {
            return tickMarks.min { tick1, tick2 in
                abs(tick1.normalizedPosition - position) < abs(tick2.normalizedPosition - position)
            }
        }
    }
    
    /// Find the tick mark closest to a given angle on a circular scale
    /// - Parameter angle: Angular position (0° to 360°)
    /// - Returns: The closest tick mark
    public func nearestTick(toAngle angle: AngularPosition) -> TickMark? {
        guard definition.isCircular else {
            fatalError("nearestTick(toAngle:) called on non-circular scale")
        }
        
        let normalizedPosition = angle / 360.0
        return nearestTick(to: normalizedPosition)
    }
    
    /// Find all ticks within a normalized position range
    /// - Parameter range: Range of normalized positions
    /// - Returns: Array of tick marks in that range
    public func ticks(in range: ClosedRange<NormalizedPosition>) -> [TickMark] {
        tickMarks.filter { range.contains($0.normalizedPosition) }
    }
    
    /// Find all ticks within an angular range on a circular scale
    /// - Parameter range: Range of angular positions (0° to 360°)
    /// - Returns: Array of tick marks in that angular range
    public func ticks(inAngularRange range: ClosedRange<AngularPosition>) -> [TickMark] {
        guard definition.isCircular else {
            fatalError("ticks(inAngularRange:) called on non-circular scale")
        }
        
        let normalizedRange = (range.lowerBound / 360.0)...(range.upperBound / 360.0)
        
        // Handle wrap-around case (e.g., 350° to 10°)
        if range.lowerBound > range.upperBound {
            // Split into two ranges: [start...360°] and [0°...end]
            let range1 = tickMarks.filter { $0.normalizedPosition >= normalizedRange.lowerBound }
            let range2 = tickMarks.filter { $0.normalizedPosition <= normalizedRange.upperBound }
            return range1 + range2
        } else {
            return ticks(in: normalizedRange)
        }
    }
    
    /// Calculate circular distance between two normalized positions (0-1)
    /// Takes into account wrap-around for circular scales
    private func circularDistance(from pos1: NormalizedPosition, to pos2: NormalizedPosition) -> Double {
        let directDist = abs(pos2 - pos1)
        let wrapDist = 1.0 - directDist
        return min(directDist, wrapDist)
    }
}
