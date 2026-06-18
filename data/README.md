# Project Data

This folder contains datasets used in the analysis and simulation activities of the CityHybrid project.

## Purpose

The data stored in this directory provides the input information required for vehicle modelling, drive cycle analysis, and powertrain evaluation.

## Files

### colombo_drive_cycle.csv

The primary drive cycle dataset used in the project.

This file contains the vehicle speed profile representing urban driving conditions in Colombo.

Applications:

* Drive cycle analysis
* Vehicle energy consumption estimation
* Power requirement calculations
* Hybrid powertrain evaluation
* MATLAB-based simulations

---

### colombo_cycle_verified.mat

MATLAB data file generated during drive cycle verification and processing.

This file contains processed data derived from the original drive cycle dataset and may be used to reduce processing time during subsequent analyses.

Applications:

* MATLAB simulations
* Processed drive cycle storage
* Intermediate analysis results

## Notes

* The CSV file serves as the primary source dataset.
* The MAT file contains processed MATLAB data generated from the source dataset.
* Any future datasets related to vehicle testing, simulation, or validation should be stored in this directory.
* File names should remain descriptive and consistent to ensure reproducibility of analyses.
