import Foundation

// LL02 function: log₁₀(-ln(x) × 10)
func ll02Transform(_ value: Double) -> Double {
    return log10(-log(value) * 10.0)
}

func ll02InverseTransform(_ transformed: Double) -> Double {
    return exp(-pow(10, transformed) / 10.0)
}

// Current range: 0.91 to 0.35
let beginValue = 0.91
let endValue = 0.35

let fBegin = ll02Transform(beginValue)
let fEnd = ll02Transform(endValue)

print("LL02 transformed values:")
print("  0.91 transforms to: \(fBegin)")
print("  0.35 transforms to: \(fEnd)")
print("  Range in transformed space: \(fEnd - fBegin)")

// If 0.91 should be at normalized position 0.02 (not 0.0)
let gapFraction = 0.02  // 2% gap at start

// For virtual begin calculation:
// V = (fBegin - gapFraction * fEnd) / (1 - gapFraction)
let targetVirtualTransformed = (fBegin - gapFraction * fEnd) / (1 - gapFraction)
let virtualBegin = ll02InverseTransform(targetVirtualTransformed)

print("\nTo have 0.91 at position \(gapFraction):")
print("  Virtual begin transform value: \(targetVirtualTransformed)")
print("  Virtual begin value: \(virtualBegin)")

// Verify the calculation
let testRange = ll02Transform(endValue) - ll02Transform(virtualBegin)
let testPos91 = (ll02Transform(0.91) - ll02Transform(virtualBegin)) / testRange
print("  Verification: 0.91 would be at normalized position: \(testPos91)")
