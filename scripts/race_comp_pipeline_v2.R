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
library(renv)
renv::restore()

# Load required libraries
library(FITfileR)
library(tidyverse)
library(sf)
library(mapdeck)
library(sfheaders)
library(geojsonsf)
library(here)
library(yaml)

# After adding new packages (use renv::install():
# renv::snapshot()  # To save current state

# Set your Mapbox token
set_token("pk.eyJ1Ijoia25lY2h0cnMiLCJhIjoiY21hOWlsbXR1MWd4djJrc2JhYmU3c3VrbCJ9._BxOBVsWVDX9WBEzfIu8Dg")

#-----------------------------#
# 1. Load and clean .fit data
#-----------------------------#
# 1. Load YAML Parameters
load_param <- function(default_file = here("config", "params_v1.yaml"), 
                       override_file = NULL) {
  settings <- yaml::read_yaml(default_file)
  
  if (!is.null(override_file)) {
    override <- yaml::read_yaml(override_file)
    settings[names(override)] <- override
  }
  
  return(settings)
}

# 2. Define Read Function
read_fit_data <- function(file, trip_id, start_time = NULL) {
  data <- FITfileR::readFitFile(file)
  
  df <- FITfileR::records(data) %>%
    bind_rows() %>%
    arrange(timestamp)
  
  if (!is.null(start_time)) {
    df <- df %>% filter(timestamp > as.POSIXct(start_time, tz = "UTC"))
  }
  
  df <- df %>% 
    mutate(
      time_rel = as.numeric(timestamp - first(timestamp), units = "secs"),
      timestamp_str = format(timestamp, "%Y-%m-%dT%H:%M:%SZ"),
      trip_id = as.character(trip_id),
      lon = position_long,
      lat = position_lat,
      z = 0,
      m = as.numeric(time_rel)
    ) %>%
    filter(!is.na(lon), !is.na(lat))
  
  return(df)
}

# 3. Load Parameters and Loop Over All Files
params <- load_param(here("config", "config_IATF_25K_RSK_v1.yaml"))

fit_dfs <- lapply(params$fit_data, function(entry) {
  file_path <- here("data", "raw", entry$file)
  trip_id <- entry$trip_id
  start_time <- entry$start_time  # may be NULL
  
  read_fit_data(file_path, trip_id, start_time)
})

# 4. Combine All Data Frames (Optional)
all_fits_combined <- bind_rows(fit_dfs)
#--- make sure activities have same length and create LINESTRING ----#

# Function to extend one linestring
extend_linestring_from_df <- function(df, target_m_max) {
  required_cols <- c("lon", "lat", "z", "m")
  stopifnot(all(required_cols %in% names(df)))
  
  df <- df %>% arrange(m)
  current_m_max <- max(df$m, na.rm = TRUE)
  
  # If already long enough, just use as is
  if (current_m_max >= target_m_max) {
    coords <- df %>% select(lon, lat, z, m) %>% as.matrix()
  } else {
    last_point <- df[nrow(df), ]
    last_point$m <- target_m_max
    
    coords <- bind_rows(
      df %>% select(lon, lat, z, m),
      last_point %>% select(lon, lat, z, m)
    ) %>% as.matrix()
  }
  
  st_sf(
    trip_id = unique(df$trip_id),
    geometry = st_sfc(st_linestring(coords, dim = "XYZM")),
    crs = 4326
  )
}

# run extend_linestring_from_df function
# Step 1: Find the global maximum time (m)
max_time <- max(map_dbl(fit_dfs, ~ max(.x$m, na.rm = TRUE)))

# Step 2: Extend all trips to the same max time: apply function
sf_list <- map(fit_dfs, extend_linestring_from_df, target_m_max = max_time)

# Step 3: Combine all sf linestrings
sf_combined <- bind_rows(sf_list)

#-----------------------------#
# 2. Determine map center
#-----------------------------#

compute_center_coords <- function(sf_object) {
  st_coordinates(sf_object) %>%
    as_tibble() %>%
    summarise(
      lon = mean(X, na.rm = TRUE),
      lat = mean(Y, na.rm = TRUE)
    ) %>%
    unlist(use.names = FALSE)
}

center_coords <- compute_center_coords(sf_combined)

#-----------------------------#
# 3. Show animated movement with add_trips
#-----------------------------#

# Modular rendering function
render_iatf_map <- function(
    data,
    center = center_coords,
    zoom = 10,
    pitch = 45,
    trips_palette = "viridis",
    trips_palette_range = 0:150,
    path_palette = "plasma",
    path_palette_range = 100:200,
    legend_title = "IATF 25k"
) {
  mapdeck(style = mapdeck_style("light"),
          location = center,
          zoom = zoom,
          pitch = pitch) %>%
    
    add_trips(
      data = data,
      stroke_colour = "trip_id",
      palette = colourvalues::get_palette(trips_palette)[trips_palette_range, ],
      trail_length = 100,
      stroke_width = 100,
      animation_speed = 500,
      layer_id = "trips_layer",
      legend = TRUE,
      legend_options = list(title = legend_title)
    ) %>%
    
    add_path(
      data = data,
      stroke_colour = "trip_id",
      palette = colourvalues::get_palette(path_palette)[path_palette_range, ],
      stroke_width = 5,
      layer_id = "path_layer",
      legend = FALSE
    )
}

render_iatf_map(
  data = sf_combined,
  trips_palette = "viridis",
  path_palette = "plasma"
)

