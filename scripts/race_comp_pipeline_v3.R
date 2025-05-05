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

# Set your Mapbox token
set_token("pk.eyJ1Ijoia25lY2h0cnMiLCJhIjoiY21hOWlsbXR1MWd4djJrc2JhYmU3c3VrbCJ9._BxOBVsWVDX9WBEzfIu8Dg")

# load functions
source(here("scripts", "utilities", "config_loader_v1.R"))
source(here("scripts", "data_processing", "fit_reader_v1.R"))
source(here("scripts", "data_processing", "geometry_utils_v1.R"))
source(here("scripts", "plotting", "map_renderer_v1.R"))


# Load parameters
params <- load_param(here("config", "config_IATF_25K_RSK_v1.yaml"))

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
                trail_length = 10,
                animation_speed = 50,
                stroke_width = 50,
                trips_palette_range = 1:250,
                legend_title = "Test",
                SinglePath = TRUE,
                Trip_id = "18077597590_ACTIVITY")


