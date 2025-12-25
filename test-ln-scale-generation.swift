#!/usr/bin/env swift

import Foundation

// Add SlideRuleCoreV3 package path
import PackageDescription

#if canImport(SlideRuleCoreV3)
import SlideRuleCoreV3
#endif

print("=== Testing Ln Scale Generation ===\n")

// Create Ln scale
let lnScale = StandardScales.lnScale(length: 700.0)

print("Ln Scale Definition:")
print("  Name: \(lnScale.name)")
print("  Formula: \(lnScale.formula)")
print("  Range: \(lnScale.beginValue) to \(lnScale.endValue)")
print("  Function: \(lnScale.function.name)")
print("  Tick Direction: \(lnScale.tickDirection)")
print("  Show Baseline: \(lnScale.showBaseline)")
print("")

// Generate the scale
let generated = GeneratedScale(definition: lnScale)

print("Generated Scale:")
print("  Total ticks: \(generated.tickMarks.count)")
print("")

// Check first 10 ticks
print("First 10 ticks:")
for (idx, tick) in generated.tickMarks.prefix(10).enumerated() {
    let isValid = !tick.normalizedPosition.isNaN && !tick.normalizedPosition.isInfinite
    let status = isValid ? "✓" : "✗"
    print("  \(status) Tick \(idx): value=\(String(format: "%.4f", tick.value)) normPos=\(String(format: "%.4f", tick.normalizedPosition)) relLen=\(String(format: "%.2f", tick.style.relativeLength))")
}

// Check for major ticks
let majorTicks = generated.tickMarks.filter { $0.style.relativeLength >= 0.9 }
print("\nMajor ticks (relLen >= 0.9): \(majorTicks.count)")
for (idx, tick) in majorTicks.prefix(5).enumerated() {
    print("  Major \(idx): value=\(String(format: "%.4f", tick.value)) normPos=\(String(format: "%.4f", tick.normalizedPosition))")
}

// Compare with L scale
print("\n=== Comparing with L Scale ===\n")

let lScale = StandardScales.lScale(length: 700.0)
let lGenerated = GeneratedScale(definition: lScale)

print("L Scale:")
print("  Total ticks: \(lGenerated.tickMarks.count)")
print("  First tick: value=\(lGenerated.tickMarks.first?.value ?? 0), normPos=\(lGenerated.tickMarks.first?.normalizedPosition ?? 0)")
print("  Major ticks: \(lGenerated.tickMarks.filter { $0.style.relativeLength >= 0.9 }.count)")
