import Foundation
#if canImport(os)
import os
#endif

// MARK: - Parser Logger

#if canImport(os)
private let parserLogger = Logger(subsystem: "com.sliderulecorev3", category: "RuleDefinitionParser")
#endif

// MARK: - Slide Rule Components

/// Represents a stator (fixed part) of a slide rule
public struct Stator: Sendable {
    public let name: String
    public let scales: [GeneratedScale]
    public let heightInPoints: Distance
    /// Whether to render a border around this stator
    public let showBorder: Bool
    
    public init(name: String, scales: [GeneratedScale], heightInPoints: Distance, showBorder: Bool = false) {
        self.name = name
        self.scales = scales
        self.heightInPoints = heightInPoints
        self.showBorder = showBorder
    }
}

/// Represents a slide (movable part) of a slide rule
public struct Slide: Sendable {
    public let name: String
    public let scales: [GeneratedScale]
    public let heightInPoints: Distance
    /// Whether to render a border around this slide
    public let showBorder: Bool
    
    public init(name: String, scales: [GeneratedScale], heightInPoints: Distance, showBorder: Bool = false) {
        self.name = name
        self.scales = scales
        self.heightInPoints = heightInPoints
        self.showBorder = showBorder
    }
}

/// Represents a complete slide rule with front and back sides
public struct SlideRule: Sendable {
    /// Front side (side A)
    public let frontTopStator: Stator
    public let frontSlide: Slide
    public let frontBottomStator: Stator
    
    /// Back side (side B) - optional
    public let backTopStator: Stator?
    public let backSlide: Slide?
    public let backBottomStator: Stator?
    
    /// Total physical dimensions
    public let totalLengthInPoints: Distance
    
    /// Optional: If present, this is a circular rule with this diameter
    public let diameter: Distance?
    
    /// For circular rules: radial positions for each component [outer, middle, inner]
    public let radialPositions: [Distance]?
    
    public init(
        frontTopStator: Stator,
        frontSlide: Slide,
        frontBottomStator: Stator,
        backTopStator: Stator? = nil,
        backSlide: Slide? = nil,
        backBottomStator: Stator? = nil,
        totalLengthInPoints: Distance,
        diameter: Distance? = nil,
        radialPositions: [Distance]? = nil
    ) {
        self.frontTopStator = frontTopStator
        self.frontSlide = frontSlide
        self.frontBottomStator = frontBottomStator
        self.backTopStator = backTopStator
        self.backSlide = backSlide
        self.backBottomStator = backBottomStator
        self.totalLengthInPoints = totalLengthInPoints
        self.diameter = diameter
        self.radialPositions = radialPositions
    }
    
    /// Whether this is a circular slide rule
    public var isCircular: Bool {
        diameter != nil
    }
}

// MARK: - Rule Definition Parser

/// Parses PostScript-style slide rule definitions
/// Format: "(scale1 scale2 [ slide_scale1 ] scale3 : back_scale1 [ back_slide ])"
/// Circular: "(scales) circular:4inch"
public struct RuleDefinitionParser {
    
    public enum ParseError: Error, CustomStringConvertible, Equatable {
        case invalidFormat(String)
        case unknownScale(String)
        case missingBrackets
        case invalidDimensions
        case invalidCircularSpec(String)
        case conflictingModifiers(String)
        
        public var description: String {
            switch self {
            case .invalidFormat(let msg): return "Invalid format: \(msg)"
            case .unknownScale(let name): return "Unknown scale: \(name)"
            case .missingBrackets: return "Missing or mismatched brackets"
            case .invalidDimensions: return "Invalid dimensions specified"
            case .invalidCircularSpec(let spec): return "Invalid circular spec: \(spec)"
            case .conflictingModifiers(let token): return "Conflicting tick direction modifiers in token: \(token)"
            }
        }
    }
    
    /// Component heights in points (converted from PostScript mm values)
    public struct Dimensions: Sendable {
        public let topStatorHeight: Distance
        public let slideHeight: Distance
        public let bottomStatorHeight: Distance
        
        public init(topStatorMM: Double, slideMM: Double, bottomStatorMM: Double) {
            // Convert mm to points (1 mm = 2.834645669 points)
            let mmToPoints = 2.834645669
            self.topStatorHeight = topStatorMM * mmToPoints
            self.slideHeight = slideMM * mmToPoints
            self.bottomStatorHeight = bottomStatorMM * mmToPoints
        }
        
