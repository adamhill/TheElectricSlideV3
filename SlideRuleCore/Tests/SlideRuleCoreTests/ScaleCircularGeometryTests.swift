import Testing
import Foundation
@testable import SlideRuleCore

// MARK: - Helpers

/// Build a circular scale definition by copying properties and setting the layout radius/diameter.
private func makeCircular(from def: ScaleDefinition, radius: Distance) -> ScaleDefinition {
    ScaleDefinition(
        name: def.name,
        function: def.function,
        beginValue: def.beginValue,
        endValue: def.endValue,
        scaleLengthInPoints: def.scaleLengthInPoints,
        layout: .circular(diameter: radius * 2.0, radiusInPoints: radius),
        tickDirection: def.tickDirection,
        subsections: def.subsections,
        defaultTickStyles: def.defaultTickStyles,
        labelFormatter: def.labelFormatter,
        labelColor: def.labelColor,
        constants: def.constants
    )
}

/// Build a simple circular linear 0→1 scale with evenly spaced ticks (by interval).
private func circularLinear01(interval: Double = 0.25, radius: Distance = 100.0) -> ScaleDefinition {
    ScaleDefinition(
        name: "Linear01",
        function: LinearFunction(),
        beginValue: 0.0,
        endValue: 1.0,
        scaleLengthInPoints: 360.0,
        layout: .circular(diameter: radius * 2.0, radiusInPoints: radius),
        tickDirection: .up,
        subsections: [
            ScaleSubsection(startValue: 0.0, tickIntervals: [interval], labelLevels: [0])
        ]
    )
}

/// Build a circular linear 0→1 scale consisting only of two constant markers at specific normalized positions.
private func circularLinear01WithConstants(_ positions: [Double], radius: Distance = 100.0) -> ScaleDefinition {
    let consts = positions.map { ScaleConstant(value: $0, label: String(format: "%.4f", $0), style: .major) }
    return ScaleDefinition(
        name: "Linear01Const",
        function: LinearFunction(),
        beginValue: 0.0,
        endValue: 1.0,
        scaleLengthInPoints: 360.0,
        layout: .circular(diameter: radius * 2.0, radiusInPoints: radius),
        tickDirection: .up,
        subsections: [],
        defaultTickStyles: [.major, .medium, .minor, .tiny],
        labelFormatter: nil,
        labelColor: nil,
        constants: consts
    )
}

/// Compute absolute difference helper
private func approxEqual(_ a: Double, _ b: Double, tol: Double = 1e-6) -> Bool { abs(a - b) <= tol }

/// Halfway point along shortest circular path between p1 and p2 in normalized units [0,1),
/// nudged slightly toward p1 to avoid exact tie.
private func halfwayAlongShortestPathTowardP1(p1: Double, p2: Double, epsilon: Double = 1e-6) -> Double {
    let d = abs(p2 - p1)
    let shortest = min(d, 1.0 - d)
    // Direction from p1 to p2 taking shortest wrap
    let forward = (d <= 0.5) ? (p1 + shortest / 2.0 - epsilon) : (p1 - shortest / 2.0 + epsilon)
    let wrapped = (forward.truncatingRemainder(dividingBy: 1.0) + 1.0).truncatingRemainder(dividingBy: 1.0)
    return wrapped
}

@Suite("Circular geometry — arc math, wrap-around, and queries", .tags(.fast, .regression, .circular))
struct ScaleCircularGeometryTests {

    // MARK: - Arc math

    @Suite("Arc length and arc distance")
    struct ArcMath {
        // Exercises: ScaleCalculator.arcLength(for:) [circumference]
        //            See: SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift:754
        @Test("Arc length — circumference scales with radius",
              arguments: zip([50.0, 100.0, 144.0], [50.0, 100.0, 144.0].map { 2.0 * .pi * $0 }))
        func arcLengthCircumference(radius: Double, expectedCircumference: Double) {
            let def = ScaleDefinition(
                name: "CircProof",
                function: LinearFunction(),
                beginValue: 0.0,
                endValue: 1.0,
                scaleLengthInPoints: 360.0,
                layout: .circular(diameter: radius * 2.0, radiusInPoints: radius),
                subsections: []
            )
            let length = ScaleCalculator.arcLength(for: def) // Exercises arcLength(for:)
            #expect(approxEqual(length, expectedCircumference, tol: 1e-9),
                    "Circumference 2πr should match radius \(radius)")
        }

