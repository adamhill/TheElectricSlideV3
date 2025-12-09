# Pickett N-16 ES Electronic Slide Rule: Complete Technical Reference

The Pickett N-16 ES represents the pinnacle of analog electronic computation, combining **32 scales** specifically designed for RF engineering, filter analysis, and resonance calculations. Designed by **Chan Street** of Street Laboratory and Industries (El Segundo, California) and manufactured by Pickett circa 1959-1960, this "Electronic Log Log Dual Base Speed Rule" remains the most sophisticated electronics slide rule ever mass-produced.

## Back face scale layout reveals a three-zone architecture

The N-16 ES back face organizes its specialized electronics scales into distinct zones—upper stator, slide, and lower stator—each serving specific computational functions. This arrangement enables simultaneous reading of related quantities (phase angle, decibels, and relative gain) from a single cursor position.

**Upper Stator (fixed top, 5 scales):**
| Position | Scale | Function |
|----------|-------|----------|
| 1 | **θ (Theta/α)** | Phase angle in degrees |
| 2 | **db** | Decibels (power/voltage ratio) |
| 3 | **D or Q** | Dissipation factor / Quality factor |
| 4 | **XL** | Inductive reactance |
| 5 | **Zs or Xc** | Impedance / Capacitive reactance |

**Slide (movable center, 7 scales):**
| Position | Scale | Function |
|----------|-------|----------|
| 6 | **C or L** | Capacitance / Inductance (4 decades) |
| 7 | **F** | Frequency |
| 8 | **λ (Lambda)** | Wavelength |
| 9 | **ω (Omega)** | Angular frequency |
| 10 | **τ (Tau)** | Time constant |
| 11 | **τR' or X'c** | Modified time constant / reactance |
| 12 | **Cr** | Capacitance for resonance (4 decades) |

**Lower Stator (fixed bottom, 4 scales):**
| Position | Scale | Function |
|----------|-------|----------|
| 13 | **Lr** | Inductance for resonance (4 decades) |
| 14 | **db** | Decibels (second instance) |
| 15 | **COS θ** | Cosine theta (relative gain / power factor) |
| 16 | **τ'c or C'** | Time constant variant / capacitance |

The dual db scales on upper and lower stators create a computational "sandwich" allowing frequency response analysis without cursor repositioning.

## Mathematical formulas govern each specialized scale

### Phase Angle Scale (θ/α)
**Formula:** α = cot⁻¹(2πfRC) or θ = arctan(X/R)

The phase angle scale provides direct readout of voltage-current phase shift in AC circuits. For RC filters, phase ranges from **0° to 90°** depending on the 2πfRC product. The scale construction maps the arctangent function onto the logarithmic slide rule framework.

### Decibel Scale (db)
**Formula:** dB = **20 log₁₀(V₂/V₁)** for voltage/current ratios

The N-16 ES uses the **20 log₁₀** convention (voltage ratio), not 10 log₁₀ (power ratio), consistent with electronics engineering practice. The scale spans **0-40 dB** in both directions from center, enabling both gain (+dB) and attenuation (-dB) readings. Construction: since dB = 20 log₁₀(ratio), and the underlying A scale represents x², reading voltage ratio against db scale yields 20 × (½ log x) = 10 log x per half-decade.

### Quality Factor / Dissipation Scale (D or Q)
**Formulas:**
- Q = XL/R = ωL/R = 1/(ωCR) = f₀/Δf (bandwidth)
- D = 1/Q = R/X (dissipation factor)

This dual-purpose scale computes circuit "sharpness"—higher Q indicates narrower bandwidth and greater voltage magnification at resonance (voltage across L or C equals Q × applied voltage).

### Inductive Reactance Scale (XL)
**Formula:** XL = 2πfL = ωL

Scale construction uses logarithmic addition: log(XL) = log(2π) + log(f) + log(L). Setting frequency on F scale and inductance on Lr enables direct XL readout. **Typical range:** µH to H inductance with Hz to MHz frequency, yielding Ω to MΩ reactance.

### Capacitive Reactance Scale (Zs/Xc)
**Formula:** Xc = 1/(2πfC) = 1/(ωC)

The reciprocal relationship causes this scale to run **opposite** to XL due to the inverse frequency dependence: log(Xc) = -log(2π) - log(f) - log(C). **Typical range:** pF to µF capacitance with kHz to MHz frequencies.