        public var totalHeight: Distance {
            topStatorHeight + slideHeight + bottomStatorHeight
        }
        
        /// For circular rules, these become radii from outer to inner
        public var asRadii: [Distance] {
            [topStatorHeight, slideHeight, bottomStatorHeight]
        }
    }
    
    // MARK: - Circular Support
    
    /// Parse circular rule specification
    /// Formats: "circular:4inch", "circular:144", "circular:10cm", "circular:100mm"
    public static func parseCircularSpec(_ spec: String) -> Distance? {
        let cleaned = spec.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard cleaned.hasPrefix("circular:") else { return nil }
        
        let sizeSpec = cleaned.replacingOccurrences(of: "circular:", with: "")
        
        // Handle "5inch" or "5in"
        if sizeSpec.hasSuffix("inch") || sizeSpec.hasSuffix("in") {
            let inchStr = sizeSpec
                .replacingOccurrences(of: "inch", with: "")
                .replacingOccurrences(of: "in", with: "")
            if let inches = Double(inchStr) {
                return inches * 72.0 // points per inch
            }
        }
        
        // Handle "5mm"
        if sizeSpec.hasSuffix("mm") {
            let mmStr = sizeSpec.replacingOccurrences(of: "mm", with: "")
            if let mm = Double(mmStr) {
                return mm * 2.834645669 // points per mm
            }
        }
        
        // Handle "5cm"
        if sizeSpec.hasSuffix("cm") {
            let cmStr = sizeSpec.replacingOccurrences(of: "cm", with: "")
            if let cm = Double(cmStr) {
                return cm * 28.34645669 // points per cm
            }
        }
        
        // Handle raw points
        if let points = Double(sizeSpec) {
            return points
        }
        
        return nil
    }
    
    /// Parse with circular support
    /// Format: "(K A [ C ]) circular:4inch"
    public static func parseWithCircular(
        _ definition: String,
        dimensions: Dimensions,
        scaleLength: Distance = 250.0
    ) throws -> SlideRule {
        
        // Check for circular specification - split on " circular:" (with leading space)
        let parts = definition.components(separatedBy: " circular:")
        
        let layoutDef = parts[0].trimmingCharacters(in: .whitespaces)
        let circularSpec: Distance?
        
        if parts.count > 1 {
            let specString = "circular:" + parts[1].trimmingCharacters(in: .whitespaces)
            circularSpec = parseCircularSpec(specString)
            if circularSpec == nil {
                throw ParseError.invalidCircularSpec(specString)
            }
        } else {
            circularSpec = nil
        }
        
        // Parse the base rule (linear)
        var rule = try parse(layoutDef, dimensions: dimensions, scaleLength: scaleLength)
        
        // If circular, convert all scales
        if let diameter = circularSpec {
            let radii = dimensions.asRadii
            
            rule = SlideRule(
                frontTopStator: convertToCircular(stator: rule.frontTopStator, diameter: diameter, radius: radii[0]),
                frontSlide: convertToCircular(slide: rule.frontSlide, diameter: diameter, radius: radii[1]),
                frontBottomStator: convertToCircular(stator: rule.frontBottomStator, diameter: diameter, radius: radii[2]),
                backTopStator: rule.backTopStator.map { convertToCircular(stator: $0, diameter: diameter, radius: radii[0]) },
                backSlide: rule.backSlide.map { convertToCircular(slide: $0, diameter: diameter, radius: radii[1]) },
                backBottomStator: rule.backBottomStator.map { convertToCircular(stator: $0, diameter: diameter, radius: radii[2]) },
                totalLengthInPoints: scaleLength,
                diameter: diameter,
                radialPositions: radii
            )
        }
        
        return rule
    }
    
    // MARK: - Linear Parse (Original)
    
