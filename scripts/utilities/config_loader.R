load_param <- function(default_file = here("config", "params_v1.yaml"), 
                       override_file = NULL) {
  settings <- yaml::read_yaml(default_file)
  if (!is.null(override_file)) {
    override <- yaml::read_yaml(override_file)
    settings[names(override)] <- override
  }
  return(settings)
}