### Capacitance/Inductance Scale (C or L)
**Range:** Four orders of magnitude (4 decades)
- Capacitance: pF (10⁻¹²) through µF (10⁻⁶) to F
- Inductance: µH (10⁻⁶) through mH (10⁻³) to H

This multi-decade scale serves as the primary "decimal keeper" for tracking magnitude in calculations spanning many orders of magnitude—essential when electronics values range from picofarads to microfarads.

### Frequency Scale (F)
**Range:** Approximately **1 Hz to 100 MHz** (8 decades)

Divided into labeled sections for Hz, kHz, and MHz. The scale includes gauge marks at frequencies corresponding to standard electronic component value calculations.

### Wavelength Scale (λ)
**Formula:** λ = c/f where c ≈ 3×10⁸ m/s

Since λ = c/f with c constant: log(λ) = log(c) - log(f). The wavelength scale runs **inversely** to frequency, essentially a reciprocal F scale shifted by log(c). **Typical range:** 3000 meters (100 kHz) to 0.3 meters (1 GHz), covering radio wavelengths from longwave through UHF.

### Angular Frequency Scale (ω)
**Formula:** ω = 2πf (rad/s)

Construction shifts the frequency scale by log(2π) ≈ 0.798: log(ω) = log(2π) + log(f). Having ω pre-computed eliminates one multiplication step in reactance formulas (XL = ωL, Xc = 1/ωC).

### Time Constant Scale (τ)
**Formulas:**
- RC circuits: τ = RC (seconds)
- RL circuits: τ = L/R (seconds)

The time constant represents decay/rise to **63.2%** of final value (1 - e⁻¹). After 5τ, response reaches >99% completion. **Typical range:** microseconds to seconds.

### Modified Reactance/Time Constant Scale (τR'/X'c)
These scales represent normalized quantities for frequency response calculations—specifically, τR' products and frequency-dependent capacitive reactance terms used in filter transfer function analysis. They enable direct computation of filter frequency response without intermediate calculations.

### Capacitance Reciprocal Square Root Scale (Cr)
**Formula:** Cr = √(1/C) = 1/√C

Construction: log(Cr) = -½ log(C). **Range:** 4 orders of magnitude. Critical for resonant frequency calculations where f = 1/(2π√LC) can be rewritten as f = (1/2π) × √(1/L) × √(1/C) = (1/2π) × Lr × Cr.

### Inductance Reciprocal Square Root Scale (Lr)
**Formula:** Lr = √(1/L) = 1/√L

Construction: log(Lr) = -½ log(L). **Range:** 4 orders of magnitude. Paired with Cr for resonance calculations through logarithmic addition of reciprocal square roots.

### Power Factor / Relative Gain Scale (COS θ)
**Formulas:**
- Power factor: cos(θ) = R/Z = P/S
- For RC circuits: cos(θ) = **1/√(1 + (1/(2πfRC))²)**

The COS θ scale provides direct readout of power factor (0 to 1) and, when read alongside the db scale, gives relative gain in both decimal and decibel form simultaneously.

## Color coding and tick directions follow Pickett conventions

The N-16 ES uses Pickett's standard "Eye-Saver" yellow aluminum construction with two-color scale markings:

**Black scales** (ticks pointing toward scale label):
- Standard scales increasing **left to right**
- Includes: D/Q, XL, F, Lr, COS θ, and most primary scales

**Red scales** (ticks pointing toward scale label):
- Inverse/reciprocal scales increasing **right to left**
- Includes: CI (front), Cr (runs opposite to Lr for resonance calculations), Xc scales

**Tick direction convention:** On standard Pickett rules, tick marks point toward the scale label/number line. Upper stator scales have ticks pointing **down**, lower stator scales have ticks pointing **up**, and slide scales have ticks on both edges pointing toward the respective adjacent stator.

## Gauge marks encode standard electronic values

The N-16 ES includes specialized gauge marks critical for electronics calculations:

| Gauge Mark | Value | Location | Purpose |
|------------|-------|----------|---------|
| **1/(2π)** | ≈ 0.159 | F scale | Reactance calculations (XL = 2πfL) |
| **2π** | ≈ 6.283 | ω scale | Frequency-to-angular frequency conversion |
| **1/(2π)²** | ≈ 0.0253 | Lr/Cr scales | Resonant frequency calculations |
| **Standard R values** | Various | Xc scale | Common resistor values (1Ω-10MΩ series) |
| **Standard C values** | Various | C/L scale | Common capacitor values in preferred series |
| **fcps/fkC marks** | — | F scale | Frequency in cycles per second / kilocycles |
| **Unit prefixes** | µF, nF, pF, mH, µH | C/L, Cr, Lr | Decimal point tracking |

