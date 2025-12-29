#!/usr/bin/env swift

import Foundation

// Add SlideRuleCoreV3 path
import SlideRuleCoreV3

// Test the THETA small scale label generation
print("=== THETA Small Scale Debug Analysis ===\n")

// Generate the scale
let thetaSmall = StandardScales.phaseAngleThetaSmallScale(length: 250.0)
let ticks = ScaleCalculator.generateTickMarks(for: thetaSmall)

print("Scale Configuration:")
print("  Range: \(thetaSmall.beginValue)° → \(thetaSmall.endValue)°")
print("  Number of subsections: \(thetaSmall.subsections.count)")
print("  Total ticks generated: \(ticks.count)\n")

// Analyze subsections
print("=== Subsection Configuration ===")
for (i, subsection) in thetaSmall.subsections.enumerated() {
    let nextStart = (i < thetaSmall.subsections.count - 1) 
        ? thetaSmall.subsections[i + 1].startValue 
        : thetaSmall.endValue
    
    print("\nSubsection \(i): \(subsection.startValue)° → \(nextStart)°")
    print("  Intervals: \(subsection.tickIntervals)")
    print("  Label Levels: \(subsection.labelLevels)")
    print("  Has dual formatter: \(subsection.dualLabelFormatter != nil)")
}

// Check for ticks at 5.71° and 5.0°
print("\n=== Critical Ticks Check ===")
let tick571 = ticks.first { abs($0.value - 5.71) < 0.01 }
let tick5 = ticks.first { abs($0.value - 5.0) < 0.01 }

if let tick = tick571 {
    print("\n✓ Tick at 5.71°:")
    print("  Value: \(tick.value)")
    print("  Position: \(tick.normalizedPosition)")
    print("  Has labels: \(!tick.labels.isEmpty)")
    if !tick.labels.isEmpty {
        for label in tick.labels {
            print("    - '\(label.text)' (\(label.color), \(label.position))")
        }
    } else {
        print("    ❌ NO LABELS")
    }
} else {
    print("\n❌ NO TICK at 5.71°")
}

if let tick = tick5 {
    print("\n✓ Tick at 5.0°:")
    print("  Value: \(tick.value)")
    print("  Position: \(tick.normalizedPosition)")
    print("  Has labels: \(!tick.labels.isEmpty)")
    if !tick.labels.isEmpty {
        for label in tick.labels {
            print("    - '\(label.text)' (\(label.color), \(label.position))")
        }
    } else {
        print("    ❌ NO LABELS")
    }
} else {
    print("\n❌ NO TICK at 5.0°")
}

// Show all labeled ticks
print("\n=== All Labeled Ticks  (sorted by value) ===")
let labeledTicks = ticks.filter { !$0.labels.isEmpty }
print("Found \(labeledTicks.count) labeled ticks:\n")

for tick in labeledTicks.sorted(by: { $0.value > $1.value }) {
    let labels = tick.labels.map { "\($0.text)" }.joined(separator: " / ")
    print("  \(String(format: "%6.2f", tick.value))° at pos \(String(format: "%.6f", tick.normalizedPosition)): \(labels)")
}

// Detailed analysis of first two subsections
print("\n=== First Two Subsections Detail ===")
print("\nSubsection 0 (5.71° → 5.0°):")
let sub0Ticks = ticks.filter { $0.value >= 5.0 && $0.value <= 5.71 }
print("  Total ticks: \(sub0Ticks.count)")
print("  Labeled ticks: \(sub0Ticks.filter { !$0.labels.isEmpty }.count)")
for tick in sub0Ticks.sorted(by: { $0.value > $1.value }) {
    let labelInfo = tick.labels.isEmpty ? "NO LABELS" : tick.labels.map { $0.text }.joined(separator: " / ")
    print("    \(String(format: "%.3f", tick.value))°: \(labelInfo)")
}

print("\nSubsection 1 (5.0° → 4.0°):")
let sub1Ticks = ticks.filter { $0.value >= 4.0 && $0.value <= 5.0 }
print("  Total ticks: \(sub1Ticks.count)")
print("  Labeled ticks: \(sub1Ticks.filter { !$0.labels.isEmpty }.count)")
for tick in sub1Ticks.sorted(by: { $0.value > $1.value }) {
    let labelInfo = tick.labels.isEmpty ? "NO LABELS" : tick.labels.map { $0.text }.joined(separator: " / ")
    print("    \(String(format: "%.3f", tick.value))°: \(labelInfo)")
}

// Test the label formatter directly
print("\n=== Label Formatter Test ===")
print("\nTesting StandardLabelFormatter.thetaScaleDual:")
let labels571 = StandardLabelFormatter.thetaScaleDual(value: 5.71)
print("  5.71° produces \(labels571.count) labels:")
for label in labels571 {
    print("    - '\(label.text)' (\(label.color), \(label.position))")
}

let labels5 = StandardLabelFormatter.thetaScaleDual(value: 5.0)
print("  5.0° produces \(labels5.count) labels:")
for label in labels5 {
    print("    - '\(label.text)' (\(label.color), \(label.position))")
}

print("\n=== Analysis Complete ===")
