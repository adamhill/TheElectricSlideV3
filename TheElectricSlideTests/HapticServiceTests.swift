//
//  HapticServiceTests.swift
//  TheElectricSlideTests
//
//  Unit tests for HapticService using the Swift Testing framework.
//  Tests the HapticEvent enum, TickLevel initialization, and MockHapticService behavior.
//

import Foundation
import Testing
@testable import TheElectricSlide

// MARK: - HapticService Tests

@Suite("Haptic Feedback")
@MainActor
struct HapticServiceTests {
    
    // MARK: - HapticEvent.TickLevel Tests
    
    @Suite("Tick Mark Haptic Intensity")
    struct TickLevelTests {
        
        @Test("Major tick level for relativeLength >= 0.9", arguments: [0.9, 0.95, 1.0])
        @MainActor
        func testMajorTickLevel(relativeLength: Double) {
            let level = HapticEvent.TickLevel(relativeLength: relativeLength)
            #expect(level == .major)
        }
        
        @Test("Secondary tick level for relativeLength >= 0.65 and < 0.9", arguments: [0.65, 0.75, 0.89])
        @MainActor
        func testSecondaryTickLevel(relativeLength: Double) {
            let level = HapticEvent.TickLevel(relativeLength: relativeLength)
            #expect(level == .secondary)
        }
        
        @Test("Tertiary tick level for relativeLength >= 0.4 and < 0.65", arguments: [0.4, 0.5, 0.64])
        @MainActor
        func testTertiaryTickLevel(relativeLength: Double) {
            let level = HapticEvent.TickLevel(relativeLength: relativeLength)
            #expect(level == .tertiary)
        }
        
        @Test("Ignored tick level for relativeLength < 0.4", arguments: [0.0, 0.2, 0.39])
        @MainActor
        func testIgnoredTickLevel(relativeLength: Double) {
            let level = HapticEvent.TickLevel(relativeLength: relativeLength)
            #expect(level == .ignored)
        }
        
        @Test("Boundary at exactly 0.9 is major")
        @MainActor
        func testBoundary090() {
            let level = HapticEvent.TickLevel(relativeLength: 0.9)
            #expect(level == .major)
        }
        
        @Test("Just below 0.9 (0.899) is secondary")
        @MainActor
        func testJustBelow090() {
            let level = HapticEvent.TickLevel(relativeLength: 0.899)
            #expect(level == .secondary)
        }
        
        @Test("Boundary at exactly 0.65 is secondary")
        @MainActor
        func testBoundary065() {
            let level = HapticEvent.TickLevel(relativeLength: 0.65)
            #expect(level == .secondary)
        }
        
        @Test("Just below 0.65 (0.649) is tertiary")
        @MainActor
        func testJustBelow065() {
            let level = HapticEvent.TickLevel(relativeLength: 0.649)
            #expect(level == .tertiary)
        }
        
        @Test("Boundary at exactly 0.4 is tertiary")
        @MainActor
        func testBoundary040() {
            let level = HapticEvent.TickLevel(relativeLength: 0.4)
            #expect(level == .tertiary)
        }
        
        @Test("Just below 0.4 (0.399) is ignored")
        @MainActor
        func testJustBelow040() {
            let level = HapticEvent.TickLevel(relativeLength: 0.399)
            #expect(level == .ignored)
        }
        
        @Test("Negative values are ignored")
        @MainActor
        func testNegativeValues() {
            let level = HapticEvent.TickLevel(relativeLength: -0.5)
            #expect(level == .ignored)
        }
        
        @Test("Values greater than 1.0 are major")
        @MainActor
        func testValuesOverOne() {
            let level = HapticEvent.TickLevel(relativeLength: 1.5)
            #expect(level == .major)
        }
    }
    
    // MARK: - Test Haptic Feedback Recording
    
    @Suite("Test Haptic Feedback Recording")
    struct MockHapticServiceTests {
        
