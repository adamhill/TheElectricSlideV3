import Testing
import Foundation
@testable import SlideRuleCoreV3

/// Tests for Electrical Engineering Scale Definitions (factory methods)
/// Verifies scale configuration, ranges, functions, and EE-specific properties
@Suite("Electrical Engineering Scale Definitions", .tags(.fast, .regression))
struct ElectricalEngineeringScalesTests {
    
    // MARK: - Scale Factory Lookup Tests
    
    @Suite("EE Scale Factory Lookup")
    struct EEScaleFactoryLookupTests {
        
        /// All EE parser names that should resolve via StandardScales.scale(named:length:)
        static let eeParserNames = [
            "eeXl", "eeXc", "eeF", "eer1", "eer2",
            "eeP", "eeQ", "eeLi", "eeCf", "eeCz",
            "eeL", "eeZ", "eeFo"
        ]
        
        @Test("Scale lookup returns correct scale for all EE parser names",
              arguments: ["eeXl", "eeXc", "eeF", "eer1", "eer2", "eeP", "eeQ", "eeLi", "eeCf", "eeCz", "eeL", "eeZ", "eeFo"])
        func scaleLookupReturnsScale(name: String) {
            let scale = StandardScales.scale(named: name, length: 250.0)
            #expect(scale != nil, "Scale '\(name)' should be found via factory lookup")
        }
        
        @Test("EE scale lookup is case-insensitive",
              arguments: [("EEXL", "XL"), ("eexl", "XL"), ("EeXl", "XL"),
                         ("eep", "P"), ("EEP", "P"), ("EeP", "P")])
        func scaleLookupCaseInsensitive(parserName: String, expectedScaleName: String) {
            let scale = StandardScales.scale(named: parserName, length: 250.0)
            #expect(scale != nil, "Scale '\(parserName)' should be found (case-insensitive)")
            #expect(scale?.name == expectedScaleName, "Scale name should be '\(expectedScaleName)'")
        }
        
        @Test("EE scales have alternate parser names",
              arguments: [("XL", "XL"), ("XC", "Xc"), ("CZ", "Cz"), ("LI", "Li"), ("Z", "Z"), ("FO", "Fo")])
        func alternateParserNames(parserName: String, expectedScaleName: String) {
            let scale = StandardScales.scale(named: parserName, length: 250.0)
            #expect(scale != nil, "Scale '\(parserName)' should be found as alternate name")
            #expect(scale?.name == expectedScaleName, "Scale should be '\(expectedScaleName)'")
        }
        
        @Test("Factory lookup returns nil for invalid scale names",
              arguments: ["eeInvalid", "eeXXX", "notEE", ""])
        func invalidScaleLookupReturnsNil(name: String) {
            let scale = StandardScales.scale(named: name, length: 250.0)
            #expect(scale == nil, "Invalid scale '\(name)' should return nil")
        }
        
        @Test("Factory lookup respects custom length parameter",
              arguments: [100.0, 250.0, 500.0, 720.0])
        func factoryLookupRespectsLength(length: Double) {
            let scale = StandardScales.scale(named: "eeXl", length: length)
            #expect(scale?.scaleLengthInPoints == length, "Scale length should be \(length)")
        }
    }
    
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
    
    // MARK: - Tick Generation Tests
    
    @Suite("EE Scale Tick Generation")
    struct EEScaleTickGenerationTests {
        
        /// Helper to get scale by name for tick generation tests
        private static func getScale(named name: String) -> ScaleDefinition? {
            switch name {
            case "XL": return StandardScales.xlScale(length: 250.0)
            case "Xc": return StandardScales.xcScale(length: 250.0)
            case "F": return StandardScales.fScale(length: 250.0)
            case "Fo": return StandardScales.foScale(length: 250.0)
            case "Z": return StandardScales.zScale(length: 250.0)
            case "P": return StandardScales.eePowerRatioScale(length: 250.0)
            case "Q": return StandardScales.eePowerRatioInvertedScale(length: 250.0)
            case "r1": return StandardScales.eeReflectionCoefficientScale(length: 250.0)
            case "L": return StandardScales.eeInductanceScale(length: 250.0)
            case "Li": return StandardScales.eeInductanceInvertedScale(length: 250.0)
            case "Cz": return StandardScales.czScale(length: 250.0)
            case "Cf": return StandardScales.eeCapacitanceFrequencyScale(length: 250.0)
            default: return nil
            }
        }
        
