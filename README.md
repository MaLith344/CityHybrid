# CityHybrid

This repository contains the progress of our Mechanical Engineering Third Year Project.

## Project Title
**Conceptual Design and Bench-scale Demonstration of a Hybrid Powertrain for a Small Urban Vehicle**

## Project Overview
CityHybrid is a mechanical engineering design project focused on the conceptual development and evaluation of a hybrid powertrain system for a three-wheeler (L7e category) operating in urban environments. 

The project combines vehicle modelling, drive cycle analysis, aerodynamic assessment, and powertrain design to investigate the feasibility and performance benefits of hybridization for small urban transport vehicles. 

## Project Objectives
* Develop a conceptual hybrid powertrain architecture for a three-wheeler.
* Analyze vehicle operating conditions using the localized Colombo drive cycle.
* Estimate vehicle power and energy requirements.
* Evaluate aerodynamic performance using Computational Fluid Dynamics (CFD).
* Support design decisions through simulation and engineering analysis.
* Demonstrate the feasibility of hybrid powertrain integration at bench scale.

## Repository Structure
* **`CAD/`** - Simplified vehicle CAD model used for analysis.
* **`CFD/`** - Fluent/ANSYS CFD setup files and aerodynamic results.
* **`MATLAB/`** - Vehicle parameter and powertrain calculation scripts.
* **`EMS Simulation/`** - Main Simulink powertrain models (`hybrid_powertrain_model.slx`) and Stateflow controllers.
* **`data/`** - Drive cycle and input datasets.
* **`documentation/`** - Project proposal, presentations, and progress documents.
* **`reference-documents/`** - Datasheets, papers, and supporting references.

---

## Current Milestones & System Architecture

### 1. 1D Vehicle Dynamics & Drive Cycle Modeling
* **Mechanical-to-Electrical Linkage:** Successfully established a mathematical model converting tractive road forces (drag, rolling resistance, inertia) into electrical power demand on the DC bus.
* **Data Smoothing:** Implemented a continuous-time Low-Pass Filter (τ=1s) on the Colombo drive cycle to eliminate numerical noise and prevent impossible physical acceleration demands.
* **Mechanical Braking Isolation:** Applied load saturation limits (Min: 0 W) to the tractive demand. Deceleration is currently handled by mechanical friction brakes, preventing erroneous regenerative spikes (Regen recovery to be implemented in subsequent phases).

### 2. Series Hybrid Powertrain Sizing
Based on peak load simulations and tractability requirements, the vehicle operates as a **Battery-Dominant "Range Extender" Series Hybrid**:
* **Traction Motor:** 14.0 kW peak power (300.6 Nm peak torque at the wheel).
* **Battery Pack:** 1.5 kWh capacity (High-power chemistry required to handle transient discharge bursts).
* **Auxiliary Power Unit (APU):** 1.5 kW downsized ICE generator to provide a continuous trickle charge.

### 3. Energy Management System (EMS) Logic
The EMS is controlled via a Simulink Stateflow Rule-Based Thermostat (Coulomb Counting) that dynamically balances power across the DC bus ($I_{Battery} = I_{APU} - I_{Motor}$).

* **Low SoC Threshold (APU ON):** 30%
* **High SoC Threshold (APU OFF):** 80%

**Validated Operational Modes:**
1. **Charge Depleting (Pure EV):** APU is OFF. Motor draws 100% of its required current from the 1.5 kWh battery.
2. **Charge Sustaining (Cruising/Slow Speed):** APU is ON. Motor demand is < 1.5 kW. The APU powers the motor directly, and any excess power trickles into the battery.
3. **Power Assist (Heavy Acceleration):** APU is ON. Motor demand > 1.5 kW (up to 14.0 kW). The APU provides its maximum 1.5 kW, and the battery seamlessly discharges the remaining load to prevent bus stalls.
4. **Braking & Idle:** Motor demand is 0 W. If the APU is ON, its full 1.5 kW output is routed to continuously charge the battery while stopped at traffic lights.

---

## Software and Tools
* SolidWorks
* ANSYS Workbench & ANSYS Fluent
* MATLAB & Simulink (Stateflow)
* Git & GitHub

## Disclaimer
The current CAD, CFD, and Simulink models are simplified representations developed for preliminary engineering analysis. Results are intended for conceptual design purposes and may differ from those of a fully detailed production vehicle.

## Team Members
* **E/21/089** - Dewpura A. S.
* **E/21/091** - Dharmapriya B. U. G.
* **E/21/344** - Samarakoon M. M.

**Supervisor:** Prof. A. C. Ratnaweera