    /// Parse a rule definition string
    /// - Parameters:
    ///   - definition: String like "(C D [ CI ] A K : LL1 LL2 [ LL3 ])"
    ///   - dimensions: Component heights
    ///   - scaleLength: Length of scales in points (e.g., 250mm = ~710 points)
    /// - Returns: A SlideRule structure
    public static func parse(
        _ definition: String,
        dimensions: Dimensions,
        scaleLength: Distance = 250.0
    ) throws -> SlideRule {
        // Remove parentheses and split by colon for front/back
        let cleaned = definition
            .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            .trimmingCharacters(in: .whitespaces)
        
        let sides = cleaned.components(separatedBy: ":")
        guard !sides.isEmpty else {
            throw ParseError.invalidFormat("Empty definition")
        }
        
        // Parse front side with component heights for scale sizing
        let frontComponents = try parseComponents(
            sides[0],
            scaleLength: scaleLength,
            topStatorHeight: dimensions.topStatorHeight,
            slideHeight: dimensions.slideHeight,
            bottomStatorHeight: dimensions.bottomStatorHeight
        )
        
        let frontTopStator = Stator(
            name: "Front Top",
            scales: frontComponents.topScales,
            heightInPoints: dimensions.topStatorHeight
        )
        
        let frontSlide = Slide(
            name: "Front Slide",
            scales: frontComponents.slideScales,
            heightInPoints: dimensions.slideHeight
        )
        
        let frontBottomStator = Stator(
            name: "Front Bottom",
            scales: frontComponents.bottomScales,
            heightInPoints: dimensions.bottomStatorHeight
        )
        
        // Parse back side if present
        var backTopStator: Stator?
        var backSlide: Slide?
        var backBottomStator: Stator?
        
        if sides.count > 1 {
            let backComponents = try parseComponents(
                sides[1],
                scaleLength: scaleLength,
                topStatorHeight: dimensions.topStatorHeight,
                slideHeight: dimensions.slideHeight,
                bottomStatorHeight: dimensions.bottomStatorHeight
            )
            
            backTopStator = Stator(
                name: "Back Top",
                scales: backComponents.topScales,
                heightInPoints: dimensions.topStatorHeight
            )
            
            backSlide = Slide(
                name: "Back Slide",
                scales: backComponents.slideScales,
                heightInPoints: dimensions.slideHeight
            )
            
            backBottomStator = Stator(
                name: "Back Bottom",
                scales: backComponents.bottomScales,
                heightInPoints: dimensions.bottomStatorHeight
            )
        }
        
        return SlideRule(
            frontTopStator: frontTopStator,
            frontSlide: frontSlide,
            frontBottomStator: frontBottomStator,
            backTopStator: backTopStator,
            backSlide: backSlide,
            backBottomStator: backBottomStator,
            totalLengthInPoints: scaleLength
        )
    }
    
    // MARK: - Private Parsing Helpers
    
    private struct ParsedComponents {
        let topScales: [GeneratedScale]
        let slideScales: [GeneratedScale]
        let bottomScales: [GeneratedScale]
    }
    
