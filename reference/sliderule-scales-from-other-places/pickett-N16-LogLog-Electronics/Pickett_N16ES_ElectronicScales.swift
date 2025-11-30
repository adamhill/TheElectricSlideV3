import Foundation

// MARK: - Complete Electrical Engineering Scale Collection
// Unified extension combining Hemmi 266, Pickett N-16 ES, and universal EE scales
// This extension integrates all specialized electronics slide rule scales

extension ElectricalEngineeringScales {
    
    // MARK: - Pickett N-16 ES Specialized Scales
    
    /// Complete set of N-16 ES scales organized by function
    public enum PickettN16ES {
        
        // MARK: Component Value Scales (Four-Decade Span)
        
        /// Lr - Inductance with reciprocal function for resonance calculations
        /// Historical: Revolutionary four-decade span (0.001µH to 100H)
        /// Used with Cr scale for direct f = 1/(2π√LC) reading
        public static func inductanceReciprocal(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            N16ESScaleBuilder.createLrScale(
                scaleLengthInPoints: scaleLengthInPoints,
                layout: layout,
                tickDirection: tickDirection
            )
        }
        
        /// Cr - Capacitance with reciprocal function for resonance calculations
        /// Historical: Four-decade span (1pF to 1000µF)
        /// Decimal keeper prevents magnitude errors across femtofarads to farads
        public static func capacitanceReciprocal(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .down
        ) -> ScaleDefinition {
            N16ESScaleBuilder.createCrScale(
                scaleLengthInPoints: scaleLengthInPoints,
                layout: layout,
                tickDirection: tickDirection
            )
        }
        
