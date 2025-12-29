# How to Use... Model N-16ES Electronic Slide Rule

**Pickett & Eckel, Inc.**

*Price 50 Cents*

---

## SPECIAL INSTRUCTIONS FOR THE CHAN STREET ELECTRONIC SLIDE RULE
### PICKETT & ECKEL MODEL N-16

---

## Solving for X_c and X_L

Set the frequency F, the angular velocity ω, or the wave length λ to the reference arrow (hereafter called the arrow), that is in the middle of the (D) scale, using the indicator. Opposite a value of capacitance C or inductance L on the (C or L) scale read X_c on its scale or X_L on the (X_L) scale. The relative values of frequency, capacitance, inductance and ohms can be readily determined by the use of the special decimal point scales. Along the lower edge of the rule and on the slide are scales that give the powers of 10 that are to be applied to the readings taken from the rule. For example, if the frequency is being read in mc, set the slide so the +6 or mc of the scale at the right hand end is just under the bridge. For capacitance in micromicrofarads, set the indicator to -12 or PF on the (C') scale. Above on TR' or X'_c read +6 or MΩ for the power of 10 that is to be applied to the X_c reading.

### Example:

**Find X_c for 4μμf at 6mc.**

Set .6 on the (F) scale to the arrow. Above 4 on the (C or L) scale read .0662 on the (X_c) scale. Now set +7 (.6 × 10⁷ = 6mc) to the bridge and the indicator to -12 or PF on the (C') scale. Above read +5 on the (X'_c) scale. This indicates that the reading of X_c scale should be multiplied by 10⁵ or .0662 × 10⁵ = 6,620 ohms.

The value of X_L is found in the same manner as for X_c except that readings are made between the (C or L) scale and the X_L scale.

This process may be reversed to find the value of C or L that will give a certain reactance X at a desired frequency or the frequency at which C or L will have a required reactance. Given two knowns of the equations:

$$X_C = \frac{1}{2\pi FC} = \frac{1}{\omega C} \quad \text{or} \quad X_L = 2\pi FL = \omega L$$

the other unknown may be found.

---

## Solving for Resonant Frequency

If frequency F, wave length λ or angular velocity ω is set to the arrow, the (C_r) and (L_r) scales give a continuous reading of the values of C and L that will be series or parallel resonant at the set frequency. The decimal point for C_r, L_r or F are found in the same manner as for X_c and X_L, but using (C'_r), (L'_r).

### Example:

Find the frequency at which a .2mh coil will be resonant with a 280μμf condenser. Set 2 on L_r to 2.8 on C_r. At the arrow read .672. Since .2mh = 2 × 10⁻⁴ henrys and 280μμf = 2.8 × 10⁻¹⁰ farads, set the indicator to -4 on (L'_r) scale and move the slide so that -10 is at the indicator on the (C'_r) scale. At the bridge read +6 or mc on the (F') scale, then F = .672 × 10⁶ or 672 Kc. Since the resonant frequency is a square scale, the powers of 10 used must add to an even number for this solution.

---

## RC Coupling Network

The interstage coupling network commonly used between vacuum tubes has the circuit configuration of:

![Figure 1: RC Coupling Network - Interstage vacuum tube coupling circuit showing R_L, R_M load resistors, C_c coupling capacitor, C'_o and C'_i output/input capacitances, R_g grid resistor, and R_K cathode resistor](fig1_rc_coupling_network.png)

*Figure 1: RC Coupling Network*

### Low Frequency Behavior

Assume that R_g and C_c are assigned. Set the value of C_c on the (C or L) scale to R_g on the (X_c) scale. Standard values of resistance are marked on the rule to aid in this setting. These consist of small dots just under the (X_L) scale. At the arrow read the frequency at which the coupling will be at the half power point with 45° phase shift. This value is F_L, the low frequency cutoff point. Holding the same slide setting, move the indicator to any other frequency setting and read the phase shift on the (θ) scale, (read numerals on left side of graduations without arrows), the dissipation on the (D) scale, the relative gain on the (Cos θ) scale, and the db loss on the (db) scale.

Since dissipation D = Cot θ, relative gain = Cos θ and db = 20 Log₁₀(1/Cos θ), these values have a fixed relation to each other. This means that at any setting of the slide, all values of C & R that are referring to each other will give the response indicated for any frequency as read by setting the indicator to a value of F and reading θ, D, db or relative gain. By this relationship any three factors between the groups may be chosen and the other found. This requires choosing one factor from (θ, D, db, or Cos θ) and two factors from (C, R or F).

### Example:

Let R_g in Fig. 1 be 390K and it is desired to find the nearest standard value of condenser for C_c that will give a loss of 1 db at 20 cycles. Set the indicator to -1 on the (db) scale. Move the slide and set 2 on the (F) scale to the hair line. Re-set the indicator to .39 on the (X_c) scale. Under the hair line read .4. Determining the decimal point gives a value of .04μf. If this value is not convenient and say .05μf is more suitable, move the slide till .5 (for .05μf) is at .39 (for 390K) and read F = 16.2∼ for -1 db response. The impedance Z in polar form represented by the coupling as a load on the tube may be solved by the relation of |Z| = R/Cos θ. Cos θ and θ may be read directly for any value of frequency when C is set to R. The (C) and (X_c) scales are used to compute R/Cos θ. Set the left index of scale (C) to R on (X_c).

Opposite Cos θ on (C) read |Z| on the (X_c) scale. This has performed the necessary division of R/Cos θ and gives |Z| ∠-θ.

In the above example for C = .04μf, Cos θ = .891. Set the left index of (C) to .39 and at 8.9 on (C) read .438. This gives Z = 438K ∠-26.96°.

---

## High Frequency Behavior

At high frequency the circuit in Fig. 1 resolves into the equivalent circuit of:

![Figure 2: High Frequency Equivalent Circuit - Simplified circuit showing signal source (~), r_p plate resistance, R_L load resistor, R_g grid resistor, and parallel capacitances C'_o, C'_g, C'_i](fig2_high_frequency_circuit.png)

*Figure 2: High Frequency Equivalent Circuit*

The effective internal impedance of the tube as a signal source may be solved by:

$$Z_{oL} = R_L \frac{r_p + R_k(1 + \mu)}{R_L + r_p + R_k(1 + \mu)}$$

Where R_L is the load resistor, r_p the dynamic plate resistance of the tube, R_k the cathode resistor and μ the amplification factor of the tube. C'_o is the effective output capacitance of the first tube and C'_I the effective input capacitance of the second tube. C_w, the wiring capacitance, is usually estimated. C'_I may be determined by:

$$C'_I = C_{gk}(1 - A_K) + C_{gp}(1 + A_L)$$

where C_gk is the grid to cathode capacitance and C_gp the grid to plate capacitance. A_k is the gain at the cathode and A_L the gain at the plate. C'_o is evaluated by:

$$C'_o = C_{pk}(1 + A_k) + C_{gp}(1 + \frac{1}{A_L})$$

where C_pk is the plate to cathode capacitance. Combining C'_o, C'_I and C_w to equal C_T gives the total shunt capacitance across the internal impedance of the source, Z_OL. To solve for the high cutoff frequency F_h, set C_T on (C) opposite Z_OL on (X_c), at the arrow read F_h on (F).

Leaving the slide as set, the indicator may be moved to any other frequency and the phase shift read directly on the (∢) scale. This scale is calibrated on the (θ) scale and is equal to (90-θ). The values of ∢ increase to the right and are marked with arrows. The loss in db is read at the bottom numerals of the db scale marked with arrows. If relative gain is desired, move the indicator to the same db value on the scale above (reading the other way) and read relative gain on the Cos θ scale. The polar impedance value of the load may be found by solving R cos ∢. The value of cos ∢ may be read when the indicator is set to θ = ∢. To solve for Z set cos ∢ on the (C) scale, to R on the (X_c) scale, and read |Z| on (X_c) opposite the index of (C). This has performed the solution of R cos ∢ and gives |Z| ∠+∢.

The rule may be used for the rapid solution of the stability criterion of the Nyquist diagram. A lead or lag circuit may be expressed in either its reactive and resistive components or simply by its time constant τ. For any combination of resistive and reactive components to which the rule is set, the time constant is at the arrow as read on the τ scale. If the coupling network is expressed in the S plane and can be factored to the form: s/(s+1/τ), it will be a lead circuit and its phase shift and db loss will be read on the θ and db scales. If the network factors into the form: 1/(s+1/τ), it will be a lag circuit and these values will be read on the ∢ scale and the bottom db scale.

---

## Solution

Set the time constant τ to the arrow, or if the problem involves a simple coupling network in a vacuum tube amplifier, the values as found in the previous example of coupling analysis may be used. With the slide set to the proper position for one of the networks in the closed loop, a note is made of the phase shift and db loss at various frequencies. The phase angle scale is extended on the upper side of the θ scale and reads angles to 0.6°. The db scale is also extended on the upper side of the D scale and reads db loss to -60 db for either a lag or lead circuit. These extended values are of importance in circuit stability problems. Complete this operation for each coupling circuit in the full loop. By adding the phase angles and db loss for each frequency used, the behavior of the entire loop is determined. These may be plotted on the accompanying chart. This plotting is best accomplished by slipping the chart under a piece of tracing paper and drawing directly on the transparent sheet so that the chart will not be spoiled by many markings. The basic criterion of stability is that the line so plotted does not encircle the -1 point. For further details on the subject of circuit stability, refer to the more extensive writings on the subject. A good practical discussion is in "RADIOTRON DESIGNERS HANDBOOK" by Langford-Smith. Further more advanced material will be found in "ELECTRONICS DESIGNER' HANDBOOK" by Landee, Davis and Albrecht, and "HANDBOOK OF AUTOMATION COMPUTATION AND CONTROL", Vol. 1 by Grabbe, Ramo and Wooldridge.

---

## TRANSMISSION or DELAY LINES

### Solving for Z_s, Surge Impedance

The surge, or characteristic impedance of a line in which the losses are negligible, is given by:

$$Z_s = \sqrt{\frac{L}{C}}$$

This may be solved in one setting of the rule. Set the arrow at the left index of (C_r) to the value of L on (L_r). Move the indicator to the value of C on (C_r) and read Z_s on the (Z_s) scale. The decimal point for this solution is determined with the use of the Z'_s, C'_s, and the multiplier of the frequency scale F'. Due to the extraction of a square root, C'_s and L'_s are chosen so that the exponents sum to an even power as in the resonant frequency solution. By setting the powers being used for C_s and L_s opposite each other, read the power of the multiplier at the bridge on the F' scale.

### DELAY TIME

The delay time of a transmission line or delay line in which the losses are negligible, may be solved by:

where N is the unit length for which L and C are defined.

To solve this set L on (L_r) to C on (C_r). At the arrow in the middle of (C) read τ_b/n on (X_c). This has solved for the delay time per section of the line. The decimal point is determined by the use of the C'_D, L'_D, and τ' scales. A position on the (C_r) and (L_r) scales should be used so that the power of 10 exponents sum to an even number. Set these powers opposite each other on the C'_D and L'_D scales and read the exponent to be used at bridge on the τ' scale.

---

## THE TIME CONSTANT. RC.

To determine the time constant of any RC circuit, set the value of R on (X_c) to the value of C on (C) and read the time constant τ on the (X_c) scale opposite the arrow in the middle of the (C) scale or at the arrow in the center of the D scale on the τ scale of the slide.

The decimal point is set using the τ'_c and τ'_R scales and the multiplier is read at the bridge on the τ' scale. If the time constant of an RL combination is being sought, the value of L on the (C or L) scale is set to the value of R on the (X_L) scale and the multiplier for the answer is found using the τ'_L and τ'_R scales. The multiplier of the answer is again read at the bridge on the τ' scale.

---

## Special Scale Side

| Scale | Description |
|-------|-------------|
| **θ** | phase shift angle (voltage with respect to current) of circuits whose phase increases with decreasing frequency (reads against frequency F scale). |
| **∢** | phase shift angle (voltage with respect to current) of circuits whose phase increases with increasing frequency (reads against frequency F scale). |
| **db** | power or voltage loss in coupling circuit (ratio of voltages or power) same as extended range scale on lower stator. |
| **D or Q** | quality factor of capacitive or inductive circuits (capacitance will normally have some resistive factor). A coil always has some losses so Q will always equal something less than infinity. |
| **X_L** | Inductive reactive impedance in ohms. |
| **\*** | Row of dots directly above X_L scale are standard resistance values (in ohms) when referred to X_L scale. |
| **Z_s or X_c** | X_c capacitive reactive impedance in ohms. Z_s surge impedance of transmission or characteristic impedance in ohms. |
| **C or L** | capacitive or inductive values in Farads or Henrys. |
| **F** | frequency, cycles per second. |
| **λ** | (lambda) wave length of any propagated signal in meters (calibrated on basis of velocity of light). |
| **ω** | (omega) angular rotation frequency in radians per second. |
| **τ** | (tau) time constant = 1/ω, τ = RC |
| **τR' or X'_c** | used with scales at bottom and edge of right hand end plate (bridge) to determine decimal point location. |
| **C_r & L_r** | for any frequency read at arrow on F scale, the values of resonant condenser and inductance are opposite each other on C_r and L_r scale. |
| **Cos θ** | relative gain in coupling circuit. |

---

## Standard Scale Side

| Scale | Description |
|-------|-------------|
| **SH 1, SH 2** | A continuous scale of Hyperbolic Sines in two parts |
| **TH** | Hyperbolic Tangents |
| **DF** | Full length D scale folded at π |
| **CF** | Full length C scale folded at π |
| **L** | Full length scale of equal parts 0 to 1.0 (decimal exponents of 10) |
| **S, ST, T** | Full length trig scales for Sines, Cosines, Tangents and Sine-Tangents of small angles for convenience in electrical problems inverted to read against CI. |
| **CI** | Full length C scale inverted |
| **C, D** | Two single logarithmic scales |
| **LL3** | Log Log scale with range 2.718 (e¹) to 22000 (e¹⁰) |
| **LL2** | Log Log scale with range 1.105 (e·¹) to 2.718 (e¹) |
| **LL1** | Log Log scale with range 1.01 (e·⁰¹) to 1.105 (e·¹) |
| **L_n** | Scale of equal parts 0 to 2.3 (decimal exponents of e) |

---

## Niquist Plot Sheet

The following Niquist Plot Sheet is included for circuit stability analysis. The red lines indicate circuit gain with feedback.

![Niquist Plot Sheet - Polar coordinate chart for plotting circuit stability analysis with phase angles from 90° to 270° and gain measurements in dB. Red lines indicate circuit gain with feedback.](niquist_plot_sheet.png)

*Niquist Plot Sheet - For circuit stability analysis. Red lines are circuit gain with feedback.*

**[High Resolution Version (400 DPI)](niquist_plot_400dpi.png)**

---

## Document Information

- **Source:** ISRM M379
- **Manufacturer:** Pickett & Eckel, Inc.
- **Locations:** Chicago 5, Illinois • Alhambra, California
- **Form:** M-23
- **Gift of:** Polly Hattemer
- **Archive:** International Slide Rule Museum

---

*This document has been converted from the original PDF to Markdown format for preservation and accessibility.*
