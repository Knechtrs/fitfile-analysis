extend_linestring_from_df <- function(df, target_m_max) {
  required_cols <- c("lon", "lat", "z", "m")
  stopifnot(all(required_cols %in% names(df)))

  df <- df %>% arrange(m)
  current_m_max <- max(df$m, na.rm = TRUE)

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

compute_center_coords <- function(sf_object) {
  st_coordinates(sf_object) %>%
    as_tibble() %>%
    summarise(lon = mean(X, na.rm = TRUE), lat = mean(Y, na.rm = TRUE)) %>%
    unlist(use.names = FALSE)
}