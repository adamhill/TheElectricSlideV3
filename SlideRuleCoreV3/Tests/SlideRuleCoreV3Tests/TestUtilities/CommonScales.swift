import Testing
import Foundation
@testable import SlideRuleCoreV3

// MARK: - Scale Instantiation Helpers

/// Quick access to commonly-used scale definitions for testing
enum CommonScales {
    
    // MARK: Basic Scales
    
    static func c(length:Double = 250.0) -> ScaleDefinition {
        StandardScales.cScale(length: length)
    }
    
    static func d(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.dScale(length: length)
    }
    
    static func ci(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ciScale(length: length)
    }
    
    static func di(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.diScale(length: length)
    }
    
    // MARK: Power Scales
    
    static func a(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.aScale(length: length)
    }
    
    static func b(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.bScale(length: length)
    }
    
    static func k(length: Double = 250.0) -> ScaleDefinition {
       StandardScales.kScale(length: length)
    }
    
    // MARK: Folded Scales
    
    static func cf(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.cfScale(length: length)
    }
    
    static func df(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.dfScale(length: length)
    }
    
    static func cif(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.cifScale(length: length)
    }
    
    static func dif(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.difScale(length: length)
    }
    
    // MARK: Trigonometric Scales
    
    static func s(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.sScale(length: length)
    }
    
    static func t(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.tScale(length: length)
    }
    
    static func st(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.stScale(length: length)
    }
    
    // MARK: Linear Scales
    
    static func l(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.lScale(length: length)
    }
    
    static func ln(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.lnScale(length: length)
    }
    
    // MARK: Additional Log-Log Scales
    
    static func ll00(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ll00Scale(length: length)
    }
    
    static func ll01(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ll01Scale(length: length)
    }
    
    static func ll02(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ll02Scale(length: length)
    }
    
    static func ll03(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ll03Scale(length: length)
    }
    
    static func ll00B(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ll00BScale(length: length)
    }
    
    static func ll02B(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.ll02BScale(length: length)
    }
    
    static func h266LL01(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.h266LL01Scale(length: length)
    }
    
    static func h266LL03(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.h266LL03Scale(length: length)
    }
    
    // MARK: Extended Trig Scales
    
    static func t1(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.t1Scale(length: length)
    }
    
    static func t2(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.t2Scale(length: length)
    }
    
    static func keS(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.keSScale(length: length)
    }
    
    static func keT(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.keTScale(length: length)
    }
    
    static func keST(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.keSTScale(length: length)
    }
    
    // MARK: Extended Range Scales
    
    static func c10to100(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.c10to100Scale(length: length)
    }
    
    static func c100to1000(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.c100to1000Scale(length: length)
    }
    
    static func d10to100(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.d10to100Scale(length: length)
    }
    
    // MARK: Specialized Scales
    
    static func cas(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.casScale(length: length)
    }
    
    static func time(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.timeScale(length: length)
    }
    
    static func time2(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.time2Scale(length: length)
    }
    
    static func cr3s(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.cr3sScale(length: length)
    }
    
    static func r1(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.r1Scale(length: length)
    }
    
    static func r2(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.r2Scale(length: length)
    }
    
    static func q1(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.q1Scale(length: length)
    }
    
    static func q2(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.q2Scale(length: length)
    }
    
    static func q3(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.q3Scale(length: length)
    }
    
    // MARK: Power Inverted Scales
    
    static func ai(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.aiScale(length: length)
    }
    
    static func bi(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.biScale(length: length)
    }
    
    // MARK: DFm Variant
    
    static func dfmPostScript(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.dfmPostScriptScale(length: length)
    }
    
    // MARK: Hyperbolic Scales
    
    static func ch(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.chScale(length: length)
    }
    
    static func th(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.thScale(length: length)
    }
    
    static func sh(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.shScale(length: length)
    }
    
    static func sh1(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.sh1Scale(length: length)
    }
    
    static func sh2(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.sh2Scale(length: length)
    }
    
    static func h1(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.h1Scale(length: length)
    }
    
    static func h2(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.h2Scale(length: length)
    }
    
    static func p(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.pScale(length: length)
    }
    
    static func l360(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.l360Scale(length: length)
    }
    
    static func l180(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.l180Scale(length: length)
    }
    
    static func pa(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.paScale(length: length)
    }
    
    // MARK: Electrical Engineering Scales
    
    static func xl(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.xlScale(length: length)
    }
    
    static func xc(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.xcScale(length: length)
    }
    
    static func eef(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eefScale(length: length)
    }
    
    static func eefo(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eefoScale(length: length)
    }
    
    static func eeInductance(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eeInductanceScale(length: length)
    }
    
    static func eeInductanceInverted(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eeInductanceInvertedScale(length: length)
    }
    
    static func cz(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.czScale(length: length)
    }
    
    static func eeCapacitanceFrequency(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eeCapacitanceFrequencyScale(length: length)
    }
    
    static func z(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.zScale(length: length)
    }
    
    static func eeReflectionCoefficient(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eeReflectionCoefficientScale(length: length)
    }
    
    static func eeReflectionCoefficient2(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eeReflectionCoefficient2Scale(length: length)
    }
    
    static func eePowerRatio(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eePowerRatioScale(length: length)
    }
    
    static func eePowerRatioInverted(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.eePowerRatioInvertedScale(length: length)
    }
    
    // MARK: Pickett N16-ES Scales
    
    static func inductanceReciprocal(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.inductanceReciprocalScale(length: length)
    }
    
    static func capacitanceReciprocal(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.capacitanceReciprocalScale(length: length)
    }
    
    static func pickettL(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.pickettLScale(length: length)
    }
    
    static func pickettD(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.pickettDScale(length: length)
    }
    
    static func pickettQ(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.pickettQScale(length: length)
    }
    
    static func pickettF(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.pickettFScale(length: length)
    }
    
    static func wavelengthLambda(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.wavelengthLambdaScale(length: length)
    }
    
    static func phaseAngleTheta(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.phaseAngleThetaScale(length: length)
    }
    
    static func cosinePowerFactor(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.cosinePowerFactorScale(length: length)
    }
    
    static func decibelPower(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.decibelPowerScale(length: length)
    }
    
    static func decibelVoltage(length: Double = 250.0) -> ScaleDefinition {
        StandardScales.decibelVoltageScale(length: length)
    }
}
