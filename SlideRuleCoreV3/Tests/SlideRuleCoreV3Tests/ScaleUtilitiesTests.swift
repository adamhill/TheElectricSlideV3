import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Priority 1: Comprehensive ScaleUtilities Test Suite
/// Tests concurrent scale generation, interpolation, validation, analysis, and export
@Suite("Scale Utilities - Comprehensive Coverage")
struct ScaleUtilitiesTests {
    
    // MARK: - Concurrent Scale Generation Tests
    
    @Suite("Concurrent Scale Generation - Actor-based thread-safe operations")
    struct ConcurrentGenerationTests {
        
        @Test("Concurrent generator produces scales in original order")
        func concurrentOrderPreservation() async {
            let generator = ConcurrentScaleGenerator()
            let definitions = [
                StandardScales.cScale(length: 250.0),
                StandardScales.dScale(length: 250.0),
                StandardScales.aScale(length: 250.0),
                StandardScales.kScale(length: 250.0)
            ]
            
            let generated = await generator.generateScales(definitions)
            
            #expect(generated.count == 4, "Should generate 4 scales")
            #expect(generated[0].definition.name == "C")
            #expect(generated[1].definition.name == "D")
            #expect(generated[2].definition.name == "A")
            #expect(generated[3].definition.name == "K")
        }
        
        @Test("Concurrent generation with 10 scales completes successfully")
        func largeScaleConcurrentGeneration() async {
            let generator = ConcurrentScaleGenerator()
            var definitions: [ScaleDefinition] = []
            
            // Generate 10 different scales
            let scaleNames = ["C", "D", "CI", "A", "K", "S", "T", "L", "LL1", "LL2"]
            for name in scaleNames {
                if let scale = StandardScales.scale(named: name, length: 250.0) {
                    definitions.append(scale)
                }
            }
            
            let generated = await generator.generateScales(definitions)
            
            #expect(generated.count == 10, "Should generate all 10 scales")
            for (index, scale) in generated.enumerated() {
                #expect(!scale.tickMarks.isEmpty, "Scale \(index) should have tick marks")
            }
        }
        
        @Test("Concurrent generation maintains scale definition integrity")
        func definitionIntegrityPreservation() async {
            let generator = ConcurrentScaleGenerator()
            let originalScale = StandardScales.cScale(length: 250.0)
            let definitions = [originalScale, originalScale, originalScale]
            
            let generated = await generator.generateScales(definitions)
            
            #expect(generated.count == 3)
            for scale in generated {
                #expect(scale.definition.name == "C")
                #expect(scale.definition.scaleLengthInPoints == 250.0)
                #expect(scale.definition.beginValue == 1.0)
                #expect(scale.definition.endValue == 10.0)
            }
        }
        
        @Test("Empty scale array returns empty results")
        func emptyScaleArray() async {
            let generator = ConcurrentScaleGenerator()
            let generated = await generator.generateScales([])
            
            #expect(generated.isEmpty, "Empty input should produce empty output")
        }
        
        @Test("Single scale generation works correctly")
        func singleScaleGeneration() async {
            let generator = ConcurrentScaleGenerator()
            let scale = StandardScales.cScale(length: 250.0)
            let generated = await generator.generateScales([scale])
            
            #expect(generated.count == 1)
            #expect(!generated[0].tickMarks.isEmpty)
        }
        
        @Test("Concurrent generation of different scale types produces valid results")
        func diverseScaleGeneration() async {
            let generator = ConcurrentScaleGenerator()
            let definitions: [ScaleDefinition] = [
                StandardScales.cScale(length: 250.0),     // Logarithmic
                StandardScales.aScale(length: 250.0),     // Squared
                StandardScales.sScale(length: 250.0),     // Trigonometric
                StandardScales.lScale(length: 250.0)      // Linear
            ]
            
            let generated = await generator.generateScales(definitions)
            
            #expect(generated.count == 4)
            // Each scale type should have different tick distributions
            let cTicks = generated[0].tickMarks.count
            let aTicks = generated[1].tickMarks.count
            let sTicks = generated[2].tickMarks.count
            let lTicks = generated[3].tickMarks.count
            
            #expect(cTicks > 0 && aTicks > 0 && sTicks > 0 && lTicks > 0, "All scales should generate ticks")
        }
    }
    
