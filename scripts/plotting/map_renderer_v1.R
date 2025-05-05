render_iatf_map <- function(
    data,
    center,
    zoom = 10,
    pitch = 45,
    trail_length = 100,
    stroke_width = 100,
    animation_speed = 500,
    trips_palette = "viridis",
    trips_palette_range = 1:150,
    path_palette = "plasma",
    path_palette_range = 101:200,
    legend_title = "IATF 25k", 
    SinglePath = FALSE, # Should only one add_path be plotted?
    Trip_id = NULL       # Define which trip_id to use if SinglePath = TRUE
) {
  
  # Filter path layer if SinglePath is TRUE
  data_path <- if (SinglePath && !is.null(Trip_id)) {
    data %>% filter(trip_id == Trip_id)
  } else {
    data
  }

  # Create the map with both trips animation and path layers
  mapdeck(style = mapdeck_style("light"),
          location = center, zoom = zoom, pitch = pitch) %>%
    add_trips(
      data = data,
      stroke_colour = "trip_id",
      palette = colourvalues::get_palette(trips_palette)[trips_palette_range, ],
      trail_length = trail_length,
      stroke_width = stroke_width,
      animation_speed = animation_speed,
      layer_id = "trips_layer",
      legend = TRUE,
      legend_options = list(title = legend_title)
    ) %>%
    add_path(
      data = data_path,
      stroke_colour = "trip_id",
      palette = colourvalues::get_palette(path_palette)[path_palette_range, ],
      stroke_width = 5,
      layer_id = "path_layer",
      legend = FALSE
    )
}