read_fit_data <- function(file, trip_id, start_time = NULL) {
  data <- FITfileR::readFitFile(file)
  df <- FITfileR::records(data) %>%
    bind_rows() %>%
    arrange(timestamp)
  
  # ensure position_lat and position_lon are valid
  df <- df %>%
    filter(
      !is.na(position_lat), !is.na(position_long),
      position_lat != 180, position_long != 180,
      between(position_lat, -90, 90),
      between(position_long, -180, 180)
    )

  if (!is.null(start_time)) {
    df <- df %>% filter(timestamp > as.POSIXct(start_time, tz = "UTC"))
  }

  df %>% 
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
}