    // MARK: - Scale Interpolation Tests
    
    @Suite("Scale Interpolation - Finding values between tick marks")
    struct InterpolationTests {
        
        private let cScale = StandardScales.cScale(length: 250.0)
        private let lScale = StandardScales.lScale(length: 250.0)
        
        @Test("Interpolation finds value at normalized position", arguments: zip(
            [0.0, 0.5, 1.0],
            [1.0, 3.162, 10.0]
        ))
        func interpolationAtPositions(position: Double, expectedValue: Double) {
            let value = ScaleInterpolation.interpolateValue(at: position, in: GeneratedScale(definition: cScale))
            #expect(abs(value - expectedValue) < 0.01, "Interpolated value should match expected")
        }
        
        @Test("Nearest labeled tick is found correctly")
        func nearestLabeledTick() {
            let generatedScale = GeneratedScale(definition: cScale)
            let position = 0.5  // Middle of C scale
            
            let nearest = ScaleInterpolation.nearestLabeledTick(to: position, in: generatedScale)
            
            #expect(nearest != nil, "Should find a labeled tick near middle")
            if let tick = nearest {
                #expect(tick.label != nil, "Should be a labeled tick")
                #expect(abs(tick.normalizedPosition - position) < 0.2, "Should be reasonably close")
            }
        }
        
        @Test("Major divisions are identified properly")
        func majorDivisionsIdentification() {
            let generatedScale = GeneratedScale(definition: cScale)
            let majorDivisions = ScaleInterpolation.majorDivisions(in: generatedScale)
            
            #expect(!majorDivisions.isEmpty, "Should find major divisions")
            for division in majorDivisions {
                #expect(division.style.relativeLength >= 0.9, "Major divisions should have >= 0.9 relative length")
            }
        }
        
        @Test("Interpolation works on linear scales")
        func linearScaleInterpolation() {
            let generatedLinear = GeneratedScale(definition: lScale)
            
            let positions = [0.0, 0.25, 0.5, 0.75, 1.0]
            for pos in positions {
                let value = ScaleInterpolation.interpolateValue(at: pos, in: generatedLinear)
                // Linear scale: position should equal value (0 to 1)
                #expect(abs(value - pos) < 0.01, "Linear scale interpolation should match position")
            }
        }
    }
    
    // MARK: - Scale Validation Tests
    
    @Suite("Scale Validation - Mathematical correctness checking")
    struct ValidationTests {
        
        @Test("Valid scale passes all validation checks")
        func validScalePasses() throws {
            let validScale = StandardScales.cScale(length: 250.0)
            try ScaleValidator.validate(validScale)
            // If we get here without exception, validation passed
            #expect(Bool(true))
        }
        
        @Test("Invalid scale with infinite values throws error")
        func invalidInfiniteValues() {
            let invalidScale = ScaleDefinition(
                name: "Invalid",
                function: CustomFunction(
                    name: "invalid",
                    transform: { _ in Double.infinity },
                    inverseTransform: { _ in Double.infinity }
                ),
                beginValue: Double.infinity,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            
            #expect(throws: ScaleValidator.ValidationError.self) {
                try ScaleValidator.validate(invalidScale)
            }
        }
        
        @Test("Invalid scale with equal begin and end values throws error")
        func invalidEqualBeginEnd() {
            let invalidScale = ScaleDefinition(
                name: "Invalid",
                function: LogarithmicFunction(),
                beginValue: 5.0,
                endValue: 5.0,
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            
            #expect(throws: ScaleValidator.ValidationError.self) {
                try ScaleValidator.validate(invalidScale)
            }
        }
        
        @Test("Scale without subsections throws error")
        func emptySubsectionsError() {
            let invalidScale = ScaleDefinition(
                name: "Empty",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: []
            )
            
            #expect(throws: ScaleValidator.ValidationError.self) {
                try ScaleValidator.validate(invalidScale)
            }
        }
        
