# CityHybrid — Series Hybrid Powertrain for L7e Urban Three-Wheelers

**ME 325 — Mechanical Engineering Group Project**
University of Peradeniya · Department of Mechanical Engineering

> A 1D longitudinal dynamics simulation of a series hybrid electric powertrain for commercial tuk-tuks, validated against the Colombo Urban Drive Cycle (Galgamuwa et al., 2016).

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [System Architecture](#3-system-architecture)
4. [Mathematical Models](#4-mathematical-models)
5. [Subsystem Details](#5-subsystem-details)
6. [Energy Management System](#6-energy-management-system)
7. [Simulation Setup](#7-simulation-setup)
8. [Results](#8-results)
9. [Impact Analysis](#9-impact-analysis)
10. [Team & Supervision](#10-team--supervision)
11. [References](#11-references)

---

## 1. Project Overview

Urban transportation in developing nations like Sri Lanka relies heavily on small three-wheelers (tuk-tuks) powered by conventional 200–236 cc internal combustion engines. These vehicles operate almost exclusively in erratic, low-speed urban traffic — exactly the worst operating regime for a conventional ICE.

This project designs, simulates, and bench-scale demonstrates a **Series Hybrid Electric Vehicle (SHEV)** architecture that replaces the stock engine with:

- A downsized **2.5 kW Auxiliary Power Unit (APU)** running at constant optimal RPM
- A **12 kW peak PMSM traction motor** handling all road demand
- A **1.2 kWh LiFePO₄ buffer battery** (48 V, 25 Ah)
- A **Thermostat Rule-Based EMS** implemented in Stateflow

The Colombo drive cycle (Galgamuwa et al., 2016) — with 20.5% idle time, 36.1% acceleration, and only 12.75% cruising — is used as the design target. The series topology is scientifically justified: with only 12.75% of the cycle spent cruising, a parallel engine would operate in its worst-efficiency low-gear transient region for 87.25% of the time.

### Key Results at a Glance

| Metric | Conventional Tuk-Tuk | Series Hybrid (This Project) | Improvement |
|---|---|---|---|
| Fuel Economy | ~4.20 L/100 km | **1.80 L/100 km** | **57.1% reduction** |
| CO₂ Emission Factor | ~98.0 g/km | **30.7 g/km** | **68.7% reduction** |
| Zero-Emission EV Mode | 0% | **65.8% of trip** | Urban air quality |
| Engine Displacement | 200–236 cc (always on) | 100 cc APU (34.2% of trip) | 50% downsizing |

---

## 2. Repository Structure

```
CityHybrid-ME325/
│
├── matlab/
│   ├── init_hybrid_model.m          # Master parameter initialization script
│   ├── post_process_results.m       # Fuel & CO₂ impact analysis script
│   └── colombo_clean.csv            # Digitized Colombo drive cycle data
│
├── simulink/
│   └── hybrid_powertrain_model.slx  # Complete Simulink model
│
├── docs/
│   ├── img_toplevel_model.png       # Top-level Simulink canvas
│   ├── img_vehicle_load_model.png   # Vehicle_Load_Model subsystem
│   ├── img_battery_subsystem.png    # Battery_Subsystem internals
│   ├── img_stateflow_ems.png        # Thermostat_EMS Stateflow chart
│   ├── img_scope_4trace.png         # Scope: Speed, SoC, I_Load, V_bus
│   └── img_scope_final.png          # Scope: Speed, SoC, APU_Cmd (final)
│
├── README.md
└── Project_Proposal.pdf
```

---

## 3. System Architecture

The top-level Simulink model implements a closed-loop series hybrid energy flow. Every subsystem communicates through a shared 48 V DC bus.

![Top-Level Simulink Model](docs/img_toplevel_model.png)
*Figure 1 — Top-level hybrid_powertrain_model.slx canvas. The drive cycle feeds the Vehicle_Load_Model, which computes I_Load and feeds Battery_Subsystem. SoC drives the Thermostat_EMS, whose APU_Cmd output controls the APU_Generator_Model. I_APU feeds back into the battery, closing the energy loop.*

### Signal Flow Summary

```
colombo_drive_cycle ──► Vehicle_Load_Model ──► I_Load ──► Battery_Subsystem
                              ▲                                │         │
                          V_bus (feedback)               soc ◄┘    V_bus ◄┘
                                                          │              │
                                                  Thermostat_EMS    APU_Generator_Model
                                                          │              │
                                                     APU_Cmd ──────────►│
                                                                    I_APU ──► Battery_Subsystem
```

---

## 4. Mathematical Models

### 4.1 Vehicle Longitudinal Dynamics

Total tractive effort at the wheel for flat-road operation:

$$F_{\text{TR}} = \underbrace{k_m \cdot m \cdot a}_{\text{Inertial}} + \underbrace{\frac{1}{2}\rho C_D A_F v^2}_{\text{Aerodynamic drag}} + \underbrace{C_{rr} \cdot m \cdot g}_{\text{Rolling resistance}}$$

where the rotational inertia coefficient $k_m = 1.08$ accounts for the apparent mass increase from the motor rotor, driveshaft, and road wheels (effective mass = 486 kg).

### 4.2 Motor Power Demand and Load Current

$$P_{\text{mechanical}} = F_{\text{TR}} \times v$$

$$I_{\text{Load}} = \frac{P_{\text{mechanical}}}{\eta_{\text{motor}} \times V_{\text{bus}}}$$

Regenerative braking is captured via a negative $F_{\text{TR}}$ path:

$$I_{\text{regen}} = \frac{P_{\text{decel}} \times K_{\text{regen}}}{V_{\text{bus}}}, \quad K_{\text{regen}} = \eta_{\text{motor}} \times k_{\text{regen}} = 0.88 \times 0.80 = 0.704$$

### 4.3 Battery State of Charge (Coulomb Counting)

$$\text{SoC}(t) = \text{SoC}_0 - \frac{1}{Q_{\text{capacity}}} \int_0^t \left(I_{\text{Load}} - I_{\text{APU}}\right) \mathrm{d}t$$

$$V_{\text{bus}} = V_{\text{OC}}(\text{SoC}) - \left(I_{\text{Load}} - I_{\text{APU}}\right) \cdot R_{\text{internal}}$$

where $V_{\text{OC}}(\text{SoC})$ is a 15-point LFP Open-Circuit Voltage lookup table reflecting the chemistry's characteristic flat mid-SoC plateau.

### 4.4 APU Generator Current Output

$$I_{\text{APU}} = \frac{P_{\text{APU,elec}} \times \eta_{\text{gen}}}{V_{\text{bus}}} = \frac{2500 \times 0.87}{V_{\text{bus}}} \approx 52 \text{ A (at nominal bus voltage)}$$

---

## 5. Subsystem Details

### 5.1 Vehicle Load Model

![Vehicle Load Model](docs/img_vehicle_load_model.png)
*Figure 2 — Vehicle_Load_Model subsystem. The pre-computed `accel_profile` timeseries feeds directly into the Inertial Force gain block (km×m), bypassing the numerical Derivative block that previously caused high-frequency noise in I_Load. The Transfer Fcn (τᵢ = 0.05 s) smooths the final current output.*

**Key design decision — Derivative block elimination:**
The standard approach of using Simulink's built-in `du/dt` Derivative block amplifies sample-to-sample jitter in the digitised velocity profile, producing non-physical current spikes of ±100 A at high frequency. The fix implemented here pre-computes acceleration in MATLAB using central differences followed by Savitzky-Golay filtering and physical clamping, then feeds the result into Simulink as a timeseries:

```matlab
a_raw     = gradient(v_ms_final, dt_cycle);    % Central difference
a_smooth  = sgolayfilt(a_raw, 2, 15);          % 1.5 s SG window
a_clamped = max(min(a_smooth, 1.5), -2.0);     % Physical clamp ±a_max
accel_profile = timeseries(a_clamped, t_uniform);
```

### 5.2 Battery Subsystem

![Battery Subsystem](docs/img_battery_subsystem.png)
*Figure 3 — Battery_Subsystem internals. The SoC integrator (1/s) feeds the 15-point LFP OCV lookup table (1-D T(u)) and the soc output port. The V_bus path computes OCV(SoC) − I_net × R_internal, then passes through a unit delay (1/z) and BMS Saturation block [45 V, 54 V].*

**Battery parameters:**

| Parameter | Value | Notes |
|---|---|---|
| Chemistry | LiFePO₄ (LFP) | Flat OCV plateau; thermal stability |
| Nominal Voltage | 48 V | 15S cell configuration |
| Capacity | 25 Ah / 1.2 kWh | Buffer pack (not full EV traction pack) |
| R_internal | 12 mΩ | Corrected for Colombo ambient (30°C) |
| SoC Window | 30% – 80% | EMS operating range |
| BMS V_bus limits | 45.0 – 54.0 V | Hardware protection saturation |
| BMS SoC limits | 15% – 95% | Software integration saturation |
| Initial SoC | 80% | Discharge-first for full sawtooth visibility |

**LFP OCV Curve (15-point lookup table):**

```matlab
soc_breakpoints = [0.00, 0.05, 0.10, 0.15, 0.20, 0.30, 0.40, 0.50, ...
                   0.60, 0.70, 0.80, 0.85, 0.90, 0.95, 1.00];
voc_values      = [37.5, 41.0, 44.0, 46.5, 48.0, 48.3, 48.6, 48.9, ...
                   49.2, 49.5, 49.8, 50.1, 50.8, 52.2, 54.75];
```

Note the flat plateau from 20%–80% SoC (48.0–49.8 V range), which distinguishes LFP from generic NMC Li-ion — a linear OCV curve would overestimate voltage variation and produce incorrect power calculations.

---

## 6. Energy Management System

### 6.1 Thermostat Stateflow EMS

![Stateflow EMS Chart](docs/img_stateflow_ems.png)
*Figure 4 — Thermostat_EMS Stateflow chart with 3 states. The ENGINE_STARTING intermediate state enforces a 2-second cranking delay (t_start ≥ 2.0 s) before APU_Cmd goes HIGH, modelling real engine start-up transient behaviour.*

**State transition logic:**

```
ENGINE_OFF  ──[soc ≤ 0.30]──►  ENGINE_STARTING  ──[t_start ≥ 2.0]──►  ENGINE_ON
    ▲                                                                        │
    └──────────────────[soc ≥ 0.80]─────────────────────────────────────────┘
```

| State | `APU_Cmd` | Action |
|---|---|---|
| `ENGINE_OFF` | `false` (0) | Pure EV mode — battery drives motor |
| `ENGINE_STARTING` | `false` (0) | Timer counting; battery still drives motor |
| `ENGINE_ON` | `true` (1) | APU generates power; charges battery + drives motor |

**Local data variable** `timer` (type `double`, initial value `0`) increments by `dt_cycle = 0.1 s` each Stateflow execution step in the `ENGINE_STARTING` `during` action.

### 6.2 APU Generator Model

The `APU_Generator_Model` subsystem implements a simple two-position switch:

$$I_{\text{APU}} = \begin{cases} \dfrac{P_{\text{APU,optimal}} \times \eta_{\text{gen}}}{V_{\text{bus}}} & \text{if } \texttt{APU\_Cmd} = 1 \\ 0 & \text{if } \texttt{APU\_Cmd} = 0 \end{cases}$$

**APU parameters:**

| Parameter | Value | Justification |
|---|---|---|
| Electrical output | 2,500 W | Sized for average Colombo cycle demand + surplus charging |
| Mechanical input | 2,874 W | P_elec / η_gen = 2500 / 0.87 |
| Generator efficiency | 87% | Conservative mid-point for small PM generators (85–92% range) |
| Engine class | ~100 cc single-cylinder | Downsized from stock 236 cc Bajaj RE (7.25–8.5 kW) |
| BSFC | 280 g/kWh | Small 4-stroke petrol at fixed optimal RPM |
| Bench-scale target | 28.7 W | Full-scale ÷ 100 for physical demonstrator |

### 6.3 Filter Configuration

Two first-order filters are used to maintain unity DC gain while suppressing numerical noise:

$$G(s) = \frac{1}{\tau s + 1}$$

| Filter | Location | Time Constant τ | Cutoff f_c | DC Gain |
|---|---|---|---|---|
| V_bus filter | Voltage feedback path | 0.10 s (100 ms) | 1.59 Hz | 1.0× |
| I_Load filter | Motor current output | 0.05 s (50 ms) | 3.18 Hz | 1.0× |

> **Critical:** Both filters must use the form `[1] / [τ, 1]` (not `[1] / [s + τ]`). Using `1/(s + 0.1)` produces a DC gain of 10, amplifying V_bus to ~480 V and corrupting all downstream power calculations.

---

## 7. Simulation Setup

### 7.1 Prerequisites

- MATLAB R2021a or later
- Simulink
- Stateflow
- Signal Processing Toolbox (for `sgolayfilt`)
- DSP System Toolbox (optional, for scope features)

### 7.2 Running the Simulation

**Step 1** — Place `colombo_clean.csv` in your MATLAB working directory.

**Step 2** — Run the initialization script:

```matlab
run('matlab/init_hybrid_model.m')
```

Expected console output:
```
Initialization complete. Workspace parameters loaded.
```

**Step 3** — Open and run the Simulink model:

```matlab
open('simulink/hybrid_powertrain_model.slx')
sim('hybrid_powertrain_model')
```

**Step 4** — Run post-processing:

```matlab
run('matlab/post_process_results.m')
```

### 7.3 Simulation Configuration

| Setting | Value |
|---|---|
| Solver | ode4 (Runge-Kutta fixed-step) |
| Step size | 0.1 s |
| Stop time | 4,800 s (4 loops × 1,200 s) |
| Drive cycle loops | 4 (configurable via `num_loops`) |

### 7.4 Drive Cycle Pre-Processing Pipeline

The raw Colombo cycle CSV is processed through three stages before entering Simulink:

```
Stage A  Uniform 10 Hz resampling using PCHIP interpolation
         → Eliminates variable-Δt noise from digitisation
         
Stage B  Savitzky-Golay smoothing (poly=2, frame=15 samples = 1.5 s window)
         → Removes corner jitter while preserving acceleration peaks
         
Stage C  Physical acceleration clamping: a ∈ [−2.0, +1.5] m/s²
         → Enforces tuk-tuk traction limits; prevents non-physical spikes
```

A pre-computed acceleration profile (`accel_profile`) is generated from the clamped velocity and fed directly to Simulink as a `timeseries` object, completely replacing the Derivative block.

---

## 8. Results

### 8.1 Four-Signal Scope Output (Intermediate)

![Scope 4 Trace](docs/img_scope_4trace.png)
*Figure 5 — Scope output showing (top to bottom): vehicle speed [km/h], battery SoC, motor I_Load [A], and DC bus voltage V_bus [V] across 4,800 s (4 Colombo loops). SoC discharges from 80% to 30% in EV mode (t = 0–1,950 s), then recovers to 80% during APU charging (t = 1,950–3,450 s), demonstrating correct thermostat operation.*

### 8.2 Final Scope with APU_Cmd

![Final Scope with APU_Cmd](docs/img_scope_final.png)
*Figure 6 — Final 3-channel scope showing speed, SoC, and APU_Cmd on separate Y-axes. The APU_Cmd binary signal (0 = engine off, 1 = engine on) transitions cleanly at both the 30% lower threshold (rising edge) and 80% upper threshold (falling edge). The 2-second ENGINE_STARTING delay is visible as a brief lag between the SoC threshold crossing and the APU_Cmd rising edge.*

### 8.3 Observed Waveform Properties

**SoC Trace — Thermostat Cycle Verification**

| Phase | Time Window | SoC Change | Average I_net | Average P_load |
|---|---|---|---|---|
| Discharge (EV mode) | 0 – 1,950 s | 80% → 30% | −22.9 A | 1,100 W |
| Charge (APU mode) | 1,950 – 3,450 s | 30% → 80% | +29.2 A net | 2,500 W in − 1,100 W out |
| Discharge (EV mode) | 3,450 – 4,800 s | 80% → 42% | −22.9 A | 1,100 W |

**I_Load Trace — Physical Bounds**

| Event | Current | Equivalent Power | Physical Interpretation |
|---|---|---|---|
| Peak acceleration | +220 A | +10.6 kW | 0→40 km/h burst demand |
| Cruise at avg speed | +25–35 A | +1.2–1.7 kW | Normal urban driving |
| Regenerative braking | −50 to −70 A | −2.4 to −3.4 kW | Deceleration energy recovery |
| Idle (v = 0) | 0 A | 0 W | Correctly zero — no engine idle waste |

**V_bus Trace — BMS Compliance**

- Minimum recorded: **46.0 V** (above BMS cutoff of 45.0 V ✓)
- Maximum recorded: **51.5 V** (below BMS ceiling of 54.0 V ✓)
- APU-ON segments visible as elevated baseline (~50.0–51.5 V) reflecting higher OCV at rising SoC

---

## 9. Impact Analysis

### 9.1 Post-Processing Results

```
================== SIMULATION IMPACT RESULTS ==================
 Total Distance Traveled:    27.61 km
 APU Running Time:           1643 s (34.2% of total trip)
 Engine OFF (EV Mode Time):  3157 s (65.8% zero local emissions)
---------------------------------------------------------------
 Total Fuel Consumed:        0.496 Liters
 Equivalent Fuel Economy:    1.80 L/100km
 CO2 Emission Factor:        30.7 g/km
===============================================================
```

### 9.2 Comparison Against Stock Tuk-Tuk Baseline

| Performance Parameter | Stock 200 cc Tuk-Tuk | Series-Hybrid Tuk-Tuk | Improvement |
|---|---|---|---|
| Powertrain | Conventional ICE | Series-Hybrid (APU + Battery) | — |
| Engine Displacement | 200–236 cc | ~100 cc APU | 50% downsizing |
| Engine Runtime | 100% of operation | 34.2% of operation | 65.8% reduction |
| Fuel Economy | ~4.20 L/100 km | **1.80 L/100 km** | **57.1% reduction** |
| CO₂ Factor | ~98.0 g/km | **30.7 g/km** | **68.7% reduction** |
| Zero-emission EV travel | 0% | **65.8% of trip** | Urban air quality |
| Regenerative braking | None | Yes (K_regen = 0.704) | Energy recovery |

### 9.3 Why Series Topology Outperforms Parallel for Colombo Conditions

The Colombo drive cycle statistics (Galgamuwa et al., 2016) directly justify the series architecture:

| Colombo Cycle Parameter | Value | Series Hybrid Advantage |
|---|---|---|
| Average speed | 20.3 km/h | Low speed → low aero drag → small APU sufficient |
| Idle time | 20.5% | APU shuts off during idle → zero fuel waste |
| Acceleration fraction | 36.1% | Traction motor provides instant peak torque at 0 RPM |
| Deceleration fraction | 30.65% | Regen captures 70.4% of kinetic energy back |
| Cruising fraction | 12.75% | Engine decoupled from road → runs at BSFC optimum |

In a parallel configuration, the ICE would be mechanically coupled to the wheels and forced to operate at low-gear, high-transient RPM for 87.25% of the cycle — far from its BSFC optimum. The series decoupling eliminates this penalty entirely.

### 9.4 Engineering Limitations and Future Work

| Limitation | Impact on Results | Mitigation for Future Work |
|---|---|---|
| Road gradient neglected (θ = 0) | Underestimates average load by ~15–20% on hilly routes | Implement time-varying θ profile from Colombo elevation data |
| Constant temperature (30°C) | R_internal does not vary with thermal cycling | Add electrothermal battery model |
| Rule-based EMS only | Not globally optimal | Replace with ECMS (Equivalent Consumption Minimisation Strategy) |
| Engine start transient simplified | 2-second fixed delay; real engines have RPM ramp-up | Add engine RPM dynamics with generator load coupling |
| Flat BSFC at 280 g/kWh | Real BSFC varies with throttle and RPM | Implement 2D BSFC map lookup |

---

## 10. Team & Supervision

| Role | Member | Specialisation |
|---|---|---|
| Mechanical Design | E/21/089 — Dewpura A. S. | Vehicle dynamics, chassis, thermal |
| Mechatronics A — Simulation | E/21/091 — Dharmapriya B. U. G. | 1D Simulink modelling, component sizing |
| Mechatronics B — Control | E/21/344 — Samarakoon M. M. | Stateflow EMS, firmware, bench hardware |
| Supervisor | Prof. A. C. Ratnaweera | Department of Mechanical Engineering |

**Course:** ME 325 — Mechanical Engineering Group Project
**Institution:** Faculty of Engineering, University of Peradeniya, Sri Lanka

---

## 11. References

1. Galgamuwa, U., Perera, L., and Bandara, S. (2016). Development of a driving cycle for Colombo, Sri Lanka. *Journal of Advanced Transportation*, 50, 1520–1530. https://doi.org/10.1002/atr.1414

2. Husain, I. (2011). *Electric and Hybrid Vehicles: Design Fundamentals* (2nd ed.). CRC Press.

3. Khurmi, R. S., and Gupta, J. K. (2005). *Theory of Machines*. S. Chand & Co. Ltd.

4. Shigley, J. E. (2011). *Mechanical Engineering Design*. McGraw-Hill Education.

5. Mashadi, B., and Crolla, D. (2011). *Vehicle Powertrain Systems: Integration and Optimization*. John Wiley & Sons.

6. Mahindra Electric. Treo Product Specifications. Retrieved from https://www.mahindraelectric.com/treo

7. Department of Motor Traffic, Sri Lanka. (2015). Total Vehicle Population 2007–2014.

---

## Licence

This project was developed for academic purposes under ME 325, University of Peradeniya. All simulation code and documentation are made available for educational reference.

---

*Last updated: 2025 | CityHybrid ME325 — Series Hybrid L7e Three-Wheeler*