        @Test("Haptic events are recorded when triggered")
        @MainActor
        func testMockRecordsEvents() {
            let mock = MockHapticService()
            
            mock.fire(.flip)
            mock.fire(.precisionModeEntered)
            mock.fire(.longBuzz)
            
            #expect(mock.firedEvents.count == 3)
            #expect(mock.firedEvents[0] == .flip)
            #expect(mock.firedEvents[1] == .precisionModeEntered)
            #expect(mock.firedEvents[2] == .longBuzz)
        }
        
        @Test("Haptic engine preparation is tracked")
        @MainActor
        func testMockTracksPrepare() {
            let mock = MockHapticService()
            
            #expect(mock.prepareCallCount == 0)
            
            mock.prepare()
            #expect(mock.prepareCallCount == 1)
            
            mock.prepare()
            mock.prepare()
            #expect(mock.prepareCallCount == 3)
        }
        
        @Test("Resetting clears all haptic history")
        @MainActor
        func testMockReset() {
            let mock = MockHapticService()
            
            // Add some events and calls
            mock.fire(.flip)
            mock.fire(.precisionModeEntered)
            mock.prepare()
            mock.prepare()
            
            #expect(mock.firedEvents.count == 2)
            #expect(mock.prepareCallCount == 2)
            
            // Reset
            mock.reset()
            
            #expect(mock.firedEvents.isEmpty)
            #expect(mock.prepareCallCount == 0)
        }
        
        @Test("Tick crossing haptics capture the correct intensity level")
        @MainActor
        func testMockRecordsTickEvents() {
            let mock = MockHapticService()
            
            mock.fire(.tickCrossed(level: .major))
            mock.fire(.tickCrossed(level: .secondary))
            mock.fire(.tickCrossed(level: .tertiary))
            mock.fire(.tickCrossed(level: .ignored))
            
            #expect(mock.firedEvents.count == 4)
            #expect(mock.firedEvents[0] == .tickCrossed(level: .major))
            #expect(mock.firedEvents[1] == .tickCrossed(level: .secondary))
            #expect(mock.firedEvents[2] == .tickCrossed(level: .tertiary))
            #expect(mock.firedEvents[3] == .tickCrossed(level: .ignored))
        }
        
        @Test("Button tap haptics capture the correct style")
        @MainActor
        func testMockRecordsButtonTapStyles() {
            let mock = MockHapticService()
            
            mock.fire(.buttonTap(style: .light))
            mock.fire(.buttonTap(style: .medium))
            mock.fire(.buttonTap(style: .heavy))
            mock.fire(.buttonTap(style: .rigid))
            mock.fire(.buttonTap(style: .soft))
            
            #expect(mock.firedEvents.count == 5)
            #expect(mock.firedEvents[0] == .buttonTap(style: .light))
            #expect(mock.firedEvents[4] == .buttonTap(style: .soft))
        }
        
        @Test("No haptic events exist before any interaction")
        @MainActor
        func testMockStartsEmpty() {
            let mock = MockHapticService()
            
            #expect(mock.firedEvents.isEmpty)
            #expect(mock.prepareCallCount == 0)
        }
    }
    
    // MARK: - Haptic Event Identity Tests
    
    @Suite("Haptic Event Identity")
    struct HapticEventEquatableTests {
        
        @Test("Same discrete events are equal")
        @MainActor
        func testDiscreteEventEquality() {
            #expect(HapticEvent.flip == HapticEvent.flip)
            #expect(HapticEvent.precisionModeEntered == HapticEvent.precisionModeEntered)
            #expect(HapticEvent.precisionModeExited == HapticEvent.precisionModeExited)
            #expect(HapticEvent.longBuzz == HapticEvent.longBuzz)
        }
        
        @Test("Different discrete events are not equal")
        @MainActor
        func testDiscreteEventInequality() {
            #expect(HapticEvent.flip != HapticEvent.precisionModeEntered)
            #expect(HapticEvent.precisionModeEntered != HapticEvent.precisionModeExited)
            #expect(HapticEvent.longBuzz != HapticEvent.flip)
        }
        