The formulas **f = 1/(2π√LC)**, **XL = 2πfL**, and **Xc = 1/(2πfC)** are printed directly on the rule body for quick reference.

## Four-decade decimal keeper scales solve magnitude tracking

The C/L, Cr, and Lr scales each span **four orders of magnitude** (10,000:1 ratio)—far exceeding typical slide rule scales. This design addresses electronics' unique challenge: calculations routinely involve values spanning 12+ orders of magnitude (picofarads to farads, microhenries to henries, hertz to megahertz).

**Practical operation:** When values exceed a scale's range, users adjust by factors of 100 (two decades) rather than 10, maintaining alignment with the reciprocal square root relationships central to resonance calculations.

**Resonant frequency calculation example** (L=25mH, C=2µF):
1. Set cursor at 25mH (or 2.5H with ×10 adjustment) on Lr scale
2. Align 2µF on Cr scale under cursor
3. Move cursor to right index
4. Read resonant frequency: **711 Hz**

**RC filter response example** (R=30kΩ, C=1.0µF at 5Hz):
1. Set cursor at 0.03MΩ on Xc scale
2. Align 1.0µF on C/L scale under cursor
3. Move cursor to 5Hz on F scale
4. Read simultaneously: relative gain **0.686** on COS θ, **-3.28 dB** on db scale, phase shift **46.7°** on θ scale

## Historical context anchors the N-16 ES in telecommunications engineering

**Chan Street** (1907-?) owned Street Laboratory and Industries in El Segundo, California, where he developed specialized slide rules for the burgeoning electronics industry. He designed both the N-16 ES and the simpler N535-ES Electronic Technician rule for Pickett, authoring the detailed instruction manuals himself.

The N-16 ES emerged around **1959-1960** during the golden age of analog computation, when radio frequency engineering, filter design, and telecommunications demanded rapid calculation of reactances, resonant frequencies, and frequency response. Its target market included:
- RF engineers designing radio transmitters and receivers
- Filter designers computing frequency response and phase shift
- Telecommunications engineers working with transmission lines
- Electronics technicians troubleshooting resonant circuits

**Comparison with other Pickett electronics rules:**

| Model | Designer | Distinctive Features |
|-------|----------|---------------------|
| N515-T | — | H scale, 2π scale, basic decimal keeper |
| N531-ES | — | 2π scale, Log-Log scales |
| N535-ES | Chan Street | AI scale, decimal keeper, F gauge mark |
| N1020-ES | — | 2π scale, NRI curriculum-aligned |
| **N16-ES** | **Chan Street** | **Most sophisticated: hyperbolic scales, complete decimal keepers, filter response scales, 4-decade coverage** |

Brian Borchers of the Oughtred Society described the N-16 ES as "**by far the most sophisticated**" of Pickett's five electronics slide rules.

## Documentation preserves operational knowledge

Primary sources for the N-16 ES include:
- **M379**: Chan Street's original 16-page instruction manual (ISRM archive)
- **M114**: "How To Use Model N-16-ES Electronic Slide Rule" - Pickett Form M-23 (60 pages)
- **Brian Borchers**: "Five Pickett Electronics Slide Rules," *Journal of the Oughtred Society* Vol. 11, No. 2 (Fall 2002), pp. 4-7

The International Slide Rule Museum maintains digitized manuals and high-resolution photographs of the N-16 ES, preserving this remarkable instrument's computational legacy for contemporary engineers studying pre-digital analog computation methods.

## Conclusion

The Pickett N-16 ES embodies a complete analog computational system for electronics engineering—its 16-scale back face providing instantaneous solutions to resonance, reactance, frequency response, and phase shift problems that would otherwise require lengthy calculations. The ingenious use of reciprocal square root scales (Cr, Lr), four-decade decimal keepers (C/L), and simultaneous phase/gain/decibel readout (θ, COS θ, db) demonstrates sophisticated mathematical engineering. While digital calculators and computers have superseded its practical function, the N-16 ES remains an elegant example of how physical instrument design can encode complex mathematical relationships into immediately accessible computational tools.