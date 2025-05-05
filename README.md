# Plots animated gps coordinates from garmin fit files to compare activites/races on the same route.

## Project Structure

- `R/` – custom functions
- `config/` - input variables
- `figures/` – plotting scripts
- `data/raw/` – raw input data
- `data/processed/` – cleaned/processed data
- `data/plots_rds/` – saved ggplot objects
- `Output/final_figures/` – final publication-ready plots
- `Output/temp/` – temporary plots (ignored by git)
- `scripts/` – analysis scripts
- `reports/` – knitted reports
- `renv/` - folder containing installed packages

## Setup

## Version history of scripts
- v1: initial set-up
- v2: improved version
 	- input files and parameters defined in yaml file
	- takes more than n=2 files as input now
- v3: functions are now external scripts and loaded via source
	

## restore version using renv::restore()

## How to run:
- visit garmin connet website
- click on activity
- click on gear icon and export activity
- open zip.file and load .fit file into data folder
- select which activites to plot in yaml file
- open r-project
- run script: /Users/Raphael/Library/CloudStorage/OneDrive-Charité-UniversitätsmedizinBerlin/Privat/R_fun/Race_comparison/scripts/race_comp_pipeline_v3.R
- to create gif: record screen and upload to https://ezgif.com/video-to-gif

# NOTE: needs a mapbox account. set your token!