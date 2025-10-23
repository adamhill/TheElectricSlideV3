import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Comprehensive tick mark generation tests for the L scale (Linear scale for mantissas)
/// PostScript Reference: postscript-engine-for-sliderules.ps:1136-1142
///
/// L scale characteristics:
/// - Function: Linear (identity) f(x) = x
/// - Range: 0 to 1
/// - Title: "L"
/// - One subsection covering entire range: 0 [.1 .05 .01 .002] [plabel]
/// - Tick intervals: Primary 0.1, Secondary 0.05, Tertiary 0.01, Quaternary 0.002
@Suite("L Scale Tick Mark Generation Tests")
struct LScaleTickMarkTests {
    
    private let lScale = StandardScales.lScale(length: 250.0)
    
    // MARK: - Basic Scale Properties
    @Test("L scale has correct basic properties")
    func lScaleBasicProperties() {
        #expect(lScale.name == "L")
        #expect(lScale.beginValue == 0.0)
        #expect(lScale.endValue == 1.0)
        #expect(lScale.scaleLengthInPoints == 250.0)
        #expect(lScale.function is LinearFunction)
        // PostScript reference line 1138: tickdir=1 means UP
        #expect(lScale.tickDirection == .up, "L scale should have ticks pointing up per PostScript")
    }
    
    @Test("L scale has exactly one subsection covering full range")
    func lScaleSubsectionCount() {
        #expect(lScale.subsections.count == 1)
        
        if let subsection = lScale.subsections.first {
            #expect(subsection.startValue == 0.0)
        }
    }
    
    @Test("L scale subsection has correct tick intervals")
    func lScaleTickIntervals() {
        guard let subsection = lScale.subsections.first else {
            Issue.record("L scale should have a subsection")
            return
        }
        
        // PostScript: [ .1 .05 .01 .002]
        #expect(subsection.tickIntervals.count == 4)
        #expect(subsection.tickIntervals[0] == 0.1)   // Primary (major)
        #expect(subsection.tickIntervals[1] == 0.05)  // Secondary (medium)
        #expect(subsection.tickIntervals[2] == 0.01)  // Tertiary (minor)
        #expect(subsection.tickIntervals[3] == 0.002) // Quaternary (tiny)
    }
    
    // MARK: - Tick Mark Generation Tests
    
    @Test("L scale generates major ticks at 0.1 intervals")
    func lScaleMajorTicks() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // Major ticks should be at: 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0
        let expectedMajorValues: [Double] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        
        let majorTicks = ticks.filter { $0.style == .major }
        
        #expect(majorTicks.count >= 11, "Expected at least 11 major ticks (0.0 to 1.0 at 0.1 intervals)")
        