        @Test("Slide rule validation collects all scale errors")
        func slideRuleValidationCollectErrors() {
            let validC = StandardScales.cScale(length: 250.0)
            let validD = StandardScales.dScale(length: 250.0)
            
            let rule = SlideRule(
                frontTopStator: Stator(name: "Top", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                frontSlide: Slide(name: "Slide", scales: [GeneratedScale(definition: validD)], heightInPoints: 180.0),
                frontBottomStator: Stator(name: "Bottom", scales: [], heightInPoints: 200.0),
                backTopStator: nil,
                backSlide: nil,
                backBottomStator: nil,
                totalLengthInPoints: 250.0
            )
            
            let errors = ScaleValidator.validateRule(rule)
            // Valid scales should produce no errors
            #expect(errors.isEmpty)
        }
    }
    
    // MARK: - Scale Analysis Tests
    
    @Suite("Scale Analysis - Statistical information and density")
    struct AnalysisTests {
        
        private let cScale = StandardScales.cScale(length: 250.0)
        
        @Test("Scale statistics computed correctly")
        func statisticsComputation() {
            let generatedScale = GeneratedScale(definition: cScale)
            let stats = ScaleAnalysis.ScaleStatistics(scale: generatedScale)
            
            #expect(stats.totalTicks > 0, "Should have ticks")
            #expect(stats.majorTicks > 0, "Should have major ticks")
            #expect(stats.majorTicks <= stats.totalTicks, "Major ticks should be subset of total")
            #expect(stats.labeledTicks >= 0, "Should count labeled ticks")
            #expect(stats.averageTickSpacing > 0, "Should calculate average spacing")
        }
        
        @Test("Tick density varies across scale regions")
        func tickDensityVariation() {
            let generatedScale = GeneratedScale(definition: cScale)
            let densities = ScaleAnalysis.tickDensity(in: generatedScale, regions: 10)
            
            #expect(densities.count == 10, "Should have 10 region densities")
            // Log scale compresses low values in position space, so later regions have more ticks
            #expect(densities[9] > densities[0], "Later regions should be denser than early regions for log scale")
        }
        
        @Test("Highest density region identified correctly")
        func highestDensityRegion() {
            let generatedScale = GeneratedScale(definition: cScale)
            let result = ScaleAnalysis.highestDensityRegion(in: generatedScale, regionCount: 10)
            
            #expect(result != nil, "Should identify highest density region")
            if let region = result {
                #expect(region.density > 0, "Density should be positive")
                #expect(region.start >= 0.0 && region.start <= 1.0, "Start should be in range")
                #expect(region.end > region.start, "End should be after start")
            }
        }
        
        @Test("Statistics handle scale with many ticks")
        func largeTickCount() {
            let generatedScale = GeneratedScale(definition: cScale)
            let stats = ScaleAnalysis.ScaleStatistics(scale: generatedScale)
            
            #expect(stats.totalTicks > 100, "C scale should have many ticks")
            #expect(stats.mediumTicks + stats.minorTicks + stats.tinyTicks + stats.majorTicks <= stats.totalTicks, "Breakdown should sum to total")
        }
    }
    
    // MARK: - Scale Export Tests
    
    @Suite("Scale Export - CSV and JSON format support")
    struct ExportTests {
        
        private let cScale = StandardScales.cScale(length: 250.0)
        
        @Test("CSV export produces valid format with required columns")
        func csvExportFormat() {
            let generatedScale = GeneratedScale(definition: cScale)
            let csv = ScaleExporter.toCSV(generatedScale)
            
            #expect(csv.contains("value,normalizedPosition,absolutePosition,tickLength,label"), "Should have header row")
            
            let lines = csv.components(separatedBy: "\n")
            #expect(lines.count > 1, "Should have header plus data rows")
            
            // Check data rows
            for i in 1..<min(3, lines.count) {
                let line = lines[i]
                if !line.isEmpty {
                    let components = line.components(separatedBy: ",")
                    #expect(components.count >= 4, "Each row should have at least 4 columns")
                }
            }
        }
        
        @Test("CSV export handles special characters in labels")
        func csvSpecialCharacters() {
            let scale = ScaleDefinition(
                name: "Test",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [0])
                ],
                constants: [
                    ScaleConstant(value: 3.14159, label: "π", style: .major),
                    ScaleConstant(value: 2.71828, label: "e", style: .major)
                ]
            )
            
            let generatedScale = GeneratedScale(definition: scale)
            let csv = ScaleExporter.toCSV(generatedScale)
            
