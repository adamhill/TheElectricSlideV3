// File: TheElectricSlideTests/PDF/TestScaleFactory.swift

import Foundation
import SlideRuleCoreV3

enum TestScaleFactory {
    static func createEmptySlideRule() -> SlideRule {
        return SlideRule(
            frontTopStator: Stator(name: "Top", scales: [], heightInPoints: 100),
            frontSlide: Slide(name: "Slide", scales: [], heightInPoints: 100),
            frontBottomStator: Stator(name: "Bottom", scales: [], heightInPoints: 100),
            totalLengthInPoints: 708
        )
    }
    
    static func createSimpleScale(name: String, length: Distance = 708) -> GeneratedScale {
        let definition = StandardScales.cScale(length: length)
        return GeneratedScale(definition: definition)
    }
}