        /// C/L - Combined capacitance/inductance scale (four-decade)
        /// Dual purpose: Component values or time constant calculations
        public static func capacitanceInductanceCombined(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            let function = CapacitanceInductanceFunction(cycles: 12)
            
            return ScaleBuilder()
                .withName("C/L")
                .withFunction(function)
                .withRange(begin: 1e-12, end: 1e-3)
                .withLength(scaleLengthInPoints)
                .withTickDirection(tickDirection)
                .withSubsections([
                    ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                    ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.2], labelLevels: [0]),
                    ScaleSubsection(startValue: 5.0, tickIntervals: [1, 0.5], labelLevels: [0]),
                    ScaleSubsection(startValue: 10.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0])
                ])
                .build()
        }
        
        // MARK: Frequency and Wavelength Scales
        
        /// Fo - Frequency/Wavelength scale (six-decade inverted)
        /// Dual labeling: Frequency (Hz/MHz/GHz) and wavelength (m/cm/mm)
        /// Critical for: Antenna design, transmission lines, RF work
        public static func frequencyWavelength(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            N16ESScaleBuilder.createFoScale(
                scaleLengthInPoints: scaleLengthInPoints,
                layout: layout,
                tickDirection: tickDirection
            )
        }
        
        /// λ - Wavelength scale (c/f relationship)
        /// Shows wavelength corresponding to frequency (c = fλ)
        public static func wavelength(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            let function = WavelengthFunction(cycles: 6)
            
            return ScaleBuilder()
                .withName("λ")
                .withFunction(function)
                .withRange(begin: 1e5, end: 1e11)
                .withLength(scaleLengthInPoints)
                .withTickDirection(tickDirection)
                .withLabelFormatter(N16ESLabelFormatters.wavelengthFormatter)
                .withLabelColor(red: 1.0, green: 0.0, blue: 0.0)
                .build()
        }
        
        /// ω - Angular frequency scale (ω = 2πf)
        /// Used for: Complex impedance, AC analysis in radian notation
        public static func angularFrequency(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            let function = AngularFrequencyFunction(cycles: 12)
            
            return ScaleBuilder()
                .withName("ω")
                .withFunction(function)
                .withRange(begin: 0.001, end: 1e9)
                .withLength(scaleLengthInPoints)
                .withTickDirection(tickDirection)
                .withSubsections([
                    ScaleSubsection(startValue: 1.0, tickIntervals: [1, 0.5, 0.1], labelLevels: [0]),
                    ScaleSubsection(startValue: 2.0, tickIntervals: [1, 0.2], labelLevels: [0]),
                    ScaleSubsection(startValue: 5.0, tickIntervals: [1, 0.5], labelLevels: [0])
                ])
                .build()
        }
        
        // MARK: Filter Response Scales (Coordinated Triple Reading)
        
        /// Θ - Phase angle scale for RC/RL circuits (0° to 90°)
        /// Used with: cos(Θ) and dB scales for simultaneous filter analysis
        /// Applications: Audio equalizers, communications filters
        public static func phaseAngle(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            N16ESScaleBuilder.createPhaseAngleScale(
                scaleLengthInPoints: scaleLengthInPoints,
                layout: layout,
                tickDirection: tickDirection
            )
        }
        
        /// cos(Θ) - Relative gain and power factor (0 to 1)
        /// Formula: cos(θ) = 1/√(1 + (1/(2πfRC))²) for filters
        /// Special marker: -3dB point at 0.707
        public static func cosinePhase(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .down
        ) -> ScaleDefinition {
            N16ESScaleBuilder.createCosinePhaseScale(
                scaleLengthInPoints: scaleLengthInPoints,
                layout: layout,
                tickDirection: tickDirection
            )
        }
        
        /// dB - Decibel scale (power ratios)
        /// Formula: 10 log₁₀(P₂/P₁)
        /// Coordinated with Θ and cos(Θ) for complete filter characterization
        public static func decibelPower(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            N16ESScaleBuilder.createDecibelScale(
                isVoltageRatio: false,
                scaleLengthInPoints: scaleLengthInPoints,
                layout: layout,
                tickDirection: tickDirection
            )
        }
        
        /// dB - Decibel scale (voltage/current ratios)
        /// Formula: 20 log₁₀(V₂/V₁)
        /// Lower scale on N-16 ES back face
        public static func decibelVoltage(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .down
        ) -> ScaleDefinition {
            N16ESScaleBuilder.createDecibelScale(
                isVoltageRatio: true,
                scaleLengthInPoints: scaleLengthInPoints,
                layout: layout,
                tickDirection: tickDirection
            )
        }
        
        // MARK: Time Constant Scales
        
        /// τ - Time constant scale (τ = RC or L/R)
        /// Dual function: Capacitive (RC) or inductive (L/R) circuits
        /// Applications: Charging rates, transient response, settling time
        public static func timeConstant(
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            let function = TimeConstantFunction(cycles: 12)
            
            return ScaleBuilder()
                .withName("τ")
                .withFunction(function)
                .withRange(begin: 1e-9, end: 1e3)
                .withLength(scaleLengthInPoints)
                .withTickDirection(tickDirection)
                .withLabelFormatter(N16ESLabelFormatters.timeConstantFormatter)
                .build()
        }
        
        // MARK: Utility Scales
        
        /// D/Q - Decimal keeper and Q-factor scale
        /// Dual mode: Decade tracking or quality factor
        /// Essential: Prevents magnitude errors in four-decade calculations
        public static func decimalKeeperQ(
            isQMode: Bool = false,
            scaleLengthInPoints: Distance = 250.0,
            layout: ScaleLayout = .linear,
            tickDirection: TickDirection = .up
        ) -> ScaleDefinition {
            let function = DecimalKeeperQFunction(isQMode: isQMode)
            
            return ScaleBuilder()
                .withName(isQMode ? "Q" : "D")
                .withFunction(function)
                .withRange(begin: 1.0, end: 10.0)
                .withLength(scaleLengthInPoints)
                .withTickDirection(tickDirection)
                .withLabelFormatter(isQMode ? N16ESLabelFormatters.qFactorFormatter : StandardLabelFormatter.oneDecimal)
                .build()
        }
    }
    
    // MARK: - Complete N-16 ES Rule Assembly
    
    /// Generate a complete Pickett N-16 ES slide rule with all 32 scales
    /// Front face: Mathematical scales with hyperbolic functions
    /// Back face: Complete electronics calculation system
    public static func completePickettN16ES(
        scaleLength: Distance = 250.0,
        layout: ScaleLayout = .linear
    ) -> SlideRule {
        // Front face: Mathematical capabilities
        let frontTopStator = RuleComponent(scales: [
            // Hyperbolic scales (rare in slide rules)
            hyperbolicSine(scaleLengthInPoints: scaleLength, part: 1),
            hyperbolicSine(scaleLengthInPoints: scaleLength, part: 2),
            hyperbolicTangent(scaleLengthInPoints: scaleLength),
            // Folded D scale at π
            StandardScales.dFolded(scaleLengthInPoints: scaleLength)
        ])
        
        let frontSlide = RuleComponent(scales: [
            // Folded C scale at π
            StandardScales.cFolded(scaleLengthInPoints: scaleLength),
            // Common logarithm
            StandardScales.commonLogarithm(scaleLengthInPoints: scaleLength),
            // Trigonometric trio
            StandardScales.sine(scaleLengthInPoints: scaleLength),
            StandardScales.sineSmallAngles(scaleLengthInPoints: scaleLength),
            StandardScales.tangent(scaleLengthInPoints: scaleLength),
            // Standard C and CI
            StandardScales.cInverted(scaleLengthInPoints: scaleLength),
            StandardScales.c(scaleLengthInPoints: scaleLength)
        ])
        
        let frontBottomStator = RuleComponent(scales: [
            StandardScales.d(scaleLengthInPoints: scaleLength),
            // Log-log system (LL3, LL2, LL1)
            logLogFunction(range: .ll3, scaleLengthInPoints: scaleLength),
            logLogFunction(range: .ll2, scaleLengthInPoints: scaleLength),
            logLogFunction(range: .ll1, scaleLengthInPoints: scaleLength),
            // Natural logarithm
            StandardScales.naturalLogarithm(scaleLengthInPoints: scaleLength)
        ])
        
        // Back face: Electronics calculation system
        let backTopStator = RuleComponent(scales: [
            PickettN16ES.phaseAngle(scaleLengthInPoints: scaleLength, tickDirection: .up),
            PickettN16ES.decibelPower(scaleLengthInPoints: scaleLength, tickDirection: .up),
            PickettN16ES.decimalKeeperQ(scaleLengthInPoints: scaleLength, tickDirection: .up),
            inductiveReactance(scaleLengthInPoints: scaleLength, tickDirection: .up),
            capacitiveReactance(scaleLengthInPoints: scaleLength, tickDirection: .up)
        ])
        
        let backSlide = RuleComponent(scales: [
            PickettN16ES.capacitanceInductanceCombined(scaleLengthInPoints: scaleLength),
            frequency(scaleLengthInPoints: scaleLength),
            PickettN16ES.wavelength(scaleLengthInPoints: scaleLength),
            PickettN16ES.angularFrequency(scaleLengthInPoints: scaleLength),
            PickettN16ES.timeConstant(scaleLengthInPoints: scaleLength),
            PickettN16ES.capacitanceReciprocal(scaleLengthInPoints: scaleLength)
        ])
        
        let backBottomStator = RuleComponent(scales: [
            PickettN16ES.inductanceReciprocal(scaleLengthInPoints: scaleLength, tickDirection: .down),
            PickettN16ES.decibelVoltage(scaleLengthInPoints: scaleLength, tickDirection: .down),
            PickettN16ES.cosinePhase(scaleLengthInPoints: scaleLength, tickDirection: .down),
            impedance(scaleLengthInPoints: scaleLength, tickDirection: .down)
        ])
        
        return SlideRule(
            frontTopStator: frontTopStator,
            frontSlide: frontSlide,
            frontBottomStator: frontBottomStator,
            backTopStator: backTopStator,
            backSlide: backSlide,
            backBottomStator: backBottomStator
        )
    }
    
    // MARK: - Hemmi 266 Electronics Scales
    
    /// Complete Hemmi 266 electronics slide rule configuration
    /// Similar to N-16 ES but with Hemmi's specific scale arrangements
    public static func completeHemmi266(
        scaleLength: Distance = 250.0,
        layout: ScaleLayout = .linear
    ) -> SlideRule {
        // Front face: Standard mathematical scales
        let frontTopStator = RuleComponent(scales: [
            logLogFunction(range: .ll3, scaleLengthInPoints: scaleLength),
            logLogFunction(range: .ll1, scaleLengthInPoints: scaleLength),
            logLogFunction(range: .ll02, scaleLengthInPoints: scaleLength),
            logLogFunction(range: .ll2, scaleLengthInPoints: scaleLength, tickDirection: .down),
            StandardScales.a(scaleLengthInPoints: scaleLength)
        ])
        
        let frontSlide = RuleComponent(scales: [
            StandardScales.b(scaleLengthInPoints: scaleLength),
            StandardScales.bInverted(scaleLengthInPoints: scaleLength),
            StandardScales.cInverted(scaleLengthInPoints: scaleLength),
            StandardScales.c(scaleLengthInPoints: scaleLength)
        ])
        
        let frontBottomStator = RuleComponent(scales: [
            StandardScales.d(scaleLengthInPoints: scaleLength),
            StandardScales.commonLogarithm(scaleLengthInPoints: scaleLength, tickDirection: .down),
            StandardScales.sine(scaleLengthInPoints: scaleLength),
            StandardScales.tangent(scaleLengthInPoints: scaleLength, tickDirection: .down)
        ])
        
        // Back face: Electronics scales
        let backTopStator = RuleComponent(scales: [
            inductiveReactance(scaleLengthInPoints: scaleLength),
            capacitiveReactance(scaleLengthInPoints: scaleLength),
            frequency(scaleLengthInPoints: scaleLength),
            reflectionCoefficient(part: 1, scaleLengthInPoints: scaleLength),
            powerRatio(scaleLengthInPoints: scaleLength)
        ])
        
        let backSlide = RuleComponent(scales: [
            reflectionCoefficient(part: 2, scaleLengthInPoints: scaleLength),
            PickettN16ES.decimalKeeperQ(isQMode: true, scaleLengthInPoints: scaleLength),
            inductance(scaleLengthInPoints: scaleLength),
            capacitanceFrequency(scaleLengthInPoints: scaleLength),
            capacitanceImpedance(scaleLengthInPoints: scaleLength)
        ])
        
        let backBottomStator = RuleComponent(scales: [
            inductance(scaleLengthInPoints: scaleLength),
            impedance(scaleLengthInPoints: scaleLength),
            PickettN16ES.frequencyWavelength(scaleLengthInPoints: scaleLength)
        ])
        
        return SlideRule(
            frontTopStator: frontTopStator,
            frontSlide: frontSlide,
            frontBottomStator: frontBottomStator,
            backTopStator: backTopStator,
            backSlide: backSlide,
            backBottomStator: backBottomStator
        )
    }
    
    // MARK: - Utility Functions
    
    /// Helper function for hyperbolic sine scales (two-part for extended range)
    private static func hyperbolicSine(
        scaleLengthInPoints: Distance,
        part: Int,
        tickDirection: TickDirection = .up
    ) -> ScaleDefinition {
        let function = CustomFunction(
            name: "sh\(part)",
            transform: { value in
                log10(sinh(value * .pi / 180.0) * (part == 1 ? 10.0 : 1.0))
            },
            inverseTransform: { transformed in
                asinh(pow(10, transformed) / (part == 1 ? 10.0 : 1.0)) * 180.0 / .pi
            }
        )
        
        let range = part == 1 ? (begin: 0.5, end: 3.0) : (begin: 2.5, end: 10.0)
        
        return ScaleBuilder()
            .withName("SH\(part)")
            .withFunction(function)
            .withRange(begin: range.begin, end: range.end)
            .withLength(scaleLengthInPoints)
            .withTickDirection(tickDirection)
            .build()
    }
    
    /// Hyperbolic tangent scale
    private static func hyperbolicTangent(
        scaleLengthInPoints: Distance,
        tickDirection: TickDirection = .up
    ) -> ScaleDefinition {
        let function = CustomFunction(
            name: "th",
            transform: { value in
                log10(tanh(value * .pi / 180.0) * 10.0)
            },
            inverseTransform: { transformed in
                atanh(pow(10, transformed) / 10.0) * 180.0 / .pi
            }
        )
        
        return ScaleBuilder()
            .withName("TH")
            .withFunction(function)
            .withRange(begin: 0.5, end: 10.0)
            .withLength(scaleLengthInPoints)
            .withTickDirection(tickDirection)
            .build()
    }
}

