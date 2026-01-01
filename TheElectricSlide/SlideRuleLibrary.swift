//
//  SlideRuleLibrary.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/26/25.
//

import Foundation

/// Factory for creating standard slide rule definitions based on the PostScript reference
struct SlideRuleLibrary {
    
    /// Current version of the slide rule library
    /// Increment this when adding/removing/modifying rules
    /// Version 1: Initial library
    /// Version 2: Added Pickett N3
    /// Version 3: Added scale name overrides (Hemmi 266 "dB L")
    /// Version 4: Updated Hemmi 266 scale name overrides (H266LL01, H266LL03)
    /// Version 5: Added Pickett N-16 ES Electronic with 32 specialized scales
    /// Version 6: Updated Pickett N-16 ES definition (fix for old cached version)
    /// Version 7: Updated Pickette N3 Added SQ1 SQ2 Q1 Q2 Q3 scales
    /// Version 8: Fixed K&E 4081-3 corruption (sortOrder collision with Pickett N-16 ES)
    /// Version 9: Fixed Hemmi 266 sortOrder collision with K&E 4081-3
    /// Version 10: Added Faber-Castell 62/83 N with W scale aliases (W1→R1, W2→R2, W1'→SQ1, W2'→SQ2)
    /// Version 11: Implemented Pickett N-16 ES pickettF (PF) Scale (frequency in MHz, 0.1-10 MHz range)
    /// Version 12: Added manufacturer field for colorway support (Pickett, Faber-Castell, K&E, Hemmi)
    /// Version 13: Added α (Alpha) phase angle scale to Pickett N-16 ES back top stator (complements Θ scale)
    /// Version 14: Added Θ₁ and Θ₂ (Theta subscript) scales to Pickett N-16 ES back top stator (phase angle scales)
    /// Version 15: Added | to Θ₁ and Θ₂ to test out physical ranges (Theta subscript) scales to Pickett N-16 ES back top stator (phase angle scales)
    /// Version 16: Added - to Θ₂ to flip ticks to test out physical ranges (Theta subscript) scales to Pickett N-16 ES back top stator (phase angle scales)
    /// Version 17: Changed Θ₁ | Θ₂ to Θ₁^ Θ₂ for split scale rendering (^ = split pair, | = visual separator)
    /// Version 18: Enabled showBaseline=true for THETA scales (shared baseline with ALPHA)
    /// Version 19: Fixed THETA domain: 6.0°→0.57°→6.0° with no tick at 6.0°, first/last visible tick at 5.7°
    /// Version 20: Fixed Θ₂ tick direction: changed Θ₂- to Θ₂^ (both scales need ticks UP, not DOWN)
    /// Version 21: Fixed ^ in the wrong place

    static let libraryVersion = 21
    
    /// All standard slide rule definitions from the PostScript engine
    /// Each rule is tagged with the current library version
    static func standardRules() -> [SlideRuleDefinitionModel] {
        let rules = [
            pickettN16ESElectronic(),
            keuffelEsser4081_3(),
            fabercastell6283N(),
            hemmi266(),
            hemmi266ThinkGeek(),
            ultralog(),
            keLon(),
            dsp01(),
            pickettN3Powerlog(),
            circularCR3(),
            circularCR3P(),
            circularCR3Combined(),
            basicDuplex(),
            mannheim(),
        ]
        
        // Tag all rules with current library version
        return rules.map { rule in
            rule.libraryVersion = libraryVersion
            return rule
        }
    }
    
    
    // MARK: - Linear Slide Rules
    
