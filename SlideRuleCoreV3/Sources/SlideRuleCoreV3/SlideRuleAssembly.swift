import Foundation

// MARK: - Slide Rule Components

/// Represents a stator (fixed part) of a slide rule
public struct Stator: Sendable {
    public let name: String
    public let scales: [GeneratedScale]
    public let heightInPoints: Distance
    
    public init(name: String, scales: [GeneratedScale], heightInPoints: Distance) {
        self.name = name
        self.scales = scales
        self.heightInPoints = heightInPoints
    }
}

/// Represents a slide (movable part) of a slide rule
public struct Slide: Sendable {
    public let name: String
    public let scales: [GeneratedScale]
    public let heightInPoints: Distance
    
    public init(name: String, scales: [GeneratedScale], heightInPoints: Distance) {
        self.name = name
        self.scales = scales
        self.heightInPoints = heightInPoints
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
        
        public var description: String {
            switch self {
            case .invalidFormat(let msg): return "Invalid format: \(msg)"
            case .unknownScale(let name): return "Unknown scale: \(name)"
            case .missingBrackets: return "Missing or mismatched brackets"
            case .invalidDimensions: return "Invalid dimensions specified"
            case .invalidCircularSpec(let spec): return "Invalid circular spec: \(spec)"
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
        
        // Parse front side
        let frontComponents = try parseComponents(sides[0], scaleLength: scaleLength)
        
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
            let backComponents = try parseComponents(sides[1], scaleLength: scaleLength)
            
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
        scaleLength: Distance
    ) throws -> ParsedComponents {
        var topScales: [GeneratedScale] = []
        var slideScales: [GeneratedScale] = []
        var bottomScales: [GeneratedScale] = []
        
        var currentTarget: ScaleTarget = .topStator
        var inBrackets = false
        
        // Tokenize by spaces and brackets
        let tokens = tokenize(sideDefinition)
        
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
                // Separator line indicator - ignored for now
                continue
                
            case "blank":
                // Blank line indicator - ignored for now
                continue
                
            default:
                // Parse scale name with optional modifiers
                let (scaleName, tickDir, noLineBreak) = parseScaleToken(token)
                
                guard let definition = StandardScales.scale(named: scaleName, length: scaleLength) else {
                    throw ParseError.unknownScale(scaleName)
                }
                
                // Apply tick direction override if specified
                var finalDefinition = definition
                if let overrideDir = tickDir {
                    finalDefinition = ScaleDefinition(
                        name: finalDefinition.name,
                        function: finalDefinition.function,
                        beginValue: finalDefinition.beginValue,
                        endValue: finalDefinition.endValue,
                        scaleLengthInPoints: finalDefinition.scaleLengthInPoints,
                        layout: finalDefinition.layout,
                        tickDirection: overrideDir,
                        subsections: finalDefinition.subsections,
                        defaultTickStyles: finalDefinition.defaultTickStyles,
                        labelFormatter: finalDefinition.labelFormatter,
                        labelColor: finalDefinition.labelColor,
                        constants: finalDefinition.constants
                    )
                }
                
                let generated = GeneratedScale(definition: finalDefinition, noLineBreak: noLineBreak)
                
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
        
        if inBrackets {
            throw ParseError.missingBrackets
        }
        
        return ParsedComponents(
            topScales: topScales,
            slideScales: slideScales,
            bottomScales: bottomScales
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
    /// Examples: "C", "D-", "ST+", "LL1^"
    /// - Returns: (scale name, optional tick direction override, noLineBreak flag)
    private static func parseScaleToken(_ token: String) -> (String, TickDirection?, Bool) {
        var scaleName = token
        var tickDir: TickDirection?
        var noLineBreak = false
        
        // Check for tick direction override at the end
        if token.hasSuffix("-") {
            tickDir = .down
            scaleName = String(token.dropLast())
        } else if token.hasSuffix("+") {
            tickDir = .up
            scaleName = String(token.dropLast())
        } else if token.hasSuffix("^") {
            // No line break indicator - scale continues on same line
            noLineBreak = true
            scaleName = String(token.dropLast())
        }
        
        return (scaleName, tickDir, noLineBreak)
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
            constants: generated.definition.constants
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