    private static func parseComponents(
        _ sideDefinition: String,
        scaleLength: Distance,
        topStatorHeight: Distance,
        slideHeight: Distance,
        bottomStatorHeight: Distance
    ) throws -> ParsedComponents {
        var topScales: [GeneratedScale] = []
        var slideScales: [GeneratedScale] = []
        var bottomScales: [GeneratedScale] = []
        
        var currentTarget: ScaleTarget = .topStator
        var inBrackets = false
        var nextScaleNoLineBreak = false  // Track if next scale should have noLineBreak
        var splitGroupAccumulator: [GeneratedScale] = []  // Accumulate scales for split processing
        
        // Tokenize by spaces and brackets
        let tokens = tokenize(sideDefinition)
        
        // First pass: count scales per component to calculate individual scale heights
        var topScaleCount = 0
        var slideScaleCount = 0
        var bottomScaleCount = 0
        var targetForCounting: ScaleTarget = .topStator
        
        for token in tokens {
            switch token {
            case "[":
                targetForCounting = .slide
            case "]":
                targetForCounting = .bottomStator
            case "|", "blank":
                continue
            default:
                // Count actual scales (not separators or brackets)
                switch targetForCounting {
                case .topStator:
                    topScaleCount += 1
                case .slide:
                    slideScaleCount += 1
                case .bottomStator:
                    bottomScaleCount += 1
                }
            }
        }
        
        // Calculate individual scale heights: component_height / number_of_scales
        // Minimum 5pt per scale to ensure visibility
        let topScaleHeight = topScaleCount > 0 ? max(5.0, topStatorHeight / Double(topScaleCount)) : 36.0
        let slideScaleHeight = slideScaleCount > 0 ? max(5.0, slideHeight / Double(slideScaleCount)) : 36.0
        let bottomScaleHeight = bottomScaleCount > 0 ? max(5.0, bottomStatorHeight / Double(bottomScaleCount)) : 36.0
        
        // Second pass: create scales with calculated heights
        for token in tokens {
            switch token {
            case "[":
                if inBrackets {
                    throw ParseError.missingBrackets
                }
                inBrackets = true
                currentTarget = .slide
                
            case "]":
                if !inBrackets {
                    throw ParseError.missingBrackets
                }
                inBrackets = false
                currentTarget = .bottomStator
                
            case "|":
                // Separator line indicator: affects both PREVIOUS and NEXT scales in different ways
                //
                // SEMANTIC MEANING: "S | T" means:
                //   - S has a separator line drawn below it (hasBottomSeparator = true)
                //   - T appears without vertical spacing/line break (noLineBreak = true)
                //
                // INTENTIONAL ASYMMETRY:
                //   - Separator flag: marks the PREVIOUS scale (the one before |)
                //   - NoLineBreak flag: marks the NEXT scale (the one after |)
                //
                // This asymmetry is correct because:
                //   1. The separator is drawn BELOW the previous scale
                //   2. The next scale is positioned WITHOUT line break
                //   3. They work together to create a visual separator between scales
                //
                // EDGE CASE: "| C D" (separator at beginning)
                //   - C gets noLineBreak = true (normal behavior)
                //   - NO scale gets hasBottomSeparator (no previous scale exists)
                //   - The guard checks (!isEmpty) prevent crashes in this case
                
                // Set flag for NEXT scale to have noLineBreak
                nextScaleNoLineBreak = true
                
                // Mark the PREVIOUS scale (most recently added) with hasBottomSeparator
                // Guard checks ensure we don't try to mark a non-existent scale
                switch currentTarget {
                case .topStator:
                    if !topScales.isEmpty {
                        let lastIndex = topScales.count - 1
                        let lastScale = topScales[lastIndex]
                        topScales[lastIndex] = GeneratedScale(
                            definition: updateScaleWithSeparator(lastScale.definition),
                            noLineBreak: lastScale.noLineBreak
                        )
                    }
                case .slide:
                    if !slideScales.isEmpty {
                        let lastIndex = slideScales.count - 1
                        let lastScale = slideScales[lastIndex]
                        slideScales[lastIndex] = GeneratedScale(
                            definition: updateScaleWithSeparator(lastScale.definition),
                            noLineBreak: lastScale.noLineBreak
                        )
                    }
                case .bottomStator:
                    if !bottomScales.isEmpty {
                        let lastIndex = bottomScales.count - 1
                        let lastScale = bottomScales[lastIndex]
                        bottomScales[lastIndex] = GeneratedScale(
                            definition: updateScaleWithSeparator(lastScale.definition),
                            noLineBreak: lastScale.noLineBreak
                        )
                    }
                }
                continue
                
            case "blank":
                // "blank" token was used for spacer scales in the original PostScript engine.
                // This feature is no longer supported. Log a warning and skip.
                #if canImport(os)
                parserLogger.warning("'blank' token is no longer supported and will be ignored. Remove 'blank' from your definition string.")
                #endif
                continue
                
            default:
                // Parse scale name with optional modifiers
                let (scaleName, tickDir, noLineBreak) = try parseScaleToken(token)
                
                guard let definition = StandardScales.scale(named: scaleName, length: scaleLength) else {
                    throw ParseError.unknownScale(scaleName)
                }
                
                // Preserve original scale name from definition string if different from canonical name
                let originalName = (definition.name != scaleName) ? scaleName : nil
                
                // Calculate the appropriate height for this scale based on its component
                let scaleHeight: Distance
                switch currentTarget {
                case .topStator:
                    scaleHeight = topScaleHeight
                case .slide:
                    scaleHeight = slideScaleHeight
                case .bottomStator:
                    scaleHeight = bottomScaleHeight
                }
                
                // Apply height, tick direction override, or displayName if needed
                var finalDefinition = definition
                if tickDir != nil || originalName != nil || definition.height != scaleHeight {
                    finalDefinition = ScaleDefinition(
                        name: finalDefinition.name,
                        formula: finalDefinition.formula,
                        function: finalDefinition.function,
                        beginValue: finalDefinition.beginValue,
                        endValue: finalDefinition.endValue,
                        scaleLengthInPoints: finalDefinition.scaleLengthInPoints,
                        height: scaleHeight,  // Apply calculated height
                        layout: finalDefinition.layout,
                        tickDirection: tickDir ?? finalDefinition.tickDirection,
                        subsections: finalDefinition.subsections,
                        defaultTickStyles: finalDefinition.defaultTickStyles,
                        labelFormatter: finalDefinition.labelFormatter,
                        labelColor: finalDefinition.labelColor,
                        colorApplication: finalDefinition.colorApplication,
                        constants: finalDefinition.constants,
                        showBaseline: finalDefinition.showBaseline,
                        hasBottomSeparator: false,  // Never set separator on the scale after |
                        formulaTracking: finalDefinition.formulaTracking,
                        displayName: originalName
                    )
                }
                
                // Use nextScaleNoLineBreak flag (from | token) or noLineBreak from token modifier (^)
                let generated = GeneratedScale(
                    definition: finalDefinition,
                    noLineBreak: nextScaleNoLineBreak || noLineBreak
                )
                nextScaleNoLineBreak = false  // Reset flag after use
                
                // Handle split group accumulation
                // If this scale has noLineBreak (from ^), add to accumulator
                if noLineBreak {
                    splitGroupAccumulator.append(generated)
                } else {
                    // This scale completes a split group (or is standalone)
                    if !splitGroupAccumulator.isEmpty {
                        // We have accumulated scales - this is the final scale in the group
                        splitGroupAccumulator.append(generated)
                        
                        // Process the split group: assign split segments
                        let processedGroup = processSplitGroup(splitGroupAccumulator)
                        
                        // Append all processed scales to appropriate target
                        for scale in processedGroup {
                            switch currentTarget {
                            case .topStator:
                                topScales.append(scale)
                            case .slide:
                                slideScales.append(scale)
                            case .bottomStator:
                                bottomScales.append(scale)
                            }
                        }
                        
                        // Clear accumulator
                        splitGroupAccumulator = []
                    } else {
                        // Standalone scale (no split group)
                        switch currentTarget {
                        case .topStator:
                            topScales.append(generated)
                        case .slide:
                            slideScales.append(generated)
                        case .bottomStator:
                            bottomScales.append(generated)
                        }
                    }
                }
            }
        }
        
        if inBrackets {
            throw ParseError.missingBrackets
        }
        
        // Handle any remaining scales in split accumulator (shouldn't happen in valid input)
        if !splitGroupAccumulator.isEmpty {
            // Malformed: scales with ^ but no final scale
            // Process them anyway as a group
            let processedGroup = processSplitGroup(splitGroupAccumulator)
            for scale in processedGroup {
                switch currentTarget {
                case .topStator:
                    topScales.append(scale)
                case .slide:
                    slideScales.append(scale)
                case .bottomStator:
                    bottomScales.append(scale)
                }
            }
        }
        
        return ParsedComponents(
            topScales: topScales,
            slideScales: slideScales,
            bottomScales: bottomScales
        )
    }
    