        // Verify each expected major value exists
        for expectedValue in expectedMajorValues {
            let hasTick = majorTicks.contains { tick in
                abs(tick.value - expectedValue) < 1e-6
            }
            #expect(hasTick, "Missing major tick at value \(expectedValue)")
        }
    }
    
    @Test("L scale generates medium ticks at 0.05 intervals")
    func lScaleMediumTicks() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // Medium ticks at: 0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95
        let expectedMediumValues: [Double] = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95]
        
        let mediumTicks = ticks.filter { $0.style == .medium }
        
        #expect(mediumTicks.count >= 10, "Expected at least 10 medium ticks")
        
        // Verify each expected medium value exists
        for expectedValue in expectedMediumValues {
            let hasTick = mediumTicks.contains { tick in
                abs(tick.value - expectedValue) < 1e-6
            }
            #expect(hasTick, "Missing medium tick at value \(expectedValue)")
        }
    }
    
    @Test("L scale generates minor ticks at 0.01 intervals")
    func lScaleMinorTicks() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // Minor ticks every 0.01 from 0.0 to 1.0 (100 ticks total, excluding major/medium)
        let minorTicks = ticks.filter { $0.style == .minor }
        
        // We expect many minor ticks (at least 80, excluding overlaps with major/medium)
        #expect(minorTicks.count >= 80, "Expected at least 80 minor ticks at 0.01 intervals")
        
        // Check a sample of minor tick values
        let sampleMinorValues: [Double] = [0.01, 0.02, 0.03, 0.11, 0.22, 0.33, 0.44, 0.67, 0.88, 0.99]
        
        for expectedValue in sampleMinorValues {
            let hasTick = minorTicks.contains { tick in
                abs(tick.value - expectedValue) < 1e-6
            }
            #expect(hasTick, "Missing minor tick at value \(expectedValue)")
        }
    }
    
    @Test("L scale generates tiny ticks at 0.002 intervals")
    func lScaleTinyTicks() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // Tiny ticks every 0.002 from 0.0 to 1.0 (500 ticks total, excluding others)
        let tinyTicks = ticks.filter { $0.style == .tiny }
        
        // We expect many tiny ticks (at least 400, excluding overlaps)
        #expect(tinyTicks.count >= 400, "Expected at least 400 tiny ticks at 0.002 intervals")
        
        // Check a sample of tiny tick values
        let sampleTinyValues: [Double] = [0.002, 0.004, 0.006, 0.008, 0.012, 0.234, 0.456, 0.678, 0.892, 0.998]
        
        for expectedValue in sampleTinyValues {
            let hasTick = tinyTicks.contains { tick in
                abs(tick.value - expectedValue) < 1e-6
            }
            #expect(hasTick, "Missing tiny tick at value \(expectedValue)")
        }
    }
    
    @Test("L scale tick marks span full range 0 to 1")
    func lScaleTickRange() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        #expect(ticks.count > 0, "L scale should generate tick marks")
        
        let minValue = ticks.map { $0.value }.min() ?? 1.0
        let maxValue = ticks.map { $0.value }.max() ?? 0.0
        
        #expect(minValue <= 0.001, "Minimum tick value should be at or near 0.0")
        #expect(maxValue >= 0.999, "Maximum tick value should be at or near 1.0 (allowing for floating point precision)")
    }
    
    @Test("L scale tick hierarchy is correct")
    func lScaleTickHierarchy() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        let majorCount = ticks.filter { $0.style == .major }.count
        let mediumCount = ticks.filter { $0.style == .medium }.count
        let minorCount = ticks.filter { $0.style == .minor }.count
        let tinyCount = ticks.filter { $0.style == .tiny }.count
        
        // Verify hierarchy: tiny > minor > medium > major
        #expect(tinyCount > minorCount, "Should have more tiny ticks than minor")
        #expect(minorCount > mediumCount, "Should have more minor ticks than medium")
        #expect(mediumCount >= majorCount - 1, "Should have approximately equal or more medium ticks than major")
    }
    
    // MARK: - Position Calculation Tests
    
    @Test("L scale tick positions are linearly distributed")
    func lScaleLinearPositioning() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // For linear scale, position should equal value
        for tick in ticks {
            let expectedNormalizedPosition = tick.value
            #expect(abs(tick.normalizedPosition - expectedNormalizedPosition) < 1e-6,
                   "Tick at value \(tick.value) should be at normalized position \(expectedNormalizedPosition)")
        }
    }
    
    @Test("L scale major tick at 0.5 is at midpoint")
    func lScaleMidpointTick() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        let midpointTick = ticks.first { tick in
            abs(tick.value - 0.5) < 1e-6
        }
        
        guard let tick = midpointTick else {
            Issue.record("L scale should have a tick at 0.5")
            return
        }
        
        let expectedNormalizedPosition = 0.5
        #expect(abs(tick.normalizedPosition - expectedNormalizedPosition) < 1e-6,
               "Midpoint tick should be at normalized position \(expectedNormalizedPosition)")
    }
    
    @Test("L scale ticks at boundaries")
    func lScaleBoundaryTicks() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // Check for tick at 0.0
        let startTick = ticks.first { abs($0.value - 0.0) < 1e-6 }
        #expect(startTick != nil, "Should have tick at start (0.0)")
        
        // Check for tick at 1.0
        let endTick = ticks.first { abs($0.value - 1.0) < 1e-6 }
        #expect(endTick != nil, "Should have tick at end (1.0)")
    }
    
    // MARK: - Label Tests
    
    @Test("L scale generates labels at major ticks")
    func lScaleLabels() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        let labeledTicks = ticks.filter { $0.label != nil && !$0.label!.isEmpty }
        
        #expect(labeledTicks.count >= 11, "Expected labels at major tick positions")
        
        // Check specific labels
        let expectedLabels: [(Double, String)] = [
            (0.0, "0.0"),
            (0.1, "0.1"),
            (0.5, "0.5"),
            (1.0, "1.0")
        ]
        
        for (value, expectedLabel) in expectedLabels {
            let tick = ticks.first { abs($0.value - value) < 1e-6 }
            if let tick = tick, let label = tick.label {
                #expect(label == expectedLabel, "Tick at \(value) should have label '\(expectedLabel)', got '\(label)'")
            }
        }
    }
    
    // MARK: - Subsection Coverage Tests
    
    @Test("L scale subsection covers entire range")
    func lScaleSubsectionCoverage() {
        guard let subsection = lScale.subsections.first else {
            Issue.record("L scale should have a subsection")
            return
        }
        
        // The subsection starts at 0.0 and should cover to 1.0
        #expect(subsection.startValue == 0.0)
        
        // Verify tick intervals can generate ticks up to 1.0
        let largestInterval = subsection.tickIntervals.first ?? 0.0
        let estimatedTicks = Int((1.0 - subsection.startValue) / largestInterval)
        #expect(estimatedTicks >= 10, "Subsection should cover full range with tick intervals")
    }
    
    // MARK: - Comparison with Other Linear Scales
    
    @Test("L scale behaves consistently with linear function")
    func lScaleLinearConsistency() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // For a linear scale, spacing between ticks of same type should be uniform
        let majorTicks = ticks.filter { $0.style == .major }.sorted { $0.value < $1.value }
        
        if majorTicks.count >= 2 {
            let spacings = zip(majorTicks.dropFirst(), majorTicks).map { $0.0.value - $0.1.value }
            
            // All major tick spacings should be approximately equal (0.1)
            for spacing in spacings {
                #expect(abs(spacing - 0.1) < 1e-6, "Major tick spacing should be uniform at 0.1")
            }
        }
    }
    
    // MARK: - Total Tick Count Verification
    
    @Test("L scale generates expected total number of ticks")
    func lScaleTotalTickCount() throws {
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        
        // Expected counts (excluding duplicates):
        // Major (0.1): ~11 ticks
        // Medium (0.05): ~10 ticks
        // Minor (0.01): ~90 ticks (some overlap with major)
        // Tiny (0.002): ~490 ticks (some overlap with others)
        // Total expected: ~550-600 ticks
        
        #expect(ticks.count >= 500, "L scale should generate at least 500 tick marks total")
        #expect(ticks.count <= 700, "L scale should not generate more than 700 tick marks")
    }
    
    // MARK: - Debug Output Test
    
    @Test("L scale DEBUG - Print actual tick generation results")
    func lScaleDebugOutput() throws {
        print("\n=== L SCALE DEBUG OUTPUT ===")
        print("L Scale Definition:")
        print("  Name: \(lScale.name)")
        print("  Range: \(lScale.beginValue) to \(lScale.endValue)")
        print("  Function: \(type(of: lScale.function))")
        print("  Subsections: \(lScale.subsections.count)")
        
        for (i, subsection) in lScale.subsections.enumerated() {
            print("  Subsection \(i):")
            print("    startValue: \(subsection.startValue)")
            print("    tickIntervals: \(subsection.tickIntervals)")
            print("    labelLevels: \(subsection.labelLevels)")
        }
        
        let ticks = try ScaleCalculator.generateTickMarks(for: lScale)
        print("\nGenerated Ticks: \(ticks.count)")
        
        if ticks.isEmpty {
            print("ERROR: No ticks generated!")
        } else {
            print("\nFirst 10 ticks:")
            for (i, tick) in ticks.prefix(10).enumerated() {
                print("  \(i): value=\(tick.value), pos=\(tick.normalizedPosition), style=\(tick.style), label=\(tick.label ?? "nil")")
            }
            
            print("\nTicks by style:")
            let majorCount = ticks.filter { $0.style == .major }.count
            let mediumCount = ticks.filter { $0.style == .medium }.count
            let minorCount = ticks.filter { $0.style == .minor }.count
            let tinyCount = ticks.filter { $0.style == .tiny }.count
            print("  Major: \(majorCount)")
            print("  Medium: \(mediumCount)")
            print("  Minor: \(minorCount)")
            print("  Tiny: \(tinyCount)")
            
            print("\nTick at 0.0:")
            if let zeroTick = ticks.first(where: { abs($0.value - 0.0) < 1e-6 }) {
                print("  Found: value=\(zeroTick.value), pos=\(zeroTick.normalizedPosition), style=\(zeroTick.style)")
            } else {
                print("  NOT FOUND - This is the problem!")
            }
        }
        print("=== END DEBUG OUTPUT ===\n")
    }
}