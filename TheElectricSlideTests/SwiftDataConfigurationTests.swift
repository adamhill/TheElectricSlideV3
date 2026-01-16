//
//  SwiftDataConfigurationTests.swift
//  TheElectricSlideTests
//
//  Created by Adam Hill on 1/16/26.
//
//  Tests for Phase 6: SwiftData Integration of Scale Configuration API
//

import Testing
import Foundation
@testable import TheElectricSlide
@testable import SlideRuleCoreV3

/// Tests for SwiftData integration of SlideRuleConfiguration
@Suite("SwiftData Configuration Integration")
struct SwiftDataConfigurationTests {
    
    // MARK: - Configuration JSON Persistence
    
    @Suite("Configuration JSON Encoding/Decoding")
    struct JSONPersistenceTests {
        
        @Test("Configuration round-trips through JSON correctly")
        func configurationRoundTrip() throws {
            // Build a configuration with various settings
            let original = SlideRuleConfigurationBuilder()
                .hideFormulas()
                .suppressEvenScaleNames()
                .addNameOverrides(["C": "Custom C", "D": "Custom D"])
                .addAnnotation(
                    ComponentAnnotation(
                        content: .text("Test annotation"),
                        color: LabelColor(red: 1, green: 0, blue: 0, alpha: 1),
                        horizontalPosition: 0.5,
                        verticalPosition: 0.5,
                        anchor: .center,
                        fontSize: 12,
                        fontWeight: .medium,
                        textAlignment: .center
                    ),
                    on: .back
                )
                .build()
            
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(original)
            let json = String(data: data, encoding: .utf8)
            
            #expect(json != nil, "JSON encoding should succeed")
            
            // Decode back
            let decoded = try JSONDecoder().decode(SlideRuleConfiguration.self, from: data)
            
            // Verify key properties preserved
            #expect(decoded.displaySettings.showFormulas == false)
            #expect(decoded.scaleNameOverrides["C"] == "Custom C")
            #expect(decoded.scaleNameOverrides["D"] == "Custom D")
            #expect(decoded.ruleAnnotations[.back]?.count == 1)
        }
        
        @Test("Empty configuration encodes correctly")
        func emptyConfigurationEncoding() throws {
            let config = SlideRuleConfiguration()
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)
            let decoded = try JSONDecoder().decode(SlideRuleConfiguration.self, from: data)
            
            #expect(decoded.displaySettings.showScaleNames == true)
            #expect(decoded.displaySettings.showFormulas == true)
            #expect(decoded.scaleNameOverrides.isEmpty)
            #expect(decoded.componentConfigs.isEmpty)
        }
        
