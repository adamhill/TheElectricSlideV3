import Testing
@testable import SlideRuleCoreV3

/// Debugging test for THETA small angle scale missing labels at 5.71° and 5°
struct ThetaSmallScaleDebugTests {
    
    @Test("THETA small scale generates tick at 5.71°")
    func thetaSmallHasTickAt571() {
        // Generate the THETA small scale
        let thetaSmall = StandardScales.phaseAngleThetaSmallScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: thetaSmall)
        
        // Check if there's a tick at 5.71°
        let tick571 = ticks.first { abs($0.value - 5.71) < 0.001 }
        
        #expect(tick571 != nil, "Should have a tick at 5.71°")
        
        if let tick = tick571 {
            print("✓ Found tick at 5.71°:")
            print("  - Value: \(tick.value)")
            print("  - Position: \(tick.normalizedPosition)")
            print("  - Style: \(tick.style)")
            print("  - Label: \(tick.label ?? "nil")")
            print("  - Labels: \(tick.labels)")
            
            // Verify this tick should have a label
            #expect(!tick.labels.isEmpty, "Tick at 5.71° should have labels")
        }
    }
    
    @Test("THETA small scale generates tick at 5.0°")
    func thetaSmallHasTickAt5() {
        // Generate the THETA small scale
        let thetaSmall = StandardScales.phaseAngleThetaSmallScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: thetaSmall)
        
        // Check if there's a tick at 5.0°
        let tick5 = ticks.first { abs($0.value - 5.0) < 0.001 }
        
        #expect(tick5 != nil, "Should have a tick at 5.0°")
        
        if let tick = tick5 {
            print("✓ Found tick at 5.0°:")
            print("  - Value: \(tick.value)")
            print("  - Position: \(tick.normalizedPosition)")
            print("  - Style: \(tick.style)")
            print("  - Label: \(tick.label ?? "nil")")
            print("  - Labels: \(tick.labels)")
            
            // Verify this tick should have a label
            #expect(!tick.labels.isEmpty, "Tick at 5.0° should have labels")
        }
    }
    
    @Test("THETA small scale - first subsection tick generation")
    func thetaSmallFirstSubsectionTicks() {
        // Generate the THETA small scale
        let thetaSmall = StandardScales.phaseAngleThetaSmallScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: thetaSmall)
        
        // First subsection is 5.71° → 5.0° with intervals [1.0, 0.5, 0.2, 0.1]
        // Major ticks (level 0) are at 1.0 intervals
        // So we should have a tick at 5.71°
        
        print("\n=== First Subsection (5.71° → 5.0°) ===")
        let firstSubsectionTicks = ticks.filter { $0.value >= 5.0 && $0.value <= 5.71 }
        print("Found \(firstSubsectionTicks.count) ticks in range [5.0, 5.71]:")
        
        for tick in firstSubsectionTicks.sorted(by: { $0.value > $1.value }) {
            print("  - \(String(format: "%.3f", tick.value))° at position \(String(format: "%.6f", tick.normalizedPosition))")
            if !tick.labels.isEmpty {
                print("    Labels: \(tick.labels.map { "\($0.text) (\($0.position))" }.joined(separator: ", "))")
            } else {
                print("    NO LABELS")
            }
        }
        
        // Verify we have at least 2 ticks (5.71 and 5.0)
        #expect(firstSubsectionTicks.count >= 2, "Should have at least 2 ticks in first subsection")
    }
    
    @Test("THETA small scale - second subsection tick generation")
    func thetaSmallSecondSubsectionTicks() {
        // Generate the THETA small scale
        let thetaSmall = StandardScales.phaseAngleThetaSmallScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: thetaSmall)
        
        // Second subsection is 5.0° → 4.0° with intervals [1.0, 0.5, 0.2, 0.1]
        // Major ticks (level 0) are at 1.0 intervals
        // So we should have ticks at 5.0° and 4.0°
        
        print("\n=== Second Subsection (5.0° → 4.0°) ===")
        let secondSubsectionTicks = ticks.filter { $0.value >= 4.0 && $0.value <= 5.0 }
        print("Found \(secondSubsectionTicks.count) ticks in range [4.0, 5.0]:")
        
        for tick in secondSubsectionTicks.sorted(by: { $0.value > $1.value }) {
            print("  - \(String(format: "%.3f", tick.value))° at position \(String(format: "%.6f", tick.normalizedPosition))")
            if !tick.labels.isEmpty {
                print("    Labels: \(tick.labels.map { "\($0.text) (\($0.position))" }.joined(separator: ", "))")
            } else {
                print("    NO LABELS")
            }
        }
        
        // Verify we have labeled ticks at 5.0 and 4.0
        let labeled = secondSubsectionTicks.filter { !$0.labels.isEmpty }
        #expect(labeled.count >= 2, "Should have at least 2 labeled ticks in second subsection")
    }
    
    @Test("THETA small scale - all labeled ticks")
    func thetaSmallAllLabeledTicks() {
        // Generate the THETA small scale
        let thetaSmall = StandardScales.phaseAngleThetaSmallScale(length: 250.0)
        let ticks = ScaleCalculator.generateTickMarks(for: thetaSmall)
        
        print("\n=== All Labeled Ticks on THETA Small Scale ===")
        let labeledTicks = ticks.filter { !$0.labels.isEmpty }
        print("Found \(labeledTicks.count) labeled ticks total:")
        
        for tick in labeledTicks.sorted(by: { $0.value > $1.value }) {
            let labels = tick.labels.map { "\($0.text) (\($0.color))" }.joined(separator: ", ")
            print("  - \(String(format: "%.3f", tick.value))° at position \(String(format: "%.6f", tick.normalizedPosition))")
            print("    Labels: \(labels)")
        }
        
        // Check specifically for 5.71° and 5.0°
        let has571 = labeledTicks.contains { abs($0.value - 5.71) < 0.001 }
        let has5 = labeledTicks.contains { abs($0.value - 5.0) < 0.001 }
        
        print("\n=== Missing Labels Check ===")
        print("Has label at 5.71°: \(has571)")
        print("Has label at 5.0°: \(has5)")
        
        #expect(has571, "Should have label at 5.71°")
        #expect(has5, "Should have label at 5.0°")
    }
    
    @Test("THETA small scale - subsection boundaries")
    func thetaSmallSubsectionBoundaries() {
        let thetaSmall = StandardScales.phaseAngleThetaSmallScale(length: 250.0)
        
        print("\n=== THETA Small Scale Subsection Configuration ===")
        print("Scale range: \(thetaSmall.beginValue) → \(thetaSmall.endValue)")
        print("Number of subsections: \(thetaSmall.subsections.count)")
        print("")
        
        for (i, subsection) in thetaSmall.subsections.enumerated() {
            let nextStart = (i < thetaSmall.subsections.count - 1) 
                ? thetaSmall.subsections[i + 1].startValue 
                : thetaSmall.endValue
            
            print("Subsection \(i): \(subsection.startValue) → \(nextStart)")
            print("  Intervals: \(subsection.tickIntervals)")
            print("  Label Levels: \(subsection.labelLevels)")
            print("  Has dual formatter: \(subsection.dualLabelFormatter != nil)")
        }
    }
    
    @Test("THETA label formatter test with 5.71° and 5.0°")
    func thetaLabelFormatterTest() {
        print("\n=== Testing THETA Label Formatter ===")
        
        // Test the formatter directly
        let labels571 = StandardLabelFormatter.thetaScaleDual(value: 5.71)
        print("\nLabels for 5.71°:")
        for label in labels571 {
            print("  - '\(label.text)' at \(label.position), color: \(label.color)")
        }
        
        let labels5 = StandardLabelFormatter.thetaScaleDual(value: 5.0)
        print("\nLabels for 5.0°:")
        for label in labels5 {
            print("  - '\(label.text)' at \(label.position), color: \(label.color)")
        }
        
        // Verify structure
        #expect(labels571.count == 2, "Should have 2 labels for 5.71°")
        #expect(labels5.count == 2, "Should have 2 labels for 5.0°")
        
        // Check that labels are non-empty
        #expect(!labels571[0].text.isEmpty, "First label for 5.71° should not be empty")
        #expect(!labels571[1].text.isEmpty, "Second label for 5.71° should not be empty")
        #expect(!labels5[0].text.isEmpty, "First label for 5.0° should not be empty")
        #expect(!labels5[1].text.isEmpty, "Second label for 5.0° should not be empty")
    }
}
