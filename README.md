# Project EYE: VLEO Remote Sensing Systems Sizing & Trade Tool

A multidisciplinary design optimization (MDO) model developed in MATLAB and SIMULINK for the Advanced Space Systems Engineering module at The University of Manchester. 

The architecture sizes a Very Low Earth Orbit (VLEO) satellite, resolving coupled orbital, optical, aerodynamic, and power loops to minimize total spacecraft wet mass for a 5-year mission.

## Key Subsystems & Methodology
- **Orbital Mechanics:** Solves J2 repeating Sun-Synchronous Orbits (SSO) at 10:30 LTAN, evaluating ground-track resonance ($n/m$) with GCD filtering to guarantee a $<5$-day revisit across $40^\circ\text{--}80^\circ$ latitudes.
- **Optical Payload Trade:** Evaluates diffraction-limited Rayleigh aperture sizing ($1\text{ m}$ GSD) vs. SNR constraints ($\text{SNR} > 100$), implementing an 8-stage Time Delay Integration (TDI) sensor to minimize Optical Telescope Assembly (OTA) mass.
- **Rarefied Aerodynamics (ADBSat):** Free molecular flow panel method analysis across swept angles of attack to extract drag coefficients ($C_D$) for cuboid, cylindrical, and hexagonal buses.
- **Dynamic Simulation (SIMULINK):** Propagates orbits coupled with NRLMSISE-00 atmospheric density, modeling diurnal density swings, battery depth-of-discharge, and a 72-hour Coronal Mass Ejection (CME) safe mode.
- **Space Sustainability & Demise:** Validates orbit maintenance with DEMS and confirms passive atmospheric burn-up in 72 days, exceeding FCC 5-year de-orbit rules and ESA Design for Demise (D4D) standards.

## Optimal Converged Baseline (Hexagonal Chassis)
- **Altitude:** 330.5 km ($i = 96.8^\circ$)
- **Total Wet Mass:** 99.8 kg (Dry Mass: 79.2 kg, Margin: 15.8 kg, Propellant: 4.8 kg)
- **Propulsion:** High-$I_{sp}$ Gridded Ion Thruster
- **Internal Free Volume:** 20.01% (compliant with COTS antenna and vibration clearance)

## Contents
- `src/`: MATLAB trade space scripts and SIMULINK orbit/power propagation models.
- `docs/`: Technical slide deck and preliminary system requirements.
- `media/`: Has figures from all tests completed for final presentation deliverable.

## Guide
- Use trade_constants.m first to load constants into workspace
- Use TradeSpaceTool.m and PowerAndPropulsionSizingTool.m as main scripts in that order.
- Use SIMULINK AdvancedOrbitModel.slx for dynamic Power and Environment results.
