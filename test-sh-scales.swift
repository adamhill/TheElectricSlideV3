#!/usr/bin/env swift

import Foundation

// Add the package path
#if canImport(SlideRuleCoreV3)
import SlideRuleCoreV3
#endif

print("Testing SH1 and SH2 scale generation...")

let sh1 = StandardScales.sh1Scale(length: 250.0)
let sh2 = StandardScales.sh2Scale(length: 250.0)

print("\n=== SH1 Scale ===")
print("Name: \(sh1.name)")
print("Formula: \(sh1.formula)")
print("Range: \(sh1.range.begin) to \(sh1.range.end)")
print("Function type: \(type(of: sh1.function))")
if let func1 = sh1.function as? HyperbolicSineFunction {
    print("  Multiplier: \(func1.multiplier)")
    print("  Offset: \(func1.offset)")
}
print("Subsections: \(sh1.subsections.count)")
for (index, subsection) in sh1.subsections.enumerated() {
    print("  [\(index)] Start: \(subsection.startValue), Intervals: \(subsection.tickIntervals)")
}

// Generate the scale
let generatedSh1 = ScaleCalculator.generateScale(from: sh1)
print("Generated tick marks: \(generatedSh1.tickMarks.count)")
print("First 10 ticks:")
for (i, tick) in generatedSh1.tickMarks.prefix(10).enumerated() {
    print("  [\(i)] Value: \(tick.value), Position: \(tick.position), Style: \(tick.style)")
}

print("\n=== SH2 Scale ===")
print("Name: \(sh2.name)")
print("Formula: \(sh2.formula)")
print("Range: \(sh2.range.begin) to \(sh2.range.end)")
print("Function type: \(type(of: sh2.function))")
if let func2 = sh2.function as? HyperbolicSineFunction {
    print("  Multiplier: \(func2.multiplier)")
    print("  Offset: \(func2.offset)")
}
print("Subsections: \(sh2.subsections.count)")
for (index, subsection) in sh2.subsections.enumerated() {
    print("  [\(index)] Start: \(subsection.startValue), Intervals: \(subsection.tickIntervals)")
}

// Generate the scale
let generatedSh2 = ScaleCalculator.generateScale(from: sh2)
print("Generated tick marks: \(generatedSh2.tickMarks.count)")
print("First 10 ticks:")
for (i, tick) in generatedSh2.tickMarks.prefix(10).enumerated() {
    print("  [\(i)] Value: \(tick.value), Position: \(tick.position), Style: \(tick.style)")
}

// Test the transformation at a few key points
print("\n=== Transformation Tests ===")
let testValues = [0.88, 1.0, 1.5, 2.0, 3.0]
for value in testValues {
    if value >= sh2.range.begin && value <= sh2.range.end {
        let transformed = sh2.function.transform(value)
        print("SH2: f(\(value)) = \(transformed)")
    }
}
