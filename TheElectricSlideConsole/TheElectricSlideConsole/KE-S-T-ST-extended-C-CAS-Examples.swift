import Foundation
import SlideRuleCore

// MARK: - Specialty Scales Usage Examples

/// Comprehensive examples showing how to use the specialty scales
/// Demonstrates KE variants, extended range C scales, and aviation scales

    
    // MARK: - Example 1: KE Trigonometric Scales
    
    /// Demonstrates the Keuffel & Esser trigonometric scale variants
    /// Shows the difference between standard and KE versions
    public func example1_KETrigScales() {
        print("=" * 60)
        print("Example 1: Keuffel & Esser Trigonometric Scales")
        print("=" * 60)
        
        // Standard S scale: 5.7° to 90°
        let standardS = StandardScales.sScale(length: 250.0)
        print("\nStandard S scale:")
        print("  Range: \(standardS.beginValue)° to \(standardS.endValue)°")
        print("  Function: log₁₀(10×sin(x))")
        
        // KE S scale: 5.5° to 90°
        let keS = StandardScales.keSScale(length: 250.0)
        print("\nKE-S scale:")
        print("  Range: \(keS.beginValue)° to \(keS.endValue)°")
        print("  Extended by: \(standardS.beginValue - keS.beginValue)°")
        print("  Advantage: More range for small angle calculations")
        
        // Generate and compare
        let generatedStandardS = GeneratedScale(definition: standardS)
        let generatedKES = GeneratedScale(definition: keS)
        
        print("\nTick mark comparison:")
        print("  Standard S: \(generatedStandardS.tickMarks.count) ticks")
        print("  KE-S:       \(generatedKES.tickMarks.count) ticks")
        
        // Standard T scale: 5.7° to 45°
        let standardT = StandardScales.tScale(length: 250.0)
        print("\nStandard T scale:")
        print("  Range: \(standardT.beginValue)° to \(standardT.endValue)°")
        
        // KE T scale: 5.5° to 45°
        let keT = StandardScales.keTScale(length: 250.0)
        print("\nKE-T scale:")
        print("  Range: \(keT.beginValue)° to \(keT.endValue)°")
        print("  Extended by: \(standardT.beginValue - keT.beginValue)°")
        
        // KE ST scale (SRT): 0.55° to 6°
        let standardST = StandardScales.stScale(length: 250.0)
        let keSRT = StandardScales.keSTScale(length: 250.0)
        
        print("\nStandard ST scale:")
        print("  Range: \(standardST.beginValue)° to \(standardST.endValue)°")
        print("\nKE-ST (SRT) scale:")
        print("  Range: \(keSRT.beginValue)° to \(keSRT.endValue)°")
        print("  Label: '\(keSRT.name)' (as shown on K&E rules)")
        print("  Upper range extended by: \(keSRT.endValue - standardST.endValue)°")
        
        print("\n" + "─" * 60)
        print("Use Case: The KE variants provide slightly extended ranges")
        print("at small angles, useful for precision work in surveying,")
        print("navigation, and engineering calculations.")
        print("─" * 60)
    }
    
    // MARK: - Example 2: Extended Range C Scales
    
    /// Demonstrates the C10-100 and C100-1000 scales
    /// Shows how they work for different decimal ranges
    public func example2_ExtendedRangeCScales() {
        print("\n" + "=" * 60)
        print("Example 2: Extended Range C Scales")
        print("=" * 60)
        
        let c = StandardScales.cScale(length: 250.0)
        let c10_100 = StandardScales.c10to100Scale(length: 250.0)
        let c100_1000 = StandardScales.c100to1000Scale(length: 250.0)
        
        print("\nStandard C scale: 1 to 10")
        print("C10-100 scale:    10 to 100 (internally 1-10)")
        print("C100-1000 scale:  100 to 1000 (internally 1-10)")
        
        // Test position calculations at key values
        let testValue = 2.5
        
        let posC = ScaleCalculator.normalizedPosition(for: testValue, on: c)
        let posC10 = ScaleCalculator.normalizedPosition(for: testValue, on: c10_100)
        let posC100 = ScaleCalculator.normalizedPosition(for: testValue, on: c100_1000)
        
        print("\nPosition of value 2.5 on each scale:")
        print("  C:         \(posC) (represents 2.5)")
        print("  C10-100:   \(posC10) (represents 25)")
        print("  C100-1000: \(posC100) (represents 250)")
        print("\nAll three scales have the SAME physical position!")
        print("Only the labels differ.")
        
        // Generate scales and show label differences
        let genC = GeneratedScale(definition: c)
        let genC10 = GeneratedScale(definition: c10_100)
        let genC100 = GeneratedScale(definition: c100_1000)
        
        print("\nLabels at major tick marks:")
        print("\nC scale (1-10):")
        genC.tickMarks.filter { $0.style == .major && $0.label != nil }.prefix(5).forEach {
            print("  Value: \($0.value), Label: '\($0.label ?? "")'")
        }
        
        print("\nC10-100 scale (10-100):")
        genC10.tickMarks.filter { $0.style == .major && $0.label != nil }.prefix(5).forEach {
            print("  Value: \($0.value), Label: '\($0.label ?? "")' (×10)")
        }
        
        print("\nC100-1000 scale (100-1000):")
        genC100.tickMarks.filter { $0.style == .major && $0.label != nil }.prefix(5).forEach {
            print("  Value: \($0.value), Label: '\($0.label ?? "")' (×100)")
        }
        
        print("\n" + "─" * 60)
        print("Use Case: Extended range scales eliminate mental decimal")
        print("shifting. Use C10-100 for engineering calculations in tens,")
        print("C100-1000 for hundreds. Reduces calculation errors.")
        print("─" * 60)
    }
    
    // MARK: - Example 3: Calibrated Airspeed (CAS) Scale
    
    /// Demonstrates the aviation CAS scale
    /// Shows the non-linear relationship in airspeed calculations
    public func example3_CASScale() {
        print("\n" + "=" * 60)
        print("Example 3: Calibrated Airspeed (CAS) Scale")
        print("=" * 60)
        
        let cas = StandardScales.casScale(length: 250.0)
        print("\nCAS Scale: \(cas.beginValue) to \(cas.endValue) knots")
        print("Formula: log₁₀((v × 22.74 + 698.7) / 1000)")
        print("\nThis is a specialized aviation scale for converting")
        print("between indicated airspeed (IAS) and calibrated")
        print("airspeed (CAS), accounting for instrument errors.")
        
        let generated = GeneratedScale(definition: cas)
        print("\nGenerated \(generated.tickMarks.count) tick marks")
        
        // Test specific airspeed values
        let testSpeeds: [Double] = [100, 150, 200, 300, 500, 750, 1000]
        
        print("\nAirspeed positions on scale:")
        for speed in testSpeeds {
            let pos = ScaleCalculator.normalizedPosition(for: speed, on: cas)
            let distance = ScaleCalculator.absolutePosition(for: speed, on: cas)
            print(String(format: "  %4.0f knots: position %.3f (%.1f points)",
                        speed, pos, distance))
        }
        
        // Show non-linearity
        print("\nNon-linear spacing demonstration:")
        print("  80-150:   Δ = 70 knots")
        let pos80 = ScaleCalculator.normalizedPosition(for: 80, on: cas)
        let pos150 = ScaleCalculator.normalizedPosition(for: 150, on: cas)
        print("            Physical distance: \((pos150 - pos80) * 250) points")
        
        print("  500-570:  Δ = 70 knots")
        let pos500 = ScaleCalculator.normalizedPosition(for: 500, on: cas)
        let pos570 = ScaleCalculator.normalizedPosition(for: 570, on: cas)
        print("            Physical distance: \((pos570 - pos500) * 250) points")
        
        print("\nThe same speed difference occupies different physical")
        print("distances due to the non-linear calibration formula.")
        
        print("\n" + "─" * 60)
        print("Use Case: Aviation slide rules and E6-B flight computers")
        print("use CAS scales for airspeed corrections. The non-linear")
        print("formula accounts for pitot-static system errors.")
        print("─" * 60)
    }
    
    // MARK: - Example 4: Building a K&E 4081-3 Rule
    
    /// Demonstrates how to assemble a complete Keuffel & Esser 4081-3 slide rule
    /// Uses PostScript definition: (LL01 K A [ B | T ST S ] D L : ...)
    public func example4_KE4081Assembly() {
        print("\n" + "=" * 60)
        print("Example 4: Assembling K&E 4081-3 Slide Rule")
        print("=" * 60)
        
        print("\nKeuffel & Esser Model 4081-3: Log-Log Duplex Decitrig")
        print("One of the most popular slide rules used by engineers")
        
        // Front side: LL01 K A [ B | T ST S ] D L
        print("\n" + "─" * 60)
        print("FRONT SIDE")
        print("─" * 60)
        
        print("\nTop Stator:")
        let frontTopStator = [
            StandardScales.ll1Scale(length: 250.0),
            StandardScales.kScale(length: 250.0),
            StandardScales.aScale(length: 250.0)
        ]
        frontTopStator.forEach { scale in
            print("  \(scale.name): \(scale.function.name), range \(scale.beginValue)-\(scale.endValue)")
        }
        
        print("\nSlide (with vertical separator):")
        let frontSlide = [
            StandardScales.bScale(length: 250.0),
            // Separator line here
            StandardScales.keTScale(length: 250.0),      // KE variant!
            StandardScales.keSTScale(length: 250.0),     // KE variant! (SRT)
            StandardScales.keSScale(length: 250.0)       // KE variant!
        ]
        print("  B: log, range 1-100")
        print("  ─────────")
        frontSlide[1...].forEach { scale in
            if scale.name == "SRT" {
                print("  \(scale.name): \(scale.function.name), range \(scale.beginValue)°-\(scale.endValue)° (KE variant)")
            } else {
                print("  \(scale.name): \(scale.function.name), range \(scale.beginValue)°-\(scale.endValue)° (KE variant)")
            }
        }
        
        print("\nBottom Stator:")
        let frontBottomStator = [
            StandardScales.dScale(length: 250.0),
            StandardScales.lScale(length: 250.0)
        ]
        frontBottomStator.forEach { scale in
            print("  \(scale.name): \(scale.function.name), range \(scale.beginValue)-\(scale.endValue)")
        }
        
        // Back side would be: LL02 LL03 DF [ CF CIF | CI C ] D LL3 LL2
        print("\n" + "─" * 60)
        print("BACK SIDE (not shown in detail)")
        print("─" * 60)
        print("Would include: LL02, LL03, DF, CF, CIF, CI, C, D, LL3, LL2")
        
        print("\n" + "─" * 60)
        print("Notable Features:")
        print("- Uses KE-T, KE-ST (SRT), and KE-S for extended trig ranges")
        print("- Log-log scales (LL series) for exponentials")
        print("- Folded scales (CF, DF, CIF) for extended range")
        print("- Complete set for engineering calculations")
        print("─" * 60)
    }
    
    // MARK: - Example 5: Factory Method Usage
    
    /// Demonstrates using the factory methods to create scales by name
    public func example5_FactoryMethods() {
        print("\n" + "=" * 60)
        print("Example 5: Using Factory Methods")
        print("=" * 60)
        
        print("\nStandard scale factory (original):")
        if let c = StandardScales.scale(named: "C") {
            print("  ✓ Created scale '\(c.name)'")
        }
        if let d = StandardScales.scale(named: "D") {
            print("  ✓ Created scale '\(d.name)'")
        }
        
        print("\nSpecialty scale factory (new):")
        if let keS = StandardScales.scale(named: "KE-S") {
            print("  ✓ Created scale '\(keS.name)'")
        }
        if let srt = StandardScales.scale(named: "SRT") {
            print("  ✓ Created scale '\(srt.name)'")
        }
        if let c10_100 = StandardScales.scale(named: "C10-100") {
            print("  ✓ Created scale '\(c10_100.name)'")
        }
        if let cas = StandardScales.scale(named: "CAS") {
            print("  ✓ Created scale '\(cas.name)'")
        }
        
        print("\nUnified factory (searches both):")
        let scaleNames = ["C", "D", "KE-S", "KE-T", "SRT", "C10-100", "CAS"]
        for name in scaleNames {
            if let scale = StandardScales.scale(named: name) {
                print("  ✓ '\(name)' → scale '\(scale.name)'")
            } else {
                print("  ✗ '\(name)' not found")
            }
        }
        
        print("\nAlternate name variations:")
        let variations = [
            "KE-S", "KES",           // Same scale
            "KE-ST", "KEST", "SRT",  // Same scale (three names)
            "C10-100", "C10.100"     // Same scale (dot or dash)
        ]
        print("  Accepted variations:")
        for name in variations {
            if let scale = StandardScales.scale(named: name) {
                print("    '\(name)' → '\(scale.name)'")
            }
        }
        
        print("\n" + "─" * 60)
        print("The factory methods provide flexible scale creation")
        print("with support for alternate naming conventions.")
        print("─" * 60)
    }
    
    // MARK: - Example 6: Concurrent Generation
    
    /// Demonstrates concurrent generation of specialty scales
    public func example6_ConcurrentGeneration() async {
        print("\n" + "=" * 60)
        print("Example 6: Concurrent Specialty Scale Generation")
        print("=" * 60)
        
        let definitions = [
            StandardScales.keSScale(),
            StandardScales.keTScale(),
            StandardScales.keSTScale(),
            StandardScales.c10to100Scale(),
            StandardScales.c100to1000Scale(),
            StandardScales.casScale()
        ]
        
        print("\nGenerating \(definitions.count) specialty scales concurrently...")
        
        let startTime = Date()
        let generator = ConcurrentScaleGenerator()
        let scales = await generator.generateScales(definitions)
        let duration = Date().timeIntervalSince(startTime)
        
        print("✓ Generated in \(String(format: "%.2f", duration * 1000))ms")
        
        print("\nResults:")
        for scale in scales {
            print("  \(scale.definition.name): \(scale.tickMarks.count) ticks")
        }
        
        print("\n" + "─" * 60)
        print("Concurrent generation uses Swift 6 async/await")
        print("for efficient parallel scale calculation.")
        print("─" * 60)
    }
    
    // MARK: - Example 7: Validation
    
    /// Validates all specialty scales for mathematical correctness
    public func example7_Validation() {
        print("\n" + "=" * 60)
        print("Example 7: Specialty Scale Validation")
        print("=" * 60)
        
        let scales = [
            ("KE-S", StandardScales.keSScale()),
            ("KE-T", StandardScales.keTScale()),
            ("KE-ST (SRT)", StandardScales.keSTScale()),
            ("C10-100", StandardScales.c10to100Scale()),
            ("C100-1000", StandardScales.c100to1000Scale()),
            ("CAS", StandardScales.casScale())
        ]
        
        print("\nValidating scales...")
        var allValid = true
        
        for (name, definition) in scales {
            do {
                try ScaleValidator.validate(definition)
                print("  ✓ \(name): Valid")
            } catch let error as ScaleValidator.ValidationError {
                print("  ✗ \(name): \(error.description)")
                allValid = false
            } catch {
                print("  ✗ \(name): Unexpected error")
                allValid = false
            }
        }
        
        if allValid {
            print("\n✓ All specialty scales passed validation!")
        } else {
            print("\n✗ Some scales failed validation")
        }
        
        print("\n" + "─" * 60)
        print("Validation checks:")
        print("- Range validity (finite, non-equal begin/end)")
        print("- Function correctness (transform/inverse round-trip)")
        print("- Subsection presence and non-overlap")
        print("─" * 60)
    }
    
    // MARK: - Example 8: Export Specialty Scales
    
    /// Demonstrates exporting specialty scales to CSV and JSON
    public func example8_Export() {
        print("\n" + "=" * 60)
        print("Example 8: Exporting Specialty Scales")
        print("=" * 60)
        
        let cas = StandardScales.casScale(length: 250.0)
        let generated = GeneratedScale(definition: cas)
        
        // CSV export
        let csv = ScaleExporter.toCSV(generated)
        print("\nCSV Export Preview (first 5 lines):")
        let csvLines = csv.split(separator: "\n")
        csvLines.prefix(5).forEach { line in
            print("  \(line)")
        }
        print("  ... (\(csvLines.count - 5) more lines)")
        
        // JSON export
        do {
            let json = try ScaleExporter.toJSON(generated)
            print("\nJSON Export Preview (first 300 characters):")
            let preview = String(json.prefix(300))
            print("  " + preview.replacingOccurrences(of: "\n", with: "\n  "))
            print("  ... (truncated)")
        } catch {
            print("\nJSON Export failed: \(error)")
        }
        
        print("\n" + "─" * 60)
        print("Exported data can be used for:")
        print("- CAD/CAM systems for physical rule manufacture")
        print("- PDF/SVG generation for printing")
        print("- Data analysis and verification")
        print("- Cross-platform visualization tools")
        print("─" * 60)
    }
    
    // MARK: - Run All Examples
    
    /// Runs all specialty scale examples
    public func runAllKEExamples() {
        example1_KETrigScales()
        example2_ExtendedRangeCScales()
        example3_CASScale()
        example4_KE4081Assembly()
        example5_FactoryMethods()
        //await example6_ConcurrentGeneration()
        example7_Validation()
        example8_Export()
        
        print("\n" + "=" * 60)
        print("All Specialty Scale Examples Complete!")
        print("=" * 60)
    }

// MARK: - Quick Test Function

/// Quick test to verify all specialty scales work
public func testKEScales() {
    print("Testing Specialty Scales...")
    
    // Test each scale can be created
    let scales: [(String, ScaleDefinition)] = [
        ("KE-S", StandardScales.keSScale()),
        ("KE-T", StandardScales.keTScale()),
        ("KE-ST", StandardScales.keSTScale()),
        ("C10-100", StandardScales.c10to100Scale()),
        ("C100-1000", StandardScales.c100to1000Scale()),
        ("CAS", StandardScales.casScale())
    ]
    
    for (name, definition) in scales {
        let generated = GeneratedScale(definition: definition)
        print("  ✓ \(name): \(generated.tickMarks.count) ticks")
    }
    
    print("✓ All specialty scales working!")
}