// MARK: - Calculation Workflows

/// Complete calculation workflows demonstrating N-16 ES capabilities
public enum N16ESWorkflows {
    
    /// Complete resonant frequency workflow with decimal keeper
    /// Demonstrates: Four-decade scales, reciprocal functions, magnitude tracking
    public static func resonantFrequencyWorkflow(
        inductance: Double,
        capacitance: Double
    ) -> (frequency: Double, magnitude: Int, decades: String) {
        // Calculate frequency
        let f = N16ESExamples.resonantFrequency(
            inductance: inductance,
            capacitance: capacitance
        )
        
        // Determine decade/magnitude
        let logF = log10(f)
        let magnitude = Int(floor(logF))
        
        // Decimal keeper guidance
        let decades = magnitude >= 0 ? "\(magnitude) decades above 1 Hz" : "\(abs(magnitude)) decades below 1 Hz"
        
        return (f, magnitude, decades)
    }
    
    /// Complete filter design workflow
    /// Demonstrates: Simultaneous triple reading (phase, gain, dB)
    public static func filterDesignWorkflow(
        resistance: Double,
        capacitance: Double,
        frequency: Double
    ) -> (
        timeConstant: Double,
        cutoffFrequency: Double,
        responseAtFreq: (gain: Double, phase: Double, dB: Double),
        responseAtCutoff: (gain: Double, phase: Double, dB: Double)
    ) {
        // Time constant
        let tau = N16ESExamples.timeConstantRC(
            resistance: resistance,
            capacitance: capacitance
        )
        
        // Cutoff frequency
        let fc = 1.0 / (2.0 * .pi * tau)
        
        // Response at specified frequency
        let respFreq = N16ESExamples.rcFilterResponse(
            resistance: resistance,
            capacitance: capacitance,
            frequency: frequency
        )
        
        // Response at cutoff (-3dB point)
        let respCutoff = N16ESExamples.rcFilterResponse(
            resistance: resistance,
            capacitance: capacitance,
            frequency: fc
        )
        
        return (
            tau,
            fc,
            (respFreq.relativeGain, respFreq.phaseShift, respFreq.gainDB),
            (respCutoff.relativeGain, respCutoff.phaseShift, respCutoff.gainDB)
        )
    }
    
