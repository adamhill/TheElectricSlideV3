#!/usr/bin/env swift

import Foundation

// Debug script to check visibleEndValue behavior
// Run with: swift debug-visible-end.swift

// Simulate the descending scale logic
let beginValue = 0.912272537119513  // virtualBegin
let endValue = 0.29178597781571775  // virtualEnd  
let visibleEndValue = 0.32

let isAscending = beginValue < endValue
print("Scale is ascending: \(isAscending)")
print("beginValue: \(beginValue)")
print("endValue: \(endValue)")
print("visibleEndValue: \(visibleEndValue)")

// Subsections (just the last two)
let subsections = [
    ("0.40 -> 0.35", 0.40, 0.35),
    ("0.35 -> end", 0.35, endValue)
]

for (name, start, naturalEnd) in subsections {
    print("\nSubsection: \(name)")
    print("  start: \(start)")
    print("  naturalEnd: \(naturalEnd)")
    
    // Apply visibleEndValue constraint
    let constrainedEnd: Double
    if isAscending {
        constrainedEnd = min(naturalEnd, visibleEndValue)
    } else {
        constrainedEnd = max(naturalEnd, visibleEndValue)
    }
    
    print("  constrainedEnd (max for descending): \(constrainedEnd)")
    print("  Should generate ticks from \(start) to \(constrainedEnd)")
}
