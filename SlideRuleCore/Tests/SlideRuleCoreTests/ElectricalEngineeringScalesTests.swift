import Testing
import Foundation
@testable import SlideRuleCore

/// Tests for Electrical Engineering Scale Definitions (factory methods)
/// Verifies scale configuration, ranges, functions, and EE-specific properties
@Suite("Electrical Engineering Scale Definitions", .tags(.fast, .regression))
struct ElectricalEngineeringScalesTests {
    
    // MARK: - Reactance Scales
    
    @Suite("XL/Xc Scales - Inductive and Capacitive Reactance")
    struct ReactanceScalesTests {
        
        @Test("XL scale has correct basic properties")
        func xlScaleBasicProperties() {
            let xl = StandardScales.xlScale(length: 250.0)
            
            #expect(xl.name == "XL")
            #expect(xl.beginValue == 1.0)
            #expect(xl.endValue == 100.0)
            #expect(xl.scaleLengthInPoints == 250.0)
            #expect(xl.tickDirection == .up)
        }
        
        @Test("XL scale uses InductiveReactanceFunction with 12 cycles")
        func xlScaleFunctionType() {
            let xl = StandardScales.xlScale(length: 250.0)
            #expect(xl.function is InductiveReactanceFunction)
            
            // Verify 12 cycles by checking function behavior
            if let xlFunc = xl.function as? InductiveReactanceFunction {
                #expect(xlFunc.cycles == 12)
            }
        }
        
        @Test("XL scale has green label color")
        func xlScaleGreenLabels() {
            let xl = StandardScales.xlScale(length: 250.0)
            
            // Verify green label color
            if let labelColor = xl.labelColor {
                #expect(labelColor.green == 0.5)
                #expect(labelColor.red == 0.0)
                #expect(labelColor.blue == 0.0)
            } else {
                Issue.record("XL scale should have label color")
            }
        }
        
        @Test("XL scale has appropriate subsections")
        func xlScaleSubsections() {
            let xl = StandardScales.xlScale(length: 250.0)
            #expect(xl.subsections.count >= 5)
            #expect(xl.subsections[0].startValue == 1.0)
        }
        
        @Test("Xc scale has correct basic properties")
        func xcScaleBasicProperties() {
            let xc = StandardScales.xcScale(length: 250.0)
            
            #expect(xc.name == "Xc")
            #expect(xc.beginValue == 100.0)
            #expect(xc.endValue == 1.0)
            #expect(xc.scaleLengthInPoints == 250.0)
            #expect(xc.tickDirection == .down)
        }
        
        @Test("Xc scale uses CapacitiveReactanceFunction with 12 cycles inverted")
        func xcScaleFunctionType() {
            let xc = StandardScales.xcScale(length: 250.0)
            #expect(xc.function is CapacitiveReactanceFunction)
            
            // Verify 12 cycles
            if let xcFunc = xc.function as? CapacitiveReactanceFunction {
                #expect(xcFunc.cycles == 12)
            }
        }
        
        @Test("Xc scale has red label color")
        func xcScaleRedLabels() {
            let xc = StandardScales.xcScale(length: 250.0)
            
            // Verify red label color
            if let labelColor = xc.labelColor {
                #expect(labelColor.red == 1.0)
                #expect(labelColor.green == 0.0)
                #expect(labelColor.blue == 0.0)
            } else {
                Issue.record("Xc scale should have label color")
            }
        }
        
        @Test("XL and Xc scales are inverted relative to each other")
        func xlXcInversion() {
            let xl = StandardScales.xlScale(length: 250.0)
            let xc = StandardScales.xcScale(length: 250.0)
            
            #expect(xl.beginValue == xc.endValue)
            #expect(xl.endValue == xc.beginValue)
            #expect(xl.tickDirection != xc.tickDirection)
        }
    }
    
    // MARK: - Frequency Scales
    
    @Suite("F/Fo Scales - Frequency and Wavelength")
    struct FrequencyScalesTests {
        
        @Test("F scale has correct basic properties")
        func fScaleBasicProperties() {
            let f = StandardScales.fScale(length: 250.0)
            
            #expect(f.name == "F")
            #expect(f.beginValue == 1.0)
            #expect(f.endValue == 100.0)
            #expect(f.scaleLengthInPoints == 250.0)
            #expect(f.tickDirection == .up)
        }
        
        @Test("F scale uses FrequencyFunction with 12 cycles")
        func fScaleFunctionType() {
            let f = StandardScales.fScale(length: 250.0)
            #expect(f.function is FrequencyFunction)
            
            if let fFunc = f.function as? FrequencyFunction {
                #expect(fFunc.cycles == 12)
            }
        }
        