    /// Antenna design workflow
    /// Demonstrates: Wavelength calculations, dimensional conversions
    public static func antennaDesignWorkflow(
        frequency: Double,
        antennaType: AntennaType
    ) -> (
        wavelength: Double,
        physicalLength: Double,
        velocityFactor: Double,
        practicalLength: Double
    ) {
        let wavelength = N16ESExamples.wavelength(frequency: frequency)
        
        let (lengthMultiplier, vf) = antennaType.parameters
        let physicalLength = wavelength * lengthMultiplier
        let practicalLength = physicalLength * vf
        
        return (wavelength, physicalLength, vf, practicalLength)
    }
    
    public enum AntennaType {
        case halfWaveDipole
        case quarterWaveMonopole
        case fullWave
        case fiveEighthsWave
        
        var parameters: (lengthMultiplier: Double, velocityFactor: Double) {
            switch self {
            case .halfWaveDipole: return (0.5, 0.95)
            case .quarterWaveMonopole: return (0.25, 0.95)
            case .fullWave: return (1.0, 0.95)
            case .fiveEighthsWave: return (0.625, 0.95)
            }
        }
    }
    
    /// Transmission line impedance matching workflow
    /// Demonstrates: Complex impedance, VSWR, reflection coefficient
    public static func impedanceMatchingWorkflow(
        sourceImpedance: Double,
        loadImpedance: Double,
        frequency: Double
    ) -> (
        reflectionCoefficient: Double,
        vswr: Double,
        returnLossDB: Double,
        matchingRequired: Bool
    ) {
        // Reflection coefficient: Γ = (ZL - Z0) / (ZL + Z0)
        let gamma = abs((loadImpedance - sourceImpedance) / (loadImpedance + sourceImpedance))
        
        // VSWR: (1 + |Γ|) / (1 - |Γ|)
        let vswr = (1.0 + gamma) / (1.0 - gamma)
        
        // Return loss in dB: -20 log₁₀(|Γ|)
        let returnLoss = -20.0 * log10(gamma)
        
        // Good match: VSWR < 2:1 (return loss > 9.5 dB)
        let matching = vswr > 2.0
        
        return (gamma, vswr, returnLoss, matching)
    }
}
