//
//  SlideRuleLibrary.swift
//  TheElectricSlide
//
//  Created by Adam Hill on 10/26/25.
//

import Foundation

/// Factory for creating standard slide rule definitions based on the PostScript reference
struct SlideRuleLibrary {
    
    /// All standard slide rule definitions from the PostScript engine
    static func standardRules() -> [SlideRuleDefinitionModel] {
        [
            keuffelEsser4081_3(),
            hemmi266(),
            hemmi266ThinkGeek(),
            ultralog(),
            keLon(),
            dsp01(),
            circularCR3(),
            circularCR3P(),
            circularCR3Combined(),
            basicDuplex(),
            mannheim(),
        ]
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
    /// Front: LL03 LL01 LL02B LL2B- A [ B BI CI C ] D L- S T-
    /// Back:  Electrical engineering scales
    static func hemmi266() -> SlideRuleDefinitionModel {
        SlideRuleDefinitionModel(
            name: "Hemmi 266",
            description: "Japanese precision slide rule with electrical engineering scales on the back.",
            definitionString: "(K A [ B BI CI C ] D L- S T- : DF [ CF CIF CI C ] D)",
            topStatorMM: 15,
            slideMM: 15,
            bottomStatorMM: 15,
            sortOrder: 1
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