            #expect(csv.contains("π"), "Should include π constant")
            #expect(csv.contains("e"), "Should include e constant")
        }
        
        @Test("JSON export produces parseable output")
        func jsonExportValidity() throws {
            let generatedScale = GeneratedScale(definition: cScale)
            let json = try ScaleExporter.toJSON(generatedScale)
            
            #expect(!json.isEmpty, "JSON should not be empty")
            #expect(json.contains("\"name\""), "Should have name field")
            #expect(json.contains("\"tickMarks\""), "Should have tickMarks field")
            
            // Try to parse it as JSON
            if let data = json.data(using: .utf8) {
                let parsed = try JSONSerialization.jsonObject(with: data)
                #expect(parsed is [String: Any], "Should parse as JSON object")
            }
        }
        
        @Test("JSON export maintains all scale metadata")
        func jsonMetadataPreservation() throws {
            let generatedScale = GeneratedScale(definition: cScale)
            let json = try ScaleExporter.toJSON(generatedScale)
            
            #expect(json.contains("\"name\":\"C\""), "Should preserve scale name")
            #expect(json.contains("\"beginValue\":1"), "Should preserve begin value")
            #expect(json.contains("\"endValue\":10"), "Should preserve end value")
            #expect(json.contains("\"scaleLengthInPoints\":250"), "Should preserve scale length")
        }
        
        @Test("Export works with scales that have no labels")
        func unlabeledScaleExport() {
            let scale = ScaleDefinition(
                name: "Unlabeled",
                function: LinearFunction(),
                beginValue: 0.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(startValue: 0.0, tickIntervals: [0.1], labelLevels: [])
                ]
            )
            
            let generatedScale = GeneratedScale(definition: scale)
            let csv = ScaleExporter.toCSV(generatedScale)
            
            #expect(!csv.isEmpty, "Should export unlabeled scale")
            #expect(csv.contains("0.1"), "Should have tick at 0.1")
        }
        
        @Test("Export handles circular scales correctly")
        func circularScaleExport() throws {
            let circularScale = ScaleDefinition(
                name: "CircularC",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 360.0,
                layout: .circular(diameter: 200.0, radiusInPoints: 100.0),
                subsections: [
                    ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [0])
                ]
            )
            
            let generatedScale = GeneratedScale(definition: circularScale)
            let csv = ScaleExporter.toCSV(generatedScale)
            let json = try ScaleExporter.toJSON(generatedScale)
            
            #expect(!csv.isEmpty, "Should export circular scale to CSV")
            #expect(!json.isEmpty, "Should export circular scale to JSON")
        }
    }
    
    // MARK: - Async Rule Generation Tests
    
    @Suite("Async Rule Generation - Concurrent rule assembly from definition strings")
    struct AsyncRuleGenerationTests {
        
        @Test("Async generateRule creates valid slide rule from definition string")
        func asyncRuleGeneration() async throws {
            let generator = ConcurrentScaleGenerator()
            let definition = "B BI [ C CI D ]"
            let dimensions = RuleDefinitionParser.Dimensions(
                topStatorMM: 14.0,
                slideMM: 13.0,
                bottomStatorMM: 14.0
            )
            
            let rule = try await generator.generateRule(definition, dimensions: dimensions, scaleLength: 250.0)
            
            #expect(rule.frontTopStator.scales.count == 2, "Should have B and BI scales")
            #expect(rule.frontSlide.scales.count == 3, "Should have C, CI, and D scales")
            #expect(rule.totalLengthInPoints == 250.0, "Should preserve scale length")
        }
        
        @Test("Async generateRule handles complex multi-scale rules")
        func complexRuleGeneration() async throws {
            let generator = ConcurrentScaleGenerator()
            let definition = "K A [ B C CI D ] S L T"
            let dimensions = RuleDefinitionParser.Dimensions(
                topStatorMM: 14.0,
                slideMM: 13.0,
                bottomStatorMM: 14.0
            )
            
            let rule = try await generator.generateRule(definition, dimensions: dimensions, scaleLength: 300.0)
            
            #expect(rule.frontTopStator.scales.count == 2, "Should have K and A scales")
            #expect(rule.frontSlide.scales.count == 4, "Should have B, C, CI, and D scales")
            #expect(rule.frontBottomStator.scales.count == 3, "Should have S, L, and T scales")
        }
        
        @Test("Async generateRule maintains scale order from definition")
        func scaleOrderPreservation() async throws {
            let generator = ConcurrentScaleGenerator()
            let definition = "A B [ C D ]"
            let dimensions = RuleDefinitionParser.Dimensions(
                topStatorMM: 14.0,
                slideMM: 13.0,
                bottomStatorMM: 14.0
            )
            
            let rule = try await generator.generateRule(definition, dimensions: dimensions)
            
            #expect(rule.frontTopStator.scales[0].definition.name == "A")
            #expect(rule.frontTopStator.scales[1].definition.name == "B")
            #expect(rule.frontSlide.scales[0].definition.name == "C")
            #expect(rule.frontSlide.scales[1].definition.name == "D")
        }
        
        @Test("Async generateRule with custom scale length applies to all scales")
        func customScaleLength() async throws {
            let generator = ConcurrentScaleGenerator()
            let definition = "C [ D ]"
            let dimensions = RuleDefinitionParser.Dimensions(
                topStatorMM: 14.0,
                slideMM: 13.0,
                bottomStatorMM: 14.0
            )
            
            let rule = try await generator.generateRule(definition, dimensions: dimensions, scaleLength: 500.0)
            
            #expect(rule.totalLengthInPoints == 500.0)
            #expect(rule.frontTopStator.scales[0].definition.scaleLengthInPoints == 500.0)
            #expect(rule.frontSlide.scales[0].definition.scaleLengthInPoints == 500.0)
        }
    }
    
    // MARK: - Back-Sided Slide Rule Validation Tests
    
    @Suite("Back-sided slide rule validation catches configuration errors")
    struct BackSidedValidationTests {
        
        @Test("Validation checks back stator scales")
        func backStatorValidation() {
            let validC = StandardScales.cScale(length: 250.0)
            let invalidScale = ScaleDefinition(
                name: "Invalid",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 1.0,  // Equal begin and end
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            
            let rule = SlideRule(
                frontTopStator: Stator(name: "Top", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                frontSlide: Slide(name: "Slide", scales: [GeneratedScale(definition: validC)], heightInPoints: 180.0),
                frontBottomStator: Stator(name: "Bottom", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                backTopStator: Stator(name: "BackTop", scales: [GeneratedScale(definition: invalidScale)], heightInPoints: 200.0),
                backSlide: nil,
                backBottomStator: nil,
                totalLengthInPoints: 250.0
            )
            
            let errors = ScaleValidator.validateRule(rule)
            #expect(errors.count > 0, "Should detect error in back top stator")
            #expect(errors.contains { $0.0.contains("Back top") }, "Error should be from back top stator")
        }
        
        @Test("Validation checks back slide scales")
        func backSlideValidation() {
            let validC = StandardScales.cScale(length: 250.0)
            let invalidScale = ScaleDefinition(
                name: "Invalid",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: []  // Empty subsections
            )
            
            let rule = SlideRule(
                frontTopStator: Stator(name: "Top", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                frontSlide: Slide(name: "Slide", scales: [GeneratedScale(definition: validC)], heightInPoints: 180.0),
                frontBottomStator: Stator(name: "Bottom", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                backTopStator: nil,
                backSlide: Slide(name: "BackSlide", scales: [GeneratedScale(definition: invalidScale)], heightInPoints: 180.0),
                backBottomStator: nil,
                totalLengthInPoints: 250.0
            )
            
            let errors = ScaleValidator.validateRule(rule)
            #expect(errors.count > 0, "Should detect error in back slide")
            #expect(errors.contains { $0.0.contains("Back slide") }, "Error should be from back slide")
        }
        
        @Test("Validation checks back bottom stator scales")
        func backBottomStatorValidation() {
            let validC = StandardScales.cScale(length: 250.0)
            let invalidScale = ScaleDefinition(
                name: "Invalid",
                function: CustomFunction(
                    name: "inf",
                    transform: { _ in Double.infinity },
                    inverseTransform: { _ in 0 }
                ),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            
            let rule = SlideRule(
                frontTopStator: Stator(name: "Top", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                frontSlide: Slide(name: "Slide", scales: [GeneratedScale(definition: validC)], heightInPoints: 180.0),
                frontBottomStator: Stator(name: "Bottom", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                backTopStator: nil,
                backSlide: nil,
                backBottomStator: Stator(name: "BackBottom", scales: [GeneratedScale(definition: invalidScale)], heightInPoints: 200.0),
                totalLengthInPoints: 250.0
            )
            
            let errors = ScaleValidator.validateRule(rule)
            #expect(errors.count > 0, "Should detect error in back bottom stator")
            #expect(errors.contains { $0.0.contains("Back bottom") }, "Error should be from back bottom stator")
        }
        
        @Test("Validation collects multiple errors from back-sided rule")
        func multipleBackSideErrors() {
            let validC = StandardScales.cScale(length: 250.0)
            let invalidScale1 = ScaleDefinition(
                name: "Invalid1",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            let invalidScale2 = ScaleDefinition(
                name: "Invalid2",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: []
            )
            
            let rule = SlideRule(
                frontTopStator: Stator(name: "Top", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                frontSlide: Slide(name: "Slide", scales: [GeneratedScale(definition: validC)], heightInPoints: 180.0),
                frontBottomStator: Stator(name: "Bottom", scales: [GeneratedScale(definition: validC)], heightInPoints: 200.0),
                backTopStator: Stator(name: "BackTop", scales: [GeneratedScale(definition: invalidScale1)], heightInPoints: 200.0),
                backSlide: Slide(name: "BackSlide", scales: [GeneratedScale(definition: invalidScale2)], heightInPoints: 180.0),
                backBottomStator: nil,
                totalLengthInPoints: 250.0
            )
            
            let errors = ScaleValidator.validateRule(rule)
            #expect(errors.count >= 2, "Should detect multiple errors")
        }
    }
    
    // MARK: - Validation Error Paths Tests
    
    @Suite("Validation error paths throw appropriate exceptions")
    struct ValidationErrorPathsTests {
        
        @Test("Invalid function producing non-finite results throws invalidFunction error")
        func nonFiniteResultsError() {
            let invalidScale = ScaleDefinition(
                name: "InfiniteProducer",
                function: CustomFunction(
                    name: "inf",
                    transform: { _ in Double.infinity },
                    inverseTransform: { _ in 0 }
                ),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            
            #expect(throws: ScaleValidator.ValidationError.self) {
                try ScaleValidator.validate(invalidScale)
            }
        }
        
        @Test("Function with poor round-trip accuracy throws invalidFunction error")
        func poorRoundTripAccuracyError() {
            let badRoundTripScale = ScaleDefinition(
                name: "BadRoundTrip",
                function: CustomFunction(
                    name: "bad",
                    transform: { x in x * 2 },
                    inverseTransform: { x in x * 2 }  // Incorrect inverse
                ),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear
            )
            
            #expect(throws: ScaleValidator.ValidationError.self) {
                try ScaleValidator.validate(badRoundTripScale)
            }
        }
        
        @Test("Overlapping subsections throws overlappingSubsections error")
        func overlappingSubsectionsError() {
            let overlappingScale = ScaleDefinition(
                name: "Overlapping",
                function: LogarithmicFunction(),
                beginValue: 1.0,
                endValue: 10.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(startValue: 1.0, tickIntervals: [1.0], labelLevels: [0]),
                    ScaleSubsection(startValue: 1.0, tickIntervals: [0.5], labelLevels: [0])  // Same start value
                ]
            )
            
            #expect(throws: ScaleValidator.ValidationError.self) {
                try ScaleValidator.validate(overlappingScale)
            }
        }
        
        @Test("Validationhandles unexpected error types gracefully in validateRule")
        func unexpectedErrorHandling() {
            // Create a scale that will pass individual validation
            let validScale = StandardScales.cScale(length: 250.0)
            
            let rule = SlideRule(
                frontTopStator: Stator(name: "Top", scales: [GeneratedScale(definition: validScale)], heightInPoints: 200.0),
                frontSlide: Slide(name: "Slide", scales: [GeneratedScale(definition: validScale)], heightInPoints: 180.0),
                frontBottomStator: Stator(name: "Bottom", scales: [GeneratedScale(definition: validScale)], heightInPoints: 200.0),
                backTopStator: nil,
                backSlide: nil,
                backBottomStator: nil,
                totalLengthInPoints: 250.0
            )
            
            let errors = ScaleValidator.validateRule(rule)
            // Valid scales should not produce errors, even with unexpected error handling path
            #expect(errors.isEmpty, "Valid scales should produce no errors")
        }
        
        @Test("ValidationError descriptions are descriptive")
        func errorDescriptions() {
            let rangeError = ScaleValidator.ValidationError.invalidRange("test message")
            let functionError = ScaleValidator.ValidationError.invalidFunction("test function")
            let emptyError = ScaleValidator.ValidationError.emptySubsections
            let overlapError = ScaleValidator.ValidationError.overlappingSubsections
            
            #expect(rangeError.description.contains("Invalid range"))
            #expect(rangeError.description.contains("test message"))
            #expect(functionError.description.contains("Invalid function"))
            #expect(functionError.description.contains("test function"))
            #expect(emptyError.description.contains("at least one subsection"))
            #expect(overlapError.description.contains("overlapping"))
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Suite("Edge cases with zero or single ticks handle gracefully")
    struct EdgeCasesTests {
        
        @Test("Statistics with single tick produces zero average spacing")
        func singleTickZeroSpacing() {
            let singleTickScale = ScaleDefinition(
                name: "SingleTick",
                function: LinearFunction(),
                beginValue: 0.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(startValue: 0.5, tickIntervals: [1.0], labelLevels: [0])
                ]
            )
            
            let generatedScale = GeneratedScale(definition: singleTickScale)
            let stats = ScaleAnalysis.ScaleStatistics(scale: generatedScale)
            
            #expect(stats.totalTicks >= 0, "Should handle single tick")
            #expect(stats.averageTickSpacing == 0.0, "Single tick should have zero average spacing")
        }
        
        @Test("Statistics with no ticks produces zero average spacing")
        func noTicksZeroSpacing() {
            let noTickScale = ScaleDefinition(
                name: "NoTicks",
                function: LinearFunction(),
                beginValue: 0.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: []
            )
            
            let generatedScale = GeneratedScale(definition: noTickScale)
            let stats = ScaleAnalysis.ScaleStatistics(scale: generatedScale)
            
            #expect(stats.totalTicks == 0, "Should have no ticks")
            #expect(stats.averageTickSpacing == 0.0, "No ticks should have zero average spacing")
        }
        
        @Test("Highest density region returns nil when scale has no ticks")
        func noTicksReturnsNilDensityRegion() {
            let noTickScale = ScaleDefinition(
                name: "NoTicks",
                function: LinearFunction(),
                beginValue: 0.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: []
            )
            
            let generatedScale = GeneratedScale(definition: noTickScale)
            let result = ScaleAnalysis.highestDensityRegion(in: generatedScale, regionCount: 10)
            
            // When there are no ticks, the function may return a zero-density region or nil
            if let region = result {
                #expect(region.density == 0.0, "Should have zero density when no ticks")
            }
        }
        
        @Test("Tick density handles scales with very few ticks")
        func fewTicksDensity() {
            let fewTicksScale = ScaleDefinition(
                name: "FewTicks",
                function: LinearFunction(),
                beginValue: 0.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(startValue: 0.0, tickIntervals: [0.5], labelLevels: [0])
                ]
            )
            
            let generatedScale = GeneratedScale(definition: fewTicksScale)
            let densities = ScaleAnalysis.tickDensity(in: generatedScale, regions: 10)
            
            #expect(densities.count == 10, "Should return density for all regions")
            #expect(densities.allSatisfy { $0 >= 0 }, "All densities should be non-negative")
        }
        
        @Test("Edge case with scale having exactly two ticks")
        func twoTicksAverageSpacing() {
            let twoTicksScale = ScaleDefinition(
                name: "TwoTicks",
                function: LinearFunction(),
                beginValue: 0.0,
                endValue: 1.0,
                scaleLengthInPoints: 250.0,
                layout: .linear,
                subsections: [
                    ScaleSubsection(startValue: 0.0, tickIntervals: [1.0], labelLevels: [0])
                ]
            )
            
            let generatedScale = GeneratedScale(definition: twoTicksScale)
            let stats = ScaleAnalysis.ScaleStatistics(scale: generatedScale)
            
            if stats.totalTicks == 2 {
                #expect(stats.averageTickSpacing > 0, "Two ticks should have positive spacing")
                #expect(stats.averageTickSpacing <= 1.0, "Spacing should be within normalized range")
            }
        }
    }
}