        @Test("F scale has appropriate subsections")
        func fScaleSubsections() {
            let f = StandardScales.fScale(length: 250.0)
            #expect(f.subsections.count >= 5)
        }
        
        @Test("Fo scale has correct basic properties")
        func foScaleBasicProperties() {
            let fo = StandardScales.foScale(length: 250.0)
            
            #expect(fo.name == "Fo")
            #expect(fo.beginValue == 100.0)
            #expect(fo.endValue == 1.0)
            #expect(fo.scaleLengthInPoints == 250.0)
            #expect(fo.tickDirection == .down)
        }
        
        @Test("Fo scale uses FrequencyWavelengthFunction with 6 cycles")
        func foScaleFunctionType() {
            let fo = StandardScales.foScale(length: 250.0)
            #expect(fo.function is FrequencyWavelengthFunction)
            
            if let foFunc = fo.function as? FrequencyWavelengthFunction {
                #expect(foFunc.cycles == 6)
            }
        }
        
        @Test("Fo scale is inverted for wavelength relationship")
        func foScaleInverted() {
            let fo = StandardScales.foScale(length: 250.0)
            
            #expect(fo.beginValue > fo.endValue, "Fo should be inverted")
            #expect(fo.tickDirection == .down)
        }
    }
    
    // MARK: - Component Scales
    
    @Suite("L/Li/Cz/Cf Scales - Inductance and Capacitance")
    struct ComponentScalesTests {
        
        @Test("L scale has correct basic properties")
        func lScaleBasicProperties() {
            let l = StandardScales.eeInductanceScale(length: 250.0)
            
            #expect(l.name == "L")
            #expect(l.beginValue == 1.0)
            #expect(l.endValue == 100.0)
            #expect(l.scaleLengthInPoints == 250.0)
            #expect(l.tickDirection == .up)
        }
        
        @Test("L scale uses InductanceFunction with 12 cycles")
        func lScaleFunctionType() {
            let l = StandardScales.eeInductanceScale(length: 250.0)
            #expect(l.function is InductanceFunction)
            
            if let lFunc = l.function as? InductanceFunction {
                #expect(lFunc.cycles == 12)
            }
        }
        
        @Test("Li scale has correct basic properties")
        func liScaleBasicProperties() {
            let li = StandardScales.eeInductanceInvertedScale(length: 250.0)
            
            #expect(li.name == "Li")
            #expect(li.beginValue == 100.0)
            #expect(li.endValue == 1.0)
            #expect(li.scaleLengthInPoints == 250.0)
            #expect(li.tickDirection == .down)
        }
        
        @Test("Li scale uses InductanceFunction with 12 cycles inverted")
        func liScaleFunctionType() {
            let li = StandardScales.eeInductanceInvertedScale(length: 250.0)
            #expect(li.function is InductanceFunction)
        }
        
        @Test("Li scale has TL/XL constants")
        func liScaleConstants() {
            let li = StandardScales.eeInductanceInvertedScale(length: 250.0)
            
            #expect(li.constants.count == 2)
            
            let hasLabelTL = li.constants.contains { $0.label == "TL" }
            let hasLabelXL = li.constants.contains { $0.label == "XL" }
            
            #expect(hasLabelTL, "Li should have TL constant")
            #expect(hasLabelXL, "Li should have XL constant")
        }
        
        @Test("Cz scale has correct basic properties")
        func czScaleBasicProperties() {
            let cz = StandardScales.czScale(length: 250.0)
            
            #expect(cz.name == "Cz")
            #expect(cz.beginValue == 1.0)
            #expect(cz.endValue == 100.0)
            #expect(cz.scaleLengthInPoints == 250.0)
            #expect(cz.tickDirection == .up)
        }
        
        @Test("Cz scale uses CapacitanceImpedanceFunction with 12 cycles")
        func czScaleFunctionType() {
            let cz = StandardScales.czScale(length: 250.0)
            #expect(cz.function is CapacitanceImpedanceFunction)
            
            if let czFunc = cz.function as? CapacitanceImpedanceFunction {
                #expect(czFunc.cycles == 12)
            }
        }
        
        @Test("Cz scale has TC/fm constant")
        func czScaleConstants() {
            let cz = StandardScales.czScale(length: 250.0)
            
            #expect(cz.constants.count >= 1)
            
            let hasTCfm = cz.constants.contains { $0.label == "TC/fm" }
            #expect(hasTCfm, "Cz should have TC/fm constant")
        }
        