    /// Process a split scale group and assign split segments
    /// For 2-segment splits: first = left(0.0), second = right(-1.0)
    /// For 3+ segments: evenly distribute (currently unsupported, will log warning)
    private static func processSplitGroup(_ group: [GeneratedScale]) -> [GeneratedScale] {
        guard group.count >= 2 else {
            // Single scale shouldn't be in a split group, but return as-is
            return group
        }
        
        if group.count == 2 {
            // Standard 2-segment split
            let leftScale = updateScaleWithSplitSegment(
                group[0],
                segment: .left(formulaOffset: 0.0)
            )
            let rightScale = updateScaleWithSplitSegment(
                group[1],
                segment: .right(formulaOffset: 0.0)
            )
            #if DEBUG
            print("[SplitScaleDebug] Processed group: \(group[0].definition.name) [\(group[0].definition.beginValue)→\(group[0].definition.endValue)] and \(group[1].definition.name) [\(group[1].definition.beginValue)→\(group[1].definition.endValue)]. Left offset: 0.0, Right offset: 0.0")
            #endif
            return [leftScale, rightScale]
        } else {
            // 3+ segment splits are not yet supported in Phase 2
            // Log warning and return without split segments
            #if canImport(os)
            parserLogger.warning("Split groups with more than 2 segments are not yet supported. Found \(group.count) segments.")
            #endif
            return group
        }
    }
    