    static func fabercastell6283N() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Faber-Castell 62/83 N",
            description: "Faber-Castell NOVO DUPLEX pocket slide rule. " +
                "30-scale German precision instrument (1962-1976) with " +
                "split tangent scales, Pythagorean P scale, and " +
                "self-documenting formula annotations. 12.5cm scales.",
            definitionString: "(T1 T2 K A DF [ CF B CIF CI C ] D DI S ST P : " +
                "LL03 LL02 LL01 LL00 W2 [ W2' CI L C W1' ] W1 D^ LL0 LL1 LL2 LL3)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 20,
            scaleNameOverrides: [:],
            manufacturer: SlideRuleManufacturer.faberCastell.rawValue
        )
    }
    
    /// Pickett N-16 ES Electronic Slide Rule (circa 1960)
    /// Professional electronics slide rule with 32 specialized scales
    /// Designed by Chan Street for RF engineering, filter design, and impedance matching
    /// Front: SH1 SH2 TH DF [ CF L S Cos ST T CI C ] D LL3 LL2 LL1 Ln
    /// Back:  Θ db D XL Xc [ L F λ ω τ Cr ] Lr db CosΘ
    ///
    /// ## Historical Note: ω/τ Scale Alignment
    ///
    /// The ω (angular frequency) and τ (time constant) scales include an intentional
    /// offset in their transform functions so that at any position, ω × τ = 1.
    /// This reciprocal alignment was essential for electronics calculations and is
    /// a manufacturing artifact, not a mathematical error. The offset (~0.27-0.28)
    /// grows logarithmically from the reference point (ω=1, τ=1).
    ///
    /// This same alignment principle was used by:
    /// - Faber-Castell 2/83N (Germany), Aristo 0970 (Europe), Hemmi 266 (Japan)
    ///
    /// See: `PickettN16ESOmegaTauAlignmentTests.swift` for alignment verification.
    static func pickettN16ESElectronic() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Pickett N-16 ES Electronic",
            description: """
                Professional electronics slide rule with 32 specialized scales designed by Chan Street (circa 1960). \
                Features revolutionary four-decade component scales (picofarads to farads, nanohenries to henries), \
                reciprocal square root embedding for direct resonant frequency calculation (f = 1/(2π√LC)), and \
                simultaneous triple reading (gain, phase, dB) for filter response. Eye-Saver yellow aluminum coating \
                (5600Å wavelength). Used extensively in Apollo space program, color television development, RF engineering, \
                and impedance matching. Includes decimal keeper to prevent magnitude errors across extreme component value ranges. \
                Historical significance: First slide rule with embedded 2π factors in reactance scales and coordinated \
                phase/gain/dB scales for complete filter characterization from single cursor position.
                """,
            // NOTE: Θ₁^ Θ₂^ uses ^ (caret) for SPLIT SCALE - both render in same row
            // BOTH scales must have ticks pointing UP to share baseline with ALPHA below
            // Do NOT use - suffix on Θ₂ as that flips ticks DOWN (wrong direction!)
            definitionString: "(SH1 SH2- TH DF [ CF L S Cos ST T CI C ] D LL3 LL2 LL1 Ln : Θ₁^ Θ₂ α db D XL Xc [ L PF λ ω τ Cr ] Lr db CosΘ)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 0,
            scaleNameOverrides: [
                "D": "D/Q",          // Decimal keeper with Q-factor dual mode
                "L": "C/L",          // Combined capacitance/inductance scale
                "Cos": "cos",        // Lowercase for clarity
                "CosΘ": "cos Θ",     // Phase power factor with Greek letter
                "Θ": "θ",            // Phase angle (lowercase Greek)
                "λ": "λ",            // Wavelength (lowercase Greek)
                "ω": "ω",            // Angular frequency (lowercase Greek)
                "τ": "τ",
                "PF": "F"            // Time constant (lowercase Greek)
            ],
            manufacturer: SlideRuleManufacturer.pickett.rawValue
        )
    }
    
    /// Keuffel and Esser Log-Log Duplex Decitrig (4081-3)
    /// Front: LL01 K A [ B | T ST S ] D L- LL1-
    /// Back:  LL02 LL03 DF [ CF CIF | CI C ] D LL3- LL2-
    static func keuffelEsser4081_3() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "K&E 4081-3 Log-Log Duplex Decitrig",
            description: "Professional log-log duplex slide rule with trigonometric scales. Features LL scales for exponential calculations.",
            definitionString: "(LL01 K A [ B | T ST S ] D L- LL1- : LL02 LL03 DF [ CF CIF | CI C ] D LL3- LL2-)",
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14,
            sortOrder: 1,  // Changed from 0 to prevent collision with Pickett N-16 ES
            manufacturer: SlideRuleManufacturer.keuffelEsser.rawValue
        )
    }
    
    /// Hemmi 266 Standard
    /// Front: H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo
    /// Back:  Electrical engineering scales
    static func hemmi266() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Hemmi 266",
            description: "Japanese precision slide rule with electrical engineering scales on the back.",
            definitionString: "(H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 2,
            scaleNameOverrides: [
                "L": "㏈ L", // Hemmi 266 labels L scale as "dB L"
                "H266LL01": "L̅L̅1",
                "H266LL03": "L̅L̅3"
            ],
            manufacturer: SlideRuleManufacturer.hemmi.rawValue
        )
    }
    
    /// Hemmi 266 ThinkGeek Variant
    /// Extended slide with hyperbolic functions
    static func hemmi266ThinkGeek() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Hemmi 266 ThinkGeek Edition",
            description: "Extended Hemmi 266 variant with hyperbolic functions (Sh, Th) and additional scales.",
            definitionString: "(K A [ B BI SH1 SH2 TH CI C ] D DI P L : DF [ CF CIF ST S | T- CI C ] D)",
            topStatorMM: 13,
            slideMM: 22,
            bottomStatorMM: 13,
            sortOrder: 3,
            manufacturer: SlideRuleManufacturer.hemmi.rawValue
        )
    }
    
    /// Ultralog - Advanced Log-Log Rule
    /// Extensive LL scales from LL00 to LL3
    static func ultralog() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Ultralog Advanced",
            description: "Advanced slide rule with extensive log-log scales (LL00-LL3) and hyperbolic functions.",
            definitionString: "(DF [ CF CIF | Sh1- Sh2- Ch- Th- | Ln L CI C ] D : K A [ B | T- ST- S- | P H1 H2 | CI C ] D DI)",
            topStatorMM: 18.5,
            slideMM: 37,
            bottomStatorMM: 18.5,
            sortOrder: 4
        )
    }
    
    /// Keuffel & Esser KeLon
    /// Specialized long-form slide rule
    static func keLon() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "K&E KeLon",
            description: "Specialized Keuffel & Esser long-form slide rule with extended precision.",
            definitionString: "(DF [ CF CIF | L CI C ] D : SH1 SH2 TH A [ B | T ST S C ] D DI K-)",
            topStatorMM: 19,
            slideMM: 19,
            bottomStatorMM: 19,
            sortOrder: 5,
            manufacturer: SlideRuleManufacturer.keuffelEsser.rawValue
        )
    }
    
    /// DSP-01 Duplex
    /// Simplified duplex with common scales
    static func dsp01() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "DSP-01 Duplex",
            description: "Simplified duplex slide rule with common calculation scales.",
            definitionString: "(P DFm+ K A [ B ST S | T- CI ] D DI L | Ln- : LL01 LL02 LL03 DF [ CF CIF | CI C ] D  LL3- LL2- LL1-)",
            topStatorMM: 16,
            slideMM: 16,
            bottomStatorMM: 13,
            sortOrder: 6
        )
    }
    
    /// Pickett N3 Powerlog - Exponential
    static func pickettN3Powerlog() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Pickett N3 Powerlog",
            description: "Sophisticated dual-base duplex slide rule with 32 scales, featuring extended-precision square root, cube root, and tangent scales. Includes comprehensive log-log scales (LL0-LL3±) with extended range for exponential calculations. One of Pickett's most powerful general-purpose scientific computing rules.",
            definitionString: "(SQ1 SQ2- K A [ B ST S T1 T2- CI C ] D DI : LL00 LL00- LL01 LL1- DF [ CF CIF Ln L CI C ] D LL02 LL2- LL03 LL3- Q1 Q2 Q3-)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 7,
            manufacturer: SlideRuleManufacturer.pickett.rawValue
        )
    }
    
    /// Basic Duplex - Educational/Starter
    /// Simplified front and back with essential scales
    static func basicDuplex() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Basic Duplex",
            description: "Educational duplex slide rule with essential scales for learning.",
            definitionString: "(K A [ B T ST S ] D : DF [ CF CI C ] D)",
            topStatorMM: 14,
            slideMM: 13,
            bottomStatorMM: 14,
            sortOrder: 10
        )
    }
    
    /// Mannheim (single-sided, classic)
    /// Traditional German pattern
    static func mannheim() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Mannheim Standard",
            description: "Classic single-sided Mannheim pattern slide rule. Traditional German design.",
            definitionString: "(A [ B CI C ] D L)",
            topStatorMM: 12,
            slideMM: 12,
            bottomStatorMM: 12,
            sortOrder: 11
        )
    }
    
    // MARK: - Circular Slide Rules
    
    /// Circular Rule CR3 - Front Side
    /// Concise Circular - Time/Speed/Distance calculations
    static func circularCR3() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "CR3 Circular (Time/Speed)",
            description: "Circular slide rule for time, speed, and distance calculations. Front side.",
            definitionString: "(C10.100 [ CR3S L180 ])",
            topStatorMM: 3.5,
            slideMM: 17.5,
            bottomStatorMM: 0,
            circularSpec: "circular:5inch",
            sortOrder: 30
        )
    }
    
    /// Circular Rule CR3P - Alternate Back
    /// With angle/position scales
    static func circularCR3P() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "CR3P Circular (Angles)",
            description: "Circular slide rule with angle and position scales. Back side variant.",
            definitionString: "(C10.100 [ CAS L360 ])",
            topStatorMM: 3.5,
            slideMM: 14,
            bottomStatorMM: 0,
            circularSpec: "circular:5inch",
            sortOrder: 31
        )
    }
    
    /// Combined CR3 Front + Back
    static func circularCR3Combined() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "CR3 Combined Circular",
            description: "Combined circular rule with time/speed and angle scales on both sides.",
            definitionString: "(C10.100 [ D10.100 CAS PA ] : C10.100 [ CR3S L360 L180 ])",
            topStatorMM: 3.5,
            slideMM: 17.5,
            bottomStatorMM: 0,
            circularSpec: "circular:5inch",
            sortOrder: 32
        )
    }
}