        @Test("Cf scale has correct basic properties")
        func cfScaleBasicProperties() {
            let cf = StandardScales.eeCapacitanceFrequencyScale(length: 250.0)
            
            #expect(cf.name == "Cf")
            #expect(cf.beginValue == 100.0)
            #expect(cf.endValue == 1.0)
            #expect(cf.scaleLengthInPoints == 250.0)
            #expect(cf.tickDirection == .down)
        }
        
        @Test("Cf scale uses CapacitanceFrequencyFunction with 11 cycles")
        func cfScaleFunctionType() {
            let cf = StandardScales.eeCapacitanceFrequencyScale(length: 250.0)
            #expect(cf.function is CapacitanceFrequencyFunction)
            
            if let cfFunc = cf.function as? CapacitanceFrequencyFunction {
                #expect(cfFunc.cycles == 11)
            }
        }
        
        @Test("Cf scale has XC constant")
        func cfScaleConstants() {
            let cf = StandardScales.eeCapacitanceFrequencyScale(length: 250.0)
            
            #expect(cf.constants.count >= 1)
            
            let hasXC = cf.constants.contains { $0.label == "XC" }
            #expect(hasXC, "Cf should have XC constant")
        }
    }
    
    // MARK: - Impedance and Transmission Line Scales
    
    @Suite("Z/r1/r2 Scales - Impedance and Reflection")
    struct ImpedanceScalesTests {
        
        @Test("Z scale has correct basic properties")
        func zScaleBasicProperties() {
            let z = StandardScales.zScale(length: 250.0)
            
            #expect(z.name == "Z")
            #expect(z.beginValue == 1.0)
            #expect(z.endValue == 100.0)
            #expect(z.scaleLengthInPoints == 250.0)
            #expect(z.tickDirection == .up)
        }
        
        @Test("Z scale uses ImpedanceFunction with 6 cycles")
        func zScaleFunctionType() {
            let z = StandardScales.zScale(length: 250.0)
            #expect(z.function is ImpedanceFunction)
            
            if let zFunc = z.function as? ImpedanceFunction {
                #expect(zFunc.cycles == 6)
            }
        }
        
        @Test("r1 scale has correct basic properties")
        func r1ScaleBasicProperties() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            
            #expect(r1.name == "r1")
            #expect(r1.beginValue == 0.5)
            #expect(r1.endValue == 50.0)
            #expect(r1.scaleLengthInPoints == 250.0)
            #expect(r1.tickDirection == .up)
        }
        