    /// Helper to create a copy of a GeneratedScale with splitSegment set
    private static func updateScaleWithSplitSegment(
        _ generated: GeneratedScale,
        segment: SplitSegment
    ) -> GeneratedScale {
        let updatedDefinition = ScaleDefinition(
            name: generated.definition.name,
            formula: generated.definition.formula,
            function: generated.definition.function,
            beginValue: generated.definition.beginValue,
            endValue: generated.definition.endValue,
            scaleLengthInPoints: generated.definition.scaleLengthInPoints,
            height: generated.definition.height,
            layout: generated.definition.layout,
            tickDirection: generated.definition.tickDirection,
            subsections: generated.definition.subsections,
            defaultTickStyles: generated.definition.defaultTickStyles,
            labelFormatter: generated.definition.labelFormatter,
            labelColor: generated.definition.labelColor,
            colorApplication: generated.definition.colorApplication,
            constants: generated.definition.constants,
            showBaseline: generated.definition.showBaseline,
            hasBottomSeparator: generated.definition.hasBottomSeparator,
            formulaTracking: generated.definition.formulaTracking,
            displayName: generated.definition.displayName,
            splitSegment: segment
        )
        
        return GeneratedScale(
            definition: updatedDefinition,
            noLineBreak: generated.noLineBreak
        )
    }
    
    private enum ScaleTarget {
        case topStator
        case slide
        case bottomStator
    }
    
    /// Tokenize the definition string, preserving brackets as separate tokens
    private static func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        
        for char in input {
            if char == "[" || char == "]" || char == "|" {
                if !currentToken.isEmpty {
                    tokens.append(currentToken.trimmingCharacters(in: .whitespaces))
                    currentToken = ""
                }
                tokens.append(String(char))
            } else if char.isWhitespace {
                if !currentToken.isEmpty {
                    tokens.append(currentToken.trimmingCharacters(in: .whitespaces))
                    currentToken = ""
                }
            } else {
                currentToken.append(char)
            }
        }
        
        if !currentToken.isEmpty {
            tokens.append(currentToken.trimmingCharacters(in: .whitespaces))
        }
        