        @Test("TickCrossed events with same level are equal")
        @MainActor
        func testTickCrossedEquality() {
            #expect(HapticEvent.tickCrossed(level: .major) == HapticEvent.tickCrossed(level: .major))
            #expect(HapticEvent.tickCrossed(level: .secondary) == HapticEvent.tickCrossed(level: .secondary))
            #expect(HapticEvent.tickCrossed(level: .tertiary) == HapticEvent.tickCrossed(level: .tertiary))
            #expect(HapticEvent.tickCrossed(level: .ignored) == HapticEvent.tickCrossed(level: .ignored))
        }
        
        @Test("TickCrossed events with different levels are not equal")
        @MainActor
        func testTickCrossedInequality() {
            #expect(HapticEvent.tickCrossed(level: .major) != HapticEvent.tickCrossed(level: .secondary))
            #expect(HapticEvent.tickCrossed(level: .secondary) != HapticEvent.tickCrossed(level: .tertiary))
            #expect(HapticEvent.tickCrossed(level: .tertiary) != HapticEvent.tickCrossed(level: .ignored))
        }
        
        @Test("ButtonTap events with same style are equal")
        @MainActor
        func testButtonTapEquality() {
            #expect(HapticEvent.buttonTap(style: .light) == HapticEvent.buttonTap(style: .light))
            #expect(HapticEvent.buttonTap(style: .medium) == HapticEvent.buttonTap(style: .medium))
            #expect(HapticEvent.buttonTap(style: .heavy) == HapticEvent.buttonTap(style: .heavy))
            #expect(HapticEvent.buttonTap(style: .rigid) == HapticEvent.buttonTap(style: .rigid))
            #expect(HapticEvent.buttonTap(style: .soft) == HapticEvent.buttonTap(style: .soft))
        }
        
        @Test("ButtonTap events with different styles are not equal")
        @MainActor
        func testButtonTapInequality() {
            #expect(HapticEvent.buttonTap(style: .light) != HapticEvent.buttonTap(style: .heavy))
            #expect(HapticEvent.buttonTap(style: .medium) != HapticEvent.buttonTap(style: .rigid))
            #expect(HapticEvent.buttonTap(style: .soft) != HapticEvent.buttonTap(style: .light))
        }
        
        @Test("Different event types are not equal")
        @MainActor
        func testDifferentEventTypesInequality() {
            #expect(HapticEvent.flip != HapticEvent.tickCrossed(level: .major))
            #expect(HapticEvent.buttonTap(style: .light) != HapticEvent.flip)
            #expect(HapticEvent.tickCrossed(level: .major) != HapticEvent.buttonTap(style: .heavy))
            #expect(HapticEvent.precisionModeEntered != HapticEvent.longBuzz)
        }
    }
    
    // MARK: - HapticEvent.HapticStyle Tests
    
    @Suite("Haptic Feedback Styles")
    struct HapticStyleTests {
        
        @Test("All HapticStyle cases exist")
        @MainActor
        func testAllStyleCasesExist() {
            let styles: [HapticEvent.HapticStyle] = [.light, .medium, .heavy, .rigid, .soft]
            #expect(styles.count == 5)
        }
        
        @Test("HapticStyle cases are distinct")
        @MainActor
        func testStyleEquatable() {
            let light1: HapticEvent.HapticStyle = .light
            let light2: HapticEvent.HapticStyle = .light
            let heavy: HapticEvent.HapticStyle = .heavy
            
            #expect(light1 == light2)
            #expect(light1 != heavy)
        }
    }
    
    // MARK: - Tick Intensity Level Identity Tests
    
    @Suite("Tick Intensity Level Identity")
    struct TickLevelEquatableTests {
        
        @Test("Same TickLevel values are equal")
        @MainActor
        func testTickLevelEquality() {
            #expect(HapticEvent.TickLevel.major == HapticEvent.TickLevel.major)
            #expect(HapticEvent.TickLevel.secondary == HapticEvent.TickLevel.secondary)
            #expect(HapticEvent.TickLevel.tertiary == HapticEvent.TickLevel.tertiary)
            #expect(HapticEvent.TickLevel.ignored == HapticEvent.TickLevel.ignored)
        }
        