        @Test("r1 scale uses ReflectionCoefficientFunction")
        func r1ScaleFunctionType() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            #expect(r1.function is ReflectionCoefficientFunction)
        }
        
        @Test("r1 scale has red label color")
        func r1ScaleRedLabels() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            
            if let labelColor = r1.labelColor {
                #expect(labelColor.red == 1.0)
                #expect(labelColor.green == 0.0)
                #expect(labelColor.blue == 0.0)
            } else {
                Issue.record("r1 scale should have label color")
            }
        }
        
        @Test("r1 scale has infinity constant")
        func r1ScaleInfinityConstant() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            
            #expect(r1.constants.count >= 1)
            
            let hasInfinity = r1.constants.contains { $0.label == "∞" }
            #expect(hasInfinity, "r1 should have infinity constant")
        }
        
        @Test("r1 scale has many subsections for wide range")
        func r1ScaleSubsections() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            #expect(r1.subsections.count >= 8)
        }
        
        @Test("r2 scale has correct basic properties")
        func r2ScaleBasicProperties() {
            let r2 = StandardScales.eeReflectionCoefficient2Scale(length: 250.0)
            
            #expect(r2.name == "r2")
            #expect(r2.beginValue == 0.5)
            #expect(r2.endValue == 50.0)
            #expect(r2.scaleLengthInPoints == 250.0)
            #expect(r2.tickDirection == .down)
        }
        
        @Test("r2 scale uses ReflectionCoefficientFunction")
        func r2ScaleFunctionType() {
            let r2 = StandardScales.eeReflectionCoefficient2Scale(length: 250.0)
            #expect(r2.function is ReflectionCoefficientFunction)
        }
        
        @Test("r2 scale has tick direction down")
        func r2ScaleTickDirectionDown() {
            let r2 = StandardScales.eeReflectionCoefficient2Scale(length: 250.0)
            #expect(r2.tickDirection == .down)
        }
        
        @Test("r2 scale has infinity constant")
        func r2ScaleInfinityConstant() {
            let r2 = StandardScales.eeReflectionCoefficient2Scale(length: 250.0)
            
            let hasInfinity = r2.constants.contains { $0.label == "∞" }
            #expect(hasInfinity, "r2 should have infinity constant")
        }
        
        @Test("r1 and r2 scales are mirror images")
        func r1R2Mirror() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            let r2 = StandardScales.eeReflectionCoefficient2Scale(length: 250.0)
            
            #expect(r1.beginValue == r2.beginValue)
            #expect(r1.endValue == r2.endValue)
            #expect(r1.tickDirection != r2.tickDirection)
        }
    }
    
    // MARK: - Power Scales
    
    @Suite("P/Q Scales - Power Ratio (dB)")
    struct PowerScalesTests {
        
        @Test("P scale has correct basic properties")
        func pScaleBasicProperties() {
            let p = StandardScales.eePowerRatioScale(length: 250.0)
            
            #expect(p.name == "P")
            #expect(p.beginValue == 0.0)
            #expect(p.endValue == 14.0)
            #expect(p.scaleLengthInPoints == 250.0)
            #expect(p.tickDirection == .up)
        }
        
        @Test("P scale uses PowerRatioFunction")
        func pScaleFunctionType() {
            let p = StandardScales.eePowerRatioScale(length: 250.0)
            #expect(p.function is PowerRatioFunction)
        }
        
        @Test("P scale has green label color")
        func pScaleGreenLabels() {
            let p = StandardScales.eePowerRatioScale(length: 250.0)
            
            if let labelColor = p.labelColor {
                #expect(labelColor.green == 0.5)
                #expect(labelColor.red == 0.0)
                #expect(labelColor.blue == 0.0)
            } else {
                Issue.record("P scale should have label color")
            }
        }
        
        @Test("P scale position calculations for key values",
              arguments: [0.0, 3.0, 6.0, 10.0, 14.0])
        func pScalePositionCalculations(value: Double) {
            let p = StandardScales.eePowerRatioScale(length: 250.0)
            let pos = ScaleCalculator.normalizedPosition(for: value, on: p)
            #expect(pos >= 0.0 && pos <= 1.0)
            
            let recovered = ScaleCalculator.value(at: pos, on: p)
            let absoluteError = abs(recovered - value)
            #expect(absoluteError < 0.5)
        }
        
        @Test("Q scale has correct basic properties")
        func qScaleBasicProperties() {
            let q = StandardScales.eePowerRatioInvertedScale(length: 250.0)
            
            #expect(q.name == "Q")
            #expect(q.beginValue == 0.0)
            #expect(q.endValue == 14.0)
            #expect(q.scaleLengthInPoints == 250.0)
            #expect(q.tickDirection == .down)
        }
        
        @Test("Q scale uses PowerRatioFunction")
        func qScaleFunctionType() {
            let q = StandardScales.eePowerRatioInvertedScale(length: 250.0)
            #expect(q.function is PowerRatioFunction)
        }
        
        @Test("Q scale has tick direction down")
        func qScaleTickDirectionDown() {
            let q = StandardScales.eePowerRatioInvertedScale(length: 250.0)
            #expect(q.tickDirection == .down)
        }
        
        @Test("P and Q scales are mirror images")
        func pqMirror() {
            let p = StandardScales.eePowerRatioScale(length: 250.0)
            let q = StandardScales.eePowerRatioInvertedScale(length: 250.0)
            
            #expect(p.beginValue == q.beginValue)
            #expect(p.endValue == q.endValue)
            #expect(p.tickDirection != q.tickDirection)
        }
    }
    
    // MARK: - Scale Instantiation Tests
    
    @Suite("EE Scales - Instantiation and Generation")
    struct EEScalesInstantiationTests {
        
        @Test("All EE scales can be instantiated without errors")
        func allScalesInstantiate() {
            let scales = [
                StandardScales.xlScale(),
                StandardScales.xcScale(),
                StandardScales.fScale(),
                StandardScales.foScale(),
                StandardScales.eeInductanceScale(),
                StandardScales.eeInductanceInvertedScale(),
                StandardScales.czScale(),
                StandardScales.eeCapacitanceFrequencyScale(),
                StandardScales.zScale(),
                StandardScales.eeReflectionCoefficientScale(),
                StandardScales.eeReflectionCoefficient2Scale(),
                StandardScales.eePowerRatioScale(),
                StandardScales.eePowerRatioInvertedScale()
            ]
            
            for scale in scales {
                #expect(scale.scaleLengthInPoints > 0)
                #expect(scale.name.count > 0)
                #expect(!scale.subsections.isEmpty)
            }
        }
        
        @Test("All EE scales work with custom lengths",
              arguments: [100.0, 250.0, 500.0])
        func allScalesCustomLengths(length: Double) {
            let scales = [
                StandardScales.xlScale(length: length),
                StandardScales.xcScale(length: length),
                StandardScales.fScale(length: length),
                StandardScales.foScale(length: length),
                StandardScales.zScale(length: length)
            ]
            
            for scale in scales {
                #expect(scale.scaleLengthInPoints == length)
            }
        }
        
        @Test("All EE scales generate ticks successfully")
        func allScalesGenerateTicks() {
            let scales = [
                StandardScales.xlScale(),
                StandardScales.xcScale(),
                StandardScales.fScale(),
                StandardScales.foScale(),
                StandardScales.eeInductanceScale(),
                StandardScales.eeInductanceInvertedScale(),
                StandardScales.czScale(),
                StandardScales.eeCapacitanceFrequencyScale(),
                StandardScales.zScale(),
                StandardScales.eeReflectionCoefficientScale(),
                StandardScales.eeReflectionCoefficient2Scale(),
                StandardScales.eePowerRatioScale(),
                StandardScales.eePowerRatioInvertedScale()
            ]
            
            for scale in scales {
                let generated = GeneratedScale(definition: scale)
                #expect(!generated.tickMarks.isEmpty,
                       "\(scale.name) should generate non-empty ticks")
            }
        }
        
        @Test("Multi-cycle scales have correct function configuration",
              arguments: [(12, "XL"), (12, "Xc"), (12, "F"), (6, "Fo"), (12, "L"), (12, "Cz"), (11, "Cf"), (6, "Z")])
        func multiCycleScales(expectedCycles: Int, scaleName: String) {
            let scale: ScaleDefinition
            
            switch scaleName {
            case "XL": scale = StandardScales.xlScale()
            case "Xc": scale = StandardScales.xcScale()
            case "F": scale = StandardScales.fScale()
            case "Fo": scale = StandardScales.foScale()
            case "L": scale = StandardScales.eeInductanceScale()
            case "Cz": scale = StandardScales.czScale()
            case "Cf": scale = StandardScales.eeCapacitanceFrequencyScale()
            case "Z": scale = StandardScales.zScale()
            default: return
            }
            
            // Verify that the scale's function has the expected number of cycles
            // This is checked through the function's cycle property
            if let xlFunc = scale.function as? InductiveReactanceFunction {
                #expect(xlFunc.cycles == expectedCycles)
            } else if let xcFunc = scale.function as? CapacitiveReactanceFunction {
                #expect(xcFunc.cycles == expectedCycles)
            } else if let fFunc = scale.function as? FrequencyFunction {
                #expect(fFunc.cycles == expectedCycles)
            } else if let foFunc = scale.function as? FrequencyWavelengthFunction {
                #expect(foFunc.cycles == expectedCycles)
            } else if let lFunc = scale.function as? InductanceFunction {
                #expect(lFunc.cycles == expectedCycles)
            } else if let czFunc = scale.function as? CapacitanceImpedanceFunction {
                #expect(czFunc.cycles == expectedCycles)
            } else if let cfFunc = scale.function as? CapacitanceFrequencyFunction {
                #expect(cfFunc.cycles == expectedCycles)
            } else if let zFunc = scale.function as? ImpedanceFunction {
                #expect(zFunc.cycles == expectedCycles)
            }
        }
        
        @Test("Inverted scales have correct range ordering")
        func invertedScalesRangeOrdering() {
            let invertedScales = [
                StandardScales.xcScale(),
                StandardScales.foScale(),
                StandardScales.eeInductanceInvertedScale(),
                StandardScales.eeCapacitanceFrequencyScale(),
                StandardScales.eePowerRatioInvertedScale()
            ]
            
            for scale in invertedScales {
                // Inverted scales should have begin > end or tick direction down
                let isInverted = (scale.beginValue > scale.endValue) || (scale.tickDirection == .down)
                #expect(isInverted, "\(scale.name) should be inverted")
            }
        }
        
        @Test("Color-coded scales have appropriate label colors")
        func colorCodedScales() {
            let greenScales = [
                StandardScales.xlScale(),
                StandardScales.eePowerRatioScale()
            ]
            
            for scale in greenScales {
                if let labelColor = scale.labelColor {
                    #expect(labelColor.green > 0.0, "\(scale.name) should have green component")
                } else {
                    Issue.record("\(scale.name) should have label color")
                }
            }
            
            let redScales = [
                StandardScales.xcScale(),
                StandardScales.eeReflectionCoefficientScale()
            ]
            
            for scale in redScales {
                if let labelColor = scale.labelColor {
                    #expect(labelColor.red > 0.0, "\(scale.name) should have red component")
                } else {
                    Issue.record("\(scale.name) should have label color")
                }
            }
        }
    }
}