        @Test("Configuration with nudge preserves nudge values")
        func nudgePreservation() throws {
            let annotation = ComponentAnnotation(
                content: .text("Nudged"),
                color: LabelColor(red: 0, green: 0, blue: 0, alpha: 1),
                horizontalPosition: 0.5,
                verticalPosition: 0.5,
                anchor: .center,
                fontSize: 10,
                fontWeight: .regular,
                textAlignment: .center,
                nudge: PositionNudge.left(15)
            )
            
            let config = SlideRuleConfigurationBuilder()
                .addAnnotation(annotation, on: .front)
                .build()
            
            let data = try JSONEncoder().encode(config)
            let decoded = try JSONDecoder().decode(SlideRuleConfiguration.self, from: data)
            
            let decodedAnnotation = try #require(decoded.ruleAnnotations[.front]?.first)
            #expect(decodedAnnotation.nudge == PositionNudge.left(15))
        }
    }
    
    // MARK: - SlideRuleDefinitionModel Integration
    
    @Suite("SlideRuleDefinitionModel Configuration Property")
    struct ModelIntegrationTests {
        
        @Test("Model stores configuration via JSON property")
        func modelStoresConfiguration() {
            let config = SlideRuleConfigurationBuilder()
                .hideFormulas()
                .addNameOverrides(["K": "K-scale"])
                .build()
            
            let model = SlideRuleDefinitionModel(
                name: "Test Rule",
                description: "Test description",
                definitionString: "(K A [ B CI C ] D)",
                configuration: config
            )
            
            // Verify JSON was stored
            #expect(model.configurationJSON != nil)
            
            // Verify configuration can be read back
            #expect(model.configuration.displaySettings.showFormulas == false)
            #expect(model.configuration.scaleNameOverrides["K"] == "K-scale")
        }
        
        @Test("Model without configuration returns migrated defaults")
        func modelWithoutConfigurationMigrates() {
            let model = SlideRuleDefinitionModel(
                name: "Legacy Rule",
                description: "Created without configuration",
                definitionString: "(DF [ CF CI C ] D)",
                showScaleNames: true,
                showFormulas: false,
                suppressEvenScaleNames: true
            )
            
            // Should migrate legacy values
            let config = model.configuration
            #expect(config.displaySettings.showScaleNames == true)
            #expect(config.displaySettings.showFormulas == false)
            // suppressEvenScaleNames creates component configs
            #expect(!config.componentConfigs.isEmpty)
        }
        
        @Test("Setting configuration property updates JSON")
        func settingConfigurationUpdatesJSON() {
            let model = SlideRuleDefinitionModel(
                name: "Test Rule",
                description: "Test",
                definitionString: "(C D)"
            )
            
            // Initially no JSON
            let initialJSON = model.configurationJSON
            
            // Set new configuration
            let newConfig = SlideRuleConfigurationBuilder()
                .hideScaleNames()
                .build()
            model.configuration = newConfig
            
            // JSON should be updated
            #expect(model.configurationJSON != initialJSON)
            #expect(model.configuration.displaySettings.showScaleNames == false)
        }
        
        @Test("Computed showScaleNames reads from configuration")
        func showScaleNamesReadsFromConfiguration() {
            let config = SlideRuleConfigurationBuilder()
                .hideScaleNames()
                .build()
            
            let model = SlideRuleDefinitionModel(
                name: "Test",
                description: "Test",
                definitionString: "(C D)",
                configuration: config
            )
            
            #expect(model.showScaleNames == false)
        }
        
        @Test("Computed showFormulas reads from configuration")
        func showFormulasReadsFromConfiguration() {
            let config = SlideRuleConfigurationBuilder()
                .hideFormulas()
                .build()
            
            let model = SlideRuleDefinitionModel(
                name: "Test",
                description: "Test",
                definitionString: "(C D)",
                configuration: config
            )
            
            #expect(model.showFormulas == false)
        }
    }
    
    // MARK: - Migration Tests
    
    @Suite("Legacy Property Migration")
    struct MigrationTests {
        
        @Test("migrateToConfiguration converts legacy properties")
        func migrateToConfigurationWorks() {
            let model = SlideRuleDefinitionModel(
                name: "Legacy",
                description: "Legacy rule",
                definitionString: "(A [ B C ] D)",
                showScaleNames: true,
                showFormulas: false,
                suppressEvenScaleNames: true
            )
            
            // Clear any auto-generated JSON for testing
            // (In real usage, models created with legacy init won't have configurationJSON)
            
            // Get migrated configuration
            let config = model.configuration
            
            #expect(config.displaySettings.showScaleNames == true)
            #expect(config.displaySettings.showFormulas == false)
        }
        
        @Test("Scale name overrides migrate to configuration")
        func scaleNameOverridesMigrate() {
            let model = SlideRuleDefinitionModel(
                name: "With Overrides",
                description: "Has name overrides",
                definitionString: "(C D)",
                scaleNameOverrides: ["C": "Custom-C", "D": "Custom-D"]
            )
            
            let config = model.configuration
            #expect(config.scaleNameOverrides["C"] == "Custom-C")
            #expect(config.scaleNameOverrides["D"] == "Custom-D")
        }
        
        @Test("Back slide annotations migrate to configuration")
        func backSlideAnnotationsMigrate() throws {
            // Create annotation JSON manually (simulating legacy data)
            let annotation = ComponentAnnotation(
                content: .text("Legacy annotation"),
                color: LabelColor(red: 0, green: 0, blue: 0, alpha: 1),
                horizontalPosition: 0.9,
                verticalPosition: 0.5,
                anchor: .trailing,
                fontSize: 10,
                fontWeight: .regular,
                textAlignment: .leading
            )
            let annotationsJSON = try {
                let data = try JSONEncoder().encode([annotation])
                return String(data: data, encoding: .utf8)
            }()
            
            let model = SlideRuleDefinitionModel(
                name: "With Annotations",
                description: "Has back slide annotations",
                definitionString: "(C D : E F)",
                backSlideAnnotationsJSON: annotationsJSON
            )
            
            let config = model.configuration
            let backAnnotations = config.ruleAnnotations[.back]
            #expect(backAnnotations?.count == 1)
        }
    }
    
    // MARK: - ParseSlideRule Integration
    
    @Suite("ParseSlideRule with Configuration")
    struct ParseSlideRuleTests {
        
        @Test("parseSlideRule applies configuration display settings")
        func parseAppliesDisplaySettings() throws {
            let config = SlideRuleConfigurationBuilder()
                .hideFormulas()
                .build()
            
            let model = SlideRuleDefinitionModel(
                name: "Test",
                description: "Test",
                definitionString: "(DF [ CF CI C ] D)",
                configuration: config
            )
            
            let rule = try model.parseSlideRule()
            
            #expect(rule.displaySettings.showFormulas == false)
        }
        
        @Test("parseSlideRule applies scale name overrides")
        func parseAppliesNameOverrides() throws {
            let config = SlideRuleConfigurationBuilder()
                .addNameOverrides(["C": "Renamed-C"])
                .build()
            
            let model = SlideRuleDefinitionModel(
                name: "Test",
                description: "Test",
                definitionString: "([ C ] D)",
                configuration: config
            )
            
            let rule = try model.parseSlideRule()
            
            // Find the C scale and check its name was overridden
            let cScale = rule.frontSlide.scales.first { $0.definition.name == "Renamed-C" }
            #expect(cScale != nil, "C scale should be renamed to 'Renamed-C'")
        }
        
        @Test("parseSlideRule applies back slide annotations")
        func parseAppliesAnnotations() throws {
            let annotation = ComponentAnnotation(
                content: .text("Test annotation"),
                color: LabelColor(red: 0, green: 0, blue: 0, alpha: 1),
                horizontalPosition: 0.5,
                verticalPosition: 0.5,
                anchor: .center,
                fontSize: 10,
                fontWeight: .regular,
                textAlignment: .center
            )
            
            let config = SlideRuleConfigurationBuilder()
                .addAnnotation(annotation, on: .back)
                .build()
            
            let model = SlideRuleDefinitionModel(
                name: "Test",
                description: "Test",
                definitionString: "(C [ D ] A : K [ L ] S)",  // Has back side with slide
                configuration: config
            )
            
            let rule = try model.parseSlideRule()
            
            let backSlide = try #require(rule.backSlide)
            #expect(backSlide.annotations.count >= 1)
        }
    }
    
    // MARK: - Library Integration
    
    @Suite("SlideRuleLibrary Configuration Integration")
    @MainActor
    struct LibraryTests {
        
        @Test("Annotation Test rule uses Configuration API")
        func annotationTestUsesConfigAPI() {
            let rule = SlideRuleLibrary.pickettN16ESAnnotationTest()
            
            // Should have configurationJSON set
            #expect(rule.configurationJSON != nil)
            
            // Configuration should have expected values
            let config = rule.configuration
            #expect(config.displaySettings.showFormulas == false)
            #expect(!config.scaleNameOverrides.isEmpty)
            #expect(config.ruleAnnotations[.back]?.isEmpty == false)
        }
        
        @Test("Annotation Test rule parses successfully")
        func annotationTestParses() throws {
            let model = SlideRuleLibrary.pickettN16ESAnnotationTest()
            let rule = try model.parseSlideRule()
            
            #expect(rule.displaySettings.showFormulas == false)
            
            // Back slide should have annotations
            let backSlide = try #require(rule.backSlide)
            #expect(!backSlide.annotations.isEmpty)
        }
    }
}