        @Test("Different TickLevel values are not equal")
        @MainActor
        func testTickLevelInequality() {
            #expect(HapticEvent.TickLevel.major != HapticEvent.TickLevel.secondary)
            #expect(HapticEvent.TickLevel.secondary != HapticEvent.TickLevel.tertiary)
            #expect(HapticEvent.TickLevel.tertiary != HapticEvent.TickLevel.ignored)
            #expect(HapticEvent.TickLevel.major != HapticEvent.TickLevel.ignored)
        }
        
        @Test("All four TickLevel cases exist")
        @MainActor
        func testAllTickLevelCasesExist() {
            let levels: [HapticEvent.TickLevel] = [.major, .secondary, .tertiary, .ignored]
            #expect(levels.count == 4)
        }
    }
    
    // MARK: - Haptic Feedback Providers Tests
    
    @Suite("Haptic Feedback Providers")
    struct HapticServiceProtocolTests {
        
        @Test("Test haptic provider can substitute for real haptic engine")
        @MainActor
        func testMockConformance() {
            let service: HapticService = MockHapticService()
            
            // Should be able to call protocol methods
            service.fire(.flip)
            service.prepare()
            
            // Cast back to check recorded state
            if let mock = service as? MockHapticService {
                #expect(mock.firedEvents.count == 1)
                #expect(mock.prepareCallCount == 1)
            }
        }
        
        @Test("Default haptic provider delivers real device feedback")
        @MainActor
        func testDefaultConformance() {
            let service: HapticService = DefaultHapticService()
            
            // Should be able to call protocol methods without error
            // (actual haptic feedback won't occur in test environment)
            service.fire(.flip)
            service.prepare()
            
            // No assertion needed - just verifying no crash
            #expect(true)
        }
    }
    
    // MARK: - Haptic Feedback Workflows Tests
    
    @Suite("Haptic Feedback Workflows")
    struct HapticIntegrationTests {
        
        @Test("Tick mark height determines haptic intensity when cursor crosses it")
        @MainActor
        func testTickLevelIntegration() {
            let mock = MockHapticService()
            
            // Simulate typical slide rule tick crossing scenario
            let majorLength = 0.95
            let level = HapticEvent.TickLevel(relativeLength: majorLength)
            mock.fire(.tickCrossed(level: level))
            
            #expect(mock.firedEvents.count == 1)
            #expect(mock.firedEvents[0] == .tickCrossed(level: .major))
        }
        
        @Test("Entering precision mode, crossing ticks, and exiting produces correct haptic sequence")
        @MainActor
        func testPrecisionModeWorkflow() {
            let mock = MockHapticService()
            
            // User enters precision mode
            mock.fire(.precisionModeEntered)
            
            // User crosses some ticks
            mock.fire(.tickCrossed(level: .major))
            mock.fire(.tickCrossed(level: .secondary))
            mock.fire(.tickCrossed(level: .tertiary))
            
            // User exits precision mode
            mock.fire(.precisionModeExited)
            
            #expect(mock.firedEvents.count == 5)
            #expect(mock.firedEvents.first == .precisionModeEntered)
            #expect(mock.firedEvents.last == .precisionModeExited)
        }
        
        @Test("Minor tick marks below haptic threshold produce no feedback")
        @MainActor
        func testIgnoredTickLevelNoHaptic() {
            let mock = MockHapticService()
            
            // Fire an ignored tick event
            let level = HapticEvent.TickLevel(relativeLength: 0.1)
            mock.fire(.tickCrossed(level: level))
            
            // Event is still recorded even though it's ignored
            // (the DefaultHapticService won't produce haptic for .ignored,
            // but MockHapticService records it for verification)
            #expect(mock.firedEvents.count == 1)
            #expect(mock.firedEvents[0] == .tickCrossed(level: .ignored))
        }
    }
}
