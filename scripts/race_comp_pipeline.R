##--- Project Initialization (Run Once) ---#
# First time setup:
# install.packages("renv")  # Install renv globally if needed
# renv::init()              # Initialize project environment

#--- Package Installation (As Needed) ---#
# Install all required packages
# renv::install(c(
#   "tidyverse", "sf", "mapdeck", "sfheaders", "geojsonsf", 
#   "remotes"   # Include remotes for GitHub installations
# ))
# 
# # GitHub packages
# renv::install("grimbough/FITfileR")

#--- Regular Project Startup ---#
# Restore project environment
library(renv); renv::restore()
library(here)

# Load required libraries
library(FITfileR)
library(tidyverse)
library(sf)
library(mapdeck)
library(sfheaders)
library(geojsonsf)
library(here)
library(yaml)

# Set your Mapbox token from .Renviron file
Sys.getenv("MAPBOX_TOKEN")

# load functions
source(here("scripts", "utilities", "config_loader.R"))
source(here("scripts", "data_processing", "fit_reader.R"))
source(here("scripts", "data_processing", "geometry_utils.R"))
source(here("scripts", "plotting", "map_renderer.R"))


# Load parameters: per command or interactively
# command example: Rscript scripts/race_comp_pipeline_v3.R config/config_test_v1.yaml
args <- commandArgs(trailingOnly = TRUE)
yaml_file <- if (interactive()) {
  file.choose()
} else if (length(args) > 0) {
  args[1]
} else {
  "config/config_default.yaml"
}

params <- load_param(here::here(yaml_file))

# if you want to remove certain files
# params$fit_data <- params$fit_data[-1]


# Read and process FIT files
fit_dfs <- lapply(params$fit_data, function(entry) {
  read_fit_data(here("data", "raw", entry$file), entry$trip_id, entry$start_time)
})


# Extend trips to same length
max_time <- max(map_dbl(fit_dfs, ~ max(.x$m, na.rm = TRUE)))
sf_combined <- bind_rows(map(fit_dfs, extend_linestring_from_df, target_m_max = max_time))

# Center + visualize
center_coords <- compute_center_coords(sf_combined)

render_iatf_map(data = sf_combined,
                center = center_coords,
                mapStyle = "light",
                trail_length = 100,
                stroke_width = 150,
                stroke_widthPath = 50,
                animation_speed = 500,
                trips_palette_range = 0:130,
                path_palette_range = 200:210,
                legend_title = "IATF")
                # SinglePath = FALSE,
                # Trip_id = "18077597590_ACTIVITY")