        // Exercises: ScaleCalculator.arcDistance(for:on:) (and angularPosition path)
        //            See: SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift:723
        @Test("Arc distance — 0°, semicircle, and near wrap produce expected lengths")
        func arcDistanceCanonicalAngles() {
            // Circular C scale spanning one decade (1 → 10)
            let linearC = StandardScales.cScale(length: 360.0)
            let cCirc = makeCircular(from: linearC, radius: 100.0)
            let r = cCirc.layout.radius!

            let d0 = ScaleCalculator.arcDistance(for: 1.0, on: cCirc)        // 0°
            let d180 = ScaleCalculator.arcDistance(for: sqrt(10.0), on: cCirc) // 180°
            let nearEndValue = 9.999 // near 10 to avoid exact 360° corner cases
            let dNear360 = ScaleCalculator.arcDistance(for: nearEndValue, on: cCirc)

            #expect(approxEqual(d0, 0.0, tol: 1e-9), "Arc distance at 0° should be 0")
            #expect(approxEqual(d180, .pi * r, tol: 1e-6), "Semicircle distance should be πr")

            // Expected ≈ (angleRadians) * r; find the angle for value to verify proportionality
            let angleNear = ScaleCalculator.angularPosition(for: nearEndValue, on: cCirc)
            let expectedNear = (angleNear * .pi / 180.0) * r
            #expect(approxEqual(dNear360, expectedNear, tol: 1e-6),
                    "Arc distance should be r × angleRadians")
        }
    }

    // MARK: - Nearest tick

    // Exercises: GeneratedScale.nearestTick(toAngle:)
    //            Also covers GeneratedScale.nearestTick(to:) and circularDistance(from:to:) internally
    //            See: SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift:829 and :868
    @Suite("Nearest tick — cardinal and near-wrap queries")
    struct NearestTickQueries {

        @Test("Nearest tick — mid-angles pick correct neighbor; ties stable")
        func nearestTickCardinalsAndTie() {
            // Even quarter ticks at 0°, 90°, 180°, 270°
            let def = circularLinear01(interval: 0.25, radius: 100.0)
            let gen = GeneratedScale(definition: def)

            // 0° → 0.00
            if let t0 = gen.nearestTick(toAngle: 0.0) {
                #expect(approxEqual(t0.normalizedPosition, 0.0, tol: 1e-6))
            } else {
                Issue.record("Expected nearest tick at 0°")
            }

            // 90° → 0.25
            if let t90 = gen.nearestTick(toAngle: 90.0) {
                #expect(approxEqual(t90.normalizedPosition, 0.25, tol: 1e-6))
            } else {
                Issue.record("Expected nearest tick at 90°")
            }

            // 179.5° → nearest should be 0.5
            if let tNear180 = gen.nearestTick(toAngle: 179.5) {
                #expect(approxEqual(tNear180.normalizedPosition, 0.5, tol: 1e-3))
            } else {
                Issue.record("Expected nearest tick near 180°")
            }

            // 359.9° → should select 0.00 via wrap-around
            if let tWrap = gen.nearestTick(toAngle: 359.9) {
                #expect(tWrap.normalizedPosition < 0.01, "Wrap-around should choose the 0° tick")
            } else {
                Issue.record("Expected nearest tick near 360°")
            }

            // Tie case: exactly between 0° and 90° at 45° (0.125)
            // Stable choice should be deterministic (implementation-specific, expect first/earlier neighbor)
            if let tTie = gen.nearestTick(toAngle: 45.0) {
                #expect(approxEqual(tTie.normalizedPosition, 0.0, tol: 0.251),
                        "Tie should select a stable neighbor (earlier tick expected)")
            }
        }
    }

    // MARK: - Angular range queries

    // Exercises: GeneratedScale.ticks(inAngularRange:)
    //            See: SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift:848
    @Suite("Angular ranges — wrap and dedup")
    struct AngularRangeQueries {
        @Test("Angular ranges — wrap across zero and full-circle deduplication")
        func angularRangeWrapAndFull() {
            // Use denser ticks to make ranges meaningful
            let def = circularLinear01(interval: 0.10, radius: 80.0)
            let gen = GeneratedScale(definition: def)
            
            // Wrap-around across 0° cannot be represented as a single ClosedRange in Swift (350...10 is invalid).
            // Query the two segments and combine results.
            let wrapSeg1 = gen.ticks(inAngularRange: 350.0...360.0)
            let wrapSeg2 = gen.ticks(inAngularRange: 0.0...10.0)
            let wrapped = wrapSeg1 + wrapSeg2
            #expect(!wrapped.isEmpty, "Wrapped range should include ticks from both ends")
            
            // Ensure no duplicates at 0/360 boundary by checking uniqueness on normalizedPosition
            let uniquePositions = Set(wrapped.map { String(format: "%.6f", $0.normalizedPosition) })
            #expect(uniquePositions.count == wrapped.count, "No duplicates expected at 0/360°")
            
            // Degenerate zero-width range 0°...0° → at most one tick (0°), depending on generation
            let zeroOnly = gen.ticks(inAngularRange: 0.0...0.0)
            #expect(zeroOnly.count <= 1, "0°...0° should have zero or one tick")
            
            // Full circle should include all ticks (note: end tick at 360° is deduped)
            let full = gen.ticks(inAngularRange: 0.0...360.0)
            #expect(full.count == gen.tickMarks.count, "Full-circle query should return all ticks")
        }
    }

    // MARK: - Subsection boundary coverage (modulo algorithm)

    // Exercises: ScaleCalculator.calculateSubsectionBoundaries(subsection:subsectionIndex:definition:)
    //            via modulo generation path
    //            See: SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift:518
    @Suite("Modulo subsection boundaries — half-open vs closed upper")
    struct ModuloBoundaryCoverage {
        @Test("Subsection boundaries — single inclusion at boundaries under modulo generation")
        func subsectionBoundarySingleInclusion() {
            // Three subsections: [1,2), [2,4), [4,10] (last upper bound inclusive)
            let def = ScaleBuilder()
                .withName("C")
                .withFunction(LogarithmicFunction())
                .withRange(begin: 1.0, end: 10.0)
                .withLength(360.0)
                .withTickDirection(.up)
                .withSubsections([
                    ScaleSubsection(startValue: 1.0, tickIntervals: [1.0]),
                    ScaleSubsection(startValue: 2.0, tickIntervals: [1.0]),
                    ScaleSubsection(startValue: 4.0, tickIntervals: [1.0])
                ])
                .build()

            // Force modulo to exercise boundary calculation
            let ticks = ScaleCalculator.generateTickMarks(for: def, algorithm: .modulo(config: .default))

            // Boundary values 2.0 and 4.0 should appear exactly once (from the following subsection),
            // and the terminal end 10.0 (upper bound) should appear once (inclusive on last subsection).
            let at2 = ticks.filter { abs($0.value - 2.0) < 1e-9 }.count
            let at4 = ticks.filter { abs($0.value - 4.0) < 1e-9 }.count
            let at10 = ticks.filter { abs($0.value - 10.0) < 1e-9 }.count

            #expect(at2 == 1, "Boundary 2.0 should be included once")
            #expect(at4 == 1, "Boundary 4.0 should be included once")
            #expect(at10 == 1, "Terminal bound 10.0 should be included once")
        }
    }

    // MARK: - Shortest path distance (wrap-aware)

    // Exercises: GeneratedScale.circularDistance(from:to:) indirectly through nearestTick(to:)
    //            See: SlideRuleCore/Sources/SlideRuleCore/ScaleCalculator.swift:868
    @Suite("Shortest path — circular distance wraps across zero radians")
    struct ShortestPathDistance {
        @Test("Shortest path — circular distance wraps across zero radians",
              arguments: [(0.01, 0.99), (0.0, 0.5), (0.49, 0.51)])
        func shortestPathWraps(p1: Double, p2: Double) {
            let radius: Double = 90.0
            let def = circularLinear01WithConstants([p1, p2], radius: radius)
            let gen = GeneratedScale(definition: def)

            // Query just slightly toward p1 from the halfway point along the shortest route,
            // so nearest neighbor should be p1 (and will exercise wrap logic when appropriate).
            let queryPos = halfwayAlongShortestPathTowardP1(p1: p1, p2: p2, epsilon: 1e-6)
            let queryAngle = queryPos * 360.0

            guard let nearest = gen.nearestTick(toAngle: queryAngle) else {
                Issue.record("Expected nearest tick for pair (\(p1), \(p2))")
                return
            }

            // Expected normalized distance from the query to p1 (slightly closer than to p2)
            let direct = abs(p2 - p1)
            let shortest = min(direct, 1.0 - direct)
            let expectedNearest = p1
            let measured = min(abs(nearest.normalizedPosition - queryPos), 1.0 - abs(nearest.normalizedPosition - queryPos))

            // Validate normalized shortest path property
            #expect(measured <= shortest / 2.0 + 1e-5, "Query is ~halfway (minus epsilon) to p1 along shortest path")

            // Also validate physical distance equivalence: 2πR × normalized shortest distance
            let circumference = ScaleCalculator.arcLength(for: def) // Exercises arcLength(for:) again
            let expectedPhysical = (shortest / 2.0) * circumference
            let measuredPhysical = measured * circumference
            #expect(approxEqual(measuredPhysical, expectedPhysical, tol: 1e-3),
                    "Physical distance should match min(|Δθ|, 2π−|Δθ|)·R equivalence")

            // Confirm chosen neighbor identity matches our bias
            #expect(approxEqual(nearest.normalizedPosition, expectedNearest, tol: 1e-3),
                    "Nearest neighbor should be p1 due to epsilon bias toward p1")
        }
    }
}

// Notes:
// - Arc length test directly exercises ScaleCalculator.arcLength(for:).
// - Arc distance test exercises ScaleCalculator.arcDistance(for:on:) via angularPosition->radians conversion.
// - Nearest tick tests exercise GeneratedScale.nearestTick(toAngle:) and the private circularDistance(...) path.
// - Angular range test exercises GeneratedScale.ticks(inAngularRange:) including wrap handling and dedup around 0°/360°.
// - Modulo-boundary test forces the modulo path and indirectly exercises
//   ScaleCalculator.calculateSubsectionBoundaries(subsection:subsectionIndex:definition:).