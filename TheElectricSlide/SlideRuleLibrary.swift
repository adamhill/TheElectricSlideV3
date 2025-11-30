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
    /// Version 5: Added Pickett N-16 ES Electronic slide rule
    static let libraryVersion = 5
    
    /// All standard slide rule definitions from the PostScript engine
    /// Each rule is tagged with the current library version
    static func standardRules() -> [SlideRuleDefinitionModel] {
        let rules = [
            keuffelEsser4081_3(),
            hemmi266(),
            hemmi266ThinkGeek(),
            ultralog(),
            keLon(),
            dsp01(),
            pickettN3Powerlog(),
            pickettN16ES(),
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
            sortOrder: 0
        )
    }
    
    /// Hemmi 266 Standard
    /// Front: H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank
    /// Back:  Electrical engineering scales
    static func hemmi266() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Hemmi 266",
            description: "Japanese precision slide rule with electrical engineering scales on the back.",
            definitionString: "(H266LL03 H266LL01^ LL02B LL2B- A [ B BI CI C ] D L- S T- : eeXl eeXc eeF eer1 eeP^ [ eer2^ eeQ eeLi eeCf eeCz ] eeL eeZ eeFo blank)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 1,
            scaleNameOverrides: [
                "L": "㏈ L", // Hemmi 266 labels L scale as "dB L"
                "H266LL01": "L̅L̅1",
                "H266LL03": "L̅L̅3"
            ]
        )
    }
    
    /// Hemmi 266 ThinkGeek Variant
    /// Extended slide with hyperbolic functions
    static func hemmi266ThinkGeek() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Hemmi 266 ThinkGeek Edition",
            description: "Extended Hemmi 266 variant with hyperbolic functions (Sh, Th) and additional scales.",
            definitionString: "(K A [ B BI Sh1 Sh2 Th CI C ] D DI P L : DF [ CF CIF ST S | T- CI C ] D)",
            topStatorMM: 13,
            slideMM: 22,
            bottomStatorMM: 13,
            sortOrder: 2
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
            sortOrder: 3
        )
    }
    
    /// Keuffel & Esser KeLon
    /// Specialized long-form slide rule
    static func keLon() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "K&E KeLon",
            description: "Specialized Keuffel & Esser long-form slide rule with extended precision.",
            definitionString: "(DF [ CF CIF | L CI C ] D : Sh1 Sh2 Th A [ B | T ST S C ] D DI K-)",
            topStatorMM: 19,
            slideMM: 19,
            bottomStatorMM: 19,
            sortOrder: 4
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
            sortOrder: 5
        )
    }
    
    /// Pickett N3 Powerlog - Exponential
    static func pickettN3Powerlog() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Pickett N3 Powerlog",
            description: "Sophisticated dual-base duplex slide rule with 32 scales, featuring extended-precision square root, cube root, and tangent scales. Includes comprehensive log-log scales (LL0-LL3±) with extended range for exponential calculations. One of Pickett's most powerful general-purpose scientific computing rules.",
            definitionString: "(K A [ B ST S T1 T2- CI C ] D DI : LL00 LL00- LL01 LL1- DF [ CF CIF Ln L CI C ] D LL02 LL2- LL03 LL3-)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 6
        )
    }
    
    /// Pickett N-16 ES Electronic - Professional Electronics Slide Rule
    /// Front: SH1, SH2, TH, DF [ CF, L, S, ST, T1 T2, CI, C ] D, LL3, LL2, LL1, Ln
    /// Back:  Θ, db, D/Q, XL, Xc [ C/L, F, λ, ω, τ, Cr ] Lr, db, CosΘ
    static func pickettN16ES() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Pickett N-16 ES Electronic",
            description: """
            Professional 32-scale electronics slide rule designed by Chan Street (circa 1960) for \
            RF engineering, filter design, and AC circuit analysis. Manufactured by Pickett Industries \
            (Alhambra, California). Featured revolutionary four-decade component scales (Lr, Cr) with \
            embedded reciprocal functions for direct f = 1/(2π√LC) resonance calculation. The "-ES" \
            Eye-Saver yellow aluminum construction (5600Å wavelength) reduced eye strain. Used during \
            the Apollo space program for S-band RF calculations and antenna design. Simultaneous \
            triple reading of gain, phase, and dB from single cursor position.
            """,
            definitionString: "(SH1 SH2 TH DF [ CF L S ST T1 T2 CI C ] D LL3 LL2 LL1 Ln : Θ db D/Q XL Xc [ C/L N16F λ ω τ Cr ] Lr db CosΘ)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 7,
            scaleNameOverrides: [
                "db": "dB",           // Decibel notation
                "CosΘ": "cos Θ",      // Cosine of phase
                "N16F": "F"           // Frequency scale display name
            ]
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
            sortOrder: 20
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
            sortOrder: 21
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
            sortOrder: 22
        )
    }
}
