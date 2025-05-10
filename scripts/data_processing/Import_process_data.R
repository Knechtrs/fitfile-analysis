
# get list with data files
list.csv <- list.files(path = here("data/raw"), pattern = "\\.csv|\\.CSV", recursive=FALSE, full.names=TRUE) 

# get names for data files
Names_list.csv <- list.csv

# Create clean names
Names_list.csv <- list.csv %>%
  basename() %>%                # remove full folder path
  str_remove("\\.csv$|\\.CSV$")  # remove .csv extension only

# create list with files
list_data <- list.csv %>%
  map(~ readr::read_csv(.x, show_col_types = FALSE)) %>%
  setNames(Names_list.csv) # add filename to the list items

# bind list to dataframe
df_data_raw <- list_data %>% 
  bind_rows(.id="ID") 

#---- create metadata columns ----#

df_data <- df_data_raw %>%
  mutate(Donor = str_extract(ID, "(?<=_)(?!MCSF|GMCS|woRG|VLVG)[A-Za-z]{4}")) %>%  #look for donors
  mutate(
    CellType = str_extract(ID, "MDM|Monocytes"),
    Alginate = str_extract(ID, "MVG|VLVG|TCP"),
    Stimulus = str_extract(ID, "GMCSF|LPS"),
    Time = str_extract(ID, "48h"),
    RGD = if_else(str_detect(ID, "woRGD"), "woRGD", "RGD")
  ) %>%
  mutate(
    Alginate = Alginate %>%
        forcats::fct_recode("Slow" = "MVG", "Fast" = "VLVG") %>%
        forcats::fct_relevel("Fast", "Slow")) %>% 
  mutate(across(where(is.character), as.factor))

#---- check for NA in dataframe ----#
# Check if the data has any missing values
any(is.na(df_data))

# if (sum(is.na(df_data)) > 0) {
# 
#   # Remove rows containing any NA values
#   df_data <- df_data %>% drop_na()
# 
#   # Print message
#   cat("Missing values found and rows removed.\n")
#   cat("Remaining NAs after cleaning:\n")
#   print(colSums(is.na(df_data)))
# } else {
#   cat("No missing values found. No rows removed.\n")
# }

#---- remove fluorophore ----#
# rename header names
names(df_data) <- sub("\\s.*$", "", names(df_data)) # remove ": AF647 - Area"

#---- filter Markers ----#
df_data <- df_data %>%
  select(where(Negate(is.numeric)), all_of(params$Marker_order))

#---- Focus on Macrophages in gel ----#
df_data <- df_data %>% 
  filter(Alginate %in% params$FilterSample$Alginate,
         RGD %in% params$FilterSample$RGD,
         CellType %in% params$FilterSample$CellType,
         Stimulus %in% params$FilterSample$Stimulus
      ) %>% 
  droplevels()

#---- filter out Donors -----#
df_data <- df_data %>%
  filter(!Donor %in% params$FilterSample$Donor) %>%
  droplevels()


