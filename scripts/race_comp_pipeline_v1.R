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

# create function to read in yaml file
load_param <- function(default_file = here("config", "params_v1.yaml"), 
                       override_file = NULL) {
  # Load default
  settings <- yaml::read_yaml(default_file)
  
  # If override exists, update defaults
  if (!is.null(override_file)) {
    override <- yaml::read_yaml(override_file)
    settings[names(override)] <- override
  }
  
  return(settings)
}

# read in yaml file with custom functions: defines which files to take as input and their input variables
params <- load_param(default_file = here("config", "config_IATF_25K_RSK_v1.yaml"))

read_fit_data <- function(file, # fit.file
                          trip_id,  # id for file, e.g. 2025
                          start_time = NULL # if activity start is not correct
                          ) {
  data <- FITfileR::readFitFile(file)
  
  df <- FITfileR::records(data) %>%
    bind_rows() %>%
    arrange(timestamp)
  
  # if you need to define start manually
  if (!is.null(start_time)) {
    df <- df %>% filter(timestamp > as.POSIXct(start_time, tz = "UTC"))
  }
  
  df <- df %>% 
    mutate(
      time_rel = as.numeric(timestamp - first(timestamp), units = "secs"), # calculate relative timing
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

df_2024 <- read_fit_data("~/Downloads/15219812583_ACTIVITY.fit", "2024", "2024-05-04 09:30:55")
df_2025 <- read_fit_data("~/Downloads/19013373499_ACTIVITY.fit", "2025")

#--- make sure activities have same length and create LINESTRING ----#

extend_linestring_from_df <- function(df, target_m_max) {
  # Ensure required columns exist
  if (!all(c("lon", "lat", "z", "m") %in% names(df))) {
    stop("Data frame must contain 'lon', 'lat', 'z', and 'm' columns.")
  }
  
  # Sort by time just in case
  df <- df %>% arrange(m)
  
  current_m_max <- max(df$m, na.rm = TRUE)
  
  # If already long enough, return original LINESTRING ZM
  if (current_m_max >= target_m_max) {
    coords <- df %>% select(lon, lat, z, m) %>% as.matrix()
  } else {
    # Duplicate last row and update m
    last_point <- df[nrow(df), ]
    last_point$m <- target_m_max
    
    coords <- bind_rows(
      df %>% select(lon, lat, z, m),
      last_point %>% select(lon, lat, z, m)
    ) %>% as.matrix()
  }
  
  # Return as sf LINESTRING ZM
  st_sf(
    trip_id = unique(df$trip_id),
    geometry = st_sfc(st_linestring(coords, dim = "XYZM")),
    crs = 4326
  )
}

# Determine common max time
max_time <- max(
  max(df_2025$m),
  max(df_2024$m)
)

# Extend the shorter trip
sf_2025 <- extend_linestring_from_df(df_2025, target_m_max = max_time)
sf_2024 <- extend_linestring_from_df(df_2024, target_m_max = max_time)

# combine both years to one dataframe
sf_combined <- bind_rows(sf_2024, sf_2025)
                         
#-----------------------------#
# 2. Determine map center
#-----------------------------#

center_coords <- st_coordinates(sf_combined) %>%
  as_tibble() %>%
  summarise(
    lon = mean(X, na.rm = TRUE),
    lat = mean(Y, na.rm = TRUE)
  ) %>%
  unlist(use.names = FALSE)

#-----------------------------#
# 3. Show animated movement with add_trips
#-----------------------------#

mapdeck(style = mapdeck_style("light"),
        location = center_coords,
        zoom = 10,
        pitch = 45) %>%
  add_trips(
    data = sf_combined,
    stroke_colour = "trip_id",
    palette = colourvalues::get_palette("viridis")[0:150, ],
    trail_length = 100,
    stroke_width = 100,
    animation_speed = 500,
    layer_id = "trips_layer",
    legend = TRUE,
    legend_options = list(title = "IATF 25k")
  ) %>% 
  add_path(
    data = sf_combined,
    stroke_colour = "trip_id",
    palette = colourvalues::get_palette("plasma")[100:200, ],
    stroke_width = 5,
    layer_id = "path_layer",
    legend = FALSE
  )