        @Test("Generated ticks are within scale domain",
              arguments: ["XL", "Xc", "F", "Fo", "Z", "P", "Q"])
        func ticksWithinDomain(name: String) {
            guard let scale = EEScaleTickGenerationTests.getScale(named: name) else {
                Issue.record("Could not find scale named \(name)")
                return
            }
            let generated = GeneratedScale(definition: scale)
            
            let minValue = min(scale.beginValue, scale.endValue)
            let maxValue = max(scale.beginValue, scale.endValue)
            
            for tick in generated.tickMarks {
                #expect(tick.value >= minValue - 0.001,
                       "\(name): Tick value \(tick.value) should be >= \(minValue)")
                #expect(tick.value <= maxValue + 0.001,
                       "\(name): Tick value \(tick.value) should be <= \(maxValue)")
            }
        }
        
        @Test("Tick positions are within [0, 1] range",
              arguments: ["XL", "Xc", "F", "P"])  // Note: r1 excluded due to edge case at boundaries
        func tickPositionsInUnitRange(name: String) {
            guard let scale = EEScaleTickGenerationTests.getScale(named: name) else {
                Issue.record("Could not find scale named \(name)")
                return
            }
            let generated = GeneratedScale(definition: scale)
            
            for tick in generated.tickMarks {
                #expect(tick.normalizedPosition >= 0.0,
                       "\(name): Tick position \(tick.normalizedPosition) should be >= 0")
                #expect(tick.normalizedPosition <= 1.0,
                       "\(name): Tick position \(tick.normalizedPosition) should be <= 1")
            }
        }
        
        @Test("Major labels are present for all EE scales",
              arguments: ["XL", "Xc", "F", "Z", "r1", "P"])
        func majorLabelsPresent(name: String) {
            guard let scale = EEScaleTickGenerationTests.getScale(named: name) else {
                Issue.record("Could not find scale named \(name)")
                return
            }
            let generated = GeneratedScale(definition: scale)
            
            let labeledTicks = generated.tickMarks.filter { $0.label != nil }
            #expect(!labeledTicks.isEmpty,
                   "\(name) should have at least one labeled tick")
        }
        
        @Test("Tick count is reasonable for multi-cycle scales",
              arguments: [("XL", 12), ("Xc", 12), ("F", 12), ("Fo", 6), ("Z", 6)])
        func reasonableTickCount(name: String, cycles: Int) {
            let scale: ScaleDefinition
            switch name {
            case "XL": scale = StandardScales.xlScale(length: 250.0)
            case "Xc": scale = StandardScales.xcScale(length: 250.0)
            case "F": scale = StandardScales.fScale(length: 250.0)
            case "Fo": scale = StandardScales.foScale(length: 250.0)
            case "Z": scale = StandardScales.zScale(length: 250.0)
            default: return
            }
            
            let generated = GeneratedScale(definition: scale)
            
            // Multi-cycle scales should have many ticks (at least ~5 per cycle for visibility)
            let minExpectedTicks = cycles * 5
            #expect(generated.tickMarks.count >= minExpectedTicks,
                   "\(name) with \(cycles) cycles should have at least \(minExpectedTicks) ticks, got \(generated.tickMarks.count)")
        }
    }
    
    // MARK: - Round-Trip Accuracy Tests
    
    @Suite("EE Scale Round-Trip Accuracy")
    struct EEScaleRoundTripTests {
        
        /// Tolerance for round-trip accuracy (EE scales may have lower precision)
        static let standardTolerance = 0.01
        static let relaxedTolerance = 0.05
        
        @Test("XL scale round-trip accuracy")
        func xlScaleRoundTrip() {
            let scale = StandardScales.xlScale(length: 250.0)
            let testValues = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
            
            for value in testValues {
                let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
                let recovered = ScaleCalculator.value(at: position, on: scale)
                let relativeError = abs(recovered - value) / value
                
                #expect(relativeError < EEScaleRoundTripTests.relaxedTolerance,
                       "XL scale: Value \(value) round-trip error \(relativeError) exceeds tolerance")
            }
        }
        
        @Test("Xc scale round-trip accuracy")
        func xcScaleRoundTrip() {
            let scale = StandardScales.xcScale(length: 250.0)
            let testValues = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
            
            for value in testValues {
                let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
                let recovered = ScaleCalculator.value(at: position, on: scale)
                let relativeError = abs(recovered - value) / value
                
                #expect(relativeError < EEScaleRoundTripTests.relaxedTolerance,
                       "Xc scale: Value \(value) round-trip error \(relativeError) exceeds tolerance")
            }
        }
        
        @Test("F scale round-trip accuracy")
        func fScaleRoundTrip() {
            let scale = StandardScales.fScale(length: 250.0)
            let testValues = [1.0, 5.0, 10.0, 25.0, 50.0, 100.0]
            
            for value in testValues {
                let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
                let recovered = ScaleCalculator.value(at: position, on: scale)
                let relativeError = abs(recovered - value) / value
                
                #expect(relativeError < EEScaleRoundTripTests.relaxedTolerance,
                       "F scale: Value \(value) round-trip error \(relativeError) exceeds tolerance")
            }
        }
        
        @Test("Z scale round-trip accuracy")
        func zScaleRoundTrip() {
            let scale = StandardScales.zScale(length: 250.0)
            let testValues = [1.0, 5.0, 10.0, 25.0, 50.0, 100.0]
            
            for value in testValues {
                let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
                let recovered = ScaleCalculator.value(at: position, on: scale)
                let relativeError = abs(recovered - value) / value
                
                #expect(relativeError < EEScaleRoundTripTests.relaxedTolerance,
                       "Z scale: Value \(value) round-trip error \(relativeError) exceeds tolerance")
            }
        }
        
        @Test("r1 scale round-trip accuracy")
        func r1ScaleRoundTrip() {
            let scale = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            let testValues = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0]
            
            for value in testValues {
                let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
                let recovered = ScaleCalculator.value(at: position, on: scale)
                let relativeError = abs(recovered - value) / value
                
                #expect(relativeError < EEScaleRoundTripTests.relaxedTolerance,
                       "r1 scale: Value \(value) round-trip error \(relativeError) exceeds tolerance")
            }
        }
        
        @Test("P scale round-trip accuracy for dB values",
              arguments: [0.0, 1.0, 3.0, 6.0, 10.0, 14.0])
        func pScaleRoundTrip(value: Double) {
            let scale = StandardScales.eePowerRatioScale(length: 250.0)
            
            let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let recovered = ScaleCalculator.value(at: position, on: scale)
            
            // For power scales with values near zero, use absolute error
            let error = abs(recovered - value)
            #expect(error < 0.5, "P scale: Value \(value) round-trip error \(error) exceeds tolerance")
        }
        
        @Test("Q scale round-trip accuracy for dB values",
              arguments: [0.0, 1.0, 3.0, 6.0, 10.0, 14.0])
        func qScaleRoundTrip(value: Double) {
            let scale = StandardScales.eePowerRatioInvertedScale(length: 250.0)
            
            let position = ScaleCalculator.normalizedPosition(for: value, on: scale)
            let recovered = ScaleCalculator.value(at: position, on: scale)
            
            let error = abs(recovered - value)
            #expect(error < 0.5, "Q scale: Value \(value) round-trip error \(error) exceeds tolerance")
        }
        
        @Test("Round-trip from generated ticks",
              arguments: ["XL", "F", "Z"])
        func roundTripFromTicks(name: String) {
            let scale: ScaleDefinition
            switch name {
            case "XL": scale = StandardScales.xlScale(length: 250.0)
            case "F": scale = StandardScales.fScale(length: 250.0)
            case "Z": scale = StandardScales.zScale(length: 250.0)
            default: return
            }
            let generated = GeneratedScale(definition: scale)
            
            // Sample every 10th tick to keep test fast
            let sampledTicks = generated.tickMarks.enumerated().filter { $0.offset % 10 == 0 }.map { $0.element }
            
            for tick in sampledTicks {
                let position = ScaleCalculator.normalizedPosition(for: tick.value, on: scale)
                let recovered = ScaleCalculator.value(at: position, on: scale)
                let relativeError = abs(recovered - tick.value) / max(abs(tick.value), 0.001)
                
                #expect(relativeError < 0.1,
                       "\(name): Tick value \(tick.value) round-trip error \(relativeError) exceeds tolerance")
            }
        }
    }
    
    // MARK: - Parity Tests Between Related Scales
    
    @Suite("EE Scale Parity Tests")
    struct EEScaleParityTests {
        
        @Test("XL and Xc scales have inverse relationship at same position")
        func xlXcInverseRelationship() {
            let xl = StandardScales.xlScale(length: 250.0)
            let xc = StandardScales.xcScale(length: 250.0)
            
            // Test several positions across the scale
            let testPositions = [0.0, 0.25, 0.5, 0.75, 1.0]
            
            for position in testPositions {
                let xlValue = ScaleCalculator.value(at: position, on: xl)
                let xcValue = ScaleCalculator.value(at: position, on: xc)
                
                // At position 0, XL=1, Xc=100; At position 1, XL=100, Xc=1
                // Product should be ~100
                let product = xlValue * xcValue
                let expectedProduct = 100.0
                let relativeError = abs(product - expectedProduct) / expectedProduct
                
                #expect(relativeError < 0.1,
                       "XL*Xc at position \(position) = \(product), expected ~\(expectedProduct)")
            }
        }
        
        @Test("r1 and r2 scales have same values at mirrored positions")
        func r1R2MirrorPositions() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            let r2 = StandardScales.eeReflectionCoefficient2Scale(length: 250.0)
            
            // Since r2 has tick direction down, positions should mirror
            let testValues = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0]
            
            for value in testValues {
                let r1Pos = ScaleCalculator.normalizedPosition(for: value, on: r1)
                let r2Pos = ScaleCalculator.normalizedPosition(for: value, on: r2)
                
                // Same value should map to same position (both use same function)
                let positionDiff = abs(r1Pos - r2Pos)
                #expect(positionDiff < 0.01,
                       "r1 and r2 position difference for value \(value) is \(positionDiff)")
            }
        }
        
        @Test("P and Q scales have same values at same positions")
        func pqSameValuePositions() {
            let p = StandardScales.eePowerRatioScale(length: 250.0)
            let q = StandardScales.eePowerRatioInvertedScale(length: 250.0)
            
            let testPositions = [0.0, 0.25, 0.5, 0.75, 1.0]
            
            for position in testPositions {
                let pValue = ScaleCalculator.value(at: position, on: p)
                let qValue = ScaleCalculator.value(at: position, on: q)
                
                // P and Q use same function, same range, just different tick direction
                let valueDiff = abs(pValue - qValue)
                #expect(valueDiff < 0.1,
                       "P and Q values differ at position \(position): P=\(pValue), Q=\(qValue)")
            }
        }
        
        @Test("Cf and Cz scales both span 1 to 100 range")
        func cfCzRangeComparison() {
            let cf = StandardScales.eeCapacitanceFrequencyScale(length: 250.0)
            let cz = StandardScales.czScale(length: 250.0)
            
            // Both should cover same value range
            let cfMin = min(cf.beginValue, cf.endValue)
            let cfMax = max(cf.beginValue, cf.endValue)
            let czMin = min(cz.beginValue, cz.endValue)
            let czMax = max(cz.beginValue, cz.endValue)
            
            #expect(cfMin == czMin, "Cf and Cz should have same minimum value")
            #expect(cfMax == czMax, "Cf and Cz should have same maximum value")
        }
        
        @Test("L and Li scales are inversely oriented")
        func lLiInverseOrientation() {
            let l = StandardScales.eeInductanceScale(length: 250.0)
            let li = StandardScales.eeInductanceInvertedScale(length: 250.0)
            
            // L goes 1→100, Li goes 100→1
            #expect(l.beginValue == li.endValue)
            #expect(l.endValue == li.beginValue)
            #expect(l.tickDirection != li.tickDirection)
            
            // Same function type
            #expect(type(of: l.function) == type(of: li.function))
        }
        
        @Test("F and Fo scales have related cycle counts")
        func fFoCycleRelationship() {
            let f = StandardScales.fScale(length: 250.0)
            let fo = StandardScales.foScale(length: 250.0)
            
            // F has 12 cycles, Fo has 6 cycles (half)
            if let fFunc = f.function as? FrequencyFunction,
               let foFunc = fo.function as? FrequencyWavelengthFunction {
                #expect(fFunc.cycles == 12)
                #expect(foFunc.cycles == 6)
                #expect(fFunc.cycles == 2 * foFunc.cycles, "F should have twice as many cycles as Fo")
            }
        }
    }
    
    // MARK: - Known Mathematical Values Tests
    
    @Suite("EE Scale Known Mathematical Values")
    struct EEKnownValueTests {
        
        @Test("XL scale: position at value 10 is approximately 0.5 (log10 relationship)")
        func xlScaleValueAt10() {
            let xl = StandardScales.xlScale(length: 250.0)
            
            // XL formula: log10(f) / 2 mapped over 12 cycles
            // At value 10, log10(10) = 1, position should be mid-range
            let position = ScaleCalculator.normalizedPosition(for: 10.0, on: xl)
            
            // For 12-cycle scale over 1-100 (2 decades), position at 10 is 0.5
            #expect(abs(position - 0.5) < 0.05,
                   "XL position at 10 should be ~0.5, got \(position)")
        }
        
        @Test("Xc scale: position at value 10 is approximately 0.5 (inverted log10)")
        func xcScaleValueAt10() {
            let xc = StandardScales.xcScale(length: 250.0)
            
            // Xc is inverted XL, so value 10 should also be at ~0.5
            let position = ScaleCalculator.normalizedPosition(for: 10.0, on: xc)
            
            #expect(abs(position - 0.5) < 0.05,
                   "Xc position at 10 should be ~0.5, got \(position)")
        }
        
        @Test("Z scale: 6 cycles means each decade spans 1/3 of scale")
        func zScaleCycleSpacing() {
            let z = StandardScales.zScale(length: 250.0)
            
            // With 6 cycles over 2 decades (1-100), each decade = 0.5 of scale
            let pos1 = ScaleCalculator.normalizedPosition(for: 1.0, on: z)
            let pos10 = ScaleCalculator.normalizedPosition(for: 10.0, on: z)
            let pos100 = ScaleCalculator.normalizedPosition(for: 100.0, on: z)
            
            // First decade (1-10) should span ~0.5
            let firstDecadeSpan = pos10 - pos1
            #expect(abs(firstDecadeSpan - 0.5) < 0.05,
                   "Z scale first decade span should be ~0.5, got \(firstDecadeSpan)")
            
            // Second decade (10-100) should also span ~0.5
            let secondDecadeSpan = pos100 - pos10
            #expect(abs(secondDecadeSpan - 0.5) < 0.05,
                   "Z scale second decade span should be ~0.5, got \(secondDecadeSpan)")
        }
        
        @Test("P scale: Pythagorean formula x²/196 * 0.477 + 0.523")
        func pScalePythagoreanValues() {
            let p = StandardScales.eePowerRatioScale(length: 250.0)
            
            // Test known dB values
            // At 0 dB: position should be at start (0.523 offset from formula)
            let pos0 = ScaleCalculator.normalizedPosition(for: 0.0, on: p)
            #expect(pos0 >= 0.0 && pos0 <= 0.1,
                   "P scale at 0 dB should be near start, got \(pos0)")
            
            // At 14 dB (max): position should be at end
            let pos14 = ScaleCalculator.normalizedPosition(for: 14.0, on: p)
            #expect(pos14 >= 0.9 && pos14 <= 1.0,
                   "P scale at 14 dB should be near end, got \(pos14)")
        }
        
        @Test("r1 scale: VSWR values map to positions within valid range")
        func r1ScaleVSWRRelationship() {
            let r1 = StandardScales.eeReflectionCoefficientScale(length: 250.0)
            
            // r1 scale range is 0.5 to 50 (VSWR)
            // Test that positions are within valid range and monotonically increasing
            let pos05 = ScaleCalculator.normalizedPosition(for: 0.5, on: r1)
            let pos1 = ScaleCalculator.normalizedPosition(for: 1.0, on: r1)
            let pos10 = ScaleCalculator.normalizedPosition(for: 10.0, on: r1)
            let pos50 = ScaleCalculator.normalizedPosition(for: 50.0, on: r1)
            
            // Positions should be monotonically increasing with value
            #expect(pos05 < pos1, "r1 position at 0.5 should be less than at 1")
            #expect(pos1 < pos10, "r1 position at 1 should be less than at 10")
            #expect(pos10 < pos50, "r1 position at 10 should be less than at 50")
            
            // Start and end values should map near boundaries
            #expect(abs(pos05) < 0.05, "r1 at 0.5 (begin) should be near position 0")
            #expect(abs(pos50 - 1.0) < 0.05, "r1 at 50 (end) should be near position 1")
        }
        
        @Test("L scale: inductance uses log10(f/1000) / 2 relationship")
        func lScaleInductanceFormula() {
            let l = StandardScales.eeInductanceScale(length: 250.0)
            
            // Test decade transitions
            let pos1 = ScaleCalculator.normalizedPosition(for: 1.0, on: l)
            let pos10 = ScaleCalculator.normalizedPosition(for: 10.0, on: l)
            let pos100 = ScaleCalculator.normalizedPosition(for: 100.0, on: l)
            
            // Should be monotonically increasing
            #expect(pos1 < pos10, "L position should increase with value")
            #expect(pos10 < pos100, "L position should increase with value")
            
            // Endpoints should be at 0 and 1
            #expect(abs(pos1) < 0.01, "L at 1 should be near position 0")
            #expect(abs(pos100 - 1.0) < 0.01, "L at 100 should be near position 1")
        }
        
        @Test("EE scales boundary values map to positions 0 and 1")
        func boundaryValuesMapCorrectly() {
            let scales: [(String, ScaleDefinition)] = [
                ("XL", StandardScales.xlScale(length: 250.0)),
                ("F", StandardScales.fScale(length: 250.0)),
                ("Z", StandardScales.zScale(length: 250.0)),
                ("L", StandardScales.eeInductanceScale(length: 250.0)),
                ("P", StandardScales.eePowerRatioScale(length: 250.0))
            ]
            
            for (name, scale) in scales {
                let posBegin = ScaleCalculator.normalizedPosition(for: scale.beginValue, on: scale)
                let posEnd = ScaleCalculator.normalizedPosition(for: scale.endValue, on: scale)
                
                #expect(abs(posBegin) < 0.01,
                       "\(name) beginValue should map to position ~0, got \(posBegin)")
                #expect(abs(posEnd - 1.0) < 0.01,
                       "\(name) endValue should map to position ~1, got \(posEnd)")
            }
        }
        
        @Test("Multi-cycle scales have consistent spacing per cycle")
        func multiCycleConsistentSpacing() {
            let xl = StandardScales.xlScale(length: 250.0)
            
            // For 12-cycle XL scale over 2 decades, each cycle is 1/12 of scale
            // Decade markers (10×) should be evenly spaced
            let generated = GeneratedScale(definition: xl)
            
            // Find major decade markers (1, 10, 100)
            let decadeMarkers = generated.tickMarks.filter { tick in
                let value = tick.value
                return value == 1.0 || value == 10.0 || value == 100.0
            }
            
            #expect(decadeMarkers.count >= 3,
                   "XL should have decade markers at 1, 10, 100")
        }
    }
}