        return tokens.filter { !$0.isEmpty }
    }
    
    /// Parse a scale token which may have modifiers
    /// Examples: "C", "D-", "ST+", "LL1^", "C^-" (combined)
    /// - Returns: (scale name, optional tick direction override, noLineBreak flag)
    /// - Throws: ParseError.conflictingModifiers if both + and - modifiers are present
    private static func parseScaleToken(_ token: String) throws -> (String, TickDirection?, Bool) {
        var scaleName = token
        var tickDir: TickDirection?
        var noLineBreak = false
        var hasPlusModifier = false
        var hasMinusModifier = false
        
        // Process modifiers from the end, handling combined modifiers like "C^-" or "C-^"
        // Keep stripping modifiers until we have only the scale name
        while !scaleName.isEmpty {
            if scaleName.hasSuffix("-") {
                hasMinusModifier = true
                tickDir = .down
                scaleName = String(scaleName.dropLast())
            } else if scaleName.hasSuffix("+") {
                hasPlusModifier = true
                tickDir = .up
                scaleName = String(scaleName.dropLast())
            } else if scaleName.hasSuffix("^") {
                // No line break indicator - scale continues on same line
                noLineBreak = true
                scaleName = String(scaleName.dropLast())
            } else {
                // No more modifiers, we have the scale name
                break
            }
        }
        
        // Check for conflicting tick direction modifiers after all processing
        if hasPlusModifier && hasMinusModifier {
            throw ParseError.conflictingModifiers(token)
        }
        
        return (scaleName, tickDir, noLineBreak)
    }
    
    /// Helper to create a copy of a ScaleDefinition with hasBottomSeparator set to true
    private static func updateScaleWithSeparator(_ definition: ScaleDefinition) -> ScaleDefinition {
        return ScaleDefinition(
            name: definition.name,
            formula: definition.formula,
            function: definition.function,
            beginValue: definition.beginValue,
            endValue: definition.endValue,
            scaleLengthInPoints: definition.scaleLengthInPoints,
            height: definition.height,
            layout: definition.layout,
            tickDirection: definition.tickDirection,
            subsections: definition.subsections,
            defaultTickStyles: definition.defaultTickStyles,
            labelFormatter: definition.labelFormatter,
            labelColor: definition.labelColor,
            colorApplication: definition.colorApplication,
            constants: definition.constants,
            showBaseline: definition.showBaseline,
            hasBottomSeparator: true,  // Set separator flag
            formulaTracking: definition.formulaTracking,
            displayName: definition.displayName
        )
    }
    
    // MARK: - Circular Conversion Helpers
    
    private static func convertToCircular(
        stator: Stator,
        diameter: Distance,
        radius: Distance
    ) -> Stator {
        let circularScales = stator.scales.map { generated in
            convertScaleToCircular(generated, diameter: diameter, radius: radius)
        }
        return Stator(name: stator.name, scales: circularScales, heightInPoints: stator.heightInPoints)
    }
    
    private static func convertToCircular(
        slide: Slide,
        diameter: Distance,
        radius: Distance
    ) -> Slide {
        let circularScales = slide.scales.map { generated in
            convertScaleToCircular(generated, diameter: diameter, radius: radius)
        }
        return Slide(name: slide.name, scales: circularScales, heightInPoints: slide.heightInPoints)
    }
    
    private static func convertScaleToCircular(
        _ generated: GeneratedScale,
        diameter: Distance,
        radius: Distance
    ) -> GeneratedScale {
        // Create circular layout version of the scale
        let circularDef = ScaleDefinition(
            name: generated.definition.name,
            formula: generated.definition.formula,
            function: generated.definition.function,
            beginValue: generated.definition.beginValue,
            endValue: generated.definition.endValue,
            scaleLengthInPoints: generated.definition.scaleLengthInPoints,
            layout: .circular(diameter: diameter, radiusInPoints: radius),
            tickDirection: generated.definition.tickDirection,
            subsections: generated.definition.subsections,
            defaultTickStyles: generated.definition.defaultTickStyles,
            labelFormatter: generated.definition.labelFormatter,
            labelColor: generated.definition.labelColor,
            colorApplication: generated.definition.colorApplication,
            constants: generated.definition.constants,
            showBaseline: generated.definition.showBaseline,
            hasBottomSeparator: generated.definition.hasBottomSeparator,
            formulaTracking: generated.definition.formulaTracking,
            displayName: generated.definition.displayName
        )
        
        // Preserve the noLineBreak flag when converting to circular
        return GeneratedScale(definition: circularDef, noLineBreak: generated.noLineBreak)
    }
}

// MARK: - Convenience Factory

extension SlideRule {
    /// Create common slide rule models
    public static func logLogDuplexDecitrig(scaleLength: Distance = 250.0) -> SlideRule {
        // Keuffel and Esser 4081-3 pattern
        // "(LL01 K A [ B | T ST S ] D L- LL1- : LL02 LL03 DF [ CF CIF | CI C ] D LL3- LL2-)"
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14
        )
        
        do {
            return try RuleDefinitionParser.parse(
                "(K A [ C T ST S ] D L- : LL1 LL2 LL3 [ CI C ] D)",
                dimensions: dimensions,
                scaleLength: scaleLength
            )
        } catch {
            fatalError("Failed to parse standard rule definition: \(error)")
        }
    }
    
    /// Create a circular slide rule
    public static func circularBasic(diameter: Distance = 288.0) -> SlideRule {
        let dimensions = RuleDefinitionParser.Dimensions(
            topStatorMM: 12,  // outer ring
            slideMM: 16,      // middle ring
            bottomStatorMM: 8 // inner ring
        )
        
        do {
            return try RuleDefinitionParser.parseWithCircular(
                "(A [ C ] CI) circular:\(diameter / 72.0)inch",
                dimensions: dimensions
            )
        } catch {
            fatalError("Failed to parse circular rule: \(error)")
        }
    }
}
